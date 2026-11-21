#!perl -w

# Log::Dispatch::Email::flush is what turns buffered log lines into mail: it
# joins the buffer into one message, calls send_email once, and then empties
# the buffer.  The POD's STATE DIAGRAM describes this (EMPTY, PENDING and
# SENDING), so check each transition: log() queues, flush() sends one mail
# and empties the queue, an empty queue sends nothing, an unbuffered appender
# has nothing to flush, and an appender that is destroyed flushes.

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);

BEGIN {
	use_ok('Log::Dispatch::Email::DKIM');
}

# A sendmail(1) stand-in that saves each message it is given in its own file
# in $ENV{CAPDIR}, so the number of files is the number of mails sent
my $bin = tempdir(CLEANUP => 1);
my $sendmail = File::Spec->catfile($bin, 'sendmail');
open(my $script, '>', $sendmail) or die "Cannot write $sendmail: $!";
print $script "#!/bin/sh\nexec cat > \"\$CAPDIR/message.\$\$\"\n";
close($script) or die "Cannot write $sendmail: $!";
chmod(0700, $sendmail) or die "Cannot chmod $sendmail: $!";

# No key, so that nothing here depends on one; the missing-key warning is
# expected and is caught in new_appender's caller
my $no_keys = tempdir(CLEANUP => 1);

delete @ENV{qw(DKIM_DOMAIN DKIM_SELECTOR DKIM_KEYFILE)};
$ENV{'DKIM_SENDMAIL'} = $sendmail;
$ENV{'DKIM_KEYDIR'} = $no_keys;

# Each test gets an empty directory for the mail it sends
sub fresh_capture_dir {
	my $dir = tempdir(CLEANUP => 1);
	$ENV{'CAPDIR'} = $dir;
	return $dir;
}

# The text of every message sent so far, in file-name order
sub mails_in {
	my $dir = shift;

	opendir(my $handle, $dir) or die "Cannot read $dir: $!";
	my @files = sort grep { !/\A\./ } readdir($handle);
	closedir($handle);

	return [ map {
		open(my $in, '<', File::Spec->catfile($dir, $_)) or die "Cannot read $_: $!";
		local $/;
		scalar <$in>;
	} @files ];
}

sub new_appender {
	my ($class, %extra) = @_;

	return $class->new(
		'name' => 'VF', 'min_level' => 'debug',
		'from' => 'webmaster@bandsman.co.uk', 'to' => ['njh@bandsman.co.uk'],
		'subject' => 'Error in shop/index.fcgi',
		%extra,
	);
}

# Every test below expects, and ignores, the "no DKIM key" warning
$SIG{'__WARN__'} = sub { die @_ unless($_[0] =~ /no DKIM key/) };

subtest 'log() queues, and sends nothing yet' => sub {
	my $dir = fresh_capture_dir();
	my $log = new_appender('Log::Dispatch::Email::DKIM');

	$log->log('level' => 'error', 'message' => "first\n");
	$log->log('level' => 'error', 'message' => "second\n");

	is(scalar(@{ $log->{'buffer'} }), 2, 'two messages are waiting');
	is(scalar(@{ mails_in($dir) }), 0, 'and no mail has been sent');

	$log->{'buffer'} = [];	# keep DESTROY from sending in this subtest
};

subtest 'flush() sends one mail holding every message, then empties the buffer' => sub {
	my $dir = fresh_capture_dir();
	my $log = new_appender('Log::Dispatch::Email::DKIM');

	$log->log('level' => 'error', 'message' => "first\n");
	$log->log('level' => 'error', 'message' => "second\n");
	$log->log('level' => 'error', 'message' => "third\n");
	$log->flush();

	my $mails = mails_in($dir);
	is(scalar(@{$mails}), 1, 'exactly one mail was sent');
	like($mails->[0], qr/first\r?\nsecond\r?\nthird\r?\n/, 'it holds the messages, in order');
	like($mails->[0], qr/^Subject: Error in shop\/index\.fcgi\r?$/m, 'with the appender\'s subject');
	is_deeply($log->{'buffer'}, [], 'the buffer is empty');

	$log->flush();
	is(scalar(@{ mails_in($dir) }), 1, 'a second flush() sends nothing more');
};

subtest 'flush() of an empty buffer sends nothing' => sub {
	my $dir = fresh_capture_dir();
	my $log = new_appender('Log::Dispatch::Email::DKIM');

	$log->flush();

	is(scalar(@{ mails_in($dir) }), 0, 'no mail');
};

subtest 'the buffer fills again after a flush' => sub {
	my $dir = fresh_capture_dir();
	my $log = new_appender('Log::Dispatch::Email::DKIM');

	$log->log('level' => 'error', 'message' => "one\n");
	$log->flush();
	$log->log('level' => 'error', 'message' => "two\n");
	$log->flush();

	my $mails = mails_in($dir);
	is(scalar(@{$mails}), 2, 'two mails');
	unlike(join('', @{$mails}), qr/one.*one/s, 'a message is never sent twice');
	like(join('', @{$mails}), qr/two/, 'and the later one is sent');
};

subtest 'an unbuffered appender sends at once and has nothing to flush' => sub {
	my $dir = fresh_capture_dir();
	my $log = new_appender('Log::Dispatch::Email::DKIM', 'buffered' => 0);

	$log->log('level' => 'error', 'message' => "now\n");
	is(scalar(@{ mails_in($dir) }), 1, 'the mail went out when logged');

	$log->flush();
	is(scalar(@{ mails_in($dir) }), 1, 'flush() adds nothing');
	ok(!exists($log->{'buffer'}), 'there is no buffer');
};

subtest 'destroying the appender flushes it' => sub {
	my $dir = fresh_capture_dir();
	{
		my $log = new_appender('Log::Dispatch::Email::DKIM');
		$log->log('level' => 'error', 'message' => "left behind\n");
	}

	my $mails = mails_in($dir);
	is(scalar(@{$mails}), 1, 'the waiting message was sent');
	like($mails->[0], qr/left behind/, 'and it is the one that was logged');
};

subtest 'a Log::Dispatch dispatcher flushes its appender when it goes away' => sub {
	my $dir = fresh_capture_dir();
	require Log::Dispatch;
	{
		my $dispatcher = Log::Dispatch->new('outputs' => [ [
			'Email::DKIM', 'min_level' => 'error',
			'from' => 'webmaster@bandsman.co.uk', 'to' => ['njh@bandsman.co.uk'],
		] ]);
		$dispatcher->error("one\n");
		$dispatcher->error("two\n");
	}

	my $mails = mails_in($dir);
	is(scalar(@{$mails}), 1, 'one mail');
	like($mails->[0], qr/one\r?\ntwo/, 'holding both messages');
};

# Documented in the STATE DIAGRAM: when send_email croaks, flush() does not
# reach the line that empties the buffer
subtest 'if send_email croaks, the messages are kept' => sub {
	{
		package Croaker;
		our @ISA = ('Log::Dispatch::Email::DKIM');
		sub send_email { require Carp; Carp::croak('no way') }
	}
	my $log = new_appender('Croaker');
	$log->log('level' => 'error', 'message' => "keep me\n");

	ok(!eval { $log->flush(); 1 }, 'flush() passes the error on');
	is_deeply($log->{'buffer'}, ["keep me\n"], 'and the message is still waiting');

	$log->{'buffer'} = [];	# nothing for DESTROY to send
};

done_testing();
