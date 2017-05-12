package FWS::V2::SocketLabs;

use 5.006;
use strict;
use warnings;
use MIME::Lite;
use MIME::Base64;
use Authen::SASL;

#
# not everything will be defined by nature
#
no warnings 'uninitialized';

#
# Merge this module with the FWS V2 
#
BEGIN { push @FWS::V2::ISA, 'FWS::V2::SocketLabs'; }

=head1 NAME

FWS::V2::SocketLabs - FrameWork Sites version 2 socketlabs.com SMTP integration

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

This module will process all outgoing mail from FWS 2.0 though a socketlabs.com SMTP account.   Add the following to your FWS go.pl FWS parameter:

	
	my $fws = FWS::V2->new( %yourConfiguration,
				sendMethod		=> 'socketlabs');

Here is an example FWS independent process you can use as a starter to make your own customized FWS socketlabs process.   This will be appropriate to be added to your CRONTAB to run 'socketLabs.pl send' every minute and run 'socketLabs.pl audit' every hour.   This will work fine if your sending less than 500 email an hour.   If you are sending more than that you should create a custom optimized script for your application based on what your trying to accomplish.

Crontab entry:

	* * * * * /wherever/it/is/socketLabs.pl send  >/dev/null 2>&1
	0 * * * * /wherever/it/is/socketLabs.pl audit  >/dev/null 2>&1

