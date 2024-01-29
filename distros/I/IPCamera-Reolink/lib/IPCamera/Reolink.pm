package IPCamera::Reolink;
#ABSTRACT: HTTP(S)/REST interface to Reolink IP Cameras and NVRs per Reolink document "Camera HTTP API User Guide Version 8 2023-4"

use 5.006;
use strict;
use warnings;

use REST::Client;
use JSON;
use Data::Dump;
use Time::HiRes;

# IPCamera::Reolink channel values.
use constant ChannelDefault => 0;

# IPCamera::Reolink::PtzCtrl() op value.
use constant PTZ_Auto => 'Auto';
use constant PTZ_Down => 'Down';
use constant PTZ_Left => 'Left';
use constant PTZ_LeftDown => 'LeftDown';
use constant PTZ_LeftUp => 'LeftUp';
use constant PTZ_Right => 'Right';
use constant PTZ_RightDown => 'RightDown';
use constant PTZ_RightUp => 'RightUp';
use constant PTZ_Stop => 'Stop';
use constant PTZ_Up => 'Up';
use constant PTZ_ZoomInc => 'ZoomInc';
use constant PTZ_ZoomDec => 'ZoomDec';
use constant PTZ_IrisDec => 'IrisDec'; # Iris shrink in the specified speed.
use constant PTZ_IrisInc => 'IrisInc'; # Iris enlarge in the specified speed.
use constant PTZ_FocusDec => 'FocusDec'; # Focus backwards in the specified speed.
use constant PTZ_FocusInc => 'FocusInc'; # Focus forwards in the specified speed.
use constant PTZ_StartPatrol => 'StartPatrol'; # PTZ patrol in the specified speed.
use constant PTZ_StopPatrol => 'StopPatrol'; # PTZ stop patrol.
use constant PTZ_ToPos => 'ToPos'; # PTZ turn to a specified preset in the specified speed.

# IPCamera::Reolink::PtzCtrl() speed values.
use constant PTZ_SpeedMin => 1;
use constant PTZ_SpeedMax => 64;
use constant PTZ_SpeedHalf => 32;

# IPCamera::Reolink::StartZoomFocus() op values.
use constant ZF_ZoomPos => 'ZoomPos'; # set camera zoom to specified value

# IPCamera::Reolink::StartZoomFocus() op ZoomPos pos values.
use constant ZF_ZoomPosMin => 0;
use constant ZF_ZoomPosMax => 32;

# IPCamera::Reolink::StartZoomFocus() FocusPos op values.
use constant ZF_FocusPos => 'FocusPos'; # set camera focus to specified value

# IPCamera::Reolink::StartZoomFocus() op FocusPos pos values.
use constant ZF_FocusPosMin => 0;
use constant ZF_FocusPosMax => 248;

# IPCamera::Reolink:SetOsd pos values
use constant OSD_UpperLeft  => "Upper Left";
use constant OSD_TopCenter  => "Top Center";
use constant OSD_UpperRight  => "Upper Right";
use constant OSD_LowerLeft  => "Lower Left";
use constant OSD_BottomCenter  => "Bottom Center";
use constant OSD_LowerRight  => "Lower Right";
use constant OSD_OtherConfiguration  => "Other Configuration";


our $VERSION = '1.01';

our $DEBUG = 0; # > 0 for debug output to STDERR

sub new {
    my $class = shift;
    my $self = bless({}, $class);
    my($camera_url, $camera_user_name, $camera_password) = @_;
    $self->{CAMERA_URL} = $camera_url;
    $self->{CAMERA_USER_NAME} = $camera_user_name;
    $self->{CAMERA_PASSWORD} = $camera_password;
    $self->{_camera_rest_client} = undef; # defer REST connection to camera until first Login()
    $self->{_camera_login_token} = undef;  # pass to other API functions
    $self->{_camera_login_lease_time} = 0; # time in seconds that the login token is valid, force initial Login()
    $self->{_camera_login_lease_start_time} = time(); # time that the login token was acquired, force initial Login()
    return $self;
} # new()

