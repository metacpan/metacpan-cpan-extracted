#!/usr/local/bin/perl
#
# $Id: 04-LJN.t,v 0.3 2005/08/18 07:16:13 dankogai Exp $
#
use strict;
use Test::More tests => 7;
my $can;
BEGIN { use_ok('Lingua::JA::Numbers'); };
$can = main::->can('to_string');
ok(!$can, "to_string() not imported yet");
Lingua::JA::Numbers->import(qw/to_string/);
$can = main::->can('to_string');
ok($can, "to_string() now imported");

my %n2r = (
         1234 => "sen ni hyaku san juu yon",
         3300 => "san-zen san-byaku",
         8800 => "ha-s-sen ha-p-pyaku",
    6_000_000 => "ro-p-pyaku man",
);
for my $k (keys %n2r){
    my $romaji = join(" ", to_string($k));
    is($romaji, $n2r{$k}, qq/to_string($k) eq $n2r{$k}/);
}
__END__
