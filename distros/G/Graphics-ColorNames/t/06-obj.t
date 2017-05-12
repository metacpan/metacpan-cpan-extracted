#!/usr/bin/perl

use strict;

use constant TEST_CASES => {
    "black"		    => 0x000000,
    "red"		    => 0xff0000,
    "green"		    => 0x00ff00,
    "blue"		    => 0x0000ff,
    "white"                 => 0xffffff,
  # some arbitrary colors added for testing the autoloaded color names
    "lavenderblush"	    => 0xfff0f5,
    "lavender_blush"	    => 0xfff0f5,
    "LavenderBlush"	    => 0xfff0f5,
    "LAVENDERBLUSH"	    => 0xfff0f5,
};

use Test::More;
use Test::Exception;

my $tests = TEST_CASES;

plan tests => 4 + (11 * (keys %$tests));

use_ok('Graphics::ColorNames', 2.1003, (qw(tuple2hex)));

my $rgb = Graphics::ColorNames->new(qw( X ));
ok(defined $rgb);
ok($rgb->isa('Graphics::ColorNames'));

{
    # This causes errors

    # local $TODO = "AutoLoading non-existent color method";
    dies_ok {
	$rgb->SomeNonExistentColor();
    } "SomeNonExistentColor should have failed";

}

foreach my $name (keys %$tests) {

  my $a = $rgb->hex($name, '0x');
  ok( $a =~ /^0x[0-9a-f]{6}$/i );
  ok( eval($a) == $tests->{$name}, "Testing color $name" );

  my $b = $rgb->hex($name, '#');
  ok( $b =~ /^\x23[0-9a-f]{6}$/i );

  my $c = $rgb->hex($name, "");
  ok( $c =~ /^[0-9a-f]{6}$/i );  

     $c = $rgb->hex($name);
  ok( $c =~ /^[0-9a-f]{6}$/i );  

  ok($rgb->$name eq $c);
  {
      local $TODO = "Handle the can() method";
      ok($rgb->can($name));
  }

  my $d = $rgb->rgb($name, ',');
  ok( $d =~ /^\d{1,3}(\,\d{1,3}){2}$/ );

  my @v = $rgb->rgb($name);
  ok( @v == 3 );

  ok( join(',', @v) eq $d );
  ok( tuple2hex(@v) eq $c );

}

