use strict;
use warnings;
package Device::CurrentCost::Message;
$Device::CurrentCost::Message::VERSION = '1.142240';
# ABSTRACT: Perl modules for Current Cost energy monitor messages


use constant DEBUG => $ENV{DEVICE_CURRENT_COST_DEBUG};

use Carp qw/croak carp/;
use Device::CurrentCost::Constants;
use List::Util qw/min/;


sub new {
  my ($pkg, %p) = @_;
  croak $pkg.'->new: message parameter is required' unless (exists $p{message});
  my $self = bless { %p }, $pkg;
  $self;
}


sub device_type {
  my $self = shift;
  return $self->{device_type} if (exists $self->{device_type});
  $self->{device_type} =
    $self->message =~ m!<src><name>! ? CURRENT_COST_CLASSIC : CURRENT_COST_ENVY;
}


sub device {
  my $self = shift;
  return $self->{device}->[0] if (exists $self->{device});
  $self->_find_device->[0]
}


sub device_version {
  my $self = shift;
  return $self->{device}->[1] if (exists $self->{device});
  $self->_find_device->[1]
}

sub _find_device {
  my $self = shift;
  my $name = $self->_parse_field('name');
  $self->{device} =
    defined $name ?
      [ $name, 'v'.$self->_parse_field('sver')] :
        [ split /-/, $self->_parse_field('src'), 2 ];
}


sub message { shift->{message} }

sub _parse_field {
  my ($self, $field, $default) = @_;
  return $self->{$field} if (exists $self->{$field});
  if ($self->message =~ m!<$field>(.*?)</$field>!s) {
    my $v = $1;
    $self->{$field} =
      ($v =~ m!<([^>]+)>(.*?)</\1>!s) ? { value => $2, units => $1 } : $v;
  } elsif (defined $default) {
    return $default;
  } else {
    return
  }
}


sub dsb { shift->_parse_field('dsb') }



sub days_since_boot { shift->dsb }


sub time {
  my $self = shift;
  my $time = $self->_parse_field('time');
  return $time if (defined $time);
  $self->{time} =
    $self->_parse_field('hr').':'.
      $self->_parse_field('min').':'.
        $self->_parse_field('sec')
}


sub time_in_seconds {
  my $self = shift;
  return $self->{time_in_seconds} if (exists $self->{time_in_seconds});
  my ($h, $m, $s) = split /:/, $self->time, 3;
  $self->{time_in_seconds} = $h*3600 + $m*60 + $s;
}


sub boot_time {
  my $self = shift;
  $self->days_since_boot * 86400 + $self->time_in_seconds
}


sub sensor { shift->_parse_field('sensor', 0) }


sub id { shift->_parse_field('id') }


sub type { shift->_parse_field('type') }


sub tmpr { shift->_parse_field('tmpr') }


sub temperature { shift->tmpr }


sub has_history { shift->message =~ /<hist>/ }


sub has_readings { shift->message =~ /<ch1>/ }


sub units {
  my $self = shift;
  my $ch1 = $self->_parse_field('ch1') or return;
  $ch1->{units}
}


sub value {
  my ($self, $channel) = @_;
  $self->units || return; # return if no units can be found - historic only
  if ($channel) {
    return $self->_parse_field('ch'.$channel, { value => undef })->{value};
  }
  return $self->{total} if (exists $self->{total});
  foreach (1 .. 3) {
    $self->{total} += $self->value($_)||0;
  }
  $self->{total}
}


sub summary {
  my ($self, $prefix) = @_;
  $prefix = '' unless (defined $prefix);
  my $str = $prefix.'Device: '.$self->device.' '.$self->device_version."\n";
  $prefix .= '  ';
  if ($self->has_readings) {
    $str .= $prefix.'Sensor: '.$self->sensor;
    $str .= (' ['.$self->id.','.$self->type."]\n".
             $prefix.'Total: '.$self->value.' '.$self->units."\n");
    foreach my $phase (1..3) {
      my $v = $self->value($phase);
      next unless (defined $v);
      $str .= $prefix.'Phase '.$phase.': '.($v+0)." ".$self->units."\n";
    }
  }
  if ($self->has_history) {
    $str .= $prefix."History\n";
    my $hist = $self->history;
    foreach my $sensor (sort keys %$hist) {
      $str .= $prefix.'  Sensor '.$sensor."\n";
      foreach my $span (sort keys %{$hist->{$sensor}}) {
        foreach my $age (sort { $a <=> $b } keys %{$hist->{$sensor}->{$span}}) {
          $str .= $prefix.'    -'.$age.' '.$span.': '.
            (0+$hist->{$sensor}->{$span}->{$age})."\n";
        }
      }
    }
  }
  $str
}


