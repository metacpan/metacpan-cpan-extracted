#!/usr/bin/env perl
# ABSTRACT: RunContext + Role::Runnable are generic core primitives, usable standalone and decoupled from Raider

use strict;
use warnings;

use Test2::Bundle::More;

use Future;
use Langertha::RunContext;
use Langertha::Role::Runnable;

# --- Decoupling: loading them must not drag in the Raider/Raid layer ---
ok(!$INC{'Langertha/Raider.pm'}, 'RunContext/Runnable load without Langertha::Raider');
ok(!$INC{'Langertha/Raid.pm'},   'RunContext/Runnable load without Langertha::Raid');

# --- RunContext basics ---
my $ctx = Langertha::RunContext->new(input => 'start', state => { counter => 1 });
is($ctx->input, 'start', 'input stored');
is($ctx->state->{counter}, 1, 'state stored');

$ctx->add_trace({ event => 'step', n => 1 });
is(scalar @{$ctx->trace}, 1, 'trace appended');

# --- branch isolation + merge ---
my $branch = $ctx->branch(metadata => { path => 'left' });
isa_ok($branch, 'Langertha::RunContext');
$branch->state->{counter} = 99;
is($ctx->state->{counter}, 1, 'branch state is isolated from its parent');

$ctx->merge_branch($branch, slot => 'parallel', name => 'left');
is($ctx->artifacts->{parallel}{left}{state}{counter}, 99, 'merged branch artifact recorded');

# --- Role::Runnable is a standalone contract, no Raider needed ---
{
  package My::Runner;
  use Moose;
  with 'Langertha::Role::Runnable';
  sub run_f { my ( $self, $context ) = @_; return Future->done('ran:' . $context->input) }
  __PACKAGE__->meta->make_immutable;
}

my $runner = My::Runner->new;
ok($runner->does('Langertha::Role::Runnable'), 'consumer does Role::Runnable');
is($runner->run_f($ctx)->get, 'ran:start', 'run_f executes with a RunContext');

done_testing;
