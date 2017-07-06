#!perl -T

use strict;
use warnings;
use Test::More;

use File::Temp qw(tempdir);

use Dir::Write::Rotate;

my $dir = tempdir(CLEANUP=>1);

sub empty_dir {
    my $dir = shift;
    opendir my($dh), $dir;
    while (my $e = readdir $dh) {
        next if $e eq '.' || $e eq '..';
        ($e) = $e =~ /(.*)/; # untaint
        unlink "$dir/$e";
    }
}

sub read_file {
    my $path = shift;
    local $/;
    open my $fh, "<", $path or die "Can't open $path: $!";
    ~~<$fh>;
}

subtest "max_size" => sub {
    my $dwr = Dir::Write::Rotate->new(
        path => $dir,
        max_size => 13,
        rotate_probability => 1,
    );
    $dwr->write("aaa");
    $dwr->write("bbb");
    $dwr->write("ccc");
    $dwr->write("ddd");
    $dwr->write("eee");
    my @f = glob "$dir/*";
    is(scalar(@f), 4);
    is(join(",", map {read_file($_)} @f), "bbb,ccc,ddd,eee");
};

subtest "max_files" => sub {
    empty_dir($dir);
    my $i = 0;
    my $dwr = Dir::Write::Rotate->new(
        path => $dir,
        max_files => 3,
        rotate_probability => 1,
        filename_sub => sub { ++$i },
    );
    $dwr->write("aaa");
    $dwr->write("bbb");
    $dwr->write("ccc");
    $dwr->write("ddd");
    $dwr->write("eee");
    my @f = glob "$dir/*";
    is(scalar(@f), 3);
    is(join(",", map {read_file($_)} @f), "ccc,ddd,eee");
};

subtest "max_age" => sub {
    empty_dir($dir);
    my $i = 0;
    my $dwr = Dir::Write::Rotate->new(
        path => $dir,
        max_age => 1,
        rotate_probability => 1,
        filename_sub => sub { ++$i },
    );
    $dwr->write("aaa");
    $dwr->write("bbb");
    $dwr->write("ccc");
    $dwr->write("ddd");
    sleep 2;
    $dwr->write("eee");
    my @f = glob "$dir/*";
    is(scalar(@f), 1);
    is(join(",", map {read_file($_)} @f), "eee");
};

done_testing;