# _sendCameraCommand() - send command to camera and return response
sub _sendCameraCommand($$$$){
    my($camera_rest_client, $camera_command, $request_r, $token) = @_;

    my $t1 = Time::HiRes::time() if($DEBUG > 0);
    print STDERR "$0: sendCameraCommand(): " . $t1 . ": enter: call JSON::encode_json()\n" if($DEBUG > 1);

    my $encoded_request = JSON::encode_json($request_r);

    my $t2 = Time::HiRes::time() if($DEBUG > 1);
    print STDERR "$0: sendCameraCommand(): " . $t2 . ": call POST()\n" if($DEBUG > 1);

    if(defined($token)){
        $camera_rest_client->POST('api.cgi?cmd=' . $camera_command . '&token=' . $token, $encoded_request);
    }else{
        # $token undefined for Login
        $camera_rest_client->POST('api.cgi?cmd=' . $camera_command, $encoded_request);
    } # if

    my $t3 = Time::HiRes::time() if($DEBUG > 1);
    print STDERR "$0: sendCameraCommand(): " . $t3 . ": call responseCode()\n" if($DEBUG > 1);

    my $response_code = $camera_rest_client->responseCode();

    my $t4 = Time::HiRes::time() if($DEBUG > 1);
    print STDERR "$0: sendCameraCommand(): " . $t4 . ": call responseContent()\n" if($DEBUG > 1);

    my $response_content = $camera_rest_client->responseContent(); # JSON

    my $t5 = Time::HiRes::time() if($DEBUG > 1);
    print STDERR "$0: sendCameraCommand(): " . $t5 . ": call JSON::decode_json()\n" if($DEBUG > 1);

    my $response_r = JSON::decode_json($response_content);

    my $t6 = Time::HiRes::time() if($DEBUG > 1);
    print STDERR "$0: sendCameraCommand(): " . $t5 . ": exit:()\n" if($DEBUG > 1);
    my $t7 = Time::HiRes::time() if($DEBUG > 0);
    print STDERR "$0: sendCameraCommand(): JSON encode " . ($t2 - $t1) . " POST " . ($t3 - $t2) . " responseCode " . ($t4 - $t3) . " responseContent " . ($t5 - $t4) . " JSON decode " . ($t6 - $t5) . " TOTAL " . ($t7 - $t1) . "\n" if($DEBUG > 1);
    if($DEBUG > 0){
        if($DEBUG > 1){
            my @headers = $camera_rest_client->responseHeaders();
            foreach my $header (@headers){
                print STDERR scalar(localtime()) . ": debug: IPCamera::Reolink::_sendCameraCommand(): header '" . $header . "' '" . $camera_rest_client->responseHeader($header) . "' \n";
            } # for
        } # if
        my $save_linewidth = $Data::Dump::LINEWIDTH;
        $Data::Dump::LINEWIDTH = 500; # no linebreak
        print STDERR scalar(localtime()) . ": debug: IPCamera::Reolink::_sendCameraCommand(): command '" . $camera_command . "' token '" . (defined($token) ? $token : 'undef') . "' request '" . Data::Dump::dump($request_r) . "' response '" . Data::Dump::dump($response_r) . "' time " . ($t7 - $t1) . " seconds\n";
        $Data::Dump::LINEWIDTH = $save_linewidth; 
    } # if

    my $code = @$response_r[0]->{code};
    if($response_code ne '200' || $code != 0){
        return undef;
    }else{
        return $response_r;
    } # if
} # _sendCameraCommand()

# _checkLoginLeaseTime() - determine if camera Login lease for Login token has expired and reacquire on expiry
sub _checkLoginLeaseTime($){
    my($self) = @_;
    my $now = time();
    my($_camera_login_lease_time, $_camera_login_lease_start_time) = ($self->{_camera_login_lease_time}, $self->{_camera_login_lease_start_time});
    if($now >= $_camera_login_lease_start_time + $_camera_login_lease_time){
        # Perhaps re-establish the REST connection as long intervals with no activity seem to make the camera "forget" the connection. @@@
        my($login_token, $login_lease_time) = Login();
        if(defined($login_token)){
            print STDERR "$0: " . scalar(localtime()) . ": info: Camera Login for user '" . $self->{CAMERA_USER_NAME} . "' OK, token leaseTime '" . $login_lease_time . "' name '" . $login_token . "'\n" if($DEBUG > 0);
            $self->{_camera_login_lease_start_time} = $now; # New Login token lease time
            $self->{_camera_login_lease_time} = $login_lease_time; # New Login token 
            return 1; # new Login token
        }else{
            print STDERR "$0: " . scalar(localtime()) . ": error: Camera Login for user '" . $self->{CAMERA_USER_NAME}  . "' failed\n" if($DEBUG > 0);
            return 0; # failed to acquire new Login token
        } # if
    }else{
        return 1; # Login token still valid
    } # if
} # _checkLoginLeaseTime()

