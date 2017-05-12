package Device::VantagePro;

use 5.008008;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our $VERSION = '0.25';

#-#use Win32::SerialPort qw(:STAT 0.19 );
use Device::SerialPort qw(:STAT 0.19 );

use Time::HiRes qw(usleep gettimeofday time);
use Data::Dumper;

use POSIX qw(:errno_h :fcntl_h strftime);

use Time::Local; 

our %EXPORT_TAGS = ( 'all' => [ qw( ) ] );
our @EXPORT_OK = qw();
our @EXPORT = qw();

our $Verbose = 0; 

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

  my $port = $arg_hsh{'port'} || "/dev/ttyS0";

  #my $conf = $arg_hsh{'conf'} || 'Conf.ini';
  
  #my $port_obj = new Win32::SerialPort ($port) || die "Can't open $port: $^E\n";
  my $port_obj = new Device::SerialPort ($port) || die "Can't open $port: $^E\n";
  
  my $baudrate = $arg_hsh{baudrate} || 19200;
  my $parity   = $arg_hsh{parity}   || "none";
  my $databits = $arg_hsh{databits} || 8;
  my $stopbits = $arg_hsh{stopbits} || 1;

  # After new, must check for failure
  $port_obj->baudrate($baudrate);
  $port_obj->parity($parity);
  $port_obj->databits($databits);
  $port_obj->stopbits($stopbits);
  #-# $port_obj->read_interval(1);    # max time between read char (milliseconds) Not in Device::SerialPort 
 
  $port_obj->read_const_time(10000);  # total = (avg * bytes) + const 
    
  #$port_obj->handshake("rts");
  #$port_obj->buffers(4096, 4096);

  $port_obj->write_settings || warn 'Write Settings Failed';

  #$port_obj->save($conf);

  unless ($port_obj) { die "Can't change Device_Control_Block: $^E\n"; }

  my ($BlockingFlags, $InBytes, $OutBytes, $LatchErrorFlags) = $port_obj->status
      || warn "could not get port status\n";

  if ($BlockingFlags)
  {
     #warn "Port is blocked $BlockingFlags, $InBytes, $OutBytes, $LatchErrorFlags\n";
  }

  $port_obj->purge_all();  # these don't seem to work but try anyway.
  $port_obj->purge_rx();
 
  # The object data structure
  my $self = bless {
                    'arg_hsh'         => { %arg_hsh },
                    'port_obj'        => $port_obj,
					'loop_cnt'        => 0,
                   }, $class;
  
 # if ( $self->wake_up() ) { print "Station found ready for communications\n" } 
   
  return $self;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub wake_up
{
  my $self = shift @_; 
  
  foreach (1..3)
  {
    my $cnt_out = $self->{'port_obj'}->write("\n");
    unless ($cnt_out) { warn "write failed\n" };
    my ($cnt_in, $str) = $self->read(2);
	
    if ($str eq "\n\r" ) 
	{ 
		print "Success on Wakeup $_\n" if $Verbose; 
    	return 1; 
	}
	 
	warn "Not responding to Wakeup\n"; 
	
	usleep 1200000; # As per page 5 of VantagePro Doc 
  }

  warn("Could not unit wake up"); 
  return -1; # fail 
}

# - - - - - - - - - - - - - - - - - - - - - - - - - -  
sub plug_test
{
  my $self = shift @_;

  my $port_obj = $self->{'port_obj'}; 
  
  my $str = "TEST\n";  
  
  print "Sending $str"; 
  my $cnt_out = $port_obj->write($str);
  unless ($cnt_out) { warn "write failed\n" };
  
  my ($cnt_in, $str_in) = $port_obj->read(8);

  print "returned: $cnt_in, $str_in"; 
 
  return $str; 
}

