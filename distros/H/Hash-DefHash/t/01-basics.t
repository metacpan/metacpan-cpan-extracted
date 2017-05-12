#!perl

use 5.010;
use strict;
use warnings;

use Hash::DefHash;
use Scalar::Util qw(blessed);
use Test::Exception;
use Test::More 0.98;

subtest "check" => sub {
    my @ok = (
        {},
        {p=>1},
        {_=>1},
        {_prop1=>1},
        {Prop_=>1},
        {"p._"=>1},
        {"p._attr"=>1},
        {"p.a._"=>1},
        {"p.attr1"=>1},
        {"p.a_"=>1},
        {"p.a.b.c"=>1},
        {".a"=>1},
        {"._"=>1},
    );
    my @nok = (
        {""=>1},
        {"-"=>1},
        {"-foo"=>1},
        {" foo"=>1},
        {"0a"=>1},
        {"a b"=>1},
        {"a."=>1},
        {"a.b."=>1},
        {"."=>1},
        {".a."=>1},
        {"_Prop "=>1},
        {"_Prop ..."=>1},
        {"_.b "=>1},
        {"p._attr "=>1},
        {"p._attr ..."=>1},
        {"p._ "=>1},
        {"p.a._attr "=>1},
        {"p.a._attr ..."=>1},
        {"._ ..."=>1},
    );
    for (0..@ok-1) {
        lives_ok { Hash::DefHash->new($ok[$_]) } "checkok $_";
    }
    for (0..@nok-1) {
        dies_ok { Hash::DefHash->new($nok[$_]) } "checknok $_";
    }
    for (0..@nok-1) {
        lives_ok { Hash::DefHash->new($nok[$_], check=>0) } "nocheck $_";
    }
};

subtest "hash" => sub {
    my $h  = {a=>1, b=>2};
    my $dh = Hash::DefHash->new($h);
    my $h2 = $dh->hash;
    is_deeply($h2, $h, "content is the same ...");
    is_deeply("$h2", "$h", "... because it's the same object");
};

