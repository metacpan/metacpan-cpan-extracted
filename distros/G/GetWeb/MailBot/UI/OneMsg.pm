package MailBot::UI::OneMsg;

#use MailBot::Internet;
use Mail::Internet;
use MailBot::Util;
use MailBot::Entity;
use MailBot::Config;
use MailBot::UI::Loop;

@ISA = qw( MailBot::UI );
use strict;

# my $SENDMAIL = "/usr/bin/sendmail";

# jf test sendmail Precedence line

my $gDoubleBounce = 0;

#my $MAIL = "/bin/Mail";
#(-x $MAIL) or die "no $MAIL program";

sub d
{
  MailBot::Util::debug @_;
}

sub vInit
{
    my $self = shift;
    my $config = MailBot::Config::current;

    # fix Mail::Util bug
    defined $ENV{LOGNAME} or
	$ENV{LOGNAME} = (getpwuid($>))[0];

    $$self{BOUNCE_ADDR} = $config -> getBounceAddr;
    $$self{NEVER_SEND} = $config -> neverSend;
}

sub vQuotaMultiplier
{
    1;
}

sub doubleBounce
{
    my $self = shift;
    my $badMessage = shift;
    my $error = shift;

    eval
    {
	$gDoubleBounce++ and
	    die "doubleBounce message double-bounced";

	my $bounceAddr = $$self{BOUNCE_ADDR};
	die "no bounce address" unless $bounceAddr =~ /./;

	my @data = ("$error\n\n",
		    "____Here is the double-bounced message____\n\n",
		    &MailBot::Util::messageToArray($badMessage)
		    );

	my $envelope = new MailBot::Envelope;
	&MailBot::Entity::setEnvelope($envelope);

	my $entity = build MailBot::Entity(Data => \@data);
	$entity -> head -> replace('to',$bounceAddr);
	$entity -> head -> replace('subject','GetWeb double-bounce');
	$self -> vSendMessage($entity);

    };
    if ($@)
    {
	print STDERR "triple bounce: $@";
    }
    $gDoubleBounce = 0;
    die "BOUNCE: saw double-bounce.  Closing down to prevent mail loop!";
}

sub vGetMessage
{
    my $self = shift;

    my $message = new Mail::Internet(\*STDIN);
    $self -> done;
    $self -> analyzeMessage($message);
}

sub analyzeMessage
{
    my $self = shift;
    my $message = shift;

    my $header = $message -> head;

    my $loop;

    eval
    {
	$loop = new MailBot::UI::Loop($message);
    };
    if ($@)
    {
	die $@ unless $@ =~ s/^LOOP:\s*//;
	$self -> doubleBounce($message,$@);
    }

    my $subject = $header -> get("Subject");
    
    $message -> remove_sig();
    my $paBody = $message -> body();

    $$self{LOOP} = $loop;

    $self -> setIncoming($message);
    $self -> save($message,"incoming");

    0;
}

sub vSendMessage
{
    my $self = shift;
    my $internet = shift;

    # jfj add getweb version number to headers
    # jfj check errors-to field

    my $bounceAddr = $$self{BOUNCE_ADDR};
    defined $bounceAddr or $bounceAddr = "";

    if (defined $$self{LOOP})
    {
	$$self{LOOP} -> makeAutoResponse($internet,
					 $bounceAddr);
    }

    if ($$self{NEVER_SEND})
    {
	$internet -> print;
	return;
    }

    my $config = MailBot::Config::current;
    $ENV{SMTPHOSTS} = $config -> getIniVal("smtp","host");

    $self -> save($internet,"outgoing");

    $internet -> smtpsend($bounceAddr)
	or die "could not send to " . $internet -> get('to');
}

1;
