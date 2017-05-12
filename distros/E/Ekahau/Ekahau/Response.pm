package Ekahau::Response;
use Ekahau::Base; our $VERSION=Ekahau::Base::VERSION;

# Written by Scott Gifford <gifford@umich.edu>
# Copyright (C) 2004 The Regents of the University of Michigan.
# See the file LICENSE included with the distribution for license
# information.

use strict;
use warnings;
use bytes;

=head1 NAME

Ekahau::Response - Response from an Ekahau server

=head1 SYNOPSIS

Provides a straightforward encapsulation of the response objects
returned by the Ekahau Positioning Engine.  This is the base class for
the specific responses; in general you will want to use one of them.

=head1 DESCRIPTION

This class takes care of parsing responses from the Ekahau server into
their individual components.

The responses returned by Ekahau are a sort of half-assed XML.  They
look superficially like XML, but not enough that they can be parsed by
an XML parser.  Instead, this module takes a simplistic approach to
parsing them.  The exact rules for parsing aren't clear from the
documentation, so this parsing may not be correct in all
circumstances, but we have not observed any misparsing with the
current code.

The response is parsed into the hash reference that comprises this
object.  It's parsed like this:

  <#tag cmd args[0] args[1] ...
  params{key1}=value1
  params{key2}=value2
  SEPARATOR1
  params{SEPERATOR1}[0]{key3}=value3
  params{SEPERATOR1}[0]{key4}=value4
  SEPARATOR1
  params{SEPERATOR1}[1]{key3}=value3
  params{SEPERATOR1}[1]{key4}=value4
  >

Here are some examples.  First,

  <#LOC LOCATION_ESTIMATE 4
  accurateX=1427.09
  accurateY=2141.73
  accurateTime=1117138297067
  accurateContextId=22940
  latestX=1429.14
  latestY=2140.60
  latestTime=1117138301067
  latestContextId=22940
  speed=0.09101
  heading=5.78188
  >


parses to:

  {
    'tag' => 'LOC',
    'cmd' => 'LOCATION_ESTIMATE',
    'args' => [ '4' ],
    'params' => {
      'latestX' => '1429.14',
      'accurateY' => '2141.73',
      'heading' => '5.78188',
      'accurateTime' => '1117138297067',
      'latestY' => '2140.60',
      'accurateContextId' => '22940',
      'speed' => '0.09101',
      'accurateX' => '1427.09',
      'latestTime' => '1117138301067',
      'latestContextId' => '22940'
    },
  }

Second,

  <#AREA AREA_ESTIMATE 4
  AREA
  name=2425
  probability=1.000
  contextId=22940
  polygon=1396;1396;1554;1554;1394;1396&1964;2200;2200;1964;1964;1964;
  AREA
  name=2431
  probability=0.000
  contextId=22940
  polygon=1560;1559;1682;1680;1804;1804;1559;1560&1968;2197;2196;2153;2154;1966;1966;1968;
  >

parses to:

  {
    'tag' => 'AREA',
    'cmd' => 'AREA_ESTIMATE',
    'args' => [ '4' ],
    'params' => {
      'AREA' => [
        {
	  'contextId' => '22940',
	  'probability' => '1.000',
	  'name' => '2425',
	  'polygon' => '1396;1396;1554;1554;1394;1396&1964;2200;2200;1964;1964;1964;'
	}, {
	  'contextId' => '22940',
	  'probability' => '0.000',
	  'name' => '2431',
	  'polygon' => '1560;1559;1682;1680;1804;1804;1559;1560&1968;2197;2196;2153;2154;1966;1966;1968;'
	}
      ]
    }
  }

Finally, this response:

  <#2376 DEVICE_LIST
  1
  2
  3
  >

parses to this:

  {
    'tag' => '2376',
    'cmd' => 'DEVICE_LIST',
    'args' => [],
    'params' => {
      '3' => [ {} ],
      '2' => [ {} ],
      '1' => [ {} ],
    }
  }

=cut

use Ekahau::Response::DeviceList;
use Ekahau::Response::DeviceProperties;
use Ekahau::Response::Error;
use Ekahau::Response::LocationEstimate;
use Ekahau::Response::LocationContext;
use Ekahau::Response::AreaEstimate;
use Ekahau::Response::AreaList;
use Ekahau::Response::StopLocationTrackOK;
use Ekahau::Response::StopAreaTrackOK;
use Ekahau::Response::MapImage;

