################################################################
#                                                              #
# RCX.pm                                                       #
#                                                              #
# Version 1.01                                                 #
#                                                              #
# (c) 2000 John C. Quillan, All rights reserved                #
#                                                              #
# This program is free softeware, you can redistribute it      #
# and/or modify it under the same terms as Perl itself         #
#                                                              #
# If something doesn't work, email me quillan@cox.net          #
#                                                              #
# Special Thanks to:                                           #
#                                                              #
#   Peter Pletcher <peterp@autobahn.org>                       #
#   Laurent Demailly <L@Demailly.com>                          #
#                                                              #
#                                                              #
################################################################

package LEGO::RCX;

use FileHandle;
use POSIX qw( :termios_h );

$VERSION = "1.01";

@ISA = qw( Exporter );
use strict;


use vars qw (
$SENSOR_TYPE_RAW
$SENSOR_TYPE_TOUCH
$SENSOR_TYPE_TEMPERATURE
$SENSOR_TYPE_LIGHT
$SENSOR_TYPE_ROTATION

$SENSOR_MODE_RAW
$SENSOR_MODE_BOOL
$SENSOR_MODE_EDGE
$SENSOR_MODE_PULSE
$SENSOR_MODE_PERCENT
$SENSOR_MODE_CELSIUS
$SENSOR_MODE_FAHRENHEIT
$SENSOR_MODE_ROTATION

$SENSOR_TOUCH
$SENSOR_LIGHT
$SENSOR_ROTATION
$SENSOR_CELSIUS
$SENSOR_FAHRENHEIT
$SENSOR_PULSE
$SENSOR_EDGE

@EXPORT
);

@EXPORT = qw(
$SENSOR_TYPE_RAW
$SENSOR_TYPE_TOUCH
$SENSOR_TYPE_TEMPERATURE
$SENSOR_TYPE_LIGHT
$SENSOR_TYPE_ROTATION
$SENSOR_MODE_RAW
$SENSOR_MODE_BOOL
$SENSOR_MODE_EDGE
$SENSOR_MODE_PULSE
$SENSOR_MODE_PERCENT
$SENSOR_MODE_CELSIUS
$SENSOR_MODE_FAHRENHEIT
$SENSOR_MODE_ROTATION

$SENSOR_TOUCH
$SENSOR_LIGHT
$SENSOR_ROTATION
$SENSOR_CELSIUS
$SENSOR_FAHRENHEIT
$SENSOR_PULSE
$SENSOR_EDGE

);


$SENSOR_TYPE_RAW         = 0;
$SENSOR_TYPE_TOUCH       = 1;
$SENSOR_TYPE_TEMPERATURE = 2;
$SENSOR_TYPE_LIGHT       = 3;
$SENSOR_TYPE_ROTATION    = 4;

$SENSOR_MODE_RAW         = 0;
$SENSOR_MODE_BOOL        = 1;
$SENSOR_MODE_EDGE        = 2;
$SENSOR_MODE_PULSE       = 3;
$SENSOR_MODE_PERCENT     = 4;
$SENSOR_MODE_CELSIUS     = 5;
$SENSOR_MODE_FAHRENHEIT  = 6;
$SENSOR_MODE_ROTATION    = 7;

#   







#   

$SENSOR_TOUCH      = 0;
$SENSOR_LIGHT      = 1;
$SENSOR_ROTATION   = 2;
$SENSOR_CELSIUS    = 3;
$SENSOR_FAHRENHEIT = 4;
$SENSOR_PULSE      = 5;
$SENSOR_EDGE       = 6;

use vars qw( $O_FH $O_FLIP  $O_NQC_VAR $O_NQC_TASK $O_NQC_SUB
             $O_COMM_TIMEOUT  $O_UPLD_SZ  $O_IS_ALIVE  );
( $O_FH, $O_FLIP, $O_NQC_VAR, $O_NQC_TASK, $O_NQC_SUB,
  $O_COMM_TIMEOUT, $O_UPLD_SZ, $O_IS_ALIVE ) = ( 0 .. 7 );


