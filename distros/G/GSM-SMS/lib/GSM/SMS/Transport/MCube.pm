package GSM::SMS::Transport::MCube;
use strict;

use vars qw( $VERSION $AUTOLOAD );

$VERSION = '0.2';

=head1 NAME

GSM::SMS::Transport::MCube - HTTP access to the MCube SMS center

=head1 DESCRIPTION

Implements a ( send-only ) transport for the MCube ss7 SMS gateway.
Please visit www.mcube.be for getting an account. 

Also can do PDU messages and as such can be used to send NBS messages.

=cut

use base qw( GSM::SMS::Transport::Transport );

use HTTP::Request::Common qw(GET);
use LWP::UserAgent;
use URI::URL qw(url);
use URI::Escape qw(uri_escape);
use GSM::SMS::PDU;
use Log::Agent;
use Data::Dumper;

# All the parameters I need to run
my @config_vars = qw( 
	name
	proxy
	userid
	password
	originator
	smsserver
	match
					);

use constant PRIMARY_SERVER	  => 'http://clients.sms-wap.com:80/cgi/csend.cgi';

{
	my %_attrs = (
		_name				=> 'read',
		_proxy				=> 'read/write',
		_userid				=> 'read/write',
		_password			=> 'read/write',
		_originator			=> 'read/write',
		_smsserver			=> 'read/write',
		_match				=> 'read/write'
	);	

	sub _accessible
	{
		my ($self, $attr, $mode) = @_;
		$_attrs{$attr} =~ /$mode/
	}
}

=head1 METHODS

=over 4

=item B<new> - Constructor

  my $mcube = GSM::SMS::Transport::MCube->new(
    -name=> $name_of_transport,
    -proxy=> $http_proxy,
    -userid=> $userid_credential_for_mcube,
    -password=> $password_credential_for_mcube,
    -originator=> $originator,
    -smsserver=> $primary_novelsoft_sms_server,
    -match=> $matching_regex_for_allowed_msisdn
  );

=cut

sub new {
	my ($proto, %args) = @_;
	my $class = ref($proto) || $proto;

	logdbg "debug", "$class constructor called";

	my $self = $class->SUPER::new(%args);

	$self->{_proxy}				= $args{-proxy}; 
	$self->{_userid}			= $args{-userid}	|| croak("missing userid");
	$self->{_password}			= $args{-password}	|| croak("missing password");
	$self->{_smsserver}			= $args{-smsserver} || PRIMARY_SERVER;

	bless $self, $class;

	logdbg "debug", "GSM::SMS::Transport::NovelSoft started";

	return $self;
}

=item B<get_info> - Return info about the transport

=cut

sub get_info {
	my ($self) = @_;

	my $revision = '$Revision: 1.1.1.1 $';
	my $date = '$Date: 2002/10/15 20:53:38 $';

print <<EOT;
MCube transport $VERSION

Revision: $revision
Date: $date

EOT
}

=item B<send> - Send a (PDU encoded) message  

=cut

sub send	{
	my ($self, $msisdn, $pdu) = @_;

	logdbg "debug", "MCube: send [$pdu]";

	if ( $self->_transmit($pdu, $self->get_smsserver() ) ) {
		logerr "MCube: Error sending"; 
		return -1;
	}
	return 0;
};

=item B<receive> - Receive a PDU encoded message

=cut

sub receive 	{
	my ($self, $pduref) = @_;

	return -1;
};	
 
=item B<close> 

=cut

sub close	 {
	my ($self) = @_;

	logdbg "debug", "MCube transport closed";

}

=item B<ping> - A ping command .. just return an informative string on success

=cut

sub ping {
	my ($self) = @_;

	return "Pong.. MCube transport ok";
}

=back

=cut

#####################################################################
# transport specific
#####################################################################
sub _transmit {
	my ($self, $pdustr, $server) = @_;

	my $uid = $self->{cfg}->{"userid"};
	my $pwd = $self->{cfg}->{"password"};
	my $originator = $self->{cfg}->{"originator"};
	my $proxy = $self->{cfg}->{"proxy"};
	my $url = url( $server );
	my $msg;
	my $decoder = GSM::SMS::PDU->new();
	my ($da, $pdutype, $dcs, $udh, $payload) = $decoder->SMSSubmit_decode($pdustr); 

	$da=~s/^\+//;

	my $type;
	if (defined($udh) && (length($udh) > 0)) {
		# transfor to hexprints
		#$udh = $self->serialize_to_hex( $decoder->decode_7bit( $udh, length($udh) ));
		#$payload = $self->serialize_to_hex( $decoder->decode_7bit( $payload, length($payload) ) );

		# $udh = $decoder->decode_7bit( $udh, length($udh));
		# $payload = $decoder->decode_7bit( $payload, length($payload) );

		$type = 3;
	} else {
		$type = 1;
	 	$udh = "";	
	}

	my $ua = LWP::UserAgent->new();
	$ua->proxy( 'http', $proxy ) if ( $proxy ne "" );
	my $urlstring = "$server"
					.
					"?"
					.
					"login=" . uri_escape( $uid )
					.
					"&password=" . uri_escape( $pwd )
					.
					"&togsm=" . uri_escape( $da )
					.
					"&oastring=" . uri_escape( $originator )
					.
					"&type=" . $type
					.
					"&datas=" . uri_escape( $payload )
					.
					"&header=" . uri_escape( $udh )		
					;

	my $req = GET $urlstring;	
	$req->header( Host => $url->host );

	my $res = $ua->request($req);

	if ($res->is_success) {
		my $content = $res->content;
		logdbg "debug", "MCube: HTTP response [$content]";
		return 0 if ($content=~/01/);
		return -1;
	} else {
		logdbg "debug", "MCube: " . $res->error_as_HTML;
		logerr "MCube: " . $res->error_as_HTML;
		return -1;
	}
}

sub serialize_to_hex {
    my ($self, $ud) = @_;
	my $msg;
 
    while (length($ud)) {
       $msg .= sprintf("%.2X", ord(substr($ud,0,1)));
       $ud = substr($ud,1);
    }
    return $msg;
} 

1;

=head1 AUTHOR

Johan Van den Brande <johan@vandenbrande.com>

=cut
