#!/bin/perl

use strict;
use warnings;

use Test::More;
use if $ENV{AUTHOR_TESTING} || $ENV{RELEASE_TESTING}, 'Test::Warnings';

use_ok("Media::Type::Simple");

can_ok("Media::Type::Simple",
  qw( is_type alt_types ext_from_type ext3_from_type is_ext type_from_ext add_type ));

ok(is_type("image/jpeg"), "is_type");

ok(!is_type("image/wxyz-foobar"), "is_type");
ok(!is_type("image/"), "is_type - false if no subtype provided");
ok(!is_type("image"), "is_type - false when only type provided");
ok(!is_type(""), "is_type - empty string returns false");

my @as = alt_types("image/jpeg");
is_deeply(\@as, [qw( image/jpeg image/pipeg image/pjpeg )], "alt_types");

@as = alt_types("application/x-rtf");
is_deeply(\@as, [qw( application/rtf text/rtf )], "alt_types");

@as = alt_types("image/rgb");
is_deeply(\@as, [qw( image/x-rgb )], "alt_types");

@as = alt_types("model/dwg");
is_deeply(\@as, [qw( image/vnd.dwg )], "alt_types");

my @es = ext_from_type("image/jpeg");
is_deeply(\@es, [qw( jpeg jpg jpe jfif )], "array ext_from_type");

my $e = ext_from_type("image/jpeg");
is($e, "jpeg", "scalar ext_from_type");

@es = ext3_from_type("image/jpeg");
is_deeply(\@es, [qw( jpg jpe )], "array ext3_from_type");

$e = ext3_from_type("image/jpeg");
is($e, "jpg", "scalar ext3_from_type");

ok(is_ext("jpeg"), "is_ext");
ok(!is_ext(""), "is_ext - empty string returns false");

my @ts = type_from_ext("jpeg");
is_deeply(\@ts, [qw( image/jpeg image/pipeg image/pjpeg )], "array type_from_ext");

{
  local $TODO = "option to allow no extensions enabled";

  ok(is_type("application/http"), "is_type");
  @es = ext_from_type("application/http");
  is_deeply(\@es, [ ], "ext_from_type empty");
}

my $t = type_from_ext("jpeg");
is($t, "image/jpeg", "scalar type_from_ext");

{
	my $o = Media::Type::Simple->new();

	ok($o->isa("Media::Type::Simple"), "isa");

	ok($o->is_type("image/jpeg"), "is_type (oo)");

	ok(!$o->is_type("image/wxyz-foobar"), "is_type");

	my @as = $o->alt_types("image/jpeg");
	is_deeply(\@as, [qw( image/jpeg image/pipeg image/pjpeg )], "alt_types");

	my @es = $o->ext_from_type("image/jpeg");
	is_deeply(\@es, [qw( jpeg jpg jpe jfif )], "array ext_from_type");

	$e = $o->ext_from_type("image/jpeg");
	is($e, "jpeg", "scalar ext_from_type");

	@es = $o->ext3_from_type("image/jpeg");
	is_deeply(\@es, [qw( jpg jpe )], "array ext3_from_type");

	$e = $o->ext3_from_type("image/jpeg");
	is($e, "jpg", "scalar ext3_from_type");

	ok($o->is_ext("jpeg"), "is_ext");

	my @ts = $o->type_from_ext("jpeg");
	is_deeply(\@ts, [qw( image/jpeg image/pipeg image/pjpeg )], "array type_from_ext");

	my $t = $o->type_from_ext("jpeg");
	is($t, "image/jpeg", "scalar type_from_ext");


	$o->add_type("image/wxyz-foobar", "foobar", "foo", "bar");

  	ok($o->is_type("image/wxyz-foobar"), "add_type");
  	ok(!is_type("image/wxyz-foobar"), "add_type is safe");

	@es = $o->ext_from_type("image/wxyz-foobar");
	is_deeply(\@es, [qw( foobar foo bar )], "array ext_from_type");

	$o->add_type("image/jpeg", "jpeg_file");
	@es = $o->ext_from_type("image/jpeg");
	is_deeply(\@es, [qw( jpeg jpg jpe jfif jpeg_file )], "add_exten");


        ok my $c = $o->clone, 'clone';

	ok($c->isa("Media::Type::Simple"), "isa");
}

done_testing;
