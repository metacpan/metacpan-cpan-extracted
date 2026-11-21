#!/usr/bin/env perl
#
# i18n: every sentence the module says comes out of one catalogue, and the
# catalogue can be replaced.  What is tested is what the POD of i18n and new
# say: named placeholders with sprintf's flags, a choice of format by count and
# by variant (a gender, say), an error - not an empty string - for a missing
# argument, and a croak for a message that does not exist.

use strict;
use warnings;

use Test::Most;

use File::Spec;
use FindBin qw($Bin);

use lib File::Spec->catdir($Bin, File::Spec->updir(), 'lib');
use Mail::Send::DKIM;

my $dkim = Mail::Send::DKIM->new('domains' => 'example.org', 'keydir' => '/nonexistent');

subtest 'the default catalogue is English, with the arguments put in' => sub {
	is($dkim->i18n('keydir_unreadable', { 'keydir' => '/k', 'os_error' => 'No such file' }),
		'Mail::Send::DKIM: cannot read /k: No such file', 'named placeholders are filled');
	is($dkim->i18n('syslog_failed', { 'error' => 'down' }), 'Mail::Send::DKIM: cannot write to syslog: down',
		'a message with one placeholder');
};

subtest 'the count picks the plural form' => sub {
	like($dkim->i18n('keys_ambiguous', { 'keydir' => '/k', 'count' => 1 }), qr{/k holds 1 key; }, 'one key');
	like($dkim->i18n('keys_ambiguous', { 'keydir' => '/k', 'count' => 2 }), qr{/k holds 2 keys; }, 'two keys');
	like($dkim->i18n('keys_ambiguous', { 'keydir' => '/k', 'count' => 0 }), qr{/k holds 0 keys; }, 'zero falls back to other');
};

subtest 'a caller\'s catalogue replaces and adds to the default one' => sub {
	my $other = Mail::Send::DKIM->new(
		'messages' => {
			'syslog_failed' => 'syslog: %{error}-6s|',
			'greeting' => {
				'feminine' => 'Chere %{name}s',
				'masculine' => 'Cher %{name}s',
				'feminine.other' => 'Cheres %{name}s',
				'other' => 'Chers %{name}s',
			},
			'zeroes' => { 'zero' => 'none', 'one' => 'one', 'other' => 'many' },
		},
	);

	is($other->i18n('syslog_failed', { 'error' => 'x' }), 'syslog: x     |', 'sprintf flags and width are honoured');
	like($other->i18n('keydir_unreadable', { 'keydir' => 'd', 'os_error' => 'e' }), qr/cannot read d/,
		'a message the caller did not replace is still there');

	is($other->i18n('greeting', { 'name' => 'A', 'variant' => 'feminine' }), 'Chere A', 'a variant is chosen');
	is($other->i18n('greeting', { 'name' => 'A', 'variant' => 'masculine' }), 'Cher A', 'another variant');
	is($other->i18n('greeting', { 'name' => 'A', 'variant' => 'feminine', 'count' => 3 }), 'Cheres A',
		'variant and count together choose "variant.count"');
	is($other->i18n('greeting', { 'name' => 'A', 'variant' => 'masculine', 'count' => 3 }), 'Cher A',
		'a variant with no form for the count keeps its plain form');
	is($other->i18n('greeting', { 'name' => 'A' }), 'Chers A', 'no variant, no count: other');

	is($other->i18n('zeroes', { 'count' => 0 }), 'none', 'zero is its own form when there is one');
	is($other->i18n('zeroes', { 'count' => 1 }), 'one', 'and so is one');
};

subtest 'a message that is not defined, or an argument that is missing, croaks' => sub {
	throws_ok { $dkim->i18n('no_such_message') } qr/no message is defined for the key "no_such_message"/, 'unknown key';
	throws_ok { $dkim->i18n('syslog_failed', {}) } qr/needs the argument "error"/, 'missing argument';
	throws_ok { $dkim->i18n('syslog_failed') } qr/needs the argument "error"/, 'no arguments at all';

	# A catalogue that blanks the message about missing messages must not
	# leave the module unable to say so.
	my $broken = Mail::Send::DKIM->new('messages' => { 'unknown_message' => undef });
	throws_ok { $broken->i18n('no_such_message') } qr/no message is defined/, 'the default is the fall-back';
};

subtest 'the messages the module warns with come from the catalogue' => sub {
	my $says = Mail::Send::DKIM->new(
		'sendmail' => '/nonexistent/sendmail',
		'messages' => { 'sendmail_failed' => 'cannot start %{sendmail}s (%{os_error}s)' },
	);
	my @warnings;
	local $SIG{'__WARN__'} = sub { push(@warnings, @_) };

	is($says->send("x\n"), 1, 'a sendmail that cannot be run returns 1');
	is(scalar(@warnings), 1, 'with one warning, not also perl\'s own "Can\'t exec"');
	like($warnings[0], qr{\Acannot start /nonexistent/sendmail \(}, 'in the caller\'s words');
};

subtest 'the options are checked' => sub {
	throws_ok { Mail::Send::DKIM->new('domains' => {}) } qr/domains/, 'a hash is not a list of domains';
	throws_ok { Mail::Send::DKIM->new('messages' => 'text') } qr/messages/, 'nor is a string a catalogue';
	lives_ok { Mail::Send::DKIM->new('unheard_of' => 1) } 'an option nobody knows is ignored';
};

done_testing();
