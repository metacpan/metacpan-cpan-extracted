package GSM::SMS::Transport::NovelSoft;

=head1 NAME

GSM::SMS::Transport::NovelSoft - Send SMS messages via the sms-wap.com service.

=head1 DESCRIPTION

Implements a  send-only transport for the I<http://www.sms-wap.com> 
HTTP based SMS center. This is a swiss company and they provide a very nice 
service. 

Also can do PDU messages and as such can be used to send NBS messages.

=cut

use strict;
use vars qw( $VERSION $AUTOLOAD );

use base qw( GSM::SMS::Transport::Transport );

$VERSION = "0.161";

use Carp;
use HTTP::Request::Common qw(POST);
use LWP::UserAgent;
use URI::URL qw(url);
use GSM::SMS::PDU;
use Log::Agent;

use constant PRIMARY_SERVER	  => 'http://clients.sms-wap.com:80/cgi/csend.cgi';
use constant SECONDARY_SERVER => 'http://clients.sms-wap.com:80/cgi/csend.cgi';

{
	my %_attrs = (
		_name				=> 'read',
		_proxy				=> 'read/write',
		_userid				=> 'read/write',
		_password			=> 'read/write',
		_originator			=> 'read/write',
		_smsserver			=> 'read/write',
		_backupsmsserver	=> 'read/write',
		_match				=> 'read/write'
	);	

	sub _accessible
	{
		my ($self, $attr, $mode) = @_;

		return $_attrs{$attr} =~ /$mode/ if exists $_attrs{$attr};
	}
}

=head1 METHODS

=over 4

=item B<new> - Constructor

  my $novelsoft = GSM::SMS::Transport::NovelSoft->new(
    -name=> $name_of_transport,
    -proxy=> $http_proxy,
    -userid=> $userid_credential_for_novelsoft,
    -password=> $password_credential_for_novelsoft,
    -originator=> $originator,
    -smsserver=> $primary_novelsoft_sms_server,
    -backupsmsserver=> $secundary_novelsoft_sms_server,
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
	$self->{_backupsmsserver}	= $args{-backupsmsserver} || SECONDARY_SERVER;

	bless $self, $class;

	logdbg "debug", "GSM::SMS::Transport::NovelSoft started";

	return $self;
}

=item B<get_info> - Return info about the transport

=cut

sub get_info {
	my ($self) = @_;

	my $revision = '$Revision: 1.2 $';
	my $date = '$Date: 2003/01/11 14:16:34 $';

print <<EOT;
NovelSoft transport $VERSION

Revision: $revision

Date: $date

EOT
}


# Send a (PDU encoded) message  
sub send	{
	my ($self, $msisdn, $pdu) = @_;

	logdbg "debug", "NovelSoft: msisdn=$msisdn";
	logdbg "debug", "NovelSoft: pdu=$pdu";


	if ( $self->_transmit($pdu, $self->get_smsserver()) ) {
		# trying backup
		if ( $self->_transmit($pdu, $self->get_backupsmsserver()) ) {    
			logerr "Novelsoft: Error sending";
			return -1;
		}
	}
	return 0;
};

sub receive 	{
	my ($self, $pduref) = @_;

	return -1;
};	
 

# Close
sub close	 {
	my ($self) = @_;

	logdbg "debug", "NovelSoft Transport ended";
}

# A ping command .. just return an informative string on success
sub ping {
	my ($self) = @_;

	return "Pong.. NovelSoft  transport ok";
}

#####################################################################
# transport specific
#####################################################################
sub _transmit {
	my ($self, $pdustr, $server) = @_;

	my $object_class = ref($self);

	my $uid = $self->get_userid();
	my $pwd = $self->get_password();
	my $originator = $self->get_originator();
	my $proxy = $self->get_proxy();

	my $url = url( $server );
	my $msg;
	my $decoder = GSM::SMS::PDU->new();
	my ($da, $pdutype, $dcs, $udh, $payload) = $decoder->SMSSubmit_decode($pdustr); 

	$da=~s/^\+//;

	if ( $udh && (length($udh) > 0) ) {
		$udh = '01' . sprintf("%02X", int(length($udh)/2)) . $udh;
		$msg="|$udh|$payload";
	} else {
		$msg=$payload;
	}

	my $ua = LWP::UserAgent->new();
	$ua->proxy( 'http', $proxy ) if ( $proxy ne "" );
	my $req = POST "$server",
				[ 
				UID => $uid, 
				PW => $pwd, 
				N => $da, 
				O => $originator,
				M => $msg 
				];

	$req->header( Host => $url->host );

	my $res = $ua->request($req);


	if ($res->is_success) {
		my $content = $res->content;
		logdbg "debug", "In ${object_class} HTTP response [$content]";
		return 0 if ($content=~/01/);
		return -1;
	} else {
		my $err_msg = "In ${object_class} HTTP error with result : " 
					  . $res->error_as_HTML;
		logdbg "debug", $err_msg;
		logerr $err_msg;
		return -1;
	}
}

1;

=head1 AUTHOR

Johan Van den Brande <johan@vandenbrande.com>
