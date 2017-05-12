#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

my $bdir = 't/base/';
my $base = 't/base/child.log';
my $fn = 't/working/append.log';
my $parent = 't/working/parent.log';
my $f1 = 't/working/one.log';
my $f2 = 't/working/two.log';
my $f3 = 't/working/three.log';
my $f4 = 't/working/four.log';

my %files = (f1 => $f1, f2 => $f2, f3 => $f3, p => $parent);

{ # test append output

    open my $base_fh, '<', $base or die $!;
    open my $append_fh, '<', $fn or die $!;

    my @base = <$base_fh>;
    close $base_fh;
    my @append = <$append_fh>;
    close $append_fh;

    is (@base, @append, "appended file is same as base file");

    my $i = 0;
    for (@append){
        is ($_, $base[$i], "line $_ in parent/child append file ok");
        $i++;
    }
}

for (keys %files){
    my $fn = $files{$_};
    my $base = $fn;
    $base =~ s/working/base/;

    open my $bfh, '<', $base or die $!;
    open my $fh, '<', $fn or die $!;

    my @b_arr = <$bfh>;
    my @w_arr = <$fh>;
    close $bfh;
    close $fh;

    is (@b_arr, @w_arr, "$fn working copy has same num lines as base");

    my $i = 0;
    for (@w_arr){
        is ($_, $b_arr[$i], "line $_ in $fn file ok");
        $i++;
    }
}
for ($f1, $f2, $f3, $f4, $parent, $fn){
    unlink $_;
    ok (! -e $_, "$_ file unlinked ok");
}

is (rmdir 't/working', 1, "removed working dir ok");

done_testing();

