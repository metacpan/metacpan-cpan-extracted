use strict;
use warnings;
package Device::RFXCOM::Decoder::Oregon;
$Device::RFXCOM::Decoder::Oregon::VERSION = '1.163170';
# ABSTRACT: Device::RFXCOM::Decoder::Oregon decode Oregon RF messages


use 5.006;
use constant DEBUG => $ENV{DEVICE_RFXCOM_DECODER_OREGON_DEBUG};
use Carp qw/croak/;
use Device::RFXCOM::Decoder qw/hi_nibble lo_nibble nibble_sum/;
our @ISA = qw(Device::RFXCOM::Decoder);
use Device::RFXCOM::Response::Sensor;
use Device::RFXCOM::Response::DateTime;

my %types =
  (
   type_length_key(0xfa28, 80) =>
   {
    part => 'THGR810', checksum => \&checksum2, method => 'common_temphydro',
   },
   type_length_key(0xfab8, 80) =>
   {
    part => 'WTGR800', checksum => \&checksum2, method => 'alt_temphydro',
   },
   type_length_key(0x1a99, 88) =>
   {
    part => 'WTGR800', checksum => \&checksum4, method => 'wtgr800_anemometer',
   },
   type_length_key(0x1a89, 88) =>
   {
    part => 'WGR800', checksum => \&checksum4, method => 'wtgr800_anemometer',
   },
   type_length_key(0xda78, 72) =>
   {
    part => 'UVN800', checksum => \&checksum7, method => 'uvn800',
   },
   type_length_key(0xea7c, 120) =>
   {
    part => 'UV138', checksum => \&checksum1, method => 'uv138',
   },
   type_length_key(0xea4c, 80) =>
   {
    part => 'THWR288A', checksum => \&checksum1, method => 'common_temp',
   },
   type_length_key(0xea4c, 68) =>
   {
    part => 'THN132N', checksum => \&checksum1, method => 'common_temp',
   },
   type_length_key(0x8aec, 104) => { part => 'RTGR328N', },
   type_length_key(0x9aec, 104) =>
   {
    part => 'RTGR328N', checksum => \&checksum3, method => 'rtgr328n_datetime',
   },
   type_length_key(0x9aea, 104) =>
   {
    part => 'RTGR328N', checksum => \&checksum3, method => 'rtgr328n_datetime',
   },
   type_length_key(0x1a2d, 80) =>
   {
    part => 'THGR228N', checksum => \&checksum2, method => 'common_temphydro',
   },
   type_length_key(0x1a3d, 80) =>
   {
    part => 'THGR918', checksum => \&checksum2, method => 'common_temphydro',
   },
   type_length_key(0x5a5d, 88) =>
   {
    part => 'BTHR918', checksum => \&checksum5,
    method => 'common_temphydrobaro',
   },
   type_length_key(0x5a6d, 96) =>
   {
    part => 'BTHR918N', checksum => \&checksum5, method => 'alt_temphydrobaro',
   },
   type_length_key(0x3a0d, 80) =>
   {
    part => 'WGR918',  checksum => \&checksum4, method => 'wgr918_anemometer',
   },
   type_length_key(0x3a0d, 88) =>
   {
    part => 'WGR918',  checksum => \&checksum4, method => 'wgr918_anemometer',
   },
   type_length_key(0x2a1d, 84) =>
   {
    part => 'RGR918', checksum => \&checksum6, method => 'common_rain',
   },
   type_length_key(0x0a4d, 80) =>
   {
    part => 'THR128', checksum => \&checksum2, method => 'common_temp',
   },
   #type_length_key(0x0a4d,80)=>{ part => 'THR138', method => 'common_temp', },

   type_length_key(0xca2c, 80) =>
   {
    part => 'THGR328N', checksum => \&checksum2, method => 'common_temphydro',
   },

   type_length_key(0xca2c, 120) =>
   {
    part => 'THGR328N', checksum => \&checksum2, method => 'common_temphydro',
   },

   # masked
   type_length_key(0x0acc, 80) =>
   {
    part => 'RTGR328N', checksum => \&checksum2, method => 'common_temphydro',
   },

   type_length_key(0x2a19, 92) =>
   {
    part => 'PCR800',
    checksum => \&checksum8,
    method => 'pcr800_rain',
   },

   type_length_key(0xca48, 68) =>
   {
    part => 'THWR800', checksum => \&checksum1, method => 'common_temp',
   },

   # for testing
   type_length_key(0xfefe, 80) => { part => 'TEST' },
  );

