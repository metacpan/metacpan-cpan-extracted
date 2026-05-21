# Prefer numeric version for backwards compatibility
BEGIN { require 5.006000 }; ## no critic ( RequireUseStrict, RequireUseWarnings )
use strict;
use warnings;

package Log::Log4perl::Config::YamlConfigurator;

$Log::Log4perl::Config::YamlConfigurator::VERSION = 'v1.2.0';

use parent qw( Clone Log::Log4perl::Config::BaseConfigurator );

use Carp                  qw( croak );
use Log::Log4perl::Config ();

sub create_appender_instance {
  my ( $self, $name ) = @_;

  my $data = $self->parse;
  Log::Log4perl::Config::create_appender_instance( $data, $name, {}, [],
    exists $data->{ threshold } ? $data->{ threshold }->{ value } : undef )
}

sub new {
  my $class = shift;

  my $self = $class->SUPER::new( subst => {}, @_ );

  unless ( exists $self->{ data } ) {
    if ( exists $self->{ text } ) {
      require YAML::PP;
      $self->{ data } = YAML::PP::Load( join( "\n", @{ $self->{ text } } ) )
    } else {
      croak "'text' parameter not set, stopped"
    }
  }

  croak "'data' parameter has to be a HASH reference with the keys 'category', and 'appender', stopped"
    unless ref( $self->{ data } ) eq 'HASH'
    and exists $self->{ data }->{ category }
    and exists $self->{ data }->{ appender };

  $self
}

# https://metacpan.org/pod/Log::Log4perl::Config::BaseConfigurator#Parser-requirements
sub parse {
  my ( $self ) = @_;

  # Make sure that a parse() does not change $self!
  my $copy = $self->clone;
  my @todo = ( $copy->{ data } );

  while ( @todo ) {
    my $ref = shift @todo;
    for ( keys %$ref ) {
      if ( ref( $ref->{ $_ } ) eq 'HASH' ) {
        push @todo, $ref->{ $_ }
      } elsif ( $_ eq 'name' ) {
        # Appender 'name' entries and layout 'name entries are converted to ->{ value } entries
        ( $ref->{ value } = $ref->{ $_ } ) =~ s/\$\{(.*?)\}/Log::Log4perl::Config::var_subst( $1, $self->{ subst } )/ge;
        delete $ref->{ $_ }
      } else {
        ( my $tmp = $ref->{ $_ } ) =~ s/\$\{(.*?)\}/Log::Log4perl::Config::var_subst( $1, $self->{ subst } )/ge;
        $ref->{ $_ } = {};
        $ref->{ $_ }->{ value } = $tmp
      }
    }
  }

  $copy->{ data }
}

1
