use strict;
use warnings;

eval {
    require Log::Any::Adapter;
    Log::Any::Adapter->set( 'Stdout', log_level => 'error' );
};

use Test::More tests => 4;

BEGIN { use_ok('Footprintless::CommandOptionsFactory') }

use Footprintless::Command qw(tail_command);
use Footprintless::Localhost;

my $factory = Footprintless::CommandOptionsFactory->new( default_ssh => 'ssh' );

is( tail_command( '/silly', follow => 1 ), 'tail -f /silly', 'tail silly' );
is( tail_command(
        '/silly',
        follow => 1,
        $factory->command_options( hostname => 'localhost' )
    ),
    'tail -f /silly',
    'localhost tail silly'
);
is( tail_command(
        '/silly',
        follow => 1,
        $factory->command_options( hostname => 'foo' )
    ),
    'ssh foo "tail -f /silly"',
    'foo tail silly'
);
