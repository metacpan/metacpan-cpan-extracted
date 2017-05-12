package Test::SyntheticModule;

use strict;
use warnings;
use Carp;
use File::Temp qw/tempdir/;
use File::Path;
use File::Spec;

use base qw(Exporter);
use vars qw(@EXPORT_OK $VERSION);
@EXPORT_OK = qw( make_module_name make_module );
$VERSION   = '0.0.1';

my $base_dir;
my $next_module = 'AAAAAAAA';

BEGIN {
  $base_dir = tempdir();
  # Include our temp directory in @INC
  unshift @INC, $base_dir;
}

sub make_module_name {
  return 'Synthetic::' . $next_module++;
}

sub _make_file_name {
  return File::Spec->catfile( $base_dir, split( /::/, $_[0] . '.pm' ) );
}

sub _dirname {
  my ( $v, $d, undef ) = File::Spec->splitpath( $_[0] );
  return File::Spec->catpath( $v, $d, '' );
}

sub make_module {
  my ( $src, $name ) = @_;
  $name = make_module_name() unless defined $name;
  my $file = _make_file_name( $name );

  my @src = 'ARRAY' eq ref $src ? @$src : ( $src );
  unshift @src, "package $name;";
  push @src, "1;";

  mkpath( _dirname( $file ) );

  # Write the module
  open my $mh, '>', $file or croak "Can't write $file ($!)\n";
  print $mh join( "\n", @src ), "\n";
  close $mh;

  return wantarray ? ( $name, $file ) : $name;
}

END {
  rmtree( $base_dir ) if defined $base_dir;
}

1;
