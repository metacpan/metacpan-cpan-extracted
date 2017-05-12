package Joystick;

use Win32::API;
use Carp;
use strict;
require Exporter;

use vars qw(@ISA @EXPORT @EXPORT_OK @EXPORT_TAGS $_joyGetDevCaps $_joyGetNumDevs $joyGetPos
            $_joyGetPos @_LPINFO @_LPCAPS $N $P $VERSION);
$VERSION = '1.01';

@ISA = qw(Exporter Win32::API);

@EXPORT = qw();
@EXPORT_OK = qw(joyGetNumDevs);
@EXPORT_TAGS = qw();

#Win32 joy data structs
	my ($N, $P) = qw(N P);
	my @_LPINFO = (0,0,0,0);
    	my @_LPCAPS;
      my $LPINFOPACK = "LLLL";
     	my $LPCAPSPACK = "ssA28L20a30sa13"; #data structure needed for windows API call

#the Win32 API definitions
	my $_joyGetDevCaps = new Win32::API("winmm", "joyGetDevCaps", [$N,$P,$N], $N);
	my $_joyGetNumDevs = new Win32::API("winmm", "joyGetNumDevs", [], $N);
	my $_joyGetPos = new Win32::API("winmm", "joyGetPos", [$N,$P], $N);
      my $_joyGetPosEx = new Win32::API("winmm", "joyGetPosEx", [$N,$P], $N);

sub new{
   my $proto = shift;
   my $class = ref($proto) || $proto;
   my $self = {};
   
   if (@_){
   	$self->{DEV} = shift;
   }else{
    carp "Using default device 0 ...\n";
   	$self->{DEV} = 0;
   }
   
   bless $self, $class;
   $self->joyGetDevCaps;

   if ($self->joyGetPos eq "N"){
	return 0;
   }else{
        return $self;
   }

}
   

sub joyGetPos{
   my $self = shift;
   my $_LPINFO = pack "$LPINFOPACK",@_LPINFO;
   my $retval;

   $retval = $_joyGetPos->Call($self->{DEV},$_LPINFO);
   
   if ($retval == 0){
       return unpack "$LPINFOPACK", $_LPINFO;
   }else{
       return "N";
   }
   
} 

sub joyGetNumDevs{
	return $_joyGetNumDevs->Call;
}


sub joyGetDevCaps{
	my $self = shift;
	my $_LPCAPS = pack $LPCAPSPACK,@_LPCAPS;
	$_joyGetDevCaps->Call($self->{DEV}, $_LPCAPS, length $_LPCAPS);

	my ($mid, $pid, $driver, $junk, $xmin, $xmax, $ymin, $ymax,
       $zmin, $zmax, $numbuttons, $periodmin, $periodmax, $rmin,
       $rmax, $umin, $umax, $vmin, $vmax, $junk, $maxaxes, 
       $numaxes, $maxbuttons, $regkey, $junk, $oemvxd, @junk)
       = unpack $LPCAPSPACK, $_LPCAPS; 

   	$self->{MID} = $mid;
   	$self->{PID} = $pid;
	$self->{DRIVER} = $driver;
	$self->{XMIN} = $xmin;
	$self->{XMAX} = $xmax;
	$self->{XCENT} = $xmax/2;
	$self->{YMIN} = $ymin;
	$self->{YMAX} = $ymax;
	$self->{YCENT} = $ymax/2;
	$self->{ZMIN} = $zmin;
	$self->{ZMAX} = $zmax;
	$self->{ZCENT} = $zmax/2;
	$self->{NUMBUTTONS} = $numbuttons;
	$self->{PERIODMIN} = $periodmin;
	$self->{PERIODMAX} = $periodmax;
	$self->{RMIN} = $rmin;
	$self->{RCENT} = $rmax/2;
	$self->{RMAX} = $rmax;
	$self->{UMIN} = $umin;
	$self->{UCENT} = $umax/2;
	$self->{UMAX} = $umax;
	$self->{VMIN} = $vmin;
	$self->{VCENT} = $vmax/2;
	$self->{VMAX} = $vmax;
	$self->{MAXAXES} = $maxaxes;
	$self->{NUMAXES} = $numaxes;
	$self->{MAXBUTTONS} = $maxbuttons;
	$self->{REGKEY} = $regkey;
	$self->{OEMVXD} = $oemvxd;

}


__END__


=pod

=head2 DESCRIPTION

	Joystick allows input from game control devices.  Currently, Joystick has only been
	developed for Win32API.

=head2 REQUIRMENTS
	
	To use Joystick you must have the Win32::API package installed.

=head2 SYNOPSIS

	use Win32API::Joystick;
	
	#returns number of POSSIBLE joystick devices in Windows
	$number_of_joysticks = Joystick::joyGetNumDevs; 
   	
	#create joystick object
	$my_joystick = Joystick->new(0): 	#joystick devices start at zero 
	
	#many attributes can be retrieved (see EXPLANATION).
	print "x axis max is $my_joystick->{XMAX}\n";
	
	#returns position of x,y,z axes and button status
	($x, $y, $z, $button) =$my_joy->joyGetPos;  

=head2 CONSTRUCTOR

	The constructor takes the device number of the game controller you wish to use, returns a
	blessed reference if joystick is connected and working, and 0 if not. Device numbers for
	windows joysticks start at 0. You can determine how many game controllers windows has
	listed in the control panel by calling WinJoy::joyGetNumDevs.  This returns the number of
	devices LISTED, not the number that are connected and working.  The constructor does not
	throw an exception when the object cannot be created since often you may encounter
	joysticks listed in windows that aren't there or don't work.

=head2 EXPLANATION

=head4 	ATTRIBUTES

	When the Joystick object is created, several attributes are extracted from the device's
	configuration in windows.  They can be accessed this way:

	$my_joystick_object->{ATTRIBUTE}

	General information on joystick:
	NUMBUTTONS MAXBUTTONS NUMAXES MAXAXES

	x,y,z,r,u,and v axes minimum and maximum values:
	XMIN XMAX YMIN YMAX ZMIN ZMAX RMIN RMAX UMIN UMAX VMIN VMAX

	Axes center values (if the axes exists):
	XCENT YCENT ZCENT RCENT UCENT VCENT
	
	Windows driver information:
	DRIVER REGKEY OEMVXD

=head4	GETTING POSITION

	The method joyGetPos returns four things.  The first three are x,y, and z positions. The
	fourth is the button status.  The single number for the button status is a sum of values
	for all the buttons that are being depressed.  This is how it is calculated:
	
	button1 = 1
	button2 = 2
	button3 = 4
	button4 = 8
	button5 = 16
	...

	So, if buttons 1 and 3 were being depressed at the same time, the button status would be
	5.

=head2 BUGS

	The windows API call that returns the position of the joystick axes will only return
	x, y, and z values.  In the case that you have a joystick that has more than x,y, and z
	(r,u, and v) you will not be able to read those values. (There is an extended joystick
      info that may be implimented in the future)

=head2 TODO

	Create a Joystick module for use with Device under Unix/Linux.  Add capability to get
      extended joystick info, such as POV positions, and axes on sticks with more than 3 axes.

=head2 AUTHOR

	Ben Lilley bdlilley@cpan.org

=head2 COPYRIGHT

	(C) Copyright 2000, Ben Lilley all rights reserverd
	This module may freely distributed in accordance with the artistic license.

=cut


	