# Login() - provides login credentials (username/password) to camera and returns API access token good for specified number of seconds
sub Login(){
    my($self) = @_;
    my($_camera_rest_client, $camera_url, $camera_user_name, $camera_password) = ($self->{_camera_rest_client}, $self->{CAMERA_URL}, $self->{CAMERA_USER_NAME}, $self->{CAMERA_PASSWORD});
    if(!defined($_camera_rest_client)){
        $_camera_rest_client = REST::Client->new(host => $camera_url, timeout => 10, );
        $self->{_camera_rest_client} = $_camera_rest_client;
    } # if
    my $login_r = [ {cmd => "Login", param => { User => { Version => "0", userName => $camera_user_name, password => $camera_password, }}} ];
    my $response_r = _sendCameraCommand($_camera_rest_client, 'Login', $login_r, undef);
    if(defined($response_r)){
        $self->{_camera_login_token} =  @$response_r[0]->{value}->{Token}->{name};
        $self->{_camera_login_lease_time} = @$response_r[0]->{value}->{Token}->{leaseTime};
        $self->{_camera_login_lease_start_time} = time(); # detect lease expiry 
        return ($self->{_camera_login_token}, $self->{_camera_login_lease_time}); 
    }else{
        return (undef, undef);
    } # if
} # Login()

# Logout() - release login credentials from previous Login()
sub Logout(){
    my($self) = @_;
    my($_camera_rest_client, $_camera_login_token) = ($self->{_camera_rest_client}, $self->{_camera_login_token});
    if(defined($_camera_rest_client)){
		$self->{_camera_login_token} = undef;
		$self->{_camera_login_lease_time} = 0;
		$self->{_camera_login_lease_start_time} = time();
	}else{
        # No Login()
		return 0;
    } # if
    my $logout_r = [ {cmd => "Logout", param => { }} ];
    my $response_r = _sendCameraCommand($_camera_rest_client, 'Logout', $logout_r, $_camera_login_token);
    if(defined($response_r)){
        return 1; 
    }else{
        return 0;
    } # if
} # Logout()

# GetDevInfo() - implement camera API GetDevInfo interface.
sub GetDevInfo($){
    my($self) = @_;
    if(!_checkLoginLeaseTime($self)){
        return undef;
    } # if
    my $get_dev_info_r = [ {cmd => "GetDevInfo", } ];
    my($_camera_rest_client, $_camera_login_token) = ($self->{_camera_rest_client}, $self->{_camera_login_token});
    my $response_r = _sendCameraCommand($_camera_rest_client, 'GetDevInfo', $get_dev_info_r, $_camera_login_token);
    if(defined($response_r)){
        return @$response_r[0]->{value}->{DevInfo};
    }else{
        return undef;
    } # if
} # GetDevInfo()

# PtzCtrl() - implement camera API PtzCtrl interface, used to control the operation of PTZ (Pan/Tilt/Zoom).
sub PtzCtrl($$$){
    my($self, $channel, $op, $speed) = @_;
    if(!_checkLoginLeaseTime($self)){
        return 0;
    } # if
    my($_camera_rest_client, $_camera_login_token) = ($self->{_camera_rest_client}, $self->{_camera_login_token});
    # speed : 1 (lent) -> 64 (rapide)
    my $ptzctrl_r;
	if($op eq PTZ_Stop){
		# No 'speed' field for op PTZ_Stop
		$ptzctrl_r = [ {cmd => "PtzCtrl", action => 0, param => { channel => $channel, op => $op, }}];
	}else{
		$ptzctrl_r = [ {cmd => "PtzCtrl", action => 0, param => { channel => $channel, speed => int($speed), op => $op, }}]; # the int($speed) is important otherwise the field could be encoded as a real which will be rejected by the camera
	} # if
    my $response_r = _sendCameraCommand($_camera_rest_client, 'PtzCtrl', $ptzctrl_r, $_camera_login_token);
    if(defined($response_r)){
        return 1;
    }else{
        return 0;
    } # if
} # PtzCtrl()

