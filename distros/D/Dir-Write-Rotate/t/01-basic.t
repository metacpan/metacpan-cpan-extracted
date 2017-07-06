#!perl -T

use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;
#use Test::Needs;

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

subtest "argument checking" => sub {
    dies_ok { Dir::Write::Rotate->new() } "missing required argument -> dies";
    dies_ok { Dir::Write::Rotate->new(path => $dir, foo=>1) }
        "unknown argument -> dies";
};

subtest "basics" => sub {
    my $dwr = Dir::Write::Rotate->new(path => $dir);
    $dwr->write("foo");
    $dwr->write("bar");
    my @f = glob "$dir/*";
    is(scalar(@f), 2);
    is(read_file($f[0]), "foo");
    is(read_file($f[1]), "bar");

    for (@f) {
        like($_, qr!^.+/\d{4}-\d{2}-\d{2}-\d{2}\d{2}\d{2}\.pid-$$\.\w+(\.\d+)?$!,);
    }
};

subtest "filename_pattern" => sub {
    empty_dir($dir);
    my $dwr = Dir::Write::Rotate->new(
        path => $dir,
        filename_pattern => "file",
    );
    $dwr->write("foo");
    $dwr->write("bar");
    my @f = glob "$dir/*";
    is_deeply(\@f, ["$dir/file", "$dir/file.1"]);
};

subtest "filename_pattern: %{ext}" => sub {
    #test_needs "File::LibMagic";
    #test_needs "Media::Type::Simple";
    plan skip_all => "File::LibMagic / Media::Type::Simple not available"
        unless eval { require File::LibMagic; require Media::Type::Simple; 1 };

    empty_dir($dir);
    my $dwr = Dir::Write::Rotate->new(
        path => $dir,
        filename_pattern => "file.%{ext}",
    );
    $dwr->write("<html>hello, world</html>");
    my @f = glob "$dir/*";
    is_deeply(\@f, ["$dir/file.html"]);
};

subtest "filename_sub" => sub {
    empty_dir($dir);
    my $dwr = Dir::Write::Rotate->new(
        path => $dir,
        filename_sub => sub { my ($self, $content) = @_; "$content.txt" },
    );
    $dwr->write("bar");
    $dwr->write("foo");
    my @f = glob "$dir/*";
    is_deeply(\@f, ["$dir/bar.txt", "$dir/foo.txt"]);
};

done_testing;
