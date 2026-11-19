#!/usr/bin/env perl
#
# The POD at the end of this file is this programme's description: perldoc
# dmarc-check-mail.pl.

use strict;
use warnings;

use Getopt::Long qw(GetOptions);
use File::Spec;
use POSIX qw(strftime);
use Sys::Hostname qw(hostname);

use FindBin qw($Bin);
# Beside the module in a checkout, and under lib/perl5 when installed with
# INSTALL_BASE into a prefix that @INC does not reach on its own.
use lib grep { -d } map { "$Bin/../$_" } qw(lib lib/perl5);

# Kept apart from what the options become, so that the usage text goes on
# offering these however the programme was called.
my %default = (
	'to' => $ENV{'DMARC_TEST_TO'} || 'nigel@example.org',
	'from' => $ENV{'DMARC_TEST_FROM'} || 'alerts@example.org',
	'domain' => $ENV{'DMARC_TEST_DOMAIN'} || 'example.org',
	'selector' => $ENV{'DMARC_TEST_SELECTOR'} || 'selector1',
	'sendmail' => $ENV{'SENDMAIL'} || '/usr/sbin/sendmail',
	'keyfile' => $ENV{'DKIM_KEYFILE'},
);

my %opt = (
	%default,
	'plain' => 0,
	'dry-run' => 0,
	'save' => undef,
);

# Nothing that goes wrong once the options have been read is a usage error, and
# die() decides a status of its own - whatever errno was left over (2 for a
# directory that is not there, 13 for one that is not writable) or sendmail's
# own - which would hand out the 2 that means "the options were not usable".
# 1 is the status for having sent nothing, whichever failure it was.
sub fail
{
	print STDERR @_;

	exit(1);
}

GetOptions(
	'to|t=s' => \$opt{'to'},
	'from|f=s' => \$opt{'from'},
	'domain=s' => \$opt{'domain'},
	'selector=s' => \$opt{'selector'},
	'keyfile|k=s' => \$opt{'keyfile'},
	'sendmail=s' => \$opt{'sendmail'},
	'plain' => \$opt{'plain'},
	'dry-run|n' => \$opt{'dry-run'},
	'save=s' => \$opt{'save'},
	'help|h' => sub { usage(0) },
) or usage(2);

usage(2) unless($opt{'to'} && $opt{'from'});
# Both addresses become headers, and --from is sendmail's envelope sender as
# well, so neither may hold a space or a control character - the shape of a
# header injection - or begin with a - that sendmail would read as an option.
usage(2) if(unusable_address($opt{'to'}) || unusable_address($opt{'from'}));

my $host = hostname();
my $token = sprintf('%s-%d', $host, time());
my $now = strftime('%Y-%m-%d %H:%M:%S %z', localtime());

# Sending unsigned from the signing path is a mistake worth stopping: the
# whole point is to see a signature arrive.  --plain asks for it deliberately.
my ($keyfile, $mailer);
if($opt{'plain'}) {
	$mailer = 'sendmail(1), unsigned';
} else {
	$keyfile = $opt{'keyfile'} || find_keyfile();
	if(!$keyfile) {
		my @candidates = candidate_keys();
		fail "No DKIM key found: name one with --keyfile or set DKIM_KEYFILE.\n"
			. (@candidates ? 'Looked at: ' . join(', ', @candidates) . "\n" : '')
			. "Use --plain to send unsigned on purpose.\n";
	}
	fail "Cannot read $keyfile\n" unless(-r $keyfile);
	# Loaded here rather than with use, so that --plain still works on a host
	# without Mail::DKIM: sending unsigned is exactly what it is for there.
	fail "Mail::DKIM is not installed for $^X, so nothing can be signed.\n"
		. "Install it, or use --plain to send unsigned on purpose.\n"
		unless(eval { require Mail::DKIM::Signer; require Mail::Send::DKIM; 1 });
	$mailer = "Mail::Send::DKIM, signed with d=$opt{'domain'} s=$opt{'selector'}";
}

my $subject = "DKIM check from $host at $now";
my $body = <<"BODY";
This is a test message from $host at $now.

It was sent by $mailer.

Its only purpose is to show, in the headers at the far end, whether mail from
this host authenticates.  The token below is unique to this run, so the message
can be found again among others:

  $token

Nothing replies to it and nothing depends on it.
BODY

my $message = join('',
	"From: $opt{'from'}\n",
	"To: $opt{'to'}\n",
	"Subject: $subject\n",
	"Date: $now\n",
	"Message-ID: <$token\@$host>\n",
	"MIME-Version: 1.0\n",
	"Content-Type: text/plain; charset=utf-8\n",
	"Content-Transfer-Encoding: 8bit\n",
	"\n",
	$body,
);

