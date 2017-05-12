# -*- perl -*-
#
#   HTML::EP	- A Perl based HTML extension.
#
#
#   Copyright (C) 1998    Jochen Wiedmann
#                         Am Eisteich 9
#                         72555 Metzingen
#                         Germany
#
#                         Phone: +49 7123 14887
#                         Email: joe@ispsoft.de
#
#   All rights reserved.
#
#   You may distribute this module under the terms of either
#   the GNU General Public License or the Artistic License, as
#   specified in the Perl README file.
#
############################################################################

require 5.004;
use strict;

use HTML::EP ();
use HTML::EP::Locale ();
use Mail::POP3Client ();


package HTML::EP::Examples::POP3Client;

$HTML::EP::Examples::POP3Client::VERSION = '0.01';
@HTML::EP::Examples::POP3Client::ISA = qw(HTML::EP::Locale HTML::EP);


sub _init {
    my $self = shift;  my $attr = shift;
    my $debug = $self->{'debug'};
    my $cgi = $self->{'cgi'};
    my $server = $self->{'pop3server'} =
	    ($attr->{'pop3server'}  or  $cgi->param('pop3server'))
		or die "Missing POP3 server";
    my $user = $self->{'pop3user'} =
	    ($attr->{'pop3user'}  or  $cgi->param('pop3user'))
		or die "Missing POP3 user";
    my $password = $self->{'pop3password'} =
	    ($attr->{'pop3password'}  or  $cgi->param('pop3password'))
		or die "Missing POP3 password";

    my $port;
    if ($server =~ /(.*)\:(.*)/) {
	$server = $1;
	$port = $2;
    }
    my @args = ($user, $password, $server);
    push(@args, $port) if defined($port) or $debug;
    push(@args, 1) if $debug;

    $self->printf("Connecting to server %s, port %s as user %s\n",
		  $server, ($port || 110), $user) if $debug;

    Mail::POP3Client->new(@args) or die "Failed to connect: $!";
}