sub new
{
   my $class = shift;

   my ( $port ) = @_;

   if( ! defined $port ) {
      $port = "/dev/ttyS0";
   }

   my $this = [];


   #
   # Open the serial port
   #
   local *RCX;
   open( RCX, "+< $port" ) || die "Cant open serial";

   #
   # Set up the serial ports paramaters
   #
   my $termios = new POSIX::Termios();

   $termios->getattr( fileno( RCX ) );

   my $c_flag = $termios->getcflag();

   $termios->setcflag( $c_flag | CREAD | CLOCAL | CS8 | PARENB | PARODD );
   $termios->setispeed( B2400 );
   $termios->setospeed( B2400 );

   $termios->setattr( fileno( RCX ), TCSANOW );

   RCX->autoflush();

   $this->[ $O_FH ] = *RCX;

   $this->[ $O_FLIP ] = 0;

   $this->[ $O_COMM_TIMEOUT ] = 2;

   $this->[  $O_UPLD_SZ ] = 1;  # NOT USED YET

   $this->[ $O_IS_ALIVE ] = 0;

   bless $this, $class;

   $this->alive();

   return $this;
}

#
# Not a method.
#
sub mkShort
{
   my( $val ) = @_;

   return unpack "C*", pack "v", $val;
}


sub flip
{
   my $this = shift;
   my( $byte ) = @_;

   if( $this->[ $O_FLIP ] == 1 ) {
      $this->[ $O_FLIP ] = 0;
      return 0x08 ^ $byte;
   }
   else {
      $this->[ $O_FLIP ] = 1;
      return $byte;
   }
}


sub transactCommand
{
   my $this = shift;

   my( $byteCode, $resp_len, $resp_code ) = @_;

   $this->sendPacket( $byteCode );

   my $fh = $this->[ $O_FH ];

   if( $resp_len != -1 ) {
      ##TODO Make a get response method to handle this
      my $retData;

      local $SIG{ ALRM } = sub { die "TIMEOUT" };
      alarm  $this->[ $O_COMM_TIMEOUT ];

      eval {
	 read( $fh, $retData, $resp_len * 2 + 3  + 2 );
	 alarm 0; # Cancel alarm
      };

      if ( $@ =~ /TIMEOUT/ ) {

	 # We timed out.
	 return undef;

      }
      


      ## TODO  Need to check opcode here

      $retData =~ s/^.....//s;  # Strip off header and op code
      $retData =~ s/..$//s;     # Strip off checksum

      $retData =~ s/(.)./$1/gs; # Strip off complement bytes.

      return $retData;

   }

}

sub emit
{
   my $this = shift;
   my ( $byteCode, $resp_len, $resp_code ) = @_;

   if( ! $this->[ $O_IS_ALIVE ] && $byteCode->[ 0 ] != 0x10 ) {
      $this->alive();
   }

   #
   # Unlike the tcl version of this library there is only a
   # immediate mode.  That is why this is so minimal;
   #

   return $this->transactCommand( $byteCode, $resp_len, $resp_code )

}

sub code2packet
{
   my $this = shift;
   my ( $byteCode ) = @_;

   my @HEADER = ( 0x55, 0xff, 0x00 );

   my @packet = ( @HEADER );

   my $checkSum = 0;   
   
   #
   # If any of the nonflip bytecodes are here then don't flip
   #
   # Only flip the flipable bytecodes
   #
   if( ! ( $byteCode->[ 0 ] == 0x17 || 
           $byteCode->[ 0 ] == 0x27 || 
           $byteCode->[ 0 ] == 0x37 || 
           $byteCode->[ 0 ] == 0x43 || 
           $byteCode->[ 0 ] == 0x72 || 
           $byteCode->[ 0 ] == 0x85 || 
           $byteCode->[ 0 ] == 0x90 || 
           $byteCode->[ 0 ] == 0xf6 || 
           $byteCode->[ 0 ] == 0xf7 || 
           $byteCode->[ 0 ] == 0xb2    )) 
   {
      $byteCode->[ 0 ] = $this->flip( $byteCode->[ 0 ] );
   }

   foreach my $byte ( @{$byteCode} ) {

      push @packet, $byte;
      push @packet, ( ~$byte & 0xff );
      
      $checkSum += $byte;
   }
   $checkSum &= 0xff;

   push @packet, $checkSum;
   push @packet, ( ~$checkSum & 0xff );

   return @packet;

}

