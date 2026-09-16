#!/usr/bin/env perl

# Build obituaries.sql from:
#   https://wayback.archive-it.org  (mlarchives mirror, pages 1-18 only)
#   https://www.freelists.org/list/obitdailytimes
#   https://www.funeral-notices.co.uk
#   __DATA__ section (locally curated records)
#
# -f    Force rebuild even if the file is less than a day old or we are
#       running on a CI smoker.

use strict;
use warnings;
use autodie qw(:all);

use Carp qw(confess croak);
use Data::Dumper;
use DBI;
use File::HomeDir;
use File::Slurp;
use File::Spec;
use HTML::Entities;
use HTTP::Cache::Transparent;
use Lingua::EN::NameCase qw(nc);
use LWP::ConnCache;
use LWP::UserAgent::WithCache;
use Readonly;
use Text::CSV;
use Try::Tiny;
use URI::Escape qw(uri_escape);

# Suppress non-fatal "uninitialized" warnings from HTML parsers; fatal-ise
# them if they occur inside our own business logic.
BEGIN {
	$SIG{__WARN__} = sub {
		my $w = shift;
		if($w =~ /^Use of uninitialized value/ || $w =~ /isn't numeric in numeric eq /i) {
			die $w;
		}
		warn $w;
	};
}

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
Readonly::Scalar my $QUEUE_FLUSH_THRESHOLD => 10_000;	# Rows before mid-run flush
Readonly::Scalar my $HTTP_TIMEOUT          => 60;
Readonly::Scalar my $CACHE_NO_UPDATE       => 60 * 60 * 24 * 7 * 31;	# ~1 month; archive never changes
Readonly::Scalar my $CACHE_MAX_AGE         => 30 * 24;
Readonly::Scalar my $DB_CACHE_PAGES        => -65536;	# 64 MB page cache for SQLite

my %normalised;	# Cache of normalise_name() results to reduce Lingua::EN::NameCase calls
my $force_flag;
my $dir  = 'lib/Genealogy/Obituary/Lookup/data';
my $bdir = File::Spec->catdir('blib', $dir);

# ---------------------------------------------------------------------------
# Guard: skip download on CI smokers unless -f is passed
# ---------------------------------------------------------------------------
if(defined($ARGV[0]) && ($ARGV[0] eq '-f')) {
	$force_flag++;
} elsif($ENV{'AUTOMATED_TESTING'}) {
	mkdir $dir, 0755 unless -d $dir;
	exit 0;
}

mkdir $dir, 0755 unless -d $dir;

my $filename = File::Spec->catdir($dir, 'obituaries.sql');

if(-r $filename) {
	# Skip rebuild if the file is fresh (less than a day old) and not forced
	if((-s $filename) > 0 && (-M $filename < 1) && !$force_flag) {
		exit;
	}
	unlink $filename;
}

# ---------------------------------------------------------------------------
# HTTP cache setup
# ---------------------------------------------------------------------------
my $cache_dir = $ENV{'CACHE_DIR'} || $ENV{'CACHEDIR'};
if($cache_dir) {
	mkdir $cache_dir, 0700 unless -d $cache_dir;
	$cache_dir = File::Spec->catfile($cache_dir, 'http-cache-transparent');
} else {
	$cache_dir = File::Spec->catfile(
		File::HomeDir->my_home(), '.cache', 'http-cache-transparent'
	);
}

HTTP::Cache::Transparent::init({
	BasePath => $cache_dir,
	Verbose  => 0,
	NoUpdate => $CACHE_NO_UPDATE,
	MaxAge   => $CACHE_MAX_AGE,
}) || die "$0: $cache_dir: $!";

print "This will take some time. It'd be best to go and make yourself a cup of tea.\n";

my $ua = $force_flag
	? LWP::UserAgent->new(timeout => $HTTP_TIMEOUT, keep_alive => 1)
	: LWP::UserAgent::WithCache->new(timeout => $HTTP_TIMEOUT, keep_alive => 1);
