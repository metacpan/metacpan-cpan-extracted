use strict;
use warnings;
use Test::More;
use File::Temp qw/tempdir/;
use File::Spec;
use File::Stamped;
use File::Basename;

my $dir = tempdir(CLEANUP => 1);
my $pattern = File::Spec->catdir($dir, 'foo.%Y%m%d%H%M%S.log');

my $f = File::Stamped->new(
    pattern => $pattern,
    rotationtime => 3,
);

my $f1 = $f->_gen_filename();
ok($f1);

sleep 3;

my $f2 = $f->_gen_filename();
ok($f2);
ok($f1 ne $f2);

done_testing;

