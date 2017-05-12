package MailBot::UI::CGI;

use Mail::Internet;
use MailBot::Util;

@ISA = qw( MailBot::UI );
use strict;

sub d
{
  MailBot::Util::debug @_;
}

sub vInit
{
    my $self = shift;
    my $config = MailBot::Config::current;

    $$self{BOUNCE_ADDR} = $config -> getBounceAddr();
}

sub getOutHeader
{
    "Content-Type: text/plain\n";
}

sub vGetMessage
{
    my $self = shift;

    # jf: allow web interface to forward, de-MIME messages

    my $req;

    # needs CGI-modules-2.75 or later
    require CGI::Request;
    require CGI::Base;
    my $req = new CGI::Request;

    my $outHeader = $self -> getOutHeader;
    CGI::Base::SendHeaders($outHeader);
    
    my $subject = $req -> param("Subject");
    #&d("subject is $subject");
    
    my $replyTo = $req -> param("Reply-to");
    
    my $body = $req -> param("Body");
    my @aBody = split("\n",$body);
    my $paBody = \@aBody;

    chomp($subject) if defined $subject;
    chomp($replyTo) if defined $replyTo;

    my $message = new Mail::Internet;
    $$self{INCOMING} = $message;

    my $head = $message -> head;
    $head -> add('Subject',$subject) if defined $subject;
    $head -> add('Reply-To',$replyTo) if defined $replyTo;
    $head -> add('From',"ORIGINAL_SENDER");

    $message -> body($paBody);
    
    $self -> done;
}

sub vQuotaMultiplier
{
    0;
}

sub vSendMessage
{
    my $self = shift;
    my $internet = shift;

    print "Here is the message that would be sent in response:\n\n";
    # print "<P><PRE>\n";
    $internet -> print;
    # print "</PRE>\n";
}