$ua->env_proxy(1);
$ua->agent('Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36');
$ua->conn_cache()->total_capacity(undef);
$Lingua::EN::NameCase::POSTNOMINAL = 0;

# ---------------------------------------------------------------------------
# Database setup
# ---------------------------------------------------------------------------
my $dbh = DBI->connect(
	"dbi:SQLite:dbname=$filename",
	undef, undef,
	{ RaiseError => 1, AutoCommit => 0, synchronous => 0, locking_mode => 'EXCLUSIVE' }
) || die "$filename: $!";

$dbh->do("PRAGMA cache_size = $DB_CACHE_PAGES");
$dbh->do('PRAGMA journal_mode = OFF');
$dbh->do(
	'CREATE TABLE obituaries('
	. 'first VARCHAR NOT NULL, middle VARCHAR, last VARCHAR NOT NULL,'
	. ' maiden VARCHAR, age INTEGER, place VARCHAR,'
	. ' newspaper VARCHAR NOT NULL, date DATE NOT NULL,'
	. ' source CHAR NOT NULL, page VARCHAR NOT NULL)'
);

my @queue;

# ---------------------------------------------------------------------------
# funeral-notices.co.uk — list of (surname => page_id) pairs
# ---------------------------------------------------------------------------
my %notices;
my $fn_list_url = 'https://www.nigelhorne.com/downloads/obt.txt';
my $fn_response = $ua->get($fn_list_url);
my $fn_data;
if($fn_response->is_success()) {
	$fn_data = $fn_response->decoded_content();
} else {
	die "$fn_list_url: ", $fn_response->status_line();
}

$fn_data =~ s/\r//g;
for my $line (split /^/ms, $fn_data) {
	chomp $line;
	next if $line =~ /^\s*$/;	# skip blank lines
	if($line =~ /^'(.+)' => (\d+),?$/) {
		$notices{$1} = $2;
	} else {
		die "$fn_list_url: can't parse line: $line";
	}
}

while(my($last, $page) = each %notices) {
	funeral_notices($last, $page);
}

# ---------------------------------------------------------------------------
# Locally curated records from __DATA__
# ---------------------------------------------------------------------------
import_data();
flush($dbh);

# ---------------------------------------------------------------------------
# mlarchives — Wayback Machine mirror of the Rootsweb ODT archive
# ---------------------------------------------------------------------------
if($ENV{'MLARCHIVE_DIR'} || $ENV{'MLARCHIVEDIR'}) {
	flush($dbh) if mlarchives($ua, 'other');
}

print ' ' x 78, "\r";

my $page = 1;
while(mlarchives($ua, $page)) {
	flush($dbh) if scalar(@queue) > $QUEUE_FLUSH_THRESHOLD;
	$page++;
}

print ' ' x 78, "\r";
flush($dbh);

# ---------------------------------------------------------------------------
# freelists.org — Obituary Daily Times volumes 25–31
# ---------------------------------------------------------------------------
my $issue = 9;
while(freelists($ua, 'v25no' . sprintf('%03d', $issue))) {
	flush($dbh) if scalar(@queue) > $QUEUE_FLUSH_THRESHOLD;
	$issue++;
}
flush($dbh);

$issue = 1;
while(freelists($ua, 'v26no' . sprintf('%03d', $issue))) {
	flush($dbh) if scalar(@queue) > $QUEUE_FLUSH_THRESHOLD;
	$issue++;
	$issue++ if $issue == 52;	# v26no052 does not exist on the server
}
flush($dbh);

foreach my $volume (27, 28, 29, 30, 31) {
	$issue = 1;
	while(freelists($ua, "v${volume}no" . sprintf('%03d', $issue))) {
		flush($dbh) if scalar(@queue) > $QUEUE_FLUSH_THRESHOLD;
		$issue++;
	}
	flush($dbh);
}

print "\n";
flush($dbh);

