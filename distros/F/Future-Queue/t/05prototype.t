#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Future;
use Future::Queue;

package t::Future::Subclass {
   use base qw( Future );
}

# prototype is class name
{
   my $queue = Future::Queue->new( prototype => "t::Future::Subclass" );

   isa_ok( $queue->shift, [ "t::Future::Subclass" ], '->shift for prototype class' );
}

# prototype is an instance
{
   my $queue = Future::Queue->new( prototype => t::Future::Subclass->new );

   isa_ok( $queue->shift, [ "t::Future::Subclass" ], '->shift for prototype object instance' );
}

# prototype is a code ref
{
   my $queue = Future::Queue->new( prototype => sub { t::Future::Subclass->new } );

   isa_ok( $queue->shift, [ "t::Future::Subclass" ], '->shift for prototype object instance' );
}

done_testing;
