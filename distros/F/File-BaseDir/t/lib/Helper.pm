package Helper;

use strict;
use warnings;
use File::Temp qw( tempdir );
use File::Path qw( mkpath );
use Test::More ();
use Exporter qw( import );

our @EXPORT_OK = qw( build_test_data );

sub build_test_data {
  my $root = tempdir( CLEANUP => 1 );

  my $dir = File::Spec->catdir($root, 't','data','dir');
  Test::More::note "mkpath $dir";
  mkpath($dir, 0, oct('0700'));

  foreach my $file (map { File::Spec->catfile($root, @$_) } ['t','data','test'], ['t','data','dir','test']) {
    Test::More::note "create $file";
    open my $fh, '>', $file or die "unable to write $file $!";
    print $fh "test 1 2 3\n";
    close $fh;
  }

  $root;
}

1;