# ---------------------------------------------------------------------------
# Finalise the database
# ---------------------------------------------------------------------------
$dbh->commit();
$dbh->prepare('CREATE INDEX name_index ON obituaries(first, last)')->execute();
$dbh->prepare('CREATE INDEX name_age_index ON obituaries(first, last, age)')->execute();
$dbh->do('pragma optimize');
$dbh->disconnect();

# Symlink into blib so the installed copy matches the built one
if(-d $bdir) {
	my $bfilename = File::Spec->catdir($bdir, 'obituaries.sql');
	unlink($bfilename) if -e $bfilename;
	link $filename, $bfilename;
}

# ===========================================================================
# Subroutines
# ===========================================================================

# Import the locally curated data embedded in the __DATA__ section.
# Each row is CSV: first, middle, last, maiden, age, place, date, url
sub import_data
{
	local $| = 1;
	printf "%-70s\r", '<DATA>';

	my $parser = Text::CSV->new();
	while(<DATA>) {
		next unless $parser->parse($_);
		my ($first, $middle, $last, $maiden, $age, $place, $date, $url) = $parser->fields();
		queue($first, normalise_name($last), $maiden, $age, $place, $date, 'L', 'L', $url);
	}
}

# Fetch and parse one page (or a local file) from the mlarchives Wayback mirror.
# Returns 1 if more pages may follow, 0 if we should stop paging.
sub mlarchives
{
	my $ua   = shift;
	my $page = shift;

	my $url = "https://wayback.archive-it.org/20669/20231102044925/https://mlarchives.rootsweb.com/listindexes/emails?listname=gen-obit&page=$page";

	local $| = 1;
	printf "%-70s\r", $url if $page ne 'other';

	my @lines;
	if($ENV{'MLARCHIVEDIR'}) {
		my $base = File::Spec->canonpath($ENV{'MLARCHIVEDIR'});
		croak "MLARCHIVEDIR '$base' must be an absolute path"
			unless File::Spec->file_name_is_absolute($base);
		my $local = ($page eq 'other')
			? File::Spec->catfile($base, 'other')
			: File::Spec->catfile($base, "emails?listname=gen-obit&page=$page");
		croak "MLARCHIVEDIR path escapes base directory: $local"
			unless index(File::Spec->canonpath($local), $base) == 0;
		return 0 unless -r $local;
		printf "%-70s\r", $local if $page eq 'other';
		@lines = read_file($local);
	} elsif($ENV{'MLARCHIVE_DIR'}) {
		my $base = File::Spec->canonpath($ENV{'MLARCHIVE_DIR'});
		croak "MLARCHIVE_DIR '$base' must be an absolute path"
			unless File::Spec->file_name_is_absolute($base);
		my $local = ($page eq 'other')
			? File::Spec->catfile($base, 'other')
			: File::Spec->catfile($base, "emails?listname=gen-obit&page=$page");
		croak "MLARCHIVE_DIR path escapes base directory: $local"
			unless index(File::Spec->canonpath($local), $base) == 0;
		return 0 unless -r $local;
		printf "%-70s\r", $local if $page eq 'other';
		@lines = read_file($local);
	} else {
		my $response = $ua->get($url);
		if($response->is_success) {
			my $data = $response->decoded_content();
			$data =~ s/\r//g;
			@lines = split(/$/ms, $data);
		} else {
			if($response->status_line() ne '404 Not Found') {
				print STDERR "You may need to run bin/ml_from_cache\n";
				die "\n$url: ", $response->status_line();
			}
			return 0;
		}
	}

	$| = 0;

	# State machine: -1=header, 0=post-preamble, 1=post-content
	my $stage     = -1;
	my $last_line = undef;
	my $rc        = undef;

	while(my $line = shift @lines) {
		chomp $line;
		next unless length $line;
		next if defined($last_line) && $line eq $last_line;

		if($line =~ /The Obituary Daily Times \(ODT\) is/ ||
		   $line =~ /To unsubscribe from this mailing list, please send a message/) {
			$stage = 0;
			next;
		}
		last if $line =~ /^RootsWeb is funded and supported/;
		$last_line = $line;

		$line =~ s/^\n//;

		if($line =~ /^------/) {
			if($stage == -1) {
				if($line =~ /No Results/) {
					return 0;
				}
				if($line =~ /This page has not been archived here/) {
					# Wayback Machine reached the end of its archive
					return 0;
				}
				$stage = 0;
			} elsif($stage == 0) {
				$stage = 1;
			} else {
				$stage = 0;
			}
			next;
		} elsif($line =~ /^Obituary Results/) {
			$stage = 1;
			next;
		} elsif($stage == -1) {
			if($line =~ /^LAST NAME/) {
				$stage = 0;
			} elsif($line =~ /Re: \[GEN-OBIT\]/) {
				return 1;	# Reply thread, not an actual post
			} elsif($line =~ /No Results/) {
				return 0;
			} elsif($line =~ /This page has not been archived here/) {
				return 0;
			}
		}

		next unless $stage == 1;
		$line =~ s/^<[^>]*>//;		# strip leading HTML tag (e.g. <li>) injected by Wayback Machine
		next unless length $line;
		next if $line =~ /<\/p>.+/;
		next if $line =~ /^LAST NAME/;	# Unparsable header inside content
		next if $line =~ /^\s/;

		$line =~ s/&nbsp;/ /g;
		$line = decode_entities($line);
		$line =~ s/<[^>]*>//g;	# strip residual HTML tags injected by Wayback Machine
		$line =~ s/\s+$//;	# trim trailing whitespace left by stripping
		# Note: no s/'/''/g needed — values go through DBI placeholders in flush()

		# Every ODT entry contains semicolons; prose lines (moderator notes,
		# HTTP headers, plain URLs) never do — skip them before parsing.
		next unless index($line, ';') >= 0;

		my ($name, $age, $place, $newspaper, $date, $tag) = split(/;\s?/, $line);

		if(defined($age) && ($age =~ /D/)) {
			# Handle format anomaly: page=33 has location before newspaper
			my $unknown;
			($name, $place, $newspaper, $unknown, $date, $tag) = split(/;\s?/, $line);
			$age = undef;
		}

		# Colon used instead of semicolon after age (e.g. "65: City ST>City2 ST").
		# Extract the numeric age and shift the fused place into the place field.
		if(defined($age) && $age =~ /^(\d+):\s*(.+)$/) {
			($age, $place, $newspaper, $date, $tag) = ($1, $2, $place, $newspaper, $date);
		}

		# Age field contains a place name — the submitter omitted the age.
		# Ages never contain spaces; re-parse shifting fields left.
		if(defined($age) && $age =~ /[ >]/) {
			($place, $newspaper, $date, $tag) = ($age, $place, $newspaper, $date);
			$age = undef;
		}

		# Handle multi-line entries: long ODT records sometimes wrap across
		# lines in the original email.  Consume continuation lines until $date
		# is populated, stopping at a new ODT entry (ALL-CAPS surname) or a
		# section delimiter.
		while((!defined($date) || $date eq '') && @lines
				&& $lines[0] !~ /^[A-Z]{2}[A-Z\-]*,[ \t]/
				&& $lines[0] !~ /^-{6}/) {
			my $cont = shift @lines;
			chomp $cont;
			next unless length $cont;
			$line = "$line $cont";
			($name, $age, $place, $newspaper, $date, $tag) = split(/;\s?/, $line);
		}

		# Some entries split the tag onto the next line (e.g. page 135).
		# ODT tags are short lowercase alphanumeric codes; peek and consume
		# only if the next line matches that shape, so we don't eat a real entry.
		if((!defined($tag) || $tag eq '') && @lines && $lines[0] =~ /^\s*([a-z]\w{0,9})\s*$/) {
			$tag = $1;
			shift @lines;
		}

		# Trim trailing whitespace from all parsed fields.
		for my $f ($age, $place, $newspaper, $date, $tag) {
			$f =~ s/\s+$// if defined $f;
		}

		# Silently skip lines that aren't in ODT "SURNAME, First; ..." format.
		# Prose text (moderator announcements, URLs, etc.) reaches stage 1 on
		# some pages but has no comma-separated name and no semicolons.
		next unless defined $name;
		my ($last, $first) = split(/,\s/, $name);
		next unless defined($last) && defined($first);

		my $maiden;
		if($first =~ /(.+)\s\((.+)\)$/) {
			$first  = normalise_name($1);
			$maiden = normalise_name($2);
		} else {
			$first = normalise_name($first);
		}

		if($last =~ /^[A-Z]/) {
			queue($first, normalise_name($last), $maiden, $age, $place, $date, $newspaper, 'M', $page);
		}
		$rc = 1;
	}

	die "\nCouldn't parse $url: no valid entries found" unless defined $rc;
	return 1;
}

