# Prefer numeric version for backwards compatibility
BEGIN { require 5.010000 }; ## no critic ( RequireUseStrict, RequireUseWarnings )
use strict;
use warnings;

#<<<
package
  Dist::Starter::Context;
#>>>

use File::Spec::Functions qw( catfile );
use YAML::Tiny            qw( Dump DumpFile LoadFile );

use Dist::Starter::Exception ();

my %registry = map { $_ => 1 } qw(
  abstract
  author.from
  author.full_name
  author.email
  git_base_url
  license
  main_module
  main_module_file
  main_module_podfile
  min_perl_version
  share.type
  share.dir
  share.MY
  share.Makefile
  share.deps.configure
  share.deps.runtime
);

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

  bless( LoadFile( $file ) // {}, $class )->_adjust_context( @_ )
}

sub lookup {
  my ( $self, $variable ) = @_;

  my $value = $self;
  for ( split /\./, $variable ) {
    unless ( defined( $value = $value->{ $_ } ) ) {
      die Dist::Starter::Exception->new( message => "Context does not know the variable '$variable'" )
        unless exists $registry{ $variable };
      last
    }
  }

  $value // ''
}

sub _adjust_context { ## no critic ( ProhibitExcessComplexity )
  my $self = shift;
  my %args;
  {
    use warnings FATAL => qw( misc uninitialized );
    %args = @_
  }
  die Dist::Starter::Exception->new( message => "'distname' parameter not specified" )
    unless exists $args{ distname };

  # Process 'args'
  for ( qw( abstract distname git_base_url initial_version license ) ) {
    $self->{ $_ } = $args{ $_ } if exists $args{ $_ };
  }

  if ( exists $args{ min_perl_version } ) {
    my $min_perl_version = $args{ min_perl_version };
    die Dist::Starter::Exception->new( message => "Invalid minimum perl version '$min_perl_version'" )
      unless $min_perl_version =~ qr/\A 5 \. \d{6} \z/x;
    $self->{ min_perl_version } = $min_perl_version
  }

  if ( exists $args{ share } ) {
    my $share_type = $args{ share }->{ type } // 'dist';
    die Dist::Starter::Exception->new( message => "Invalid share type '$share_type'" )
      unless $share_type =~ qr/\A (?: dist | module ) \z/x;
    $self->{ share }->{ type } = $share_type;
    $self->{ share }->{ dir }  = $args{ share }->{ dir } // 'share'
  }

  $self->{ author }->{ from } = $args{ author_from } if exists $args{ author_from };
  if ( exists $self->{ author } and exists $self->{ author }->{ from } ) {
    my $author_from = $self->{ author }->{ from };
    if ( $author_from eq 'FROM_GIT' ) {
      # Do not enclose qx() command string in spaces
      chomp( $self->{ author }->{ full_name } = qx(git config --global --get user.name) );
      chomp( $self->{ author }->{ email }     = qx(git config --global --get user.email) )
    } elsif ( $author_from eq 'FROM_ENV' ) {
      for ( qw( full_name email ) ) {
        $self->{ author }->{ $_ } = $ENV{ +uc }
      }
    } elsif ( $author_from eq 'FROM_GECOS' ) {
      # Use below global default algorithm
      delete $self->{ author }
    } else {
      die Dist::Starter::Exception->new( message => "Cannot parse author '$author_from'" )
        unless my ( $full_name, $email ) = $author_from =~ m/\A ( [^<@]+? ) (?:\ * < ( [^>]+ ) >)? \z/x;
      @{ $self->{ author } }{ qw( full_name email ) } = ( $full_name, $email // '' );
    }
  }

  # Set global defaults
  my @main_module_namespace = split /-/, $self->{ distname };
  # Derive variables from 'distname'
  $self->{ main_module }         //= join '::', @main_module_namespace;
  $self->{ main_module_file }    //= catfile( 'lib', @main_module_namespace ) . '.pm';
  $self->{ main_module_podfile } //= catfile( 'lib', @main_module_namespace ) . '.pod';
  $self->{ abstract }            //= 'The great new ' . $self->{ main_module };
  unless ( defined $self->{ author } ) {
    $self->{ author }->{ from } = 'FROM_GECOS';
    ( $self->{ author }->{ full_name }, undef, undef, undef, my $email ) = split /,/, _gecos();
    unless ( defined $email and $email =~ m/\@/ ) {
      undef $email;
      $email = $ENV{ EMAIL } if exists $ENV{ EMAIL };
    }
    $self->{ author }->{ email } = $email if defined $email;
  }
  $self->{ initial_version }  //= 'v0.1.0';
  $self->{ license }          //= 'perl_5';
  $self->{ min_perl_version } //= '5.010000';
  if ( defined( my $share = $self->{ share } ) ) {
    my $share_type = $share->{ type };
    my $share_dir = $share->{ dir };
    $share->{ MY } = <<'EOF';
$make_fragment .= join "\n", '', File::ShareDir::Install::postamble( $self )
    if is_loaded 'File::ShareDir::Install';
EOF
    $share->{ Makefile } = <<"EOF";
require File::ShareDir::Install;
  no warnings qw( once );
  \$File::ShareDir::Install::INCLUDE_DOTFILES = 1;
  mkdir '$share_dir' unless -d '$share_dir';
  File::ShareDir::Install::install_share( ${ \( $share_type eq 'dist' ? "$share_type => '$share_dir'" : "$share_type => \$main_module => '$share_dir'" ) } );
EOF
    $share->{ deps }->{ configure } = "requires 'File::ShareDir::Install' => '0';";
    $share->{ deps }->{ runtime }   = "requires 'File::ShareDir::Tiny' => '0';"
  }

  $self
}

sub _gecos { ( getpwuid $> )[ 6 ] }

1
