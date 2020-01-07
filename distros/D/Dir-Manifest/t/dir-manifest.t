#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 14;
use Dir::Manifest ();

use Socket qw(:crlf);

use Path::Tiny qw/ path tempdir tempfile cwd /;

{
    my $dir = tempdir();

    my $dwim_create = sub {
        return Dir::Manifest->dwim_new(
            {
                base => "$dir",
            }
        );
    };

    my $fh         = $dir->child("list.txt");
    my $d          = $dir->child("texts");
    my $create_obj = sub {
        return Dir::Manifest->new(
            {
                manifest_fn => "$fh",
                dir         => "$d",
            }
        );
    };

    $d->mkpath;

    $fh->spew_utf8("f%%g\n");

    my $obj;
    my @keys;
    eval {
        $obj  = $create_obj->();
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
        $obj  = $create_obj->();
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
        $obj  = $create_obj->();
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
        $obj  = $create_obj->();
        @keys = @{ $obj->get_keys };
        $key  = $obj->get_obj("not_exist");
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
    $obj  = $create_obj->();
    @keys = @{ $obj->get_keys };
    $key  = $obj->get_obj("one");

    # TEST
    is_deeply( $key->fh->slurp_utf8, "sample text", "slurp worked.", );

    # TEST
    is_deeply( $obj->text( "one", {} ), "sample text", "->text worked.", );

    $fh->spew_utf8("key1\nkey2.txt\nkey3.md");
    $d->child("key1")->spew_utf8("this is key1");
    $d->child("key2.txt")->spew_utf8("this is key2");
    $d->child("key3.md")->spew_utf8("this is key3");

    $obj = $create_obj->();

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

    # TEST
    is_deeply(
        $dwim_create->()->texts_dictionary( { slurp_opts => {}, } ),
        +{
            "key1"     => "this is key1",
            "key2.txt" => "this is key2",
            "key3.md"  => "this is key3"
        },
        "dwim_new() constructor worked.",
    );

    $obj->add_key(
        {
            key      => "added_key",
            utf8_val => "added_key value[]",
        }
    );

    # TEST
    is_deeply(
        $obj->texts_dictionary( { slurp_opts => {}, } ),
        +{
            "added_key" => "added_key value[]",
            "key1"      => "this is key1",
            "key2.txt"  => "this is key2",
            "key3.md"   => "this is key3"
        },
        "add_key() has added the key - texts_dictionary().",
    );

    # TEST
    is_deeply(
        scalar( $d->child("added_key")->slurp_utf8 ),
        "added_key value[]",
        "add_key() has added the key - file system.",
    );

    $obj->remove_key( { key => "key1" } );

    # TEST
    is_deeply(
        $obj->texts_dictionary( { slurp_opts => {}, } ),
        +{
            "added_key" => "added_key value[]",
            "key2.txt"  => "this is key2",
            "key3.md"   => "this is key3"
        },
        "remove_key() has removed the key - texts_dictionary().",
    );

    # TEST
    ok(
        scalar( !-e $d->child("key1") ),
        "remove_key() has removed the key - file not exists.",
    );
    {
        my $new_obj = $create_obj->();

        # TEST
        is_deeply(
            $new_obj->texts_dictionary( { slurp_opts => {}, } ),
            +{
                "added_key" => "added_key value[]",
                "key2.txt"  => "this is key2",
                "key3.md"   => "this is key3"
            },
            "remove_key() has removed the key - in a new obj from the FS.",
        );
    }
}
