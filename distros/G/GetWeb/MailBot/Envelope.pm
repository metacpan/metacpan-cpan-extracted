package MailBot::Envelope;

use MailBot::Recip;
use MailBot::UI;
use MailBot::Config;

use strict;

sub d
{
    &MailBot::Util::debug(@_);
}

sub new
{
    my $type = shift;

    my $ui = MailBot::UI::current;

    my $replyTo = $ui -> getReturnAddress;
    my $defaultRecip = new MailBot::Recip($replyTo);

    my $self = {DEFAULT_RECIP => $defaultRecip,
		MESSAGE_TYPE => "normal",
		QUOTA_MULTIPLIER => 1,
		MIME => 1};

    bless($self,$type);
}

sub setSplitSize
{
    my $self = shift;
    my $size = shift;

    $size =~ /^\d+$/ or
	die "illegal split size: $size\n";

    $$self{SPLIT_SIZE} = $size;
}

sub getSplitSize
{
    my $self = shift;
    my $size = $$self{SPLIT_SIZE};
    return $size if defined $size;

    my $config = MailBot::Config::current;
    $config -> getSplitSize;
}

sub setMIME
{
    my $self = shift;
    $$self{MIME} = shift;
}

sub getRecip
{
    my $self = shift;
    my $recip = $$self{RECIP};
    return $recip if defined $recip;

    # &d("using default");
    $self -> {DEFAULT_RECIP};
}

sub getQuotaMultiplier
{
    shift -> {QUOTA_MULTIPLIER};
}

sub setRecipientList
{
    my $self = shift;
    # &d("setting list to ",@_);
    $self -> {RECIP} = new MailBot::Recip(@_);
}

sub setDefaultAddress
{
    my $self = shift;

    $self -> {DEFAULT_RECIP} = new MailBot::Recip(@_);
}

sub setQuotaMultiplier
{
    my $self = shift;

    $$self{QUOTA_MULTIPLIER} = shift;
}

sub getFrom
{
    shift -> {FROM};
}

sub setFrom
{
    my $self = shift;
    my $sender = shift;

    $$self{FROM} = $sender;
}

sub getSubject
{
    shift -> {SUBJECT};
}

sub setSubject
{
    my $self = shift;
    my $subject = shift;

    $$self{SUBJECT} = $subject;
}

sub getLastByte
{
    my $config = MailBot::Config::current;
    $config -> getMaxSize;
}

1;
