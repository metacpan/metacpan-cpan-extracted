#!/usr/bin/env perl
#
# dmarc-report - summarise DMARC aggregate reports, and flag every source
# address that is not the host we expect to be sending as our domains.
#
# Aggregate reports arrive as XML, sometimes gzipped, and often several at a
# time, so this reads a whole directory rather than one file: every report
# that parses is summarised, then the totals per source address are given, and
# anything that did not come from the expected host is marked.  The exit
# status is the part a cron job can act on - 0 when every message came from
# the expected host and authenticated, 1 when something else did - so it can
# run unattended over a reports directory.
#
# Namespace: some reporters put the report in a namespace and some do not, so
# every lookup is by local-name() rather than by the plain element name.

use strict;
use warnings;

use File::Basename qw(basename);
use File::Spec;
use Getopt::Long qw(GetOptions);
use IO::Uncompress::Gunzip qw(gunzip $GunzipError);
use IO::Uncompress::Unzip qw($UnzipError);
use POSIX qw(strftime);
use Readonly;
use Pod::Usage qw(pod2usage);
use XML::PP;

# The hosts that are expected to send as these domains; everything else is a
# finding.  There is no built-in address, so they come from --expected or from
# DMARC_EXPECTED, given as a comma or space separated list.

my $home = $ENV{'HOME'} || (getpwuid($<))[7] || '.';
my $DEFAULT_DIR = $ENV{'DMARC_DIR'} || "$home/Downloads";

my (@dirs, @expected, $file_list, $help);
GetOptions(
	'dir|d=s' => \@dirs,
	'expected|e=s' => \@expected,
	'file-list=s' => \$file_list,
	'help|h' => \$help,
) or pod2usage(-exitval => 2, -verbose => 0);
pod2usage(-exitval => 0, -verbose => 1) if($help);