sub sendPacket
{
   my $this = shift;

   my ( $byteCode ) = @_;

   my @packet = $this->code2packet( $byteCode );

   my $data = pack "C*", @packet;

   my $dataLen = length( $data );

   my $fh = $this->[ $O_FH ];
   print $fh $data;

   local $SIG{ ALRM } = sub { die "TIMEOUT" };

   my $indata;

   #
   # Read the towers echo responce.
   #
   eval {
      my $bytsRead = read( $fh, $indata, $dataLen );

      if( $bytsRead != $dataLen ) {
         return undef;
      }

   };

   if( $@ =~ /TIMEOUT/ ) {
      return undef;
   }

   if( $indata ne $data ) {
      return undef;
   }
}

sub setCommTimeout
{
   my $this = shift;

}
sub motorOn
{
   my $this = shift;
   
   $this->motor( @_, 0x80 );
}


sub motorOff
{
   my $this = shift;

   $this->motor( @_, 0x40 );
}

sub motorFloat
{
   my $this = shift;

   $this->motor( @_, 0x0 );
}

sub motorDir
{
   my $this = shift;
   my( $motors, $dir ) = @_;

   my $data;

   if( $dir =~ /toggle/i ) {
      $data = 0x40;
   }
   elsif( $dir =~ /forward/i ) {
      $data = 0x80;
   }
   elsif( $dir =~ /reverse/i ) {
      $data = 0x00;
   }

   $data = selmotor( $data, $motors );

   $this->emit( [ 0xe1, $data ], 1 );
}

sub motorPower
{
   my $this = shift;
   my( $motors, $power ) = @_;

   return undef if ( $power < 0 || $power > 7 );

   my $motdat = 0x00;

   $motdat = selmotor( $motdat, $motors );

   $this->emit( [ 0x13, $motdat, 0x02, $power ], 1 );

}

sub selmotor
{
   my( $data, $motors ) = @_;

   $data |= 0x01 if( $motors =~ /A/i );
   $data |= 0x02 if( $motors =~ /B/i );
   $data |= 0x04 if( $motors =~ /C/i );

   return $data;
}

sub motor
{
   my $this = shift;
   my( $motors, $onoff ) = @_;

   my $data = $onoff;

   $data = selmotor( $data, $motors );

   $this->emit( [ 0x21, $data ], 1 );

}

sub beep
{
   my $this = shift;
   my( $sound ) = @_;

   return undef if( $sound < 0 || $sound > 5 );

   $this->emit( [ 0x51, $sound ], 1 );
}

sub tone
{
   my $this = shift;
   my( $freq, $duration ) = @_;

   return undef if( $freq < 0 && $freq > 65535 );
   return undef if(  $duration < 0 && $duration > 255 );

   $this->emit( [ 0x23, mkShort( $freq ), $duration ], 1 );

}

sub display
{
   my $this = shift;
   my( $display  ) = @_;

   return undef if( $display < 0 || $display > 6 );

   $this->emit( [ 0x33, 0x02, $display, 0x00 ], 1);
}


sub powerOff
{
   my $this = shift;

   $this->emit( [ 0x60 ], 1 );
}

sub powerDelay
{
   my $this = shift;
   my( $delay ) = @_;

   
   $this->emit( [ 0xb1, $delay ], 1 );
}

sub program
{
   my $this = shift;

   my( $progNum ) = @_;

   return undef if( $progNum < 1 || $progNum > 5 );

   $this->emit( [ 0x91, $progNum - 1 ], 1 );

}

sub watch
{
   my $this = shift;
   my ( $hrs, $mins ) = @_;

   return undef if ( $hrs < 0 || $hrs > 23 );
   return undef if ( $mins < 0 || $mins > 59 );

   $this->emit( [ 0x22, $hrs, $mins ], 1 );
}

