package GSM::SMS::OTA::Config;

require Exporter;
@ISA = qw(Exporter);

$VERSION = '0.1';

@EXPORT = qw(	OTA_BEARER_CSD 
				OTA_BEARER_SMS
				OTA_CONNECTIONTYPE_TEMPORARY
				OTA_CONNECTIONTYPE_CONTINUOUS
				OTA_CSD_AUTHTYPE_PAP
				OTA_CSD_AUTHTYPE_CHAP
				OTA_CSD_CALLTYPE_ISDN
				OTA_CSD_CALLTYPE_ANALOGUE
				OTA_CSD_CALLSPEED_9600
				OTA_CSD_CALLSPEED_AUTO
				OTA_CSD_CALLSPEED_14400
				OTAmakestream
				OTAConfig_makestream
				);

sub OTAConfig_makestream {
 	my ($bearer, $connection, $auth, $type, $speed, $proxy, $home, $uid, $pwd, $phone, $name) = @_;	
	
	# BEARER
	my $_bearer;
	if 		( $bearer eq "CSD" ) {
		$_bearer =  OTA_BEARER_CSD;
	}
	elsif	( $bearer eq "SMS" ) {
		$_bearer = OTA_BEARER_SMS;
	}
	else {
		# print "Unknown bearer type: $bearer!\n";
		return;
	}

	# CONNECTION
	my $_connection;
	if		( $connection eq "TEMPORARY" ) {
		$_connection = OTA_CONNECTIONTYPE_TEMPORARY;
	}
	elsif	( $connection eq "CONTINUOUS" ) {
		$_connection = OTA_CONNECTIONTYPE_CONTINUOUS;
	}
	else {
		# print "Unknown connection type: $connection!\n";
		return;
	}

	# AUTH
	my $_auth;
	if 		( $auth eq "PAP" ) {
		$_auth = OTA_CSD_AUTHTYPE_PAP;
	}
	elsif	( $auth eq "CHAP" ) {
		$_auth = OTA_CSD_AUTHTYPE_CHAP;
	}
	else {
		# print "Unknwon authentication type: $auth!\n";
		return;
	}

	# TYPE
	my $_type;
	if		( $type eq "ISDN" ) {
		$_type = OTA_CSD_CALLTYPE_ISDN;
	}
	elsif	( $type eq "ANALOGUE" ) {
		$_type = OTA_CSD_CALLTYPE_ANALOGUE;
	}
	else {
		# print "Unknown calltype: $type!\n";
		return;
	}

	# SPEED
	my $_speed;
	if		( $speed eq "9600" ) {
		$_speed = OTA_CSD_CALLSPEED_9600;
	}
	elsif	( $speed eq "AUTO" ) {
		$_speed = OTA_CSD_CALLSPEED_AUTO;
	}
	elsif	( $speed eq "14400" ) {
		$_speed = OTA_CSD_CALLSPEED_14400;
	}
	else {
		# print "Unknown speed: $speed!\n";
		return;
	}


	# We do not check the other parameters	

	my $ota = OTAmakestream(
                $_bearer,
                $proxy,
                $_connection,
                $phone,
                $_auth,
                $uid,
                $pwd,
				$_type,
                $_speed,
                $home,
                $name);

	return $ota;
}


sub OTAmakestream {
	my (	$BEARER, 
			$PROXY, 
			$CONNECTIONTYPE,
			$CSD_DIALSTRING,
			$CSD_AUTHTYPE,
			$CSD_AUTHNAME,
			$CSD_AUTHSECRET,
			$CSD_CALLTYPE,
			$CSD_CALLSPEED,
			$URL,
			$NAME 				)	=	@_;	



my $_PROXY 			= OTAencode_8bit( $PROXY );
my $_CSD_DIALSTRING	= OTAencode_8bit( $CSD_DIALSTRING );
my $_CSD_AUTHNAME	= OTAencode_8bit( $CSD_AUTHNAME );
my $_CSD_AUTHSECRET	= OTAencode_8bit( $CSD_AUTHSECRET );
my $_URL			= OTAencode_8bit( $URL );
my $_NAME			= OTAencode_8bit( $NAME );



my $ota = <<END;
01
06
04
03
9481EA00
010045C606
018712${BEARER}	
0187131103
${_PROXY}00 
018714${CONNECTIONTYPE}
0187211103
${_CSD_DIALSTRING}00
018722${CSD_AUTHTYPE}
0187231103
${_CSD_AUTHNAME}00
0187241103
${_CSD_AUTHSECRET}00 
018728${CSD_CALLTYPE}
018729${CSD_CALLSPEED}
01
0186071103
${_URL}00 
01C608
0187151103
${_NAME}00 
01
01
01
END

$ota=~s/[\n\s]//ig;
return $ota;

}

# constant  definition
use constant	OTA_BEARER_CSD => '45'; 
use constant	OTA_BEARER_SMS => '41'; 
use constant    OTA_CONNECTIONTYPE_TEMPORARY => '60';
use constant    OTA_CONNECTIONTYPE_CONTINUOUS => '61';
use constant    OTA_CSD_AUTHTYPE_PAP => '70';
use constant    OTA_CSD_AUTHTYPE_CHAP => '71';
use constant    OTA_CSD_CALLTYPE_ISDN => '73';
use constant    OTA_CSD_CALLTYPE_ANALOGUE => '72';
use constant    OTA_CSD_CALLSPEED_9600 => '6B';
use constant    OTA_CSD_CALLSPEED_AUTO => '6A';
use constant    OTA_CSD_CALLSPEED_14400 => '6C';
use constant 	OTAConfig_PORT => 49999;  

# help functions

sub OTAdecode_8bit {
        my ($ud) = @_;
        my $msg;

        while (length($ud)) {
                $msg .= pack('H2',substr($ud,0,2));
                $ud = substr($ud,2);
        }
        return $msg;
}


sub OTAencode_8bit {
        my ($ud) = @_;
        my $msg;

        while (length($ud)) {
               $msg .= sprintf("%.2X", ord(substr($ud,0,1)));
               $ud = substr($ud,1);
        }
        return $msg;
}


1;

=head1 NAME

GSM::SMS::OTA::Config

=head1 DESCRIPTION

Create an "over the air" configuration message to configure a WAP telephone with a proper setting. I only tested this one on Nokia phones (7110). This is very useful to "bulk configurate" WAP telephones.

=head1 METHODS

=head2 OTAConfig_makestream

	$stream = OTAConfig_makestream(
					$bearer,
					$connection,
					$auth,
					$type,
					$speed,
					$proxy,
					$home,
					$uid,
					$pwd,
					$phone,
					$name
					);

	$bearer:
		CSD | SMS

	$connection:
		TEMPORARY | CONTINUOUS

	$auth:
		PAP | CHAP

	$type:
		ISDN | ANALOGUE

	$speed:
		9600 | 14400 | AUTO

	$proxy:
		IP address of wap gateway to use

	$home:
		URL of home address

	$uid:
		Username for dialin authentication

	$pwd:
		Password for dialin authentification

	$phone:
		Phone number to dial for dial-in connection

	$name:
		Nick name you can give for this connection

=head1 AUTHOR

Johan Van den Brande <johan@vandenbrande.com>

