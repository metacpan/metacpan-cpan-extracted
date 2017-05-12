#!/usr/bin/env perl
# Test try()

use warnings;
use strict;

use Test::More tests => 36;

use Log::Report undef, syntax => 'SHORT';
use Carp;  # required for tests

eval
{  use POSIX ':locale_h', 'setlocale';  # avoid user's environment
   setlocale(LC_ALL, 'POSIX');
};

# start a new logger
my $text = '';
open my($fh), '>', \$text;

dispatcher close => 'default';
dispatcher FILE => 'out', to => $fh, accept => 'ALL', format => sub {shift};

cmp_ok(length $text, '==', 0, 'created normal file logger');

my $text_l1 = length $text;
info "test";
my $text_l2 = length $text;
cmp_ok($text_l2, '>', $text_l1);

my @l1 = dispatcher 'list';
cmp_ok(scalar(@l1), '==', 1);
is($l1[0]->name, 'out');

try { my @l2 = dispatcher 'list';
      cmp_ok(scalar(@l2), '==', 2);
      is($l2[1]->name, 'try', 'only try dispatcher');
      error "this is an error";
    };

my $caught = $@;   # be careful with this... Test::More may spoil it.
my @l3 = dispatcher 'list';
cmp_ok(scalar(@l3), '==', 1);
is($l3[0]->name, 'out', 'original dispatcher restored');

isa_ok($caught, 'Log::Report::Dispatcher::Try');

ok($caught->failed);
ok($caught ? 1 : 0);
my @r1 = $caught->exceptions;
cmp_ok(scalar(@r1), '==', 1);

isa_ok($r1[0], 'Log::Report::Exception');

my @r2 = $caught->wasFatal;
cmp_ok(scalar(@r2), '==', 1);
isa_ok($r2[0], 'Log::Report::Exception');

eval {
   try { try { failure "oops! no network" };
         $@->reportAll;
       };
   $@->reportAll;
};
like($@, qr[^failure: oops]i);

### context

my $context;
my $scalar = try {
    $context = !wantarray && defined wantarray ? 'SCALAR' : 'OTHER';
    my @x = 1..10;
    @x;
};

is($context, 'SCALAR', 'try in SCALAR context');
cmp_ok($scalar, '==', 10);

try {
   $context = !defined wantarray ? 'VOID' : 'OTHER';
   3;
};
is($context, 'VOID', 'try in VOID context');

my @list = try {
   $context = wantarray ? 'LIST' : 'OTHER';
   1..5;
};
is($context, 'LIST', 'try in LIST context');
cmp_ok(scalar @list, '==', 5);

### convert die/croak/confess
# conversions by Log::Report::Die, see t/*die.t

my $die = try { die "oops" };
ok(ref $@, 'caught die');
isa_ok($@, 'Log::Report::Dispatcher::Try');
my $die_ex = $@->wasFatal;
isa_ok($die_ex, 'Log::Report::Exception');
is($die_ex->reason, 'ERROR');
like("$@", qr[^try-block stopped with ERROR: oops at ] );

my $croak = try { croak "oops2" };
ok(ref $@, 'caught croak');
isa_ok($@, 'Log::Report::Dispatcher::Try');
my $croak_ex = $@->wasFatal;
isa_ok($croak_ex, 'Log::Report::Exception');
is($croak_ex->reason, 'ERROR');
like("$@", qr[^try-block stopped with ERROR: oops2 at ] );

my $confess = try { confess "oops3" };
ok(ref $@, 'caught confess');
isa_ok($@, 'Log::Report::Dispatcher::Try');
my $confess_ex = $@->wasFatal;
isa_ok($confess_ex, 'Log::Report::Exception');
is($confess_ex->reason, 'PANIC');
like("$@", qr[^try-block stopped with PANIC: oops3 at ] );