# Fetch and parse one issue of the Obituary Daily Times from freelists.org.
# Returns 1 if the issue existed, 0 if we should stop.
sub freelists
{
	my $ua   = shift;
	my $page = shift;
	my $url  = "https://www.freelists.org/post/obitdailytimes/Obituary-Daily-Times-$page";

	local $| = 1;
	printf "%-70s\r", $url;
	$| = 0;

	my $response = $ua->get($url);
	unless($response->is_success) {
		my $status = $response->status_line();
		return 0 if $status eq '404 Not Found';
		return 0 if $status eq '403 Forbidden';	# Freelists erroneously returns this sometimes
		die "\n$url: $status";
	}

	my $data = $response->decoded_content();
	$data =~ s/<br>/\n/g;
	$data =~ s/<br ?\/>/\n/g;
	$data =~ s/\n\n+/\n/g;
	my @lines = split /\n/ms, $data;

	my $rc    = undef;
	my $stage = 0;

	while(my $line = shift @lines) {
		$line =~ s/^\n//;
		next if $line eq '';

		if($line =~ /\-{8}/) {
			$stage++;
			last if $stage >= 3;
			$line =~ s/^.*\-+//;
			next if $line eq '' || $line eq '<br/>';
		}

		next if $stage != 2;

		$line =~ s/&nbsp;/ /g;
		$line =~ s/\x{a0}/ /g;
		$line = decode_entities($line);
		# Note: no s/'/''/g needed — values go through DBI placeholders in flush()

		my ($name, $age, $place, $newspaper, $date, $tag) = split(/;\s?/, $line);

		unless(defined($tag) && $tag ne '') {
			# Entry may span two lines — peek at the continuation
			my $cont = shift @lines;
			last if !defined($cont) || $cont =~ /^\-{8}/;
			$cont =~ s/^\n//;
			$cont =~ s/&nbsp;/ /g;
			$cont =~ s/\x{a0}/ /g;
			$cont =~ s/&gt;/>/g;
			$cont =~ s/&quot;/"/g;
			$line .= $cont;
			($name, $age, $place, $newspaper, $date, $tag) = split(/;\s?/, $line);
		}

		next unless defined $name;
		my ($last, $first) = split(/,\s/, $name);
		next unless defined($last) && defined($first);

		# Parsing is completely broken for some issues — stop at first sign of it
		last unless defined $newspaper;

		my $maiden;
		if($first =~ /(.+)\s\((.+)\)$/) {
			$first  = normalise_name($1);
			$maiden = normalise_name($2);
		} else {
			$first = normalise_name($first);
		}

		if($last =~ /^[A-Z]/) {
			queue($first, normalise_name($last), $maiden, $age, $place, $date, $newspaper, 'F', $page);
		}
		$rc = 1;
	}

	die "Couldn't parse $url (stage=$stage, no valid entries found)" unless defined $rc;
	return 1;
}

