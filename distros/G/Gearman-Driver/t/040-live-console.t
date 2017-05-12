use strict;
use warnings;
use Test::More tests => 60;
use Test::Differences;
use FindBin;
use lib "$FindBin::Bin/lib";
use Gearman::Driver::Test;
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;

my $test = Gearman::Driver::Test->new();

$test->prepare('Gearman::Driver::Test::Live::Console');

my $gc     = $test->gearman_client;
my $telnet = $test->telnet_client;

{
    $telnet->print("asdf");
    is( $telnet->getline(), "ERR unknown_command: asdf\n" );
    is( $telnet->getline(), ".\n" );

    $telnet->print("set_min_processes asdf 5");
    is( $telnet->getline(), "ERR invalid_job_name: asdf\n" );
    is( $telnet->getline(), ".\n" );

    $telnet->print("set_min_processes Gearman::Driver::Test::Live::Console::ping ten");
    is( $telnet->getline(), "ERR invalid_value: min_processes must be >= 0\n" );
    is( $telnet->getline(), ".\n" );

    $telnet->print("set_min_processes Gearman::Driver::Test::Live::Console::ping 10");
    is( $telnet->getline(), "ERR invalid_value: min_processes must be smaller than max_processes\n" );
    is( $telnet->getline(), ".\n" );

    $telnet->print("set_max_processes asdf 5");
    is( $telnet->getline(), "ERR invalid_job_name: asdf\n" );
    is( $telnet->getline(), ".\n" );

    $telnet->print("set_max_processes Gearman::Driver::Test::Live::Console::ping ten");
    is( $telnet->getline(), "ERR invalid_value: max_processes must be >= 0\n" );
    is( $telnet->getline(), ".\n" );

    $telnet->print("set_max_processes Gearman::Driver::Test::Live::Console::ping 5");
    is( $telnet->getline(), "OK\n" );
    is( $telnet->getline(), ".\n" );
    $telnet->print("set_min_processes Gearman::Driver::Test::Live::Console::ping 5");
    is( $telnet->getline(), "OK\n" );
    is( $telnet->getline(), ".\n" );

    $telnet->print("set_max_processes Gearman::Driver::Test::Live::Console::ping 4");
    is( $telnet->getline(), "ERR invalid_value: max_processes must be greater than min_processes\n" );
    is( $telnet->getline(), ".\n" );

    $telnet->print("set_processes asdf 1 1");
    is( $telnet->getline(), "ERR invalid_job_name: asdf\n" );
    is( $telnet->getline(), ".\n" );

    $telnet->print("set_processes Gearman::Driver::Test::Live::Console::ping ten ten");
    is( $telnet->getline(), "ERR invalid_value: min_processes must be >= 0\n" );
    is( $telnet->getline(), ".\n" );

    $telnet->print("set_processes Gearman::Driver::Test::Live::Console::ping 1 ten");
    is( $telnet->getline(), "ERR invalid_value: max_processes must be >= 0\n" );
    is( $telnet->getline(), ".\n" );

    $telnet->print("set_processes Gearman::Driver::Test::Live::Console::ping 5 1");
    is( $telnet->getline(), "ERR invalid_value: max_processes must be greater than min_processes\n" );
    is( $telnet->getline(), ".\n" );

    $telnet->print('kill 1');
    is( $telnet->getline(), "ERR invalid_value: the given PID(s) do not belong to us\n" );
    is( $telnet->getline(), ".\n" );

    # reset default values
    $telnet->print("set_min_processes Gearman::Driver::Test::Live::Console::ping 0");
    is( $telnet->getline(), "OK\n" );
    is( $telnet->getline(), ".\n" );
    $telnet->print("set_max_processes Gearman::Driver::Test::Live::Console::ping 1");
    is( $telnet->getline(), "OK\n" );
    is( $telnet->getline(), ".\n" );
}

{
    my @expected = (
        'Gearman::Driver::Test::Live::Console::ping  0  1  0  1970-01-01T00:00:00  1970-01-01T00:00:00  ',
        'Gearman::Driver::Test::Live::Console::pong  0  1  0  1970-01-01T00:00:00  1970-01-01T00:00:00  ',
    );
    my @status = fetch_status();
    eq_or_diff( \@status, \@expected );
}

{
    $telnet->print("set_max_processes Gearman::Driver::Test::Live::Console::ping 2");
    is( $telnet->getline(), "OK\n" );
    is( $telnet->getline(), ".\n" );
    $telnet->print("set_min_processes Gearman::Driver::Test::Live::Console::ping 2");
    is( $telnet->getline(), "OK\n" );
    is( $telnet->getline(), ".\n" );

    sleep(6);

    my @pids = ();
    my $test = sub {
        my @expected = (
            qr/^Gearman::Driver::Test::Live::Console::ping  2  2  2  1970-01-01T00:00:00  1970-01-01T00:00:00  $/,
            qr/^\d+$/, qr/^\d+$/,
        );
        $telnet->print('show Gearman::Driver::Test::Live::Console::ping');
        while ( my $line = $telnet->getline() ) {
            last if $line eq ".\n";
            chomp $line;
            like( $line, shift(@expected) );
            push @pids, $line if $line =~ /^\d+$/;
        }
    };

    $test->();

    my @old_pids = @pids;

    for ( 1 .. 2 ) {
        $telnet->print( 'kill ' . shift(@pids) );
        is( $telnet->getline(), "OK\n" );
        is( $telnet->getline(), ".\n" );
    }

    sleep(6);

    $test->();

    for ( 1 .. 2 ) {
        isnt( shift(@pids), shift(@old_pids) );
    }

    $telnet->print('killall Gearman::Driver::Test::Live::Console::ping');
    is( $telnet->getline(), "OK\n" );
    is( $telnet->getline(), ".\n" );

    sleep(6);

    $test->();

    for ( 1 .. 2 ) {
        isnt( shift(@pids), shift(@old_pids) );
    }

    # reset default values
    $telnet->print("set_min_processes Gearman::Driver::Test::Live::Console::ping 0");
    is( $telnet->getline(), "OK\n" );
    is( $telnet->getline(), ".\n" );
    $telnet->print("set_max_processes Gearman::Driver::Test::Live::Console::ping 1");
    is( $telnet->getline(), "OK\n" );
    is( $telnet->getline(), ".\n" );
}

$test->shutdown;

sub fetch_status {
    $telnet->print('status');
    my @lines = ();
    while ( my $line = $telnet->getline() ) {
        last if $line eq ".\n";
        chomp $line;
        push @lines, $line;
    }
    return @lines;
}