my $DOT = q{.};


sub decode {
  my ($self, $parent, $message, $bytes, $bits, $result) = @_;

  return unless (scalar @$bytes >= 2);

  my $type = ($bytes->[0] << 8) + $bytes->[1];
  my $key = type_length_key($type, $bits);
  my $rec = $types{$key} || $types{$key&0xfffff};
  unless ($rec) {
    return;
  }

  my @nibbles = map { hex $_ } split //, unpack "H*", $message;
#  my @nibbles = map { vec $message, $_ + ($_%2 ? -1 : 1), 4
#                    } 0..(2*length $message);
  my $checksum = $rec->{checksum};
  if ($checksum && !$checksum->($bytes, \@nibbles)) {
    return;
  }

  my $method = $rec->{method};
  unless ($method) {
    warn "Possible message from Oregon part \"", $rec->{part}, "\"\n";
    return;
  }
  my $device = sprintf "%s.%02x", (lc $rec->{part}), $bytes->[3];
  $self->$method($device, $bytes, \@nibbles, $result);
}


sub uv138 {
  my ($self, $device, $bytes, $nibbles, $result) = @_;

  uv($device, $bytes, $nibbles, $result);
  simple_battery($device, $bytes, $nibbles, $result);
  return 1;
}


sub uvn800 {
  my ($self, $device, $bytes, $nibbles, $result) = @_;

  uv2($device, $bytes, $nibbles, $result);
  percentage_battery($device, $bytes, $nibbles, $result);
  return 1;
}


sub wgr918_anemometer {
  my ($self, $device, $bytes, $nib, $result) = @_;

  my $dir = $nib->[10]*100 + $nib->[11]*10 + $nib->[8];
  my $speed = $nib->[15]*10 + $nib->[12] + $nib->[13]/10;
  my $avspeed = $nib->[16]*10 + $nib->[17] + $nib->[14]/10;
  #print "WGR918: $device $dir $speed\n";
  push @{$result->{messages}},
    Device::RFXCOM::Response::Sensor->new(device => $device,
                                          measurement => 'speed',
                                          value => $speed,
                                          units => 'mps',
                                          average => $avspeed,
                                         ),
    Device::RFXCOM::Response::Sensor->new(device => $device,
                                          measurement => 'direction',
                                          value => $dir,
                                          units => 'degrees',
                                         );
  percentage_battery($device, $bytes, $nib, $result);
  return 1;
}


sub wtgr800_anemometer {
  my ($self, $device, $bytes, $nib, $result) = @_;

  my $dir = $nib->[8] * 22.5;
  my $speed = $nib->[14]*10 + $nib->[12] + $nib->[13]/10;
  my $avspeed = $nib->[16]*10 + $nib->[17] + $nib->[14]/10;
  #print "WTGR800: $device $dir $speed\n";
  push @{$result->{messages}},
    Device::RFXCOM::Response::Sensor->new(device => $device,
                                          measurement => 'speed',
                                          value => $speed,
                                          units => 'mps',
                                          average => $avspeed,
                                         ),
    Device::RFXCOM::Response::Sensor->new(device => $device,
                                          measurement => 'direction',
                                          value => $dir,
                                         );
  percentage_battery($device, $bytes, $nib, $result);
  return 1
}


sub alt_temphydro {
  my ($self, $device, $bytes, $nibbles, $result) = @_;

  temperature($device, $bytes, $nibbles, $result);
  humidity($device, $bytes, $nibbles, $result);
  percentage_battery($device, $bytes, $nibbles, $result);
  return 1;
}


sub alt_temphydrobaro {
  my ($self, $device, $bytes, $nibbles, $result) = @_;

  temperature($device, $bytes, $nibbles, $result);
  humidity($device, $bytes, $nibbles, $result);
  pressure($device, $bytes, $nibbles, $result, 18, 856);
  percentage_battery($device, $bytes, $nibbles, $result);
  return 1;
}


