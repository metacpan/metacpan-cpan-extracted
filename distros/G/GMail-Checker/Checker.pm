package GMail::Checker;

# Perl interface for a gmail wrapper
# Allows you to check new mails, retrieving new mails and information about them

# $Id: Checker.pm,v 1.04 2004/12/13 22:52:17 sacred Exp $

use strict;
use IO::Socket::SSL;
use Carp;
use vars qw($VERSION);

$VERSION = 1.04;

sub version { sprintf("%f", $VERSION); }

sub new {
    my $self = {};
    my $proto = shift;
    my %params = @_;
    $self->{SOCK} = undef;
    $self->{NBMSG} = 0;
    $self->{USERNAME} = '';
    $self->{PASSWORD} = '';
    my $class = ref($proto) || $proto;
    bless($self,$class);
    $self->login($params{"USERNAME"}, $params{"PASSWORD"}) if ((exists $params{"USERNAME"}) and (exists $params{"PASSWORD"}));
    return $self;
}

sub DESTROY {
    my $self = shift;
    if (defined $self->{SOCK}) { $self->{SOCK}->close(); }
}

sub getsize { # Formatting the mail[box] size in a pretty manner
    my $self = shift;
    my $size = shift;
    $size /= 1024;
    my $unit = "Kbytes";
    ($size, $unit) = ($size/1024, "Mbytes") if (($size / 1024) > 1) ;
    return ($size, $unit);
}

sub login {
    my $self = shift;
    my ($login, $passwd) = @_;
    my $not = new IO::Socket::SSL "pop.gmail.com:995" or die IO::Socket::SSL->errstr();
    $self->{SOCK} = $not;
    my $line = <$not>; # Reading the welcome message
    print $not "USER $login\r\n";
    $line = <$not>;
    if ($line !~ /^\+OK/) { print "Wrong username, please check your settings.\n"; $self->close(); } # We are not allowing USER on transaction state.
    print $not "PASS $passwd\r\n";
    $line = <$not>;
    if ($line !~ /^\+OK/) { print "Wrong password, please check your settings.\n"; $self->close(); } # Same as above for PASS.
    $self->{USERNAME} = $login;
    $self->{PASSWORD} = $passwd;
    return 1;
}

sub get_msg_nb_size {
    my $self = shift;
    if (defined $self->{SOCK}) {
	my $gsocket = $self->{SOCK};
	print $gsocket "STAT\r\n";
	my $gans = <$gsocket>;
	unless ($gans !~ /^\+OK\s(\d+)\s(\d+)(\s.*)?\r\n/) {
	    return ($1,$2); # Sending the number of messages and the size of the mailbox 
	}
    } else { croak "Operation failed, connection to server is not established.\n"; }
}

sub get_pretty_nb_messages {
    my $self = shift;
    my %params = @_;
    $params{"ALERT"} = "TOTAL_MSG" unless exists $params{"ALERT"}; # Making sure we have an alert type.
    if (defined $self->{SOCK}) {
	my $gsocket = $self->{SOCK};
	print $gsocket "STAT\r\n";
	my $gans = <$gsocket>;
	unless ($gans !~ /^\+OK\s(\d+)\s(\d+)(\s.*)?\r\n/) {
	    if ($params{"ALERT"} eq "NEW_MSG_ONLY") {
		if ($1 > $self->{NBMSG}) {
		    return sprintf "You have %d new messages.\n", $1 - $self->{NBMSG};
		}
	    }
	    $self->{NBMSG} = $1;
	    return sprintf "You have $1 messages in your inbox (size %0.2f %s)\n", $self->getsize($2) unless $params{"ALERT"} eq "NEW_MSG_ONLY";
	}
    } else { croak "Operation failed, connection to server is not established.\n"; }
}

sub get_msg_size {
    my $self = shift;
    my %params = @_;
    if (defined $self->{SOCK}) {
	my (@msg_size, $gans);
	my $gsocket = $self->{SOCK};
	if (exists $params{"MSG"}) {
	    print $gsocket "LIST " . $params{"MSG"} . "\r\n";
	    $gans = <$gsocket>;
	    if ($gans =~ /^\+OK\s(\d+)\s(\d+)/) {
		($msg_size[0]->{nb}, $msg_size[0]->{size}) = ($1, $2);
		return @msg_size;
	    } else { print "No such message number.\r\n"; }
	} else {
	    print $gsocket "LIST\r\n";
	    my $i = 0;
	    for ($gans = <$gsocket>; $gans ne ".\r\n"; $gans = <$gsocket>) {
		if ($gans =~ /^(\d+)\s(\d+)/) {
		    ($msg_size[$i]->{nb}, $msg_size[$i]->{size}) = ($1, $2);
		    $i++;
		}
	    }
	    ($msg_size[0]->{nb}, $msg_size[0]->{size}) = (-1,-1) if $i == 0; # Mailbox is empty
	    return @msg_size;
	}
    }
}