subtest "various 1" => sub {
    my %origh = (
        _ip => 1,
        p => 2,
        "p.a" => 3,
        "p._ia" => 4,
        "p.a.b" => 5,
        "p.a._ib" => 6,
        ".a" => 7,
        "._ia" => 8,
        ".a.b" => 9,
        ".a._ib" => 10,
        "p2.a" => 11,
    );
    my %h = %origh;
    my %ct = (
        p => {""=>2, a=>3, "a.b"=>5},
        p2 => {a=>11},
        "" => {a=>7, "a.b"=>9},
    );
    my $dh = Hash::DefHash->new(\%h);

    is_deeply({ $dh->contents }, \%ct, "contents")
        or diag explain { $dh->contents };

    is_deeply([ $dh->props ], [qw/p/], "props")
        or diag explain [ $dh->props ];

    is($dh->prop("p"), 2, "prop");
    dies_ok { $dh->prop("p2") } "prop (not found -> dies 1)";
    dies_ok { $dh->prop("p3") } "prop (not found -> dies 2)";

    is($dh->get_prop("p"), 2, "get_prop");
    ok(!defined($dh->get_prop("p2")), "get_prop (not found) 1");
    ok(!defined($dh->get_prop("p3")), "get_prop (not found) 2");

    ok( $dh->prop_exists("p") , "prop_exists 1");
    ok(!$dh->prop_exists("p2"), "prop_exists 2");
    ok(!$dh->prop_exists("p3"), "prop_exists 3");

    dies_ok  { $dh->add_prop("p" , -1) } "add_prop (already exists -> dies)";
    lives_ok { $dh->add_prop("p2", -2) } "add_prop p2";
    is($dh->prop("p2"), -2, "prop p2 added");

    ok(!defined($dh->set_prop("p3", -3)), "set_prop (not exists)");
    is($dh->prop("p3"), -3, "prop p3 added");
    is($dh->set_prop("p3", -4), -3, "set_prop (already exists)");
    is($dh->prop("p3"), -4, "prop p3 set");

    ok(!defined($dh->del_prop("p4")), "del_prop (not exists)");
    ok(!$dh->prop_exists("p4"), "prop p4 doesn't exist");
    is($dh->del_prop("p3"), -4, "del_prop (exists)");
    ok(!$dh->prop_exists("p3"), "prop p4 deleted");

    %h = %origh; $dh = Hash::DefHash->new(\%h);
    $dh->del_all_props;
    is_deeply($dh->hash, {
        "._ia"    => 8,
        ".a"      => 7,
        ".a._ib"  => 10,
        ".a.b"    => 9,
        "_ip"     => 1,
        "p._ia"   => 4,
        "p.a"     => 3,
        "p.a._ib" => 6,
        "p.a.b"   => 5,
        "p2.a"    => 11,
    }, "del_all_props")
        or diag explain $dh->hash;

    %h = %origh; $dh = Hash::DefHash->new(\%h);
    $dh->del_all_props(1);
    is_deeply($dh->hash, {
        "._ia"    => 8,
        ".a._ib"  => 10,
        "_ip"     => 1,
        "p._ia"   => 4,
        "p.a._ib" => 6,
    }, "del_all_props (delattrs=1)")
        or diag explain $dh->hash;

    %h = %origh; $dh = Hash::DefHash->new(\%h);

    is_deeply({ $dh->attrs() }, {
        "a" => 7,
        "a.b" => 9,
    }, "attrs hash")
        or diag explain { $dh->attrs };
    is_deeply({ $dh->attrs("p3") }, {
    }, "attrs (non existing prop)");
    is_deeply({ $dh->attrs("p") }, {
        "a" => 3,
        "a.b" => 5,
    }, "attrs p");

    is($dh->attr("p", "a"), 3, "attr 1");
    is($dh->attr("p", "a.b"), 5, "attr 2");
    dies_ok { $dh->attr("p3", "a") } "attr (unknown prop -> dies)";
    dies_ok { $dh->attr("p", "x") } "attr (unknown attr -> dies)";

    is($dh->get_attr("p", "a"), 3, "get_attr 1");
    is($dh->get_attr("p", "a.b"), 5, "get_attr 2");
    ok(!defined($dh->get_attr("p3", "a")), "get_attr (unknown prop)");
    ok(!defined($dh->get_attr("p", "x")), "get_attr (unknown attr)");

    ok( $dh->attr_exists("", "a")     , "attr_exists 1");
    ok( $dh->attr_exists("", "a.b")   , "attr_exists 2");
    ok(!$dh->attr_exists("", "x")     , "attr_exists 3");
    ok( $dh->attr_exists("p", "a")    , "attr_exists 4");
    ok( $dh->attr_exists("p", "a.b")  , "attr_exists 5");
    ok(!$dh->attr_exists("p", "x")    , "attr_exists 6");
    ok(!$dh->attr_exists("p3", "a")   , "attr_exists 7");

    dies_ok  { $dh->add_attr("p", "a", -1) }
        "add_attr (already exists -> dies) 1";
    dies_ok  { $dh->add_attr("", "a", -1) }
        "add_attr (already exists -> dies) 2";
    lives_ok { $dh->add_attr("p", "c", -2) } "add_attr p.c";
    is($dh->attr("p", "c"), -2, "attr p.c added");
    lives_ok { $dh->add_attr("", "c", -3) } "add_attr .c";
    is($dh->attr("", "c"), -3, "attr .c added");
    lives_ok { $dh->add_attr("p3", "c", -4) } "add_attr p3.c";
    is($dh->attr("p3", "c"), -4, "attr p3.c added");

    ok(!defined($dh->set_attr("p", "d", -1)), "set_attr p.d");
    is($dh->attr("p", "d"), -1, "p.d added");
    ok(!defined($dh->set_attr("", "d", -2)), "set_attr .d");
    is($dh->attr("", "d"), -2, ".d added");
    is($dh->set_attr("p", "a", -3), 3, "set_attr p.a");
    is($dh->attr("p", "a"), -3, "p.a set");
    is($dh->set_attr("", "a", -4), 7, "set_attr .a");
    is($dh->attr("", "a"), -4, ".a set");

    ok(!defined($dh->del_attr("p", "e")), "del_attr (not exists) 1");
    ok(!$dh->attr_exists("p", "e"), "attr p.e doesn't exist");
    is($dh->del_attr("p", "a"), -3, "del_attr (exists) 1");
    ok(!$dh->attr_exists("p", "a"), "attr p.a deleted");
    ok(!defined($dh->del_attr("", "e")), "del_attr (not exists) 2");
    ok(!$dh->attr_exists("", "e"), "attr .e doesn't exist");
    is($dh->del_attr("", "a"), -4, "del_attr (exists) 2");
    ok(!$dh->attr_exists("", "a"), "attr .a deleted");

    %h = %origh; $dh = Hash::DefHash->new(\%h);
    $dh->del_all_attrs("p");
    is_deeply({ $dh->attrs("p") }, {}, "del_all_attrs p")
        or diag explain { $dh->attrs("p") };
    $dh->del_all_attrs("");
    is_deeply({ $dh->attrs("") }, {}, "del_all_attrs hash");
    is_deeply({ $dh->attrs("p2") }, {a=>11}, "p2 attrs not deleted")
        or diag explain { $dh->attrs("p2") };

};

