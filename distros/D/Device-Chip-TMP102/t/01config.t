#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Device::Chip::Adapter;

use Device::Chip::TMP102;

my $chip = Device::Chip::TMP102->new;

$chip->mount( my $adapter = Test::Device::Chip::Adapter->new, )->get;

# ->read_config
{
    $adapter->expect_write_then_read( "\x01", 2 )->returns("\x60\xA0");

    is_deeply(
        $chip->read_config->get,    # values represent power on state
        {
            SD  => '',
            TM  => '',
            POL => '',
            F   => 1,
            R0  => 1,
            R1  => 1,
            OS  => '',
            EM  => '',
            AL  => 1,
            CR  => '4Hz',
        },
        '->read_config returns config'
    );

    $adapter->check_and_clear('->read_config');
}

# ->change_config
{
    $adapter->expect_write("\x01\x60\xB0");

    $chip->change_config( EM => 1, )->get;

    $adapter->check_and_clear('$chip->change_config');
}

done_testing;