sub rtgr328n_datetime {
  my ($self, $device, $bytes, $nib, $result) = @_;

  my $time = $nib->[15].$nib->[12].$nib->[13].$nib->[10].$nib->[11].$nib->[8];
  my $day =
    [ 'Mon', 'Tues', 'Wednes',
      'Thur', 'Fri', 'Satur', 'Sun' ]->[($bytes->[9]&0x7)-1];
  my $date =
    2000+($nib->[21].$nib->[18]).sprintf("%02d",$nib->[16]).
      $nib->[17].$nib->[14];

  #print STDERR "datetime: $date $time $day\n";
  push @{$result->{messages}},
    Device::RFXCOM::Response::DateTime->new(date => $date,
                                            time => $time,
                                            day => $day.'day',
                                            device => $device,
                                           );
  return 1;
}


sub common_temp {
  my ($self, $device, $bytes, $nibbles, $result) = @_;

  temperature($device, $bytes, $nibbles, $result);
  simple_battery($device, $bytes, $nibbles, $result);
  return 1;
}


sub common_temphydro {
  my ($self, $device, $bytes, $nibbles, $result) = @_;

  temperature($device, $bytes, $nibbles, $result);
  humidity($device, $bytes, $nibbles, $result);
  simple_battery($device, $bytes, $nibbles, $result);
  return 1;
}


sub common_temphydrobaro {
  my ($self, $device, $bytes, $nibbles, $result) = @_;

  temperature($device, $bytes, $nibbles, $result);
  humidity($device, $bytes, $nibbles, $result);
  pressure($device, $bytes, $nibbles, $result, 19);
  simple_battery($device, $bytes, $nibbles, $result);
  return 1;
}


sub common_rain {
  my ($self, $device, $bytes, $nib, $result) = @_;

  my $rain = $nib->[10]*100 + $nib->[11]*10 + $nib->[8];
  my $train = $nib->[17]*1000 + $nib->[14]*100 + $nib->[15]*10 + $nib->[12];
  my $flip = $nib->[13];
  #print STDERR "$device rain = $rain, total = $train, flip = $flip\n";
  push @{$result->{messages}},
    Device::RFXCOM::Response::Sensor->new(device => $device,
                                          measurement => 'speed',
                                          value => $rain,
                                          units => 'mm/h',
                                          ),
    Device::RFXCOM::Response::Sensor->new(device => $device,
                                          measurement => 'distance',
                                          value => $train,
                                          units => 'mm',
                                         ),
    Device::RFXCOM::Response::Sensor->new(device => $device,
                                          measurement => 'count',
                                          value => $flip,
                                          units => 'flips',
                                         );
  simple_battery($device, $bytes, $nib, $result);
  return 1;
}


sub pcr800_rain {
  my ($self, $device, $bytes, $nib, $result) = @_;

  my $rain = $nib->[13]*10 + $nib->[10] + $nib->[11]/10 + $nib->[8]/100;
  $rain *= 25.4; # convert from inch/hr to mm/hr

  my $train = $nib->[19]*100 + $nib->[16]*10 + $nib->[17]
    + $nib->[14]/10 + $nib->[15]/100 + $nib->[12]/1000;
  $train *= 25.4; # convert from inch/hr to mm/hr
  #print STDERR "$device rain = $rain, total = $train\n";
  push @{$result->{messages}},
    Device::RFXCOM::Response::Sensor->new(device => $device,
                                          measurement => 'speed',
                                          value => (sprintf "%.2f", $rain),
                                          units => 'mm/h',
                                         ),
    Device::RFXCOM::Response::Sensor->new(device => $device,
                                          measurement => 'distance',
                                          value => (sprintf "%.2f", $train),
                                          units => 'mm',
                                         );
  simple_battery($device, $bytes, $nib, $result);
  return 1;
}


sub checksum1 {
  my $c = $_[1]->[12] + ($_[1]->[15]<<4);
  my $s = ( ( nibble_sum(12, $_[1]) + $_[1]->[13] - 0xa) & 0xff);
  $s == $c;
}


sub checksum2 {
  $_[0]->[8] == ((nibble_sum(16,$_[1]) - 0xa) & 0xff);
}


sub checksum3 {
  $_[0]->[11] == ((nibble_sum(22,$_[1]) - 0xa) & 0xff);
}


