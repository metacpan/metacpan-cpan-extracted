package Device::IRU_GE;

use 5.008008;
#use strict;
#use warnings;

#-#use Win32::SerialPort qw(:STAT 0.19 );
use Device::SerialPort qw( :PARAM :STAT 0.07 );

use Time::HiRes qw(sleep gettimeofday);
use Data::Dumper;
use Math::Trig qw(asin rad2deg pi);

require Exporter;
our @ISA = qw(Exporter);

our $VERSION = '0.92';

our @EXPORT_OK = qw();
our @EXPORT = qw();

# --- Conversion factors ---
my  $LL_cnv = pi / 2**30; 
my  $HDG_cnv = (360/6400) / 100; 

# - - - - - - - - - - - - - - - -
sub new
{
  my $caller = shift @_;

  # In case someone wants to sub-class
  my $caller_is_obj  = ref($caller);
  my $class = $caller_is_obj || $caller;

  # Passing reference or hash
  my %arg_hsh;
  if ( ref($_[0]) eq "HASH" ) { %arg_hsh = %{ shift @_ } }
  else                        { %arg_hsh = @_ }

  my $port = $arg_hsh{'port'} || "COM3";
 
  my $port_obj = new Device::SerialPort ($port) || die "Can't open $port: $^E\n";
  #-#my $port_obj = new Win32::SerialPort ($port) || die "Can't open $port: $! $^E\n";

  my $baudrate = $arg_hsh{baudrate} || 19200;
 
  my $parity   = $arg_hsh{parity}   || "none";
  my $databits = $arg_hsh{databits} || 8;
  my $stopbits = $arg_hsh{stopbits} || 1;


  # After new, must check for failure
  $port_obj->baudrate($baudrate);
  $port_obj->parity($parity);
  $port_obj->databits($databits);
  $port_obj->stopbits($stopbits);

  #$port_obj->handshake('rts');

  if ( $^O =~ /MS/ )
  {
    $port_obj->read_interval(500);    # max time between read char (milliseconds)
    $port_obj->read_const_time(500);  # Functions as a timeout
  } 
 
  #-# $port_obj->read_interval(1);    # max time between read char (milliseconds) Not in Device::SerialPort 
   $port_obj->read_const_time(10000);  # total = (avg * bytes) + const THIS IS NECESSARY!!!!
    
  #$port_obj->handshake("rts");
  #$port_obj->buffers(4096, 4096);
 
  $port_obj->write_settings || undef $port_obj;

  unless ($port_obj) { die "Can't change Device_Control_Block: $^E\n"; }

  my ($BlockingFlags, $InBytes, $OutBytes, $LatchErrorFlags) = $port_obj->status
      || warn "could not get port status\n";

  if ($BlockingFlags)
  {
     #warn "Port is blocked $BlockingFlags, $InBytes, $OutBytes, $LatchErrorFlags\n";
  }

  if ($BlockingFlags & BM_fCtsHold) { warn "Waiting for CTS"; }
  if ($LatchErrorFlags & CE_FRAME) { warn "Framing Error"; }

  $port_obj->purge_all();  # these don't seem to work but try anyway.
  $port_obj->purge_rx();

  # The object data structure
  my $self = bless {
                        'arg_hsh'         => { %arg_hsh },
                        'fh'              => $arg_hsh{fh},
                        'continuous_mode' => $arg_hsh{'continuous_mode'},
                        'port_obj'        => $port_obj,
                        'cmd'             => '',
                        'rsp'             => [],
                        'factor'          => { %factor }
                   }, $class;
  return $self;
}

#-----------------------------------------------------
# Test using serial plug
#-----------------------------------------------------
sub plug_test
{
  my $self = shift @_; 
  #my $cmd = shift @_; 

  my $cmd = "Round Trip Worked\n";
  
  my $cnt_out = $self->{'port_obj'}->write($cmd);
  unless ($cnt_out) { warn "write failed\n" };

  my $cmd_len = bytes::length($cmd);
  if ( $cnt_out != $cmd_len ) { die "write incomplete only wrote $cnt_out should have written $cmd_len\n"};

  sleep (1);  # Necessary?

  # ------ Send to unit ----- 
  my $length = length($cmd);
  my ($count_in, $str_read) = $self->{'port_obj'}->read($length);
  if ( $count_in == 0) { warn "Time out on read for $caller\n"; }

  #my $char_lst = join "", unpack("C*",$str_read);
  #print "$length ::: $count_in |$char_lst|$str_read|\n";

  return $str_read; 
}


