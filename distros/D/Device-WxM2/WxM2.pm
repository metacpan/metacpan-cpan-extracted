##################################
###### Wx Monitor-II #############
##################################
package Device::WxM2;
use warnings;
use strict;
use Carp;
use Device::SerialPort;

use vars qw($VERSION);
$VERSION = '1.03';

### Device Driver For the Davis Weather Monitor II, a personal weather station
### Copyright (C) 2003  Mark Mabry
### 
###     This program is free software; you can redistribute it and/or modify
###     it under the terms of the GNU General Public License as published by
###     the Free Software Foundation; either version 2 of the License, or
###     (at your option) any later version.
### 
###     This program is distributed in the hope that it will be useful,
###     but WITHOUT ANY WARRANTY; without even the implied warranty of
###     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
###     GNU General Public License for more details.
### 
###     You should have received a copy of the GNU General Public License
###     along with this program; if not, write to the Free Software
###     Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
### 

### Motivation:  I wrote this so I could log data from my weather
### station using a Linux box that already ran a firewall and mail
### server, so was powered up all the time already.  The Davis Weather
### Monitor II only comes with software that runs on Windoze.  

### Any updated versions may be obtained from the CPAN site.
### Contact me with any bugs/suggestions at mmabry@cpan.org

### My weather station web page is
### http://home.comcast.net/~mark.mabry/Hermes_Wx.html  

### This driver depends on the Device::SerialPort Perl driver found on
### CPAN. You must install it in your @INC path.  The standard CPAN
### install will be fine.


=head1 NAME

B<WxM2> - Davis Weather Monitor II Station device driver

=head1 SYNOPSYS


  use Device::WxM2;

=head2 Constructor

  my $ws = new Device::WxM2 ("/dev/ttyS0");

=head2 Destructor

  undef $ws;

=head2 Archive Retrieval and Logging Functions

  my @wxArchiveImage = $ws->getArcImg($archivePtr);
  my @currentWx      = $ws->getSensorImage;
  my $void           = $ws->archiveCurImage();
  my $status         = $ws->updateArchiveFromPtr($lastArchivedPtr, $file);
  my $status         = $ws->batchRetrieveArchives($x, $filename);
  my $void           = $ws->printRawLogHeader();
  my $ptr            = $ws->getNewPtr;
  my $ptr            = $ws->getLastPtr;
  my $ptr            = $ws->getOldPtr;
  my $status         = $ws->setLastArcTime($time_in_minutes_since_midnight);
  my $minutes_since_midnight = $ws->getLastArcTime;

=head2 Individual Access Functions

  my $outside_temp                       = $ws->getOutsideTemp;
  my $inside_temp                        = $ws->getInsideTemp;
  my $dewpoint                           = $ws->getDewPoint;
  my $wind_speed			 = $ws->getWindSpeed;
  my $wind_dir				 = $ws->getWindDir;
  my ($windHi, $hour, $min, $mon, $day)  = $ws->getHiWind;
  my ($dewHi, $hour, $min, $mon, $day)   = $ws->getHiDewPoint;
  my ($dewLo, $hour, $min, $mon, $day)   = $ws->getLoDewPoint;
  my ($wndChLo, $hour, $min, $mon, $day) = $ws->getLoWindChill;
  my ($temp, $hour, $min, $mon, $day)    = $ws->getHiInsideTemp;
  my ($temp, $hour, $min, $mon, $day)    = $ws->getLoInsideTemp;
  my ($temp, $hour, $min, $mon, $day)    = $ws->getHiOutsideTemp;
  my ($temp, $hour, $min, $mon, $day)    = $ws->getLoOutsideTemp;
  my ($hum, $hour, $min, $mon, $day)     = $ws->getHiInsideHumidity;
  my ($hum, $hour, $min, $mon, $day)     = $ws->getLoInsideHumidity;
  my ($hum, $hour, $min, $mon, $day)     = $ws->getHiOutsideHumidity;
  my ($hum, $hour, $min, $mon, $day)     = $ws->getLoOutsideHumidity;

  my $rainfall_float           = $ws->getYearlyRain;
  my $rainfall_float           = $ws->getDailyRain;
  my $bp_float		       = $ws->getBarometricPressure;
  my $value                    = $ws->getBaroCal;
  my ($hour, $minute, $second) = $ws->getTime;
  my ($month, $day)            = $ws->getDate;

  my $status = $ws->setTime($hour_24_format, $min);
  my $status = $ws->clearHiWind;
  my $status = $ws->clearHiDewPoint;
  my $status = $ws->clearLoDewPoint;
  my $status = $ws->clearLoWindChill;
  my $status = $ws->clearHiLoOutTemp;
  my $status = $ws->clearHiLoInTemp;
  my $status = $ws->clearHiLoOutHum;
  my $status = $ws->clearHiLoInHum;
  my $status = $ws->clearDailyRain;
  my $status = $ws->clearYearlyRain;

=head2 Configuration Functions

  my $void     = $ws->setArchiveLogFilename($filename);
  my $filename = $ws->getArchiveLogFilename();
  my $void     = $ws->setStationDescription("text");
  my $string   = $ws->getStationDescription();
  my $void     = $ws->setSerialPortReadTime($timeout_value_in_milliseconds);
  my $void     = $ws->configPort();
  my $timeout_value_in_milliseconds = $ws->getSerialPortReadTime();
  my $status   = $ws->setArchivePeriod($time_in_minutes);
  my $time_in_minutes  = $ws->getArchivePeriod();
  my $status   = $ws->setLastArcTime($time_in_minutes);
  my $time_in_minutes  = $ws->getLastArcTime();


=head1 DESCRIPTION

=head2 Installation

This driver depends on the Device::SerialPort Perl driver found on
CPAN. You must install it somewhere on the @INC list, so that wxm2.pm
can call it with 'use'.  The standard CPAN install works fine.

To install WxM2, use:

    perl Makefile.PL
    make
    make test
    make install

For all the regression tests to pass, your Davis Weather Monitor II
    must be operating and connected to your computer's serial port.
    The test will query you for the name of the serial port.  It will
    also ask if you weather station is operating and connected.  If it
    is not, the regression test will skip 5 of the 8 tests.  You can
    re-run the regression test at any time with either:

    make test

    OR

    perl -w test.pl

=head2 Setup

To use the WxM2 driver, simply create a class object with 'new', ie.

   $ws = new Device::WxM2("/dev/ttyS0");

The only parameter to C<&new> is the port to which your weather station
    is connected.  The constructor initializes all the class variables
    and configures the Device::SerialPort parameters for the Davis
    Weather Station.

Note: I found that I had to fiddle with a parameter in the SerialPort,
called 'read_const_time', which is like a timeout value when
waiting for read data.  I found that the value needed to be
increased significantly for the WxM2.  I use 5000 (units are
milliseconds) and this is the default setting in this package.
Should you need to change it, use
B<&setSerialPortReadTime>(time_in_millseconds).  Then call
B<&configPort>, which puts the new setting into effect.

If you want to change to archive period, use B<&setArchivePeriod> and
B<&getArchivePeriod>.  Just remember that if you screw up the values,
you station's archive will behave strangely until you fix it.

Use B<&getLastArcTime> and B<&setLastArcTime> to establish the time at which
the archives are captured into the weather station's archive
memory.

=head2 Individual Access Functions 

There are a bunch of individual functions that retrieve one weather
value from the weather station, such as b<&getOutsideTemp>.  These are
fairly self-explanatory.

=head2 Archive Retrieval and Logging Functions

There are 2 primary archive retrieval functions:  

  &getArcImg       - get Archive Image
  &getSensorImage  - get the "live" sensor data image

B<&getArcImg> retrieves the archive image at the address given to it as
a parameter.  To retrieve the most recent archived image, use this:

  my $lastPtr = $ws->getLastPtr;
  my @archiveData = $ws->getArcImg($lastPtr);

