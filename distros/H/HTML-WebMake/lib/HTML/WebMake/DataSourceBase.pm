#

package HTML::WebMake::DataSourceBase;


use HTML::WebMake::DataSource;
use Carp;
use strict;

use vars	qw{
  	@ISA
};




###########################################################################

sub new {
  my $class = shift;
  $class = ref($class) || $class;

  my ($parent) = @_;
  my $self = { %$parent };

  $self->{parent}	= $parent;

  bless ($self, $class);
  $self;
}

sub as_string {
  my ($self) = @_;
  $self->{parent}->as_string();
}

# -------------------------------------------------------------------------

sub add {
  my ($self) = @_;
  croak "Unimplemented interface in ".__FILE__;
}

# -------------------------------------------------------------------------

sub get_location_url {
  my ($self, $location) = @_;
  warn "<media> tag not supported by this data source: $location\n";
  "";
}

# -------------------------------------------------------------------------

sub get_location_contents {
  my ($self, $location) = @_;
  croak "Unimplemented interface in ".__FILE__;
}

# -------------------------------------------------------------------------

sub get_location_mod_time {
  my ($self, $location) = @_;
  croak "Unimplemented interface in ".__FILE__;
}

1;
