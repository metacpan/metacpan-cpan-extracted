package MailBot::UI::Manual;

@ISA = qw( MailBot::UI );
use strict;

sub vInit
{
    my $self = shift;
}

sub vQuotaMultiplier
{
    0;
}

sub vGetMessage
{
    my $self = shift;

    my $returnAddress = "terminal";

    my $config = &MailBot::Config::current;

    my $subject = $config -> getSubject();
    if (!defined($subject))
    {
	print STDERR "Type in message subject:\n";
	$subject = (<>);
    }

    my $input;
    my $paBody;
    my $body = $config -> getBody();

    if (defined($body))
    {
	$paBody = [ $body ];
    }
    else
    {
	print STDERR "Type in message, with a single '.' when done.\n";
	
	$paBody = [];
	while ($input = (<>))
	{
	    last unless defined $input;
	    last if $input eq ".\n";
	    push(@$paBody,$input);
	}
    }
    
    my $message = new Mail::Internet;
    $$self{INCOMING} = $message;

    my $head = $message -> head;
    $head -> add('From','Original_Sender');
    $head -> add('Subject',$subject);
    $head -> add('Reply-To',$returnAddress);

    $message -> body($paBody);

    $self -> done unless defined $input;
}

sub vSendMessage
{
    my $self = shift;
    my $internet = shift;

    #$internet -> head -> delete('X-Mailer');
    $internet -> print();
}
