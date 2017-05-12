#!/usr/bin/perl

package Mail::DSPAM::Learning;


our $VERSION='0.1';

use strict;
use warnings;

use Mail::MboxParser;
use Mail::Builder;
use Email::Send;
use Mail::Box::Manager;
use Term::ReadKey;

use File::Basename;
use File::Path;

use Net::DNS;
use Sys::HostIP; 

use Module::TestConfig;


sub new {
    my $class = shift;

    my $learner = {
	'delay' => 5,
	'passwd' => undef,
	'mailbox' => undef,
	'mailer' => undef,
	'folder' => undef,
	'mailboxmanager' => undef,
	'config' => undef,
    };

    bless $learner, $class;
    return $learner;
}

sub defineMyConfig {
    my ($self, $path) = @_;

    if ( ! -f $path) {
	mkpath(dirname($path));

	my $domain = &_getDomain;
	my $username = "nobody";

	Module::TestConfig->new(
	    verbose   => 1,
	    defaults  => 'defaults.config',
	    file      => $path,
	    package   => 'MyConfig', # Mail::DSPAM::Learning::
	    order     => [ qw/defaults env/ ],
	    questions => [
		[ 'Domain?' => 'hello', $domain],
		[ 'User name?' => 'user', $username ],
		[ 'Email address?' => 'from', "$username\@$domain" ], # , {skip => \&setDomain }
		[ 'DSPAM email address' => 'to', "spam\@$domain" ],
		[ 'SMTP server?' => 'smtp', "mail.$domain" ],
		[ 'SMTP port?' => 'port', '25' ],
	    ]
	)->ask->save;
	return(2);
    } else {
	return(1);
    }
}

sub setMyConfig {
    my ($self) = @_;

    $self->{"config"} = MyConfig->new;
}

sub getMyConfig {
    my ($self) = @_;

    return($self->{"config"});
}

sub printMyConfig {
    my ($self) = @_;

    my $config = $self->getMyConfig;

    my @question_name = ('hello', 'user', 'from', 'to', 'smtp', 'port');

    warn "\n\n";
    warn "Current Configuration: \n";
    foreach my $q (@question_name) {
	warn "\t$q: " . $config->$q . "\n";
    }
    warn "\n";
    return(1);
}

# this method set the delay for sending a mail to learn to dspam

sub setDelay {
    my ($self, $delay) = @_;

    $self->{'delay'} = $delay;
}

# this method returns the delay for sending a mail to learn to dspam


sub getDelay {
    my ($self) = @_;

    return($self->{'delay'});
}

# this method set the password of the user for the current session

sub askPassword {
    my ($self) = @_;
    
    print "Password: ";
    ReadMode('noecho');
    $self->{'password'} = ReadLine(0);
    chomp $self->{'password'};
    ReadMode('restore');
    print "\n";
}

# this method set the mailbox file to parse. This mailbox contains the SPAN to learn

sub setMailbox {
    my ($self, $mailbox) = @_;

    $self->{'mailbox'} = $mailbox;

}

# this method returns the mailbox file which  contains the SPAN to learn

sub getMailbox {

    my ($self) = @_;

    return($self->{'mailbox'});

}

# this method set the new mailbox manager

sub setMailboxManager {

    my ($self) = @_;

    my $mgr    = Mail::Box::Manager->new;

    $self->{'mailboxmanager'} = $mgr;
}

# this method get the mailbox manager 

sub getMailboxManager {

    my ($self) = @_;


    return($self->{'mailboxmanager'});
}

# the method parses and loads the mailbox containing the SPAMs, and sets the folder field

sub parseMailbox {
    my ($self) = @_;

    my $mb = $self->getMailbox;
    if (!defined $mb) {
	die "Mailbox is not set. Exit\n";
    }

    my $mbmgr = $self->getMailboxManager;
    if (!defined $mbmgr) {
	$mbmgr = $self->setMailboxManager;
    }
    warn "Openning mailbox $mb\n";

    my $folder = $mbmgr->open(folder => $mb);
    $self->{'folder'} = $folder;

    print STDERR "folder = $folder\n";
}

# this method returns the folder field

sub getFolder {

    my ($self) = @_;

    return($self->{'folder'});

}

# This method defines the message encapsulating the forwarded message and returns it

sub forwardMessages {

    my ($self, $sending) = @_;

    my $msg;
    my $forward_msg;
    my $folder = $self->getFolder;
    my $count = 0;
    my $return_value = undef;


    my $preamble = Mail::Message::Body->new('data' => "This is a multi-part message in MIME format.");

    while ($msg = $folder->message($count)) {    # $msg is a Mail::Message now
	print STDERR "message Id = " . $msg->messageId . "\n";
	$count++;

	$forward_msg = $msg->forwardEncapsulate('To' => $self->getMyConfig->to,
						'From' => $self->getMyConfig->from,
						'Cc' => $self->getMyConfig->from,
						'Subject' => '[Fwd: ' . $msg->subject . ']',
						'preamble' => $preamble,
	    );
	print STDERR "\tSending the message ($count)\n";

	if ((!defined $sending) || ($sending > 0)) {
	    $return_value = $self->sendForwardedMessage($forward_msg);
	} else {
	    $return_value = warn($forward_msg->head);
	}

	print STDERR "done ($return_value)\n";
	print STDERR "Sleeping for " . $self->getDelay . " second\n";
	sleep($self->getDelay);
    }
    return($count);
}