#----------------------------------------------------------------------
sub get_test_sequence
{
  my $self = shift @_; 

  # Word 1: Header = 0009h
  # Word 2: Data word 1 to be echoed
  # Word 3: Data word 2 to be echoed
  # Word 4: Data word 3 to be echoed
  # Word 5: Data word 4 to be echoed
  # Word 6: Data word 5 to be echoed
  # Word 7: Data word 6 to be echoed
  # Word 8: 16-bit checksum for this message

  my @lst = _transact($self,['0x0009','72','101','76','76','79','33']);

  return @lst;
}

#----------------------------------------------------------------------
sub get_unit_partno
{
  my $self = shift @_;
  #my @lst = _transact($self,['0x0050','00','00','00','00','00','00']);
  my @lst = _transact($self,['0xF150', '0', '0', '0', '0', '0' ,'0']);

  return @lst;
}



#----------------------------------------------------------------------
sub get_temperature
{
  my $self = shift @_;

  #Byte 1 Header byte = 0x07
  #Byte 2 Temp MSB
  #Byte 3 Temp LSB
  #Byte 4 TimerTicks MSB
  #Byte 5 TimerTicks LSB
  #Byte 6 Checksum MSB
  #Byte 7 Checksum LSB

  my @lst = _transact($self,['0x07'],7);
  #shift @lst;
  return @lst;

}

#----------------------------------------------------------------------
sub get_lat_lon
{
 # lat and lon are hardwired :( so I find out. 
 
  my $self = shift @_;

  my @lst = _transact($self,['0x002A', '0', '0', '0', '0', '0' ,'0']);

  #Message format from the IRU:
  #Word 0: Latitude LSW
  #Word 1: Longitude LSW
  #Word 2: Grid Heading
  #Word 3: True Heading
  #Word 4: Sin of Pitch
  #Word 5: Sin of Roll

  @w_lst = _conv_short(@lst);
  
  my %hsh; 
  $hsh{'lat'}      = $w_lst[0]; 
  $hsh{'lng'}      = $w_lst[1]; 
  $hsh{'hdg_grid'} = $w_lst[2]/100; 
  $hsh{'hdg_true'} = $w_lst[3]/100; 
  $hsh{'pitch'}    = sprintf( "%5.2f", rad2deg asin($w_lst[4]/10000) ); 
  $hsh{'roll'}     = sprintf( "%5.2f", rad2deg asin($w_lst[5]/10000) ); 

  #print Dumper \%hsh; 
  return \%hsh; 
}

#---- Reset ---------
sub set_01
{
  my $self = shift @_;

  my @lst = _transact($self,['0x0001', '0', '0', '0', '0', '0' ,'0']);

  sleep 180; 
  
  return @lst; 
}

#------ BIT and Reset ------
sub set_03
{
  my $self = shift @_;

  my @lst = _transact($self,['0x0003', '0', '0', '0', '0', '0' ,'0']);

  return @lst; 
}

#----------------------------------------------------------------------
sub set_04
{
  my $self = shift @_;

  my @lst = _transact($self,['0x0004', '0', '0', '0', '0', '0' ,'0']);

  return @lst; 
}