B<&getArcImg> takes the archive data, reformats it where necessary,
stores the results in class variables, and returns an array of the
data.

	@array= ($avgInsideTempInArchivePeriod, 
                 $averageOutsideTempInArchivePeriod, 
		 $outsideTempMaximumInPeriod, 
		 $outsideTempMinimumInPeriod, 
		 $barometricPressure,
		 $avgWindSpeedInPeriod, 
		 $avgWindDirInPeriod, 
		 $maxWindGustInPeriod, 
		 $rainInPeriod, 
		 $insideHumidity,
		 $outsideHumidity, 
		 $monthOfSample, 
		 $dayOfSample, 
		 $hourOfSample, 
		 $minuteOfSample, 
		 $outsideTempHumIndex, 
		 $outsideTempHumIndexMaximum,
		 $avgWindChill, 
		 $windChillMinimum);

B<&getSensorImage> enables a continuous streaming of "live" weather
data from the Davis Wx Station.  I've found this stream to be very
easy to get out of sync, so this funcion reads a single block, stops
the streaming, and flushes the serial receive buffer.  The data
returned by this function are the current values and not average
values within a sample period, like &getArcImg returns.  The array
returned is as follows:

    @array = ($insideTemp, 
	      $outsideTemp, 
	      $windSpeed, 
	      $windDirection, 
	      $barometricPressure, 
	      $insideHumidity, 
	      $outsideHumidity, 
	      $totalRainfallToday); 

There are 4 configuration functions for logging the archive data:

  &setArchiveLogFilename  - set the name of the log file to write
			    archive data
  &getArchiveLogFilename  - returns the name of the log file
  &setStationDescription  - sets the station description text (used by
                            &printRawLogHeader)
  &getStationDescription  - returns the station description string

Use B<&setArchiveLogFilename> to set the log file name.  It is used by
    all logging function calls in the class.

There are two logging functions:
  
  &archiveCurImage   - Writes the periodic data samples to a file
  &printRawLogHeader - Prints Header for the periodic samples log file

B<&archiveCurImage> writes the data samples held in the class variables
to a filename passed in as its only parameter.  For example,

  $ws->archiveCurImage();

will write the data samples as 1 line of data in the file
B<&getArchiveLogFilename>.

B<&printRawLogHeader> writes a header for the data samples into the
filename in B<&getArchiveLogFilename>.  The second line of the header for your
weather station description.  Set it with
B<&setStationDescription>("description").  Typically it contains the
name and location of the weather station.

The function B<&batchRetrieveArchives> is handy for retrieving multiple
archived images from the WxM2's archive memory.  I use it primarily
after an extended power outage, but there are lots of other reasons to
use it.  Us is at follows:

  $ws->batchRetrieveArchives($number, $filename);

where $number is the number of archives to retrieve starting with the most
recent and counting back.  And $filename is the string for the file to
write all the archive to.

The function B<&updateArchiveFromPtr> is a low-level function that retrieves archives from an initial pointer value.  B<&batchRetrieveArchives> is a user-friendly front-end for this funtion.  In most all cases B<&batchRetrieveArchives> should be used.  Just in case, you can use B<&updateArchiveFromPtr> as follows:

  $ws->updateArchiveFromPtr($lastArchivePtr, $file);

where $lastArchivePtr is the address of the last archive image that
you read.  &updateArchiveFromPtr will call &getArcImg and
&archiveCurImage for each address between $lastArchivePtr and the
currently active archive image.  It will NOT return the image at
$lastArchivePtr or the currently active image, only the ones in
between.  $file is a filename in which all the output will be
written.  

=head1 KNOWN LIMITATIONS AND BUGS

This driver is primarily for archive retrieval, so things like alarm
functions on the WxM2 are not implemented.

B<&getSensorImage> data tends to get out of sync or overflow the receive
buffer, so it currently terminates the intended nearly infinite stream
of data after 1 complete block.

=head1 HISTORY / CHANGES

Version 1.03 - added getInsideTemp, getWindSpeed, getWindDir, and 
getBarometricPressure functions.  Fixed barometer calibration bug.  

Version 1.02 - added barometer calibration and bug fix in
    batchRetrieveArchives.

Version 1.00 is the first public version.  I have been using it for
    about 2 years, and it seems stable.

=head1 AUTHOR

Mark Mabry: mmabry@cpan.org

=head2 NOTE

If you use, or even try out, this software, please drop me a short
    email at mmabry@cpan.org, to let me know that others are using it.  

=head1 SEE ALSO

Device::SerialPort

=head1 ACKNOWLEDGEMENTS

Thanks to Davis Instruments for publishing the reference
specifications needed to access the Weather Monitor II.

Chris Snell added the getInsideTemp, getWindSpeed, and getWindDir functions.

Wayne Hahn fixed a bug in a pack call that popped up in Perl 5.8.  He also 
added a sleep 1 to getSensorImage command to get it to run smoothly.

=head1 COPYRIGHT

Copyright (C) 2003, 2004 Mark Mabry. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU public license.

=cut 

use FileHandle;
use vars qw($wxPort);


my $DEBUG = 0;

my $quiet = 1;
my $sample_offset = 0;		# most will set this = 0.

my @compass_rose = ("N", "NNE", "NE", "ENE", "E",
		    "ESE", "SE", "SSE", "S", "SSW",
		    "SW", "WSW", "W", "WNW", "NW", "NNW");


###################################################################
##                                                               ##
##  Setup Functions						 ##
##                                                               ##
###################################################################

sub new {
    my $class = shift;
    my $portName = shift;
    my $self = {};

    $wxPort = new Device::SerialPort ($portName, $quiet);
    unless (defined $wxPort) {
	print STDERR "Could not open $portName\n";
	return undef;
    }
    bless $self, $class;
    $self->_initialize();
    $self->{portName} = $portName;
    $self->configPort();
    $self->setupBaroCal();
    return $self;
}

sub _initialize {
    my $self = shift;

    ##
    ## Class storage variables
    ##
    ### Instant Sensor data
    $self->{outTemp} = 0;
    $self->{inTemp} = 0;
    $self->{baro} = 0;
    $self->{windSpeed} = 0;
    $self->{windDir} = 0;
    $self->{windGust} = 0;
    $self->{inHum} = 0;
    $self->{outHum} = 0;
    $self->{rainTotal} = 0;

    $self->{avgOutTemp} = 0;
    $self->{loTemp} = 0;
    $self->{hiTemp} =0;
    $self->{avgInTemp} = 0;
    $self->{avgWindSpeed} = 0;
    $self->{windGust} = 0;
    $self->{rainInPrd} = 0;
    $self->{date} = "";
    $self->{time} = "";
    $self->{thi} = 0;
    $self->{hiTHI} = 0;
    $self->{windChillLo} = 0;
    $self->{avgWindDir} = 0;
    # these are used in both getArcImg and getSensorImage.
    $self->{inHum} = 0;
    $self->{outHum} = 0;

    $self->{dewpoint} = -100;
    $self->{avgDewpoint} = -100;

    # BaroCal
    $self->{baroCal} = 0;
    $self->{isBaroCalSet} = 0;

    # Configuration
    $self->{portName} = "Not set";
    $self->{serialPortReadConstTime} = 5000;
    my $year = &whichYear;
    $self->{archiveLogFile} = "./wx_$year.log";
    $self->{stationDescription} = 
	"Use &setStationDescription(\"text\"); to put your Wx station text here;";
}

sub configPort {
    my $self = shift;

    # configure port
    $wxPort->user_msg("ON");
    $wxPort->error_msg("ON");
    $wxPort->databits(8);
    $wxPort->baudrate(2400);
    $wxPort->parity("none");
    $wxPort->stopbits(1);
    $wxPort->handshake("rts");
    $wxPort->datatype('raw');
    $wxPort->{"_DEBUG"} = ($DEBUG > 2) ? 1 : 0;
    $wxPort->read_const_time($self->{serialPortReadConstTime});	# const time for read (milliseconds)
    $wxPort->read_char_time(50);		# avg time between read char
}

sub saveSerialConfig {
    my $self = shift;
    
    my $filename = (scalar(@_)) ? shift : "ttyS0_wxport";

    # save config
    $wxPort->write_settings || croak "Couldn't write settings\n";
    $wxPort->save($filename);
}