# GetZoomFocus() - implement camera API GetZoomFocus interface, used to get the current Zoom and Focus values.
sub GetZoomFocus($){
    my($self, $channel) = @_;
    if(!_checkLoginLeaseTime($self)){
        return 0;
    } # if
    my($_camera_rest_client, $_camera_login_token) = ($self->{_camera_rest_client}, $self->{_camera_login_token});
    my $getzoomfocus_r = [ {cmd => "GetZoomFocus", action => 0, param => { channel => $channel, }} ];
    my $response_r = _sendCameraCommand($_camera_rest_client, 'GetZoomFocus', $getzoomfocus_r, $_camera_login_token);
    if(defined($response_r)){
        return @$response_r[0]->{value}->{ZoomFocus};
    }else{
        return undef;
    } # if
} # GetZoomFocus()

# StartZoomFocus() - implement camera API StartZoomFocus interface, used to set the Zoom and Focus to specified values.
sub StartZoomFocus($$$){
    my($self, $channel, $op, $pos) = @_;
    if(!_checkLoginLeaseTime($self)){
        return 0;
    } # if
    my($_camera_rest_client, $_camera_login_token) = ($self->{_camera_rest_client}, $self->{_camera_login_token});
    my $startzoomfocus_r = [ {cmd => "StartZoomFocus", action => 0, param => {"ZoomFocus" => { channel => $channel, pos => int($pos), op => $op, }}} ];
    my $response_r = _sendCameraCommand($_camera_rest_client, 'StartZoomFocus', $startzoomfocus_r, $_camera_login_token);
    if(defined($response_r)){
        return 1;
    }else{
        return 0;
    } # if
} # StartZoomFocus()

# GetOsd() - implement camera API GetOsd interface, used to get the On Screen Display (OSD) values.
sub GetOsd($){
    my($self, $channel) = @_;
    if(!_checkLoginLeaseTime($self)){
        return 0;
    } # if
    my($_camera_rest_client, $_camera_login_token) = ($self->{_camera_rest_client}, $self->{_camera_login_token});
    my $getosd_r = [ {cmd => "GetOsd", action => 1, param => { channel => $channel, }} ];
    my $response_r = _sendCameraCommand($_camera_rest_client, 'GetOsd', $getosd_r, $_camera_login_token);
    if(defined($response_r)){
        return (@$response_r[0]->{value}, @$response_r[0]->{range}, @$response_r[0]->{initial}, );
    }else{
        return undef;
    } # if
} # GetOsd()

# SetOsd() - implement camera API SetOsd interface, used to set the On Screen Display (OSD) values.
sub SetOsd($$$$$$){
    my($self, $channel, $enableChannel, $channelName, $channelPos, $enableTime, $timePos) = @_;
    if(!_checkLoginLeaseTime($self)){
        return 0;
    } # if
    my($_camera_rest_client, $_camera_login_token) = ($self->{_camera_rest_client}, $self->{_camera_login_token});
    my $setosd_r = [ {cmd => "SetOsd", param => { Osd => { channel => $channel, osdChannel => { enable => int($enableChannel), name => $channelName, pos => $channelPos, }, osdTime => {enable => int($enableTime), pos => $timePos, }}}} ];
    my $response_r = _sendCameraCommand($_camera_rest_client, 'SetOsd', $setosd_r, $_camera_login_token);
    if(defined($response_r)){
        return 1;
    }else{
        return 0;
    } # if
} # SetOsd()

=pod

=encoding UTF-8

=head1 NAME

IPCamera::Reolink - Reolink API provides access to the System, Security, Network, Video input, Enc, Record, PTZ, and Alarm functions of a Reolink IP Camera or NVR via HTTP(S)/REST

=head1 VERSION

1.00

