#!/usr/bin/env perl
use strict;
use warnings;

# use Data::Dumper::Compact qw(ddc);
use Test::More;
use Test::Exception;

my $module = 'MIDI::Device';

use_ok $module;

subtest throws => sub {
    throws_ok { $module->new(name => 'foo') }
        qr/doesn't exist/, 'bogus device';
};

subtest HPD15 => sub {
    my $obj = new_ok $module => [ name => 'hpd-15' ];
    is $obj->name, 'hpd-15', 'name';
    is $obj->manufacturer, 'Roland', 'manufacturer';
    is $obj->port_in, 'generic', 'port_in';
    is $obj->port_out, 'generic', 'port_out';
    is_deeply $obj->cc->[0], { name => 'Bank Select', number => 0 }, 'cc';
};

subtest VolcaDrum => sub {
    my $obj = new_ok $module => [ name => 'volca-drum' ];
    is $obj->name, 'volca-drum', 'name';
    is $obj->manufacturer, 'Korg', 'manufacturer';
    is $obj->port_in, 'generic', 'port_in';
    is $obj->port_out, 'generic', 'port_out';
    is_deeply $obj->cc->[0], { name => 'Pan', number => 10 }, 'cc';
    is_deeply $obj->note_on, [qw(60 62 64 65 67 69)], 'note_on';
};

subtest microKORG => sub {
    my $obj = new_ok $module => [ name => 'microkorg' ];
    is $obj->name, 'microkorg', 'name';
    is $obj->manufacturer, 'Korg', 'manufacturer';
    is $obj->port_in, 'generic', 'port_in';
    is $obj->port_out, 'generic', 'port_out';
    is_deeply $obj->cc->[0], { name => 'Modulation Depth (MOD Wheel)', number => 1 }, 'cc';
    is_deeply $obj->note_on, { min => 0, max => 127 }, 'note_on';
};

done_testing();