sub setSerialPortReadTime {
    my $self = shift;
    $self->{serialPortReadConstTime} = shift;
}
sub getSerialPortReadTime {
    my $self = shift;
    return $self->{serialPortReadConstTime};
}

sub setArchiveLogFilename {
    my $self = shift;
    $self->{archiveLogFile} = shift;
}

sub getArchiveLogFilename {
    my $self = shift;
    return $self->{archiveLogFile};
}

sub setStationDescription {
    my $self = shift;
    $self->{stationDescription} = shift;
}

sub getStationDescription {
    my $self = shift;
    return $self->{stationDescription};
}

### Not needed for Weather Monitor II.  Other Davis stations may need
### this.  Not tested.
sub disableCRC {
    my $self = shift;
    ####################
    ## This may have to be run the first time only.  
    ###################

    # turn off CRC
    my $crcByte0 = pack "c", 44;
    my $crcByte1 = pack "c", 247;
    my $crc0 = "CRC0";
    my $returnChar = pack "c", 0x0d;
    my $count = $wxPort->write($crcByte0);
    warn "write failed\n"  unless ($count);
    warn "write incomplete\n"     if ( $count != length($crcByte0));
    #print "Write count=$count";
    
    $count = $wxPort->write($crcByte1);
    #warn "write failed\n"  unless ($count);
    #warn "write incomplete\n"     if ( $count != length($crcByte1));
    
    $count = $wxPort->write($crc0);
    warn "write failed\n"  unless ($count);
    warn "write incomplete\n"     if ( $count != length($crc0));
    
    $count = $wxPort->write($returnChar);
    warn "write failed\n"  unless ($count);
    warn "write incomplete\n"     if ( $count != length($returnChar));

    unless ($wxPort->write_done) {
	print "waiting to finish first write\n";
	sleep 1;
    }
    $self->_get_ack();
}

###################################################################
##                                                               ##
##   Individual Access Functions                                 ##
##                                                               ##
###################################################################
sub getOutsideTemp {
    my $self = shift;

    my @str_in = $self->read("RRD", 1, 0x20, 4);
    return undef unless ($self->_valCheck(2, \@str_in));

    my $outTemp = $self->tempConv(@str_in);
    $self->{outTemp} = $outTemp;
    return $outTemp;
}

sub getInsideTemp {
    my $self = shift;

    my @str_in = $self->read("RRD", 1, 0x1C, 4);
    return undef unless ($self->_valCheck(2, \@str_in));

    my $inTemp = $self->tempConv(@str_in);
    $self->{inTemp} = $inTemp;
    return $inTemp;
}

sub getWindSpeed {
    my $self = shift;

    my @str_in = $self->read("WRD", 0, 0x5E, 4); 
    return undef unless ($self->_valCheck(2, \@str_in));

    # my $windSpeed = ($str_in[1]*256 + $str_in[0]);
    my $windSpeed = $str_in[0];
    $self->{windSpeed} = $windSpeed;
    return($windSpeed);
}

sub getWindDir {
    my $self = shift;
    my @str_in = $self->read("WRD", 1, 0xB4, 4);
    return undef unless ($self->_valCheck(2, \@str_in));

    my $windDir = "$str_in[0]";
    $self->{windDir} = $windDir;
    return($windDir);
}


sub getHiWind {
    my $self = shift;

    my @str_in = $self->read("WRD", 0, 0x60, 4);
    return undef unless ($self->_valCheck(2, \@str_in));

    my $windHi = ($str_in[1]*256 + $str_in[0]);
    $self->{windGust} = $windHi;
    my ($hour, $min, $mon, $day) = $self->readTimeDate(0, 0x64, 0, 0x68);
    $self->{windGustTime} = $hour . ":" . $min;
    $self->{windGustDate} = $mon . "/" . $day;
    return ($windHi, $hour, $min, $mon, $day);
}

sub getDewPoint {
    my $self = shift;

    my @str_in = $self->read("WRD", 0, 0x8A, 4);
    return undef unless ($self->_valCheck(2, \@str_in));

    my $dew = $self->tempConv(@str_in);
    $self->{dewPoint} = $dew;
    return $dew;
}

sub getHiDewPoint {
    my $self = shift;

    my @str_in = $self->read("WRD", 0, 0x8E, 4);
    return undef unless ($self->_valCheck(2, \@str_in));

    my $dew = $self->tempConv(@str_in);
    $self->{DewPointHi} = $dew;
    my ($hour, $min, $mon, $day) = $self->readTimeDate(0, 0x96, 0, 0x9E);
    $self->{dewHiTime} = $hour . ":" . $min;
    $self->{DewHiDate} = $mon . "/" . $day;
    return ($dew, $hour, $min, $mon, $day);
}

sub getLoDewPoint {
    my $self = shift;

    my @str_in = $self->read("WRD", 0, 0x92, 4);
    return undef unless ($self->_valCheck(2, \@str_in));

    my $dew = $self->tempConv(@str_in);
    $self->{DewPointLo} = $dew;
    my ($hour, $min, $mon, $day) = $self->readTimeDate(0, 0x9A, 0, 0xA1);
    $self->{dewLoTime} = $hour . ":" . $min;
    $self->{DewLoDate} = $mon . "/" . $day;
    return ($dew, $hour, $min, $mon, $day);
}

sub getLoWindChill {
    my $self = shift;

    my @str_in = $self->read("WRD", 0, 0xAC, 4);
    return undef unless ($self->_valCheck(2, \@str_in));

    my $wc = $self->tempConv(@str_in);
    $self->{WindChillLo} = $wc;
    my ($hour, $min, $mon, $day) = $self->readTimeDate(0, 0xB0, 0, 0xB4);
    $self->{WindChillLoTime} = $hour . ":" . $min;
    $self->{WindChillLoDate} = $mon . "/" . $day;
    return ($wc, $hour, $min, $mon, $day);
}

sub getHiInsideTemp {
    my $self = shift;

    my @str_in = $self->read("WRD", 1, 0x34, 4);
    return undef unless ($self->_valCheck(2, \@str_in));

    my $temp = $self->tempConv(@str_in);
    $self->{InTempHi} = $temp;
    my ($hour, $min, $mon, $day) = $self->readTimeDate(1, 0x3C, 1, 0x44);
    $self->{InTempHiTime} = $hour . ":" . $min;
    $self->{InTempHiDate} = $mon . "/" . $day;
    return ($temp, $hour, $min, $mon, $day);
}

sub getLoInsideTemp {
    my $self = shift;

    my @str_in = $self->read("WRD", 1, 0x138, 4);
    return undef unless ($self->_valCheck(2, \@str_in));

    my $temp = $self->tempConv(@str_in);
    $self->{InTempLo} = $temp;
    my ($hour, $min, $mon, $day) = $self->readTimeDate(1, 0x40, 1, 0x47);
    $self->{InTempLoTime} = $hour . ":" . $min;
    $self->{InTempLoDate} = $mon . "/" . $day;
    return ($temp, $hour, $min, $mon, $day);
}

sub getHiOutsideTemp {
    my $self = shift;

    my @str_in = $self->read("WRD", 1, 0x5A, 4);
    return undef unless ($self->_valCheck(2, \@str_in));

    my $temp = $self->tempConv(@str_in);
    $self->{OutTempHi} = $temp;
    my ($hour, $min, $mon, $day) = $self->readTimeDate(1, 0x62, 1, 0x6A);
    $self->{OutTempHiTime} = $hour . ":" . $min;
    $self->{OutTempHiDate} = $mon . "/" . $day;
    return ($temp, $hour, $min, $mon, $day);
}

sub getLoOutsideTemp {
    my $self = shift;

    my @str_in = $self->read("WRD", 1, 0x5E, 4);
    return undef unless ($self->_valCheck(2, \@str_in));

    my $temp = $self->tempConv(@str_in);
    $self->{OutTempLo} = $temp;
    my ($hour, $min, $mon, $day) = $self->readTimeDate(1, 0x66, 1, 0x6D);
    $self->{OutTempLoTime} = $hour . ":" . $min;
    $self->{OutTempLoDate} = $mon . "/" . $day;
    return ($temp, $hour, $min, $mon, $day);
}

