#!/usr/bin/env perl
#
# from_domain, the arguments log_send understands, the privacy of the helpers,
# and a sendmail that refuses a message without reading it.  All of it is
# behaviour the POD describes; none of it needs a key or the network.

use strict;
use warnings;

use Test::Most;

use File::Spec;
use File::Temp qw(tempdir);
use FindBin qw($Bin);

use lib File::Spec->catdir($Bin, File::Spec->updir(), 'lib');
use Mail::Send::DKIM;

my $dkim = Mail::Send::DKIM->new('domains' => 'example.org', 'keydir' => '/nonexistent');

subtest 'from_domain reads the domain of the first From: address' => sub {
	my @cases = (
		['bare address' => "From: a\@Example.ORG\n\nbody\n", 'example.org'],
		['display name' => "From: Alerts <a\@example.org>\n\nbody\n", 'example.org'],
		['quoted display name holding an @' => "From: \"x\@evil.com\" <a\@example.org>\n\nb\n", 'example.org'],
		['trailing comment holding an @' => "From: a\@example.org (c\@evil.net)\n\nb\n", 'example.org'],
		['folded header' => "From: Alerts\n <a\@example.org>\n\nb\n", 'example.org'],
		['CRLF line endings' => "From: a\@example.org\r\nTo: b\r\n\r\nb\r\n", 'example.org'],
		['first of two From: headers' => "From: a\@example.org\nFrom: b\@example.net\n\nb\n", 'example.org'],
		['first of two addresses' => "From: a\@example.org, b\@example.net\n\nb\n", 'example.org'],
		['a header block with no body' => "From: a\@example.org\nTo: b\n", 'example.org'],
		['no From:' => "To: a\@example.org\n\nb\n", undef],
		['a From: that is only in the body' => "To: x\n\nFrom: a\@example.org\n", undef],
		['Resent-From: is not From:' => "Resent-From: a\@example.org\n\nb\n", undef],
		['no @' => "From: nobody\n\nb\n", undef],
		['a domain that is not a host name' => "From: a\@exa_mple.org\n\nb\n", undef],
		['an empty message' => '', undef],
	);

	foreach my $case (@cases) {
		my ($name, $message, $expected) = @{$case};
		is(Mail::Send::DKIM::from_domain($message), $expected, $name);
	}

	is($dkim->from_domain("From: a\@example.org\n\nb\n"), 'example.org', 'it can be called as a method');
	is(Mail::Send::DKIM::from_domain(undef), undef, 'and an undefined message has no From:');
};

subtest 'sign leaves alone what it has no business with' => sub {
	is($dkim->sign(undef), undef, 'an undefined message');
	is($dkim->sign(''), undef, 'an empty message');
	is($dkim->sign('message' => "From: a\@example.net\n\nb\n"), undef, 'a named message from another domain');
	throws_ok { $dkim->sign([]) } qr/message/, 'but not a reference';
};

subtest 'selector names the key file, or says why not' => sub {
	is(Mail::Send::DKIM->new('keyfile' => '/etc/dkim/2026.private')->selector(), '2026', 'the key file\'s name');
	is(Mail::Send::DKIM->new('keyfile' => '/etc/x/k.private', 'selector' => 'given')->selector(), 'given', 'a selector given wins');

	my @warnings;
	local $SIG{'__WARN__'} = sub { push(@warnings, @_) };
	is($dkim->selector(), undef, 'an unreadable key directory gives undef');
	like($warnings[0], qr{cannot read /nonexistent: }, 'and a warning');
};

# What log_send puts in the log, for these arguments and this message.
sub logged_line
{
	my ($message, @args) = @_;

	my @lines;
	no warnings 'redefine';
	local *Sys::Syslog::openlog = sub { };
	local *Sys::Syslog::syslog = sub { push(@lines, $_[-1]) };
	local *Sys::Syslog::closelog = sub { };

	$dkim->log_send($message, @args);

	return $lines[0];
}