#----------------------------------------------------------------------
sub get_0B
{
  my $self = shift @_;

  my @lst = _transact($self,['0x000B', '0', '0', '0', '0', '0' ,'0']);

  #Message format from the IRU:
  # Words 2-3: Latitude
  # Words 4-5: Longitude
  # Word 6: True Heading
  # Word 7: Malfunction BIT (Least Significant Byte (LSByte))
  # Word 7: IRU Mode/GPS Status/Moving (Most Significant Byte (MSByte))

  my ($lat,$long) = _conv_long(@lst[0..7]);
  my ($hdg_true)  = _conv_short(@lst[8..9]);
  
  my %hsh; 
  $hsh{'lat'}      = rad2deg ($lat * $LL_cnv) ; 
  $hsh{'lng'}      = rad2deg ($long * $LL_cnv); 
  $hsh{'hdg_true'} = $hdg_true / 100;  
 
  $hsh{'bit'}      = unpack("B*",$lst[10]);  
  $hsh{'iru_mode'} = unpack("B*",$lst[11]);  

  #print ">>> $hsh{'bit'} $hsh{'iru_mode'} $hsh{'hdg_true'}\n"; 
  #print Dumper \%hsh; 

  return \%hsh; 
}


#----------------------------------------------------------------------
sub get_0F
{
  my $self = shift @_;
  my $mode = shift @_;
   
  my @lst = _transact($self,['0x000F', '0', '0', '0', '0', '0' ,'0']);

  my $len = scalar @lst;
  if ( $len < 1 ) { warn "Status not returned"; return ''; }  
 
  #  2: Box Azimuth alignment
  #  3: Gyrocompass residual
  #  4: Gyrocompass state
  #  5: Gyrocompass time remaining
  #  6: Moving status
  #  7: 0000h
  @lst = _conv_short(@lst[0..15]); # 12??

###    print Dumper \@lst;  
    
  my @mode_lst;
  $mode_lst[0] = 'CHECK_IF_VALID_TO_GC';
  $mode_lst[1] = 'FIRST_SETTLE_AT_0';
  $mode_lst[2] = 'FIRST_COLLECT_DATA_AT_0';
  $mode_lst[3] = 'MOVE_0_TO_180';
  $mode_lst[4] = 'STOP_AT_180';
  $mode_lst[5] = 'SETTLE_AT_180';
  $mode_lst[6] = 'FIRST_COLLECT_DATA_AT_180';
  $mode_lst[7] = 'SECOND_COLLECT_DATA_AT_180';
  $mode_lst[8] = 'MOVE_FROM_180_TO_0';
  $mode_lst[9] = 'STOP_AT_0';
  $mode_lst[10] = 'SETTLE_AT_0';
  $mode_lst[11] = 'SECOND_COLLECT_DATA_AT_0';
  $mode_lst[12] = 'COMPUTE_FIRST_HEADING_EST';
  $mode_lst[13] = 'GYRO_COMPASS_FAIL';
  $mode_lst[14] = 'END_GYRO_COMPASS';
  $mode_lst[15] = 'RETRY_MOVE_0_TO_180';
  $mode_lst[16] = 'RETRY_MOVE_180_TO_0';
  $mode_lst[17] = 'MOVE_TO_0_NOW';
  $mode_lst[18] = 'RESTART_GYRO_COMPASS';
  $mode_lst[19] = 'ESTIMATE_R_GYRO_BIAS';
  $mode_lst[20] = 'ITERATE_HEADING_ESTIMATE';

  my %hsh; 
  $hsh{'gc_time'} = sprintf("%3.0f",$lst[3] / 61); 
  $hsh{'gc_mode_num'} = $lst[2]; 
  $hsh{'gc_mode_str'} = $mode_lst[$lst[2]];
  $hsh{'box_az_align'} = $lst[0];
  $hsh{'residual'}     = $lst[1];
  $hsh{'move_stat'}  = $lst[4];
  
  $hsh{'move_stat_str'}  = "Not Moving";
  if ($hsh{'move_stat'} ) { $hsh{'move_stat_str'}  = "Moving" }
    
  $hsh{'len'} = $len; 
  
  return \%hsh; 
}