sub getHiInsideHumidity {
    my $self = shift;

    my @str_in = $self->read("WRD", 1, 0x82, 2);
    return undef unless ($self->_valCheck(1, \@str_in));

    my $hum = $str_in[0];
    $self->{InHumHi} = $hum;
    my ($hour, $min, $mon, $day) = $self->readTimeDate(1, 0x86, 1, 0x8E);
    $self->{InHumHiTime} = $hour . ":" . $min;
    $self->{InHumHiDate} = $mon . "/" . $day;
    return ($hum, $hour, $min, $mon, $day);
}

sub getLoInsideHumidity {
    my $self = shift;

    my @str_in = $self->read("WRD", 1, 0x84, 2);
    return undef unless ($self->_valCheck(1, \@str_in));

    my $hum = $str_in[0];
    $self->{InHumLo} = $hum;
    my ($hour, $min, $mon, $day) = $self->readTimeDate(1, 0x8A, 1, 0x91);
    $self->{InHumLoTime} = $hour . ":" . $min;
    $self->{InHumLoDate} = $mon . "/" . $day;
    return ($hum, $hour, $min, $mon, $day);
}
sub getHiOutsideHumidity {
    my $self = shift;

    my @str_in = $self->read("WRD", 1, 0x9A, 2);
    return undef unless ($self->_valCheck(1, \@str_in));

    my $hum = $str_in[0];
    $self->{OutHumHi} = $hum;
    my ($hour, $min, $mon, $day) = $self->readTimeDate(1, 0x9E, 1, 0xA6);
    $self->{OutHumHiTime} = $hour . ":" . $min;
    $self->{OutHumHiDate} = $mon . "/" . $day;
    return ($hum, $hour, $min, $mon, $day);
}
sub getLoOutsideHumidity {
    my $self = shift;

    my @str_in = $self->read("WRD", 1, 0x9C, 2);
    return undef unless ($self->_valCheck(1, \@str_in));

    my $hum = $str_in[0];
    $self->{OutHumLo} = $hum;
    my ($hour, $min, $mon, $day) = $self->readTimeDate(1, 0xA2, 1, 0xA9);
    $self->{OutHumLoTime} = $hour . ":" . $min;
    $self->{OutHumLoDate} = $mon . "/" . $day;
    return ($hum, $hour, $min, $mon, $day);
}

sub getYearlyRain {
    my $self = shift;
    
    my @yRainBytes = $self->read("WRD", 1, 0xCE, 4);
    return undef unless ($self->_valCheck(2, \@yRainBytes));

    return ($yRainBytes[1]*256 + $yRainBytes[0])/100;
}

sub getDailyRain {
    my $self = shift;

    my @dRainBytes = $self->read("WRD", 1, 0xD2, 4);
    return undef unless ($self->_valCheck(2, \@dRainBytes));

    return ($dRainBytes[1]*256 + $dRainBytes[0])/100;
}

sub getBarometricPressure {
    my $self = shift;

    my @baroPressure = $self->read("WRD", 1, 0x00, 4);
    return undef unless ($self->_valCheck(2, \@baroPressure));
    
    # raw barometric pressure reading
    my $bp = ($baroPressure[1]*256 + $baroPressure[0])/1000;

    # subtract baroCal factor, if set
    if ($self->{isBaroCalSet}) {
	$bp -= $self->{baroCal};
    }
    return $bp;
}

sub setupBaroCal {
    my $self = shift;

    my $baroCal = $self->getBaroCal;
    return undef unless (defined $baroCal);

    # Note, this will not work for places below sea level, since it
    # assumes the calibration number should be negative
    $self->{baroCal} = -(65536 - $baroCal)/1000;
    $self->{isBaroCalSet} = 1;
    return;
}

sub unsetBaroCal {
    my $self = shift;

    $self->{isBaroCalSet} = 0;
    return;
}

sub getBaroCal {
    my $self = shift;

    my @str_in = $self->read("WRD", 2, 0x2C, 4);
    return undef unless ($self->_valCheck(2, \@str_in));

    printf "BaroCal=%02x%02x\n", $str_in[1], $str_in[0] if $DEBUG > 1;
    return ($str_in[1]*256 + $str_in[0]);
}

sub getTime{
    my $self = shift;

    my @str_in = $self->read("WRD", 1, 0xBE, 6);
    return undef unless ($self->_valCheck(3, \@str_in));

    my $second = bcd2dec($str_in[2]);
    my $minute = bcd2dec($str_in[1]);
    my $hour   = bcd2dec($str_in[0]);
    printf "Time is %d:%02d:%02d\n", $hour, $minute, $second if $DEBUG > 1;
    return ($hour, $minute, $second);
}

sub getDate {
    my $self = shift;

    my @str_in = $self->read("WRD", 1, 0xC8, 6);
    return undef unless ($self->_valCheck(3, \@str_in));

    my $month = $str_in[1];
    my $day    = bcd2dec($str_in[0]);
    printf "Date is %d/%02d\n", $month, $day if $DEBUG > 1;
    return ($month, $day);
}

sub getArchivePeriod {
    my $self = shift;

    my @str_in = $self->read("RRD", 1, 0x3C, 2);
    return undef unless ($self->_valCheck(1, \@str_in));

    my $period = $str_in[0];
    printf "Archive Period is %d minutes\n", $period if $DEBUG > 1;
    return $period;
}

sub setArchivePeriod {
    my $self = shift;
    my $period = shift;

    return $self->write("RWR", 1, 0x3C, 2, $period);
}

sub getLastArcTime {
    my $self = shift;

    my @str_in = $self->read("RRD", 1, 0x48, 4);
    return undef unless ($self->_valCheck(2, \@str_in));

    my $minutes = $str_in[1] * 256 + $str_in[0]; 
    if ($DEBUG > 1) {
	printf "last Archive Time is %d minutes since midnight\n",
	$minutes; 
    }
    return $minutes;
}

sub setLastArcTime {
    my $self = shift;
    my $timeInMin = shift;

    return $self->write("RWR", 1, 0x48, 4, $timeInMin);
}

# New Pointer is the address of the Archive image currently in progress.
# Output is in hex format.
sub getNewPtr {
    my $self = shift;
    my @str_in = $self->read("RRD", 1, 0, 4);
    return undef unless ($self->_valCheck(2, \@str_in));

    printf "NewPtr=%02x%02x\n", $str_in[1], $str_in[0] if $DEBUG > 1;
    return sprintf("%02x%02x", $str_in[1], $str_in[0]);
}

# Returns the most recently completed archive image address.
# Output is in decimal.
sub getLastPtr {
    my $self = shift;

    my $newPtr = hex($self->getNewPtr);
    return (($newPtr - 21) & 0xffff);
}

# Old Pointer is the address of the oldest completed Archive image.
sub getOldPtr {
    my $self = shift;
    my @str_in = $self->read("RRD", 1, 4, 4);
    return undef unless ($self->_valCheck(2, \@str_in));

    printf "OldPtr=%02x%02x\n", $str_in[1], $str_in[0] if $DEBUG > 1;
    return sprintf("%02x%02x", $str_in[1], $str_in[0]);
}

sub clearHiWind {
    my $self = shift;
    return $self->write("WWR", 0, 0x60, 4, 0);
}

sub clearHiDewPoint {
    my $self = shift;
    return $self->write("WWR", 0, 0x8E, 4, 0);
}

sub clearLoDewPoint {
    my $self = shift;
    return $self->write("WWR", 0, 0x92, 4, 1200);
}

sub clearLoWindChill {
    my $self = shift;
    return $self->write("WWR", 0, 0xAC, 4, 1200);
}

