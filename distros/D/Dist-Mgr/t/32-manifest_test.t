use warnings;
use strict;
use Test::More;

use Data::Dumper;
use Dist::Mgr qw(:all);

use lib 't/lib';
use Helper qw(:all);

my $work = 't/data/work/manifest.t';
my $orig = 't/data/orig/manifest.t';

my $dir = 't/data/work';

unlink_manifest();

my @c = manifest_t($dir);

open my $o_fh, '<', $orig or die $!;
open my $w_fh, '<', $work or die $!;

my @o = <$o_fh>;
my @w = <$w_fh>;

close $o_fh;
close $w_fh;

for (0..$#w) {
    $w[$_] =~ s/[\r\n]//g;
    $o[$_] =~ s/[\r\n]//g;
    $c[$_] =~ s/[\r\n]//g;
    chomp $w[$_];
    chomp $o[$_];
    chomp $c[$_];

    is $w[$_], $c[$_], "new manifest.t line $_ matches return content";
    is $w[$_], $o[$_], "new manifest.t line $_ matches original file";
}

unlink_manifest();

done_testing;

