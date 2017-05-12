
# Copyright(C) 2006 David Muir Sharnoff <muir@idiom.com>

package Mail::SendVarious;

use strict;
use warnings;
use Net::SMTP;
use IO::Pipe;
use Carp;
require Exporter;

our $VERSION = 0.4;
our @ISA = qw(Exporter);
our @EXPORT = qw(sendmail);
our @EXPORT_OK = qw($mail_error make_message @to_rejected @mail_hostlist @mail_command);

our $mail_error;
our @to_rejected;

our @mail_hostlist;
our @mail_command;

our %net_smtp_options;

@mail_hostlist = qw(127.0.0.1)
	unless @mail_hostlist;
@mail_command = qw(/usr/sbin/sendmail -oeml -i)
	unless @mail_command;


# EXAMPLE:
#
# sendmail(
#	From => 'Account Signup Form',
#	from => 'root@myhost',
#	to => 'support@myhost',
#	subject => "Account Signup: $d{owner} <$d{login}>",
#	body => $x,
#);
#

sub Daemon::Generic::Sendmail::T::TIEHASH { my $p = shift; return bless shift, $p; }
sub Daemon::Generic::Sendmail::T::FETCH { my $f = shift; return &$f(shift) }

tie our %jointo, 'Daemon::Generic::Sendmail::T', sub {
	my $to = shift;
	return join(', ', @$to) if ref($to);
	return $to;
};

sub splitto
{
	my $to = shift;
	return @$to if ref $to;
	return unless $to;
	$to =~ s/".*?"//;
	$to =~ s/[^<>,]*<(.*?)>[^<>,]/$1/g;
	return split(',',$to);
};

sub make_message
{
	my (%options) = @_;

	my $from = $options{from} || $options{envelope_from};
	$from = qq{"$options{From}" <$from>}
		if $options{From};

	my $message = '';
	if ($options{build_header} || 
		! ($options{header} 
			|| $options{message} 
			|| (defined($options{build_header}) && ! $options{build_header})))
	{
		$message .= "From: $from\n"			if $from;
		$message .= "To: $jointo{$options{to}}\n"	if $options{to};
		$message .= "Subject: $options{subject}\n"	if $options{subject};
		$message .= "Cc: $jointo{$options{cc}}\n"	if $options{cc};
		$message .= $options{xheader}			if $options{xheader};
	}

	if ($options{message}) {
		$message .= $options{message}			if $options{message};
	} else {
		$message .= $options{header}			if $options{header};
		$message .= "\n".$options{body}			if $options{body};
	}

	my @to = splitto($options{envelope_to});
	@to = (splitto($options{to}), splitto($options{cc})) unless @to;

	push(@to, splitto($options{bcc}));

	return ($from, $message, @to);
}

sub sendmail
{
	my (%options) = @_;

	@to_rejected = ();
	my @hostlist = $options{hostlist} 
		? splitto($options{hostlist})
		: @mail_hostlist;
	croak "no 'from' set" unless $options{from};

	my ($from, $message, @to) = make_message(%options);

	my $debuglog = $options{debuglogger} || sub { print STDERR "@_\n" };
	my $errorlog = $options{errorlogger} || sub { print STDERR "@_\n" };

	@hostlist = () unless @to;
	my $smtpfrom = $options{envelope_from} || $options{from};

	HOST:
	for my $host (@hostlist) {
		my @rejects;
		my $smtp;
		unless ($smtp = Net::SMTP->new($host, %net_smtp_options)) {
			error("Could not establish SMTP connection to $host: $!", $errorlog);
			next;
		}

		unless ($smtp->mail($smtpfrom)) {
			error("MAIL FROM: $smtpfrom - rejected", $errorlog);
			next;
		}
			
		for my $t (@to) {
			unless ($smtp->to($t)) {
				if ($options{no_rejects} || @to == 1) {
					error("RCPT TO: $t - rejected", $errorlog);
					next HOST;
				} else {
					push(@rejects, $t);
				}
			}
		}
		unless ($smtp->data()) {
			error("SMTP DATA - failed", $errorlog);
			next;
		}

		unless ($smtp->datasend($message)) {
			error("datasend() failed", $errorlog);
			next;
		}

		unless ($smtp->dataend()) {
			error("dataend() failed", $errorlog);
			next;
		}

		if (@rejects) {
			@to_rejected = @rejects;
			$debuglog->("Mail from $smtpfrom to @rejects rejected, other mail accepted");
		}

		$smtp->quit();

		$debuglog->("Mail from $smtpfrom to @to injected via $host");
		$mail_error = '';
		return 1;
	}

	$debuglog->("Mail from $smtpfrom to @to, falling back to sendmail");
	#
	# sending via smtp failed, try the local sendmail instead
	# 

	my @sm;
	push(@sm, "-f$options{from}") if $options{from};
	push(@sm, "-F$options{From}") if $options{From};

	@to = ('-t') unless @to;

	my @command = $options{mail_command}
		? splitto($options{mail_commnd})
		: @mail_command;


	my $MAIL;
	eval { $MAIL = open_to_child(@command, @sm, @to) } or do {
		error("Could not fork/exec child @command: $@", $errorlog);
		return 0;
	};
	(print $MAIL $message) or do {
		error("Could not write message to sendmail process: $!", $errorlog);
		return 0;
	};
	close($MAIL) or do {
		error("Could not close handle to sendmail process: $!", $errorlog);
		return 0;
	};
	$mail_error = '';
	return 1;
}

sub open_to_child
{
	my ($command, @args) = @_;
	my $pipe = IO::Pipe->new();
	$pipe->writer($command, @args);
	return $pipe;
}

sub error
{
	my ($error, $logger) = @_;
	$mail_error = $error;
	if ($logger) {
		$logger->($error);
	} else {
		print STDERR "$error\n";
	}
}

1;