sub clearHiLoOutTemp {
    my $self = shift;
    unless ($self->write("WWR", 1, 0x5A, 4, 0x8080)) {
	return 0;
    }
    return $self->write("WWR", 1, 0x5E, 4, 1200)
}
sub clearHiLoInTemp {
    my $self = shift;
    unless ($self->write("WWR", 1, 0x34, 4, 0x8080)) {
	return 0;
    }
    return $self->write("WWR", 1, 0x38, 4, 1200)
}
sub clearHiLoOutHum {
    my $self = shift;
    unless ($self->write("WWR", 1, 0x9A, 2, 0)) {
	return 0;
    }
    return $self->write("WWR", 1, 0x9C, 2, 100)
}
sub clearHiLoInHum {
    my $self = shift;
    unless ($self->write("WWR", 1, 0x82, 2, 0)) {
	return 0;
    }
    return $self->write("WWR", 1, 0x84, 2, 100)
}

sub clearDailyRain {
    my $self = shift;
    return $self->write("WWR", 1, 0xD2, 4, 0);
}

sub clearYearlyRain {
    my $self = shift;
    return $self->write("WWR", 1, 0xCE, 4, 0);
}

sub setTime {
    my $self = shift;
    my $hour = shift; # 24 hour time
    my $min = shift;

    my $bcdMin = sprintf("%02d", $min);
    my $bcdHour = sprintf("%02d", $hour);

    my $hexHour = hex $bcdHour;
    printf "bcdHour=0x%x \n", $hexHour if $DEBUG > 1;
    $wxPort->write("WWR");
    $wxPort->write(pack "C", 0x23);	# 2 nibbles | bank 1 = 3
    $wxPort->write(pack "C", 0xBE); # address
    $wxPort->write(pack "C", $hexHour);
    $wxPort->write(pack "C", 0xD);
    $wxPort->write_done;
    unless ($self->_get_ack()) {
	print "setTime: Write not accepted\n" if $DEBUG > 0;
	return 0;
    }

    my $hexMin = hex $bcdMin;
    printf "bcdMin=0x%x \n", $hexMin if $DEBUG > 1;
    $wxPort->write("WWR");
    $wxPort->write(pack "C", 0x23);	# 2 nibbles | bank 1
    $wxPort->write(pack "C", 0xC0); # address
    $wxPort->write(pack "C", $hexMin);
    $wxPort->write(pack "C", 0xD);
    $wxPort->write_done;
    unless ($self->_get_ack()) {
	print "setTime: Write not accepted\n" if $DEBUG > 0;
    }
}

#  sub setBaroCal {
#      my $self = shift;

#      $wxPort->write("WWR");
#      $wxPort->write(pack "C", 0x44); # address
#      $wxPort->write(pack "C", 0x2C);
#      $wxPort->write(pack "S", 0x0);
#      $wxPort->write(pack "C", 0xD);
#      $wxPort->write_done;

#  }


###################################################################
##                                                               ##
##  Archive Retrieval and Logging Functions                      ##
##                                                               ##
###################################################################

sub getArcImg {
    my $self = shift;
    my $addr = shift;

    # Flush InBuffer
    $wxPort->purge_rx;

    $wxPort->write("SRD");
    $wxPort->write(pack "S", $addr); # address
    $wxPort->write(pack "C2", 20);	# bytes - 1
    $wxPort->write(pack "C", 0xD);
    $wxPort->write_done;
    if ($self->_get_ack()) {
	my @str_in = readData(23); # bytes 22,23 unused (don't know why 
				   # 2 extra bytes come back.


	my $baro = ($str_in[1]*256 + $str_in[0])/1000;
	if ($self->{isBaroCalSet}) {
	    # substract baroCal, to compensate for lower absolute pressure at 
	    # higher altitudes
	    $baro -= $self->{baroCal}; 
	}
	my $rainInPrd = ($str_in[5]*256 + $str_in[4])/100;
	my $inTemp = $self->tempConv($str_in[6], $str_in[7]);
	my $outTemp = $self->tempConv($str_in[8], $str_in[9]);
	my $outTempHi = $self->tempConv($str_in[12], $str_in[13]);
	my $outTempLo = $self->tempConv($str_in[19], $str_in[20]);
	my $wind = $str_in[10];
	my $avgWindDir = $compass_rose[$str_in[11]];
	my $windGust = $str_in[14];
	if (($windGust == 0) or ($str_in[11] == 255)) {
	    $avgWindDir = "--";
	}
	my $inHum = $str_in[2];
	my $outHum = $str_in[3];

	#       The TimeStamp field in archive records and in the archive
	#  image consists of 4 bytes that identify the time and date of the
	#  stored record, or the current time and date on the station. The
	#  first byte is the hours (0-23) in BCD, the second is the minutes
	#  (0-60) in BCD, the third is the day of the month (0-31) in BCD,
	#  and the fourth is the month (1-12) in binary.
	my $hour = &bcd2dec($str_in[15]);
	printf "Hour string %s\n", $str_in[15] if ($DEBUG > 1);
	my $min = &bcd2dec($str_in[16]);
	my $day = &bcd2dec($str_in[17]);
	my $mon = $str_in[18] % 16;

	# my wxlink samples at :02 and :32 min.  Convert that to :00 and :30.
	$min -= $sample_offset;

	# Calculate THI
	my $outTHI = $self->calcTHI($outTemp, $outHum);
	my $outTHIHi = $self->calcTHI($outTempHi, $outHum);

	# Calculate Wind Chill
 	my $windChillLo = $self->windChill($windGust, $outTemp);
 	my $windChill = $self->windChill($wind, $outTemp);
	$self->{windChill} = $windChillLo;


	if ($DEBUG > 0) {
	    printf "BaroCal is %s set\n", ($self->{isBaroCalSet}) ? "" : "NOT";
	    printf "Avg Inside Temp is %f Degrees F\n", $inTemp;
	    printf "Avg Outside Temp is %f Degrees F\n", $outTemp;
	    printf "Avg Wind speed is %d\n", $wind;
	    printf "Avg Wind dir is %s\n", $avgWindDir;
	    printf "Barometer reads %f\n", $baro;
	    printf "Inside Humidity is %d\n", $inHum;
	    printf "Outside Humidity is %d\n", $outHum;
	    printf "Rainfall in Period is %f\n", $rainInPrd;
	    printf "Wind gusting to %d mph\n", $windGust;
	    printf "Timestamp: %d:%02d on the %d day of the %d month\n",
	    $hour, $min, $day, $mon;
	    printf "Outside Hi Temp: %f\n", $outTempHi;
	    printf "Outside Lo Temp: %f\n", $outTempLo;
	    printf "Outside THI: %f\n", $outTHI;
	    printf "Outside Hi THI: %f\n", $outTHIHi;
	    printf "Wind Chill: %f Degrees\n", $windChill;
	    printf "Min Wind Chill in Period: %f Degrees\n", $windChillLo;
	    printf "Date is %d/%02d, Time is %0d:%02d\n", $mon, $day, $hour, $min;
	    my($BlockingFlags, $InBytes, $OutBytes, $ErrorFlags) = $wxPort->status;
	    printf "OutBytes=%d\n",$OutBytes;
	    printf "InBytes=%d\n",$InBytes;
	}
	
	$self->{avgOutTemp} = sprintf("%02.1f", $outTemp);
	$self->{loTemp} = sprintf("%02.1f", $outTempLo);
	$self->{hiTemp} = sprintf("%02.1f", $outTempHi);
	$self->{avgInTemp} = sprintf("%02.1f",$inTemp);
	$self->{baro} = sprintf("%5.3f", $baro);
	$self->{avgWindSpeed} = $wind;
	$self->{avgWindDir} = $avgWindDir;
	$self->{windGust} = $windGust;
	$self->{rainInPrd} = sprintf("%3.2f", $rainInPrd);
	$self->{inHum} = $inHum;
	$self->{outHum} = $outHum;
	$self->{date} = $mon . "/" . sprintf("%02d",$day);
	$self->{time} = $hour . ":" . sprintf("%02d", $min);
	$self->{thi} = sprintf "%5.1f", $outTHI;
	$self->{hiTHI} = sprintf "%5.1f", $outTHIHi;
	$self->{windChillLo} = sprintf "%5.1f", $windChillLo;

	# Calculate Dewpoint.  Don't return it with array, just store it in class vars.
	my $dpt = $self->calcDewPoint();
	$self->{avgDewpoint} = sprintf "%4.1f", $dpt;

	return ($inTemp, $outTemp, $outTempHi, $outTempLo, $baro,
		$wind, $avgWindDir, $windGust, $rainInPrd, $inHum,
		$outHum, $mon, $day, $hour, $min, $outTHI, $outTHIHi,
		$windChill, $windChillLo);

    } else { # get_ack failed
    # print results
	my($BlockingFlags, $InBytes, $OutBytes, $ErrorFlags) = $wxPort->status;
	printf "OutBytes=%d\n",$OutBytes;
	printf "InBytes=%d\n",$InBytes;
	return 0;
    }


}

