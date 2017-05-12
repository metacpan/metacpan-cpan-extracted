#!perl
BEGIN { require 't/common.pl' }

# create a subclass and do things incrementally

use Test::More tests => 2;
use_ok("Mail::Thread");
package My::Thread;
@ISA = qw(Mail::Thread);
sub _container_class { 'My::Thread::Container' }

sub _finish { }

package My::Thread::Container;
@ISA = qw(Mail::Thread::Container);

our %stuff;

sub new {
    my ($class, $id) = @_;
    if (!$stuff{$id})  { $stuff{$id} = $class->SUPER::new($id); }
    return $stuff{$id};
}

package main;

for (slurp_messages('t/testbox-5')) {
    my $threader = new My::Thread($_);

    $threader->thread;
}

ok(2, "Completes successfully...");
