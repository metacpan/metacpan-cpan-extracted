#!/usr/bin/perl

=head1 NAME

MailTool - Handy-dandy MIME mailing class

=head1 SYNOPSIS

 use lib some_directory, depending on where you put the .pm files
 use MailTool;
 $msg = MailTool->build (
	To => 'Justin.L.Heuser@usa.dupont.com',
	From => 'Harcourt.F.Mudd@usa.dupont.com',
	Subject => 'The check is in the mail',
	Path => standard_reply.txt,
	);
 $msg->send ();

=head1 DESCRIPTION

The MailTool class is actually a subclass of MIME::Lite. It provides
no new methods, but does 'enhance' (I hope!) some of the existing
ones. The natures of the enhancements (if enhancements they be) are:

=head2 The default send method is now smtp.

This may not be an enhancement if you're running Unix. The default
of MIME::Lite is (or was when I wrote this) to spawn SENDMAIL.

=head2 The SMTP host can be specified any number of ways.

If you are using the send method, and are in fact using SMTP (i.e. you
have not used the class send method to change the default way to send
mail), the SMTP host comes from the first thing in the following list
that is actually defined:

 The second argument of the class send method;
 The contents of environment variable SMTPHOSTS;
 The contents of smtp_hosts in Net::Config;
 The name of the host that is executing the script.

If you are calling send_by_smtp explicitly, the information specified
to the class send method is ignored (because this is consistent with
the behaviour of MIME::Lite), and the SMTP host is determined by the
first thing in the following list that is actually defined:

 The first argument passed to send_by_smtp;
 The contents of environment variable SMTPHOSTS;
 The contents of smtp_hosts in Net::Config;
 The name of the host that is executing the script.

Multiple SMTP hosts can be specified, either by passing a reference,
or by separating the names by colons (the normal way of specifying
SMTPHOSTS, which is used by Mail::Internet). If you specify multiple
hosts, they are tried in the order specified until the send succeeds
or the list of hosts is exhausted. In the latter case, an exception
is raised which describes the last error encountered.

Specifying multiple hosts while using a send method other than smtp
is unsupported.

=head2 Mailing lists are supported.

Any address element that begins with an "@" sign is assumed to be
a reference to a mailing list, with the rest of the address element
being the name of the file. This file is opened and read, and any
and all lines in the file are appended to the address list. This
functionality works for the "To", "Cc", and "Bcc" tags only.

=head2 You get an error message back if send_by_smtp fails.

This message is the first error encountered in the attempt to send
using the last host on the list.

=head1 REQUIREMENTS

The following Perl modules are required:
 Carp (standard module)
 FileHandle (standard module)
 Mail::Address (from library MailTools)
 MIME::Lite (from library MIME-lite)
 Net::Config (from library libnet)
 Net::SMTP (from library libnet)
 Sys::Hostname (standard module)

Note that these in turn can have requirements of their own. What these
requirements are is best found by reading the documentation for the
libraries themselves, but you can pretty much count on needing at least
 MIME::Base64 (from MIME-base64). On the other hand, the only known new
nonstandard requirement (over and above those of MIME::Lite) are
Mail::Address (because I was lazier than Eryq, and didn't provide a
hack to cover its absence). Truth to tell, Net::Config is also new, but
if you have Net::SMTP you should have Net::Config as well.

=over 4

=cut

package MailTool;

use strict;
use vars qw{@ISA $Debug};
use Carp;
use FileHandle;
use Mail::Address;
use MIME::Lite;
use Net::Config;
use Net::SMTP;
use Sys::Hostname;

@ISA = qw{MIME::Lite};

my %handler = (
    bcc	=> \&_map_addr,
    cc	=> \&_map_addr,
    to	=> \&_map_addr,
    );

#	Make the default method SMTP.

MailTool->send ('smtp');


=item $msg->add (tag, value)

This override of MIME::Light::add is the hook where mailing list
functionality is provided.

It looks up the tag being added in its internal hash table. If a hit
is found, both tag and value are passed to the subroutine specified
in the hash table, and the value returned is passed to SUPER::add. If
no hit is found, the pristine value is passed to SUPER::add.

In the case of the 'to', 'cc', and 'bcc' tags, the effect is to
try to expand all addresses beginning with "@" as mailing lists.
No other tags are currently munged.

=cut

sub add {
my $self = shift;
my $tag = lc(shift);
my $value = shift;
$value = &{$handler{$tag}} ($self, $tag, $value)
    if exists $handler{$tag};
$self->SUPER::add ($tag, $value);
}


=item $msg->send_by_smtp ([smtp_host])

This override of MIME::Lite's send_by_smtp method does pretty much the
same thing (it should! the code was stolen shamelessly! Thanks, Eryq!)
It has, however, the following differences:

 * More error detail (sometimes)
 * Sensitivity to a number of sources of SMTP server information:
    - Explicitly in the argument(s) to the method;
    - From environment variable SMTPHOSTS (colon-separated list);
    - From Net::Config;
    - If all else fails, use the local machine.