sub batchRetrieveArchives {
    my ($self, $num, $file) = @_;

    my $lastPtr = $self->getLastPtr;
    my $sizeOfBatch = 21 * $num;

    # 21 bytes does not divide evenly into 32K bytes.  The last valid
    # pointer address is 0x7fe3.  The next pointer would be 0x7ff8,
    # but it would not have the full 21 bytes before wrapping to
    # address 0x0.  So an additional 8 bytes are subtracted when
    # calculating the wrap address.
    my $firstPtr;
    if ($sizeOfBatch > $lastPtr) {
	$firstPtr = ($lastPtr - $sizeOfBatch - 8) & 0x7fff;
    } else {
	$firstPtr = $lastPtr - $sizeOfBatch;
    }
    printf "firstPtr=%d lastPtr=%d\n", $firstPtr, $lastPtr;
    return $self->updateArchiveFromPtr($firstPtr, $file);
}

sub updateArchiveFromPtr {
    my ($self, $lastArchivedPtr, $file) = @_;
    my $i;
    my $rdFailed = 0;
    my $newPtrHex = $self->getNewPtr();
    return 0 unless defined $newPtrHex;
    my $newPtr = hex($newPtrHex) - 21;
    
    $lastArchivedPtr += 21;
    if ($lastArchivedPtr > 0x7FFF) {
	$lastArchivedPtr -= 0x7FFF;
    }

    # Push $file using local
    local $self->{archiveLogFile} = $file;
    
    printf "Update from %x to %x\n", $lastArchivedPtr, $newPtr 
	if $DEBUG > 0;
    # test for address wrapping here
    if ($newPtr < $lastArchivedPtr) {
	#  Last valid ptr addr = 0x7fe3.  0x7ff8 is NOT valid.
	for ($i=$lastArchivedPtr; $i < 0x7FF8; $i+=21) {
	    unless ($self->getArcImg($i)) {
		$rdFailed = 1;
		last;
	    }
	    $self->archiveCurImage();
	    printf "Archived address %x\n",$i if $DEBUG > 0;
	}
	$lastArchivedPtr = 0;
    }

    return 0 if $rdFailed;
    for ($i=$lastArchivedPtr; $i <= $newPtr; $i+=21) {
	$self->getArcImg($i);
	#unless ($self->getArcImg($i)) {
#	    return 0;
	#}
	$self->archiveCurImage();
	printf "Archived address %x\n",$i if $DEBUG > 0;
    }
    return 1;
}

##
## `getSensorImage' enables a continuous streaming of 18 byte chunks of 
## weather data from the Davis Wx Station.  I've found this stream to be
## very easy to get out of sync, so this funcion read a single 18 byte chunk, 
## stops the streaming, and flushes the serial Rx buffer
##
sub getSensorImage {
    ##### LOOP ######
    #  Monitor, Wizard, and Perception Sensor Image:
    #       start of block                     1 byte
    #       inside temperature                 2 bytes
    #       outside temperature                2 bytes
    #       wind speed                         1 byte
    #       wind direction                     2 bytes
    #       barometer                          2 bytes
    #       inside humidity                    1 byte
    #       outside humidity                   1 byte
    #       total rain                         2 bytes
    #       not used                           2 bytes
    #       CRC checksum                       2 bytes
    #                                         --------
    #                                         18 bytes
    #################
    my $self = shift;

    $wxPort->write("LOOP");
#    $wxPort->write(pack "C2", 65535);  # doesn't work in perl 5.8
    $wxPort->write(pack "C2", 255, 255); 
    $wxPort->write(pack "C", 0xD);

    return undef unless ($self->_get_ack());

    my ($count, $string_in) = $wxPort->read(16);
    warn "read unsuccessful\n" unless (($count == 16) && ($DEBUG > 0));

    my @str_in = unpack "C16", $string_in;
    my $inTemp = $self->tempConv($str_in[1], $str_in[2]);
    my $outTemp = $self->tempConv($str_in[3], $str_in[4]);
    my $baro = ($str_in[9]*256 + $str_in[8])/1000;
    if ($self->{isBaroCalSet}) {
	# subtract baroCal, to compensate for lower absolute pressure at 
	# higher altitudes
	$baro -= $self->{baroCal};
    }
    my $tot_rain = ($str_in[13]*256 + $str_in[12])/100;
    my $wind = $str_in[5];
    my $windAdjDir = ($str_in[7]*256 + $str_in[6] + 11) % 360;
    my $windDirDegree = $windAdjDir;
    my $windDirDeg16 = int $windDirDegree/22.5;
    my $windDir = $compass_rose[$windDirDeg16];
    my $inHum = $str_in[10];
    my $outHum = $str_in[11];
    if ($DEBUG > 1) {
	printf "Inside Temp is %f Degrees F\n", $inTemp;
	printf "Outside Temp is %f Degrees F\n", $outTemp;
	printf "Wind speed is %d\n", $wind;
	printf "Wind dir is %d\n", $windDir;
	printf "Barometer reads %f\n", $baro;
	printf "Inside Humidity is %d%\n", $inHum;
	printf "Outside Humidity is %d%\n", $outHum;
	printf "Total rainfall is %f\n", $tot_rain;
    }
    my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime(time);
    $self->{outTemp} = sprintf("%02.1f", $outTemp);
    $self->{inTemp} = sprintf("%02.1f",$inTemp);
    $self->{baro} = sprintf("%5.3f", $baro);
    $self->{windSpeed} = $wind;
    $self->{windDir} = $windDir;
    $self->{rainTotal} = sprintf("%3.2f", $tot_rain);
    $self->{inHum} = $inHum;
    $self->{outHum} = $outHum;
    $self->{date} = $mon+1 . "/" . sprintf("%02d",$mday);
    $self->{time} = $hour . ":" . sprintf("%02d", $min);

    # Stops loop
    #&getOutsideTemp();
    
    # Wayne Hahn suggested a sleep 1 here to pace the loop.
    sleep 1;

    # issues command and ignore data, ack.
    $wxPort->write("RRD");
    $wxPort->write(pack "C", 1);	# bank
    $wxPort->write(pack "C", 0x20); # address
    $wxPort->write(pack "C", 3);	# nibbles - 1
    $wxPort->write(pack "C", 0xD);
    $wxPort->write_done;

    # Flush InBuffer
    $wxPort->purge_rx;

    # Return array with all items
    return ($inTemp, $outTemp, $wind, $windDir, $baro, $inHum, $outHum, 
	    $tot_rain); 
}

###############################################################################
##
##   Subroutines for the Periodic Data Samples Log 
##
###############################################################################

## Prints Header for the periodic samples log file
sub printRawLogHeader {
    my $self = shift;
#    my $file = shift;

    my $log = new FileHandle ">>$self->{archiveLogFile}";
    unless (defined $log) {
	carp "Could not open $self->{archiveLogFile}";
    }
    my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime(time);

    printf $log "               Wx Log for the Year %d\n", $year+1900;
    print $log  "$self->{stationDescription}\n\n";
    print $log  "                TH    Temp   Wind    Hi    Low    Hum   Dew   Wind                           Temp   Hum  
Date   Time   Index   Out   Chill   Temp   Temp   Out   Pt.  Speed   Hi   Dir  Rain   Bar     In     In 
----------------------------------------------------------------------------------------------------------\n";

    $log->close();
}

