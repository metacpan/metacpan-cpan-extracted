use warnings;
use strict;
use Test::More;

use Data::Dumper;
use Dist::Mgr qw(:all);

use lib 't/lib';
use Helper qw(:all);

my $work = 't/data/work/MANIFEST.SKIP';
my $orig = 't/data/orig/MANIFEST.SKIP';

my $dir = 't/data/work';

unlink_manifest_skip();

my @c = manifest_skip($dir);

open my $o_fh, '<', $orig or die $!;
open my $w_fh, '<', $work or die $!;

my @o = <$o_fh>;
my @w = <$w_fh>;

close $o_fh;
close $w_fh;

for (0..$#w) {
    chomp $w[$_];
    chomp $o[$_];
    chomp $c[$_];

    is $w[$_], $c[$_], "new manifest.skip line $_ matches return content";
    is $w[$_], $o[$_], "new manifest.skip line $_ matches original file";
}

unlink_manifest_skip();

done_testing;

