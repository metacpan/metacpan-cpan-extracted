#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::Device::Chip::Adapter;

use Device::Chip::ADT7470;

require_ok('Device::Chip::ADT7470');

my $chip = new_ok('Device::Chip::ADT7470');

$chip->mount( my $adapter = Test::Device::Chip::Adapter->new, )->get;

# ->read_duty
{
    $adapter->expect_write_then_read( "\x32", 1 )->returns("\xFF");

    is( $chip->read_duty(1)->get, 255, '->read_duty result' );

    $adapter->check_and_clear('->read_duty');
}

# ->read_duty_percent
{
    $adapter->expect_write_then_read( "\x32", 1 )->returns("\xFF");

    is( $chip->read_duty_percent(1)->get, 100, '->read_duty_percent result' );

    $adapter->check_and_clear('->read_duty_percent');
}

# ->write_duty
{
    $adapter->expect_write("\x32\xFF");

    is( $chip->write_duty( 1, 255 )->get, undef, '->write_duty result' );

    $adapter->check_and_clear('->write_duty');
}

# ->write_duty_percent
{
    $adapter->expect_write("\x32\xFF");

    is( $chip->write_duty_percent( 1, 100 )->get,
        undef, '->write_duty_percent result' );

    $adapter->check_and_clear('->write_duty_percent');
}

# ->read_fan_rpm
{
    $adapter->expect_write_then_read( "\x2A", 1 )->returns("\xFF");
    $adapter->expect_write_then_read( "\x2B", 1 )->returns("\x17");

    is( $chip->read_fan_rpm(1)->get, 879, '->read_fan_rpm result' );

    $adapter->check_and_clear('->read_fan_rpm');
}

# ->read_fan_rpm
{
    $adapter->expect_write_then_read( "\x2A", 1 )->returns("\xFF");
    $adapter->expect_write_then_read( "\x2B", 1 )->returns("\xFF");

    is( $chip->read_fan_rpm(1)->get, 0, '->read_fan_rpm result (fan stalled)' );

    $adapter->check_and_clear('->read_fan_rpm (fan stalled)');
}

# ->_format_fan
is( $chip->_format_fan(1), 'FAN1', 'format fan into string' );

# ->_format_fan
throws_ok(
    sub { $chip->_format_fan(-1) },
    qr/Fan must be 1-4/,
    'fan should not be negative'
);

# ->_format_fan
throws_ok(
    sub { $chip->_format_fan(5) },
    qr/Fan must be 1-4/,
    'fan should be 1-4'
);

# ->_format_fan
throws_ok(
    sub { $chip->_format_fan(1.2) },
    qr/Fan must be 1-4/,
    'fan should be integer'
);

done_testing;