## 
## archiveCurImage
##
## Writes the periodic data samples to a file (arg)
##
sub archiveCurImage {
    my $self = shift;
#    my $file = shift;
    
    my $rain = sprintf("%1.2f", $self->{rainTotal});

    ## Note: I'm recording the min wind chill in the period, based on the
    ## max wind gust and the average temp in the period 
    my @log_data = ($self->{date}, 
		    $self->{time}, 
		    $self->{thi}, 
		    $self->{avgOutTemp},
		    $self->{windChillLo}, 
		    $self->{hiTemp}, 
		    $self->{loTemp}, 
		    $self->{outHum},
		    $self->{avgDewpoint}, 
		    $self->{avgWindSpeed}, 
		    $self->{windGust}, 
		    $self->{avgWindDir},
		    $self->{rainInPrd}, 
		    $self->{baro}, 
		    $self->{avgInTemp}, 
		    $self->{inHum});

    ##
    ## format of data lines in periodic samples log file
    ##
    format LOG =
@<<<<  @>>>>  @>>>>  @>>>> @>>>>>  @>>>>  @>>>>  @>>  @>>>>  @>>>  @>>>  @>>  @>>>>  @<<<<<  @>>>>  @>>
@log_data
.

    my $log = new FileHandle ">> $self->{archiveLogFile}";
    unless (defined $log) {
	carp "Could not open $self->{archiveLogFile}";
    }

    $log->format_name("LOG");
    #$log->format_top_name("LOG_TOP");

    write $log;
    $log->close;

}

################################################################################
# Weather Calculations (windchill, temp humidity index)
################################################################################
#
# New US/Can Wind Chill - 11/01/2001
#
#  temp in degrees F
#  speed in mph
#
sub windChill {
    my $self = shift;
    my $speed = shift;
    my $temp = shift;
    my $chill;

    if (($speed < 4) || ($temp > 50)) {
	$chill = $temp;
    } else {
	my $v016 = $speed ** 0.16;

	$chill = 35.74 + (0.6215 * $temp) - (35.75 * $v016) + 
	    (0.4275 * $temp * $v016);
    }
    return $chill;
}

# old windchill formula
sub oldWindChill {
    my $self = shift;
    my $speed = $self->{windSpeed};
    my $temp = $self->{outTemp};
    my $chill;
    my @chillTableOne = (156, 151, 146, 141, 133, 123, 110, 87, 61, 14, 0);
    my @chillTableTwo = (0, 16, 16, 16, 25, 33, 41, 74, 82, 152, 0);

    $speed = 50 if $speed > 50;

    my $index = int (10 - $speed/5);
    my $cf = $chillTableOne[$index] +
	($chillTableTwo[$index] / 16) * ($speed % 5);
    if ($temp < 91.4) {
	$chill = $cf * (($temp - 91.4) / 256) + $temp;
    } else {
	$chill = $temp;
    }
    return $chill;
}

sub calcDewPoint {
    my $self = shift;
    my $temp = $self->{avgOutTemp};
    my $rh = $self->{outHum};
    printf "rh=%d temp=%1.1f\n", $rh, $temp if $DEBUG > 0;
    my $tempc = (5.0/9.0)*($temp-32.0);
    my $es = 6.11 * 10.0 ** (7.5 * $tempc / (237.7 + $tempc));
    my $e = ($rh * $es) / 100.0;
    my $dewc = (-430.22 + 237.7 * log($e)) / (19.08 - log($e));
    my $dp = (9.0/5.0) * $dewc + 32;
    printf "tempc=%3.1f es=%4.2f e=%4.2f dewc=%3.1f\n",
    $tempc, $es, $e, $dewc if $DEBUG > 1;
    printf " dp=%3.1f\n", $dp if $DEBUG > 0;
    return $dp;
}

my @thiTable = 
    (
     [ 61, 63, 63, 64, 66, 66, 68, 68, 70, 70, 70], #  68
     [ 63, 64, 65, 65, 67, 67, 69, 69, 71, 71, 72], #  69
     [ 65, 65, 66, 66, 68, 68, 70, 70, 72, 72, 74], #  70
     [ 66, 66, 67, 67, 69, 69, 71, 71, 73, 73, 75], #  71
     [ 67, 67, 68, 69, 70, 71, 72, 72, 74, 74, 76], #  72
     [ 68, 68, 69, 71, 71, 73, 73, 74, 75, 75, 77], #  73
     [ 69, 69, 70, 72, 72, 74, 74, 76, 76, 76, 78], #  74
     [ 70, 71, 71, 73, 73, 75, 75, 77, 77, 78, 79], #  75
     [ 71, 72, 73, 74, 74, 76, 76, 78, 79, 80, 80], #  76
     [ 72, 73, 75, 75, 75, 77, 77, 79, 81, 81, 82], #  77
     [ 74, 74, 76, 76, 77, 78, 79, 80, 82, 83, 84], #  78
     [ 75, 75, 77, 77, 79, 79, 81, 81, 83, 85, 87], #  79
     [ 76, 76, 78, 78, 80, 80, 82, 83, 85, 87, 90], #  80
     [ 77, 77, 79, 79, 81, 81, 83, 85, 87, 89, 93], #  81
     [ 78, 78, 80, 80, 82, 83, 84, 87, 89, 92, 96], #  82
     [ 79, 79, 81, 81, 83, 85, 85, 89, 91, 95, 99], #  83
     [ 79, 80, 81, 82, 84, 86, 87, 91, 94, 98,103], #  84
     [ 80, 81, 81, 83, 85, 87, 89, 93, 97,101,108], #  85
     [ 81, 82, 82, 84, 86, 88, 91, 95, 99,104,113], #  86
     [ 82, 83, 83, 85, 87, 90, 93, 97,102,109,120], #  87
     [ 83, 84, 84, 86, 88, 92, 95, 99,105,114,131], #  88
     [ 84, 84, 85, 87, 90, 94, 97,102,109,120,144], #  89
     [ 84, 85, 86, 89, 92, 95, 99,105,113,128,150], #  90
     [ 84, 86, 87, 91, 93, 96,101,108,118,136,150], #  91
     [ 85, 87, 88, 92, 94, 98,104,112,124,144,150], #  92
     [ 86, 88, 89, 93, 96,100,107,116,130,150,150], #  93
     [ 87, 89, 90, 94, 98,102,110,120,137,150,150], #  94
     [ 88, 90, 91, 95, 99,104,113,124,144,150,150], #  95
     [ 89, 91, 93, 97,101,107,117,128,150,150,150], #  96
     [ 90, 92, 95, 99,103,110,121,132,150,150,150], #  97
     [ 90, 93, 96,100,105,113,125,150,150,150,150], #  98
     [ 90, 94, 97,101,107,116,129,150,150,150,150], #  99
     [ 91, 95, 98,103,110,119,133,150,150,150,150], # 100
     [ 92, 96, 99,105,112,122,137,150,150,150,150], # 101
     [ 93, 97,100,106,114,125,150,150,150,150,150], # 102
     [ 94, 98,102,107,117,128,150,150,150,150,150], # 103
     [ 95, 99,104,109,120,132,150,150,150,150,150], # 104
     [ 95,100,105,111,123,135,150,150,150,150,150], # 105
     [ 95,101,106,113,126,150,150,150,150,150,150], # 106
     [ 96,102,107,115,130,150,150,150,150,150,150], # 107
     [ 97,103,108,117,133,150,150,150,150,150,150], # 108
     [ 98,104,110,119,137,150,150,150,150,150,150], # 109
     [ 99,105,112,122,142,150,150,150,150,150,150], # 110
     [100,106,113,125,150,150,150,150,150,150,150], # 111
     [100,107,115,128,150,150,150,150,150,150,150], # 112
     [100,108,117,131,150,150,150,150,150,150,150], # 113
     [101,109,119,134,150,150,150,150,150,150,150], # 114
     [102,110,121,136,150,150,150,150,150,150,150], # 115
     [103,111,123,140,150,150,150,150,150,150,150], # 116
     [104,112,125,143,150,150,150,150,150,150,150], # 117
     [105,113,127,150,150,150,150,150,150,150,150], # 118
     [106,114,129,150,150,150,150,150,150,150,150], # 119
     [107,116,131,150,150,150,150,150,150,150,150], # 120
     [108,117,133,150,150,150,150,150,150,150,150], # 121
     [108,118,136,150,150,150,150,150,150,150,150]  # 122
     );

