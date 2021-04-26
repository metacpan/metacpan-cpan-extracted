#!perl

use strict;
use warnings;
use Test::More 0.98;

use File::SortedSeek::PERLANCAR qw(binsearch numeric alphabetic);
use File::Temp qw(tempdir);

my $dir = tempdir();
note "tempdir=$dir";
{ open my $fh, ">", "$dir/numeric"   ; for (1..10) { print $fh "$_\n" } }
{ open my $fh, ">", "$dir/alphabetic"; for ("a".."z") { print $fh "$_\n" } }
{ open my $fh, ">", "$dir/len"; for (1..10) { print $fh (chr(107-$_) x $_) . "\n" } }

subtest "numeric" => sub {
    open my $fh, "<", "$dir/numeric";

    subtest "no cuddle" => sub {
        for my $x (1..10) {
            my $tell = numeric($fh, $x);
            # diag "x=$x, tell=$tell"; # 1=0, 2=2, 3=4, ..., 8=14, 9=16, 10=18
            chomp(my $res = <$fh>);
            is($res, $x);
            ok(File::SortedSeek::PERLANCAR::was_exact());
        }
        my $tell;

        $tell = numeric($fh, 0);
        is_deeply($tell, 0);
        $tell = numeric($fh, 11);
        is_deeply($tell, undef);

        for my $x (reverse 1..10) {
            numeric($fh, $x);
            chomp(my $res = <$fh>);
            is($res, $x);
            ok(File::SortedSeek::PERLANCAR::was_exact());
        }
    };

    subtest "cuddle" => sub {
        #require File::SortedSeek;

        File::SortedSeek::PERLANCAR::set_cuddle();

        my $tell;

        $tell = numeric($fh, 0);
        is_deeply($tell, 0);
        ok(!File::SortedSeek::PERLANCAR::was_exact());

        $tell = numeric($fh, 10);
        is_deeply($tell, undef); # not cuddled between two lines

        $tell = numeric($fh, 11);
        is_deeply($tell, undef);

        File::SortedSeek::PERLANCAR::set_no_cuddle();
    };

    subtest "minoffset & maxoffset args" => sub {
        for my $x (2..7) {
            numeric($fh, $x, undef, 2, 13);
            chomp(my $res = <$fh>); is($res, $x);
            ok(File::SortedSeek::PERLANCAR::was_exact());
        }
        my $tell;

        $tell = numeric($fh, 1, undef, 2, 13);
        #diag "x=1, tell=$tell";
        is_deeply($tell, 2);
        ok(!File::SortedSeek::PERLANCAR::was_exact());

        $tell = numeric($fh, 8, undef, 2, 13);
        #diag "x=8, tell=$tell";
        is_deeply($tell, undef);
        ok(!File::SortedSeek::PERLANCAR::was_exact());

        chomp(my $res = <$fh>); is_deeply($res, 8);
    };

    subtest "minoffset & maxoffset args + cuddle" => sub {
        File::SortedSeek::PERLANCAR::set_cuddle();

        for my $x (2..7) {
            numeric($fh, $x, undef, 2, 13);
            chomp(my $res = <$fh>); is($res, $x);
        }
        my $tell;

        $tell = numeric($fh, 1, undef, 2, 13);
        #diag "x=1, tell=$tell";
        is_deeply($tell, 2);
        ok(!File::SortedSeek::PERLANCAR::was_exact());

        $tell = numeric($fh, 8, undef, 2, 13);
        #diag "x=8, tell=$tell";
        is_deeply($tell, undef);
        ok(!File::SortedSeek::PERLANCAR::was_exact());

        File::SortedSeek::PERLANCAR::set_no_cuddle();
    };
};

subtest "alphabetic" => sub {
    open my $fh, "<", "$dir/alphabetic";
    for my $x ("a".."z") {
        alphabetic($fh, $x);
        chomp(my $res = <$fh>);
        is($res, $x);
    }
    for my $x (reverse "a".."z") {
        alphabetic($fh, $x);
        chomp(my $res = <$fh>);
        is($res, $x);
    }
};

subtest "binsearch" => sub {
    open my $fh, "<", "$dir/len";
    for my $x (1..10) {
        binsearch($fh, $x, sub { length($_[0]) <=> $_[1] });
        #note "tell(\$fh) = ", tell($fh);
        chomp(my $res = <$fh>);
        is($res, chr(107-$x) x $x);
    }
};

done_testing;
