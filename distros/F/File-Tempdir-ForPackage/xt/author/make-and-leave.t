use strict;
use warnings;

use Test::More tests => 1;

use File::Tempdir::ForPackage;

my $dir = File::Tempdir::ForPackage->new(
  package => 'File::Tempdir::ForPackage',

  #	with_version => 1,
  #	with_timestamp => 1,
  #	with_pid => 1,
  #	num_random => 4,
);

for my $i ( 0 .. 10 ) {
  $dir->run_once_in(
    sub {
      system 'find $PWD';
      $dir->preserve(1);
    }
  );
}
pass();