# Scrape a single funeral-notices.co.uk notice page.
sub funeral_notices
{
	my ($last, $page) = @_;

	my $url      = 'https://funeral-notices.co.uk/notice/' . uri_escape($last) . "/$page";
	my $real_last = $last;

	my $response = $ua->get($url);
	die "Failed to fetch $url: ", $response->status_line() unless $response->is_success();
	my $content = $response->decoded_content();

	my $maiden;
	if($last =~ /(.+)\+(.+)/) {
		$last      = $1;
		$real_last = $last;
		$maiden    = normalise_name($2);
		if($maiden eq 'Dr') {
			undef $maiden;
		} elsif($last eq 'mc') {
			$last      = "Mc$maiden";
			$real_last = "MC $maiden";
			undef $maiden;
		}
	}
	$real_last = "O'Neill" if $last eq 'oneill';

	if($content =~ /"Click here to view the tribute page for (.+?) \Q$real_last\E.*?"/is) {
		my $first = $1;
		my ($place, $age, $newspaper, $date);

		if($content =~ /aged (\d+) years/is || $content =~ /aged (\d+)[\.\s]/is || $content =~ /data-age="(\d+)"/is) {
			$age = $1;
		} else {
			warn "Can't find age in $url";
		}

		if(($content =~ /passed away at (.+?)\s+on\s+\d/is) && ($1 ne 'home')) {
			$place = $1;
		} elsif($content =~ /<h2>(.+)<span><span class="age_container">/is) {
			$place = $1;
		} else {
			die "Can't find location in $url";
		}
		# No s/'/''/g — DBI placeholder handles quoting
		$place .= ', United Kingdom';

		if($content =~ /published in:<\/span> (.+)<\/h2>/is) {
			$newspaper = $1 =~ /funeral-notices\.co\.uk\./ ? $url : $1;
		} else {
			die "Can't find publisher in $url";
		}
		$newspaper =~ s/\.$//;
		$newspaper =~ s/\s*<span.+<\/span>//;

		if($content =~ /Published: <\/span><span>([\d\/]+)/s) {
			$date = $1;
			# funeral-notices.co.uk returns DD/MM/YYYY; convert to ISO YYYY-MM-DD
			if($date =~ m{^(\d{1,2})/(\d{1,2})/(\d{4})$}) {
				$date = sprintf('%04d-%02d-%02d', $3, $2, $1);
			}
		} else {
			die "Can't find date in $url";
		}

		$last = normalise_name($last);
		queue($first, $last, $maiden, $age, $place, $date, $newspaper, 'L', $url)
			if $last =~ /^[A-Z]/;
	} elsif($content !~ /By request this notice has been.+removed from our site/is) {
		die "Can't parse $url (real_last=$real_last)";
	}
}

