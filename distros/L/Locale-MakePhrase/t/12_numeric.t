#!/usr/local/bin/perl

use strict;
use warnings;
use Test;
BEGIN { plan tests => 3 };

use Locale::MakePhrase::Numeric qw(
  stringify
);
ok(1);

$Locale::MakePhrase::Numeric::DEBUG = 0;

my $format = Locale::MakePhrase::Numeric->DOT;
my $precision = 0;
my $options = {
  numeric_format => $format,
  precision => 0,
};

ok(Locale::MakePhrase::Numeric->stringify('1',$options) eq '1') or print "Bail out! Serious problem with the stringify_number() function.\n";
ok(Locale::MakePhrase::Numeric->stringify(1.0001,$options) eq '1') or print "Bail out! Precision control problem.\n";



