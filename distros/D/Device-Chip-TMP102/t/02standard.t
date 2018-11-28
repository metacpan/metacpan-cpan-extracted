#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Device::Chip::Adapter;

use Device::Chip::TMP102;

require_ok('Device::Chip::TMP102');

my $chip = new_ok('Device::Chip::TMP102');

$chip->mount( my $adapter = Test::Device::Chip::Adapter->new, )->get;

# ->read_temp
{
    $adapter->expect_write_then_read( "\x01", 2 )->returns("\x60\xA0");  # config read first test

    my $config = $chip->read_config->get;
    is( # Extended mode off
	$config->{EM},
	'',
	'->read_config set extended mode'
    );

    $adapter->expect_write_then_read( "\x00", 2 )->returns("\x1C\x00");

    is( $chip->read_temp->get, 28.0, '->read_temp result' );

    $adapter->check_and_clear('->read_temp');
}

# ->read_temp (max)
{
    $adapter->expect_write_then_read( "\x00", 2 )->returns("\x7F\xF0");

    is( $chip->read_temp->get, 127.9375, '->read_temp max result' );

    $adapter->check_and_clear('->read_temp (max)');
}

# ->read_temp (80)
{
    $adapter->expect_write_then_read( "\x00", 2 )->returns("\x50\x00");

    is( $chip->read_temp->get, 80, '->read_temp 80 result' );

    $adapter->check_and_clear('->read_temp (80)');
}

# ->read_temp (50)
{
    $adapter->expect_write_then_read( "\x00", 2 )->returns("\x32\x00");

    is( $chip->read_temp->get, 50, '->read_temp 50 result' );

    $adapter->check_and_clear('->read_temp (50)');
}


# ->read_temp (zero)
{
    $adapter->expect_write_then_read( "\x00", 2 )->returns("\x00\x00");

    is( $chip->read_temp->get, 0.0, '->read_temp zero result' );

    $adapter->check_and_clear('->read_temp (zero)');
}

# ->read_temp (small negative)
{
    $adapter->expect_write_then_read( "\x00", 2 )->returns("\xFF\xC0");

    is( $chip->read_temp->get, -0.25, '->read_temp small negative result' );

    $adapter->check_and_clear('->read_temp (small negative)');
}

# ->read_temp (bigger negative)
{
    $adapter->expect_write_then_read( "\x00", 2 )->returns("\xC9\x00");

    is( $chip->read_temp->get, -55.0, '->read_temp bigger negative result' );

    $adapter->check_and_clear('->read_temp (bigger negative)');
}

# ->read_temp_low
{
    $adapter->expect_write_then_read( "\x02", 2 )->returns("\x1C\x00");

    is( $chip->read_temp_low->get, 28.0, '->read_temp_low result' );

    $adapter->check_and_clear('->read_temp_low');
}

# ->write_temp_low
{
    $adapter->expect_write("\x02\x1C\x00");

    is( $chip->write_temp_low(28.0)->get, undef, '->write_temp_low result' );
 
    $adapter->check_and_clear('->write_temp_low');
}

# ->read_temp_high
{
    $adapter->expect_write_then_read( "\x03", 2 )->returns("\x1C\x00");

    is( $chip->read_temp_high->get, 28.0, '->read_temp_high result' );

    $adapter->check_and_clear('->read_temp_low');
}

# ->write_temp_high
{
    $adapter->expect_write("\x03\x1C\x00");

    is( $chip->write_temp_high(28.0)->get, undef, '->write_temp_high result' );

    $adapter->check_and_clear('->write_temp_high');
}

done_testing;
