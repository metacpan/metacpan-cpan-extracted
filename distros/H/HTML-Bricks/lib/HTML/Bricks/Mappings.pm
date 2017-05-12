#-----------------------------------------------------------------------------
# File: Mappings.pm
#-----------------------------------------------------------------------------
# Manages the uri->assembly mapping database
#-----------------------------------------------------------------------------
#
# mapping{folder}            = base folder for this mapping
# mapping{recurse}           = should this flag recurse into subdirectories (yes/no)
# mapping{match_type}        = string or regexp
# mapping{match_string}      = string or Perl regexp against which to test the request URI
# mapping{brick_name}        = name of brick (typically an assembly)
#
#-----------------------------------------------------------------------------

package HTML::Bricks::Mappings;

use strict;

our $VERSION = '0.02';

#
# Hardwired mappings so that the site can always be administered
#

my @hardwired_mappings = ( 
    { folder => '/', 
      recurse => 'n',
      match_type => 'regexp',
      match_string => 'bricks.*\.html',
      brick_name => 'bricks_header_and_footer' },
    { folder => '/', 
      recurse => 'n',
      match_type => 'string',
      match_string => 'bricks_login.html',
      brick_name => 'bricks_login' },
    { folder => '/',
      recurse => 'n',
      match_type => 'string',
      match_string => 'bricks_open.html',
      brick_name => 'bricks_open' },
    { folder => '/',
      recurse => 'n',
      match_type => 'string',
      match_string => 'bricks_mappings.html',
      brick_name => 'bricks_mappings' } );


#-----------------------------------------------------------------------------
# new
#-----------------------------------------------------------------------------
sub new($$) {

  my ($class) = @_;

  my $self = {};

  $self->{basename} = $HTML::Bricks::Config{bricks_root} . '/data/mappings';
  $self->{cached_mtime} = -1;
  $self->{cached_rary} = undef;

  bless $self, $class;
  return $self;
}

#-----------------------------------------------------------------------------
# read_mappings
#-----------------------------------------------------------------------------
sub read_mappings($) {
  my $self = shift;

  my $filename = $self->{basename};

  return undef if ! -e $filename;

  my @statdata = stat($filename);

  return $self->{cached_rary} if $statdata[9] == $self->{cached_mtime};

  use Apache::File;
  my $fh = Apache::gensym();

  open($fh,"< $filename");

  return undef if !defined $fh;

  my $string = join('',<$fh>);

  my $VAR1;
  
  eval($string);

  close($fh);

  $self->{cached_mtime} = $statdata[9];
  $self->{cached_rary} = $VAR1;

  return $VAR1;  # reference to an array
}

#-----------------------------------------------------------------------------
# write_mappings
#-----------------------------------------------------------------------------
sub write_mappings($$) {
  
  my ($self,$rary) = @_;

  use Apache::File;
  my $fh = Apache::gensym();

  my $filename = $self->{basename};
  open($fh,"> $filename");

  return if !defined $fh;

  use Data::Dumper;
  print $fh Dumper($rary);

  close($fh);
}

#-----------------------------------------------------------------------------
# insert
#-----------------------------------------------------------------------------
sub insert($$$) {

  my ($self,$position,$rmapping) = @_;
  
  my $rary = $self->read_mappings();

  $position = $#$rary+1 if $position == -1;

  splice @$rary, $position, 0, $rmapping;

  $self->write_mappings($rary);

}

#-----------------------------------------------------------------------------
# update
#-----------------------------------------------------------------------------
sub update($$$) {
  my ($self, $position, $rmapping) = @_;

  $position = 0 if !defined $position;
  my $rary = $self->read_mappings();
  splice @$rary, $position, 1, $rmapping;
  $self->write_mappings($rary);

}

#-----------------------------------------------------------------------------
# [] get_list
#-----------------------------------------------------------------------------
sub get_list($) {

  my $self = shift;

  my $rary = $self->read_mappings;

  return undef if !defined $rary;

  my @ary = @$rary;  # return a copy
  return \@ary;

}

#-----------------------------------------------------------------------------
# delete
#-----------------------------------------------------------------------------
sub delete($$) {
  my ($self,$position) = @_;

  my $rary = $self->read_mappings();

  splice @$rary, $position, 1;

  $self->write_mappings($rary);
}

#-----------------------------------------------------------------------------
# [] get_matches
#-----------------------------------------------------------------------------
sub get_matches($) {
  my ($self,$uri) = @_;

  my @matches;

  my $rmappings = $self->get_list();

  splice (@$rmappings, 0, 0, @hardwired_mappings); 

  foreach (@$rmappings) {

    # 1. does the beginning of the uri match the folder name?
    #    if not, next
    
    if (substr($uri,0,length($$_{folder})) ne $$_{folder}) {
      next;
    }

    # 2. does the uri have additional dirs and is the map set for recurse?
    #    if not, next

    my @dirs = split("/",$uri);

    if (($#dirs > 1) && ($$_{recurse} eq 'no')) {
      next;
    }

    # 3. strip the folder name off of the uri
   
    my $start = length($$_{folder});
    my $uri2 = substr($uri,$start,length($uri) - $start);

    # 4. does the uri match match_string?

    if ($$_{match_type} eq 'string') {
      if ($uri2 ne $$_{match_string}) {
        next;
      }
    }
    else {
      if ($uri2 !~ $$_{match_string}) {
        next;
      }
    }

    push @matches, $$_{brick_name};
  }

  return unless ($#matches != -1);

  return @matches;
}

return 1;