# XXX v
# XXX defhash_v
# XXX name
# XXX summary
# XXX description
# XXX tags

subtest "defhash" => sub {
    my $hash = {};
    my $dh  = defhash({});
    ok(blessed($dh), "defhash() creates defhash object");
    my $dh2 = defhash($dh);
    is("$dh2", "$dh", "given the defhash object, defhash() returns it");
};

subtest "lang" => sub {
    my ($dh1, $dh2, $dh3);

    local $ENV{LANG};

    $ENV{LANG} = "C";
    $dh1 = defhash({});
    is($dh1->default_lang, "en_US", "default_lang (from LANG)");
    $ENV{LANG} = "fr_CA";
    is($dh1->default_lang, "fr_CA", "default_lang (from LANG)");

    undef $ENV{LANG};

    $dh1 = defhash({
        default_lang=>"id_ID",
        summary=>"id1",
        "summary.alt.lang.en_US"=>"en1",
    });
    $dh2 = defhash({
        summary=>"id2",
        "summary.alt.lang.en_US"=>"en2",
    }, parent=>$dh1);
    $dh3 = defhash({
        summary=>"id3",
        "summary.alt.lang.en_US"=>"en3",
    }, parent=>$dh2);

    is($dh1->default_lang, "id_ID", "default_lang (set)");
    is($dh2->default_lang, "id_ID", "default_lang (from parent)");
    is($dh3->default_lang, "id_ID", "default_lang (from grandparent)");

    is($dh1->get_prop_lang("summary")        ,"id1", "get_prop_lang dh1");
    is($dh1->get_prop_lang("summary","en_US"),"en1", "get_prop_lang dh1,en_US");
    is($dh1->get_prop_lang("summary","id_ID"),"id1", "get_prop_lang dh1,id_ID");
    is($dh2->get_prop_lang("summary")        ,"id2", "get_prop_lang dh2");
    is($dh2->get_prop_lang("summary","en_US"),"en2", "get_prop_lang dh2,en_US");
    is($dh2->get_prop_lang("summary","id_ID"),"id2", "get_prop_lang dh2,id_ID");
    is($dh3->get_prop_lang("summary")       , "id3", "get_prop_lang dh3");
    is($dh3->get_prop_lang("summary","en_US"),"en3", "get_prop_lang dh3,en_US");
    is($dh3->get_prop_lang("summary","id_ID"),"id3", "get_prop_lang dh3,id_ID");
    is($dh3->get_prop_lang("summary","fr_FR"),"{id_ID id3}",
       "get_prop_lang dh3,fr_FR");

    $dh2->set_prop(default_lang => "en_US");
    is($dh1->default_lang, "id_ID", "default_lang (set) 2a");
    is($dh2->default_lang, "en_US", "default_lang (set) 2b");
    is($dh3->default_lang, "en_US", "default_lang (from parent) 2");
};

# XXX get_prop_all_langs()
# XXX set_prop_lang()

DONE_TESTING:
done_testing;
