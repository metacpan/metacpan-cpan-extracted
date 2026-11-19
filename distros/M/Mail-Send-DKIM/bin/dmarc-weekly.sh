#!/bin/sh
#
# The POD below is this programme's description: perldoc dmarc-weekly.sh.  It is
# held in a here-document that the shell discards, because POD lines are not
# comments and a shell would try to run them.
: <<'POD'
=pod

=head1 NAME

dmarc-weekly.sh - run the DMARC check weekly and mail what needs looking at

=head1 SYNOPSIS

	dmarc-weekly.sh

	dmarc-weekly.sh --crontab

=head1 DESCRIPTION

Meant to be run from cron.  It runs C<dmarc-report.pl> over C<DMARC_DIR> and is
silent when every message came from the expected sender.  When the report exits
non-zero it sends the full output to C<MAIL_TO>, and appends a timestamped copy
to C<DMARC_LOG> as well, so that a week in which no transport was available
still leaves the information behind.

The reports that were summarised are then moved into C<DMARC_ARCHIVE_DIR>, so
that the next run reports that week's mail rather than repeating this one's. 
The archive is deliberately outside the reports directory, which is a downloads
folder; only the files the report says it read are moved, because such a folder
also holds things that are not reports.

The alert goes out through the first transport that works: C<MAIL_COMMAND>, then
the site's signer, then mail(1), mailx(1) and sendmail(1).

A week with no reports at all is not a failure: the report says so, and this
exits 0 without mailing.

=head1 OPTIONS

Only the first argument is looked at; anything else is ignored.

=over 4

=item B<--crontab>

Print a commented crontab line and exit 0, rather than installing one: the line
depends on where these programmes landed and which perl on this machine has
L<XML::PP>, and this is the one place that knows both.  The perl is written
as an absolute path, so cron's small C<PATH> cannot find a different one.  The
expected sender in the line is C<DMARC_EXPECTED>, or C<192.0.2.10> as a
placeholder to replace.

=back

=head1 ENVIRONMENT

=over 4

=item C<DMARC_DIR>

The directory of reports to summarise.  Default C<$HOME/Downloads>.

=item C<DMARC_ARCHIVE_DIR>

Where the summarised reports are moved.  Default C<$HOME/dmarc-archive>.

=item C<DMARC_ARCHIVE>

Set to 0 to leave the reports where they are.

=item C<DMARC_EXPECTED>

The one source expected to send these domains' mail, so that every other source
is a finding.  C<dmarc-report.pl> reads it - this passes its own environment on
- and C<--crontab> puts it in the line it prints.

=item C<DMARC_LOG>

The file a failure is appended to.  Default C<$HOME/dmarc-report.log>.

=item C<MAIL_TO>

Where the alert goes.  Default C<alerts@example.org>.

=item C<MAIL_FROM>

The envelope sender, which is also the header C<From:>.  Default C<MAIL_TO>.

=item C<MAIL_COMMAND>

A command that reads a complete message, headers included, on standard input,
and is used before anything else, e.g.
C<MAIL_COMMAND='ssh mail.example.com /usr/sbin/sendmail -t'>.

=item C<MAIL_DKIM>

The signer the alert is piped through.  Default C<mail-dkim> next to this
script, which signs for whatever C<DKIM_DOMAINS>, C<DKIM_KEYDIR> and
C<DKIM_SELECTOR> the site already sets, so the alert authenticates like the
rest of its mail.  A signer that cannot send - no key, no sendmail behind it -
falls through to mail(1), mailx(1) and sendmail(1) rather than costing the
week's report.

=item C<PERL>

The perl the report is run with, when the caller names one.  Left unset, the
first perl that can load L<XML::PP> is used: C<perl> on C<PATH>, then the
perlbrew perls under C<$HOME/perl5/perlbrew/perls>, newest first, then
F</usr/local/bin/perl>, F</usr/bin/perl> and F</opt/homebrew/bin/perl> - the
paths are probed rather than assumed, because a cron job's C<PATH> usually
holds only the system perl, which often cannot load the module.  When none of
them can, plain C<perl> is used, so that the run fails with the module's own
complaint - logged and mailed - rather than the week going unchecked without a
word.

=item C<DRY_RUN>

Set to 1 to rehearse: print what would be mailed and how many reports would be
archived, and move nothing.  The finding is still appended to C<DMARC_LOG>;
only the moving is held back.

=item C<TMPDIR>

Where the per-run list of reports read is kept.  Default C</tmp>.

=back

=head1 EXIT STATUS

