#!/usr/bin/perl
use lib "lib", "t";
use MIME::Lite;
use Test::More;
use Utils;

$MIME::Lite::VANILLA  = 1;
$MIME::Lite::PARANOID = 1;

# Pairs:
my @pairs = (
    ['  me@myhost.com      ',
    1,
    '<me@myhost.com>'],

    ['  mylogin      ',
    1,
    '<mylogin>'],

    ['   "Me, Jr." <  me@myhost.com >  ',
    1,
    '<me@myhost.com>'],

    ['  Me   <me@myhost.com>',
    1,
    '<me@myhost.com>'],

    ['"Me, Jr." <me@myhost.com>',
    1,
    '<me@myhost.com>'],

    ['"Me@somewhere.com, Jr." <me@myhost.com>',
    1,
    '<me@myhost.com>'],

    ['me@myhost.com,you@yourhost.com',
    2,
    '<me@myhost.com> <you@yourhost.com>'],

    ['"Me" <me@myhost.com>, "You"<you@yourhost.com>',
    2,
    '<me@myhost.com> <you@yourhost.com>'],

    ['"Me" <me@myhost.com>, you@yourhost.com, "And also" <she@herhost.com>',
    3,
    '<me@myhost.com> <you@yourhost.com> <she@herhost.com>'],

    ['"Me" <me@myhost.com>, mylogin  ,yourlogin  , She <she@herhost.com>',
    4,
    '<me@myhost.com> <mylogin> <yourlogin> <she@herhost.com>']
);

plan tests => 2 * @pairs;

# New:
foreach my $pair (@pairs) {
  my ($to, $count, $result) = @$pair;
  my @addrs = MIME::Lite::extract_only_addrs($to);

  is(@addrs, $count, "as many addrs as expected");

  is(
    join(' ', map {"<$_>"} @addrs),
	  $result,
	  "addrs stringify together as expected",
  );
}