## Temperature Humidity Index
##
## Temp in degrees F
## Humidity is an integer from 0 to 100 inclusive
sub calcTHI {
    my $self = shift;
    my $temp = shift;
    my $hum = shift;

    my $loHumIdx = int $hum/10;
    my $hiHumIdx = ($loHumIdx == 10) ? 10 : $loHumIdx + 1;

    my $t = int $temp - 68;
    my $t_frac = $temp - $t - 68;

    my ($loTHI, $hiTHI, $lt_thi, $ht_thi, $thi);
    if ($t >= 0) {
	# low temp thi
	$loTHI = $thiTable[$t][$loHumIdx];
	$hiTHI = $thiTable[$t][$hiHumIdx];
	my $hifract = $hum - $loHumIdx * 10;
	my $lofract = 10 - $hifract;

	$lt_thi = ($loTHI * $lofract + $hiTHI * $hifract) / 10;

	# hi temp thi
	$loTHI = $thiTable[$t+1][$loHumIdx];
	$hiTHI = $thiTable[$t+1][$hiHumIdx];
	$hifract = $hum - $loHumIdx * 10;
	$lofract = 10 - $hifract;

	$ht_thi = ($loTHI * $lofract + $hiTHI * $hifract) / 10;

	$hifract = $t_frac;
	$lofract = 10 - $hifract;
	$thi = ($lt_thi * $lofract + $ht_thi * $hifract) / 10;

	return $thi;
    } else {
	return $temp;
    }
}

###############################################################################
##
##   Utility functions
##
###############################################################################

# Converts BCD format numbers to decimal numbers
sub bcd2dec {
    my $byteIn = shift;

    my $hexIn = unpack "H2", (pack "C", $byteIn);
    printf "hexIn=%s\n", $hexIn if ($DEBUG > 2);

    my @hex_in = split "", $hexIn;
    my $decOut = $hex_in[0]*10 + $hex_in[1];
    return $decOut;

}

sub tempConv {
    my $self = shift;
    my @t = @_;
    my $tn;

    my $ts = $t[1]*256 + $t[0];
    if ($ts > 32767) {
	$tn = ((~$ts & 0xFFFF) +1) * -1;
	return $tn/10;
    } else {
	return $ts/10;
    }
}

# used to retrieve the time and date of the min/max of a reading,
# eg. to get the time/date of the high outside temperature
sub readTimeDate {
    my $self = shift;
    my ($bankTime, $addrTime, $bankDate, $addrDate) = @_;

    my @str_in = $self->read("WRD", $bankTime, $addrTime, 4);
    return undef unless ($self->_valCheck(2, \@str_in));

    my $hour = &bcd2dec($str_in[0]);
    my $min = &bcd2dec($str_in[1]);
    @str_in = $self->read("WRD", $bankDate, $addrDate, 4);
    return undef unless ($self->_valCheck(2, \@str_in));
    my $day = &bcd2dec($str_in[0]);
    my $mon = $str_in[1] % 16;
    return ($hour, $min, $mon, $day);
}

sub whichYear {
    my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime(time);
    $year += 1900;
    return $year;
}

################################################################################
##   Low Level Calls 
##
## These perform the actual read/write accesses to the Davis Wx Station
##
################################################################################

sub read {
    my $self = shift;
    my ($cmd, $bank, $addr, $nibbles) = @_;
    my $bankNibble;

    $_ = $cmd;
  CASE: {
      /WRD/ and do {
	  $bankNibble = $nibbles * 16;
	  $bankNibble += ($bank) ? 4 : 2;
	  
	  printf "bankNibble=%x, addr=%x, cmd=%s\n", 
	    $bankNibble, $addr, $cmd if $DEBUG > 1;
	  $wxPort->write("WRD");
	  $wxPort->write(pack "C", $bankNibble);	# 4 nibles | bank 1
	  $wxPort->write(pack "C", $addr); # address
	  $wxPort->write(pack "C", 0xD);
	  $wxPort->write_done;
	  last CASE;
      };
      /RRD/ and do {
	  $wxPort->write("RRD");
	  $wxPort->write(pack "C", $bank);	# bank
	  $wxPort->write(pack "C", $addr); # address
	  $wxPort->write(pack "C", $nibbles-1);	# nibbles - 1
	  $wxPort->write(pack "C", 0xD);
	  $wxPort->write_done;
	  last CASE;
      };
  }
    if ($self->_get_ack()) {
	my @str_in = readData($nibbles/2);
	unless ($self->_valCheck($nibbles/2, \@str_in)) {
	    return undef;
	}
	return @str_in;
    } else {
	# print results
	my($BlockingFlags, $InBytes, $OutBytes, $ErrorFlags) = $wxPort->status;
	if ($DEBUG > 1) {
	    printf "OutBytes=%d\n",$OutBytes;
	    printf "InBytes=%d\n",$InBytes;
	}
	return undef;
    }
}


sub write {
    my $self = shift;
    my ($cmd, $bank, $addr, $nibbles, $data) = @_;
    my $nibbleBank;

    $_ = $cmd;
  CASE: {
      /WWR/ and do {
	  $nibbleBank = $nibbles * 16 + 2 * $bank + 1;
	  $wxPort->write("WWR");
	  # 4 nibles | bank 0=1 for writes
	  $wxPort->write(pack "C", $nibbleBank);
	  $wxPort->write(pack "C", $addr); # address
	  $wxPort->write(pack "S", $data);
	  $wxPort->write(pack "C", 0xD);
	  $wxPort->write_done;
	  last CASE;
      };
      /RWR/ and do {
	  my $bankNibble = $bank * 16 + $nibbles;
	  $wxPort->write("RWR"); 
	  $wxPort->write(pack "C", $bankNibble);	# bank|nibble
	  $wxPort->write(pack "C", $addr); # address
	  $wxPort->write(pack "S", $data);	# data
	  $wxPort->write(pack "C", 0xD);
	  $wxPort->write_done;
	  last CASE;
      };
  }
    unless ($self->_get_ack()) {
	print "write failed\n" if $DEBUG > 0;
	return 0;
    }
    return 1;
}

sub readData {
    my $bytes = shift;

    my ($count, $string_in) = $wxPort->read($bytes);
    unless ($count == $bytes) {
	carp "readData: read unsuccessful\n" if $DEBUG > 0;
	return undef;
    }
    my $packStr = "C" . $bytes;
    return (unpack $packStr, $string_in);
}

sub _get_ack {
    my $self = shift;
    my $j=0;

    ## uses blocking read()
    my ($count, $gotit) = $wxPort->read(1);
    
    if ($count == 0) {
	carp "No data read\n" if $DEBUG > 0;
	printf "read cound is %d\n", $count
	    if ($DEBUG > 1);
	return 0;
    }

    my $readChar = unpack "C", $gotit;
    if ($readChar == 33) {
	carp "Got a Neg Ack\n" if $DEBUG > 0;
	printf "readChar=%d..%s.. j=%d\n",$readChar,$readChar, $j
	    if $DEBUG > 1;
	return 0;
    } elsif ($readChar == 24) {
	carp "Command not understood\n" if $DEBUG > 0;
	printf "readChar=%d..%s.. j=%d\n",$readChar,$readChar, $j
	    if $DEBUG > 1;
	return 0;
    } elsif ($readChar == 6) {
	# Ack received
	return 1;
    } else {
	carp "Didn't match the expected return value\n" if $DEBUG > 0;
	printf "readChar=%d..%s.. j=%d\n",$readChar,$readChar, $j
	    if $DEBUG > 1;
	return 0;
    }
}

sub _valCheck {
    my $self = shift;
    my $len = shift;
    my $array = shift;

    if ($len != scalar @$array) {
	return 0;
    }
    my $i = 0;
    while ($i < $len) {
	unless (defined $$array[$i++]) {
	    return 0;
	}
    }
    return 1;
}

1;
