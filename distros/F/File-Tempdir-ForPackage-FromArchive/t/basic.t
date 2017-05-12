use strict;
use warnings;

use Test::More;
use File::Tempdir::ForPackage::FromArchive;

use FindBin;
use File::Find;
use Cwd;

my $corpus = "$FindBin::Bin/../corpus/";

for my $d (qw( tar_test.tar.gz zip_test.zip )) {
  subtest $d => sub {
    my $td = File::Tempdir::ForPackage::FromArchive->new(
      package => 't::File::Tempdir::ForPackage::FromArchive::' . $d,
      archive => $corpus . $d,
    );
    for my $i ( 0 .. 5 ) {
      $td->run_once_in(
        sub {
          pass(Cwd::getcwd);

          sub wanted {
            note($File::Find::name);
            return 1;
          }
          find( { wanted => \&wanted, follow => 0 }, '.' );
        }
      );
    }
  };
}

done_testing;