socketLabs.pl:

	#!/usr/bin/perl
	use strict;

	#
	# setup your FWS
	#
	use FWS::V2;

	my $fws = FWS::V2->new(%yourConfiguration,
       		                        
			SocketLabs=>{	mailingId       => 'unique',  # up to 8 characters of unique string
       		                        port            => '2525',
               		                host            => 'smtp.socketlabs.com',
                       		        username        => 'user name for SMTP auth',
                               		password        => 'password for SMTP auth',
		                        queueFailLimit  => 5,
               		                apiURL          => 'https://api.socketlabs.com/v1',
                       		        apiAccountId    => 'from socket labs account',
	                     		apiPassword     => 'from socket labs account',
       					apiUsername     => 'from socket labs account'}
			);

	#
	# add SocketLabs
	#
	$fws->registerPlugin('FWS::V2::SocketLabs');

	#
	# Add your site values
	#
	$fws->setSiteValues('site');


	#
	# Usage String
	#
	my $usageString = "\nUsage: socketlabs.pl [send|audit]\n\n\tsend: send the current queue\n\taudit: sync the socketlabs data with FWS\n\n";
	if ($#ARGV != 0) { print $usageString }

	#
	# we have an argument lets do it!
	#
	else {
        	
		my $arg = $ARGV[0];
        	my $email = $ARGV[1];
	

		#
		# send anything in the queue
		#	
	        if ($arg eq 'send') {
	                print "Runnning Process: ".$arg."\n\n";
	                $fws->SocketLabs_processQueue();
                }

		#
		# audit anything that was sent and update FWS if there is something not synced
		#
        	elsif ($arg eq 'audit') {
               		print "Runnning Process: ".$arg."\n\n";
                	my @historyArray = $fws->queueHistoryArray(synced=>'0');
                	if ($#historyArray > -1 ) { $fws->SocketLabs_processAudit() }
                	else { print "No sync required\n\n" }
        	}
	}
	1;


=head1 PLUGIN INITIALIZATION

=head2 pluginInit

Create a socketLabs object with the configuration parameters.

=over 4

=item * fws

Pass what FWS object you want it to use for its lookups

=item * mailingId

Make sure this is Less than 8 characters.  If you use your socketLabs account for more than one account make sure this is unique.

=item * port

Port 2525 should be good.  If not 25 would be another appropriate port.

=item * host

Default is: smtp.socketlabs.com

=item * username

This is the username for the SMTP auth. 

=item * password

This is the password for the SMTP auth. 

=item * queueFailLimit

How many times it will try to audit before it gives up on the sync.   Make sure this is at least 5 is you are syncing every minute.

=item * apiURL

Deault is:  https://api.socketlabs.com/v1

=item * apiAccountId

Consult the socketlabs API documentation to know what this is.

=item * apiUsername

Consult the socketlabs API documentation to know what this is.

=item * apiPassword

Consult the socketlabs API documentation to know what this is.

=back

=cut

sub pluginInit {
       my ($self,$fws) = @_;

	#
	# set defaults
	#
	if ($fws->{"SocketLabs"}->{"port"} eq '') {		$fws->{"SocketLabs"}->{"port"}               = 2525 }
	if ($fws->{"SocketLabs"}->{"host"} eq '') {		$fws->{"SocketLabs"}->{"host"}               = 'smtp.socketlabs.com' }
	if ($fws->{"SocketLabs"}->{"apiURL"} eq '') {		$fws->{"SocketLabs"}->{"apiURL"}             = 'https://api.socketlabs.com/v1' }
	if ($fws->{"SocketLabs"}->{"queueFailLimit"} eq '') {	$fws->{"SocketLabs"}->{"queueFailLimit"}     = 5 }
	
	#
	# update any $fws data
	#
       
	#
	# pass back our extended class
	#
	return $fws;
}

=head1 EXTENDED METHODS

=head2 SocketLabs_processQueue

Move through the FWS queue and send all email in the queue with the socketlabs type.

=cut

sub SocketLabs_processQueue {
        my ($self) = @_;

	#
        # Get Items
	#
        my @queueArray = $self->queueArray();
	
	#
        # send each one via SocketLabs_sendEmail
	#
        for my $i (0 .. $#queueArray) { $self->_SocketLabs_sendEmail(%{$queueArray[$i]}) }
}

=head2 SocketLabs_processAudit

Audit all the socket labs success and fail messages and update FWS with the response.

=cut

sub SocketLabs_processAudit {
        my ($self) = @_;

        #
        # Request Processed Messages from SocketLabs
        #
        my @SLArray = $self->_SocketLabs_post(	url          =>  $self->{'SocketLabs'}->{'apiURL'},
		                                method       =>  "messagesProcessed",
		                                account_id   =>  $self->{'SocketLabs'}->{'apiAccountId'},
		                                mailingId    =>  $self->{'SocketLabs'}->{'mailingId'},
		                                user         =>  $self->{'SocketLabs'}->{'apiUsername'},
		                                password     =>  $self->{'SocketLabs'}->{'apiPassword'});

        for my $i (0 .. $#SLArray) {
                my %queueHash = $self->queueHistoryHash(queueGUID=>$SLArray[$i]{'MessageId'});

                if ($queueHash{'guid'} ne '' && $queueHash{'response'} eq '') {
                        $queueHash{'response'} = $SLArray[$i]{"Response"} . $SLArray[$i]{"Reason"};
                        if ($SLArray[$i]{"Reason"} eq '')  { $queueHash{'success'} = 1 }
                	print $queueHash{'guid'}.": Synced!\n";
                        $queueHash{'synced'} = 1;
                        $queueHash{"response"} =~ s/\{CRLF\}/<br>/sg;
                        $self->saveQueueHistory(%queueHash);
                }
        }

        my @historyArray = $self->queueHistoryArray(synced=>'0');
        for my $i (0 .. $#historyArray) {
                $historyArray[$i]{'failureCode'}++;
                print $historyArray[$i]{'guid'}.': Not Synced  Try # '.$historyArray[$i]{'failureCode'}."\n";

                #
                # if this is tried to many times, just mark it as synced
                #
                if ($historyArray[$i]{'failureCode'} gt $self->{'SocketLabs'}->{'queueFailLimit'}) {
                	print $historyArray[$i]{'guid'}.": Giving up, to many tries\n";
                        $historyArray[$i]{'synced'} = 1;
                        $historyArray[$i]{'response'} = 'Audit not available';
                }
                $self->saveQueueHistory(%{$historyArray[$i]});
        }

        #
        # Request Failed Messages from SocketLabs
        #
        @SLArray = $self->_SocketLabs_post(	 	url          =>  $self->{'SocketLabs'}->{'apiURL'},
                                                        method       =>  "messagesFailed",
                                                        account_id   =>  $self->{'SocketLabs'}->{'apiAccountId'},
                                                        mailingId    =>  $self->{'SocketLabs'}->{'mailingId'},
                                                        user         =>  $self->{'SocketLabs'}->{'apiUsername'},
                                                        password     =>  $self->{'SocketLabs'}->{'apiPassword'});

         for my $i (0 .. $#SLArray) {
                my %queueHash = $self->queueHistoryHash(queueGUID=>$SLArray[$i]{'MessageId'});
                if ($queueHash{'guid'} ne '' && $queueHash{'response'} eq '') {
                        $queueHash{'response'} = $SLArray[$i]{"Response"} . $SLArray[$i]{"Reason"};
                        if ($SLArray[$i]{"Reason"} eq '')  { $queueHash{'success'} = 1 }
                	print $queueHash{'guid'}.": Synced!\n";
                        $queueHash{'synced'} = 1;
                        $queueHash{"response"} =~ s/\{CRLF\}/<br>/sg;
                        $self->saveQueueHistory(%queueHash);
                }
        }
}





##########################################################
# Net: do the actual send via SocketLabs
##########################################################
sub _SocketLabs_sendEmail {
        my ($self,%paramHash) = @_;

        #
        # create email sending params
        #
        my $msg = MIME::Lite->new(
                From     => $paramHash{'fromName'}." <".$paramHash{'from'}.">",
                To       => $paramHash{'to'},
                Subject  => $paramHash{'subject'},
                Type     => $paramHash{'mimeType'},
                Data     => $paramHash{'body'});

        #
        # add guid references
        # We loose some uniqueness - but we need to make these short so they will work with
	# all email systems.  The combined size of message and mailing id cannot be 
	# greater than 30 chars
	#
	# we will truncate the guids to 20 so they don't bust over.  In the context of this 
	# limit the replication rate should never happen because we will only have a few in the
	# queue at any given time.   And the context of this id, will only last a couple minutes
	#
	my $messageId = substr($paramHash{'guid'},0,20);
        $msg->add('X-xsMailingId' => $self->{'SocketLabs'}->{'mailingId'});
        $msg->add('X-xsMessageId' => $messageId);

        #
        # send email
        #
        eval { $msg->send('smtp',                       $self->{'SocketLabs'}->{'host'},
                                        Port      =>    $self->{'SocketLabs'}->{'port'},
                                        AuthUser  =>    $self->{'SocketLabs'}->{'username'},
                                        AuthPass  =>    $self->{'SocketLabs'}->{'password'});
        };

        my $errorCode = $@;
        if ($errorCode eq '') {
                print  "\nMESSAGE SENT TO: ".$paramHash{'to'} ."\n";
                print  "SUBJECT: ".$paramHash{'subject'} ."\n";
                print "-----------------------------------------\n";
        }
        else {
                print "ERROR: ". $errorCode."\n\n";
                $paramHash{'response'} = $errorCode;
        }

        #
        # kill the guid so we make a new record and save it to the history
        #
        my %historyHash                 = %paramHash;
        $historyHash{'queueGUID'}       = $messageId;
        $historyHash{'guid'}            = '';
        $self->saveQueueHistory(%historyHash);

        #
        # Remove this item from the Queue
        #
        $self->deleteQueue(%paramHash);
}

sub _SocketLabs_post {
        my ($self,%paramHash) = @_;

        # Connection
        my $URL = $paramHash{'url'};
        my $method = $paramHash{'method'};

        # Authentication
        my $account_id = $paramHash{'account_id'};
        my $user = $paramHash{'user'};
        my $password = $paramHash{'password'};

        # Query Params
        my $serverId            = $paramHash{'serverId'};
        my $startDate           = $paramHash{'startDate'};
        my $endDate             = $paramHash{'endDate'};
        my $timeZone            = $paramHash{'timeZone'};
        my $mailingId           = $paramHash{'mailingId'};
        my $messageId           = $paramHash{'messageId'};
        my $index               = $paramHash{'index'};
        my $count               = $paramHash{'count'};
        my $type                = $paramHash{'type'};

        #
        # Failure codes
        #
        my %failCode = (
                  1001 => "Spam complaint",
                  1002 => "Blacklist",
                  1003 => "ISP block",
                  1004 => "Content block",
                  1005 => "URL block",
                  1006 => "Excess traffic",
                  1007 => "Security violation or virus",
                  1008 => "Open relay",
                  1009 => "Namespace mining detection",
                  1010 => "Authentication",
                  1999 => "Other",
                  2001 => "Unknown user",
                  2002 => "Bad domain",
                  2003 => "Address error",
                  2004 => "Closed account",
                  2999 => "Other",
                  3001 => "Recipient mailbox full",
                  3002 => "Recipient email account is inactive or disabled",
                  3003 => "Greylist",
                  3999 => "Other",
                  4001 => "Recipient server too busy",
                  4002 => "Recipient server returned a data format error",
                  4003 => "Network error",
                  4004 => "Recipient server rejected message as too old",
                  4006 => "Recipient network or configuration error normally a relay denied",
                  4999 => "Other",
                  5001 => "Auto Reply",
                  5999 => "Other",
                  9999 => "Unknown"
        );

        #
        # Check for Important Variables
        #
        if ($account_id eq '') {        warn("Your account number has not been set"); }
        if ($user eq '') {              warn("Your authentication Username has not been set"); }
        if ($password eq '') {          warn("Your authentication Password has not been set"); }


        # Check if URL and method are set
        if ($URL eq '') { $URL = "https://api.socketlabs.com/v1"; }
        if ($method eq '') { $method = "messagesQueued"; }

        #
        # Trim Ending Backslash from URL and Method
        # so we can handle it without worrying how
        # it was passed to the sub routine
        #
        $URL    =~ s/\/$//sg;
        $method =~ s/\/$//sg;

        #
        # BUILD URL
        #
        $URL .= "/" . $method . "/?accountId=" . $account_id;

        # Check if serverId is set
        if ($serverId ne '') { $URL .= "&serverId=" . $serverId; }

        # Check if startDate is set
        if ($startDate ne '') { $URL .= "&startDate=" . $startDate; }

        # Check if endDate is set
        if ($endDate ne '') { $URL .= "&endDate=" . $endDate; }

        # Check if timeZone is set
        if ($timeZone ne '') { $URL .= "&timeZone=" . $timeZone; }

        # Check if timeZone is set
        if ($mailingId ne '') { $URL .= "&mailingId=" . $mailingId; }

        # Check if timeZone is set
        if ($messageId ne '') { $URL .= "&messageId=" . $messageId; }

        # Check if timeZone is set
        if ($index ne '') { $URL .= "&index=" . $index; }

        # Check if timeZone is set
        if ($count ne '') { $URL .= "&count=" . $count; }

        # Check if type is set
        if ($type ne '') { $URL .= "&type=" . $type; }
        else { $URL .= "&type=xml"; }

        #
        # Connect to SocketLabs
        #
        my $responseRef = $self->HTTPRequest(
                                        url      =>  $URL,
                                        user     =>  $user,
                                        password =>  $password);
        my $httpReturn = $responseRef->{'content'};

        #
        # XML to Hash
        #
        my @itemArray;
        while ($httpReturn =~ /<item>(.*?)<\/item>/g) {
                my %itemHash;

                my $itemNode = $1;

                while ($itemNode =~ /<(.*?)>(.*?)<\//g) {
                        my $key = $1;
                        my $value = $2;
                        $itemHash{$key} = $value;
                        if ($key eq 'FailureCode') { $itemHash{$key} = $failCode{$value} }
                }
	        push (@itemArray,{%itemHash});
        }

        return @itemArray;
}

=head1 AUTHOR

Nate Lewis, C<< <nlewis at gnetworks.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-fws-v2-socketlabs at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=FWS-V2-SocketLabs>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc FWS::V2::SocketLabs


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=FWS-V2-SocketLabs>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/FWS-V2-SocketLabs>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/FWS-V2-SocketLabs>

=item * Search CPAN

L<http://search.cpan.org/dist/FWS-V2-SocketLabs/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Nate Lewis.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of FWS::V2::SocketLabs
