use strict;
use warnings;

package Log::Log4perl::Config::YamlConfigurator;

# keeping the following $VERSION declaration on a single line is important
#<<<
use version 0.9915; our $VERSION = version->declare( 'v1.0.0' );
#>>>

use parent qw( Clone Log::Log4perl::Config::BaseConfigurator );

use Carp                  qw( croak  );
use YAML                  qw( Load );
use Log::Log4perl::Config qw();

sub create_appender_instance {
  my ( $self, $name ) = @_;

  my $data = $self->parse;
  return Log::Log4perl::Config::create_appender_instance( $data, $name, {}, [],
    exists $data->{ threshold } ? $data->{ threshold }->{ value } : undef );
}

sub new {
  my $class = shift;

  my $self = $class->SUPER::new( @_ );

  unless ( exists $self->{ data } ) {
    if ( exists $self->{ text } ) {
      $self->{ data } = Load( join( "\n", @{ $self->{ text } } ) );
    } else {
      croak "'text' parameter not set, stopped";
    }
  }

  croak "'data' parameter has to be a HASH reference with the keys 'category', and 'appender', stopped"
    unless ref( $self->{ data } ) eq 'HASH'
    and exists $self->{ data }->{ category }
    and exists $self->{ data }->{ appender };

  return $self;
}

# https://metacpan.org/pod/Log::Log4perl::Config::BaseConfigurator#Parser-requirements
sub parse {
  my ( $self ) = @_;

  # make sure that a parse() does not change $self!
  my $copy = $self->clone;
  my @todo = ( $copy->{ data } );

  while ( @todo ) {
    my $ref = shift @todo;
    for ( keys %$ref ) {
      if ( ref( $ref->{ $_ } ) eq 'HASH' ) {
        push @todo, $ref->{ $_ };
      } elsif ( $_ eq 'name' ) {
        # appender 'name' entries and layout 'name entries are converted to ->{value} entries
        $ref->{ value } = $ref->{ $_ };
        delete $ref->{ $_ };
      } else {
        my $tmp = $ref->{ $_ };
        $ref->{ $_ } = {};
        $ref->{ $_ }->{ value } = $tmp;
      }
    }
  }

  return $copy->{ data };
}

1;