# This method sets the mailer 

sub setMailer {

    my ($self) = @_;

    $self->{"mailer"} = Email::Send->new({mailer_args => [ 
						     $self->getMyConfig->smtp,
						     Port => $self->getMyConfig->port,
						     User => $self->getMyConfig->user,
						     Password => $self->{"passwd"},
						     Hello => $self->getMyConfig->hello,
						   ]
					 });
}

# This method returns the mailer 

sub getMailer {

    my ($self) = @_;

    return($self->{"mailer"});

}


# this method sends the formwarded message

sub sendForwardedMessage {

    my ($self, $forward_msg) = @_;


    return($self->{"mailer"}->send($forward_msg->string));
    
}


sub _getIP {

    my $ip_addresses = Sys::HostIP->ips;
    my $ip="127.0.0.1";
    my $i=0;
    
    while($ip_addresses->[$i] eq "127.0.0.1") {
	$i++;
    }
    
    if ($i < scalar(@$ip_addresses)) {
	$ip = $ip_addresses->[$i];
    }
    
    
    warn "IP: $ip\n";
    return($ip);
}
#

sub _getDomain {
    my $ip = &_getIP;
    my $res   = Net::DNS::Resolver->new;
    
    my $query;
    my $hostname="localhost";

    eval {
	$query = $res->search($ip);
    };
    
    if (!$@) {
	if ($query) {
	    foreach my $rr ($query->answer) {
		next unless $rr->type eq "PTR";
		print STDERR $rr->rdatastr, "\n";
		$hostname = $rr->rdatastr;
	    }
	    

	    warn "Hostname: $hostname\n";
	    
	    $hostname =~ /^([^\.]+)\.(.*)\.$/;
	    
	    my $domain = $2;
	    return ($domain);
	} else {
	    warn "query failed: ", $res->errorstring, "\n";
	    return("localdomain");
	}
    } else {
	warn "query failed: ", $res->errorstring, "\n";
	return("localdomain");
    }

}


__END__


=head1 NAME

Mail::DSPAM::Learning - Perl extension for correcting spam learning of a DPSAM server

=head1 SYNOPSIS


    use Mail::DSPAM::Learning;

    my dspam_learner = Mail::DSPAM::Learning->new();

    $dspam_learner->defineMyConfig("MyConfig.pm");
    require $MyConfigFile;
    $dspam_learner->setMyConfig;

    $dspam_learner->setMailbox("spam_mbox");

    $dspam_learner->parseMailbox();

    $dspam_learner->askPassword();

    $dspam_learner->setMailer;

    my $count = $dspam_learner->forwardMessages(!$test);


=head1 DESCRIPTION



This module aims at proposing methods to correct the spam learning of
your DSPAM server. Basically, it helps to parse a mailbox containing spams that
a DSPAM server miss, and to forward them to the DSPAM server.


=head1 METHODS

=head2 new

 new();

This method creates a new DSPAM lerner object and returns it.

=head2 defineMyConfig

 $dspamèl = defineMyConfig($path);

This method sets the filename c<$path/MyConfig.pm>. Several
information is asked to the user: domain, username, email address,
DSPAM email adress, SMTP server and port.

=head2 setMyConfig

    $dspam_l->setMyConfig;

This metho sets the user configuration of the dspam learner.

=head2 getMyConfig

    $dpsam_l->getMyConfig();

This method return the user configuration of the dspam learner.


=head2 printMyConfig

 $dspam_l->printMyConfig();

This method displays the user configuration of the dspam learner.

=head2 setDelay

    $dpsam-l->setDelay($delay);

This method set the delay (C<$delay>) for sending a mail to learn to the dspam server.

=head2 getDelay

    $dspam_l->getDelay;


This method returns the delay for sending a mail to learn to the dspam server.

=head2 

    $dspam_l->askPassword();

This method sets the password of the user for the current session

=head2 setMailbox

    $dspam_l->setMailbox;

This method set the mailbox file to parse. This mailbox contains the spam to learn.


=head2 getMailbox

    $dspam_l->getMailbox;

This method returns the mailbox file which  contains the spam to learn.


=head2 setMailboxManager

    $dspam_l->setMailboxManager;

This method sets the new mailbox manager.


=head2 getMailboxManager

    $dspam_l->getMailboxManager;

This method greturns the mailbox manager.


=head2 parseMailbox

    $dspam_l->parseMailbox;

The method parses and loads the mailbox containing the SPAMs, and sets the folder field.

=head2 getFolder

    $dspam_l->getFolder;

This method returns the folder field


=head2 forwardMessages

    $dspam_l->forwardMessages;

This method defines the message encapsulating the forwarded message
and returns it. A additional parameter can be passed to the method. It
is only useful, if its value is 0 to test the configuration without
really sending message.


=head2 setMailer

    $dpsam_l->setMailer;

This method creats and sets the mailer.


=head2 getMailer

    $dspam_l->getMailer;

This method returns the mailer.

=head2 sendForwardedMessage


    $dspam_l->sendForwardedMessage($forward_msg);

This method sends the formwarded message C<$forward_msg>.


=head1 SEE ALSO

DSPAM web site: http://dspam.nuclearelephant.com/

=head1 AUTHOR

Thierry Hamon <thierry.hamon@lipn.univ-paris13.fr>

=head1 LICENSE

Copyright (C) 2008 by Thierry Hamon

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

