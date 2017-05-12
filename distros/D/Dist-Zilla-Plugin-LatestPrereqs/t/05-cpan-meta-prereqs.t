#!perl

use strict;
use warnings;
use Test::More;
use CPAN::Meta::Prereqs;
use Scalar::Util qw( blessed );

my $cm = CPAN::Meta::Prereqs->new;
ok($cm, 'CPAN::Meta::Prereqs constructor is ok without parameters');

my $req = $cm->requirements_for('runtime', 'requires');
ok($req, 'Got a requirements object ok');

$req->add_minimum('Dist::Zilla', '4.0');

## Object internals are as expected
ok(exists($cm->{prereqs}),          "... has 'prereqs' key");
ok(exists($cm->{prereqs}{runtime}), "... and that has 'runtime' key");
ok(exists($cm->{prereqs}{runtime}{requires}), "... and that has 'requires' key");

my $reqs = $cm->{prereqs}{runtime}{requires};

ok(blessed($reqs),               "The {prereqs}{runtime} has an object");
ok($reqs->can('as_string_hash'), "... that has a 'as_string_hash' method");

my $raw = $reqs->as_string_hash;
is(ref($raw), 'HASH',
  '$reqs_obj->as_string_hash returns the expected HashRef');

is(scalar(keys %$raw), 1, 'Expected number of prereqs');
ok(exists($raw->{'Dist::Zilla'}),
  '... and it is the expected prereq, Dist::Zilla');
is($raw->{'Dist::Zilla'}, '4.0', '... with the expected value');


done_testing();