sub parse_plain_msg {
    my $self = shift;
    my ($gsocket, $msgl) = ($self->{SOCK}, "");
    for (my $gans = <$gsocket>; $gans ne ".\r\n"; $gans = <$gsocket>) { 
	$msgl .= $gans; 
    }
    return $msgl;
}

sub msg_to_file {
    my $self = shift;
    my $ind = shift;
    my $gsocket = $self->{SOCK};
    print $gsocket "RETR $ind\r\n";
    my $gans = "";
    my @uidl = $self->get_uidl(MSG => $ind);
    open(MAILFILE, ">" .  $uidl[0]->{hash});
    while ($gans ne ".\r\n") {
	$gans = <$gsocket>;
	print MAILFILE $gans;
    }
    close(MAILFILE);
}

sub parse_multipart_msg {
    my $self = shift;
    my ($gsocket, $msgl, $gans) = ($self->{SOCK}, "", "");
    my %msgs = @_;
    my @attachments = undef;
    my ($content, $opt, $opttype, $encoding, $filename) =  (undef, undef, undef, undef, undef);
    my $boundary = $msgs{opt};
    while ($gans !~ /^--$boundary/) { $gans = <$gsocket>; }
    
    # Retrieving the message body [inline text].
    while ($gans ne "\r\n") {
	$gans = <$gsocket>;
	if ($gans =~ /^Content-Type: ([a-z0-9\/-]+);\s?(?:([a-z0-9-]+)=\"?([a-z0-9._=-]+)\"?)?\r\n/i) {
	    $content = $1;
	    if (!defined $2) {
		$gans = <$gsocket>;
		$gans =~ /\s+([a-z0-9-]+)=\"?([a-z0-9._=-]+)\"?\r\n/i;
		$opt = $2;
		$opttype = $1;
	    } else { $opt = $3; $opttype = $2; } # Content options (eg. name, charset)
	}
	if ($gans =~ /^Content-Transfer-Encoding: (7bit|8bit|binary|base64|quote-printable|ietf-token|x-token)\r\n/i) { 
	    $encoding = $1;
	}
    }
    do {
	$gans = <$gsocket>;
	$msgs{body} .= $gans unless $gans =~ /^--$boundary/;
    } while (($gans ne ".\r\n") && ($gans !~ /^--$boundary/i));
    $msgs{contentmsg} = $content;
    $msgs{optmsg} = $opt;
    $msgs{opttypemsg} = $opttype;
    $msgs{encoding} = $encoding;
    
    # Retrieving attachements.

    for (my $i = -1; $gans ne ".\r\n";) {
	if ($gans =~ /^--$boundary/) {
	    $i++;
	    ($content, $opt, $opttype, $encoding, $filename) =  ("","","","","");
	    $gans = <$gsocket>;
	    while ($gans !~ /^(?:--$boundary|\.\r\n)/) {
		if ($gans =~ /^Content-Type: ([a-z0-9\/-]+);\s?(?:([a-z0-9-]+)=\"?([a-z0-9._=-]+)\"?)?\r\n/i) {
		    $content = $1;
		    if (!defined $2) {
			$gans = <$gsocket>;
			$gans =~ /\s+([a-z0-9-]+)=\"?([a-z0-9._=-]+)\"?\r\n/i;
			$opt = $2;
			$opttype = $1;
		    } else { $opt = $3; $opttype = $2; } # Content options (eg. name, charset)
		}
		if ($gans =~ /^Content-Transfer-Encoding: (7bit|8bit|binary|base64|quote-printable|ietf-token|x-token)\r\n/i) { 
		    $encoding = $1;
		} 
		if ($gans =~ /^Content-Disposition: ([a-z]+);(?:\s+filename=\"?(\S+)\"?)?/) {
		    if ($1 eq "attachment") {
			if (!defined $2) {
			    $gans = <$gsocket>;
			    ($attachments[$i]->{filename}) = $gans =~ /\s+filename=\"?(\S+)\"?/;
			} else {$attachments[$i]->{filename} = $3; }
			while ($gans ne "\r\n") {
			    $gans = <$gsocket>;
			    if ($gans =~ /^\s+$/) { next; }
			    $attachments[$i]->{body} .= $gans;
			}
			$attachments[$i]->{content} = $content;
			$attachments[$i]->{opt} = $opt;
			$attachments[$i]->{opttype} = $opttype;
			$attachments[$i]->{encoding} = $encoding;
			$gans = <$gsocket>;
			last;
		    }
		}
		$gans = <$gsocket>;
	    }
	}
	if ($gans !~ /^(--$boundary|\.\r\n)/i) { $gans = <$gsocket>;}
    }
    if (@attachments != 0) { $msgs{attachment} = @attachments; }
    return %msgs;
}

sub parse_msg {
    my $self = shift;
    my $ind = shift;
    my %msgs;
    my $gsocket = $self->{SOCK};
    print $gsocket "RETR $ind\r\n";
    my ($msgl, $msgtype) = ("", 0);
    my $gans = <$gsocket>;
    if ($gans =~ /^\+OK\s/) {
	do { # Getting the message headers
	    $gans = <$gsocket>;
	    $msgl .= $gans  if $gans =~ /^([A-Z][a-zA-Z0-9-]+:\s+|\t)/;
	    if ($gans =~ /^Content-Type: ([a-z0-9\/-]+);\s?(?:([a-z0-9-]+)=\"?([a-z0-9._=-]+)\"?)?\r\n/i) {
		$msgs{content} = $1;
		if ($msgs{content} =~ /^multipart\/mixed/i) { $msgtype = 1; } # Mail content
		if (!defined $2) {
		    $msgl .= $gans = <$gsocket>;
		    $gans =~ /\s+([a-z0-9-]+)=\"?([a-z0-9._=-]+)\"?\r\n/i;
		    $msgs{opt} = $2;
		    $msgs{opttype} = $1;
		} else { $msgs{opt} = $3; $msgs{opttype} = $2; } # Content options (eg. name, charset)
	    }
	    # We need to know the encoding type
	    if ($gans =~ /^Content-Type-Encoding: (7bit|8bit|binary|base64|quote-printable|ietf-token|x-token)\r\n/i) { $msgs{encoding} = $1; } 
	} while ($gans ne "\r\n");
	$msgs{headers} = $msgl;
	$msgl = "";
	if (!$msgtype) { $msgs{body} = $self->parse_plain_msg(); } else { %msgs = $self->parse_multipart_msg(%msgs); }
	return %msgs;
    } else { print "No such message number (" .  $ind  .").\r\n"; }
}

sub get_msg {
    my $self = shift;
    my %params = @_;
    if (defined $self->{SOCK}) {
	my (@msgs, $gans);
	my $gsocket = $self->{SOCK};
	if (exists $params{"MSG"}) {
	    my %tmp = $self->parse_msg($params{"MSG"});
	    push(@msgs, \%tmp);
	    print $gsocket "DELE " . $params{"MSG"} . "\r\n" if exists $params{"DELETE"};
	} else {
	    my $total = shift(@{ $self->get_msg_nb_size() } );
	    for (my $ind = 1; $ind < $total; $ind++) {
		my %tmp = $self->parse_msg($ind);
		push(@msgs, \%tmp);
		print $gsocket "DELE $ind\r\n" if exists $params{"DELETE"};
	    }
	}
	return @msgs;
    }
}

sub get_msg_headers {
    my $self = shift;
    my %params = @_;
    $params{"HEADERS"} = "MINIMAL" unless exists $params{"HEADERS"}; # Making sure we have headers type for retrieval.
    my $headregx = ($params{"HEADERS"} eq "FULL") ? '^([A-Z][a-zA-Z0-9-]+:\s+|\t)' : '^(From|Subject|Date):\s+'; # Headers regexp
    my @messages = [];
    if (defined $self->{SOCK}) {
	my $gsocket = $self->{SOCK};
	my ($lastmsg, $gans) = (undef, undef);
	if (!exists $params{"MSG"}) {  # By default we get the last message's headers.
	    print $gsocket "STAT\r\n";
	    $gans = <$gsocket>;
	    if ($gans =~ /^\+OK\s(\d+)\s\d+(\s.*)?\r\n/) {
		$lastmsg = $1;
	    } 
	} else { # Did we specify a message for which we want headers ? 
	    $lastmsg = $params{"MSG"};
	}
	print $gsocket "TOP $lastmsg 1\r\n";
	$gans = <$gsocket>;
	if ($gans =~ /^\+OK/) {
	    do {
		$gans = <$gsocket>;
		push(@messages, $gans)  if $gans =~ /$headregx/;
	    } while ($gans ne "\r\n");

	} else { print "No such message number.\r\n"; } # Duh! We received an -ERR
	return @messages;
    } else { croak "Operation failed, socket is not open.\n"; }
}

sub get_uidl {
      my $self = shift;
      my %params = @_;
   if (defined $self->{SOCK}) {
	my (@uidls, $gans);
	my $gsocket = $self->{SOCK};
	if (exists $params{"MSG"}) {
	    print $gsocket "UIDL " . $params{"MSG"} . "\r\n";
	    $gans = <$gsocket>;
	    if ($gans =~ /^\+OK\s\d+\s<([\x21-\x7E]+)>\r\n/) { return $1; } else {  print "No such message number (" .  $params{"MSG"}  .").\r\n"; return -1;}
	} else { 
	    print $gsocket "UIDL\r\n";
	    my $i = 0;
	    for ($gans = <$gsocket>; $gans ne ".\r\n"; $gans = <$gsocket>) {
		if ($gans =~ /^(\d+)\s<([\x21-\x7E]+)>\r\n/) {
		    ($uidls[$i]->{nb}, $uidls[$i]->{hash}) = ($1, $2);
		    $i++;
		}
	    }
	    ($uidls[0]->{nb}, $uidls[0]->{hash}) = (-1,-1) if $i == 0;
	    return @uidls;
	}
    } else { croak "Operation failed, socket is not open.\n"; }
}

sub rset {
    my $self = shift;
    if (defined $self->{SOCK}) {
	my $gsocket = $self->{SOCK};
	print $gsocket "RSET\r\n";
	my $gans = <$gsocket>;
	return $gans;
    } else { croak "Operation failed, socket is not open.\n"; }
}

sub close {
    my $self = shift;
    if (defined $self->{SOCK}) { 
	my $gsocket = $self->{SOCK};	    
	print $gsocket "QUIT\r\n"; # Sending a proper quit to the server so it can make an UPDATE in case DELE requests were sent.
	$gsocket->close(SSL_ctx_free => 1); # Freeing the connection context
	$self->{SOCK} = undef;
	return 1;
    } else { croak "Operation failed, socket is not open.\n"; }
}


__END__

=head1 NAME

GMail::Checker - Wrapper for Gmail accounts

=head1 VERSION

1.04

=head1 SYNOPSIS

    use GMail::Checker;

    my $gwrapper = new GMail::Checker();
    my $gwrapper = new GMail::Checker(USERNAME => "username", PASSWORD => "password");

    # Let's log into our account (using SSL)
    $gwrapper->login("username","password");

    # Get the number of messages in the maildrop & their total size
    my ($nb, $size) = $gwrapper->get_msg_nb_size();

    # Do we have new messages ?
    my $alert =  $gwrapper->get_pretty_nb_messages(ALERT => "TOTAL_MSG");

    # Get the headers for a specific message (defaults to last message)
    my @headers = $gwrapper->get_msg_headers(HEADERS => "FULL", MSG => 74);

    # Get a message size
    my ($msgnb, $msgsize) = $gwrapper->get_msg_size(MSG => 42);

    # Retrieve a specific message
    my @msg = $gwrapper->get_msg(MSG => 23);
    print $msg[0]->{content}, "\n";
    print $msg[0]->{body};

    # Retrieve UIDL for a message
    my @uidl = $gwrapper->get_uidl(MSG => 10);
    
=head1 DESCRIPTION

This module provides a wrapper that allows you to perform major operations on your gmail account.

You may create a notifier to know about new incoming messages, get information about a specific e-mail,

retrieve your mails using the POP3 via SSL interface.

=head1 METHODS

The implemented methods are :

=over 4

=item C<new>


Creates the wrapper object.

The L<IO::Socket::SSL> object is stored as $object->{SOCK}.

It currently only accepts username and password as hash options.

=over 4

=item C<USERNAME>

Your GMail account username (without @gmail.com).

=item C<PASSWORD>

Your GMail password.

=back 4

Returns 1 if login is successfull otherwise it closes connection.

We are not allowing USER and PASS on transaction state.

=item C<get_msg_nb_size>


This method checks your maildrop for the number of messages it actually contains and their total size.

It returns an array which consists of (nb_of_msgs, total_size).

Example :

    my ($msgnb, $size) = $gwrapper->get_msg_nb_size();
    or my @maildrop = $gwrapper->get_msg_nb_size();

=item C<get_pretty_nb_messages>


Alerts you when you have new mails in your mailbox.

It takes as a hash argument C<ALERT> which can have two values :

=over 4

=item C<NEW_MSG_ONLY> 

Gives you only the number of new messages that have arrived in your mailbox since the last check.

=item C<TOTAL_MSG> 

Gives you the total number of messages and the actual size of the mailbox prettily formatted.

=back 4

Returns a formatted string.

=item C<get_msg_size>


This methods retrieves the messages size.

By default, it will return an array containing all the messages with message number and its size.

Given the hash argument C<MSG>, size information will be returned for that message only.

Returns (-1,-1) if the mailbox is empty.

Example :

    my @msg_sizes = $gwrapper->get_msg_size();
    foreach $a (@msg_sizes) { printf "Message number %d - size : %d", $a->{nb}, $a->{size}; }
    my @specific_msg_size = $gwrapper->get_msg_size(MSG => 2);
    printf "Message number %d - size : %d", $specific_msg_size[0]->{nb}, $specific_msg_size[0]->{size};

=item C<get_msg>


Retrieves a message from your mailbox and returns it as an array of hash references [you will need to dereference it].

If no message number is specified, it will retrieve all the mails in the mailbox.

Returns an empty array if there is no message matching the request or mailbox is empty.

The method accepts as hash arguments :

=over 4

=item C<MSG> 

The message number

=item C<DELETE> 

Deletes the message from the server (do not specify it at all if you want to keep your mail on the server)

=back 4

By default the messages are kept in the mailbox.

Do not forget to specify what happens to the mails that have been popped in your Gmail account settings.

The array contains for each element these properties :

=over 4

=item C<headers>

The mail headers.

=item C<body>

The mail body containing the message in case of a multipart message or the entire body if Content-Type holds something else.

=item C<content>

The content type

=item <opttype>

The option type for the content-type (charset, file name...)

=item C<opt>

The option value

=item C<encoding>

The message encoding type

=back 4

In case we have multipart/mixed messages we also have :

=over 4

=item C<contentmsg>

The message Content-Type.

=item C<opttypemsg>

Same as opttype for the message, usually charset.

=item C<optmsg>

opttypemsg value (e.g. us-ascii).

=item C<attachment>

This is an array of hash references containing all the files attached to the message.
They have the same options as above (body, content, encoding, opt, opttype).

=back 4

Example :

    my @msg = $gwrapper->get_msg(MSG => 2, DELETE => 1);
    print $msg[0]->{headers}, $msg[0]->{body};

In case all messages are returned, just loop over the array to get them.

=item C<get_msg_headers>


Retrieves a message header and returns them as an array (one header item per line).

If no message number is specified, the last message headers will be retrieved.

The function takes two possible arguments as hashes

=over 4

=item C<MSG> 

The message number

=item C<HEADERS>

Takes two values, I<FULL> for full headers and I<MINIMAL> for From, Subject and Date only.

=back 4

Returns an I<empty array> if there is no message matching the request or mailbox is empty.

Example :

    my @headers = $gwrapper->get_msg_headers(HEADERS => "FULL", MSG => 3);
    foreach $h (@headers) { print $h; }

=item C<get_uidl>


Gets messages UIDL (unique-Id [hash] attributed to the message by the server).

Takes as a hash argument the MSG number or retrieves the UIDLs for all the messages.

I<Returns (-1,-1) if the mailbox is empty>.

Example :

    my @uidls = $gwrapper->get_uidl();
    foreach $uid (@uidls) { print $uid->{nb}, " ", $uid->{hash}; }
    my $spec_uid = $gwrapper->get_uidl(MSG => 1);

=item C<msg_to_file>

Writes takes as argument the message number and writes it to the current directory to a file which name is the msg's uidl.

    $gwrapper->msg_to_file(1);

=item C<rset>


If any messages have been marked as deleted by the POP3 server, they are unmarked.

=item C<close>


Closes the connection after sending a QUIT command so the server properly switches to the UPDATE state.

It doesn't take any argument for now.

=back 4

=head1 COPYRIGHT

Copyright 2004 by Faycal Chraibi. All rights reserved.

This library is a free software. You can redistribute it and/or modify it under the same terms as Perl itself.

=head1 AUTHOR

Faycal Chraibi <fays@cpan.org>

=head1 TODO

- Include charsets conversions support

- Send mails

- Search through mails body and headers

- Include mail storing/reading option

- Headers regexp argument for headers retrieval

- Correct bugs ?

=head1 SEE ALSO

L<IO::Socket::SSL>, L<WWW::GMail>

