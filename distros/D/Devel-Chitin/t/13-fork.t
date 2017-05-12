#!/usr/bin/env perl
use strict;
use warnings; no warnings 'void';
use lib 'lib';
use lib 't/lib';
use IO::Pipe;
use Devel::Chitin::TestRunner;
run_in_debugger();

Devel::Chitin::TestDB->attach();

if (is_in_test_program) {
    eval "use Test::More tests => 4;";
}

my $pipe = IO::Pipe->new();
my $pid = fork(); # 17
if ($pid) {
    $pipe->reader();
    Test::More::ok(1, 'parent');
    wait_for_child_ok();
    waitpid($pid, 0);
} elsif (defined $pid) {
    25;
} else {
    Test::More::ok(0, 'fork');
}
exit;

sub wait_for_child_ok {
    local $SIG{ALRM} = sub {
        Test::More::ok(0, 'wait_for_child_ok');
        exit;
    };

    my $response = '';
    alarm(3);
    $response = <$pipe>;
    alarm(0);

    my($ok, $msg) = split(/\t/, $response);
    $msg ||= 'response from child process';
    Test::More::ok($ok, $msg);
}

package Devel::Chitin::TestDB;
use base 'Devel::Chitin';

sub notify_fork_parent {
    my($db, $loc, $pid) = @_;

    Test::More::ok($pid, 'notify_fork_parent');
    my $different = _fork_location_different($loc);
    Test::More::ok(! $different, "parent fork location $different");
}

sub notify_fork_child {
    my($db, $loc, $pid) = @_;

    $pipe->writer;
    if ($pid) {
        print $pipe "0\tchild pid is 0\n";
    }
    my $different = _fork_location_different($loc);
    my $ok = ! $different;
    print $pipe "$ok\tnotify_fork_child $different\n";
}

sub _fork_location_different {
    my $loc = shift;

    my %expected_fork_location = (
        package => 'main',
        line    => 17,
        filename => __FILE__,
        subroutine => 'MAIN'
    );

    foreach my $k ( keys %expected_fork_location ) {
        if ($loc->$k ne $expected_fork_location{$k}) {
            return sprintf('%s got %s expected %s',
                        $k,
                        defined($loc->$k) ? $loc->$k : '(undef)',
                        $expected_fork_location{$k});
        }
    }
    return '';
}

