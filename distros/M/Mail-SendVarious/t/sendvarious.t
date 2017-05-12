#!/usr/bin/perl -w

use strict;
use warnings;
use FindBin;
use Test::SharedFork;
use Net::SMTP::Receive;
use Test::More tests => 29;
use File::Temp qw(tempdir);
use Mail::SendVarious;
use POSIX qw(:errno_h);
use File::Slurp;
use English;
use autodie;
use YAML;
use Time::HiRes qw(time sleep);
use Test::Deep;
use List::Util;

my $debug = 0;
my $tmp = tempdir(CLEANUP => ! $debug);
mkdir("$tmp/queue", 0777);


srand($$);
my $port;

for(;;) {
	$port = 2000 + int(rand(40000));
	my $listen = IO::Socket::INET->new(
		'LocalAddr' => '127.0.0.1',
		'LocalPort' => $port,
		'Proto' => 'tcp',
		'Reuse' => 1,
		'Listen' => 20,
	);
	last if $listen;
	BAIL_OUT("Could not bind port: $!") unless $! == EADDRINUSE;
}

pass "will listen on port $port";

my $rcpt_ok = 0;

{
	package myReceiver;

	use strict;
	use warnings;
	use File::Slurp;
	use YAML;
	use Test::More;

	$SIG{USR1} = sub { 
		pass("USR1 recevied, exiting");
		exit(0)
	};

	our @ISA = qw(Net::SMTP::Receive);

	sub queue_directory { "$tmp/queue" }

	sub ipaddr { '127.0.0.1' }

	sub port { $port }

	sub do_syslog { 0 }

	sub do_ident { 0 }

	sub log { shift; diag("N::S::R: " , sprintf(shift, @_)) if $debug }

	sub mainloop {
		my ($server, $listen) = @_;
		write_file("$tmp/server-is-live", "ha");
		$server->SUPER::mainloop($listen);
		fail("should not get here");
	}

	sub check_rcptto 
	{
		my ($self, $address) = @_;
		if ($address =~ /bad/) {
			return "500 relaying denied";
		} else {
			return 0;
		} 
	}

	sub deliver
	{
		my ($msg) = @_;
		my $body = read_file($msg->{TEXTFILE});
		like($body, qr/deliver via smtp/, "message expected");
		$msg->{delivered} = "yup";
	}

	sub is_delivered
	{
		my ($msg, $to) = @_;
		return $msg->{delivered};
	}

	sub predeliver
	{
		my ($server, $client, $msgref) = @_;
		write_file("$tmp/smtpreceived", Dump({
			BODY => $msgref,
			FROM => $server->{FROM},
			TO => $server->{TO},
			HELO => $server->{HELO},
		}));
		my $body = join("\n", @$msgref);
		die $1 if $body =~ /\nERROR: (\d\d\d .+?)\n/;
		return 0;
	}
}

my $pid = fork();

BAIL_OUT("could not fork: $!") unless defined $pid;

if (! $pid) {
	myReceiver->server();
	exit();
}

write_file("$tmp/mailcommand", <<END_MAILCOMMAND);
#!$EXECUTABLE_NAME

use YAML;
use File::Slurp;
write_file("$tmp/cmdreceived", Dump({ARGV => \\\@ARGV, BODY => [<STDIN>]}));
exit 0;
END_MAILCOMMAND

chmod 0755, "$tmp/mailcommand";

@Mail::SendVarious::mail_command =
@Mail::SendVarious::mail_command = "$tmp/mailcommand";
%Mail::SendVarious::net_smtp_options = (
	Port	=> $port,
	Timeout	=> 10,
);

my $example_header = <<'END_HEADER';
From: nouser@nomain.notreal
Subject: a test message
To: some_other_notuser@nodomain.notreal
END_HEADER

my $example_body = <<'END_BODY';
Some body lines
go here.
END_BODY

sub cleanup
{
	no autodie;
	unlink("$tmp/smtpreceived");
	unlink("$tmp/cmdreceived");
}

sub wait_until
{
	my ($max_delay, $condition, $text) = @_;
	my $start = time;
	while(! $condition->()) {
		BAIL_OUT("Waiting too long for $text") if time - $start > $max_delay;
		sleep($max_delay / 100);
	}
	pass($text);
}

