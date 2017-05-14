package GSM::SMS::NBS;

use vars qw($VERSION);

$VERSION = "0.161";

=head1 NAME

GSM::SMS::NBS - API for sending and receiving SMS messages.

=head1 SYNOPSIS

  use GSM::SMS::NBS;

  my $nbs = GSM::SMS::NBS->new;

  $nbs->sendRTTTL('+32475000000', $rtttl_string);
  $nbs->sendOperatorLogo_b64($msisdn, $countrycode, $operator, $b64, 'gif');
  $nbs->sendOperatorLogo_file($msisdn, $countrycode, $operatorcode, $file);
  $nbs->sendGroupGraphic_b64($msisdn, $b64, 'png');
  $nbs->sendGroupGraphic_file($msisdn, $file);
  $nbs->sendVCard($msisdn, $lastname, $firstname, $phonenumber);
  $nbs->sendConfig(....);
  $nbs->sendSMSTextMessage($msisdn, $message, $multipart);

  ...

  my $originatingaddress;
  my $message;
  my $timestamp;
  my $transportname;
  my $port;
  my $blocking = GSM::SMS::NBS::RECEIVE::BLOCKING;

  $nbs->receive(	\$originatingaddress,
    \$message,
    \$timestamp,
    \$transportname,
    \$port,
    $blocking
   );

   print "I got a message from $originatingaddress\n";

=head1 DESCRIPTION

This module is a facade for the GSM::SMS package. It provides an easy API for sending and receiving SMS messages.

=cut

use GSM::SMS::NBS::Message;
use GSM::SMS::NBS::Stack;
use GSM::SMS::OTA::RTTTL;
use GSM::SMS::OTA::CLIicon;
use GSM::SMS::OTA::Operatorlogo;
use GSM::SMS::OTA::VCard;
use GSM::SMS::OTA::Config;
use GSM::SMS::OTA::PictureMessage;
use GSM::SMS::Transport;
use MIME::Base64;
use Log::Agent;

=head1 CONSTANTS

=over 4

=item B<GSM::SMS::NBS::RECEIVE_BLOCKING>

Blocking receive

=cut

use constant RECEIVE_BLOCKING => 1;

=item B<GSM::SMS::NBS::RECEIVE_NONBLOCKING>

Non blocking receive

=cut

use constant RECEIVE_NONBLOCKING => 0;

=item B<GSM::SMS::NBS::MULTIPART_YES>

No multipart text messages. See the method C<sendSMSTextMessage>.

=cut

use constant MULTIPART_NO => 0;

=item B<GSM::SMS::NBS::MULTIPART_YES>

Multipart text messages. See the method C<sendSMSTextMessage>.

=cut

use constant MULTIPART_YES => 1;

=item B<GSM::SMS::NBS::FLASH_YES>

Send flash - for immediate display - messages.
See the method C<sendSMSTextMessage>.

=cut

use constant FLASH_YES => 1;

=item B<GSM::SMS::NBS::FLASH_NO>

No flash.
See the method C<sendSMSTextMessage>.

=cut

use constant FLASH_NO => 0;

=back

=head1 CONSTRUCTORS

=over 4

=item B<new> - Constructor

  my $nbs = GSM::SMS::NBS->new(
              -transport => $name_of_transport,
              -config_file => $config_file
              );
   
  my $nbs = GSM::SMS::NBS->new( $config_file );

Both parameters are optional. If you have configured the GSM::SMS package, you'll not need to use a specific configuration file. 

The transport parameter allows you to specify a specific transport to use for this instance of GSM::SMS::NBS. When sending a message, a route will be tried to be determined via this specific transport. If successfull, this transport will be used to actualy send the message. This parameter is the name of transport as specified in the configuration.

=cut

sub new {
	my ($proto, @arg) = @_;
	my $class = ref($proto) || $proto;
	my $self = {};

	# Try to be compatible with previous version of the GSM::SMS package
	
	my $specific_transport;
	my $config_file;
	my %arg;
	
	# First we had one parameter, being the config file

	if ( 1 == @arg ) {
		$config_file = $arg[0];
	} else {
		%arg = @arg;

		$specific_transport = $arg{-transport};
		$config_file = $arg{-config_file};
	}
	
	bless($self, $class);

	logdbg "debug", "$class constructor called";

	my $transport = GSM::SMS::Transport->new( -transport => $specific_transport,
											  -config_file => $config_file );

	unless ($transport) {
		logdbg "debug", "Could not instantiate a transport";
		logerr "Could not instantiate a transport";
		return undef;
	}
	$self->{'__TRANSPORT__'} = $transport;
	$self->{'__STACK__'} = GSM::SMS::NBS::Stack->new(-transport => $transport);	
	
	return $self;
}

