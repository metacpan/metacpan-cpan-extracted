use strict;
use warnings;
use Test2::V0;  no warnings 'void';
use Devel::Chitin;

BEGIN { $^P = 0x73f }  # Turn on all the debugging stuff
plan tests => 3;
TestDB->attach();

$DB::single=1;
11;
13;
14;

package
    TestDB;
use base 'Devel::Chitin';
use Test2::Tools::Basic;

sub notify_stopped {
    my($db, $loc) = @_;

    ok( ( $loc->filename eq __FILE__
            and
            $loc->line == 11 ),
        'Stopped on line 11') || diag(sprintf('line was %s:%d', $loc->filename, $loc->line));

    ok($db->user_requested_exit(), 'set user_requested_exit');

    $db->continue;
}

sub notify_program_exit {
    ok(1, 'in notify_program_exit');
}

sub notify_program_terminated {
    fail('notify_program_terminated was unexpected');
    exit;
}