sub checksum4 {
  $_[0]->[9] == ((nibble_sum(18,$_[1]) - 0xa) & 0xff);
}


sub checksum5 {
  $_[0]->[10] == ((nibble_sum(20,$_[1]) - 0xa) & 0xff);
}


sub checksum6 {
  $_[1]->[16]+($_[1]->[19]<<4) == ((nibble_sum(16,$_[1]) - 0xa) & 0xff);
}


sub checksum7 {
  $_[0]->[7] == ((nibble_sum(14,$_[1]) - 0xa) & 0xff);
}


sub checksum8 {
  my $c = $_[1]->[18] + ($_[1]->[21]<<4);
  my $s = ( ( nibble_sum(18, $_[1]) - 0xa) & 0xff);
  $s == $c;
}


sub checksum_tester {
  my @bytes = ( @{$_[0]}, 0, 0, 0, 0, 0, 0, 0 );
  my @nibbles = ( @{$_[1]}, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 );
  my $found;
  my @fn = (\&checksum1, \&checksum2, \&checksum3, \&checksum4,
            \&checksum5, \&checksum6, \&checksum7, \&checksum8);
  foreach my $i (0..$#fn) {
    my $sum = $fn[$i];
    if ($sum->(\@bytes, \@nibbles)) {
      $found .= "Possible use of checksum, checksum".($i+1)."\n";
    }
  }

  for my $i (4..(scalar @bytes)-2) {
    my $c = $nibbles[$i*2] + ($nibbles[$i*2+3]<<4);
    my $s = ( ( nibble_sum($i*2, \@nibbles) - 0xa) & 0xff);
    if ($s == $c) {
      $found .= q{($_[1]->[}.($i*2).q{] + ($_[1]->[}.($i*2+3).
        q{])<<4)) == ( ( nibble_sum(}.($i*2).q{, $_[1]) - 0xa) & 0xff);}."\n";
    }
    if ($bytes[$i+1] == ( ( nibble_sum(1+$i*2, \@nibbles) - 0xa) & 0xff)) {
      $found .= q{$_[0]->[}.($i+1).q{] == ( ( nibble_sum(}.(1+$i*2).
        q{, $_[0]) - 0xa) & 0xff)}."\n";
    }
    if ($bytes[$i+1] == ( ( nibble_sum(($i+1)*2, \@nibbles) - 0xa) & 0xff)) {
      $found .= q{$_[0]->[}.($i+1).q{] == ( ( nibble_sum(}.(($i+1)*2).
        q{, $_[0]) - 0xa) & 0xff);}."\n";
    }
  }
  die $found || "Could not determine checksum\n";
}

my @uv_str =
  (
   qw/low low low/, # 0 - 2
   qw/medium medium medium/, # 3 - 5
   qw/high high/, # 6 - 7
   'very high', 'very high', 'very high', # 8 - 10
  );


sub uv_string {
  $uv_str[$_[0]] || 'dangerous';
}


sub uv {
  my ($dev, $bytes, $nib, $result) = @_;
  my $uv =  $nib->[11]*10 + $nib->[8];
  my $risk = uv_string($uv);
  #printf STDERR "%s uv=%d risk=%s\n", $dev, $uv, $risk;
  push @{$result->{messages}},
    Device::RFXCOM::Response::Sensor->new(device => $dev,
                                          measurement => 'uv',
                                          value => $uv,
                                          risk => $risk,
                                        );
  1;
}


sub uv2 {
  my ($dev, $bytes, $nib, $result) = @_;
  my $uv =  $nib->[8];
  my $risk = uv_string($uv);
  #printf STDERR "%s uv=%d risk=%s\n", $dev, $uv, $risk;
  push @{$result->{messages}},
    Device::RFXCOM::Response::Sensor->new(device => $dev,
                                          measurement => 'uv',
                                          value => $uv,
                                          risk => $risk,
                                        );
  1;
}


sub temperature {
  my ($dev, $bytes, $nib, $result) = @_;
  my $temp = $nib->[10]*10 + $nib->[11] + $nib->[8]/10;
  $temp *= -1 if ($bytes->[6]&0x8);
  #printf STDERR "%s temp=%.1f\n", $dev, $temp;
  push @{$result->{messages}},
    Device::RFXCOM::Response::Sensor->new(device => $dev,
                                          measurement => 'temp',
                                          value => $temp,
                                        );
  1;
}