=back

=head1 METHODS

=over 4

=item B<sendto> - Send a message

This is a helper function. It'l take a message and tries to send it. This method
uses the GSM::SMS::NBS::* subclasses to split up the message in smaller fragments.

=cut

sub sendto {
	my ($self, $msisdn, $message, $dport, $sport, $dcs ) = @_;
	my $ret = 0;

	my $transport = $self->{'__TRANSPORT__'};

	my $nbs_message = GSM::SMS::NBS::Message->new();
	$nbs_message->create($msisdn, $message, $dport, $sport, $dcs);
	foreach my $frame ( @{$nbs_message->get_frames()} ) {
		# transport->send returns -1 on failure.
		$ret = -1 if $transport->send($msisdn, $frame);
	}
	return $ret;	
}

=item B<sendRTTTL> - Send a ring tone in RTTTL format.

  $nbs->sendRTTTL( $msisdn, $rtttlstring );

Send a ring tone ( $rtttlstring ) to the specified telephone number ( $msisdn ). The RTTTL ( Ringing Tone Tagged Text Language ) format is specified as described in the file docs/rtttlsyntax.txt.

You can find a lot of information about RTTTL ( and a lot of ringing tones ) on the internet. Just point your favourite browser to your favourite searchengine and look for ringing tones.

=cut

sub sendRTTTL {
	my ($self, $msisdn, $rtttlstring) = @_;

	if ( my $error = OTARTTTL_check($rtttlstring) ) {
		return $error;
	}

	my $music = OTARTTTL_makestream($rtttlstring);
	return $self->sendto( $msisdn, $music, OTARTTTL_PORT);
}

=item B<sendOperatorLogo_b64> -  Send an operator logo

  $nbs->sendOperatorLogo_b64( $msisdn, $country, $operator, $b64, $format);

An operator logo indicates the operator you are connected to for the moment. 
This is used to have a nice logo on your telephone all of the time. 

For this method you'll also need to provide a country code and an operator code.
I've assembled a list of country and operator codes for different mobile
operators in the file "I<docs/codes.txt>". For the moment there is no convenience class that implements the lookup of these code according to the mobile phone number. Due to the dynamic nature of these numbers - numbers can be kept when switching operators - there is no real use of providing an automatic lookup using the mobile phone numbers (maybe a community web service can help us here?).

The method expects a base64 serialised image and the format of the image, 'gif', 'png'. The L<Image::Magick> package is used to process the image, this guarabntees a lot of supported formats. The image needs to be 71 by 14 pixels.

=cut

sub sendOperatorLogo_b64 {
	my ($self, $msisdn, $country, $operator, $b64, $format) = @_;
	
	my $ol = OTAOperatorlogo_fromb64( $country, $operator, $b64, $format );
	return $self->sendto( $msisdn, $ol, OTAOperatorlogo_PORT);
}

=item B<sendOperatorLogo_file> - Send an operator logo

  $nbs->sendOperatorLogo_file( $msisdn, $country, $operator, $file );

Send an operator logo to $msisdn, using the image in file $file. This method
does the same thing as C<sendOperatorLogo_b64>, but uses a file instead of a
base 64 encoded image.

=cut

sub sendOperatorLogo_file {
	my ($self, $msisdn, $country, $operator, $file ) = @_;

	my $ol = OTAOperatorlogo_fromfile( $country, $operator, $file );
	return $self->sendto($msisdn, $ol, OTAOperatorlogo_PORT);
}

=item B<sendGroupGraphic_b64> - Send a group graphic

  $nbs->sendGroupGraphic_b64( $msisdn, $b64, $format);

Send a group graphic, also called a Caller Line Identification icon ( CLIicon ),to the recipient indicated by the telephone number $msisdn. It expects a base 64 encoded image and the format the image is in, like 'gif', 'png'. To find out which image formats are supported, look at the superb package Image::Magick. The base 64 encoded image is just a serialisation of an image file, not of the image bitarray. The image is limited in size, it needs to be 71x14 pixels.

=cut

sub sendGroupGraphic_b64 {
	my ($self, $msisdn, $b64, $format) = @_;

	my $gg = OTACLIicon_fromb64( $b64, $format );
	return $self->sendto($msisdn, $gg, OTACLIicon_PORT);
}

=item B<sendGroupGraphic_file> - Send a group graphic

  $nbs->sendGroupGraphic_file( $msisdn, $file);

