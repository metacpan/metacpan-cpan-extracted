use strict;
use warnings;
use lib 'lib';

use Mac::MissileLauncher;

my $last = (($ARGV[0] || '') =~ /^\d+/) ? $ARGV[0] : 0;

my $devices;
for (0..$last) {
    $devices->{$_} = Mac::MissileLauncher->new(num => $_);
}

$SIG{INT} = sub { exit };

while (1) {
    cmd($devices, 'up', 1);
    cmd($devices, 'left');
    cmd($devices, 'down', 1);
    cmd($devices, 'right');
}

sub cmd {
    my($devices, $cmd, $timeout) = @_;
    $timeout ||= 2;

    for my $num (keys %{ $devices }) {
	$devices->{$num}->$cmd;
    }
    sleep($timeout);
}

END {
    cmd($devices, 'stop', 1);
}
