#!perl
use 5.010;
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use Ex::Op ();
use EO::OpTwin;

sub note_it { push @EO::OpTwin::LOG, join ',', @_; 'noted' }

our $g = 'outer';

twin_all( 'return in a bare block',          'my ($x) = @_; { return "in" } "after"', 1 );
twin_all( 'return in an if with a my',       'my ($x) = @_; if ($x) { my $t = "t$x"; return $t } "no"', 2 );
twin_all( '... not taken',                   'my ($x) = @_; if ($x) { my $t = "t$x"; return $t } "no"', 0 );
twin_all( 'return the loop variable',        'my ($n) = @_; for (1 .. $n) { return $_ if $_ > 1 } "none"', 3 );
twin_all( 'return a lexical loop variable',  'my ($n) = @_; for my $i (1 .. $n) { return $i * 10 if $i == 2 } "none"', 3 );
twin_all( 'return from a while',             'my ($n) = @_; while ($n > 0) { return "left $n" if $n == 2; $n-- } "done"', 4 );
twin_all( 'return from nested blocks',       'my ($x) = @_; { { if ($x) { return "deep" } } } "shallow"', 1 );
twin_all( 'return a list from a loop',       'my ($n) = @_; for my $i (1 .. $n) { return ($i, $i + 1) if $i == 2 } ()', 3 );
twin_all( 'return under a local',            'my ($x) = @_; { local $main::g = "inner"; return "saw $main::g" } "never"', 1 );
twin_all( 'local is undone by the return',   'my ($x) = @_; { local $main::g = "inner"; return 1 } 0; $main::g', 1 );
twin_all( 'a return after the loop',         'my ($n) = @_; my $s = 0; for (1 .. $n) { $s += $_ } return $s', 4 );
twin_all( 'a return inside a loop in list context from a block', 'my ($n) = @_; my @r; for my $i (1 .. $n) { push @r, $i; { return @r if $i == 2 } } "no"', 3 );
twin_all( 'the rest is skipped',             'my ($x) = @_; note_it("a"); { note_it("b"); return "x" if $x; note_it("c") } note_it("d"); "end"', 1 );
twin_all( '... and when not taken',          'my ($x) = @_; note_it("a"); { note_it("b"); return "x" if $x; note_it("c") } note_it("d"); "end"', 0 );

is($main::g, 'outer', 'the global is what it was after every return under a local');

done_testing;
