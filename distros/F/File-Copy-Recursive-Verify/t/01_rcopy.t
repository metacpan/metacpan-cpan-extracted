use strict;
use warnings;

use Test::More tests => 2;
use Path::Tiny;
use Try::Tiny;
use Test::Exception;

use File::Copy::Recursive::Verify qw(rcopy);

my $src_dir = Path::Tiny->tempdir();
my $subdir = $src_dir->child('subdir');
$subdir->mkpath();
$subdir->child('a')->spew('a');
$subdir->child('b')->spew('b');
$src_dir->child('c')->spew('c');

subtest 'default rcopy' => sub {
    my $dst_dir = Path::Tiny->tempdir();

    rcopy($src_dir, $dst_dir);
    
    is($dst_dir->child('subdir')->child('a')->slurp(), 'a', 'subdir/a');
    is($dst_dir->child('subdir')->child('b')->slurp(), 'b', 'subdir/b');
    is($dst_dir->child('c')->slurp(),                  'c', 'c');

    done_testing(3);
};

subtest 'rcopy options' => sub {
    my $dst_dir = Path::Tiny->tempdir();

    throws_ok {
        rcopy($src_dir, $dst_dir, { src_hash => { 'subdir/b' => '0' x 32 }, tries => 0 });
    }
    qr/isn't equal/, 'fake src_hash';

    throws_ok {
        rcopy($src_dir, $dst_dir, { dst_hash => { 'subdir/b' => '0' x 32 }, tries => 0 });
    }
    qr/isn't equal/, 'fake dst_hash';

    lives_ok {
        rcopy(
            $src_dir, $dst_dir,
            {
                src_hash => { 'subdir/b' => '0' x 32 },
                dst_hash => { 'subdir/b' => '0' x 32 },
                tries    => 0
            }
        );
    }
    'src and dst hash';

    done_testing(3);
};