=cut

sub send_by_smtp {
my ($self, @args) = @_;

#	Get the SMTP hosts we're to use. We do multiple calls to
#	_get_hosts to prevent evaluating any more arguments than
#	necessary. Whether this makes any real difference, deponent
#	sayeth not.
my $host_list = _get_hosts (shift @args) ||
	_get_hosts ($ENV{SMTPHOSTS}) ||
	_get_hosts ($NetConfig{smtp_hosts}) ||
	_get_hosts (hostname ()) or
    croak "send_by_smtp: cannot determine smtp host\n";
croak "send_by_smtp: host list is empty; this should never happen.\n"
    unless @$host_list;

#	We need the "From:" and "To:" headers to pass to the
#	SMTP mailer:
my $from = $self->get('From');
my $to   = $self->get('To');

#	Sanity check:
defined($to) or croak "send_by_smtp: missing 'To:' address\n";
 	       
#	Get the destinations as a simple array of addresses.
my @to_all = map {$_->format} Mail::Address->parse ($to);

#	Duplicate the superclass' cc functionality.
if ($MIME::Lite::AUTO_CC) {
    foreach my $field (qw(Cc Bcc)) {
	my $value = $self->get($field) or next;
	push @to_all, map {$_->format} Mail::Address->parse ($value);
	}
    }

#	Try each possible host.

my ($smtp, $err);
foreach my $svr (@$host_list) {
    print STDERR "Debug send_by_smtp - Trying SMTP host $svr\n" if $Debug;
    $smtp = Net::SMTP->new ($svr, @args) or do {
	$err = "Failed to connect to mail server $svr: $!\n";
	next; };
    $smtp->mail ($from) or do {
	$err = "SMTP MAIL command to $svr failed: $!\n" .
	    $smtp->message ();
	next; };
    $smtp->to (@to_all) or do {
	$err = "SMTP RCPT command to $svr failed: $!\n" .
		$smtp->message ();
	next; };
    $smtp->data ($self->as_string ()) or do {
	$err = "SMTP DATA command to $svr failed: $!\n" .
	    $smtp->message ();
	next; };
    $smtp->quit ();
    $err = '';
    print STDERR "Debug send_by_smtp - Host $svr succeeded.\n" if $Debug;
    last;
    }
  continue {
    print STDERR "Debug send_by_smtp - Host $svr failed: $err\n" if $Debug;
    $smtp->quit () if $smtp;
    }
croak $err if $err;
1;
}


########################################################################
#
#	_get_hosts
#
#	This subroutine figures out if any of its arguments represents
#	a host specification of any sort. If so, it returns a reference
#	to the list of hosts specified by the first such argument. If
#	not, it returns undef.

sub _get_hosts {
print STDERR "Debug _get_hosts (", join (', ',
	map {ref $_ ? '[' . (join (', ', map {"'$_'"} @$_)) . ']' : "'$_'"} @_),
	")\n"
    if $Debug;
foreach (@_) {
    next unless $_;
    return [split ':', $_] unless ref $_;
    return $_ if @$_;
    }
return undef;
}

########################################################################
#
#	_map_addr
#
#	This subroutine expects the value passed in to look like a list
#	of mailing addresses. If any of the addresses looks like
#	"@xxxxx", everything except the initial "@" is assumed to be
#	the name of a file; this file is read and its records inserted
#	into the list of addressees. No attempt is made to eliminate
#	duplicates.

sub _map_addr {
my $self = shift;
my $tag = lc shift;
my $value = shift;
my $ad_in = ref $value ? $value : [$value];
my @ad_out;

foreach (@$ad_in) {
    foreach (map {$_->format} Mail::Address->parse ($_)) {
	s/^\s+//;
	s/\s+$//;
	next unless $_;
	if (m/^\@(.+)/) {
	    my $fn = $1;
	    my $fh = FileHandle->new ("<$fn") or
		croak "Error - Cannot open mailing list $fn: $!";
	    while (my $buf = $fh->getline ()) {
		chomp $buf;
		$buf =~ s/\#.*//;
		next unless $buf;
		push @$ad_in, map {$_->format} Mail::Address->parse ($buf)
		}
	    $fh->close ();
	    }
	  else {
	    push @ad_out, $_;
	    }
	}
    }
return @ad_out if wantarray;
return \@ad_out if ref $value;
return join ',', @ad_out;
}


=back

=head1 COPYRIGHT

Copyright 2001 by E. I. DuPont de Nemours and Company. All rights
reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

This software comes with no warranty whatsoever, either expressed
or implied.

=head1 AUTHOR

Tom Wyant (F<Thomas.R.Wyant-III@usa.dupont.com>), E. I. DuPont de
Nemours and Company, Inc. (F<http://www.dupont.com>, and no, you
won't find anything about this module there).

=cut

1;