use constant RESPONSEBASE => 'Ekahau::Response::';

our %CMDCLASS = (
		 DEVICE_LIST => RESPONSEBASE.'DeviceList',
		 DEVICE_PROPERTIES => RESPONSEBASE.'DeviceProperties',
		 LOCATION_ESTIMATE => RESPONSEBASE.'LocationEstimate',
		 CONTEXT => RESPONSEBASE.'LocationContext',
		 AREA_ESTIMATE => RESPONSEBASE.'AreaEstimate',
		 STOP_LOCATION_TRACK_OK => RESPONSEBASE.'StopLocationTrackOK',
		 STOP_AREA_TRACK_OK => RESPONSEBASE.'StopAreaTrackOK',
		 AREALIST => RESPONSEBASE.'AreaList',
		 MAP => RESPONSEBASE.'MapImage',
		 );
use constant ERROR_CLASS => 'Ekahau::Response::Error';

=head2 Constructors

=head3 new ( %params )

Creates a new empty object.  The only parameter recognized is C<tag>,
which sets the tag property for the response.

=cut

sub new
{
    my $class = shift;
    my(%p) = @_;
    my $self = {};

    if ($p{tag})
    {
	$self->{tag} = $p{tag};
    }
    bless $self, $class;
}

# Internal method
sub init
{
    # Do nothing
}

=head3 parsenew ( $response_str )

Parse a response string into an object.  The results are undefined if
C<$response_str> is not a valid Ekahau response.

=cut

sub parsenew
{
    my $class = shift;
    my $self = $class->new();
    $self->parse(@_);
    warn "parsenew: cmd is '$self->{cmd}'\n"
	if ($ENV{VERBOSE});
    if (my $newclass = $CMDCLASS{$self->{cmd}})
    {
	bless $self,$newclass;
	$self->init;
    }
    elsif ($self->{cmd} =~ /^(?:MALFORMED_REQUEST|.*_NOT_FOUND|FAILURE|.*_FAILED|.*_PROBLEM)/)
    {
	bless $self,ERROR_CLASS;
	$self->init;
    }
    $self;
}

=head2 Methods

=head3 parse ( $response_str )

Populate the fields of an object with the ones in C<$response_str>,
overwriting any existing values.  The results are undefined if
C<$response_str> is not a valid Ekahau response.

=cut