sub humidity {
  my ($dev, $bytes, $nib, $result) = @_;
  my $hum = $nib->[15]*10 + $nib->[12];
  my $hum_str = ['normal', 'comfortable', 'dry', 'wet']->[$bytes->[7]>>6];
  #printf STDERR "%s hum=%d%% %s\n", $dev, $hum, $hum_str;
  push @{$result->{messages}},
    Device::RFXCOM::Response::Sensor->new(device => $dev,
                                          measurement => 'humidity',
                                          value => $hum,
                                          string => $hum_str,
                                         );
  1;
}


sub pressure {
  my ($dev, $bytes, $nib, $result, $forecast_index, $offset) = @_;
  $offset = 795 unless ($offset);
  my $hpa = $bytes->[8]+$offset;
  my $forecast = { 0xc => 'sunny',
                   0x6 => 'partly',
                   0x2 => 'cloudy',
                   0x3 => 'rain',
                 }->{$nib->[$forecast_index]} || 'unknown';
  #printf STDERR "%s baro: %d %s\n", $dev, $hpa, $forecast;
  push @{$result->{messages}},
    Device::RFXCOM::Response::Sensor->new(device => $dev,
                                          measurement => 'pressure',
                                          value => $hpa,
                                          units => 'hPa',
                                          forecast => $forecast
                                         );
  1;
}


sub simple_battery {
  my ($dev, $bytes, $nib, $result) = @_;
  my $battery_low = $bytes->[4]&0x4;
  my $bat = $battery_low ? 10 : 90;
  push @{$result->{messages}},
    Device::RFXCOM::Response::Sensor->new(device => $dev,
                                          measurement => 'battery',
                                          value => $bat,
                                          units => '%');
  $battery_low;
}


sub percentage_battery {
  my ($dev, $bytes, $nib, $result) = @_;
  my $bat = 100-10*$nib->[9];
  push @{$result->{messages}},
    Device::RFXCOM::Response::Sensor->new(device => $dev,
                                          measurement => 'battery',
                                          value => $bat,
                                          units => '%',
                                         );
  $bat < 20;
}