##TODO needs testing
sub messageSet
{
   my $this = shift;
   my ( $msg ) = @_;

   return undef if( $msg < 0 || $msg > 255 );

   $this->emit( [ 0xf7, $msg ], -1 );

}

sub start
{
   my $this = shift;
   my ( $task ) = @_;

   if( ! defined $task ) {
      $task = 0;
   }

   if( $task !~ /^\d+/ ) {
      $task = $this->taskTrans( $task );
   }

   return undef if( $task < 0 || $task > 9 );
   
   $this->emit( [ 0x71, $task ], 1 );

}


sub stop
{
   my $this = shift;
   my ( $task ) = @_;


   if( defined $task ) {

      if( $task !~ /^\d+/ ) {
	 $task = $this->taskTrans( $task );
      }

      return undef if( $task < 0 || $task > 9 );
   
      $this->emit( [ 0x81, $task ], 1 );
   }
   else {
      $this->emit( [ 0x50 ], 1 );
   }

}

sub call
{
   my $this = shift;
   my ( $sub ) = @_;

   if( $sub !~ /^\d+/ ) {
      $sub = $this->subTrans( $sub );
   }

   return undef if( $sub < 0 || $sub > 7 );

   $this->emit( [ 0x17, $sub ] );

}

sub clearTimer
{
   my $this = shift;
   my ( $timer ) = @_;

   return undef if( $timer < 0 || $timer > 3 );

   $this->emit( [ 0xa1, $timer ], 1 );
}


*getVar = *getReg;
sub getReg
{
   my $this = shift;
   my ( $regNum ) = @_;


   if( $regNum !~ /^\d+/ ) {
      $regNum = $this->varTrans( $regNum );
   }

   return undef if( $regNum < 0 || $regNum > 31 );

   my $val = $this->emit( [ 0x12, 0x00, $regNum ], 3 );

   return  unpack "v", "$val" ;
     
}

sub _generalSet
{
   my $this = shift;
   my ($regNum, $val, $type ) = @_;

   if( $regNum !~ /^\d+/ ) {
      $regNum = $this->varTrans( $regNum );
   }

   return undef if( $regNum < 0 || $regNum > 31 );

   $this->emit( [ $type, $regNum, 0x02, mkShort( $val ) ], 1 );

}

*setVar = *setReg;
sub setReg
{
   _generalSet( @_, 0x14 );
}

*addToVar = *addToReg;
sub addToReg
{
   _generalSet( @_, 0x24 );
}


*subFromVar = *subFromReg;
sub subFromReg
{
   _generalSet( @_, 0x34 );
}


*divVar = *divReg;
sub divReg
{
   _generalSet( @_, 0x44 );
}


*mulVar = *mulReg;
sub multReg
{
   _generalSet( @_, 0x54 );
}

*andVar = *andReg;
sub andReg
{
   _generalSet( @_, 0x84 );
}

*orVar = *orReg;
sub orReg
{
   _generalSet( @_, 0x94 );
}

sub getSensor
{
   my $this = shift;
   return $this->getSensorAny( @_, 0x09 );
}

sub getSensorType
{
   my $this = shift;
   return $this->getSensorAny( @_, 0x0a );
}

sub getSensorMode
{
   my $this = shift;
   return $this->getSensorAny( @_, 0x0b );
}

sub getSensorRaw
{
   my $this = shift;
   return $this->getSensorAny( @_, 0x0c );
}

sub getSensorBool
{
   my $this = shift;
   return $this->getSensorAny( @_, 0x0d );
}


sub getSensorAny
{
   my $this = shift;
   my ( $sensNum, $source ) = @_;

   $sensNum--;
   return undef if( $sensNum < 0 || $sensNum > 2 );

   my $val = $this->emit( [ 0x12, $source, $sensNum ], 3 );

   return ( unpack "v", "$val" );
}

sub clearSensor
{
   my $this = shift;
   my ( $sensNum ) = @_;

   $sensNum--;
   return undef if( $sensNum < 0 || $sensNum > 2 );

   $this->emit( [ 0xd1, $sensNum ], 1 );
}


