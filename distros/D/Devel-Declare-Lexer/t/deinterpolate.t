#!/usr/bin/perl

package Devel::Declare::Lexer::t;

use strict;
use warnings;

use Test::More;

use Data::Dumper;
use Devel::Declare::Lexer qw( test );
use Devel::Declare::Lexer::Tokens;

our $DEBUG = 0;

BEGIN {
    $Devel::Declare::Lexer::DEBUG = $Devel::Declare::Lexer::t::DEBUG;

    Devel::Declare::Lexer::lexed(test => sub {
        my $stream_r = shift;

        my @stream = @$stream_r;

        my $string = $stream[4]->{value};

        my @vars = $stream[4]->deinterpolate;
        print STDERR Dumper \@vars if $DEBUG;
        if(scalar @vars) {
            push @stream, new Devel::Declare::Lexer::Token::Raw(
                value => '; @testvars = (\'' . (join '\', \'', @vars) . '\');'
            );
        } else {
            push @stream, new Devel::Declare::Lexer::Token::Raw(
                value => '; @testvars = ();'
            );
        }

        return \@stream;
    });
}

my $a = "a";
our $shared = "shared";
my $ar = \$a;
my @b = ("b");
my %c = ("c" => "c");

my $tests = 0;
my @testvars;

test print "This is $a string\n";
++$tests && is(scalar @testvars, 1, 'Captured 1 variable');
++$tests && is($testvars[0], '$a', 'Captured $a');

test print "This is @b string\n";
++$tests && is(scalar @testvars, 1, 'Captured 1 variable');
++$tests && is($testvars[0], '@b', 'Captured @b');

test print "This is $b[0] string\n";
++$tests && is(scalar @testvars, 1, 'Captured 1 variable');
++$tests && is($testvars[0], '$b[0]', 'Captured @b[0]');

test print "This is $c{c} string\n";
++$tests && is(scalar @testvars, 1, 'Captured 1 variable');
++$tests && is($testvars[0], '$c{c}', 'Captured $c{c}');

test print "This is \$a string\n";
++$tests && is(scalar @testvars, 0, 'Captured 0 variable');

test print "This is \\$a string\n";
++$tests && is(scalar @testvars, 1, 'Captured 1 variable');
++$tests && is($testvars[0], '$a', 'Captured $a');

test print "This is \\\$a string\n";
++$tests && is(scalar @testvars, 0, 'Captured 0 variable');

test print "This is \\\\$a string\n";
++$tests && is(scalar @testvars, 1, 'Captured 1 variable');
++$tests && is($testvars[0], '$a', 'Captured $a');

test print "This is \\\\$a string and a \\\\@b string\n";
++$tests && is(scalar @testvars, 2, 'Captured 2 variable');
++$tests && is($testvars[0], '$a', 'Captured $a');
++$tests && is($testvars[1], '@b', 'Captured @b');

test print "This is \\\\$a string and a \\\@b string\n";
++$tests && is(scalar @testvars, 1, 'Captured 1 variable');
++$tests && is($testvars[0], '$a', 'Captured $a');

test print "This is \$a string and a \\@b string\n";
++$tests && is(scalar @testvars, 1, 'Captured 1 variable');
++$tests && is($testvars[0], '@b', 'Captured @b');

test print "I want to interpolate '$a' but not '\@b'\n";
++$tests && is(scalar @testvars, 1, 'Captured 1 variable');
++$tests && is($testvars[0], '$a', 'Captured $a');

test print "I want to interpolate '$$ar' but not '\@b'\n";
++$tests && is(scalar @testvars, 1, 'Captured 1 variable');
++$tests && is($testvars[0], '$$ar', 'Captured $$ar');

test print "I want to interpolate '$$ar$a' but not '\@b'\n";
++$tests && is(scalar @testvars, 2, 'Captured 2 variable');
++$tests && is($testvars[0], '$$ar', 'Captured $$ar');
++$tests && is($testvars[1], '$a', 'Captured $a');

test print "I want to interpolate '$$ar@b' but not '\@b'\n";
++$tests && is(scalar @testvars, 2, 'Captured 2 variable');
++$tests && is($testvars[0], '$$ar', 'Captured $$ar');
++$tests && is($testvars[1], '@b', 'Captured @b');

test print "I want to interpolate '$Devel::Declare::Lexer::t::shared' but not '\@b'\n";
++$tests && is(scalar @testvars, 1, 'Captured 1 variable');
++$tests && is($testvars[0], '$Devel::Declare::Lexer::t::shared', 'Captured $Devel::Declare::Lexer::t::shared');

test print "I want to interpolate '$Devel::Declare::Lexer::t::shared$$ar@b' but not '\$Devel::Declare::Lexer::t::shared\$\$ar\@b'\n";
++$tests && is(scalar @testvars, 3, 'Captured 3 variable');
++$tests && is($testvars[0], '$Devel::Declare::Lexer::t::shared', 'Captured $Devel::Declare::Lexer::t::shared');
++$tests && is($testvars[1], '$$ar', 'Captured $$ar');
++$tests && is($testvars[2], '@b', 'Captured @b');

test print "This is a %s format%s", "sprintf", "\n";
++$tests && is(scalar @testvars, 0, 'Captured 0 variable');

test print "$$: Perl special variable\n";
++$tests && is(scalar @testvars, 1, 'Captured 1 variable');
++$tests && is($testvars[0], '$$', 'Captured $$');

test print "Variable with comma $a, $a\n";
++$tests && is(scalar @testvars, 2, 'Captured 2 variable');
++$tests && is($testvars[0], '$a', 'Captured $a');
++$tests && is($testvars[1], '$a', 'Captured $a again');

done_testing($tests);

exit;