# Sign first, then decide what to do with the result, so that what is printed,
# saved and sent are the same bytes - and so that a rehearsal exercises the
# signing rather than pretending to.
my $wire = $opt{'plain'} ? $message : sign($message);

if($opt{'save'}) {
	open(my $fh, '>', $opt{'save'}) or fail "Cannot write $opt{'save'}: $!\n";
	print $fh $wire;
	close($fh) or fail "Cannot close $opt{'save'}: $!\n";
	print "Message as sent is in $opt{'save'}\n\n";
}

if($opt{'dry-run'}) {
	print $wire;
	print "\n--- nothing was sent; run again without --dry-run ---\n";
	exit(0);
}

open(my $sendmail, '|-', $opt{'sendmail'}, '-t', '-f', $opt{'from'})
	or fail "Cannot run $opt{'sendmail'}: $!\n";
print $sendmail $wire;
unless(close($sendmail)) {
	fail "sendmail reported a failure; the message was not delivered.\n";
}

print "Sent to $opt{'to'} as $opt{'from'}\n";
print "  via       : $mailer\n";
print "  token     : $token\n\n";
print "In the mailbox, open that message and choose \"Show original\".  You want:\n";
print "  SPF:   pass  (ip= the sending host)\n";
print "  DKIM:  pass  (domain=$opt{'domain'}, selector=$opt{'selector'})\n";
print "  DMARC: pass\n\n";
print "If DKIM is missing, nothing downstream can pass: check that the key is\n";
print "the one published at $opt{'selector'}._domainkey.$opt{'domain'}, and that\n";
print "Mail::DKIM is installed for $^X.\n";

exit(0);

# One signing implementation for the repository: Mail::Send::DKIM, which is
# what bin/mail-dkim uses, so what this sends is what the site's mail looks
# like.  The message's own From: domain is allowed as well as --domain, so a
# test sent as a different address than the one being signed for still signs.
sub sign
{
	my $message = shift;

	require Mail::Send::DKIM;

	my $dkim = Mail::Send::DKIM->new(
		'domains' => [$opt{'domain'}, Mail::Send::DKIM::from_domain($message)],
		'keyfile' => $keyfile,
		'selector' => $opt{'selector'},
	);

	my $signed = $dkim->sign($message);
	return $signed if(defined($signed));

	# The module has already said what went wrong on standard error; this adds
	# what the tester knows and it does not: which key was meant.
	fail "Cannot sign with $keyfile.\n"
		. "Check that it is the key published at $opt{'selector'}._domainkey.$opt{'domain'}.\n";
}

# The site's key is wherever the site keeps it; these are the places it has
# lived, so the common case needs no argument.
sub candidate_keys
{
	my @dirs = grep { defined } (
		$ENV{'HOME'} ? File::Spec->catdir($ENV{'HOME'}, 'dkim') : undef,
		$ENV{'HOME'} ? File::Spec->catdir($ENV{'HOME'}, '.dkim') : undef,
		$ENV{'HOME'} ? File::Spec->catdir($ENV{'HOME'}, 'lib', 'dkim') : undef,
	);

	my @keys;
	foreach my $dir (@dirs) {
		next unless(-d $dir);
		foreach my $name (glob(File::Spec->catfile($dir, '*'))) {
			next unless($name =~ /\.(?:private|key|pem)\z/);
			push @keys, $name;
		}
	}

	return @keys;
}

sub find_keyfile
{
	foreach my $key (candidate_keys()) {
		# A directory can hold keys for several domains; the selector names
		# the one this message must be signed with.
		return $key if($key =~ /\Q$opt{'selector'}\E/ || $key =~ /\Q$opt{'domain'}\E/);
	}

	return undef;
}

# An address that cannot be written into a header as it stands, and that would
# be read as an option by sendmail if it began with a dash.
sub unusable_address
{
	my $address = shift;

	return 1 if($address =~ /[\x00-\x20\x7f]/);
	return 1 if($address =~ /\A-/);

	return 0;
}

sub usage
{
	my $status = shift // 0;

	print <<"USAGE";
$0 - send one test message from this host, so its authentication can be read

Usage:
  $0 [options]

  --to ADDR         where to send it          (default $default{'to'})
  --from ADDR       envelope and header From  (default $default{'from'})
  --domain DOMAIN   the domain to sign for    (default $default{'domain'})
  --selector SEL    the DKIM selector         (default $default{'selector'})
  --keyfile FILE    the DKIM private key      (default: found under ~/dkim)
  --plain           send unsigned via sendmail(1), the way cron does
  --dry-run         sign the message, print it, send nothing
  --save FILE       also write the message, as it is sent, to FILE
  --sendmail PATH   sendmail to use           (default $default{'sendmail'})
  --help            this text

Sent through Mail::Send::DKIM, the signer bin/mail-dkim uses, so that what
arrives is what the site's mail actually looks like.
USAGE

	exit($status);
}

