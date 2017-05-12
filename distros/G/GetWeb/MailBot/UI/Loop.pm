package MailBot::UI::Loop;

use strict;

# three defenses against mail-loops:
#
# 1.  X-loop header
# 2.  Set Envelope-From to bounceaddr
# 3.  Refuse messages from @aDoubleBounce list

#my $MAX_HOP = 50;
my @aDoubleBounce = qw( system daemon mailer mailer-daemon
		       echo gateway majordomo listserv netmgr );

# jfj add 'Precedence: junk' header

sub new
{
    my $type = shift;
    my $message = shift;

    my $header = $message -> head;
    my $paBody = $message -> body;

    my $xLoop = $header -> get("X-Loop");
    defined $xLoop and
	die "LOOP: X-Loop line of $xLoop";

    if (grep(/ Transcript of session follows /i,@$paBody))
    {
	# probably a returned mailer-daemon message
	die "LOOP: saw X-Loop: line in body";
    }

    my $from = $header -> get("From");
    $from eq '' and die "did not specify 'From' address";
    my @aAddress = Mail::Address -> parse($from);
    my $address = $aAddress[0];

    my $lowerFrom = lc $address -> address;
    
    grep ($lowerFrom =~ /\b$_\b(?!\-)/,@aDoubleBounce)
	and die "LOOP: Messages from $lowerFrom risk mail-loop";

    my $notDeliveredTo = $header -> get("Not-Delivered-To");
    $notDeliveredTo eq '' or
	die "LOOP: saw Not-Delivered-To header\n";

#     my @aHop = $header -> get("Received");
#     @aHop <= $MAX_HOP
# 	or die "LOOP: too many hops: " . join(' ',@aHop);

#     my $self = {HOP_REF => \@aHop};
    my $self = {};
    bless($self,$type);
}

sub makeAutoResponse
{
    my $self = shift;
    my $internet = shift;
    my $bounceAddr = shift;

    my $header = $internet -> head;

    $header -> replace("Errors-To",$bounceAddr)
	if defined $bounceAddr;
    $header -> add("X-Loop","MailBot");

#     my $paHop = $$self{HOP_REF};
#     my $hop;
#     foreach $hop (@$paHop)
#     {
# 	#$header -> add("Received",$hop);
#     }
}
