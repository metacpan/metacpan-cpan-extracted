package MailBot::UI;

use MailBot::Config;
use MailBot::UI::Manual;
use MailBot::UI::OneMsg;
use MailBot::UI::CGI;
use MailBot::UI::AdvCGI;
use MailBot::UI::Spool;
use MailBot::Quota;
use MailBot::Profile;
use Mail::Address;

use Carp;
use strict;

# jfj parse incoming MIME multipart messages
# jfj test maximum hop-count for loop prevention
# jfj support check-boxes in custom query fields
# jf parse incoming MIME-encoded messages

my $gUI;
my $gMore = 1;

sub current
{
    defined $gUI or $gUI = new MailBot::UI;
    $gUI;
}

sub more
{
    $gMore;
}

sub done
{
    $gMore = 0;
}

sub new
{
    my $type = shift;
    my $config = MailBot::Config::current;

    my $self = {};

#    $$self{QUOTA} = $self -> newQuota();
    
    if ($config -> isCGI)
    {
	if ($config -> isInteractive)
	{
	    bless($self,"MailBot::UI::AdvCGI");
	}
	else
	{
	    bless($self,"MailBot::UI::CGI");
	}
    }
    elsif ($config -> isInteractive)
    {
	bless($self,"MailBot::UI::Manual");
    }
    elsif (defined $config -> getMailSpool())
    {
	bless($self,"MailBot::UI::Spool");
    }
    else
    {
	bless($self,"MailBot::UI::OneMsg");
    }

    $$self{NOTE} = [];
    $self -> vInit();

    $gUI = $self;
    $self;
}

sub note
{
    my $self = shift;
    push(@{$$self{NOTE}},@_);
}

sub getNoteRef
{
    shift -> {NOTE};
}

sub getProfile
{
    shift -> {PROFILE};
}

sub getQuota
{
    my $self = shift;

    $self -> getProfile -> getQuota($self -> vQuotaMultiplier);
}

sub getServiceParam
{
    my $self = shift;
    my $key = shift;

    my $internet = $$self{INCOMING};
    defined $internet or die "no internet";

    my $head = $internet -> head;
    my $to = $head -> get("To");

    # jfj un-hardwire to of 'getweb' for manual mode
    $to eq "" and
	$to = 'getweb';
    my ($address,$err) = Mail::Address -> parse($to);
    #defined $err and die "Cannot process message to multiple recipients: $to";
    my $user = $address -> user;

    my $config = MailBot::Config::current;
    my $param = $config -> getIniVal("service.$user",$key);
    if (! defined $param)
    {
	$to = 'getweb';
	$param = $config -> getIniVal("service.getweb",$key);
	defined $param or die "no key $key for service getweb";
    }
    $param;
}

sub copyIncomingHead
{
    my $self = shift;

    my $internet = $$self{INCOMING};
    defined $internet or return undef;

    my $head = $internet -> head;

    my $copy = $head -> dup;
    $copy;
}

sub getFrom
{
    my $self = shift;

    my $incoming = $$self{INCOMING};
    defined $incoming or return undef;
    my $head = $incoming -> head;

    my $from = $head -> get('From');
    chomp($from) if defined $from;
    $from;
}

sub getReturnAddress
{
    my $self = shift;

    my $incoming = $$self{INCOMING};
    defined $incoming or return undef;
    my $head = $incoming -> head;

    my $replyTo = $head -> get('Reply-To');
    if (defined $replyTo)
    {
	chomp($replyTo);
	return $replyTo;
    }
    $self -> getFrom;
}

# jfj implement maximum input message length

sub sendMessage
{
    my $self = shift;
    my $internet = shift;
    # my ($mime, $recip, $subject) = @_;

    my $head = $self -> copyIncomingHead;
    my $originalSender = $self -> getFrom;

    my $profile = $self -> getProfile;
    my $to = $internet -> get('To');
    chomp($to);
    if ($originalSender ne $to)
    {
	$profile -> allowRedirect or
	    $profile -> dDie("redirect message to $to");
    }

    $self -> vSendMessage($internet);
}

sub copyIncoming
{
    my $self = shift;
    my $internet = $$self{INCOMING};
    
    my $copy = $internet -> dup;
    $copy;
}

sub setIncoming
{
    my $self = shift;
    $$self{INCOMING} = shift;
}

sub save
{
    my $self = shift;
    my $message = shift;
    my $fileName = shift;

    defined $message or croak "message not defined";

    my $config = MailBot::Config::current;
    defined $fileName or die "fileName not defined";

    my $shouldSave = $config -> getIniVal("save",$fileName);
    if (! defined $shouldSave)
    {
	my $base = $fileName;
	$base =~ s/\..+//;
	$shouldSave = $config -> getIniVal("save",$base);
    }
    return unless $shouldSave;

    my $saveDir = $config -> getSaveDir;

    my $path = "$saveDir/$fileName.rfc";
    open(SAVE,">>$path") or die "could not save to $path: $!";
    $message -> print(\*SAVE);
    print SAVE "\n";
    close(SAVE) or die "could not close SAVE filehandle: $!";
}

sub getMessage
{
    my $self = shift;

    my $ret;
    while (1)
    {
	$ret = $self -> vGetMessage;
	last unless $ret eq 2;
	sleep 60;
    }

    my $message = $$self{INCOMING};
    my $head = $message -> head;

    my $sender = $self -> getFrom;
    my $replyTo = $self -> getReturnAddress;

    my @addr = map($_->address, Mail::Address->parse($sender));
    @addr > 0 or die "cannot find a 'from' address, stopped";
    if (@addr > 1)
    {
	# Mail::Address bug for addresses like <foo.bar> (Foo Bar)
	$head -> replace('From',$addr[0]);
	$sender = $self -> getFrom;
	@addr = map($_->address, Mail::Address->parse($sender));
    }

    # map "Rolf Nelson <rolf@usa.healthnet.org>" to rolf@usa.healthnet.org
    my $senderID = $addr[0];
    my $profile = new MailBot::Profile($senderID);

    # jfj break into requester, recipient profiles
    $$self{PROFILE} = $profile;

    if ($replyTo ne $sender)
    {
	if (! $profile -> allowRedirect)
	{
	    $self -> note("ignoring reply-to field");
	    $head -> replace('Reply-To',$sender);
	}
    }

    &MailBot::Util::fold($message);

    $ret;
}

# jfj allow string-replacement through META pragma in HELP text

sub vSendMessage { die "must be overloaded"; }
sub vGetMessage { die "must be overloaded"; }

1;
