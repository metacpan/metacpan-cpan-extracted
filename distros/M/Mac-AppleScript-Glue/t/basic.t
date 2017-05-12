#!/usr/bin/perl -w

# vim: set filetype=perl :

use strict;

use Test;

BEGIN { plan tests => 6 };

use Mac::AppleScript::Glue qw(is_number);

##;;$Mac::AppleScript::Glue::Debug{RESULT} = 1;
##;;$Mac::AppleScript::Glue::Debug{SCRIPT} = 1;

######################################################################

my @good_nums = qw(0 12 .1 1.0 0.1 -1 +5 7.5e3);
my @bad_nums = qw(17i 5.5.5 x x0 0x);

for (@good_nums) {
    if (!is_number($_)) {
        ok(0);
        warn "number \"$_\" failed to validate\n";
    }
}

for (@bad_nums) {
    if (is_number($_)) {
        ok(0);
        warn "number \"$_\" was expected to fail to validate, but succeeded\n";
    }
}

ok(1);

######################################################################

my $glue = new Mac::AppleScript::Glue;

ok(defined $glue)
    or die "can't initialize glue object\n";

######################################################################

my $r;

$r = $glue->run('return 123');

ok($r == 123)
    or die "couldn't get simple number";

######################################################################

$r = $glue->run('return {123}');

ok(
	ref($r) eq 'ARRAY'
     && length @$r == 1
     && $r->[0] == 123
) or die "couldn't get list";

######################################################################

$r = $glue->run('return {a:1, b:"zoo"}');

ok(
	ref($r) eq 'HASH'
     && $r->{a} && $r->{a} == 1
     && $r->{b} && $r->{b} eq 'zoo'
) or die "couldn't get record: " . Data::Dumper->Dump([$r], [qw(r)]);

######################################################################

# eval because we expect run() to die here

$r = eval {
    $glue->run('return @$(*#gibberish');
};

ok(!defined $r)
    or die "expected failure on gibberish, but got success";
