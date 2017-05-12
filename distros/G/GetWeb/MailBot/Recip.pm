package MailBot::Recip;

use MailBot::Util;
use strict;

sub d
{
    &MailBot::Util::debug(@_);
}

sub new
{
    my $type = shift;
    my @recipient = @_;
    my $self = {RECIPIENT_LIST => \@recipient };
    bless($self,$type);
}

sub asString
{
    my $paRecipient = shift -> {RECIPIENT_LIST};
    join(' ',@$paRecipient);
}

sub to
{
    my $paRecipient = shift -> {RECIPIENT_LIST};
    # &d("main recipient is " . $$paRecipient[0]);
    $$paRecipient[0];
}

sub cc
{
    my $paRecipient = shift -> {RECIPIENT_LIST};

    my @aRec = @$paRecipient;
    shift @aRec;
    join(' ',@aRec);
}

1;
