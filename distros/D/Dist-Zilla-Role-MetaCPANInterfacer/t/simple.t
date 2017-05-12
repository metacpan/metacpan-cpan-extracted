package Dummy::Test;

our $VERSION = v1.2.3;

use sanity;
use Moose;

with 'Dist::Zilla::Role::MetaCPANInterfacer';

sub tester {
   my $self = shift;
   my $mcpan = $self->mcpan;
}

package main;

use Test::Most tests => 1;

my $t;
lives_ok(sub {
   $t = Dummy::Test->new();
   $t->tester();
}, 'MetaCPAN interface is up');

diag $t->mcpan_mechua->agent;
