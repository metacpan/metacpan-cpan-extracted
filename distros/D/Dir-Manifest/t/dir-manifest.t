#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 8;
use Dir::Manifest ();

use Socket qw(:crlf);

use Path::Tiny qw/ path tempdir tempfile cwd /;

{
    my $dir = tempdir();

    my $fh = $dir->child("list.txt");
    my $d  = $dir->child("texts");
    $d->mkpath;

    $fh->spew_utf8("f%%g\n");

    my $obj;
    my @keys;
    eval {
        $obj = Dir::Manifest->new(
            {
                manifest_fn => "$fh",
                dir         => "$d",
            }
        );

        @keys = @{ $obj->get_keys };
    };

    # TEST
    like(
        $@,
        qr/invalid characters in key.*f%%g/i,
        "Throws an exception on invalid characters.",
    );
    $fh->spew_utf8(".hidden\n");

    eval {
        $obj = Dir::Manifest->new(
            {
                manifest_fn => "$fh",
                dir         => "$d",
            }
        );

        @keys = @{ $obj->get_keys };
    };

    # TEST
    like(
        $@,
        qr/Key does not start with an alphanumeric.*\.hidden/i,
        "Throws an exception on invalid characters.",
    );

    $fh->spew_utf8("trail_dots...\n");

    eval {
        $obj = Dir::Manifest->new(
            {
                manifest_fn => "$fh",
                dir         => "$d",
            }
        );

        @keys = @{ $obj->get_keys };
    };

    # TEST
    like(
        $@,
        qr/Key does not end with an alphanumeric.*trail_dots\.\.\./i,
        "Throws an exception on invalid characters.",
    );

    $fh->spew_utf8("one\ntwo\nthree\n");
    my $key;

    eval {
        $obj = Dir::Manifest->new(
            {
                manifest_fn => "$fh",
                dir         => "$d",
            }
        );

        @keys = @{ $obj->get_keys };

        $key = $obj->get_obj("not_exist");
    };

    # TEST
    like(
        $@,
        qr/No such key.*not_exist/i,
        "Throws an exception on invalid characters.",
    );

    # TEST
    is_deeply( \@keys, [qw/one three two/], "get_keys worked.", );

    $fh->spew_utf8("one\ntwo\nthree\n");
    $d->child("one")->spew_utf8("sample text");
    $obj = Dir::Manifest->new(
        {
            manifest_fn => "$fh",
            dir         => "$d",
        }
    );

    @keys = @{ $obj->get_keys };

    $key = $obj->get_obj("one");

    # TEST
    is_deeply( $key->fh->slurp_utf8, "sample text", "slurp worked.", );

    # TEST
    is_deeply( $obj->text( "one", {} ), "sample text", "->text worked.", );

    $fh->spew_utf8("key1\nkey2.txt\nkey3.md");
    $d->child("key1")->spew_utf8("this is key1");
    $d->child("key2.txt")->spew_utf8("this is key2");
    $d->child("key3.md")->spew_utf8("this is key3");
    $obj = Dir::Manifest->new(
        {
            manifest_fn => "$fh",
            dir         => "$d",
        }
    );

    # TEST
    is_deeply(
        $obj->texts_dictionary( { slurp_opts => {}, } ),
        +{
            "key1"     => "this is key1",
            "key2.txt" => "this is key2",
            "key3.md"  => "this is key3"
        },
        "texts_dictionary worked.",
    );
}
