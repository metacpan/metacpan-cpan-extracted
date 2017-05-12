package Geo::Cache;
use strict;
use XML::Simple;
use Time::CTime qw();

# Docs {{{

=head1 NAME

Geo::Cache - Object interface for GPS waypoints

=head1 SYNOPSIS

    use Geo::Cache;
    my $wpt = Geo::Cache->new(
        lat  => '37.99815',
        lon  => '-85.302017',
        time => $time,
        name => 'GCGVW8',
        desc => 'Neither Hill nor Dale',
        sym  => 'geocache',
        type => 'Geocache|Traditional Cache',
    );
    $wpt->url('http://www.geocaching.com/');


    my $wpt_from_xml = Geo::Cache->new( xml => $xml, );

    my $xml = $wpt->xml;

=head1 DESCRIPTION

Provide an object interface to Geocaching.com waypoints and/or
geocaches, using the Groundspeak GPX file as the reference for what
fields are valid.

Methods are provide for various of the fields that require special
treatment.

Three output methods are provided -- C<gpx>, C<gpsdrive>, and C<loc>,
for outputting a single waypoint in one of these three formats. These
can be used in conjunction with the C<Geo::Gpx> module to produce files
of those formats.

=head1 AUTHOR

	Rich Bowen
	rbowen@rcbowen.com

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

# }}}

use vars qw(@FIELDS $VERSION $AUTOLOAD $CACHEID);
$VERSION = '0.22';
@FIELDS = qw(lat lon time name desc url urlname sym type);

# sub new {{{

=head2 new

Create a new C<Geo::Cache> object.

    my $wpt = Geo::Cache->new(
        lat  => '37.99815',
        lon  => '-85.302017',
        time => $time,
        name => 'GCGVW8',
        desc => 'Neither Hill nor Dale',
        sym  => 'geocache',
        type => 'Geocache|Traditional Cache',
    );

=cut

sub new {
    my $class = shift;
    my %parameters = @_;
    my $self = {};

    # Can create with a blob of XML?
    # if ( $parameters{xml} ) {
    #    # do something useful
    # } else {
        my %valid = map {$_=>1} @FIELDS;
        foreach my $field ( keys %parameters ) {
            delete $parameters{$field} unless $valid{$field};
        }
        $self = bless( \%parameters, ref($class) || $class );
    # }

    return ($self);
} # }}}

# AUTOLOADER {{{

=head2 Data methods

A data method is provided for each of the valid fields within a Cache
object. Calling the method with no argument returns the value of that
attribute. Calling the method with an argument changes the value of that
attribute to that value.

 my $name = $cache->name;
 $cache->lon(-84.8934);

=cut

sub AUTOLOAD {
    my $self = shift;
    my $val = shift;
    my ( $method );
    ( $method = $AUTOLOAD ) =~ s/.*:://;

    if (defined $val) {
        $self->{$method} = $val;
    } else {
        # Use the existing value
    }

    return $self->{$method};
} # }}}

# sub xml {{{

=head2 xml/gpx

Returns a blob of XML which constitutes one <wpt> block of a
Geocaching.com-style gpx data file. You'll generally not use this
method by itself, but will call the C<gpx> method from the C<Geo::Gpx>
module to generate the entire file of one or more waypoints.

C<xml> is an alias for the C<gpx> method.

=cut

sub gpx {
    my $self = shift;
    my @fields = @FIELDS;
    shift @fields for (1..2); # lat and lon

    my $ret = qq~<wpt lat="$self->{lat}" lon="$self->{lon}">\n~;

    # It appears that time, url and urlname are required fields
    $self->{url} ||= 'http://drbacchus.com/';
    $self->{urlname} ||= 'Geo::Cache';
# Time looks like 2004-06-11T17:34:28.3952500-07:00
    $self->{time} ||=
      Time::CTime::strftime( '%Y-%m-%dT%T.0000000-07:00', localtime );
    $self->{sym} ||= 'box';

    foreach my $x (@fields) {
        if ($self->{$x}) {
            $ret .= qq~<$x>$self->{$x}</$x>\n~;
        } else {
            $ret .= "<$x />\n";
        }
    }

    # Need to add a little more stuff in order for this to wind up
    # generating valid GPX files
    $CACHEID++;
    $ret .= '<groundspeak:cache id="' . $$ . $CACHEID . '" available="True" archived="False" xmlns:groundspeak="http://www.groundspeak.com/cache/1/0">' . "\n";
    $ret .= qq|<groundspeak:name>$self->{name}</groundspeak:name>
<groundspeak:type>Traditional Cache</groundspeak:type>
<groundspeak:container>Regular</groundspeak:container>
<groundspeak:difficulty>1</groundspeak:difficulty>
<groundspeak:terrain>1</groundspeak:terrain>
<groundspeak:country>United States</groundspeak:country>
<groundspeak:state>Kentucky</groundpeak:state>
<groundspeak:short_description>$self->{desc}</groundspeak:short_description>
<groundspeak:long_description html="False">Geo::Cache</groundspeak:long_description>
<groundspeak:encoded_hints />
<groundspeak:logs>
</groundspeak:logs>
<groundspeak:travelbugs />
</groundspeak:cache>
|;

    $ret .= "</wpt>\n";

    return $ret;
}

sub xml {
    my $self = shift;
    return $self->gpx;
} # }}}

sub loc {
    my $self = shift;

    my $ret = '<waypoint>';
    $CACHEID++;
    $ret .= '<name ="' . $$ . $CACHEID . '"><![CDATA[' .
        $self->{name} . ']]></name>' . "\n";
    $ret .= qq~<coord lat="$self->{lat}" lon="$self->{lon}"/>\n~;
    $ret .= "<type>Geocache</type>\n";
    $ret .= qq~<link text="Cache Details">$self->{name}</link>\n</waypoint>\n~;

    return $ret;
}

sub gpsdrive {
    my $self = shift;

    my $name = $self->{name};
    $name =~ s/\W/_/g;
    $name =~ s/^_+//;
    $name =~ s/_{2,}/_/g;
    $name =~ s/^(.{15}).*/$1/;

    my $ret =
      $name . "\t" . $self->{lat} . "\t" . $self->{lon} . "\tGeocache\n";

    return $ret;
}

1; 