C<0> when the week was clean, when there were no reports to summarise, and for
C<--crontab>.  Otherwise the exit status of C<dmarc-report.pl>, passed through
unchanged: it is non-zero when something needed looking at.  The mail is still
attempted and C<DMARC_LOG> is still written, and when no transport would take
the message it is written to standard error as well, which cron keeps, but that
does not change the status.

Failing to tidy up - an archive directory that cannot be created, a report that
cannot be moved - is reported on standard error and does not change the status
either: the week's finding is what the status is for.

=head1 SEE ALSO

C<dmarc-report.pl>, which does the summarising; C<mail-dkim>, which signs the
alert; and C<dmarc-check-mail.pl>, which tests a host's mail from outside.

=cut

POD

set -u

SELF_DIR=$(cd "$(dirname "$0")" && pwd)
REPORT="$SELF_DIR/dmarc-report.pl"

# The perl the report runs with has to be one that can load XML::PP, which
# the system perl a cron job's PATH finds often cannot, so the candidates are
# tried rather than one path assumed.  A PERL named by the caller is used as it
# stands: the caller has chosen, and a perl that turns out not to work is
# better complained about than silently replaced.
perl_has_xmlpp()
{
	"$1" -MXML::PP -e 1 > /dev/null 2>&1
}

find_perl()
{
	{
		command -v perl 2>/dev/null
		# perlbrew keeps a directory per installed perl, and the newest is
		# the one most likely to have the module.
		ls -1d "$HOME"/perl5/perlbrew/perls/*/bin/perl 2>/dev/null | sort -r
		printf '%s\n' /usr/local/bin/perl /usr/bin/perl /opt/homebrew/bin/perl
	} | while IFS= read -r candidate; do
		[ -x "$candidate" ] || continue
		if perl_has_xmlpp "$candidate"; then
			printf '%s\n' "$candidate"
			break
		fi
	done
}

if [ -z "${PERL:-}" ]; then
	PERL=$(find_perl)
fi
# Nothing on this machine has the module: plain perl is still tried, so the run
# fails with the module's own complaint - logged and mailed - rather than the
# week going unchecked without a word.
[ -n "${PERL:-}" ] || PERL=perl

REPORTS=${DMARC_DIR:-$HOME/Downloads}
ARCHIVE=${DMARC_ARCHIVE_DIR:-$HOME/dmarc-archive}
MAIL_TO=${MAIL_TO:-alerts@example.org}
LOG=${DMARC_LOG:-$HOME/dmarc-report.log}
SUBJECT="DMARC: mail that needs looking at"
SELF="$SELF_DIR/$(basename "$0")"
FROM=${MAIL_FROM:-$MAIL_TO}
# The signer that ships next to this script, which signs for whatever
# DKIM_DOMAINS, DKIM_KEYDIR and DKIM_SELECTOR say.  MAIL_DKIM names another.
MAIL_DKIM=${MAIL_DKIM:-$SELF_DIR/mail-dkim}

# Printing the crontab line, not installing it: what a crontab needs depends on
# where the programmes landed and which perl has XML::PP on this machine,
# and this is the one place that knows both.
if [ "${1:-}" = '--crontab' ]; then
	# cron runs with a tiny PATH, so a bare 'perl' in the line would find the
	# system one, or none at all.
	cron_perl=$PERL
	case "$cron_perl" in
		/*) ;;
		*) cron_perl=$(command -v "$PERL" 2>/dev/null || printf '%s' "$PERL") ;;
	esac

	printf '# DMARC weekly check; nothing is mailed when the week is clean.\n'
	printf '# Replace the expected sender: it is what makes another one a finding.\n'
	printf '0 6 * * 1 DMARC_EXPECTED=%s MAIL_TO=%s PERL=%s %s\n' \
		"${DMARC_EXPECTED:-192.0.2.10}" "$MAIL_TO" "$cron_perl" "$SELF"
	printf '# Add DMARC_DIR=... and DMARC_ARCHIVE_DIR=... if they are not the defaults.\n'
	exit 0
fi

MOVED=0

# A temporary file per run, so two runs cannot tread on each other's list.
LIST=$(mktemp "${TMPDIR:-/tmp}/dmarc-read.XXXXXX") || LIST=
trap 'if [ -n "${LIST:-}" ]; then rm -f "$LIST"; fi' EXIT HUP INT TERM

if [ -n "$LIST" ]; then
	output=$("$PERL" "$REPORT" -d "$REPORTS" --file-list "$LIST" 2>&1)
else
	output=$("$PERL" "$REPORT" -d "$REPORTS" 2>&1)
fi
status=$?

# Move aside the reports just summarised.  A name already in the archive is
# kept: the same report can legitimately be fetched twice, and the second copy
# must not overwrite the first.
archive_reports()
{
	# A rehearsal must not have side effects, and this is the one place that
	# moves files, so every caller is covered by the check being here.
	if [ "${DRY_RUN:-0}" = 1 ] || [ "${DMARC_ARCHIVE:-1}" = 0 ]; then
		return 0
	fi
	if [ -z "$LIST" ] || [ ! -s "$LIST" ]; then
		return 0
	fi

	if ! mkdir -p "$ARCHIVE"; then
		echo "dmarc-weekly: cannot create $ARCHIVE; reports left where they are" >&2
		return 1
	fi

	while IFS= read -r report_file; do
		[ -n "$report_file" ] || continue
		[ -f "$report_file" ] || continue
		target="$ARCHIVE/$(basename "$report_file")"
		if [ -e "$target" ]; then
			target="$target.$(date +%Y%m%d%H%M%S)"
		fi
		if mv -- "$report_file" "$target"; then
			MOVED=$((MOVED + 1))
		fi
	done < "$LIST"

	return 0
}

# Nothing new this week is the normal quiet outcome once the previous reports
# have been archived, so it is not a failure to report.
case "$status" in
	0) ;;
	*)
		case "$output" in
			*"No reports found"*)
				archive_reports
				exit 0
				;;
		esac
		;;
esac

if [ "$status" -eq 0 ]; then
	archive_reports
	exit 0
fi

printf '%s  %s  exit %s\n%s\n\n' "$(date '+%Y-%m-%d %H:%M')" "$REPORTS" "$status" "$output" >> "$LOG"

message="DMARC check of $REPORTS at $(date '+%Y-%m-%d %H:%M') exited $status.

Addresses that are not the expected sender are marked UNEXPECTED SOURCE.
'expected, failing auth' is different: an expected host sent it, but its
signature or SPF record did not hold up, and that is a sending problem on our
side.
A message marked 'authenticated, but quarantined' passed DKIM or SPF and was
filed anyway, and 'expected sender, quarantined' means our own mail is being
filed; both are listed again under 'Filed by policy'.

$output"

if [ "${DRY_RUN:-0}" = 1 ]; then
	printf 'would mail %s\n%s\n' "$MAIL_TO" "$message"
	# grep -c exits 1 when it counts nothing, so the count is kept before its
	# status is allowed to matter; an unreadable list means nothing to move.
	count=$(grep -c . "$LIST" 2>/dev/null) || count=0
	printf 'would archive %s report(s) to %s\n' "$count" "$ARCHIVE"
	exit "$status"
fi

archive_reports
if [ "$MOVED" -gt 0 ]; then
	message="$message
$MOVED report(s) moved to $ARCHIVE."
fi

sent=0
headers=$(printf 'From: %s\nTo: %s\nSubject: %s\n\n' "$FROM" "$MAIL_TO" "$SUBJECT")

# A command that reads a complete message on stdin, headers included.
if [ -n "${MAIL_COMMAND:-}" ]; then
	printf '%s%s\n' "$headers" "$message" | sh -c "$MAIL_COMMAND" && sent=1
fi

# The site's own signer, so the alert authenticates like the rest of the mail
# from here.  A signer that fails - no key, no sendmail behind it - falls
# through to the transports below rather than costing the week's report.
if [ "$sent" -eq 0 ] && [ -x "$MAIL_DKIM" ]; then
	printf '%s%s\n' "$headers" "$message" | "$MAIL_DKIM" -t -f "$FROM" && sent=1
fi

# mail(1) and mailx(1) add the headers themselves from -s, so they are given
# the body rather than the whole message.
if [ "$sent" -eq 0 ] && command -v mail > /dev/null 2>&1; then
	printf '%s\n' "$message" | mail -s "$SUBJECT" "$MAIL_TO" && sent=1
fi

if [ "$sent" -eq 0 ] && command -v mailx > /dev/null 2>&1; then
	printf '%s\n' "$message" | mailx -s "$SUBJECT" "$MAIL_TO" && sent=1
fi

if [ "$sent" -eq 0 ] && command -v sendmail > /dev/null 2>&1; then
	printf '%s%s\n' "$headers" "$message" | sendmail -t && sent=1
fi

if [ "$sent" -eq 0 ]; then
	# Nothing could send it.  Say so on stderr, which cron keeps, and leave the
	# exit status non-zero so the week is not mistaken for a clean one.
	echo "dmarc-weekly: no mail transport; output is in $LOG" >&2
	printf '%s\n' "$message" >&2
fi

exit "$status"
