# Tests that callbacks are routed properly when more than one debugger is attached
use strict;
use warnings;

use Test2::V0; no warnings 'void';
BEGIN { $^P = 0x73f } # Turn on all the debugging stuff
use lib 't/lib';
use SampleCode;

setup_breakpoints_and_actions();
TestDB1->attach();
TestDB2->attach();

SampleCode::foo();
13;

our @events;
END {
    my @expected = qw(
        TestDB1::init
        TestDB2::init
        action
        breakpoint
        TestDB1::notify_stopped
        TestDB2::notify_stopped
        TestDB1::poll
        TestDB2::poll
        TestDB1::idle
        TestDB2::idle
        TestDB1::notify_resumed
        TestDB2::notify_resumed
    );
    plan tests => 1;
    is(\@events, \@expected, 'events in order');
}

sub setup_breakpoints_and_actions {
    Devel::Chitin::Action->new(
        file => 't/lib/SampleCode.pm',
        line => 5,
        code => q( push @main::events, 'action' ) );
    Devel::Chitin::Breakpoint->new(
        file => 't/lib/SampleCode.pm',
        line => 5,
        code => q( push @main::events, 'breakpoint' ) );
    Devel::Chitin->user_requested_exit();
}
        

package 
    DBParent;
use base 'Devel::Chitin';

sub init {
    my($db) = @_;
    push @main::events, "${db}::init";
}

sub poll {
    my($db) = @_;
    push @main::events, "${db}::poll";
}

sub idle {
    my($db) = @_;
    push @main::events, "${db}::idle";
}

sub notify_stopped {
    my($db) = @_;
    push @main::events, "${db}::notify_stopped";
}

sub notify_resumed {
    my($db) = @_;
    push @main::events, "${db}::notify_resumed";
}
                
package
    TestDB1;
BEGIN { our @ISA = qw( DBParent ); }

package 
    TestDB2;
BEGIN { our @ISA = qw( DBParent ); }