=head1 SYNOPSIS

 use IPCamera::Reolink;

 my $camera_url = "http://192.168.1.160";
 my $camera_user_name =  "vlc"; # non-admin user recommended
 my $camera_password = 'this-is-a-bad-password';

 my $camera = IPCamera::Reolink->new($camera_url, $camera_user_name, $camera_password);

 # Optionally Login to the camera immmediately to validate the camera URL and credentials, otherwise a Login will be implicitly performed by the API on the first camera command.

 die "IPCamera::Reolink::Login failed" if(!$camera->Login());

 # Some camera info

 my $devinfo_r = $camera->GetDevInfo();
 print "Camera model : " . $devinfo_r->{model} . "\n";
 print "Camera name : " . $devinfo_r->{name} . "\n";

 # Start a camera pan to the left.

 $camera->PtzCtrl(IPCamera::Reolink::ChannelDefault, IPCamera::Reolink::PTZ_Left, IPCamera::Reolink::PTZ_SpeedMax);

 # Times passes, stop the last camera PTZ function.

 $camera->PtzCtrl(IPCamera::Reolink::ChannelDefault, IPCamera::Reolink::PTZ_Stop, IPCamera::Reolink::PTZ_SpeedMin);

 $camera->Logout();

=head1 DESCRIPTION

IPCamera::Reolink provides a simple way to interact with Reolink IP cameras and NVRs.

Based on the "Reolink Camera API User Guide_V8 (Updated in April 2023)" document, available here:

https://github.com/mnpg/Reolink_api_documentations


As the author is primarily interested in accessing the Pan/Tilt/Zoom (PTZ) functions of his Reolink RLC-823A-16x IP camera,
only the subset of functions described in the above document needed to access these features have been implemented.

Other functions may be added in the future based on the need/whims of the author and requests from other (if any) users of this module.

=head1 ATTRIBUTES

=head2 DEBUG

Set I<$IPCamera::Reolink::DEBUG> to a value > 0 for increasingly detailed debug output to STDERR.

default is 0 for no debug output.

=head2 VERSION

I<$IPCamera::Reolink::VERSION> is the version of this module.

=head1 METHODS

=head2 new($camera_url, $camera_user_name, $camera_password)

Construct a new IPCamera::Reolink object.

Takes the following manditory parameters:

=over 4

=item $camera_host_url

The camera URL for access via HTTP(S), i.e. "http://192.168.1.123".

=item $camera_user_name

The camera account name for access via HTTP(S), i.e. "vlc". 

You should set up a non admin acccount for access via this API, the admin account will work as well but is not recommended.

But just to complicate things, certain methods (described below) require admin access to use with the current version of the camera firmware.

Reolink may fix this in the future.

=item $camera_password

The camera account password for access via HTTP(S), i.e. "this-is-a-bad-password". 

=back

=head2 Login()

Login to the camera using the credentials provided to new() (above).

Upon successful Login the camera passes back a Login token and lease time that is used internally by other IPCamera::Reolink camera API methods.

The token is valid for the specified lease time.

IPCamera::Reolink will manage the Login token and will call Login() internally as needed when the Login token expires.

This should all be invisible to the caller.

=over 4

=item return

Returns (undef, udef) if the Login was rejected by the camera.

Returns ($camera_login_token, $camera_login_lease_time) if the Login is successful,
where $camera_login_token is the token passed to other API methods and $camera_login_lease_time is the time in seconds for which the token is valid, after which a new token must be aquired.

Usually the caller is not interested in these values as they are used internally by IPCamera::Reolink.

=back

=head2 Logout()

Release Login() credentials.

=over 4

=item return

Returns 1 if Logout() succeeded else 0 (zero) on failure, typically if Login() not called.

=back

=head2 GetDevInfo()

Return useful information about the camera.

=over 4

=item return

Returns undef if the GetDevInfo function failed.

Returns $devinfo_r hash reference to device information if successful, fields most likely subject to change (typical values in parenthesis):

=over 4

=item $devinfo_r->{audioNum} (1)

The number of audio channels.

=item $devinfo_r->{B485} (0)

0: no 485, 1: have 485

=item $devinfo_r->{buildDay} ("build 23061923")

The establish date.

=item $devinfo_r->{cfgVer} ("v3.1.0.0")

The version number of configuration information.

=item $devinfo_r->{channelNum} (1)