sub history {
  my $self = shift;
  return $self->{history} if (exists $self->{history});
  my %hist = ();
  $self->{history} = \%hist;
  return $self->{history} unless ($self->has_history);
  my $xml = $self->message;
  if ($xml =~ /<data>/) {
    # envy
    foreach my $data (split qr!</data><data>!, $xml) {
      my ($sensor) = ($data =~ /<sensor>(\d+)</) or next;
      my %rec = ();
      $hist{$sensor} = _parse_history($data);
    }
  } else {
    # classic
    $hist{$self->sensor} = _parse_history($xml);
  }
  \%hist;
}

sub _parse_history {
  my $string = shift;
  my %rec = ();
  foreach my $span (qw/hours days months years/) {
    my $first = substr $span, 0, 1;
    while ($string =~ m!<$first(\d+)>([^<]+)</$first\1>!mg) {
      $rec{$span}->{0+$1} = 0+$2;
    }
  }
  \%rec;
}

1;

=pod

=encoding UTF-8

=head1 NAME

Device::CurrentCost::Message - Perl modules for Current Cost energy monitor messages

=head1 VERSION

version 1.142240

=head1 SYNOPSIS

  use Device::CurrentCost::Message;
  my $msg = Device::CurrentCost::Message->new(message => '<msg>...</msg>');
  print 'Device: ', $msg->device, ' ', $msg->device_version, "\n";
  if ($msg->has_readings) {
    print 'Sensor: ', $msg->sensor, '.', $msg->id, ' (', $msg->type, ")\n";
    print 'Total: ', $msg->value, ' ', $msg->units, "\n";
    foreach my $phase (1..3) {
      print 'Phase ', $phase, ': ',
        $msg->value($phase)+0, " ", $msg->units, "\n";
    }
  }

  use Data::Dumper;
  print Data::Dumper->Dump([$msg->history]) if ($msg->has_history);

  # or
  print $msg->summary, "\n";

=head1 DESCRIPTION

=head1 METHODS

=head2 C<new(%parameters)>

This constructor returns a new Current Cost message object.
The supported parameters are:

=over

=item message

The message data.  Usually a string like 'C<< <msg>...</msg> >>'.
This parameter is required.

=back

=head2 C<device_type()>

Returns the type of the device that created the message.

=head2 C<device()>

Returns the name of the device that created the message.

=head2 C<device_version()>

Returns the version of the device that created the message.

=head2 C<message()>

Returns the raw data of the message.

=head2 C<dsb()>

Returns the days since boot field of the message.

=head2 C<days_since_boot()>

Returns the days since boot field of the message.

=head2 C<time()>

Returns the time field of the message in C<HH:MM:SS> format.

=head2 C<time_in_seconds()>

Returns the time field of the message in seconds.

=head2 C<boot_time()>

Returns the time since boot reported by the message in seconds.

=head2 C<sensor()>

Returns the sensor number field of the message.  A classic monitor
supports only one sensor so 0 is returned.

=head2 C<id()>

Returns the id field of the message.

=head2 C<type()>

Returns the sensor type field of the message.

=head2 C<tmpr()>

Returns the tmpr/temperature field of the message.

=head2 C<temperature()>

Returns the temperature field of the message.

=head2 C<has_history()>

Returns true if the message contains history data.

=head2 C<has_readings()>

Returns true if the message contains current data.

=head2 C<units()>

Returns the units of the current data readings in the message.

=head2 C<value( [$channel] )>

Returns the value of the current data reading for the given channel
(phase) in the message.  If no channel is given then the total of all
the current data readings for all channels is returned.

=head2 C<summary( [$prefix] )>

Returns the string summary of the data in the message.  Each line of the
string is prefixed by the given prefix or the empty string if the prefix
is not supplied.

=head2 C<history()>

