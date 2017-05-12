#!/usr/bin/perl -w

use strict 'vars', 'subs';
use Test::More tests => 7;

#----------------------------------------
# slurp, iter
BEGIN { use_ok("Maptastic", ":iter", "mapcar") }

my @slurped = slurp "this", [ "that", "t'other" ];
is_deeply(\@slurped, [qw(this that t'other)], "slurp - simple");

my $iter = iter "this", [ "that", "t'other" ];
@slurped = ();
while (my $x = $iter->()) {
    push @slurped, $x;
}
is_deeply(\@slurped, [qw(this that t'other)], "iter - simple");

$iter = iter (iter([qw(Foo Bar)]), iter([qw(Baz Frop)], iter("Quux")));

is_deeply([ slurp $iter ], [qw(Foo Bar Baz Frop Quux)],
	  "slurp the iter");

#----------------------------------------
# igrep
$iter = iter (iter([qw(Foo Bar)]), iter([qw(Baz Frop)], iter("Quux")));

my $igrep = igrep { m/[xo]/ } $iter;

@slurped = ();
while (my $x = $igrep->()) {
    push @slurped, $x;
}
is_deeply(\@slurped, [qw(Foo Frop Quux)], "igrep");

#----------------------------------------
# ifilter
$iter = iter (iter([qw(Foo Bar)]), iter([qw(Baz Frop)], iter("Quux")));
my $ifilter = ifilter { tr/[A-Za-z]/[a-zA-Z]/ } $iter;

@slurped = ();
while (my $x = $ifilter->()) {
    push @slurped, $x;
}
is_deeply(\@slurped, [qw(fOO bAR bAZ fROP qUUX)], "ifilter");

#----------------------------------------
# mapcar with iterative input
my $a = iter(1, 2, 3);
my $b = iter(qw(Mary Jane));
my $c = iter('A' .. 'E');

my @spliced = mapcar { [ @_ ] } $a, $b, $c;

is_deeply(\@spliced, [ [1,     "Mary", "A"],
		       [2,     "Jane", "B"],
		       [3,             "C"],
		       [               "D"],
		       [               "E"] ],
	  "mapcar with iterative input");

# mapcaru with iterative input (unimplemented)

# imapcar (unimplemented)

# imap_each (unimplemented)