sub setSensorMode
{
   my $this = shift;
   my ( $sensNum, $mode, $slope ) = @_;

   $sensNum--;
   return undef if( $sensNum < 0 || $sensNum > 2 );

   return undef if( $mode < 0 || $mode > 7 );

   if( ! defined $slope ) {
      $slope = 0;
   }

   return undef if( $slope < 0 || $slope > 31 );

   my $modeSlope = ( $mode << 5 ) || $slope;

   $this->emit( [ 0x42, $sensNum, $modeSlope ], 1 );
}

sub setSensorType
{
   my $this = shift;
   my ( $sensNum, $type ) = @_;

   $sensNum--;
   return undef if( $sensNum < 0 || $sensNum > 2 );

   return undef if( $type < 0 || $type > 4 );

   $this->emit( [ 0x32, $sensNum, $type ], 1 );

}

sub setSensor
{
   my $this = shift;
   my ( $sensNum, $kind ) = @_;

   if(     $kind == $SENSOR_TOUCH ) {
      $this->setSensorType( $sensNum, $SENSOR_TYPE_TOUCH );
      $this->setSensorMode( $sensNum, $SENSOR_MODE_BOOL );
   }
   elsif( $kind == $SENSOR_LIGHT ) {
      $this->setSensorType( $sensNum, $SENSOR_TYPE_LIGHT );
      $this->setSensorMode( $sensNum, $SENSOR_MODE_PERCENT );
   }
   elsif( $kind == $SENSOR_ROTATION ) {
      $this->setSensorType( $sensNum, $SENSOR_TYPE_ROTATION );
      $this->setSensorMode( $sensNum, $SENSOR_MODE_ROTATION );
   }
   elsif( $kind == $SENSOR_CELSIUS ) {
      $this->setSensorType( $sensNum, $SENSOR_TYPE_TEMPERATURE );
      $this->setSensorMode( $sensNum, $SENSOR_MODE_CELSIUS );
   }
   elsif( $kind == $SENSOR_FAHRENHEIT ) {
      $this->setSensorType( $sensNum, $SENSOR_TYPE_TEMPERATURE );
      $this->setSensorMode( $sensNum, $SENSOR_MODE_FAHRENHEIT );
   }
   elsif( $kind == $SENSOR_PULSE ) {
      $this->setSensorType( $sensNum, $SENSOR_TYPE_TOUCH );
      $this->setSensorMode( $sensNum, $SENSOR_MODE_PULSE );
   }
   elsif( $kind == $SENSOR_EDGE ) {
      $this->setSensorType( $sensNum, $SENSOR_TYPE_TOUCH );
      $this->setSensorMode( $sensNum, $SENSOR_MODE_EDGE );
   }
   else {
      return undef;
   }
}

sub getBattery
{
   my $this = shift;

   my $val = $this->emit( [ 0x30 ], 3 );
   
   return   ( unpack "v", "$val" )/ 1000;

}

sub getVersion
{
   my $this = shift;

   my $val = $this->emit( [ 0x15, 0x01, 0x03, 0x05, 0x07, 0x0b ], 9 );
   
   return  (  unpack "nnnn", "$val" );
}

sub setTXRange
{
   my $this = shift;
   my( $range ) = @_;

   if( $range eq "long" ) {
      $range = 1;
   }
   elsif( $range eq "short" ) {
      $range = 0;
   }
   else {
      return undef;
   }

   $this->emit( [ 0x31, $range ], 1 );   
}

*alive = *ping;
sub ping
{

   my $this = shift;

   my $ret = $this->emit( [ 0x10 ], 1 );
   $this->[ $O_IS_ALIVE ] = ( defined $ret ) ? 1 : 0;

   return $ret


}

sub deleteAllTasks
{
   my $this = shift;

   return $this->emit( [ 0x40 ], 1 );
}

sub deleteTask
{
   my $this = shift;
   my( $task ) = @_;

   if( $task !~ /^\d+/ ) {
      $task = $this->taskTrans( $task );
   }

   return undef if( $task < 0 || $task > 9 );

   return $this->emit( [ 0x61 ], $task, 1 );
}