The number of channels.

=item $devinfo_r->{detail} ("IPC_523SD10S16E1W01100000001")

The details of device information.

=item $devinfo_r->{diskNum} (1)

The number of USB disk or SD card.

=item $devinfo_r->{exactType} ("IPC")

Product type.

=item $devinfo_r->{firmVer} ("v3.1.0.2347_23061923_v1.0.0.93")

The version number of the firmware.

=item $devinfo_r->{frameworkVer} (1)

Architecture version.

=item $devinfo_r->{hardVer} ("IPC_523SD10")

The version number of the hardware.

=item $devinfo_r->{IOInputNum} (0)

The number of IO input port.

=item $devinfo_r->{IOOutputNum} (0)

The number of IO output port.

=item $devinfo_r->{model} ("RLC-823A 16X")

Camera/NVR model.

=item $devinfo_r->{name} ("rlc-823a-16x")

Device name.

=item $devinfo_r->{pakSuffix} ("pak,paks")

?

=item $devinfo_r->{serial} ("00000000000000")

?

=item $devinfo_r->{type} ("IPC")

Device type.

=item $devinfo_r->{wifi} (0)

0: no WIFI, 1: have WIFI.

=back

=back

=head2 PtzCtrl($camera_channel, $camera_operation, $camera_operation_speed)

Control camera PTZ functions.

Upon successful return the camera asynchronously executes the requested operation until another operation is specified by PtzCtrl() or until the camera limit is reached for the specified operation, for example the camera has tilted as far Down as physically possible.

Some operations like IPCamera::Reolink::PTZ_Left will execute forever until another PtzCtrl command is executed.

=over 4

=item $camera_channel

Perform camera operation on specified camera channel:

=over 4

=item IPCamera::Reolink::ChannelDefault 

If you are connected to a camera then there is (usually) only 1 channel.

=item integer >= 0

If you are connected to an NVR then there is usually one channel per attached camera starting at integer value 0.

=back

=item $camera_operation 

Camera operation to perform:

=over 4

=item IPCamera::Reolink::PTZ_Stop 

PTZ stop turning.

=item IPCamera::Reolink::PTZ_Left 

PTZ turn left at the specified speed.

=item IPCamera::Reolink::PTZ_Right 

PTZ turn right at the specified speed.

=item IPCamera::Reolink::PTZ_Up 

PTZ turn up in the specified speed.

=item IPCamera::Reolink::PTZ_Down 

PTZ turn down at the specified speed.

=item IPCamera::Reolink::PTZ_LeftUp 

PTZ turn left-up at the specified speed.

=item IPCamera::Reolink::PTZ_LeftDown 

PTZ turn left-down at the specified speed.

=item IPCamera::Reolink::PTZ_RightUp 

PTZ turn right-up at the specified speed.

=item IPCamera::Reolink::PTZ_RightDown 

PTZ turn right-down at the specified speed.

=item IPCamera::Reolink::PTZ_IrisDec 

Iris shrink at the specified speed.

=item IPCamera::Reolink::PTZ_IrisInc 

Iris enlarge at the specified speed.

=item IPCamera::Reolink::PTZ_ZoomDec 

Zoom in at the specified speed.

=item IPCamera::Reolink::PTZ_ZoomInc 

Zoom out at the specified speed.

=item IPCamera::Reolink::PTZ_FocusDec 

Focus backwards at the specified speed.

=item IPCamera::Reolink::PTZ_FocusInc 

Focus forwards at the specified speed.

=item IPCamera::Reolink::PTZ_Auto 

PTZ turn auto at the specified speed.

=item IPCamera::Reolink::PTZ_StartPatrol 

PTZ patrol at the specified speed.

=item IPCamera::Reolink::PTZ_StopPatrol 

PTZ stop patrol.

=item IPCamera::Reolink::PTZ_ToPos 

PTZ turn to at specified preset at the specified speed.

=back

=item $camera_operation_speed 

Perform camera operation at the specified speed:

=over 4

=item IPCamera::Reolink::PTZ_SpeedMin 

Minimum camera operation speed.

=item PTZ_SpeedMin::PTZ_SpeedMax

Maximum camera operation speed.

=item PTZ_SpeedMin::PTZ_SpeedHalf