#---- Latitude and Longitude, True Heading, Grid Heading, Sin of Pitch and Sin of Roll ---
# Note: The checksum value gets screwed up on this call if there is any movement during aling
# The values appear to be correct the checksum is just wrong and requires a power cycle use get_62 if possible
sub get_2A
{
  my $self = shift @_;

  my @lst = _transact($self,['0x002A', '0', '0', '0', '0', '0' ,'0']);

  #Message format from the IRU:
  #Word 0: Latitude LSW
  #Word 1: Longitude LSW
  #Word 2: Grid Heading
  #Word 3: True Heading
  #Word 4: Sin of Pitch
  #Word 5: Sin of Roll

  @w_lst = _conv_short(@lst);
  
  my %hsh; 
  $hsh{'lat'}      = $w_lst[0]; 
  $hsh{'lng'}      = $w_lst[1]; 
  $hsh{'hdg_grid'} = $w_lst[2]/100; 
  $hsh{'hdg_true'} = $w_lst[3]/100; 
  $hsh{'pitch'}    = sprintf( "%5.3f", rad2deg asin($w_lst[4]/10000) ); 
  $hsh{'roll'}     = sprintf( "%5.3f", rad2deg asin($w_lst[5]/10000) ); 

  return \%hsh; 
}

#----------------------------------------------------------------------
sub get_2B
{
  my $self = shift @_;

  my @lst = _transact($self,['0x002B', '0', '0', '0', '0', '0' ,'0']);

  #Message format from the IRU:
  # Words 2-3: Latitude
  # Words 4-5: Longitude
  # Word 6: True Heading
  # Word 7: Malfunction BIT (Least Significant Byte (LSByte))
  # Word 7: IRU Mode/GPS Status/Moving (Most Significant Byte (MSByte))

  my ($lat,$hdg) = _conv_long(@lst[0..7]);
  my ($hdg_var,$hdg_var_est)  = _conv_short(@lst[8..11]);
  
  my %hsh; 
  $hsh{'lat'}      = rad2deg ($lat * $LL_cnv) ; 
  $hsh{'hdg_true'} = $hdg * $HDG_cnv; 

  $hsh{'hdg_var'}     = rad2deg ( $hdg_var / (100 * 1000) );   
  $hsh{'hdg_var_est'} = rad2deg ( $hdg_var_est/ (100 * 1000) );   
  
  print Dumper \%hsh; 

  return @lst; 
}

#----------------------------------------------------------------------
sub set_5D
{
  my $self = shift @_;
  my $mode = shift @_;

  #  3 – Gyrocompass Mode (GC)
  #  6 – Navigation Mode (NAV)
  #  8 – In-Vehicle Calibration Mode (IVC)
  #  9 – Base Motion Compensated Coarse Align Mode (BMCCOARSE)
  # 12 – Fast Base Motion Compensated Coarse Align Mode (FASTBMCCOARSE)
   
  unless ( $mode =~/(3|6|8|9|12)/ ) { return 0 } 

  my @lst = _transact($self,['0x005D', $mode, '0', '0', '0', '0' ,'0']);

  #my ($lat,$hdg) = _conv_long(@lst[0..7]);
  #my ($hdg_var,$hdg_var_est)  = _conv_short(@lst[8..11]);
  
  return @lst; 
}

#---- Heading and Attitude -----------------
sub get_62
{
  my $self = shift @_;

  my @lst = _transact($self,['0x062', '0', '0', '0', '0', '0' ,'0']);

  #Message format from the IRU:
  #Word 0: Grid Heading 
  #Word 1: True Heading 
  #Word 2: Pitch
  #Word 3: Roll

  @w_lst = _conv_short(@lst);
  
  my %hsh; 
  $hsh{'hdg_grid'} = $w_lst[0]/100; 
  $hsh{'hdg_true'} = $w_lst[1]/100; 
  $hsh{'pitch'}    = $w_lst[2]/100;
  $hsh{'roll'}     = $w_lst[3]/100; 

  return \%hsh; 
}