sub deleteAllSubs
{
   my $this = shift;

   return $this->emit( [ 0x70 ], 1 );
}


sub deleteSub
{
   my $this = shift;
   my( $sub ) = @_;

   if( $sub !~ /^\d+/ ) {
      $sub = $this->subTrans( $sub );
   }

   return undef if( $sub < 0 || $sub > 7 );

   return $this->emit( [ 0xc1 ], $sub, 1 );
}

sub DESTROY 
{
   my $this = shift;

   close( $this->[ $O_FH ] );

}


sub uploadDatalog
{
   my $this = shift;

   my $data = $this->emit( [ 0xa4, mkShort( 0 ), mkShort( 1 ) ], 4 );

   my( $type, $length ) = unpack "Cv", $data;
 
   $length = $length - 1; # remove 1 for the first data point

   if( $type != 0xff ) {
      return undef;
   }

   $data = "";

   ##TODO This needs to upload chunks for better performance

   my $count = 0;
   my @out = ();

   while( $count < $length ) {

      $data = $this->emit( [ 0xa4, mkShort( $count + 1 ), mkShort( 1 ) ], 4 );

      push @out, ( unpack "Cv", $data );
      $count++;
   }

   return @out;

}
################################################################
#
# NQC list translation stuff
#
################################################################

sub loadNQClist
{
   my $this = shift;
   my( $fileName ) = @_;

   open( NQCLST, $fileName ) || die "Cant open $fileName";

   my $line;
   while( defined( $line = <NQCLST> ) ) {

      if( $line =~ /^\*\*\*\s+Var\s+(\d+)\s+=\s+(\w+)/ ) {
         $this->[ $O_NQC_VAR ]{ $2 } = $1;
      }
      elsif( $line =~ /^\*\*\*\s+Task\s+(\d+)\s+=\s+(\w+)/ ) {
         $this->[ $O_NQC_TASK ]{ $2 } = $1;
      }
      elsif( $line =~ /^\*\*\*\s+Sub\s+(\d+)\s+=\s+(\w+)/ ) {
         $this->[ $O_NQC_SUB ]{ $2 } = $1;
      }
   }

}


sub varTrans
{
   my $this = shift;
   my ( $varName ) = @_;

   return $this->[ $O_NQC_VAR ]{ $varName };
}

sub taskTrans
{
   my $this = shift;
   my ( $taskName ) = @_;

   $this->[ $O_NQC_TASK ]{ $taskName };
}

sub subTrans
{
   my $this = shift;
   my ( $subName ) = @_;

   $this->[ $O_NQC_SUB ]{ $subName };
}

1;

__END__

=head1 NAME

RCX

=head1 SYNOPSIS

   use LOGO::RCX;

   $rcx = new LEGO::RCX();

   #
   # Turn motor A on for 10 seconds, then turn
   # it off
   #
 
   $rcx->motorOn( "A" );

   sleep( 10 );

   $rcx->motorOff( "A" );

=head1 DESCRIPTION

This module allows one to communicate with the Lego MindStorms(R) RCX
brick from a workstation through the IR tower.

The internals of this module are based of the B<rcx.tcl> by 
Peter Pletcher <peterp@autobahn.org> and Laurent Demailly <L@Demailly.com>.
I have hower made my external interface to this module OO based, and changed
the way a few things are done.

Without there tcl module I would have never been able to complete this in
a timely manner.  Thanks guys.


=head1 METHODS

=over

=item ping() or alive()

Check to see if RCX is on and responding.  A defined value
on the return means it is alive, an undef means it is not alive.

=item motorOn( motors )

Turns motor(s) on

Motors are specifed in string format
   eg: "A"
   eg: "bc"

=item motorOff( motors )

Turns motor(s) off

Motors are specifed in string format
   eg: "A"
   eg: "bc"

=item motorFloat( motors )

Floats motor(s) output

Motors are specifed in string format
   eg: "A"
   eg: "bc"


=item motorPower( motors, power )

Sets the motors power to value from 0-7