# - - - - - - - - - - - - - - - - - - - - - - - - - -  
sub do_dmpaft
{
  my $self = shift @_;

  my $vDateStamp = shift @_;
  my $vTimeStamp = shift @_; 

  # If not date/time stamp then assume 0 which will down load the entire archive
  unless ( $vDateStamp ) { $vDateStamp = 0 } 
  unless ( $vTimeStamp ) { $vTimeStamp = 0 } 
 
  my $port_obj = $self->{'port_obj'}; 
  
  my $datetime = pack("ss",$vDateStamp, $vTimeStamp); 
 
  my $crc = CRC_CCITT($datetime);
  my $cmd = pack("ssn",$vDateStamp,$vTimeStamp,$crc); 

 #-----------------------  
 #my $str = unpack("H*", $cmd); 
 #$str =~ s/(\w{2})/$1 /g; 
 # Documentation is wrong! The example should be <0xC6><0x06><0xA2><0x03> in section X
 #print "cmd : $str \n";exit; 
 #-----------------------  

 sleep 2; # Needed after loop 
 $self->wake_up();  
 
 # Ok let's start the communication sequence.... 
 my $cnt_out = $port_obj->write("DMPAFT\n");
 unless ($cnt_out) { warn "write failed\n" };
 my ($cnt_in, $str) = $self->read(1);
  
 my $ack = ord $str; 
 unless ($ack == 6) { warn "Ack not received on DMPAFT command: $ack"; exit -1; }
 
 $cnt_out = $port_obj->write($cmd);
 unless ($cnt_out) { warn "write failed\n" };
 ($cnt_in, $str) = $self->read(7); 
 
 $ack = ord substr($str,0,1);    
    
 my $ls = unpack("H20",substr($str,1,4) ); 
 $ls =~ s/(\w{2})/$1 /g;	
 
 my $pages = unpack("s",substr($str,1,2) ); 
 my $rec_start = unpack("s",substr($str,3,2) ); 
  
 $crc = CRC_CCITT(substr($str,1,6) );

 print "Pages = $pages : rec = $rec_start Datestamp $vDateStamp $crc\n"; 
  	
 $cnt_out = $port_obj->write( pack("h", 0x06) );
 
 #if ($pages == 513 ) { return -1 }
 
 my @arc_rec_lst;  	  
 foreach my $page (1..$pages) 
 {
     my $page_sz = 267; 	
     my ($cnt_in, $str) = $self->read($page_sz,3);
     print "Page $page\n" if ( $Verbose ); 
 
	  my $rec_sz = 52;
      my $date_prev = 0; 	
      my %hsh;
	  
	  foreach my $rec ( 0..4 )
	  {
     	  if ( ($page == 1) && ($rec < $rec_start ) ) { next } # Find the right starting point... 

     	  my $start_ptr = 1 + ($rec * $rec_sz ); 	  
		  my $rec_str = substr($str, $start_ptr ,52);
		  #print "$start_ptr \t > " . unpack( "h*", $rec_str) . "\n"; 
		  
		  my $date = substr($rec_str,0,2);  
		  my $date_curr =  unpack "s", $date;
		  
		  # Check if we have wrapped... 
  		  if ( $date_curr < $date_prev ) { last; }  	
          $date_prev = $date_curr;       
		  
		  $hsh{'date_stamp'} =  $date_curr; 
		  $hsh{'time_stamp'} =  unpack "s", substr($rec_str,2,2); 
		   
		  $hsh{'day'}    = unpack( "c", $date & pack("c",0x1F) ); 
		  $hsh{'month'}  = ( $hsh{'date_stamp'} >> 5) & 0xF; 
		  $hsh{'year'}  =  ( $hsh{'date_stamp'} >> 9) + 2000; 
		
		  $hsh{'hour'}  = sprintf("%02d", int ( $hsh{'time_stamp'} / 100 )); 
		  
		  $hsh{'min'}  =  $hsh{'time_stamp'} - ($hsh{'hour'} * 100);  
 		  $hsh{'min'}  =  sprintf("%02d", $hsh{'min'}); 
 		
		  $hsh{'time_stamp_fmt'}  =  "$hsh{'hour'}:$hsh{'min'}:00"; 
		  $hsh{'date_stamp_fmt'}  =  "$hsh{'year'}_$hsh{'month'}_$hsh{'day'}"; 

		  $hsh{'unixtime'} = timelocal(0,$hsh{min}, $hsh{hour},
		                                  $hsh{day}, $hsh{month}-1, $hsh{year}-1900);
		  		  
		  $hsh{'Air_Temp'} = unpack("s", substr($rec_str,4,2)) / 10; 
		  $hsh{'Air_Temp_Hi'} = unpack("s", substr($rec_str,6,2)) / 10; 
		  $hsh{'Air_Temp_Lo'} = unpack("s", substr($rec_str,8,2)) / 10;
		  $hsh{'Rain_Clicks'} = unpack("s", substr($rec_str,10,2));
		  $hsh{'Rain_Rate_Clicks'}   = unpack("s", substr($rec_str,12,2));
                  $hsh{'Rain_Rate'}   = $hsh{'Rain_Rate_Clicks'} / 100; # Inches per hour
          $hsh{'Barometric_Press'}   = unpack("s", substr $rec_str,14,2) / 1000;  
          $hsh{'Solar'}   = unpack("s", substr $rec_str,16,2);       # watt/m**2
          $hsh{'Wind_Samples'}  = unpack("s", substr $rec_str,18,2);   
		  $hsh{'Air_Temp_Inside'}  = unpack("s", substr $rec_str,20,2) / 10;  

          $hsh{'Relative_Humidity_Inside'}  = unpack("C", substr $rec_str,22,1);
          $hsh{'Relative_Humidity'} = unpack("C", substr $rec_str,23,1);

		  $hsh{'Wind_Speed'}    =  unpack("C", substr($rec_str,24,1)); 
		  $hsh{'Wind_Gust_Max'} = unpack("C", substr($rec_str,25,1));
		  $hsh{'Wind_Dir_Max'}  = unpack("C", substr($rec_str,26,1));
		  $hsh{'Wind_Dir'}      = unpack("C", substr($rec_str,27,1));

		  $hsh{'UV'} = unpack("C", substr($rec_str,28,1)) / 10;
		  $hsh{'ET'} = unpack("C", substr($rec_str,29,1)) / 1000;

		  $hsh{'Solar_Max'} = unpack("s", substr($rec_str,30,2)); 
		  $hsh{'UV_Max'} = unpack("C", substr($rec_str,32,1));
		  
		  $hsh{'Forecast_Rule'} = unpack("C", substr($rec_str,33,1));

    	  $hsh{'Dew_Point'}  = _dew_point($hsh{'Air_Temp'},$hsh{'Relative_Humidity'}); 
					
		   # Miscellaneous others omitted for now
					
	      print "date> $hsh{'time_stamp'} $hsh{'time_stamp_fmt'}  $hsh{'date_stamp'} $hsh{'date_stamp_fmt'}\n"  if ( $Verbose );  		
		  #print Dumper \%hsh; 
		  
    	  push @arc_rec_lst, {%hsh}; 
	  }	
		  
	  #$in = <STDIN>; # Testing step through facility
	  #if ($in =~ /q/i ) {  $port_obj->write( pack("h", 0x1B) ); last; }
	  #else              {  $port_obj->write( pack("h", 0x06) ); }
	  $port_obj->write( pack("h", 0x06) );
	  
  }
	   
  return \@arc_rec_lst;  
}

