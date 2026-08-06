# Prefer numeric version for backwards compatibility
BEGIN { require 5.010000 }; ## no critic ( RequireUseStrict, RequireUseWarnings )
use strict;
use warnings;

#<<<
package Dist::Starter::Context;
BEGIN {
our $VERSION = 'v0.1.0';
}
#>>>

use File::Spec::Functions qw( catfile );
use YAML::Tiny            qw( Dump DumpFile LoadFile );

use Dist::Starter::Exception ();

sub dump_to_file {
  my ( $self, $file ) = @_;

  DumpFile( $file, { %$self } )
}

sub dump_to_string {
  my $self = shift;

  Dump( { %$self } )
}

sub load_from_file {
  my ( $class, $file ) = ( shift, shift );

  bless( LoadFile( $file ), $class )->_adjust_context( @_ )
}

sub lookup {
  my ( $self, $variable ) = @_;

  my $value = $self;
  for ( split /\./, $variable ) {
    die Dist::Starter::Exception->new( message => "Context contains no value for variable '$variable'" )
      unless defined( $value = $value->{ $_ } )
  }

  $value
}

sub _adjust_context {
  my $self = shift;
  my %args;
  {
    use warnings FATAL => qw( misc uninitialized );
    %args = @_
  }

  # Process 'args'
  for ( qw( abstract distname git_base_url ) ) {
    $self->{ $_ } = $args{ $_ } if exists $args{ $_ };
  }
  if ( exists $args{ min_perl_version } ) {
    my $min_perl_version = $args{ min_perl_version };
    die Dist::Starter::Exception->new( message => "Invalid minimum perl version '$min_perl_version'" )
      unless $min_perl_version =~ qr/\A 5 \. \d{6} \z/x;
    $self->{ min_perl_version } = $min_perl_version
  }
  if ( exists $args{ author } ) {
    my $author = $args{ author };
    if ( $author eq 'FROM_GIT' ) {
      # Do not enclose qx() command string in spaces
      chomp( $self->{ author }->{ full_name } = qx(git config --global --get user.name) );
      chomp( $self->{ author }->{ email }     = qx(git config --global --get user.email) )
    } elsif ( $author eq 'FROM_ENV' ) {
      for ( qw( full_name email ) ) {
        $self->{ author }->{ $_ } = $ENV{ +uc }
      }
    } else {
      die Dist::Starter::Exception->new( message => "Cannot parse author '$args{ author }'" )
        unless my ( $full_name, $email ) = $args{ author } =~ m/\A ( [^<@]+? ) (?:\ * < ( [^>]+ ) >)? \z/x;
      @{ $self->{ author } }{ qw( full_name email ) } = ( $full_name, $email // '' );
    }
  }

  # Derive variables from 'distname'
  # 'distname' is mandatory; lookup() would croak otherwise
  my @main_module_namespace = split /-/, $self->lookup( 'distname' );
  $self->{ main_module }         //= join '::', @main_module_namespace;
  $self->{ main_module_file }    //= catfile( 'lib', @main_module_namespace ) . '.pm';
  $self->{ main_module_podfile } //= catfile( 'lib', @main_module_namespace ) . '.pod';
  $self->{ abstract }            //= 'The great new ' . $self->{ main_module };
  unless ( defined $self->{ author } ) {
    ( $self->{ author }->{ full_name }, undef, undef, undef, my $email ) = split /,/, _gecos();
    unless ( defined $email and $email =~ m/\@/ ) {
      undef $email;
      $email = $ENV{ EMAIL } if exists $ENV{ EMAIL };
    }
    $self->{ author }->{ email } = $email // ''
  }

  $self
}

sub _gecos { ( getpwuid $> )[ 6 ] }

1
