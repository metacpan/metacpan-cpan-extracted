#!perl -w

# Operating-system error strings are translated by the C library according to
# LC_ALL.  The one such string this appender reaches is the "No such file or
# directory" that Mail::Send::DKIM carps when sendmail cannot be run, so check
# that it is neither lost nor mangled, and that the appender still raises its
# own warning, in every locale.
#
# Perl reads the locale once, at start-up, so each locale needs a fresh perl.
# The child works out what $! should say for itself (with "local $! = ENOENT",
# not POSIX::strerror, so that Perl's own layer is the source) and compares,
# which stays correct whether or not the locale is installed here: an
# uninstalled one falls back to C, in the child as much as in the test.
#
# The geographic (GeoIP) locale tests that other distributions run do not
# apply: this appender has no notion of a client's country, only of the
# domain in its From address, so there is nothing to map.

use strict;
use warnings;
use Test::More;
use Config;
use File::Spec;
use File::Temp qw(tempdir);

BEGIN {
	use_ok('Log::Dispatch::Email::DKIM');
}

# One locale of each kind: English, German and an East Asian one
my @locales = qw(en_US.UTF-8 de_DE.UTF-8 ja_JP.UTF-8 zh_CN.UTF-8);

my $lib = File::Spec->rel2abs('lib');
my $missing = File::Spec->catfile(tempdir(CLEANUP => 1), 'no-such-sendmail');

# The child logs one message with a sendmail that does not exist, and prints
# what it expected $! to say, and the warnings it got, one per line
my $child = <<'PERL';
use strict;
use warnings;
use Errno qw(ENOENT);
use lib $ENV{'TEST_LIB'};
use Log::Dispatch::Email::DKIM;

my $expected = do { local $! = ENOENT; "$!" };

my @warnings;
{
	local $SIG{'__WARN__'} = sub { push @warnings, @_ };
	my $log = Log::Dispatch::Email::DKIM->new(
		'name' => 'VF', 'min_level' => 'debug', 'buffered' => 0,
		'from' => 'webmaster@bandsman.co.uk', 'to' => ['njh@bandsman.co.uk'], 'subject' => 'S',
	);
	$log->log('level' => 'error', 'message' => "body\n");
}
print "EXPECTED:$expected\n";
print "WARNING:$_" foreach @warnings;
PERL

foreach my $locale (@locales) {
	subtest "OS errors under LC_ALL=$locale" => sub {
		# PERL_BADLANG=0: a locale that is not installed here is not worth a
		# warning from perl itself; the child falls back to C and still agrees
		# with itself about what ENOENT says
		local @ENV{qw(LC_ALL LANG LANGUAGE PERL_BADLANG DKIM_SENDMAIL DKIM_KEYDIR TEST_LIB)} =
			($locale, $locale, $locale, 0, $missing, File::Spec->catdir(tempdir(CLEANUP => 1)), $lib);

		open(my $pipe, '-|', $^X, '-e', $child) or BAIL_OUT("cannot run $^X: $!");
		my @lines = <$pipe>;
		close($pipe);

		my ($expected) = map { /\AEXPECTED:(.*)\n\z/ ? $1 : () } @lines;
		my @warnings = grep { /\AWARNING:/ } @lines;

		ok(defined($expected) && length($expected), 'the child worked out the OS string for ENOENT');
		ok((grep { /cannot run \Q$missing\E: / } @warnings), 'Mail::Send::DKIM names the program it could not run')
			or diag(explain(\@lines));

		ok((grep { /cannot run \Q$missing\E: \Q$expected\E/ } @warnings), 'the OS string appears, intact, in the warning');
		ok((grep { /DKIM: sendmail failed for webmaster\@bandsman\.co\.uk/ } @warnings), 'and the appender raises its own warning');
		ok((grep { /DKIM: no DKIM key for bandsman\.co\.uk; sending unsigned/ } @warnings), 'and says the message is unsigned');
	};
}

# The appender's own messages are the catalogue's, whatever the locale
subtest 'its own messages do not depend on the locale' => sub {
	local $ENV{'LC_ALL'} = 'de_DE.UTF-8';
	{
		package Reworded;
		our @ISA = ('Log::Dispatch::Email::DKIM');
		sub words { my $self = shift; return $self->i18n(@_) }
	}
	my $log = Reworded->new(
		'name' => 'VF', 'min_level' => 'debug',
		'from' => 'webmaster@bandsman.co.uk', 'to' => ['njh@bandsman.co.uk'],
	);
	is($log->words('send_failed', { 'sender' => 'a@b.com' }), 'DKIM: sendmail failed for a@b.com', 'English wording');

	local $Log::Dispatch::Email::DKIM::MESSAGES{'send_failed'} = ['DKIM: sendmail fehlgeschlagen fuer %s', 'sender'];
	is($log->words('send_failed', { 'sender' => 'a@b.com' }), 'DKIM: sendmail fehlgeschlagen fuer a@b.com', 'a translation replaces it');
};

done_testing();