#----------------------------------------------------------------------
sub _transact
{
  my $self      = shift @_;
  my @cmd_lst   = @{ shift @_ };

  my $str = join '', @cmd_lst; 
  if ( grep { !/\d+/ } $str ){ die "Commands must be numeric" }
 
  $cmd_lst[0] = hex( $cmd_lst[0] ); # Command header is given in hex 

  my $word_cmd;  my $checksum; 
  foreach my $cmd (@cmd_lst) 
  {   
     my $bn = pack("n",$cmd); 
     $word_cmd .= $bn;
     $checksum ^= $bn; 
  } 
  
  $word_cmd .= $checksum; 
  
  my $cnt_out = $self->{'port_obj'}->write($word_cmd);
  unless ($cnt_out) { warn "write failed\n" };

  my $cmd_len = bytes::length($word_cmd);
  if ( $cnt_out != $cmd_len ) { die "write incomplete only wrote $cnt_out should have written $cmd_len\n"};

  sleep (.20);  # Necessary?

  my $caller = (caller(1) )[3]; 
  unless ( $caller =~ /get/ ) { return 1; } # return if this was a set command, continue if we are getting something

 #$self->{'port_obj'}->read_char_time(0);     # don't wait for each character
 #$self->{'port_obj'}->read_const_time(900); # 1 second per unfulfilled "read" call

  # ------ Send to unit ----- 
  my ($count_in, $str_read) = $self->{'port_obj'}->read(16);
  if ( $count_in == 0) { warn "Time out on read for $caller\n"; }

  # If we are not requesting data then just return. 
  
  my $cmd_rtn = unpack("s",$str_read);
  if ( $cmd_rtn != $cmd_lst[0] ) { warn "Return header does not match command sent for $caller $cmd_lst[0] != $cmd_rtn\n" } 
  
  # -------- Calculate checksum ----------
  my @wrd_lst = $str_read =~ /.{2}/g;
  
  my $cksum_rtn = pop @wrd_lst; 
  my $cksum_rtn_s = unpack("s", $cksum_rtn); 
 
  my $cksum_clc; 
  foreach ( @wrd_lst ) { $cksum_clc ^= $_; }

  my $cksum_clc_s = unpack("s",$cksum_clc);
  if ( $cksum_clc_s != $cksum_rtn_s ) { warn "CHCKSUM FAILED (calc=rtn) $cksum_clc_s != $cksum_rtn_s" } 

  # --------------------------------------
  #_debug($str_read);

  my @byte_lst = split(//, substr($str_read,2,12,) );   # Remove header 
  return @byte_lst;
}

sub err_clr
{
  print "alarm clock restart\n";
  die;
}

sub clear_buf
{

  my $self = shift;

  $self->{'port_obj'}->purge_all(); # doesn't seem to work but no harm

  ($count_in, $string_read) = $self->{'port_obj'}->read($rsp_bytes);

  return;
}

sub close
{
   $self = shift @_;

   $self->{port_obj}->purge_all();
   $self->{port_obj}->purge_rx();
   $self->{port_obj}->close();

}

#----------------------------------------------------------------------
sub _send_cmd
{
  my $self      = shift;
  my $cmd_str   = shift @_;
  my $rsp_bytes = shift @_;

  ####print unpack("B*",$byte_cmd) . " size incoming $rsp_bytes \n";

  my $count_out = $self->{'port_obj'}->write($cmd_str);

  unless ($count_out) { warn "write failed\n" };

  my $cmd_len = length($cmd_str);
  if ( $count_out != $cmd_len ) { warn "write incomplete only wrote $count_out should have written $cmd_len\n"};

  return 1;
}
#----------------------------------------------------------------------
sub _read_rsp
{

  my $self      = shift;
  my $rsp_bytes = shift @_;

  my ($count_in, $string_read) = $self->{'port_obj'}->read($rsp_bytes);

  my ($tod_sec, $tod_usec) = gettimeofday();
  $self->{'tod_sec'}  =  $tod_sec;
  $self->{'tod_usec'} =  $tod_usec;

  my $format = "Cn*";

  @lst = unpack($format,$string_read);

  # Calculate checksum and add signedness (perl needs a new pack format)
  my $cksum;
  foreach my $v ( @lst[0..$#lst-1] )
  {
    $cksum += $v;
    if ( $v > 32767 ) { $v = $v - 65536; }
  }

  $cksum = unpack("n",pack("n",$cksum));

  unless ( $cksum == $lst[$#lst] )
  {
      print "# checksum did not check $cksum $lst[$#lst]\n";

      $self->clear_buf();
      @lst = ();
  }

  if ( $lst[$#lst-1] < 0 ) { $lst[$#lst-1] = $lst[$#lst-1] + 65536;  } #ssshhh....

  return @lst;
}

sub _debug
{
  my $string = shift;

  @chars = split(//, $string);

  print "----------------------------------------\n";

  #my $hdg = shift @chars; 
  #print unpack("B8",$hdg) . " " . unpack("H*",$hdg) . "\n";

  my $i;
  foreach (@chars)
  {
    $end = " ";
    if ( $i++ % 2 ) { $end = "\n"; }
    print unpack("B8",$_) . $end;
  }

  foreach (@chars)
  {
    $end = " ";
    if ( $i++ % 2 ) { $end = "\n"; }
    print unpack("C*",$_) . $end;
  }
   
  # Words .... ... .... .... .... 
  print "----\n";

  my @b_lst = _conv_long(@chars); 
  print Dumper \@b_lst; 
}

# - - - - - - - - - - - - - - - - - - -
sub _conv_long
{
  my @b_lst = @_; 

  my @l_lst; 
  for ( my $i=0; $i<=$#b_lst; $i = $i + 4 )
  {
     push @l_lst, unpack( "l",$b_lst[$i+2] . $b_lst[$i+3] . $b_lst[$i] . $b_lst[$i+1] ); 
  }

  return @l_lst;  
}

# - - - - - - - - - - - - - - - - - - -
sub _conv_short
{
  my @b_lst = @_; 

  my @l_lst; 
  for ( my $i=0; $i<=$#b_lst; $i = $i + 2 )
  {
      push @l_lst, unpack("s",$b_lst[$i] . $b_lst[$i+1]); 
  }

  return @l_lst;  
}

# - - - - - - - - - - - - - - - - - - -
sub _conv_hex
{
  my @b_lst = @_; 

  my @h_lst; 
  for ( my $i=0; $i<=$#b_lst; $i++ )
  {
      push @h_lst, unpack("H",$b_lst[$i]); 
  }

  return @h_lst;  
}


# - - - - - - - - - - - - - - - - - - -
sub _get_cmd_params
{
  my $self = shift;
  my $cmd  = shift;

  my %param = ( '0x02'=>{ 'cmd_lst'=>[ '0x02' ],
                          'rsp_bytes'=>23        },
                '0x03'=>{ 'cmd_lst'=>[ '0x03' ],
                          'rsp_bytes'=>23        },
                '0x07'=>{ 'cmd_lst'=>[ '0x07' ],
                          'rsp_bytes'=>7         }
              );

  my $cmd_str;

  foreach my $cmd_byte ( @{ $param{$cmd}->{'cmd_lst'} } ) {  $cmd_str = pack("C",hex($cmd_byte) ); }

  $param{$cmd}->{cmd_str} = $cmd_str;

  return %{ $param{$cmd} };
}

1;

__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Device::IRU_GE - Perl Module to read and control a GE Aviation Systems IRU

=head1 SYNOPSIS

  use Device::IRU_GE;
 
  my %arg_hsh;  
  $arg_hsh{baudrate} = 19200;
  $arg_hsh{parity}   = "none";
  $arg_hsh{databits} = 8;
  $arg_hsh{stopbits} = 1;
  $arg_hsh{'port'} = '/dev/ttyr0a';

  my $Ge_obj = new IRU_GE(\%arg_hsh)
 
  $Ge_obj->set_5D(3); 
  print "Sent gyrocompass command\n";
     
  while (1) 
  {
      my $att_ref = $Ge_obj->get_62();
      print "$att_ref->{hdg_true} $att_ref->{roll} $att_ref->{pitch} \n";
  
  } 

=head1 DESCRIPTION

The module provides a software interface to the General Electric North Finding Module (NFM)
or also known as Interial Reference Unit (IRU) or a component of the Land Navigation System (LNS). 

This module implements several of the functions defined in the GE Aviation Systems document:  
 
"RS-422 Interface Protocol Specification for the Operational Vehicle Program of the Inertial Reference Unit"

This document is dated 08 October 2008 and must be acquired from GE Aviation Systems directly.

 GE Aviation Systems LLC
 3290 Patterson Avenue, SE, 
 Grand Rapids, MI 49512-1991, USA

This Perl Module provides functions which are identified using the numerical Command ID's found in the 
reference document. 

=head1 Methods 

Only a few of the more useful methods or functions are described please have a look 
at the code for others or contact me. 

=head2 new

Object Constructor which expects an argument with a hash or reference to a hash 
providing the communication parameters. 

	$ge_obj = Device::GE_IRU(%arg_hsh); 

Available arguements: baudrate, parity, databits, stopbits, port

Defaults for these argument parameters are as follows:    

  $arg_hsh{'port'}   = "/dev/ttyS0";
  $arg_hsh{baudrate} = 19200;
  $arg_hsh{parity}   = "none";
  $arg_hsh{databits} = 8;
  $arg_hsh{stopbits} = 1;

=head2 set_01

Branch to Zero or total system restart. All output stops and the IRU resets.
   
   $ge_obj->set_01(); 

=head2 set_5D

Set IRU Mode This command is used to set the mode of the IRU to one of the valid
modes shown below

	$ge_obj->set_5D($mode)
	
Where $modes is one of the following:
   
 3 Gyrocompass Mode (GC) 
 6 Navigation Mode (NAV)
 8 In-Vehicle Calibration Mode (IVC)
 9 Base Motion Compensated Coarse Align Mode (BMCCOARSE)
 12 Fast Base Motion Compensated Coarse Align Mode (FASTBMCCOARSE)

Mode 3 or gyrocompass is the most common arguement here and this will send the IRU
off into a gyrocompass excursion taking about 3 minutes to complete. The IRU must be
motionless during this time. 

=head2 set_2A

Get Latitude and Longitude, True Heading, Grid Heading, Pitch and Roll and return in a hash reference

Note: When using this function I have noticed that the checksum value gets screwed up if there is any movement 
during an gyrocompass and stay corrupt. The values returned by this call appear to be correct but the checksum 
is just wrong and requires a power cycle to fix. I recommend get_62 only attitude is required. 
  
Contents of returned hash reference are in degrees
  
 $ref->{'lat'}      = Latitude 
 $ref->{'lng'}      = Longitude 
 $ref->{'hdg_grid'} = Grid Heading 
 $ref->{'hdg_true'} = True Heading  
 $ref->{'pitch'}    = Pitch 
 $ref->{'roll'}     = Roll


=head2 get_62

Get the Heading and Attitude and return in a hash reference

  my $ref = $ge_obj->get_62();
  
Contents of returned hash reference are in degrees
 
 $ref->{'hdg_grid'} = Grid Heading  
 $ref->{'hdg_true'} = True Heading 
 $ref->{'pitch'}    = Pitch
 $ref->{'roll'}     = Roll 

=head2 get_0F

Get residual heading and gyrocompass time remaining. 

   my $ref = $ge_obj->get_0F();
  
Contents of returned hash reference
 
 $ref->{'gc_time'} = time remain for gyrocompass to complete 
 $ref->{'gc_mode_num'}  = Numerical gyro mode 
 $ref->{'gc_mode_str'}  = Gyro mode string 
 $ref->{'residual'}     = heading residual 
 $ref->{'move_stat'}    = Moving status 0 for static, 1 for movement in the last 10 sec

=head2 plug_test

  
Used to test the serial connection with a loopback plug. 
  

=head1 PREREQUISITES 

 Time::HiRes
 Math::Trig

 Device::SerialPort qw( :PARAM :STAT 0.07 ) or ( Win32::SerialPort qw(:STAT 0.19 ) ) with minor mods

=head1 SEE ALSO

B<PERFORMANCE SPECIFICATION FOR THE LAND NAVIGATION SYSTEM AND NORTH FINDING MODULE>, 
Document Number YV1657,
Rev. B
15 March 2001

B<RS-422 Interface Protocol Specification for the Operational Vehicle Program of the Inertial Reference Unit>, 
Document Number YV2656, Rev. x
08 October 2008

=head1 AUTHOR

Steve Troxel, E<lt>troxel 'at' perlworks.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Troxel

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