sub type_length_key {
  ($_[0] << 8) + $_[1]
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Device::RFXCOM::Decoder::Oregon - Device::RFXCOM::Decoder::Oregon decode Oregon RF messages

=head1 VERSION

version 1.163170

=head1 SYNOPSIS

  # see Device::RFXCOM::RX

=head1 DESCRIPTION

Module to recognize Oregon RF messages from an RFXCOM RF receiver.

=head1 METHODS

=head2 C<decode( $parent, $message, $bytes, $bits, \%result )>

This method attempts to recognize and decode RF messages from Oregon
Scientific sensors.  If messages are identified, a reference to a list
of message data is returned.  If the message is not recognized, undef
is returned.

=head2 C<uv138( $device, $bytes, $nibbles, \%result )>

This method is called if the device type bytes indicate that the bytes
might contain a message from a UV138 sensor.

=head2 C<uvn800( $device, $bytes, $nibbles, \%result )>

This method is called if the device type bytes indicate that the bytes
might contain a message from a UVN800 sensor.

=head2 C<wgr918_anemometer( $device, $bytes, $nibbles, \%result )>

This method is called if the device type bytes indicate that the bytes
might contain a wind speed/direction message from a WGR918 sensor.

=head2 C<wtgr800_anemometer( $device, $bytes, $nibbles, \%result )>

This method is called if the device type bytes indicate that the bytes
might contain a wind speed/direction message from a WTGR800 sensor.

=head2 C<alt_temphydro( $device, $bytes, $nibbles, \%result )>

This method is called if the device type bytes indicate that the bytes
might contain a temperature/humidity message from a WTGR800 sensor.

=head2 C<alt_temphydrobaro( $device, $bytes, $nibbles, \%result )>

This method is called if the device type bytes indicate that the bytes
might contain a temperature/humidity/baro message from a BTHR918N sensor.

=head2 C<rtgr328n_datetime( $device, $bytes, $nibbles, \%result )>

This method is called if the device type bytes indicate that the bytes
might contain a date/time message from a RTGR328n sensor.

=head2 C<common_temp( $device, $bytes, $nibbles, \%result )>

This method is a generic device method for devices that report
temperature in a particular manner.

=head2 C<common_temphydro( $device, $bytes, $nibbles, \%result )>

This method is a generic device method for devices that report
temperature and humidity in a particular manner.

=head2 C<common_temphydrobaro( $device, $bytes, $nibbles, \%result )>

This method is a generic device method for devices that report
temperature, humidity and barometric pressure in a particular manner.

=head2 C<common_rain( $device, $bytes, $nibbles, \%result )>

This method handles the rain measurements from an RGR918 rain gauge.

=head2 C<pcr800_rain( $device, $bytes, $nibbles, \%result )>

This method handles the rain measurements from a PCR800 rain gauge.

=head2 C<checksum1( $bytes, $nibbles )>

This method is a byte checksum of all nibbles of the first 6 bytes,
the low nibble of the 7th byte, minus 10 which should equal the byte
consisting of a high nibble taken from the low nibble of the 8th byte
plus the high nibble from the 7th byte.

=head2 C<checksum2( $bytes )>

This method is a byte checksum of all nibbles of the first 8 bytes
minus 10, which should equal the 9th byte.

=head2 C<checksum3( $bytes )>

This method is a byte checksum of all nibbles of the first 11 bytes
minus 10, which should equal the 12th byte.

=head2 C<checksum4( $bytes )>

This method is a byte checksum of all nibbles of the first 9 bytes
minus 10, which should equal the 10th byte.

=head2 C<checksum5( $bytes )>

This method is a byte checksum of all nibbles of the first 10 bytes
minus 10, which should equal the 11th byte.

=head2 C<checksum6( $bytes )>

This method is a byte checksum of all nibbles of the first 10 bytes
minus 10, which should equal the 11th byte.

=head2 C<checksum7( $bytes )>

This method is a byte checksum of all nibbles of the first 7 bytes,
minus 10 which should equal the byte
consisting of the 8th byte

=head2 C<checksum8( $bytes )>

This method is a byte checksum of all nibbles of the first 7 bytes,
minus 10 which should equal the byte consisting of the 8th byte

=head2 C<checksum_tester( $bytes, $nibbles )>

This method is a dummy checksum method that tries to guess the checksum
that is required.

=head2 C<uv_string( $uv_index )>

This method takes the UV Index and returns a suitable string.

=head2 C<uv( $device, $bytes, $nibbles, \%result)>

This method processes a UV Index reading.  It appends an xPL message
to the result array.

=head2 C<uv2( $device, $bytes, $nibbles, \%result)>

This method processes a UV Index reading for UVN800 sensor type.  It
appends an xPL message to the result array.

=head2 C<temperature( $device, $bytes, $nibbles, \%result)>

This method processes a temperature reading.  It appends an xPL message
to the result array.

=head2 C<humidity( $device, $bytes, $nibbles, \%result)>

This method processes a humidity reading.  It appends an xPL message
to the result array.

=head2 C<pressure( $device, $bytes, $nibbles, \%result, $forecast_index,
                   $offset )>

This method processes a pressure reading.  It appends an xPL message
to the result array.

=head2 C<simple_battery( $device, $bytes, $nibbles, \%result)>

This method processes a simple low battery reading.  It appends an xPL
message to the result array if the battery is low.

=head2 C<percentage_battery( $device, $bytes, $nibbles, \%result)>

This method processes a battery percentage charge reading.  It appends
an xPL message to the result array if the battery is low.

=head2 C<type_length_key( $type, $length )>

This function creates a simple key from a device type and message
length (in bits).  It is used to as the index for the parts table.

=head1 DEVICE METHODS

=head1 CHECKSUM METHODS

=head1 UTILITY METHODS

=head1 SENSOR READING METHODS

=head1 THANKS

Special thanks to RFXCOM, L<http://www.rfxcom.com/>, for their
excellent documentation and for giving me permission to use it to help
me write this code.  I own a number of their products and highly
recommend them.

=head1 SEE ALSO

RFXCOM website: http://www.rfxcom.com/

=head1 AUTHOR

Mark Hindess <soft-cpan@temporalanomaly.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Mark Hindess.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
