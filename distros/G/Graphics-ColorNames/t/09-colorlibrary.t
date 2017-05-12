#!/usr/bin/perl

use strict;
use Test::More;

eval "use Color::Library 0.02";

plan skip_all => "Color::Library 0.02 required" if $@;

use constant TEST_CASES => {
  "croceus"                   => 0xf4c2c2,
  "croceus28"                 => 0xf4c2c2,
  "croceus53"                 => 0xd99058,
#     "black"                 => 0x000000,
#     "aqua"                  => 0x00ffff,
#     "maroon"                => 0x800000,
#     "lime"                  => 0x00ff00,
};

my $tests = TEST_CASES;

plan tests => 3 + (keys %$tests);

use_ok("Graphics::ColorNames", "2.10002");

use_ok("Color::Library::Dictionary::NBS_ISCC::B");

{
    my $obj = Graphics::ColorNames->new( 'Color::Library::Dictionary::NBS_ISCC::B' );
    ok ($obj->isa("Graphics::ColorNames"));

    foreach my $name (keys %$tests) {
	ok($obj->hex($name) eq sprintf('%06x',$tests->{$name}), 
	   "failed test for color $name");
    }

}
