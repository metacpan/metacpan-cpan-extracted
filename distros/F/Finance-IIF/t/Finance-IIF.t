#!/usr/bin/perl
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Finance-IIF.t'

use strict;
use warnings;
use Test::More tests => 32;
use File::Temp;

BEGIN { use_ok("Finance::IIF") or exit; }

my $package  = "Finance::IIF";
my $testfile = "t/sample.iif";

{    # new
    can_ok( $package, qw(new) );

    my $obj = $package->new;
    isa_ok( $obj, $package );

    is( $obj->{debug},           0,    "default debug value" );
    is( $obj->{autodetect},      0,    "default autodetect value" );
    is( $obj->{field_separator}, "\t", "default field separator" );
    is( $obj->record_separator,  $/,   "default record separator" );

    $obj = $package->new(
        debug            => 1,
        field_separator  => ",",
        record_separator => "X\rX\n",
    );

    is( $obj->{debug},           1,        "custom debug value" );
    is( $obj->{field_separator}, ",",      "custom field separator" );
    is( $obj->record_separator,  "X\rX\n", "custom record separator" );
}

{    # autodetect
    my ( $fh, $obj );

    $fh = File::Temp->new;
    $fh->close;

    $obj = $package->new( file => $fh->filename, autodetect => 1 );
    is( $obj->record_separator, $/, "autodetect default record separator" );

    $fh = File::Temp->new;
    print( $fh "Testing Windows\r\n" );
    $fh->close;

    $obj = $package->new( file => $fh->filename, autodetect => 1 );
    is( $obj->record_separator, "\r\n", "autodetect windows record separator" );

    $fh = File::Temp->new;
    print( $fh "Testing Mac\r" );
    $fh->close;

    $obj = $package->new( file => $fh->filename, autodetect => 1 );
    is( $obj->record_separator, "\r", "autodetect mac record separator" );

    $fh = File::Temp->new;
    print( $fh "Testing Unix\n" );
    $fh->close;

    $obj = $package->new( file => $fh->filename, autodetect => 1 );
    is( $obj->record_separator, "\n", "autodetect unix record separator" );
}

{    # file
    can_ok( $package, qw(file) );

    my $obj = $package->new;

    is( $obj->file, undef, "file undef by default" );
    is( $obj->file($testfile), $testfile, "file with one arg" );
    is( $obj->file( $testfile, "<" ), $testfile, "file with two args" );

    $obj = $package->new( file => $testfile );
    is( $obj->file, $testfile, "new with scalar file argument" );

    $obj = $package->new( file => [ $testfile, "<:crlf" ] );
    is( $obj->file, $testfile, "new with arrayref file argument" );

    is_deeply( [ $obj->file( 1, 2 ) ], [ 1, 2 ], "file returns list" );
}

{    # croak checks for: _filehandle next _getline reset close
    my @methods = qw(_filehandle next _getline reset close);
    can_ok( $package, @methods );

    foreach my $method (@methods) {
        my $obj = $package->new;
        eval { $obj->$method };
        like(
            $@,
            qr/^No filehandle available/,
            "$method without a filehandle croaks"
        );
    }
}

{    # open
    can_ok( $package, qw(open) );

    my $obj = $package->new;
    eval { $obj->open };
    like( $@, qr/^No file specified/, "open without a file croaks" );

    $obj = $package->new;
    eval { $obj->open($testfile) };
    is( $@, "", "open with file does not die" );
}

{    # _parseline
    can_ok( $package, qw(_parseline) );
}

{    # _warning
    can_ok( $package, qw(_warning) );
}
