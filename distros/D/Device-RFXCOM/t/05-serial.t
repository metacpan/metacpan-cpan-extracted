#!/usr/bin/perl
#
# Copyright (C) 2010 by Mark Hindess

use strict;
use constant {
  DEBUG => $ENV{DEVICE_RFXCOM_RX_TEST_DEBUG}
};
use lib 't/lib';
use Test::More;
use File::Temp qw/tempfile/;

BEGIN {
  $ENV{DEVICE_RFXCOM_TESTING} = 1;
}

my ($fh, $filename) = tempfile();
END { unlink $filename if ($filename); }

print $fh pack 'H*', '4d26414120609f08f7';

use_ok('Device::RFXCOM::RX');

my @sent;
{
  package MY::RX;
  our @ISA = qw/Device::RFXCOM::RX/;
  sub _write_now {
    my $self = shift;
    my $rec = shift @{$self->{_q}};
    delete $self->{_waiting};
    return unless (defined $rec);
    push @sent, $rec->{hex};
    $self->{_waiting} = [ $self->_time_now, $rec ];
  }
}

my $rx = MY::RX->new(device => $filename);

ok($rx, 'instantiate MY::RX object');
$fh = $rx->filehandle;
my @calls = Device::SerialPort::calls();
is_deeply \@calls,
 [
  [ 'Device::SerialPort::baudrate' => 4800 ],
  [ 'Device::SerialPort::databits' => 8 ],
  [ 'Device::SerialPort::parity' => 'none' ],
  [ 'Device::SerialPort::stopbits' => 1 ],
  [ 'Device::SerialPort::datatype' => 'raw' ],
  [ 'Device::SerialPort::write_settings' ],
 ], '... Device::SerialPort calls';

eval { MY::RX->new(device => 't/does-not-exist.dev') };
like($@, qr!^sysopen of 't/does-not-exist\.dev' failed:!, 'sysopen error');

done_testing;
