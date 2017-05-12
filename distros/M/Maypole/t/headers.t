#!/usr/bin/perl -w
use strict;
use Test::More tests => 22;

require_ok('Maypole::Headers');
ok($Maypole::Headers::VERSION, 'defines $VERSION');
ok($INC{'HTTP/Headers.pm'}, 'requires HTTP::Headers');
ok(Maypole::Headers->isa('HTTP::Headers'), '@ISA = HTTP::Headers');
ok(Maypole::Headers->can('new'), 'can new()');
my $h = Maypole::Headers->new;
isa_ok($h, 'Maypole::Headers');

# set()
can_ok($h => 'set');
$h->set(hello_world => 1);
$h->set(JAPH => [qw(Just Another Perl Hacker!)]);
$h->set(Content_Type => 'text/plain', Referer => 'http://localhost/');

# get()
can_ok($h => 'get');
is($h->get('Hello-World'), 1, '... name is normalised, fetches value');
ok($h->get('Content_Type') eq 'text/plain'
   && $h->get('Referer') eq 'http://localhost/',
   '... fetches values set() in the same call');
is($h->get('JAPH'), 'Just, Another, Perl, Hacker!',
   '... fetches comma-separated multiple values');
is($h->get('non-existant'), undef,
   '... returns undef for non-existant header');

# push()
can_ok($h, 'push');
$h->push(japh => 'TMTOWTDI');
is($h->get('JAPH'), 'Just, Another, Perl, Hacker!, TMTOWTDI',
   '... appends to a header');
$h->push(H2G2 => 42);
is($h->get('H2G2'), 42,
   "...can be used like in place of set() if the field doesn't already exist");

# push()
can_ok($h, 'init');
$h->init(X_Server_Software => 'Maypole');
is($h->get('X-Server-Software'), 'Maypole',
   "... Sets a value if it doesn't already exist");
$h->init(X_Server_Software => 'Maypole-XP');
is($h->get('X-Server-Software'), 'Maypole',
   "... subsequent init()s don't replace previous values");

# remove()
can_ok($h, 'remove');
$h->remove('H2G2');
is($h->get('H2G2'), undef, 'removes a previously defined field');

# field_names()
can_ok($h, 'field_names');
is_deeply([$h->field_names],
          [qw(Referer Content-Type Hello-World JAPH X-Server-Software)],
          '... returns a list of field names');

# print $h->as_string;
