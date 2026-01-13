package Env::Dot::Test::Utils;
use strict;
use warnings;
use 5.010;

use Carp;
use Cwd qw( abs_path );
use Exporter 'import';
use FileHandle ();
use File::Path qw( make_path );
use File::Spec ();
use File::Temp ();

our @EXPORT_OK = qw(
  create_test_file
);
our %EXPORT_TAGS = (
    'all' => [
        qw(
          create_test_file
        )
    ],
);

my ( $dir, $dir_path );

sub create_test_file {
    my ( $dirs, $fn, $content, $args ) = @_;
    $dir = File::Temp->newdir(
        TEMPLATE => 'temp-envassert-test-XXXXX',
        CLEANUP  => $args->{'cleanup'} // 1,
        DIR      => File::Spec->tmpdir,
    );
    $dir_path = abs_path( $dir->dirname );
    make_path( File::Spec->catdir( $dir_path, @{$dirs} ) );

    my $fh = FileHandle->new( File::Spec->catfile( $dir_path, @{$dirs}, $fn ), 'w' );
    print {$fh} $content or croak;
    $fh->close;

    return $dir, $dir_path;
}

1;