# - - - - - - - - - - - - - - - - - - - - - - - - - -  
sub get_one_loop
{
  my $self = shift @_;
 
  unless ( $self->start_loop(1) ) { return 0; } 
  my $hsh_ref = $self->read_loop(); 
 
  return $hsh_ref; 
}

# - - - - - - - - - - - - - - - - - - - - - - - - - -  
sub start_loop
{
  my $self = shift @_;
  my $lp_cnt = shift @_ || 1; 

  $self->wake_up();  
  
  my $cnt_out = $self->{'port_obj'}->write("LOOP $lp_cnt\n");
  
  my ($cnt_in, $str) = $self->read(1);
 
  if ( ord($str) != 6 ) { warn("Ack not returned for Loop"); return 0; }

  return 1; 
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub read_loop
{
  my $self = shift @_;
  
  my ($cnt_in, $str) = $self->read(99, 4); # extend timeout to 3 seconds
  if ( $cnt_in != 99 ) { return 0 }
  
  my $hsh_ref = parse_loop_blck($str);
  
  return $hsh_ref; 
 }

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub parse_loop_blck 
{
  my $blk = shift @_; 
  my $loo =  substr $blk,0,3;  

  my $ack = ord substr($blk,0,1);
  
  unless ( $loo eq 'LOO') { warn("Block invalid loo -> $loo\n"); return ""; } 
    
  my %hsh; 

  $hsh{'Barometric_Trend'}    = unpack("C", substr $blk,3,1);  
  $hsh{'next_rec'}     = unpack("s", substr $blk,5,2);  
  $hsh{'Barometric_Press'}          = unpack("s", substr $blk,7,2) / 1000;  
  $hsh{'Air_Temp_Inside'}      = unpack("s", substr $blk,9,2) / 10;  
  $hsh{'Humidity_Inside'}  = unpack("C", substr $blk,11,1);  
  $hsh{'Air_Temp'}     = unpack("s", substr $blk,12,2) / 10;  
  $hsh{'Wind_Speed'}   = unpack("C", substr $blk,14,1);  
  $hsh{'Wind_Speed_10min_Ave'} = unpack("C", substr $blk,15,1);
  $hsh{'Wind_Dir'}     = unpack("s", substr $blk,16,2);
  # Skip other temps for now...
  
  $hsh{'Relative_Humidity'} = unpack("C", substr $blk,33,1);
  # Skip other humidities for now...

  $hsh{'Rain_Rate_Clicks'}  = unpack("s", substr $blk,41,2);
  $hsh{'Rain_Rate'}  = $hsh{'Rain_Rate_Clicks'} / 100; # Inches per hr
  $hsh{'UV'}         = unpack("C", substr $blk,43,1);
  $hsh{'Solar'}  = unpack("s", substr $blk,44,2);       # watt/m**2
  $hsh{'Rain_Storm'} = unpack("s", substr $blk,46,2) / 100; # Inches per storm

  $hsh{'Storm_Date'} = unpack("s", substr $blk,48,2);  # Need to parse data (not sure what this is)
  $hsh{'Rain_Day'}   = unpack("s", substr $blk,50,2)/100;  
  $hsh{'Rain_Month'}  = unpack("s", substr $blk,52,2)/100;  
  $hsh{'Rain_Year'}  = unpack("s", substr $blk,54,2)/100;  

  $hsh{'Day_ET'}   = unpack("s", substr $blk,56,2)/1000;  
  $hsh{'Month_ET'}  = unpack("s", substr $blk,58,2)/100;  
  $hsh{'Year_ET'}  = unpack("s", substr $blk,60,2)/100;  
  # Skip Soil/Leaf Wetness
  
  $hsh{'Alarms_Inside'}  = unpack("b8", substr $blk,70,1);  
  $hsh{'Alarms_Rain'}  = unpack("b8", substr $blk,70,1);  
  $hsh{'Alarms_Outside'}  = unpack("b8", substr $blk,70,1);  
  # Skip extra alarms 
  
  $hsh{'Batt_Xmit'}  = unpack("C", substr $blk,86,1) * 0.005859375;  
  $hsh{'Batt_Cons'}  = unpack("s", substr $blk,87,2) * 0.005859375;  

  $hsh{'Forecast_Icon'}  = unpack("C", substr $blk,89,1);  
  $hsh{'Forecast_Rule'}  = unpack("C", substr $blk,90,1);  

  $hsh{'Sunrise'}  = sprintf( "%04d", unpack("S", substr $blk,91,2) );  
  $hsh{'Sunrise'}  =~ s/(\d{2})(\d{2})/$1:$2/; 
  
  $hsh{'Sunset'}   = sprintf( "%04d", unpack("S", substr $blk,93,2) );  
  $hsh{'Sunset'}  =~ s/(\d{2})(\d{2})/$1:$2/; 

  $hsh{'Dew_Point'}  = _dew_point($hsh{'Air_Temp'},$hsh{'Relative_Humidity'}); 
  
  my $nl  =  ord substr $blk,95,1;  
  my $cr  =  ord substr $blk,96,1;   

  $hsh{crc} = unpack "%n", substr($blk,97,2); 
  $hsh{'crc_calc'} = CRC_CCITT($blk); 
    		   
  return \%hsh;   
}

# - - - - - - - - - - - - - - - - - - - - - - - - - -  
sub get_eeprom
{
  my $self = shift @_;
  my $item = shift @_;
 
  my ($loc, $size); 
  # Not all supported.... More to follow 
  if ( uc($item) eq 'ARCHIVE_PERIOD' ){ $loc = '2D'; $size = '01' }
  elsif ( uc($item) eq 'TIME_ZONE' ){ $loc = '11'; $size = '01' }
  elsif ( uc($item) eq 'MANUAL_OR_AUTO' ){ $loc = '12'; $size = '01' }
  elsif ( uc($item) eq 'DAYLIGHT_SAVINGS' ){ $loc = '13'; $size = '01' }
  elsif ( uc($item) eq 'GMT_OFFSET' ){ $loc = '14'; $size = '02' }
  elsif ( uc($item) eq 'GMT_OR_ZONE' ){ $loc = '16'; $size = '01' }
  elsif ( uc($item) eq 'SETUP_BITS' ){ $loc = '2B'; $size = '01' }
  else { warn "$item not found"; return -1; }  
  
  my $port_obj = $self->{port_obj}; 
  
  my $cnt_out = $port_obj->write("EERD $loc $size\n");
  unless ($cnt_out) { warn "write failed\n" };
    
  # A \n\r is prefixed not as in the documentation... 
  my $read_size = (hex($size) * 4) + 6;
  
  my ($cnt_in, $str) = $self->read($read_size);

  my @rsp_lst = split /\n\r/, $str;
  shift(@rsp_lst); 
  
  if ( $rsp_lst[0] ne 'OK' ) { _dump($str); warn "OK Not returned";  }
  shift(@rsp_lst); 
    
  return \@rsp_lst; 
}

# - - - - - - - - - - - - - - - - - - - - - - - - - -  
sub gettime
{
  my $self = shift @_;
  
  my $port_obj = $self->{port_obj}; 
   
  my $cnt_out = $port_obj->write("GETTIME\n");
  unless ($cnt_out) { warn "write failed\n" };

  my ($cnt_in, $str) = $port_obj->read(9);
      
  my $ck = CRC_CCITT(substr($str,1,9));
  if ( $ck ) { warn "checksum error"; return 0; }

  my @rsp_lst =  split //, $str;
  shift @rsp_lst; 
	
  @rsp_lst = map ord, @rsp_lst; 
    
  return \@rsp_lst; 
}

# - - - - - - - - - - - - - - - - - - - - - - - - - -  
sub settime
{
  my $self  = shift @_;
  my $t_ref = shift @_;
  
  my $port_obj = $self->{port_obj}; 
  
  my $cnt_out = $port_obj->write("SETTIME\n");
  unless ($cnt_out) { warn "write failed\n" };
  
  my ($cnt_in, $str) = $port_obj->read(1);
  my $ack = ord $str; 
  if ( $ack != 6 ) { warn "SETTIME not set ack $ack !"; return 0; }

  my ($sec, $min, $hour, $day, $mon, $yr) = @{$t_ref};
    
  $str = join "", map chr, ($sec, $min, $hour, $day, $mon, $yr);  
    	
  my $ck = CRC_CCITT($str);
  $str = $str . pack("n",$ck); 
  
  $cnt_out = $port_obj->write($str);
  unless ($cnt_out) { warn "write failed\n" };
  
  ($cnt_in, $str) = $port_obj->read(1);
  if ( ord($str) != 6 ) { warn "SETTIME not set!"; return 0; }

  sleep 3;   # The console seems to need to some time here... 
	
  return 1; 
}

# - - - - - - - - - - - - - - - - - - - - - - - - - -  
sub set_archive_period
{
  my $self    = shift @_;
  my $period  = shift @_;

  unless ( grep { $_ == $period } (1, 5, 10, 15, 30, 60, 120) ) 
  {
    warn "Not valid archive period"; # Limits in document
    return 0; 
  }
  
  my $port_obj = $self->{port_obj}; 
  
  my $cnt_out = $port_obj->write("SETPER $period\n");
  unless ($cnt_out) { warn "write failed\n" };
  
  my ($cnt_in, $str) = $port_obj->read(1);

  my $ack = ord $str; 
 
  unless ( $ack != 6 ) { warn "Archive not set!"; return 0; }
    
  return 1; 

}

my $t_prv = time; 

# - - - - - - - - - - - - - - - - - - - - - - - - - - - -
sub get_archive_period
{
 my $self    = shift @_;

 my $rst = $self->get_eeprom('archive_period'); 
 my $archive_period = hex($rst->[0]); 

 return $archive_period; 
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - -
sub get_timezone
{
 my $self    = shift @_;

 use DateTime::TimeZone;

 # Calculate the time zone used by the VP and return as a TimeZone object
 
 my $timezone;
 if (hex $self->get_eeprom('gmt_or_zone')->[0])
 {
     # Unit is configured for GMT offset value
     # Wow, this is messy!
     my $dst = 0; # Manual daylight saving adjustment to make
     if (hex $self->get_eeprom('manual_or_auto')->[0])
     {
         # Unit has daylight saving in manual
         $dst = hex $self->get_eeprom('daylight_savings')->[0];
     }
     my $val = $self->get_eeprom('gmt_offset');  # Get offset in hours
     my $offset = hex ($val->[1].$val->[0]);     # Combine the 2 bytes together
     $offset -= 65536 if $offset > 32767;        # 2's complement if -ve
     $offset /= 100;                             # Convert to hours
     $offset += $dst;                            # Adjust for daylight saving if required
     my $hours = int $offset;                    # The whole number of hours
     my $minutes = abs ($offset - $hours) * 60;  # The number of minutes
     $minutes = sprintf("%02d", $minutes);       # Prefix with 0 if required
     my $tzstr = $hours.$minutes;                # The 2 together to create tz string
     $tzstr *= -1 if $offset < 0 && $hours == 0; # Fix negative for 0 hours
     $tzstr = sprintf("%+05d", $tzstr);          # The final formatted string
     $timezone = DateTime::TimeZone->new( name => $tzstr );
 }
 else {
     # Unit configured for specific timezone
     my $tz = hex $self->get_eeprom('time_zone')->[0];
     my @timezones = qw( Pacific/Kwajalein
                         Pacific/Midway
                         Pacific/Honolulu
                         America/Anchorage
                         America/Tijuana
                         America/Denver
                         America/Chicago
                         America/Mexico_City
                         America/Monterrey
                         America/Bogota
                         America/New_York
                         America/Halifax
                         America/Santiago
                         America/St_Johns
                         America/Sao_Paulo
                         America/Argentina/Buenos_Aires
                         Atlantic/South_Georgia
                         Atlantic/Azores
                         Europe/London
                         Africa/Casablanca
                         Europe/Berlin
                         Europe/Paris
                         Europe/Prague
                         Europe/Athens
                         Africa/Cairo
                         Europe/Bucharest
                         Africa/Harare
                         Asia/Jerusalem
                         Asia/Baghdad
                         Europe/Moscow
                         Asia/Tehran
                         Asia/Muscat
                         Asia/Kabul
                         Asia/Karachi
                         Asia/Kolkata
                         Asia/Almaty
                         Asia/Bangkok
                         Asia/Shanghai
                         Asia/Hong_Kong
                         Asia/Tokyo
                         Australia/Adelaide
                         Australia/Darwin
                         Australia/Brisbane
                         Australia/Hobart
                         Asia/Magadan
                         Pacific/Fiji
                         Pacific/Auckland
                     );
     $timezone = DateTime::TimeZone->new( name => $timezones[$tz] );
 }

 return $timezone;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - -
sub make_date_time_stamp
{
 my $self    = shift @_;
 
 my ($year, $mon, $mday, $hour, $min) = @_;

      
  # Test Example as per Page 31 in Document 
  #$mon = 6;$mday = 6;$year = 2003;$hour = 9;$min  = 30; 
  # See print time stamps below after CRC and formatting 

  #print "Looking for record $year, $mon $mday $hour:$min\n"; 
	  	  
  # The friggen Vantage pro requires time stamps that _exactly_ match 
  # the record in memory or it sends the whole archive.    
  #my $rmn = $self->get_archive_period();                  
  #$min = $min - $rmn;                # Note this does not work for any archive_period > 60  

  #if ( $min > 0 ) 
  #{ $min = 60 + $min;  
  #  $hour -= 1; 
  #	if ($hour < 0 ) { $hour = 23;  }
  #}

  #my $gap = $min % $rmn; 
  #$min = $min - $gap;   
  
  #print "Looking for record $year, $mon $mday $hour:$min\n"; 
  
  my $vDateStamp = $mday + ($mon)*32 + ($year-2000)*512;  
  my $vTimeStamp = (100 * $hour) + $min; 

  return ($vDateStamp, $vTimeStamp);  
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - -
sub get_setup_bits
{
 my $self    = shift @_;

 my $rst = $self->get_eeprom('setup_bits');
 my $enc = hex($rst->[0]);
 my %setup_bits;
 $setup_bits{TimeMode}          = $enc & 0x01;
 $setup_bits{IsAM}              = $enc >> 1 & 0x01;
 $setup_bits{MonthDayFormat}    = $enc >> 2 & 0x01;
 $setup_bits{WindCupSize}       = $enc >> 3 & 0x01;
 $setup_bits{RainCollectorSize} = $enc >> 4 & 0x03;
 $setup_bits{Latitude}          = $enc >> 6 & 0x01;
 $setup_bits{Longitude}         = $enc >> 7 & 0x01;

 return \%setup_bits;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - -
sub get_ymdhm
{
 my $self    = shift @_;
 my $utime   = shift @_;

 my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($utime); 
 $mon = $mon + 1;  
 $year = $year + 1900;  

  return ($year, $mon, $mday, $hour, $min); 
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - -
sub read
{
 my $self    = shift @_;
 my $bytes   = shift @_ || 255;
 my $timeout = shift @_ || 2;
  
 my $port_obj = $self->{port_obj}; 

 my ($cnt_in, $str);

 eval {
   local $SIG{ALRM} = sub { die "alarm $timeout expired\n" }; # NB: \n required
   alarm $timeout;
    
   ($cnt_in, $str) = $self->{'port_obj'}->read($bytes);

   alarm 0;
 };
 
 if ($@) 
 { 
   warn "Read Timeout $timeout\n"; 
   return 0;
 }

 return ($cnt_in, $str);

}

sub _dew_point
{
  my $temp = shift @_; 
  my $rh   = shift @_; 
  
  #  Using the simplified approximation for dew point 
  #  Accurate to 1 degree C for humidities > 50 %  
  #  http://en.wikipedia.org/wiki/Dew_point

  my $dew_point = $temp - ( (100 - $rh)/5 ); 
    
  return $dew_point; 
}


sub _dump
{
   my @lst = split //, $_[0];
   print "Bytes " . scalar(@lst) . "\n";    
   foreach my $i ( @lst ) {
      print "> " . ord($i) . "\n"; 
   }
}

# - - - - - - - - - - - - - - - - - - - 
sub CRC_CCITT
{
    # Expects packed data... 
    my $data_str = shift @_;

	my @crc_table = crc_table();

	my $crc = 0;
	my @lst = split //, $data_str;
	foreach my $data (@lst)
	{
	   my $data = unpack("c",$data); 
	
	   my $crc_prev = $crc;
	   my $index = $crc >> 8 ^ $data;
	   my $lhs = $crc_table[$index];
       my $rhs = ($crc << 8) & 0xFFFF;
       $crc = $lhs ^ $rhs;
	
	   #$data = unpack("H*",$data); 
	   #printf("%X\t %s\t %X\t %X\t %X\t : %x \n", $crc_prev, $data, $index, $lhs, $rhs, $crc);
	}
		
	return $crc;
}

# - - - - - - - - - - - - - - - - - - - 
sub crc_table
{

my @crc_table = (
0x0, 0x1021, 0x2042, 0x3063, 0x4084, 0x50a5, 0x60c6, 0x70e7,
0x8108, 0x9129, 0xa14a, 0xb16b, 0xc18c, 0xd1ad, 0xe1ce, 0xf1ef,
0x1231, 0x210, 0x3273, 0x2252, 0x52b5, 0x4294, 0x72f7, 0x62d6,
0x9339, 0x8318, 0xb37b, 0xa35a, 0xd3bd, 0xc39c, 0xf3ff, 0xe3de,
0x2462, 0x3443, 0x420, 0x1401, 0x64e6, 0x74c7, 0x44a4, 0x5485,
0xa56a, 0xb54b, 0x8528, 0x9509, 0xe5ee, 0xf5cf, 0xc5ac, 0xd58d,
0x3653, 0x2672, 0x1611, 0x630, 0x76d7, 0x66f6, 0x5695, 0x46b4,
0xb75b, 0xa77a, 0x9719, 0x8738, 0xf7df, 0xe7fe, 0xd79d, 0xc7bc,
0x48c4, 0x58e5, 0x6886, 0x78a7, 0x840, 0x1861, 0x2802, 0x3823,
0xc9cc, 0xd9ed, 0xe98e, 0xf9af, 0x8948, 0x9969, 0xa90a, 0xb92b,
0x5af5, 0x4ad4, 0x7ab7, 0x6a96, 0x1a71, 0xa50, 0x3a33, 0x2a12,
0xdbfd, 0xcbdc, 0xfbbf, 0xeb9e, 0x9b79, 0x8b58, 0xbb3b, 0xab1a,
0x6ca6, 0x7c87, 0x4ce4, 0x5cc5, 0x2c22, 0x3c03, 0xc60, 0x1c41,
0xedae, 0xfd8f, 0xcdec, 0xddcd, 0xad2a, 0xbd0b, 0x8d68, 0x9d49,
0x7e97, 0x6eb6, 0x5ed5, 0x4ef4, 0x3e13, 0x2e32, 0x1e51, 0xe70,
0xff9f, 0xefbe, 0xdfdd, 0xcffc, 0xbf1b, 0xaf3a, 0x9f59, 0x8f78,
0x9188, 0x81a9, 0xb1ca, 0xa1eb, 0xd10c, 0xc12d, 0xf14e, 0xe16f,
0x1080, 0xa1, 0x30c2, 0x20e3, 0x5004, 0x4025, 0x7046, 0x6067,
0x83b9, 0x9398, 0xa3fb, 0xb3da, 0xc33d, 0xd31c, 0xe37f, 0xf35e,
0x2b1, 0x1290, 0x22f3, 0x32d2, 0x4235, 0x5214, 0x6277, 0x7256,
0xb5ea, 0xa5cb, 0x95a8, 0x8589, 0xf56e, 0xe54f, 0xd52c, 0xc50d,
0x34e2, 0x24c3, 0x14a0, 0x481, 0x7466, 0x6447, 0x5424, 0x4405,
0xa7db, 0xb7fa, 0x8799, 0x97b8, 0xe75f, 0xf77e, 0xc71d, 0xd73c,
0x26d3, 0x36f2, 0x691, 0x16b0, 0x6657, 0x7676, 0x4615, 0x5634,
0xd94c, 0xc96d, 0xf90e, 0xe92f, 0x99c8, 0x89e9, 0xb98a, 0xa9ab,
0x5844, 0x4865, 0x7806, 0x6827, 0x18c0, 0x8e1, 0x3882, 0x28a3,
0xcb7d, 0xdb5c, 0xeb3f, 0xfb1e, 0x8bf9, 0x9bd8, 0xabbb, 0xbb9a,
0x4a75, 0x5a54, 0x6a37, 0x7a16, 0xaf1, 0x1ad0, 0x2ab3, 0x3a92,
0xfd2e, 0xed0f, 0xdd6c, 0xcd4d, 0xbdaa, 0xad8b, 0x9de8, 0x8dc9,
0x7c26, 0x6c07, 0x5c64, 0x4c45, 0x3ca2, 0x2c83, 0x1ce0, 0xcc1,
0xef1f, 0xff3e, 0xcf5d, 0xdf7c, 0xaf9b, 0xbfba, 0x8fd9, 0x9ff8,
0x6e17, 0x7e36, 0x4e55, 0x5e74, 0x2e93, 0x3eb2, 0xed1, 0x1ef0);
}


1;
__END__

=head1 NAME

Device::VantagePro - Perl module to request data in real-time or archive and configure 
a Davis Vantage Pro Weather Station that is equiped with a WeatherLink datalogger/serial port. 

=head1 SYNOPSIS

  use Device::VantagePro;
  use Data::Dumper;
  
  my %arg_hsh;  
  $arg_hsh{baudrate} = 19200;
  $arg_hsh{port} = "/dev/ttyr08";

  my $vp_obj = new Device::VantagePro(\%arg_hsh);

  $vp_obj->wake_up();

  # Start loop for 2 times and read loop data
  $vp_obj->start_loop(2); 
 
  for my $i (1..2)
  {
      my $hsh_ref = $vp_obj->read_loop();
      print Dumper $hsh_ref; # Print out data hash 
      sleep 2; 
  }

Or perhaps better yet 

  for my $i (1..2)
  {
       my $hsh_ref = $vp_obj->get_one_loop();
       print Dumper $hsh_ref; # Print out data hash 
       sleep 2;   # Sleep arbitary number of seconds no less than 1 sec. 
  }

To retrieve archive data first requires a date/time stamp and then a call to do_dmpaft 
  
  # Create date/time stamp for April 17 2010 at 0805 
  my ($dstamp,$tstamp) = $vp_obj->make_date_time_stamp(2010,4,17,8,5);
  
  my $data_ref = $vp_obj->do_dmpaft($dstamp,$tstamp); 
  foreach my $ref ( @{$data_ref} )	
  {
      # Do something with the data hash reference
      print Dumper $ref; # data hash of archive record. 
  }


=head1 DESCRIPTION

A module to provide direct access to many of the features of the Davis VantagePro Weather family of 
weather stations. 

This module was developed and tested on a Linux operating system and relies upon the Unix specific
Device::SerialPort module. A port to Windows could be accomplished using the Win32::SerialPort module 
which uses the same calls. See code for more details. 

Some things to note: The Archive data packet and the Loop data packet provide different data values. For example, the 
Loop data packet has a value for the 10-Minute ave wind speed while the Archive data packet has only the wind speed
average for the archive period.  The Archive data packet only gives the instantaneous maximum wind speed over the archive
period and not a true wind gust measurement as defined by NOAA as a maximum sustained wind speed over a 3 second 
period, therefore wind gusts tend to be high.       

=head1 METHODS

=head2 new

Object Constructor which expects an argument with a hash or reference to a hash 
providing the communication parameters. 

	$vp_obj = Device::VantagePro->new(%arg_hsh); 

Available arguements: baudrate, parity, databits, stopbits, port

Defaults for these argument parameters are as follows:    

  $arg_hsh{'port'}   = "/dev/ttyS0";
  $arg_hsh{baudrate} = 19200;
  $arg_hsh{parity}   = "none";
  $arg_hsh{databits} = 8;
  $arg_hsh{stopbits} = 1;

=head2 wake_up

The device sleeps in order to conserve power after 2 minutes of inactivity. A wake up 
call is provided which conforms to B<Section IV Waking up the Console>
  
	$vp_obj->wake_up();

Sending a command when the console is sleeping might not wake up the device fast enough to 
read the first character correctly. Because of this, you should always perform a wakeup call 
before sending commands. Many of the calls such as start_loop, read_loop, get_one_loop, etc
send a wake_up() command implicitly so there is no need to send one. 

=head2 get_archive_period
	
Retrieves the archive period for the device.  The archive period is the time period between 
each archived data record.   
	
    my $arc_period = $vp_obj->get_archive_period(); 
    my $arc_sec = $arc_period * 60; 
    print ">Archive Period is currently: $arc_period minutes\n";

=head2 set_archive_period

Sets the archive period. Acceptable values are 1, 5, 10, 15, 30, 60, 120 minutes. See Davis 
documentation. 

    $vp_obj->set_archive_period(5) || warn "Archive Period not set" ;
 
According to the documentation this call clears the archive data. 
 
=head2 gettime
 
Retrieve the current device time
 
    my $ref = $vp_obj->gettime(); 
 
Returns a reference to a list ordered as 

	#        hour   :  min    :   sec       month /    day  /     year    
	print "$ref->[2]:$ref->[1]:$ref->[0] $ref->[4]/$ref->[3]/$ref->[5]\n"; 
 
The values are returned in the same order as provided in the Davis documentation. 

=head2 settime
	
Set the device time using a reference to a list compatible with the gettime returned reference.

The order is similar to the array returned by the perl localtime function. Here is an example 
setting the device time to the server time. 	
	
    my $s_time = [ localtime() ]; 
    $s_time->[4] += 1; 
    $vp_obj->settime($s_time); 

=head2 get_timezone

Returns the timezone of the device as a DateTime::TimeZone object.

The VantagePro does not deal with timezones particularly well. The time field
contained in a record is the local time, with no information as to its
timezone. This is problematic when the local time reverts from daylight saving
time, as for the duration of that hour there will be multiple records
containing the same time value, with no way of differentiating them other than
the order that they have been recorded. In much the same way, if the timezone
of the unit is changed, no record of this will be attached to each of the
downloaded records.

For the above reasons, it is recommended that the device is configured for a
named timezone, rather than offset from GMT, as it is easier to compensate for
daylight saving changes.

=head2 start_loop

Begins a loop data acquisition sequence. Input is the number of loops to request. If 
no value is provided a loop of 1 is assumed. The function returns and expects a read_loop call 
to service the data which is delivered every 2-seconds per the documenation. I have found
problems with higher numbered loops (>40 loops) and recommend the integrated get_one_loop() 
call instead and read a loop data packet at whatever rate you wish.  

    $vp_obj->start_loop(10);

=head2 read_loop

Reads the LOOP data format as identified in B<Section IX Data Formats> in the documentation. Note this
only reads the later revision B loop format that is found in Vantage Pro devices after April 2002.  

The data is returned via a reference to a hash. 

    $vp_obj->start_loop();
    my $hsh_ref = $vp_obj->read_loop();

    # print out hash reference 
    print Dumper $hsh_ref; 

=head2 get_one_loop	

Combines a start_loop and a read_loop and returns a data hash. 

    my $hsh_ref = $vp_obj->get_one_loop();

I have not tested to see how fast this function can be called before the device chokes. It will run 
at a 2-second rep rate without a problem. 

The Loop data packet has a value for the Next_Record. This can be monitored in a loop and used to trigger 
an event to read the archive via do_dmpaft.   
	
=head2 make_date_time_stamp

Function to create a date and time stamp suitable for using in the dmpaft command. The function 
expects a list in the following order ($year, $mon, $mday, $hour, $min) and returns a date stamp and 
time stamp. 

    my ($dstamp,$tstamp) = $vp_obj->make_date_time_stamp(2010,4,17,19,15);
 
=head2 do_dmpaft

Function to retrieve the archive data after a provided date and time stamp. Refer to the Davis 
documentation B<Section IX. Data Formats> for the sub-section concerning DMP and DMPAFT data format.  

Functions requires a date stamp and time stamp as detailed in the documenation or provided in the 
make_date_time_stamp function above. 

The date/time stamp is returned in the archive record and you can save the last returned date/time
stamp values to use in the next call to return archive data after that date/time stamp. Note the 
date/time stamp must match a date/time stamp in the archive memory or the whole 513 records will be 
returned. Also if no date/time stamp is provided the complete archive will be returned.

The returned value is a reference to a list of hashes, one hash for each archive record. 

   my $ref = $vp_obj->do_dmpaft($dstamp,$tstamp); 
   unless ( @{$ref} ) { return 0 }
 
   foreach my $arc_ref ( @{$ref} ) 
   {
      # Do something with the hash reference.... 
	  print Dumper $arc_ref; 
   } 

=head2 get_eeprom
 
Retrieve specific EEPROM configuration settings. Currently the following parameters are supported:

    ARCHIVE_PERIOD
    TIME_ZONE
    MANUAL_OR_AUTO
    DAYLIGHT_SAVINGS
    GMT_OFFSET
    GMT_OR_ZONE
    SETUP_BITS

The return value is the raw hex value from the unit, so needs to be decoded:

    my $rst = $self->get_eeprom('archive_period');
    my $archive_period = hex($rst->[0]);

=head2 get_setup_bits
 
Retrieve the setup of the device. Returns a hashref with the following keys:

    TimeMode
    IsAM
    MonthDayFormat
    WindCupSize
    RainCollectorSize
    Latitude
    Longitude


=head1 SEE ALSO

Refer to:

Vantage Pro and Vantage Pro2 Serial Communication Reference Manual
Available at: 

http://www.davisnet.com/support/weather/download/VantageSerialProtocolDocs_v230.pdf

Example of module being used at: 

http://lpo.dt.navy.mil

Other related Perl modules that might be of interest.... 

Device::Davis - Low level read/write function
vanprod       - High-level integrated daemon package with lots of bells and whistles. However, 
no support for retrieving archive data or setting archive period.  

=head1 PREREQUISITES 

Device::SerialPort
Time::HiRes
use POSIX qw(:errno_h :fcntl_h strftime)
use Time::Local 

Except for Device::SerialPort the prerequisites should be loaded with a default install. 

=head1 AUTHOR

Steve Troxel, troxel AT perlworks.com

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Steve Troxel 

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