1/2 Maximum camera operation speed.

=back

=back

=head2 GetZoomFocus($camera_channel)

Return camera current Zoom and Focus values.

=over 4

=item $camera_channel 

Perform camera operation on specified camera channel:

=over 4

=item IPCamera::Reolink::ChannelDefault 

If you are connected to a camera then there is (usually) only 1 channel.

=item integer >= 0

If you are connected to an NVR then there is usually one channel per attached camera starting at integer value 0.

=back

=item return

Returns undef if the GetZoomFocus function failed.

Returns $zoom_focus_r hash reference to Zoom/Focus information if successful, fields most likely subject to change (typical values in parenthesis):

=over 4

=item $zoom_focus_r->{channel} (0)

Camera channel.

=item $zoom_focus_r->{focus}->{pos} (23)

Current camera focus value in the range IPCamera::Reolink::ZF_FocusPosMin, IPCamera::Reolink::ZF_FocusPosMax.

=item $zoom_focus_r->{zoom}->{pos} (0)

Current camera zoom value in the range IPCamera::Reolink::ZF_ZoomPosMin, IPCamera::Reolink::ZF_ZoomPosMax.

=back

=back

=head2 StartZoomFocus($camera_channel, $camera_operation, $camera_zoom_pos|$camera_focus_pos)

Set camera current Zoom or Focus value.

Note that the current version of the firmware on the authors camera (Firmware Version v3.1.0.2347_23061923_v1.0.0.93) requires a Login() using admin credentials to use this function.
According to Reolink this may be fixed in a future firmware version.

If in doubt, set $DEBUG to 1 and if you see a log message of the form:

Tue Dec 19 18:17:07 2023: debug: IPCamera::Reolink::_sendCameraCommand(): command 'StartZoomFocus' token '5b34aab0bb481ba' request '[{ action => 0, cmd => "StartZoomFocus", param => { ZoomFocus => { channel => 0, op => "ZoomPos", pos => 1 } } }]' response '[{ cmd => "StartZoomFocus", code => 1, error => { detail => "ability error", rspCode => -26 } }]' time 0.0480499267578125 seconds

then you need to use admin credentials to use this function.

=over 4

=item $camera_channel

Perform camera operation on specified camera channel.

=over 4

=item IPCamera::Reolink::ChannelDefault 

If you are connected to a camera then there is (usually) only 1 channel.

=item integer >= 0

If you are connected to an NVR then there is usually one channel per attached camera starting at integer value 0.

=back

=item $camera_operation 

Camera operation to perform.

=over 4

=item IPCamera::Reolink::ZF_ZoomPos

Set Zoom to specified pos value.

=over 4

=item $camera_zoom_pos 

Set the camera Zoom to the specified pos value in the range:

=over 4

=item IPCamera::Reolink::ZF_ZoomPosMin

Minimum camera zoom value.

=item IPCamera::Reolink::ZF_ZoomPosMax

Maximum camera zoom value.

=back

=back

=item IPCamera::Reolink::ZF_FocusPos 

Set Focus to specified pos value.

=over 4

=item camera_focus_pos 

Set the camera Focus to the specified pos value in the range:

=over 4

=item IPCamera::Reolink::ZF_FocusPosMin

Minimum camera focus value.

=item IPCamera::Reolink::ZF_FocusPosMax

Maximum camera focus value.

=back

=back

=back

=back

=head2 GetOsd($camera_channel)

Return camera current, range and inital On Screen Display (OSD) values.

=over 4

=item $camera_channel 

Perform camera operation on specified camera channel.

=over 4

=item IPCamera::Reolink::ChannelDefault 

If you are connected to a camera then there is (usually) only 1 channel.

=item integer >= 0

If you are connected to an NVR then there is usually one channel per attached camera starting at integer value 0.

=back

=item return

Returns (undef, undef, undef) if the GetOsd function failed or ($osd_value_r, $osd_range_r, $osd_initial_r) on success, hash references to OSD current value, range and initial values information if successful, fields most likely subject to change (typical values in parenthesis):

=over 4

=item $osd_value_r

Hash reference to current camera OSD values.

=over 4

=item $osd_value_r->{Osd}

Current camera OSD values.

=over 4