sub parse
{
    my $self = shift;
    my($r) = @_;
    my $data;

    $r =~ s/^\s+//;
    $r =~ s/\s+$//;
    $self->{string} = $r;
    
    # Look for a tag
    if ($r =~ s/^\s*<(\#\w*?\s)?\s*// and $1)
    {
	# Preserve taintedness with substr(X,0,0)
	chop($self->{tag} = substr($1,1).substr($self->{string},0,0))
    }
    # Does this contain sized data?
    if ($r =~ /\x0asize=(\d+).*?\x0adata=/sg)
    {
	my $data_len = $1;
	my $data_pos = pos($r);
	$data = substr($r,$data_pos,$data_len,'');
	# Remove the "data="
	substr($r,-5,5,'');
    }

    # Remove trailing angle bracket and whitespace
    $r =~ s/\s*>\s*$//;

    # Split the response into lines
    my @lines = split(/(?<!\\)\x0d?\x0a/,$r);
    # This probably doesn't handle quoting correctly
    my @firstline = split(' ',shift @lines);

    # The first line
    $self->{cmd} = shift @firstline;
    $self->{args} = [map { s/^\"//; s/\"$//; $_ } @firstline];
    $self->{params}={};

    # Are there any arguments that are really parameters?
    foreach my $i (0..$#{$self->{args}})
    {
	if ($self->{args}[$i] =~ /^(\w+)=(.*)$/)
	{
	    # Use substr to keep taintedness
	    $self->{params}{$1}=$2.substr($self->{args}[$i],0,0);
	    # Remove argument
	    splice(@{$self->{args}},$i,1,());
	}
    }
    # Parameters on other lines
    my $datahash = $self->{params};
    foreach my $l (@lines)
    {
	my $keep_taintedness = substr($l,0,0);
	$l =~ s/\\(<|>|\x0d\x0a)/$1/g;
	if ($l =~ /^([\w.\-]+?)=(.*)$/)
	{
	    # Using this as a hash key will implictly untaint it,
	    # so require that values be "word characters".
	    my $val = $2.$keep_taintedness;
	    $datahash->{$1}=$val;
	}
	else
	{
	    $datahash = {};
	    push(@{$self->{params}{$l}},$datahash);
	}
    }
    if (defined($data))
    {
	$self->{params}{data}=$data;
    }
    # Special case: copy area up to main parameters, for backwards
    # compatibility.
    if ($self->{params}{AREA} and $self->{params}{AREA}[0])
    {
	while(my($k,$v)=each(%{$self->{params}{AREA}[0]}))
	{
	    $self->{params}{$k} = $v;
	}
    }
    
    $self;
}    

=head3 get_props ( @prop_names )

Returns a hash containing the values for the list of properties in
C<@prop_names>.  If C<@prop_names> is empty, all properties will be
returned.

=cut

sub get_props
{
    my $self = shift;
    if (!@_) { @_ = keys %{$self->{params}} };
    
    return map { $_ => $self->{params}{$_} } @_;
}

=head3 get_prop ( $prop_name )

Returns the value for one of this object's properties, specified by
C<$prop_name>.  If no property named C<$prop_name> exists, C<undef> is
returned.

=cut

sub get_prop
{
    my $self = shift;
    my $prop = $_[0];

    return $self->{params}{($prop)};
}


=head3 error ( )

Returns true if this response is an L<Ekahau::Response::Error|Ekahau::Response::Error> object,
else returns false.

=cut

sub error
{
    0;
}

=head3 eventname ( )

Returns the name of this event in the same format used by
L<Ekahau::Events|Ekahau::Events>.

=cut

sub eventname
{
    my $self = shift;
    $self->error ? 'ERROR' : uc $self->{cmd};
}

=head3 type ( )

Returns the string I<Response>, to identify the type of this object,
and that no more specific information is available.

=cut

sub type
{
    'Response';
}

=head3 tostring ( )

Return a string representation of the object.  This is reconstructed
from the object's properties, and so may not be identical to the
string which was parsed to create it.

=cut

sub tostring
{
    my $self = shift;
    
    my $str = "<";
    if (defined($self->{tag})) { $str .= "#$self->{tag} " };
    $str .= $self->{cmd};
    if (@{$self->{args}})
    {
	$str .= " ".join(" ",@{$self->{args}});
    }
    if ($self->{params})
    {
	$str .= "\x0d\x0a";
	
	foreach my $var (keys %{$self->{params}})
	{
	    my $val = $self->{params}{$var};
	    if (defined($val))
	    {
		$val =~ s/(<|>|\x0d\x0a)/\\$1/g;
		$str .= "$var=$val\x0d\x0a";
	    }
	    else
	    {
		$str .= "$var\x0d\x0a";
	    }
	}
    }
    $str .= ">\x0d\x0a";
    return $str;
}

1;

=head1 AUTHOR

Scott Gifford E<lt>gifford@umich.eduE<gt>, E<lt>sgifford@suspectclass.comE<gt>

Copyright (C) 2005 The Regents of the University of Michigan.

See the file LICENSE included with the distribution for license
information.


=head1 SEE ALSO

L<Ekahau::Base|Ekahau::Base>, L<Ekahau::Response::DeviceList|Ekahau::Response::DeviceList>,
L<Ekahau::Response::DeviceProperties|Ekahau::Response::DeviceProperties>, L<Ekahau::Response::Error|Ekahau::Response::Error>,
L<Ekahau::Response::LocationEstimate|Ekahau::Response::LocationEstimate>,
L<Ekahau::Response::LocationContext|Ekahau::Response::LocationContext>,
L<Ekahau::Response::AreaEstimate|Ekahau::Response::AreaEstimate>, L<Ekahau::Response::AreaList|Ekahau::Response::AreaList>,
L<Ekahau::Response::StopLocationTrackOK|Ekahau::Response::StopLocationTrackOK>,
L<Ekahau::Response::StopAreaTrackOK|Ekahau::Response::StopAreaTrackOK>, L<Ekahau::Response::MapImage|Ekahau::Response::MapImage>.

=cut

1;
