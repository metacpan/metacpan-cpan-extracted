#!/usr/bin/perl

use strict;
use warnings;
use Test::Most tests => 8+1;
use Test::Warnings;

use lib 't/lib';
use TestClass;

use Encode;

my $builder = Test::More->builder;
binmode $builder->output         , ":utf8";

my $latin1_test_file = "t/test_data/some_file_latin1.txt";

my $f_ref = TestClass->new( $latin1_test_file );
my $cmp = {%$f_ref};
$cmp->{fh} = ignore;
$cmp->{file} = "$cmp->{file}";

SKIP: {

    eval { require Path::Tiny; Path::Tiny->import("path"); };
    skip "Path::Tiny is not installed", 2 if $@;

    isa_ok my $f = path($latin1_test_file), "Path::Tiny";
    my $obj = TestClass->new($f);

    delete local $cmp->{filename} unless defined $cmp->{filename};
    delete local $cmp->{size} unless defined $cmp->{size};

    cmp_deeply(
        {%$f_ref},
        $cmp,
        "Path::Tiny"
    );

}

SKIP: {

    eval { require IO::All; IO::All->import("io"); };
    skip "IO::All is not installed", 2 if $@;

    isa_ok my $f = io($latin1_test_file), "IO::All";
    my $obj = TestClass->new($f);

    delete local $cmp->{filename} unless defined $cmp->{filename};
    delete local $cmp->{size} unless defined $cmp->{size};

    cmp_deeply(
        {%$f_ref},
        $cmp,
        "IO::All"
    );

}

SKIP: {

    eval { require Mojo::Path };
    skip "Mojo::Path is not installed", 2 if $@;

    isa_ok my $f = Mojo::Path->new($latin1_test_file), "Mojo::Path";
    my $obj = TestClass->new($f);

    delete local $cmp->{filename} unless defined $cmp->{filename};
    delete local $cmp->{size} unless defined $cmp->{size};

    cmp_deeply(
        {%$f_ref},
        $cmp,
        "Mojo::Path"
    );

}

## its already tested elsewhere but whattheheck
SKIP: {

    eval { require IO::File };

    skip "IO::File is not installed", 2 if $@;

    isa_ok my $f = IO::File->new($latin1_test_file), "IO::File";
    my $obj = TestClass->new($f);

    delete local $cmp->{filename} unless defined $cmp->{filename};
    delete local $cmp->{size} unless defined $cmp->{size};

    cmp_deeply(
        {%$f_ref},
        $cmp,
        "IO::File"
    );

}