# Validate and enqueue one obituary record.
# Drops records whose date does not begin with a 4-digit year.
# Invalid ages (non-numeric, negative) are silently omitted; the record is kept.
sub queue
{
	my ($first, $last, $maiden, $age, $place, $date, $newspaper, $source, $page) = @_;

	die "Invalid source '$source' (must be M, F, or L)"
		unless $source =~ /^[MFL]$/;

	# Require a 4-digit year prefix — rejects merged/garbled lines like date='68'.
	return unless defined($date) && $date =~ /^\d{4}/;

	my %columns = (
		first     => $first,
		last      => $last,
		date      => $date,
		newspaper => $newspaper,
		place     => $place,
		source    => $source,
		page      => $page,
	);

	if(defined $age) {
		$age =~ s/\s+//g;
		# Invalid ages (non-numeric like 'infant', negative like '-91') are
		# silently omitted — the record is still useful without an age.
		$columns{age} = $age if length($age) && $age =~ /^\d+$/;
	}

	$columns{maiden} = $maiden if $maiden;

	push @queue, \%columns;
}

# Write all queued records to the database, deduplicating first.
# Uses parameterised INSERT to prevent SQL injection from scraped values.
sub flush
{
	my $dbh = shift;

	return unless @queue;

	# Deduplicate by building a canonical key from all significant fields
	my (%seen, @deduped);
	while(my $item = pop @queue) {
		my $key = join '|', map { $item->{$_} // '' }
			qw(first last maiden age place date newspaper source page);
		push @deduped, $item unless $seen{$key}++;
	}
	@queue = ();

	return unless @deduped;

	# Parameterised INSERT — DBI handles all escaping, no manual quoting needed
	my $sth = $dbh->prepare(
		'INSERT INTO obituaries'
		. '(first, middle, last, maiden, age, place, date, newspaper, source, page)'
		. ' VALUES (?,?,?,?,?,?,?,?,?,?)'
	);

	try {
		for my $row (@deduped) {
			my ($first, $middle);
			if($row->{'first'} && $row->{'first'} =~ /^(.+)\s+(.+)$/) {
				($first, $middle) = ($1, $2);
			} else {
				$first = $row->{'first'} || undef;
			}

			$sth->execute(
				$first,
				$middle,
				$row->{'last'},
				($row->{'maiden'} && $row->{'maiden'} ne ' ') ? $row->{'maiden'} : undef,
				$row->{'age'}   || undef,
				($row->{'place'} && length($row->{'place'})) ? $row->{'place'} : undef,
				$row->{'date'},
				$row->{'newspaper'},
				$row->{'source'},
				$row->{'page'},
			);
		}
	} catch {
		confess "Error in obituaries INSERT: $_";
	};
}

# Normalise a name to title case, caching results to avoid repeated calls to
# Lingua::EN::NameCase (which is expensive on large datasets).
sub normalise_name
{
	my $name = shift;
	$name =~ s/"//g;
	return $normalised{lc($name)} //= nc($name);
}

# "first","middle","last","maiden","age","place","date","url"
__DATA__
"David",,"Erickson",,92,"Stow, OH, USA","2024-01-22","https://www.beaconjournal.com/obituaries/pwoo0723808"
"Lowell","Alva","Frantz",,91,"Smithville, OH, USA","2024-02-18","https://www.the-daily-record.com/obituaries/pwoo0727773"
"McRae","David","Gordon",,74,"Little Falls, NY, USA","2024-02-23","https://www.legacy.com/us/obituaries/legacyremembers/david-mcrae-obituary?id=54446719"
"Joyce",,"Diver",,,"2024-02-16","https://funeral-notices.co.uk/notice/diver/5174279"
"Thomas","Andrew","Dlugosz",,72,"Wyandotte, MI, USA","2024-02-25","https://www.legacy.com/us/obituaries/name/thomas-dlugosz-obituary?id=54466889"
"Sheila",,"Kirkham",,,"2024-02-16","https://funeral-notices.co.uk/notice/kirkham/5174285"
"Irene",,"Caney",,,"2024-02-16","https://funeral-notices.co.uk/notice/caney/5174301"
"Irene",,"Caney",,,"2024-02-16","https://funeral-notices.co.uk/notice/caney/5174314"
"Mary",,"Clarke",,,"2024-02-16","https://funeral-notices.co.uk/notice/clarke/5174319"
"Ramesh",,"Chhabra",,,"2024-02-16","https://funeral-notices.co.uk/notice/chhabra/5174399"
"Phillip",,"Morris",,,"2024-02-16","https://funeral-notices.co.uk/notice/morris/5174455"
"Marjorie",,"Bray",96,,"2024-02-15","https://funeral-notices.co.uk/notice/bray/5174000"
"Dorothy",,"Daniels",,,"2024-02-15","https://funeral-notices.co.uk/notice/daniels/5174112"
"Malva",,"Ridge",88,,"2024-02-15","https://funeral-notices.co.uk/notice/ridge/5174115"
"Paul",,"Batchelor",60,,"2024-02-21","https://funeral-notices.co.uk/notice/batchelor/5175192"
"Pamela",,"Lambert",82,,"2024-02-24","https://funeral-notices.co.uk/notice/lambert/5175963"
"Rodney",,"Bishop",,84,"Brownwood, TX, USA","2024-02-26","https://www.brownwoodnews.com/2024/02/26/rodney-dwain-bishop/"
"Wallace","Elizabeth","Wallace",,65,"Algonquin Grace Hospice, AL, USA","2025-09-29","https://doppleronline.ca/huntsville/sharon-elizabeth-wallace/"