Returns a data structure contain any history data from the message.

=head1 AUTHOR

Mark Hindess <soft-cpan@temporalanomaly.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Mark Hindess.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

ENVY:

<msg><src>CC128-v0.11</src><dsb>00089</dsb><time>13:02:39</time><tmpr>18.7</tmpr><sensor>1</sensor><id>01234</id><type>1</type><ch1><watts>00345</watts></ch1><ch2><watts>02151</watts></ch2><ch3><watts>00000</watts></ch3></msg>

<msg><src>CC128-v0.11</src><dsb>00596</dsb><time>13:11:20</time><hist><dsw>00597</dsw><type>1</type><units>kwhr</units><data><sensor>0</sensor><h250>7.608</h250><h248>7.163</h248><h246>6.541</h246><h244>3.270</h244></data><data><sensor>1</sensor><h250>0.000</h250><h248>0.000</h248><h246>0.000</h246><h244>0.000</h244></data><data><sensor>2</sensor><h250>0.000</h250><h248>0.000</h248><h246>0.000</h246><h244>0.000</h244></data><data><sensor>3</sensor><h250>0.000</h250><h248>0.000</h248><h246>0.000</h246><h244>0.000</h244></data><data><sensor>4</sensor><h250>0.000</h250><h248>0.000</h248><h246>0.000</h246><h244>0.000</h244></data><data><sensor>5</sensor><h250>0.000</h250><h248>0.000</h248><h246>0.000</h246><h244>0.000</h244></data><data><sensor>6</sensor><h250>0.000</h250><h248>0.000</h248><h246>0.000</h246><h244>0.000</h244></data><data><sensor>7</sensor><h250>0.000</h250><h248>0.000</h248><h246>0.000</h246><h244>0.000</h244></data><data><sensor>8</sensor><h250>0.000</h250><h248>0.000</h248><h246>0.000</h246><h244>0.000</h244></data><data><sensor>9</sensor><h250>0.000</h250><h248>0.000</h248><h246>0.000</h246><h244>0.000</h244></data></hist></msg>

CLASSIC:

<msg><date><dsb>00001</dsb><hr>12</hr><min>32</min><sec>01</sec></date><src><name>CC02</name><id>12345</id><type>1</type><sver>1.06</sver></src><ch1><watts>07806</watts></ch1><ch2><watts>00144</watts></ch2><ch3><watts>00144</watts></ch3><tmpr>21.1</tmpr></msg>

<msg><date><dsb>00001</dsb><hr>12</hr><min>32</min><sec>13</sec></date><src><name>CC02</name><id>12345</id><type>1</type><sver>1.06</sver></src><ch1><watts>07752</watts></ch1><ch2><watts>00144</watts></ch2><ch3><watts>00144</watts></ch3><tmpr>21.0</tmpr><hist><hrs><h02>001.3</h02><h04>000.0</h04><h06>000.0</h06><h08>000.0</h08><h10>000.0</h10><h12>000.0</h12><h14>000.0</h14><h16>000.0</h16><h18>000.0</h18><h20>000.0</h20><h22>000.0</h22><h24>000.0</h24><h26>000.0</h26></hrs><days><d01>0000</d01><d02>0000</d02><d03>0000</d03><d04>0000</d04><d05>0000</d05><d06>0000</d06><d07>0000</d07><d08>0000</d08><d09>0000</d09><d10>0000</d10><d11>0000</d11><d12>0000</d12><d13>0000</d13><d14>0000</d14><d15>0000</d15><d16>0000</d16><d17>0000</d17><d18>0000</d18><d19>0000</d19><d20>0000</d20><d21>0000</d21><d22>0000</d22><d23>0000</d23><d24>0000</d24><d25>0000</d25><d26>0000</d26><d27>0000</d27><d28>0000</d28><d29>0000</d29><d30>0000</d30><d31>0000</d31></days><mths><m01>0000</m01><m02>0000</m02><m03>0000</m03><m04>0000</m04><m05>0000</m05><m06>0000</m06><m07>0000</m07><m08>0000</m08><m09>0000</m09><m10>0000</m10><m11>0000</m11><m12>0000</m12></mths><yrs><y1>0000000</y1><y2>0000000</y2><y3>0000000</y3><y4>0000000</y4></yrs></hist></msg>
