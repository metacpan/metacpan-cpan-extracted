#!/usr/bin/perl -w
use strict;
use warnings;
use Config;
use Test::More;
$ENV{MAILDOMAIN}='example.com';
my $can_fork = $Config{d_fork} || $Config{d_pseudofork} ||
		(($^O eq 'MSWin32' || $^O eq 'NetWare') and
		$Config{useithreads} and 
		$Config{ccflags} =~ /-DPERL_IMPLICIT_SYS/);
if ($can_fork) {
	plan tests => 9;
}
else {
	plan skip_all => 'This system cannot fork';
}

use MIME::Tools;
use MIME::Entity;

use IO::Socket::INET;

# Listen on port 5225 to pretend to be an SMTP server
my $sock = IO::Socket::INET->new(Listen => 5,
				 LocalAddr => 'localhost:5225',
				 ReuseAddr => 1,
				 Type => SOCK_STREAM,
				 Timeout => 10,
				 Proto => 'tcp');

die("can't create socket: $!") unless $sock;

my $top = MIME::Entity->build(
	Type    => 'multipart/mixed',
	From    => 'devnull@roaringpenguin.com',
	To      => 'devnull@roaringpenguin.com',
	Subject => 'smtpsend test');
$top->attach(
	Data    => 'plain',
	Type    => 'text/plain');

my $pid = fork();
if (!defined($pid)) {
	die("fork() failed: $!");
}

if (!$pid) {
	# In the child
	sleep(1);
	$top->smtpsend(Host => '127.0.0.1',
		       Port => 5225);
	exit(0);
}

# In the parent
my $s = $sock->accept();
if (!$s) {
	sleep(1);
	$s = $sock->accept();
	if (!$s) {
		kill(9, $pid);
		die("accept failed: $!");
	}
}

$s->print("220 Go ahead\n");
$s->flush();
my $line = $s->getline();
like($line, qr/^EHLO/i);
$s->print("220 Hi there\n");
$s->flush();

$line = $s->getline();
like($line, qr/^MAIL/i);
$s->print("220 OK\n");
$s->flush();

$line = $s->getline();
like($line, qr/^RCPT/i);
$s->print("220 OK\n");
$s->flush();

$line = $s->getline();
like($line, qr/^DATA/i);
$s->print("311 Send it\n");
$s->flush();

my $body = '';
while(<$s>) {
	last if ($_ =~ /^\./);
	$body .= $_;
}

$s->print("220 Got it all; thanks\n");
$s->flush();

$line = $s->getline();
like($line, qr/^QUIT/i);
$s->print("220 See ya\n");
$s->flush();
$s->close();

my @lines = split("\n", $body);

# Get the end of headers
while($lines[0] ne "\r") {
	shift(@lines);
}
shift(@lines);

is(scalar(@lines), 9);
is($lines[0], "This is a multi-part message in MIME format...\r");
is($lines[3], "Content-Type: text/plain\r");
is($lines[7], "plain\r");


