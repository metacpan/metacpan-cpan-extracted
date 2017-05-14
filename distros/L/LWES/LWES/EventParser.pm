package LWES::EventParser;

use strict;
use Encode;

require Exporter;
@LWES::EventParser::ISA = qw(Exporter);

our @EXPORT = qw(bytesToEvent);

# This package will take a string which a raw event off the wire, or the
# payload of an event out of a journal, and turn it into a Perl hash.
#
# Note this is much slower than the listener in the C library, and that
# is recommended if you are concerned about performance.
#
# Typically this can be used if you want to quickly inspect some of the
# events on the network with a simple script.

sub bytesToEvent {
  my $blob = shift;

  my $event={};
  my @a=unpack('C*',$blob);
  my $i=0;

  my $length=($a[$i] & 0xff);
  $i+=1;
  my $event_type=substr($blob,$i,$length);
  $event->{'EventType'} = $event_type;

  $i+=$length;
  my $elements=($a[$i]<<8)|$a[$i+1];
  $i+=2;

  my $key;
  my $value;
  for (my $j=0;$j<$elements;++$j) {
    $length=($a[$i] & 0xff);
    $i+=1;
    $key=substr($blob,$i,$length);
    $i+=$length;

    my$type=($a[$i] & 0xff);
    $i+=1;
    if (($type == 1) || ($type == 2)) {
      # int16
      $value=(($a[$i]<<8)|$a[$i+1])&0xffff;
      $i+=2;
    } elsif (($type == 3) || ($type == 4)) {
      # int32
      $value=($a[$i]<<24)|($a[$i+1]<<16)|($a[$i+2]<<8)|$a[$i+3];
      $i+=4;
    } elsif ($type == 5) {
      # String
      $length=(($a[$i]<<8)|$a[$i+1])&0xffff;
      $i+=2;
      if ( exists($event->{'enc'}) && $event->{'enc'} == 1 ) {
        $value=Encode::decode_utf8(substr($blob,$i,$length));
      } else {
        $value=substr($blob,$i,$length);
      }
      $i+=$length;
    } elsif ($type == 6) {
      $value=sprintf("%d.%d.%d.%d",$a[$i+3],$a[$i+2],$a[$i+1],$a[$i]);
      $i+=4;
    } elsif (($type == 7) || ($type == 8)) {
      # int64 as hexstring
      $value=sprintf("%02X"x8,$a[$i]  ,$a[$i+1],$a[$i+2],$a[$i+3],
                     $a[$i+4],$a[$i+5],$a[$i+6],$a[$i+7]);
      $i+=8;
    } elsif ($type == 9) {
      $value=($a[$i])?1:0;
      $i+=1;
    }
    $event->{$key}=$value;
  }
  return $event;
}

1;

