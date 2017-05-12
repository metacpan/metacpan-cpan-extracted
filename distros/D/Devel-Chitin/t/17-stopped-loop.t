#!/usr/bin/env perl
use strict;
use warnings; no warnings 'void';
use lib 'lib';
use lib 't/lib';
use Devel::Chitin::TestRunner;
run_in_debugger();

setup_breakpoints_and_actions();
Devel::Chitin::TestDB1->attach();
Devel::Chitin::TestDB2->attach();

13;

BEGIN {
    @main::expected = qw(
        Devel::Chitin::TestDB1::init
        Devel::Chitin::TestDB2::init
        action
        breakpoint
        Devel::Chitin::TestDB1::notify_stopped
        Devel::Chitin::TestDB2::notify_stopped
        Devel::Chitin::TestDB1::poll
        Devel::Chitin::TestDB2::poll
        Devel::Chitin::TestDB1::idle
        Devel::Chitin::TestDB2::idle
        Devel::Chitin::TestDB1::notify_resumed
        Devel::Chitin::TestDB2::notify_resumed
    );
    if (Devel::Chitin::TestRunner::is_in_test_program) {
        eval 'use Test::More tests => scalar(@main::expected)';
    }
}

sub setup_breakpoints_and_actions {
    Devel::Chitin::Action->new(
        file => __FILE__,
        line => 13,
        code => q( Test::More::is(shift(@main::expected), 'action', 'action fired') ));
    Devel::Chitin::Breakpoint->new(
        file => __FILE__,
        line => 13,
        code => q( Test::More::is(shift(@main::expected), 'breakpoint', 'Breakpoint fired'); 1) );
    Devel::Chitin->user_requested_exit();
}
        

package Devel::Chitin::CommonParent;
use base 'Devel::Chitin';

BEGIN {
    foreach my $subname ( qw( init notify_stopped poll idle notify_resumed ) ) {
        my $sub = sub {
            my($class, $loc) = @_;

            my $next_test = shift @main::expected;
            unless ($next_test) {
                Test::More::ok(0, sprintf('%s::%s ran out if tests at %s:%d',
                                        $class, $subname, $loc->filename, $loc->line));
                exit;
            }
            my($got_class, $got_subname) = ($next_test =~ m/^(.*)::(\w+)/);
            Test::More::is( "${got_class}::${got_subname}",
                            "${class}::${subname}",
                            "called ${class}::${subname}");
            return 1;
        };
        no strict 'refs';
        *$subname = $sub;
    }
}
                
package Devel::Chitin::TestDB1;
BEGIN { our @ISA = qw( Devel::Chitin::CommonParent ); }

package Devel::Chitin::TestDB2;
BEGIN { our @ISA = qw( Devel::Chitin::CommonParent ); }