sub msg
{
	my $msg;
	for my $i (qw(smtp cmd)) {
		next unless -e "$tmp/${i}received";
		$msg = Load(scalar(read_file("$tmp/${i}received")));
		last;
	}
	$msg ||= {};
	$msg->{TEXT} ||= '';
	$msg->{BODY} ||= [];
	$msg->{ARGV} ||= [];
	$msg->{FROM} ||= '';
	$msg->{TO} ||= [];
	$msg->{TEXT} = join('', @{$msg->{BODY}});
	return $msg;
}

my %common = (
	debuglogger	=> sub { diag "M::SV: @_" if $debug },
	errorlogger	=> sub { diag "M::SV: ERROR @_" if $debug },
);

wait_until(6, sub { -e "$tmp/server-is-live" }, "smtp server start");

ok(sendmail(
	%common,
	from		=> 'nouser@nodomain.notreal',
	envelope_to	=> 'some_other_notuser@nodomain.notreal',
	message		=> "$example_header\n${example_body}deliver via smtp\n",
), "first message sent");

wait_until(6, sub { -e "$tmp/smtpreceived" || -e "$tmp/cmdreceived"}, "message delivered");

ok(-e "$tmp/smtpreceived", "received via smtp");

like(msg()->{TEXT}, qr/^([^\n]+\n)+\n([^\n]+\n)+$/, "header & body");
cmp_deeply(msg()->{TO}, ['<some_other_notuser@nodomain.notreal>'], 'to');
is(msg()->{FROM}, '<nouser@nodomain.notreal>', 'from');
like(msg()->{TEXT}, qr/^([^\n]+\n)*To: some_other_notuser\@nodomain\.notreal\n/, "To:");
like(msg()->{TEXT}, qr/^([^\n]+\n)*From: nouser\@nomain.notreal\n/, "From:");
like(msg()->{TEXT}, qr/^([^\n]+\n)*Subject: a test message\n/, "Subject:");

cleanup();

ok(sendmail(
	%common,
	from		=> 'nouser@nodomain.notreal',
	envelope_to	=> 'bad_some_other_notuser@nodomain.notreal',
	message		=> "$example_header\n$example_body\n",
), "second message sent");

diag "tmp= $tmp" if $debug;

wait_until(6, sub { -e "$tmp/smtpreceived" || -e "$tmp/cmdreceived"}, "message delivered");

ok(-e "$tmp/cmdreceived", "delivered via sendmail");
like(msg()->{TEXT}, qr/^([^\n]+\n)+\n([^\n]+\n)+$/, "header & body");
like(msg()->{TEXT}, qr/^([^\n]+\n)*To: some_other_notuser\@nodomain\.notreal\n/, "To:");
like(msg()->{TEXT}, qr/^([^\n]+\n)*From: nouser\@nomain.notreal\n/, "From:");
like(msg()->{TEXT}, qr/^([^\n]+\n)*Subject: a test message\n/, "Subject:");
is(scalar(grep { $_ eq 'bad_some_other_notuser@nodomain.notreal' } @{msg()->{ARGV}}), 1, "to arg");
is(scalar(grep { $_ eq '-fnouser@nodomain.notreal' } @{msg()->{ARGV}}), 1, "from arg");

cleanup();

ok(sendmail(
	%common,
	from	=> 'nouser@nodomain.notreal',
	From	=> 'No User at No Domain',
	to	=> 'some_other_nonuser1@nodomain.notreal, Fred <some_other_nonuser2@nodomain.notreal>',
	cc	=> 'Barney <some_other_nonuser3@nodomain.notreal>',
	body	=> $example_body . "deliver via smtp\n",
), "third message sent");

wait_until(6, sub { -e "$tmp/smtpreceived" || -e "$tmp/cmdreceived"}, "message delivered");

ok(-e "$tmp/smtpreceived", "received via smtp");

diag Dump(msg()) if $debug;
my @eto = qw(<some_other_nonuser1@nodomain.notreal> <some_other_nonuser2@nodomain.notreal> <some_other_nonuser3@nodomain.notreal>);
cmp_set(msg->{TO}, \@eto, "to");
like(msg()->{TEXT}, qr/^([^\n]+\n)+\n([^\n]+\n)+$/, "header & body");

pass("killing mail receiver");
kill USR1 => $pid;