subtest 'log_send understands the options sendmail takes' => sub {
	my $message = "From: Me <me\@example.org>\nTo: \"Doe, Jane\" <jane\@example.net>, bob\@example.net\nCc: cc\@example.net\nBcc: bcc\@example.net\nSubject: Hi\n\nb\n";

	like(logged_line($message, '-t'), qr/recipient=jane\@example\.net,bob\@example\.net,cc\@example\.net,bcc\@example\.net /,
		'-t reads To, Cc and Bcc, and a quoted comma does not split an address');
	like(logged_line($message, '-ti'), qr/recipient=jane\@/, 't in a cluster of flags still means -t');
	like(logged_line($message, '-it'), qr/recipient=jane\@/, 'in either order');
	like(logged_line($message, '-f', 'bounce@example.org', 'a@example.net'), qr/\Asender=bounce\@example\.org recipient=a\@example\.net /,
		'-f with its value as the next argument');
	like(logged_line($message, '-fbounce@example.org', 'a@example.net'), qr/\Asender=bounce\@example\.org /, '-f with its value attached');
	like(logged_line($message, '-f', '', 'a@example.net'), qr/\Asender=- /, 'an empty -f is a null sender, not the From: address');
	like(logged_line($message, '-oi', '-odq', 'a@example.net'), qr/recipient=a\@example\.net /,
		'-oi and -odq are options, not recipients');
	like(logged_line($message, '-o', 'i', 'a@example.net'), qr/recipient=a\@example\.net /, 'the value of -o is not a recipient');
	like(logged_line($message, '--', 'a@example.net'), qr/recipient=a\@example\.net /, '-- is not a recipient');
	like(logged_line($message, '-FTest Nigel', 'a@example.net'), qr/recipient=a\@example\.net /,
		'the value of -F is not a recipient');
	unlike(logged_line($message, '-FNigelTest', 'a@example.net'), qr/jane/,
		'and a t inside the value of -F does not turn on -t');
	unlike(logged_line($message, '-bt', 'a@example.net'), qr/jane/, '-bt is sendmail\'s address test, not -t');
	like(logged_line("From: a\@example.org\nSubject: one\x01two\n\nb\n", 'r@example.net'), qr/subject=one two\z/,
		'a control character in the subject is a space');
	like(logged_line("From: a\@example.org\n\nb\n", '-t'), qr/\Asender=a\@example\.org recipient=- subject=-\z/,
		'what is missing is -');
};

subtest 'the helpers are private, and only the message writer may be extended' => sub {
	# Under a test harness the two modules let every call through, so that
	# white-box tests can reach the helpers; this subtest is about the
	# enforcement itself, so it asks for it back.
	no warnings 'once';
	local $Sub::Private::config{'harness_bypass'} = 0;
	local $Sub::Protected::config{'harness_bypass'} = 0;

	foreach my $private (qw(_local _parse_headers _addresses _domain_set _parse_sendmail_args _trim_error _choose_format)) {
		throws_ok { no strict 'refs'; &{"Mail::Send::DKIM::$private"}('x') } qr/private subroutine of Mail::Send::DKIM/,
			"$private cannot be called from outside";
	}
	throws_ok { $dkim->_say('syslog_failed', { 'error' => 'x' }) } qr/protected method/, '_say cannot be called from outside';
	throws_ok { $dkim->_sign_for('example.org', 'x') } qr/private/, 'nor can a private method';

	# A subclass may use the protected method; it still cannot use the private ones.
	{
		package Local::Subclass;
		our @ISA = ('Mail::Send::DKIM');
		sub shout { my $self = shift; return $self->_say('syslog_failed', { 'error' => 'from a subclass' }) }
		sub peek { my $self = shift; return $self->_private_keys() }
	}
	my @warnings;
	local $SIG{'__WARN__'} = sub { push(@warnings, @_) };
	my $sub = Local::Subclass->new();
	is($sub->shout(), $sub, 'a subclass may say things, and the call chains');
	like($warnings[0], qr/from a subclass/, 'and the warning is the catalogue\'s');
	throws_ok { $sub->peek() } qr/private/, 'but not use a private method';
};

subtest 'a sendmail that refuses the message without reading it is a status, not a death' => sub {
	my $dir = tempdir('CLEANUP' => 1);
	my $refuser = File::Spec->catfile($dir, 'refuse.sh');
	open(my $fh, '>', $refuser) or BAIL_OUT("Cannot write $refuser: $!");
	print $fh "#!/bin/sh\nexit 75\n";
	close($fh);
	chmod(0755, $refuser) or BAIL_OUT("Cannot chmod $refuser: $!");

	# Larger than any pipe buffer, so the write meets the closed pipe.
	my $big = ('x' x 79) . "\n";
	$big x= 100_000;

	is(Mail::Send::DKIM->new('sendmail' => $refuser)->send($big), 75, 'sendmail\'s status is returned');

	my $accepts = File::Spec->catfile($dir, 'accept.sh');
	open($fh, '>', $accepts) or BAIL_OUT("Cannot write $accepts: $!");
	print $fh "#!/bin/sh\ncat >/dev/null\nexit 0\n";
	close($fh);
	chmod(0755, $accepts) or BAIL_OUT("Cannot chmod $accepts: $!");
	is(Mail::Send::DKIM->new('sendmail' => $accepts)->send($big), 0, 'and 0 when it reads and accepts it');
};

done_testing();