Send a group graphic to $msisdn, use the image in file $file. The image must be 71x14 pixels. 

=cut

sub sendGroupGraphic_file {
	my ($self, $msisdn, $file) = @_;

	my $gg = OTACLIicon_fromfile( $file );
	
	return $self->sendto($msisdn, $gg, OTACLIicon_PORT);
}

=item B<sendVCard> - Send a VCard

  $nbs->sendVCard( $msisdn, $lastname, $firstname, $telephone );

A VCard is a small business card, containing information about a person. It is not a GSM only standard, netscape uses vcards to identify the mail sender ( attach vcard option ). You can look at the complete VCard MIME specification in RFC 2425 and RFC 2426.

=cut

sub sendVCard {
	my ($self, $msisdn, $lname, $fname, $phone) = @_;

	my $vcard = OTAVcard_makestream( $last, $first, $phone );
	return $self->sendto( $msisdn, $vcard, OTAVcard_PORT);
}

=item B<sendConfig> - Send WAP configuration settings

  $nbs->sendConfig( $msisdn, 
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

Send a WAP configuration to a WAP capable handset. It expects the following parameters:

The parameters in UPPERCASE are exported constants by the GSM::SMS::OTA::Config.

=over 4

=item I<$msisdn>  

Phonenumber recipient

=item I<$bearer> 

The carrier used ( circuit switched data or sms ), WAP is independent of the underlying connectivity layer.
	
  OTA_BEARER_CSD
  OTA_BEARER_SMS

=item I<$connection>

You have to use continuous for CSD (circuit switched) type of calls.

  OTA_CONNECTIONTYPE_TEMPORARY
  OTA_CONNECTIONTYPE_CONTINUOUS

=item I<$auth>

Use PAP or CHAP as authentication type. A CSD call is just a data call, and as such can use a normal dial-in point.

  OTA_CSD_AUTHTYPE_PAP
  OTA_CSD_AUTHTYPE_CHAP

=item I<$type>

The following calling types are defined. You can either choose ISDN or an analogie connection. The analogue connection is the most used.

  OTA_CSD_CALLTYPE_ISDN
  OTA_CSD_CALLTYPE_ANALOGUE

=item I<$speed>

Connection speed. 

  OTA_CSD_CALLSPEED_9600
  OTA_CSD_CALLSPEED_14400
  OTA_CSD_CALLSPEED_AUTO

=item I<$proxy>

IP address of the WAP gateway to use.

=item I<$home>

URL of the homepage for this setting. e.g. L<http://wap.domain.com>

=item I<$uid>

Dial-up userid

=item I<$pwd>

Dial-up password

=item I<$phone>

Dial-up telephone number

=item I<$name>

Nick name for this connection.			

=back
		
This feature has been tested on a Nokia 7110, but other Nokia
handsets are also supported.	

=cut

sub sendConfig {
	my ($self, $msisdn, $bearer, $connection, $auth, $type, $speed, $proxy, $home, $uid, $pwd, $phone, $name) = @_;

	my $ret = -1;
	my $ota = OTAConfig_makestream(  $bearer, $connection, $auth, $type, $speed, $proxy, $home, $uid, $pwd, $phone, $name);
	if ( $ota ) {
		$ret = $self->sendto( $msisdn, $ota, OTAConfig_PORT, 9200);
	}
	return $ret;
}

=item B<sendSMSTextMessage> - Send a text message

  $nbs->sendSMSTextMessage( $msisdn, $msg, $multipart, $flash );

Send a text message ( $msg ) to the gsm number ( $msisdn ). If you set $multipart to true (!=0) the message will be split automatically in 160 char blocks. When $multipart is set to false it will be truncated at 160 characters. The flash option allows you to send a message that is displayed immediately on the screen of the
mobile phone. This message is not stored in the SIM memory of the mobile phone.
This option defaults to false.

If you want to keep it clean, the following constants can be used for the
multipart flag.

  GSM::SMS::NBS::MULTIPART_YES
  GSM::SMS::NBS::MULTIPART_NO

Likewise the following constants are usefull for the flash sending.

  GSM::SMS::NBS::FLASH_YES
  GSM::SMS::NBS::FLASH_NO

Sending out a non-multipart, non-flash message can be done as follows:

  $nbs->sendSMSTextMessage( "+324...", "Hello World" );

Sending out a non-multipart, flash message can be done as follows:

  $nbs->sendSMSTextMessage( "+324...", 
                            "Alarm, power down", 
                            $GSM::SMS::NBS::MULTIPART_NO,
                            $GSM::SMS::NBS::FLASH_YES
                            );
 
=cut

sub sendSMSTextMessage {
	my ($self, $msisdn, $msg, $multipart, $flash) = @_;
	my $cnt = 0;	
	my $ret = 0;
	my $class = ($flash)?'7biti':'7bit';
	if ( $multipart ) {
		while (length($msg) > 0) {
			my $xmsg = substr($msg, 0, (length($msg)<160)?length($msg):160 );
			$msg = substr($msg, 160, length($msg) - 160);
			$ret = -1 if $self->sendto( $msisdn, $xmsg, undef, undef, $class);
			$cnt++;
		}
	} else {
		$msg = substr($msg, 0, (length($msg)<160)?length($msg):160 );
		$ret = $self->sendto( $msisdn, $msg, undef , undef , $class);
	}
	return ($ret==-1)?$ret:$cnt;
}

=item B<sendPictureMessage_b64> - Send a picture message

  $nbs->sebdPictureMessage_b64( $msisdn, $text, $b64_encoded_image, $format );

Send a Picture message where the image is encoded in a base64 string. The base64 encoding can be handy when implementing a web based service, in which media files are kept in a RDBMS as base64 encoded strings.

=cut

sub sendPictureMessage_b64 {
	my ($self, $msisdn, $text, $b64, $format) = @_;

	my $stream = GSM::SMS::OTA::PictureMessage::OTAPictureMessage_fromb64( $text, $b64, $format );
	return $self->sendto($msisdn, $stream, $GSM::SMS::OTA::PictureMessage::PORT);
}

=item B<sendPictureMessage_file> - Send a picture message

  $nbs->sendPictureMessage_file( $msisdn, $text, $file );

A picture message is a multipart format, consisting of text and an image. The image can be the double height of a normal GSM picture, i.e. 28 pixels.
The text can be abything you want, encoded in a ISO8859-1 charset. There are no tests again the validity of the text string though! The image can be delivered in different formats, i.e. gif, png, ... If you want to know which ones, look them up in the B<convert> man page.

=cut

sub sendPictureMessage_file {
	my ($self, $msisdn, $text, $file) = @_;

	my $stream = GSM::SMS::OTA::PictureMessage::OTAPictureMessage_fromfile( $text, $file);
	return $self->sendto($msisdn, $stream, $GSM::SMS::OTA::PictureMessage::PORT);
}

=item B<receive> - Receive SMS and NBS messages

  $nbs->receive(	\$originatingaddress,
    \$message,
    \$timestamp,
    \$transportname,
    \$port,
    $blocking
  );

This method is used for implementing bidirectional SMS. With you can receive incoming messages. The only transport ( for the moment ) that can receive SMS messages is the Serial transport. 

The originatingaddress contains the sender msisdn number. 

The message contains the ( concatenated ) message. A NBS message can be larger than 140 bytes, so a UDP like format is used to send fragements. The lower layers of the GSM::SMS package take care of the SAR ( Segmentation And Reassembly ). 

The timestamp has the following format:

	YYMMDDHHMMSSTZ

	YY	:=	2 digits for the year ( 01 = 2001 )
	MM	:=	2 digits for the month
	DD	:=	2 digits for the day
	HH	:=	2 digits for the hour
	MM	:=	2 ditits for the minutes
	SS	:=	2 digits for the seconds
	TZ	:=  timezone 

Transportname contains the name of the transport as defined in the config file.

Port is the port number used to denote a specified service in the NBS stack.

  my $originatingaddress;
  my $message;
  my $timestamp;
  my $transportname;
  my $port;
  my $blocking = GSM::SMS::NBS::RECEIVE_BLOCKING;

  $nbs->receive(	\$originatingaddress,
    \$message,
    \$timestamp,
    \$transportname,
    \$port,
    $blocking
  );

  print "I got a message from $originatingaddress\n";

=cut
	
sub receive {
	my ($self, $ref_originatingaddress, $ref_message, $ref_timestamp, $ref_transportname, $ref_port, $blocking, $ref_csca) = @_;	

	my $stack = $self->{'__STACK__'};
	return $stack->receive($ref_originatingaddress, $ref_message, $ref_timestamp, $ref_transportname, $ref_port, $blocking, $ref_csca);
}

=item B<get_transport> - Return the GSM::SMS::Transport object

  my $transport = $nbs->get_transport;

=cut

sub get_transport {
	$_[0]->{'__TRANSPORT__'};
}

1;

__END__

=back

=head1 AUTHOR

Johan Van den Brande <johan@vandenbrande.com>