Motors are specifed in string format
   eg: "A"
   eg: "bc"


=item motorDir( motors, direction 

Sets the motors direction which can be
"forward", "reverse", or "toggle"

Motors are specifed in string format
   eg: "A"
   eg: "bc"

=item beep( sound );

Plays on of the following sounds

  0  Blip
  1  Beep beep
  2  Downward tones
  3  Upward tones
  4  Low buzz
  5  Fast upward tones

=item tone( frequence, duration )

Plays a tone of a specific frequency for a length
of duration

frequency is in Hz and duration is in 1/100th of a second.

=item display( display )

Selects the display for the RCX.

The valid display values are:

  0 Watch
  1 Sensor 1 
  2 Sensor 2 
  3 Sensor 3 
  4 Motor A 
  5 Motor B 
  6 Motor C 

=item powerOff()

Powers the RCX off.

=item powerDelay( delay )

Sets the power off delay time for the RCX.  The delay
is measured in minutes.  A 0 value tells the RCX to never 
power off, and vuture powerOff() calls will fail.

=item program( program_number )

Sets the RCX to be on the specified program number.
The valid program_number values ares 1-5.

=item watch( hour, minutes)

Sets the RCX's watch to hour house and minute
mintutes. hour is 0-23 and minutes is 0-59.

=item messageSet( message )

Set a message in the RCX.  Valid message values
are 0-255.

=item start( task|name ) || start()

Starts a specific task running.  If no task is specified
it defaults to task 0.  Valid task values are 0-9.

If the B<loadNQClist> method has been called then you can specify
a task name

=item stop( task|name ) || stop();

Stops a specific task.  If no task is specified it will
stop all running tasks.

If the B<loadNQClist> method has been called then you can specify
a task name

=item call( subnumber|name )

Call a subroutine.  

If the B<loadNQClist> method has been called then you can specify
a subroutine name.


=item clearTimer( timer )

This will clear the selected RCX timer.  The timer values
are from 0-3.

=item clearSensor( sensor_number )

This will clear the counter associated with sensor_number sensor.

=item setSensorType( sensor_number, sensor_type )

This will set the sensor sensor_number's type to sensor_type.
The type value can be any one of the following.

 $SENSOR_TYPE_RAW
 $SENSOR_TYPE_TOUCH
 $SENSOR_TYPE_TEMPERATURE
 $SENSOR_TYPE_LIGHT
 $SENSOR_TYPE_ROTATION

=item setSensorMode( sensor_number, sensor_mode, [ slope ] )

This will set the sensor sensor_number's mode to sensor_mode, with
said slope.  If slope is omited it defaults to 0.  This is like
NQC.

The mode value can be any one of the following.

 $SENSOR_MODE_RAW
 $SENSOR_MODE_BOOL
 $SENSOR_MODE_EDGE
 $SENSOR_MODE_PULSE
 $SENSOR_MODE_PERCENT
 $SENSOR_MODE_CELSIUS
 $SENSOR_MODE_FAHRENHEIT
 $SENSOR_MODE_ROTATION

=item setSensor( sensor_number, sensor_kind )

This will set the sensor sensor_number's kind to sensor_kind. This
is like the NQC function B<SetSensor>.

The kind value can be any one of the following.

 $SENSOR_TOUCH
 $SENSOR_LIGHT
 $SENSOR_ROTATION
 $SENSOR_CELSIUS
 $SENSOR_FAHRENHEIT
 $SENSOR_PULSE
 $SENSOR_EDGE

=item getReg( register ) | getVar( variable )

Get the value of a variable/register (the same thing) in the
RCX.  The register/variable can be from 0-31.

If the B<loadNQClist> method has been called then you can specify
a variable name instead of a number.

=item setReg( register, value ) | setVar( variable, value );

Set the value of a variable/register (the same thing) in the
RCX to value.  The register/variable can be from 0-31.

If the B<loadNQClist> method has been called then you can specify
a variable name instead of a number.

=item addReg( register, value ) | addVar( register, value )

Add value to a register and store back in register.

=item subReg( register, value ) | subVar( register, value )

Subtract value from a register and store back in register.

=item mulReg( register, value ) | mulVar( register, value )

Multiply value to a register and store back in register.

=item divReg( register, value ) | divVar( register, value )

Divide value into a register and store back in register.

=item andReg( register, value ) | andVar( register, value )

And value with a register and store back in register.

=item orReg( register, value ) | orVar( register, value )

Or value with a register and store back in register.

=item getSensor( sensor_number )

Get value of a sensor sensor_number.  sensor_number can be 1-3.

=item getSensorType( sensor_number )

Get type of a sensor  sensor_number.  sensor_number can be 1-3.

=item getSensorMode( sensor_number )

Get mode of a sensor  sensor_number.  sensor_number can be 1-3.

=item getSensorRaw( sensor_number )

Get raw value of a sensor  sensor_number.  sensor_number can be 1-3.

=item getSensorBool( sensor_number )

Get boolean value of a sensor  sensor_number.  sensor_number can be 1-3.

=item setTXRange( range )

Set the Transmit range of the RCX.  Ranges are eithor "short" or "long"

=item deleteAllTasks()

Delete all tasks in current program

=item deleteTask( task )

Delete <task> task in current program.  

If the B<loadNQClist> method has been called then you can specify
a task name.

=item deleteAllSubs()

Delete a subroutines in current program

=item deleteSub( sub )

Delete all subroutines in current program

If the B<loadNQClist> method has been called then you can specify
a subroutine name.

=item getBattery()

Returns the battery voltage in volts.

=item getVersion()

Returns the version of the ROM and Firmware in the following
order.
( $ROMMajor, $ROMMinor, $FIRMMajor, $FIRMMinor );

=item setCommTimeout( timeout )

Sets the timeout in seconds for all commands sent to the
RCX.  Default is 2 seconds.

=item uploadDatalog()

Returns an array of the datalog.  Each item in the data
log has two elements in the array. The first is the
type of data being loged, and the second is the value
of the data.  The different types are listed as follows (taken
from http://graphics.stanford.edu/~kekoa/rcx/opcodes.html

    0x00-0x1f
            Variable value (source 0, variables 0..31) 
    0x20-0x23
            Timer value (source 1, timers 0..3) 
    0x40-0x42
            Sensor reading (source 9, sensors 0..2) 
    0x80
            Clock reading (source 14) 


=item loadNQClist( nqc_list_file_name )

This method will read in a list file produced by nqc version
2.0.  It parses out the variable, task, and subrouting information
to allow you to use names in the related calls instead of just
the numbers.  This will also allow the fredom to move things
around with out impacting the code.

=back

=head1 NOTES

I have developed this software under Linux.  I know it works there.

=head1 AUTHORS

John C. Quillan quillan@cox.net

=head1 MODIFICATION HISTORY

 01/29/2000   VER 0.5   First Version
 02/04/2000   VER 0.6   Removed some commented code
                        Added posix serial code.
 02/06/2000   VER 0.7   Added the alive/ping method
                        Added the time out for communications.
                        Added the setCommTimeout method
                        Added the uploadDatalog method
 02/22/2000   VER 0.8   Fixed wrong named method in NQC translation
                        Added getVersion                 
                        Added clearSensor
                        Started sensor config code
                        Moved package RCX to Lego::RCX
                        Made a real perl module with Makefile.PL
                        Added div,mul,add,sub,and,or
                          variable
                        Added setTXRange
                        Added deleteAllTasks and deleteAllSubs
                        Added deleteTask and deleteSub
 02/29/2000   VER 0.9   Moved package from Lego::RCX to LEGO::RCX
                        Added setSensor, setSensorMode, setSensorType
                        Fixed / 1000 bug in getReg.
                        Fixed bug in pattern matches that was not catching
                         0x0a characters.  Now a single line match.

 04/16/2000   VER 1.00  Clean up source a little bit.
                        Made README more descriptive for CPAN users.
                        Fixed some typo in the pod documentation for the
                         usage. Sorry for any problems this may have
                         caused.
                        Fixed a typo in the warning.
                        Added a few samples to start off with