=item $osd_value_r->{Osd}->{bgcolor} (0/1)

Current camera OSD background color disabled (0) or enabled (1).

=item $osd_value_r->{Osd}->{channel} (0)

=over 4

=item IPCamera::Reolink::ChannelDefault 

If you are connected to a camera then there is (usually) only 1 channel.

=item integer >= 0

If you are connected to an NVR then there is usually one channel per attached camera starting at integer value 0.

=back

=item $osd_value_r->{Osd}->{osdChannel}

Current OSD values for specified camera channel.

=over 4

=item $osd_value_r->{Osd}->{osdChannel}->{enable} (0/1)

OSD enabled if 1 else disabled if 0.

=item $osd_value_r->{Osd}->{osdChannel}->{name} ("rlc-823a-16x")

OSD display value.

=item $osd_value_r->{Osd}->{osdChannel}->{pos} ("Lower Right")

OSD display position.

=back

=item $osd_value_r->{Osd}->{osdTime}

Current OSD time display values for specified camera channel.

=over 4

=item $osd_value_r->{Osd}->{osdTime}->{enable} (0/1)

OSD time display enabled if 1 else disabled if 0.

=item $osd_value_r->{Osd}->{osdTime}->{pos} ("Lower Right")

OSD time display position.

=back

=back

=back

=item osd_range_r

Hash reference to camera OSD value ranges.

=over 4

=item TBD

=back

=item osd_initial_r

Hash reference to camera OSD initial values.

=over 4

=item TBD

=back

=back

=back

=head2 SetOsd($camera_channel, $enableChannel, $channelName, $channelPos, $enableTime, $timePos)

Set camera On Screen Display (OSD) values.

Note that the current version of the firmware on the authors camera
(Firmware Version v3.1.0.2347_23061923_v1.0.0.93) requires a Login()
using admin credentials to use this function.

=over 4

=item $camera_channel 

Perform camera operation on specified camera channel.

=over 4

=item IPCamera::Reolink::ChannelDefault 

If you are connected to a camera then there is (usually) only 1 channel.

=item integer >= 0

If you are connected to an NVR then there is usually one channel per attached camera starting at integer value 0.

=back

=item $enableChannel (0/1)

1 to enable display of channelName else 0.

=item channelName ("rlc-823a-16x")

Channel OSD text to display

=item $channelPos ("Lower Right") 

Channel OSD text position:

=over 4

=item IPCamera::Reolink::OSD_UpperLeft

OSD position "Upper Left"

=item IPCamera::Reolink::OSD_TopCenter

OSD position "Top Center"

=item IPCamera::Reolink::OSD_UpperRight

OSD position "Upper Right"

=item IPCamera::Reolink::OSD_LowerLeft

OSD position "Lower Left"

=item IPCamera::Reolink::OSD_BottomCenter

OSD position "Bottom Center"

=item IPCamera::Reolink::OSD_LowerRight

OSD position "Lower Right"

=back

=item $enableTime

1 to enable display of date/time else 0.

=item timePos ("Upper Left") 

Date/Time OSD text position:

=over 4

=item IPCamera::Reolink::OSD_UpperLeft

OSD position "Upper Left"

=item IPCamera::Reolink::OSD_TopCenter

OSD position "Top Center"

=item IPCamera::Reolink::OSD_UpperRight

OSD position "Upper Right"

=item IPCamera::Reolink::OSD_LowerLeft

OSD position "Lower Left"

=item IPCamera::Reolink::OSD_BottomCenter

OSD position "Bottom Center"

=item IPCamera::Reolink::OSD_LowerRight

OSD position "Lower Right"

=back

=back 

=head1 TODO

=over 4

=item Implememnt REST via HTTPS.

=item Camera seems to "forget" existing REST/HTTP(S) session after period of inactivity.

=back

=head1 AUTHOR

Stephen Oberski, C<< <cpan at cargocult.ca> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ipcamera-reolink at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=IPCamera-Reolink>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc IPCamera::Reolink


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=IPCamera-Reolink>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/IPCamera-Reolink>

=item * Search CPAN

L<https://metacpan.org/release/IPCamera-Reolink>

=back

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2024 by Stephen Oberski.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
1; # End of IPCamera::Reolink