=pod

=head1 NAME

dmarc-check-mail.pl - send one test message from this host, so its authentication can be read

=head1 SYNOPSIS

	dmarc-check-mail.pl

	dmarc-check-mail.pl --plain

	dmarc-check-mail.pl --keyfile ~/dkim/selector1.private --domain example.org

=head1 DESCRIPTION

Sends one message through sendmail(1) to a mailbox that can be read, and says
what the C<Authentication-Results> header at the far end should contain.  The
message is signed with L<Mail::Send::DKIM>, the signer C<mail-dkim> uses, so
that what arrives is what this site's mail really looks like, rather than a test
of a signing path nothing else uses.  C<--plain> sends the same message
unsigned, which is what a cron job without the module looks like, so that both
can be compared in the same mailbox.

The subject and body carry a token made of the host name and the time, so that
the message can be found again among others.

=head1 OPTIONS

=over 4

=item B<--to> ADDR (C<-t>)

Where to send it.  Default C<DMARC_TEST_TO>, or C<nigel@example.org>.  It is
written into the message's C<To:> header, so an address holding a space or a
control character, or beginning with a C<->, is refused, as C<--from> is.

=item B<--from> ADDR (C<-f>)

The envelope sender and the header C<From:>.  Default C<DMARC_TEST_FROM>, or
C<alerts@example.org>.  An address holding a space or a control character, or
beginning with a C<->, is refused.

=item B<--domain> DOMAIN

The domain to sign for.  Default C<DMARC_TEST_DOMAIN>, or C<example.org>.  The
domain in the message's own C<From:> is signed for as well, so that a test sent
as an address from the domain being signed for still signs.

=item B<--selector> SEL

The selector to sign with.  Default C<DMARC_TEST_SELECTOR>, or C<selector1>.  It
also chooses the key when C<--keyfile> is not given.

=item B<--keyfile> FILE (C<-k>)

The private key.  Default C<DKIM_KEYFILE>, or the first file under C<~/dkim>,
C<~/.dkim> or C<~/lib/dkim> named C<*.private>, C<*.key> or C<*.pem> whose name
holds the selector or the domain.

=item B<--plain>

Send the message unsigned, through sendmail(1) alone, which is what cron does.
No key is looked for and Mail::DKIM need not be installed, so this still works
on a host that cannot sign at all.

=item B<--dry-run> (C<-n>)

Sign the message, print it, and send nothing.

=item B<--save> FILE

Also write the message, as it is sent, to FILE.

=item B<--sendmail> PATH

The sendmail the message is handed to.  Default C<SENDMAIL>, or
C</usr/sbin/sendmail>.

=item B<--help> (C<-h>)

Print the usage summary and exit 0.

=back

Each default above is set by the variable named with it, and nothing else is
read.

=head1 ENVIRONMENT

=over 4

=item C<DMARC_TEST_TO>

The default for C<--to>.

=item C<DMARC_TEST_FROM>

The default for C<--from>.

=item C<DMARC_TEST_DOMAIN>

The default for C<--domain>.

=item C<DMARC_TEST_SELECTOR>

The default for C<--selector>, which also chooses the key.

=item C<SENDMAIL>

The default for C<--sendmail>.

=item C<DKIM_KEYFILE>

The key, when C<--keyfile> is not given.

=item C<HOME>

Where the key is looked for when neither is given: C<~/dkim>, C<~/.dkim> and
C<~/lib/dkim>.

=back

=head1 EXIT STATUS

C<0> when the message was handed to sendmail, printed by C<--dry-run>, or
C<--help> was asked for - and the first two do not mean it arrived, or that it
authenticated: that is what the headers at the far end say.  C<1> when nothing
was sent: no key was found, the key could not be read, Mail::DKIM is not
installed for this perl, C<--save> could not be written, or sendmail could not
be run or reported a failure.  Standard error says which.  C<2> when the
options were not usable - an unknown option, no C<--to> or C<--from>, or a
C<--to> or C<--from> that cannot be an address - so nothing was signed or sent,
and no transport was asked to do anything.  C<2> never means that a message was
attempted and failed.

=head1 SEE ALSO

L<Mail::Send::DKIM>, the signer, and C<mail-dkim>, the sendmail front end that
C<dmarc-weekly.sh> sends its alerts through.

=cut