@dirs = ($DEFAULT_DIR) unless(@dirs);
unless(@expected) {
	@expected = grep { length } split(/[\s,]+/, $ENV{'DMARC_EXPECTED'} // '');
	pod2usage(
		-exitval => 2, -verbose => 0,
		-message => "No expected sender: give --expected IP, or set DMARC_EXPECTED to one or more IPs.\n",
	) unless(@expected);
}
my %expected = map { $_ => 1 } @expected;

my @files;
foreach my $dir (@dirs) {
	die "Not a directory: $dir\n" unless(-d $dir);
	# Only the shapes a report arrives in.  A bare *.gz would also match
	# anything else parked in the same directory - a tarball, a downloaded
	# data set - and trying to parse those is both slow and misleading.
	foreach my $pattern ('*.xml', '*.xml.gz', '*.zip') {
		push @files, glob(File::Spec->catfile($dir, $pattern));
	}
}
my %seen;
@files = sort grep { !$seen{$_}++ } @files;
die "No reports found in: @dirs\n" unless(@files);

# Read one report, gunzipping it if it is compressed.  Reports are small, so
# they are parsed in memory and there is no need to unpack them onto disc.
# Reports are kilobytes.  Capping what is opened at all keeps a downloads
# directory usable: it holds installers, archives and data sets, and one of
# them is 13 GB, so matching on the extension alone is not enough.
Readonly::Scalar my $MAX_FILE_BYTES => 10 * 1024 * 1024;
Readonly::Scalar my $MAX_XML_BYTES => 20 * 1024 * 1024;

sub read_report
{
	my $path = shift;

	my $size = -s $path;
	die "too large to be a report ($size bytes)\n" if(defined($size) && $size > $MAX_FILE_BYTES);

	my $xml;
	if($path =~ /\.zip\z/) {
		$xml = read_zipped_xml($path);
	} elsif($path =~ /\.gz\z/) {
		$xml = read_gzipped_xml($path);
	} else {
		open(my $fh, '<', $path) or die "Cannot read $path: $!\n";
		local $/;
		$xml = <$fh>;
		close($fh);
	}

	# A DMARC report is a <feedback> document.  Saying so is clearer than
	# letting the XML parser complain about a CSV or a tarball.
	die "not a DMARC report\n" unless(index($xml, '<feedback') >= 0);

	# XML::PP is pure Perl, so it installs where XML::PP does not (Windows).
	# It returns the root element; wrap it so that, as with a document, the root
	# is itself something to search for.
	my $root = XML::PP->new()->parse($xml);
	die "not a DMARC report\n" unless(ref($root) eq 'HASH' && defined($root->{'name'}));

	return { 'children' => [ $root ] };
}

# Every element below $node, in document order, with the given name.  The
# namespace prefix is not part of the name XML::PP gives, so this matches on
# the local name, as the reports' differing prefixes require.
sub descendants
{
	my ($node, $name) = @_;

	my @found;
	foreach my $child (@{$node->{'children'} || []}) {
		next unless(defined($child->{'name'}));
		push @found, $child if($child->{'name'} eq $name);
		push @found, descendants($child, $name);
	}

	return @found;
}

# Only the direct children with the given name.
sub children_named
{
	my ($node, $name) = @_;

	return grep { defined($_->{'name'}) && $_->{'name'} eq $name } @{$node->{'children'} || []};
}

# All the text under a node, as textContent gave it.
sub text_content
{
	my $node = shift;

	return join('', map { defined($_->{'name'}) ? text_content($_) : ($_->{'text'} // '') } @{$node->{'children'} || []});
}

sub read_gzipped_xml
{
	my $path = shift;

	my $gz = IO::Uncompress::Gunzip->new($path) or die "Cannot gunzip $path: $GunzipError\n";

	return _read_bounded($gz, $path);
}

# Reporters that send a .zip put the report inside, sometimes beside a
# signature file, so the first member ending in .xml is the one to read.
sub read_zipped_xml
{
	my $path = shift;

	my $zip = IO::Uncompress::Unzip->new($path) or die "Cannot open $path: $UnzipError\n";

	my $status = 1;
	while($status > 0) {
		my $name = $zip->getHeaderInfo()->{'Name'} || '';
		return _read_bounded($zip, $path) if($name =~ /\.xml\z/i);
		$status = $zip->nextStream();
	}

	die "No XML inside $path\n";
}

# Read to the end of the current stream, giving up rather than filling memory
# with something that turned out not to be a report.
sub _read_bounded
{
	my ($handle, $path) = @_;

	my $xml = '';
	while(1) {
		my $read = $handle->read(my $chunk, 65536);
		die "Cannot read $path: ", $handle->error(), "\n" if(!defined($read));
		last if($read == 0);
		$xml .= $chunk;
		die "expands beyond $MAX_XML_BYTES bytes; not a report\n" if(length($xml) > $MAX_XML_BYTES);
	}

	return $xml;
}

# The first non-empty text under a named child.  Used for the single-valued
# fields, where a reporter that repeats an element would otherwise make the
# concatenated text look like a value.
sub text_in
{
	my ($node, $name) = @_;

	return '' unless($node);

	foreach my $found (descendants($node, $name)) {
		my $text = text_content($found);
		$text =~ s/\A\s+//;
		$text =~ s/\s+\z//;
		return $text if(length($text));
	}

	return '';
}

sub when
{
	my $epoch = shift;

	return '?' unless(defined($epoch) && $epoch =~ /\A\d+\z/);

	return strftime('%Y-%m-%d %H:%M UTC', gmtime($epoch));
}

# Totals per reported domain and source address, across every report.  One
# address spread over several reports is one problem, not several - but the
# reports for every domain arrive at the same mailbox, so their figures must
# not be added together: an address that legitimately sends for one domain is
# not thereby legitimate for another.
my %by_domain;
my @read_files;
my ($total_messages, $total_records, $reports_read) = (0, 0, 0);
my $unexpected_messages = 0;
# Messages the policy quarantined or rejected that should not have been:
# either they authenticated, or they came from an expected host.
my $misfiled_messages = 0;
my %misfiled;

foreach my $path (@files) {
	my $doc = eval { read_report($path) };
	if(!$doc) {
		my ($why) = split(/\n/, "$@");
		# "not a report" is the normal case in a downloads directory, so it is
		# passed over; anything else means a report we could not read.
		warn 'Skipping ', basename($path), ": $why\n" unless($why =~ /not a (DMARC )?report|too large|expands beyond/);
		next;
	}
	$reports_read++;
	push @read_files, File::Spec->rel2abs($path);

	my ($meta) = descendants($doc, 'report_metadata');
	my ($policy) = descendants($doc, 'policy_published');

	my ($date_range) = $meta ? descendants($meta, 'date_range') : ();
	my $begin = text_in($date_range, 'begin');
	my $end = text_in($date_range, 'end');

	print '=' x 78, "\n";
	print basename($path), "\n";
	printf "  reporter : %s   report_id: %s\n", text_in($meta, 'org_name'), text_in($meta, 'report_id');
	printf "  period   : %s -> %s\n", when($begin), when($end);
	printf "  domain   : %s   p=%s sp=%s adkim=%s aspf=%s pct=%s\n",
		text_in($policy, 'domain'), text_in($policy, 'p'), text_in($policy, 'sp'),
		text_in($policy, 'adkim'), text_in($policy, 'aspf'), text_in($policy, 'pct');

	my $reported_domain = text_in($policy, 'domain');

	my @records = descendants($doc, 'record');
	if(!@records) {
		print "  (no records in this report)\n";
		next;
	}

	foreach my $record (@records) {
		my ($row) = descendants($record, 'row');
		my ($evaluated) = descendants($record, 'policy_evaluated');

		my $ip = text_in($row, 'source_ip');
		my $count = text_in($row, 'count') || 0;
		my $disposition = text_in($evaluated, 'disposition');
		my $dkim_verdict = text_in($evaluated, 'dkim');
		my $spf_verdict = text_in($evaluated, 'spf');
		my $header_from = text_in($record, 'header_from');

		# The addresses actually seen, which is what says whether a message
		# carried a signature at all rather than merely failing its check.
		my (@dkim_auth, @spf_auth);
		foreach my $results (descendants($record, 'auth_results')) {
			foreach my $dkim (children_named($results, 'dkim')) {
				push @dkim_auth, sprintf('%s/%s=%s',
					text_in($dkim, 'domain'), (text_in($dkim, 'selector') || '-'), text_in($dkim, 'result'));
			}
			foreach my $spf (children_named($results, 'spf')) {
				push @spf_auth, sprintf('%s=%s', text_in($spf, 'domain'), text_in($spf, 'result'));
			}
		}

		# A reporter that leaves policy_published out is grouped by the From
		# domain of the record instead, so nothing falls into a shared bucket.
		my $domain = $reported_domain || $header_from || '(unknown)';

		my $passed = ($dkim_verdict eq 'pass') || ($spf_verdict eq 'pass');

		# Two failures worth naming as they happen, because neither shows up in
		# the per-address totals: mail that authenticated and was filed anyway,
		# and mail of ours that the policy filed.
		my $filed = ($disposition eq 'quarantine' || $disposition eq 'reject');
		my $word = ($disposition eq 'reject') ? 'rejected' : 'quarantined';

		my @flags;
		if(!$expected{$ip}) {
			push @flags, 'NOT ' . join('/', @expected);
			$unexpected_messages += $count;
		} elsif(!$passed) {
			push @flags, 'expected host, not authenticating';
		}

		if($filed && $passed && $expected{$ip}) {
			push @flags, "expected sender, $word though authenticated";
		} elsif($filed && $passed) {
			push @flags, "authenticated, but $word";
		} elsif($filed && $expected{$ip}) {
			push @flags, "expected sender, $word";
		}

		if($filed && ($passed || $expected{$ip})) {
			my $finding = $misfiled{join("\t", $domain, $ip, $disposition)} ||= {
				'domain' => $domain, 'ip' => $ip, 'disposition' => $disposition,
				'count' => 0, 'passed' => 0, 'expected' => 0,
				'dkim' => {}, 'spf' => {},
			};
			$finding->{'count'} += $count;
			$finding->{'passed'} = 1 if($passed);
			$finding->{'expected'} = 1 if($expected{$ip});
			$finding->{'dkim'}{$dkim_verdict} = 1;
			$finding->{'spf'}{$spf_verdict} = 1;
			$misfiled_messages += $count;
		}

		my $flag = @flags ? '  <== ' . join('; ', @flags) : '';

		printf "  %-16s %5d  dkim=%-5s spf=%-8s %-9s from=%s%s\n",
			$ip, $count, $dkim_verdict, $spf_verdict, $disposition, $header_from, $flag;
		printf "      dkim seen: %s\n", (@dkim_auth ? join(', ', @dkim_auth) : 'none');
		printf "      spf  seen: %s\n", (@spf_auth ? join(', ', @spf_auth) : 'none');

		$total_records++;
		$total_messages += $count;

		my $entry = $by_domain{$domain}{$ip} ||= {
			'count' => 0, 'pass' => 0, 'fail' => 0,
			'unexpected' => (!$expected{$ip} ? 1 : 0),
			'dkim_seen' => {},
		};
		$entry->{'count'} += $count;
		$entry->{'pass'} += $count if($passed);
		$entry->{'fail'} += $count if(!$passed);
		$entry->{'dkim_seen'}{$_} = 1 foreach(@dkim_auth);
	}
}

# Named before the summary is printed, so a caller that moves the files aside
# knows exactly which ones were summarised - and which were merely in the way.
if(defined($file_list)) {
	open(my $fh, '>', $file_list) or die "Cannot write $file_list: $!\n";
	print $fh map { "$_\n" } @read_files;
	close($fh) or die "Cannot close $file_list: $!\n";
}

print '=' x 78, "\n";
printf "Totals over %d report(s): %d record(s), %d message(s)\n",
	$reports_read, $total_records, $total_messages;
foreach my $domain (sort keys %by_domain) {
	my $by_ip = $by_domain{$domain};

	my ($messages, $unexpected) = (0, 0);
	foreach my $ip (keys %{$by_ip}) {
		$messages += $by_ip->{$ip}{'count'};
		$unexpected += $by_ip->{$ip}{'count'} if($by_ip->{$ip}{'unexpected'});
	}

	printf "\n%s: %d message(s)", $domain, $messages;
	printf ", %d not from %s", $unexpected, join('/', @expected) if($unexpected);
	print "\n";

	printf "  %-16s %8s %8s %8s  %s\n", 'source_ip', 'messages', 'passed', 'failed', 'status';
	foreach my $ip (sort { $by_ip->{$b}{'count'} <=> $by_ip->{$a}{'count'} || $a cmp $b } keys %{$by_ip}) {
		my $entry = $by_ip->{$ip};
		my $status = $entry->{'unexpected'} ? 'UNEXPECTED SOURCE' : ($entry->{'fail'} ? 'expected, failing auth' : 'expected, authenticating');
		printf "  %-16s %8d %8d %8d  %s\n", $ip, $entry->{'count'}, $entry->{'pass'}, $entry->{'fail'}, $status;
		my @dkim = sort keys %{$entry->{'dkim_seen'}};
		printf "  %-16s   dkim: %s\n", '', (@dkim ? join(', ', @dkim) : 'no signature seen');
	}
}

# Named after the totals, so the figures that explain them come first.
if(%misfiled) {
	print '=' x 78, "\n";
	printf "Filed by policy although it should not have been: %d message(s)\n", $misfiled_messages;
	printf "  %-22s %-16s %-11s %8s  %s\n", 'domain', 'source_ip', 'disposition', 'messages', 'why';
	foreach my $finding (sort {
		$a->{'domain'} cmp $b->{'domain'} || $b->{'count'} <=> $a->{'count'} || $a->{'ip'} cmp $b->{'ip'}
	} values %misfiled) {
		my $reason = $finding->{'expected'}
			? ($finding->{'passed'} ? 'expected sender, and authenticated' : 'expected sender')
			: 'authenticated';
		$reason .= ($finding->{'disposition'} eq 'reject') ? ', yet rejected' : ', yet quarantined';
		printf "  %-22s %-16s %-11s %8d  %s (dkim=%s spf=%s)\n",
			$finding->{'domain'}, $finding->{'ip'}, $finding->{'disposition'},
			$finding->{'count'}, $reason,
			join('/', sort keys %{$finding->{'dkim'}}), join('/', sort keys %{$finding->{'spf'}});
	}
}

print "\n";
if(%misfiled) {
	printf "%d message(s) were quarantined or rejected although they should not have been.\n", $misfiled_messages;
}
if($unexpected_messages) {
	printf "%d message(s) came from addresses that are not %s.\n", $unexpected_messages, join('/', @expected);
	exit(1);
}
exit(1) if(%misfiled);
print "Every message came from ", join('/', @expected), ", and none was filed by policy.\n";
exit(0);

__END__

=head1 NAME

dmarc-report - summarise DMARC aggregate reports and flag unexpected senders

=head1 SYNOPSIS

	dmarc-report [--dir DIR]... [--expected IP]... [--file-list FILE]

	# only the reports of one domain, watching a different host
	dmarc-report -d ~/Downloads -e 203.0.113.10

	# in a cron job: nonzero when anything came from elsewhere
	dmarc-report -d /var/reports/dmarc || echo 'unexpected sender'

=head1 DESCRIPTION

Summarises DMARC aggregate reports and flags every message that came from an
address other than the expected sender.

DMARC reports arrive as XML, sometimes gzipped, sometimes zipped, and usually
several at a time - the reports for C<example.org>, C<example.net> and
C<example.com> all land in the same mailbox.  This
reads a whole directory, prints what each report says, then gives the totals
per source address B<for each domain separately>, because an address that
legitimately sends for one domain is not thereby legitimate for another.

Pointing it at a downloads directory is safe: a file too large to be a report
is never opened, and a file that does not contain a C<< <feedback> >> document
is passed over, so installers, archives and data sets in the same directory
cost nothing.

Any source address that is not one of the expected hosts is marked, and so is
an expected host whose mail did not authenticate, since that is the case worth
looking at: it means the host is sending but the signature or the SPF record
is wrong.

Two more cases are marked, because they are the ones that decide whether the
policy can go further: a message that passed DKIM or SPF and was quarantined
or rejected anyway, and a message from an expected host that was quarantined
or rejected.  The first means the receiver took a stricter view of alignment
than the report's own verdicts suggest, and the second means our own mail is
being filed, which has to be put right before moving on to C<p=reject>.

The totals are kept per domain because the reports for several domains arrive
at the same mailbox: an address that legitimately sends for one domain is not
thereby legitimate for another, so adding the figures together would hide both
a real sender and a real problem.

=head2 Running it

	./dmarc-report.pl                                  # ~/Downloads, or $DMARC_DIR
	./dmarc-report.pl -d ~/Downloads -d /var/reports/dmarc
	./dmarc-report.pl -e 192.0.2.10 -e 203.0.113.10    # allow more than one sender
	perldoc dmarc-report.pl                            # full options

There is no built-in expected sender: give C<--expected>, or set
C<DMARC_EXPECTED> to one or more addresses separated by commas or spaces.
C<--dir> and C<--expected> can each be given more than once.

Only C<*.xml>, C<*.xml.gz> and C<*.zip> are considered.  A file over 10 MB is
never opened and a file that does not contain a C<< <feedback> >> document is
skipped, so pointing it at a downloads directory full of installers and data
sets costs nothing - it finishes in well under a second.

=head2 Reading the output

Per report first, one line per source address:

	google.com!example.org!1794355200!1794441599.xml
	  reporter : google.com   report_id: 9250231420970591661
	  period   : 2026-11-11 00:00 UTC -> 2026-11-11 23:59 UTC
	  domain   : example.org   p=none sp=none adkim=r aspf=r pct=100
	  198.51.100.23        8  dkim=fail  spf=fail     none      from=example.org  <== NOT 192.0.2.10
	      dkim seen: none
	      spf  seen: example.org=softfail

=over 4

=item * C<domain> / C<p=> is the policy the receiving site applied, so C<p=none> means nothing was blocked and these figures are observation only.

=item * C<dkim=> and C<spf=> are the verdicts DMARC made; C<dkim seen:> and C<spf seen:> are what the report says the message actually offered.

=item * C<dkim seen: none> means the message carried no signature at all, which is a different problem from a signature that failed to verify.

=item * C<< <== authenticated, but quarantined >> - DKIM or SPF passed and the receiver filed the message regardless.

=item * C<< <== expected sender, quarantined >> - our own host's mail was filed by the policy.

=back

Then the totals, grouped by domain:

	example.org: 4 message(s)
	  source_ip        messages   passed   failed  status
	  192.0.2.10              4        4        0  expected, authenticating
	                     dkim: example.org/selector1=pass

	example.net: 3 message(s), 1 not from 192.0.2.10
	  source_ip        messages   passed   failed  status
	  192.0.2.10              2        2        0  expected, authenticating
	  198.51.100.9            1        0        1  UNEXPECTED SOURCE

	example.com: 1 message(s)
	  source_ip        messages   passed   failed  status
	  192.0.2.10              1        0        1  expected, failing auth

The C<status> column is the thing to read; these are its values and their meaning:

=over 4

=item C<expected, authenticating> - an expected host sent it and DKIM or SPF passed, which is what you want

=item C<expected, failing auth> - an expected host sent it, but the signature or SPF record did not hold up: the sending side is broken

=item C<UNEXPECTED SOURCE> - something else sent as the domain: a forwarder, another mail client, or forgery

=back

The same address appears in each domain's block with that domain's own counts,
never one merged figure.

Then, only when there are any, the messages that were filed although they
should not have been:

	==============================================================================
	Filed by policy although it should not have been: 4 message(s)
	  domain                 source_ip        disposition  messages  why
	  example.org             198.51.100.7     quarantine          4  authenticated, yet quarantined (dkim=pass spf=fail)

	4 message(s) were quarantined or rejected although they should not have been.

A quarantine or rejection is worth acting on even when every sender is
expected: at that point the mail is not being delivered, so the report has
moved from describing a problem to causing one.

=head2 Exit status

C<0> when every message came from an expected sender and none was quarantined
or rejected, C<1> when something else did or when a message was filed anyway,
C<2> on a usage error, so it is safe in a cron job:

	dmarc-report.pl -d /var/reports/dmarc || echo 'unexpected sender'

C<expected, failing auth> does not by itself make it exit 1: it is a delivery
problem on our side, not a foreign sender.  A quarantine or rejection does,
since by then the mail is being filed rather than delivered.  Errors (no reports found, a
missing directory) exit non-zero with the reason on stderr.

=head1 OPTIONS

=over 4

=item B<--dir>, B<-d> DIR

A directory of reports.  May be given more than once.

=item B<--expected>, B<-e> IP

A host that is allowed to send as these domains.  May be given more than
once.  Defaults to the addresses in C<DMARC_EXPECTED>, separated by commas or
spaces; if neither is given the tool stops with a usage error rather than
guess which host is meant.

=item B<--file-list> FILE

Write to FILE the path of every report that was read, one per line.  Only
files that were actually summarised are listed: the installers, archives and
data sets that share the directory are not, so a caller can safely move what
is named there out of the way and have the next run report only what is new.

=item B<--help>, B<-h>

Print this documentation.

=back

=head1 ENVIRONMENT

=over 4

=item C<DMARC_DIR>

The directory of reports, when C<--dir> is not given.  Default
C<$HOME/Downloads>.

=item C<DMARC_EXPECTED>

The hosts allowed to send as these domains, when C<--expected> is not given:
addresses separated by commas or spaces.  With neither this nor
C<--expected>, the programme stops rather than guess which host is meant.

=item C<HOME>

Where the default directory of reports is: C<$HOME/Downloads>.

=back

=head1 WEEKLY CHECK

C<dmarc-weekly.sh> is the cron wrapper: silent when the run is clean - every
message from an expected sender and nothing quarantined or rejected - and
otherwise a mail to C<MAIL_TO> - C<alerts@example.org> by default - with the
full output.  It is meant to be installed in a crontab, on Monday mornings or
whenever suits.

	DRY_RUN=1 dmarc-weekly.sh     # show what would be mailed, send nothing
	dmarc-weekly.sh --crontab     # print the line to paste into a crontab

C<--crontab> prints rather than installs: a ready-made line carrying the
wrapper's absolute path and the C<DMARC_EXPECTED>, C<MAIL_TO> and C<PERL>
settings the run needs, because a crontab starts with almost no environment.
That printed line is the one to paste: no example crontab file is shipped or
installed, because the path, the perl and the addresses differ on every machine
and an example carrying somebody else's values cannot be pasted.  An annotated
one to read is in L<Mail::Send::DKIM/A CRONTAB ENTRY>, which sets out what each
setting is for.  C<DMARC_DIR> and C<DMARC_ARCHIVE_DIR> are left out of the line
because they have defaults - C<~/Downloads> and C<~/dmarc-archive> - and only
need naming when the reports or the archive live somewhere else.

It probes for the perl it puts in C<PERL> rather than assuming a path for it:
C<perl> on C<PATH> first, then the perlbrew perls under C<$HOME>, newest first,
taking the first that can load C<XML::PP>, because cron's C<PATH> often
holds only a system perl without the module, and a path guessed from one
machine's layout is a guess about everybody's; set C<PERL> to choose another.
The expected sender
comes from C<DMARC_EXPECTED>, which the crontab has to provide.  Failures are
always appended to C<~/dmarc-report.log>.

The mail step prefers C<MAIL_COMMAND> when it is set - anything that reads a
message with headers on stdin.  Otherwise it uses F<mail-dkim> from its own
directory, so the alert is signed for the domains in C<DKIM_DOMAINS> with the
key in C<DKIM_KEYDIR> and authenticates at the far end like the rest of the
site's mail; it is sent as C<MAIL_FROM>, which defaults to C<MAIL_TO>, and
C<MAIL_DKIM> names a different signer.  A signer that cannot sign, or cannot
send, falls through to C<mail>, C<mailx> or C<sendmail>, and with none of them
there the output is logged and printed to stderr: a missing transport loses no
report.

Once summarised, a report is moved into C<$HOME/dmarc-archive> (override with
C<DMARC_ARCHIVE_DIR>), so each week reports that week's mail rather than
repeating last week's, and nothing accumulates next to the downloads.  The
archive lives outside C<DMARC_DIR> on purpose.

Only the files the summariser actually read are moved - C<dmarc-report.pl
--file-list FILE> names them - so the installers and data sets sharing the
directory stay put.  A report fetched twice keeps both copies, the second
renamed with a timestamp.  C<DMARC_ARCHIVE=0> turns archiving off; a run with
nothing new exits 0 and says nothing.

=head1 SIGNING THE MAIL

A report tells you what the receivers made of the mail; a signature is what
makes a copy of it forwarded by someone else stop looking like a forgery, and
is what C<p=quarantine> and C<p=reject> are cheap enough to ask for.
C<bin/mail-dkim> is that half of the job: put it where a CGI script or a
crontab calls sendmail(1) and the message is signed on its way out, with no
change to the script that sends it.  The signing itself is L<Mail::Send::DKIM>,
which the programme is a thin front end to.

	DKIM_DOMAINS=example.org DKIM_KEYDIR=~/dkim mail-dkim -t -f webmaster@example.org < message

Only the domains named in C<DKIM_DOMAINS> are signed.  Everything else - a
foreign C<From:>, a missing key, a message with no C<From:> at all - is passed
to sendmail untouched, so installing it cannot stop mail being delivered.
C<perldoc bin/mail-dkim> has the key layout and the rest.

=head1 COOKBOOK: TRENDS ACROSS REPORTERS

C<dmarc-report.pl> answers "is anything wrong this week".  L<Database::BI>
answers the questions that need several reports at once: whether Gmail and
Outlook are seeing the same spoofing run, which addresses are new today,
whether the quarantine share matches C<pct>, and how the volume moved when the
policy tightened.

BI reads the report files themselves.  It takes each repeated C<record> element
as a row and names every column after the path it followed to reach the value,
so the nesting costs nothing:

	report_metadata_org_name          google.com
	report_metadata_date_range_begin  1794614400
	policy_published_p                quarantine
	policy_published_pct              25
	row_source_ip                     198.51.100.23
	row_count                         5
	row_policy_evaluated_disposition  quarantine
	identifiers_header_from           example.org
	auth_results_spf_result           softfail

The columns differ from one reporter to the next - Google sends
C<extra_contact_info>, Microsoft sends C<fo> and the envelope addresses, and
neither fills every field - but nothing has to be converted first.

=head2 Opening a report

Start the viewer from the root of the Database-BI distribution: the templates
are loaded from C<web/> relative to the current directory, so the
C<database-bi> installed on C<PATH> renders "Could not render a response"
when started anywhere else.  Then open a file with I<Open file...>:

	database-bi

Archived names contain C<!>, so pick the file rather than typing a URL; the
URL behind the panel is C</open?path=~/dmarc-archive/...xml> with the
name percent-encoded.

=head2 Several reports at once

C</combine> stacks whole reports into one table, which is what makes a trend
visible.  The first is C<l=>, every further one C<c=>:

	/combine?l=path:~/dmarc-archive/google.com!...!1794355200!1794441599.xml
		&c=path:~/dmarc-archive/google.com!...!1794441600!1794527999.xml

Every column from every source appears and cells are blank where a reporter
does not send that field, so Google and Microsoft reports stack together
cleanly.  In the browser the same thing is the I<Combine data> panel.

=head2 Questions worth asking

=over 4

=item * Which reporters see the campaign?

Filter C<report_metadata_org_name> to C<google.com> and to
C<protection.outlook.com>, or stack both with C</combine> and pivot
C<report_metadata_org_name> against C<report_metadata_date_range_begin>
summing C<row_count>.  Two reporters listing the same address on the same day
is one run of mail reaching both, not two separate ones.

=item * Is our own mail getting through?

Filter C<row_source_ip> to your expected sender.  Every row
should have C<row_policy_evaluated_disposition> C<none> and a passing
C<row_policy_evaluated_dkim> or C<row_policy_evaluated_spf>.  If it shows
C<quarantine>, the policy is catching your own mail and the record needs
changing back.

=item * Is C<pct> doing what it says?

Filter C<row_policy_evaluated_disposition> to C<quarantine> and compare its
share of C<row_count> with C<policy_published_pct> in the same report.  The
same address appearing under both C<quarantine> and C<none> in one report is
the sampling working as intended.

=item * What is new?

Sort by C<report_metadata_date_range_begin>, then C<row_source_ip>.  An address
under one day only is either a one-off or a new sender; an address under
several days is a campaign.

=item * Who is sending most?

Pivot C<row_source_ip> against C<row_count>, summed and sorted descending.

=back

The date columns are epoch seconds, so they sort correctly as numbers.  A chart
can bucket them by day with C<span=1d&agg=sum>, but the buckets follow the
timezone of the machine running BI (C<America/New_York> here), so a report that
begins at 00:00 UTC lands on the previous local day: the label is the day it
ended as much as the day it began.

=head2 What the rows cannot tell you

Reports contain every message the receiver evaluated, not only the ones it
quarantined: C<row_policy_evaluated_disposition> is what happened, and a report
full of C<quarantine> rows still describes mail delivered to a spam folder
rather than refused.  A reporter that stops sending looks exactly like a quiet
week, so absence of rows is worth noticing.  And BI reads the files you point
it at rather than hunting for new ones, so open the archive once the weekly
wrapper has put this week's reports in it.

=head1 TESTS

	prove t/            # or: prove -v t/dmarc-report.t

The tests run the scripts as programs, because the exit status is half of what
they check, and they build their fixtures in a temporary directory - no
network, no real reports needed.

C<t/dmarc-report.t> covers each of the three formats, a gzipped CSV and a
B<3 GB sparse C<.zip>> that must be skipped in under two seconds, and the exit
status for expected, failing and foreign senders.

C<t/dmarc-weekly.t> covers what the wrapper does with the files, which is its
own behaviour rather than the summariser's.  Each run gets its own C<HOME>, so
the archive and log defaults land in the temporary directory:

=over 4

=item * a dry run moves nothing and creates no archive directory, on a week with a finding and on a clean one - the clean case is what once archived the lot

=item * a repeat download is kept beside the first copy under a timestamp, not on top of it

=item * an empty reports directory exits 0 without a word, while a missing one still fails and says why

=item * a finding is mailed, and the mail says how many reports were archived.

=back

C<t/mail-dkim.t> makes its own key pair at run time and proves that the
signature L<Mail::Send::DKIM> produces verifies against it, through a stubbed
DNS lookup, so no key material is in the repository.  It calls the module
directly - no process, no captured message - and covers the messages that have
to pass through unsigned and the errors that have to be warnings.  The
programme itself is then tested only for its wiring: stdin in, sendmail's
arguments out, sendmail's exit status back.

C<t/readme.t> runs pod2github over L<Mail::Send::DKIM> - the module this
distribution is named after - and fails if the committed README.md is not what
it produces, so the two cannot drift apart.  Regenerate it with:

	pod2github lib/Mail/Send/DKIM.pm > README.md

The title in that output comes from C<.pod2github-header.md>, named by
C<.pod2github.yml>: the generator shifts the POD headings down a level, which
would otherwise leave the README with no H1 at all.

Requires C<Test::Most>, C<XML::PP>, C<IO::Compress::{Gzip,Zip}>,
C<IO::Uncompress::{Gunzip,Unzip}>, C<Readonly>, C<Time::HiRes>, C<Mail::DKIM> and
C<Net::DNS>.

=head1 SEE ALSO

L<Mail::Send::DKIM>, the module that signs the mail these reports describe; it
is also the name of the distribution this programme is installed from, which is
why F<Makefile.PL> and F<Changes> carry that name rather than this one, and why
the project's README.md is that module's page and not this one.
C<mail-dkim> is the sendmail front end for the module and has a page of its own
(C<perldoc mail-dkim>); F<dmarc-weekly.sh> runs this programme from cron, and
F<dmarc-check-mail.pl> sends one test message so that its signature can be read
at the far end.

=cut
