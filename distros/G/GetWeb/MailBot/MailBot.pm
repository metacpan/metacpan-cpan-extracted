package MailBot;

$VERSION = "1.00";
sub version {$VERSION};

package MailBot::MailBot;

use MailBot::Util;
use MailBot::UI;
use MailBot::Envelope;
use MailBot::Entity;

use strict;

sub d
{
    &MailBot::Util::debug(@_);
}

sub new
{
    my $type = shift;

    my $self = {};
    bless($self,$type);
}

sub log
{
    my $self = shift;
    my $config = MailBot::Config::current;

    $config -> log(@_);
}

sub run
{
    my $self = shift;
    my $ui = MailBot::UI::current;
    my $config = MailBot::Config::current;

    my $sleep = $config -> getIniVal("load","sleep.message",60);

    # for testing purposes
    my $count = $ENV{MAILBOT_TEST_COUNT};

    while (1)
    {
	if (defined $count)
	{
	    last if $count < 1;
	    $count--;
	}

	while (1)
	{
	    eval {$ui -> getMessage};
	    last unless ($@ ne "");
	    $@ =~ /^BOUNCE:/
		or die $@;
	    return unless $ui -> more;
	}

	my $incoming = $ui -> copyIncoming;

	my $timeout = $config -> getIniVal("load","timeout",60*60*24);

	# $self -> setBodyRef($ui -> getBodyRef());
	eval
	{
	    $SIG{'ALRM'} = sub {die "request timed out\n"};
	    alarm($timeout);
	    $self -> vProcess($incoming);
	};
	if ($@)
	{
	    my $exception = $@;
	    $self -> log($exception);
	    $exception =~ /^SILENT/ and exit 0;
	    
	    my $condition;

	    if ($exception =~ s/^([A-Z ]+)://)
	    {
		$condition = $1;
	    }
	    
	    my $envelope = 
		$self -> newEnvelope($condition);
	    &MailBot::Entity::setEnvelope($envelope);

	    my $desc = $config -> getEnvelopeVal($condition,"desc");
	    
	    my $data = "$desc\n  $exception";
	    $data .= join('',$self -> appendOriginalRequest);
	    
	    my $entity = build MailBot::Entity (
						Data => $data
						);

	    my $fileName = $condition;
	    $fileName eq "" and
		$fileName = "INTERNAL ERROR";
	    $fileName =~ s/ /_/g;
	    $fileName = "exception.$fileName";
	    $ui -> save($entity,$fileName);
	    $fileName = "orig_$fileName";
	    $ui -> save($ui -> {INCOMING},$fileName);

	    $entity -> send;
      	}
	last unless $ui -> more;
	sleep $sleep;
    }
}

sub appendOriginalRequest
{
    my $self = shift;

    my @appendix = ("\n","____original message follows____","\n","\n");

    my $ui = MailBot::UI::current;
    my $internet = $ui -> copyIncoming;

    push(@appendix,&MailBot::Util::messageToArray($internet));

    @appendix;
}

sub setEnvelopeByCondition
{
    my $self = shift;
    my $condition = shift;

    my $envelope = $self -> newEnvelope($condition);

    &MailBot::Entity::setEnvelope($envelope);
}

sub newEnvelope
{
    my $self = shift;
    my $condition = shift;

    my $ui = MailBot::UI::current;
    my $config = MailBot::Config::current;

    $config -> log("exception is $condition");

    if ($condition eq 'QUOTA')
    {
	# try to bill 1 msg, just in case a user keeps trying
	# to squeeze out last few bytes
	my $quota = $ui -> getQuota; 
	eval {$quota -> bill(1,"message")};
    }

    my $envelope = new MailBot::Envelope();

    my $ccList = $config -> getEnvelopeVal($condition,"cc");
    my @aRecipient = ();

    if ($ccList ne "")
    {
	my $cc;
	foreach $cc (split(' ',$ccList))
	{
	    my $address = $config -> getIniVal("address",$cc);
	    defined $address or die "address not defined for $cc";
	    push (@aRecipient, $address);
	}
    }

    my $head = $ui -> copyIncomingHead;
    my $originalSender = $head -> get('From');

    my $exception = $config -> getIniVal('address','exception');
    unless ($exception eq '')
    {
	$originalSender = $exception;  #redirect errors
    }

    my $recipient = $originalSender;
    # &d("rec is $recipient");
    unshift(@aRecipient,$recipient);
    # &d("rec list is ",@aRecipient);
    $envelope -> setRecipientList(@aRecipient);
    $envelope -> setSubject($config -> getEnvelopeVal($condition,"subject"));

    my $quotaMultiplier = $config -> getEnvelopeVal($condition,
						    "quota_multiplier");
    defined $quotaMultiplier or $quotaMultiplier = 1;
    $envelope -> setQuotaMultiplier($quotaMultiplier);

    $envelope;
}