sub _ep_examples_pop3client_list {
    my $self = shift;  my $attr = shift;
    my $pop = $self->_init($attr);
    my $cgi = $self->{'cgi'};
    my $start = $self->{'start'} = $cgi->param('start') || 0;
    my $max = $self->{'max'} = $attr->{'max'} || $cgi->param('max') || 20;
    my $debug = $self->{'debug'};

    my @sizes = map { $_ =~ s/^\d+\s+//; $_ } $pop->List();
    my @list;
    $self->{'count'} = $pop->Count();
    $self->{'next'} = $start+$max if $start+$max < $self->{'count'};
    $self->{'prev'} = $start-$max if $start>0;
    for (my $i = $start;  $i < $pop->Count()  &&  $i < $start+$max;  $i++) {
	my($subject, $from, $id, $date);
	foreach my $head ($pop->Head($i+1)) {
	    if ($head =~ /^\s*subject\:\s*(.*?)\s*$/i) {
		$subject = $1;
	    } elsif ($head =~ /^\s*reply-to\:\s*(.*?)\s*$/i) {
		$from = $1;
	    } elsif ($head =~ /^\s*from\:\s*(.*?)\s*$/i) {
		$from = $1 unless $from;
	    } elsif ($head =~ /^\s*message-id\:\s*(.*?)\s*$/i) {
		$id = $1;
	    } elsif ($head =~ /^\s*date\:\s*(.*?)\s*$/i) {
		$date = $1;
	    }
	}
	my $mail = {'from' => ($from || ''),
		    'subject' => ($subject || ''),
		    'size' => $sizes[$i],
		    'nr' => $i+1,
		    'i' => $i,
		    'date' => $date,
		    'id' => $id};
	$self->print("Found mail: ", %$mail, "\n") if $debug;
	push(@list, $mail);
    }
    $self->{'list'} = \@list;
    $self->{'list_num'} = @list;

    $self->print("$self->{'list_num'} items have been found.\n") if $debug;
    '';
}


sub _ep_examples_pop3client_delete {
    my $self = shift;  my $attr = shift;
    my $pop = $self->_init($attr);
    my $cgi = $self->{'cgi'};
    my $debug = $self->{'debug'};
    my $count = $self->{'count'} = $pop->Count();
    my $id = $cgi->param('id') or die "Missing Message ID";
    my $i = $cgi->param('i');

    # Verify the message ID
    foreach my $head ($pop->Head($i+1)) {
	if ($head =~ /^\s*message-id\:\s*(.*?)\s*$/i) {
	    die "Mailfolder out of sync. Please reload folder."
		unless ($1 eq $id);
	    $pop->Delete($i+1);
	    $pop->Close();
	    if ($i >= $self->{'count'}  and  $i > 0) {
		--$i;
	    }
	    my $max = $self->{'max'} =
		$attr->{'max'} || $cgi->param('max') || 20;
	    $self->{'start'} = ($i % $max);
	    return '';
	}
    }
    die "Cannot delete message without Message-ID";
}


sub _ep_examples_pop3client_show {
    my $self = shift;  my $attr = shift;
    my $pop = $self->_init($attr);
    my $cgi = $self->{'cgi'};
    my $debug = $self->{'debug'};

    $self->{'count'} = $pop->Count();
    my $id = $cgi->param('id') or die "Missing Message ID";
    my $i = $cgi->param('i');
    if ($cgi->param('back')) {
	die "No previous mails" if --$i < 0;
	$id = 'any';
    } elsif ($cgi->param('next')) {
	die "No further mails" if ++$i >= $self->{'count'};
	$id = 'any';
    }
    $self->{'num'} = $i+1;
    $self->{'i'} = $i;
    $self->{'id'} = $id;
    die "Missing Message number" if !defined($i) || $i !~ /^\s*\d+\s*$/;

    my($subject, $from, $date);
    my @headers;
    foreach my $head ($pop->Head($i+1)) {
	push(@headers, $head);
	if ($head =~ /^\s*subject\:\s*(.*?)\s*$/i) {
	    $subject = $1;
	} elsif ($head =~ /^\s*reply-to\:\s*(.*?)\s*$/i) {
	    $from = $1;
	} elsif ($head =~ /^\s*from\:\s*(.*?)\s*$/i) {
	    $from = $1 unless $from;
	} elsif ($head =~ /^\s*date\:\s*(.*?)\s*$/i) {
	    $date = $1;
	} elsif ($head =~ /^\s*message-id\:\s*(.*?)\s*$/i) {
	    die "Mailfolder out of sync. Please reload folder."
		unless ($id eq 'any'  or  $1 eq $id);
	    $self->{'id'} = $1;
	}
    }

    $self->{'body'} = join("\n", $pop->Body($i+1));
    $self->{'headers'} = join("\n", @headers);
    $self->{'from'} = $from;
    $self->{'date'} = $date;
    $self->{'subject'} = $subject;
    '';
}


sub _ep_examples_pop3client_reply {
    my $self = shift;  my $attr = shift;
    my $pop = $self->_init($attr);
    my $cgi = $self->{'cgi'};
    my $debug = $self->{'debug'};
    my $count = $self->{'count'} = $pop->Count();
    my $id = $cgi->param('id') or die "Missing Message ID";
    my $i = $cgi->param('i');

    # Verify the message ID
    my($subject, $date, $from, $to, $cc);
    foreach my $head ($pop->Head($i+1)) {
	if ($head =~ /^message-id\:\s*(.*?)\s*$/i) {
	    die "Mailfolder out of sync. Please reload folder."
		unless ($1 eq $id);
	} elsif ($head =~ /^reply-to\:\s*(.*?)\s*$/i) {
	    $from = $1;
	} elsif ($head =~ /^from\:\s*(.*?)\s*$/i) {
	    $from = $1 unless $from;
	} elsif ($head =~ /^date\:\s*(.*?)\s*$/i) {
	    $date = $1;
	} elsif ($head =~ /^to\:\s*(.*?)\s*$/i) {
	    $to = $1;
	} elsif ($head =~ /^cc\:\s*(.*?)\s*$/i) {
	    $cc = $1;
	} elsif ($head =~ /^subject\:\s*(.*?)\s*$/i) {
	    $subject = $1;
	}
    }

    $self->{'date'} = $date;
    $self->{'from'} = $from;
    $self->{'to'} = $to;
    $self->{'cc'} = $cc ? $to : "$to, $cc";
    $subject =~ s/^(re|aw)\:\s+// if $subject;
    $self->{'subject'} = "Re: $subject";
    my $indent = $attr->{'indent'} || "> ";
    $self->{'body'} = join("\n", map{ "$indent$_" } $pop->Body($i+1));

    '';
}


sub _format_HNBSP {
    my $self = shift;  my $str = shift;
    return '&nbsp;' if !defined($str) || $str eq '';
    $self->escapeHTML($str);
}

sub _format_BR {
    my $self = shift;  my $str = shift;
    return '' unless defined($str);
    join("<BR>\n",
	 map { $self->escapeHTML($_) } split(/\r?\n/s, $str));
}

1;
