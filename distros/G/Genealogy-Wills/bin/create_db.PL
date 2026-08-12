#!/usr/bin/env perl

# Create SQLite3 from https://freepages.rootsweb.com/~mrawson/genealogy/wills.html
#
# -f:	force a build, otherwise it won't build on CPAN smokers or if the
#	database is less than a day old

use strict;
use warnings;
use autodie qw(:all);
use feature 'state';
use Carp ();
use DBI;
use File::HomeDir;
use File::Spec;
use HTTP::Cache::Transparent;
use LWP::ConnCache;
use LWP::UserAgent::WithCache;
use Lingua::EN::NameCase qw(nc);
use Try::Tiny;

BEGIN {
	$SIG{__WARN__} = sub {
		my $warning = shift;
		if(($warning =~ /^Use of uninitialized value/) ||
		   ($warning =~ /isn't numeric in numeric eq /i)) {
			die $warning;
		}
		warn $warning;
	}
}

my $force_flag;
my $dir  = 'lib/Genealogy/Wills/data';
my $bdir = File::Spec->catdir('blib', $dir);

if(defined($ARGV[0]) && ($ARGV[0] eq '-f')) {
	$force_flag++;
} elsif($ENV{'AUTOMATED_TESTING'}) {
	if(!-d $dir) {
		mkdir $dir, 0755;
	}
	exit;
}

if(!-d $dir) {
	mkdir $dir, 0755;
}

my $filename = File::Spec->catdir($dir, 'wills.sql');

if(-r $filename) {
	# Don't bother downloading if the file is less than a day old
	if(((-s $filename) > 0) && (-M $filename < 1) && !$force_flag) {
		_sync_to_blib();
		exit;
	}
	unlink $filename;
}

# $ENV{CACHE_DIR}/$ENV{CACHEDIR} is external input: validate before use in
# file operations. A tainted or attacker-controlled path (e.g. ../../etc)
# could cause mkdir or HTTP::Cache::Transparent to write outside the
# intended cache tree. Only allow safe filesystem characters and reject
# path traversal sequences.
my $cache_dir_raw = $ENV{'CACHE_DIR'} // $ENV{'CACHEDIR'};
my $cache_dir;
if(defined $cache_dir_raw) {
	unless($cache_dir_raw =~ /\A[\w.\-\/~]+\z/ && index($cache_dir_raw, '..') < 0) {
		Carp::croak("Unsafe cache directory path in CACHE_DIR/CACHEDIR: $cache_dir_raw");
	}
	$cache_dir = $cache_dir_raw;
	mkdir $cache_dir, 0700 if(!-d $cache_dir);
	$cache_dir = File::Spec->catfile($cache_dir, 'http-cache-transparent');
} else {
	$cache_dir = File::Spec->catfile(File::HomeDir->my_home(), '.cache', 'http-cache-transparent');
}

HTTP::Cache::Transparent::init({
	BasePath => $cache_dir,
	Verbose  => 0,
	NoUpdate => 60 * 60 * 24 * 7 * 31,	# The archive never changes
	MaxAge   => 30 * 24
}) || Carp::croak("$0: $cache_dir: $!");

my $ua = LWP::UserAgent::WithCache->new(timeout => 10, keep_alive => 1);
$ua->env_proxy(1);
$ua->agent('Genealogy::Wills');
# $ua->agent('Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36');
$ua->conn_cache()->total_capacity(undef);
$Lingua::EN::NameCase::POSTNOMINAL = 0;

# RaiseError => 1 means DBI throws on failure before ever returning undef
my $dbh = DBI->connect("dbi:SQLite:dbname=$filename", undef, undef, { RaiseError => 1, AutoCommit => 0, synchronous => 0, locking_mode => 'EXCLUSIVE' });

$dbh->do('PRAGMA cache_size = -65536');	# 64MB
$dbh->do('PRAGMA journal_mode = OFF');
$dbh->do('CREATE TABLE wills(first VARCHAR NOT NULL, middle VARCHAR, last VARCHAR NOT NULL, town VARCHAR, year INTEGER, url VARCHAR)');

my @queue;
foreach my $page ('ab', 'c', 'dg', 'hj', 'km', 'nr', 'sv', 'wy') {
	mrawson($ua, $page);
	flush($dbh) if(scalar(@queue) > 200_000);
};

print ' ' x 78, "\r";

flush($dbh);

$dbh->commit();
$dbh->prepare('CREATE INDEX name_index ON wills(first, last)')->execute();
$dbh->prepare('CREATE INDEX name_index_year ON wills(first, last, year)')->execute();
$dbh->do('pragma optimize');
$dbh->disconnect();

print "\n";

_sync_to_blib();

sub _sync_to_blib {
	mkdir $bdir, 0755 unless -d $bdir;
	return unless -d $bdir && -r $filename;
	my $bfilename = File::Spec->catdir($bdir, 'wills.sql');
	unlink $bfilename if -e $bfilename;
	link $filename, $bfilename;
}

sub mrawson {
	my ($ua, $page) = @_;

	my $url = "https://freepages.rootsweb.com/~mrawson/genealogy/will_$page.html";

	# local $| flushes immediately and restores on scope exit
	local $| = 1;
	printf "%-70s\r", $url;

	my $response = $ua->get($url);

	my $data;
	if($response->is_success) {
		$data = $response->decoded_content();
	} else {
		# status_line() comes from the upstream server; concatenate (not
		# comma-list) to form one string before passing to Carp::croak.
		Carp::croak("\n$url: " . $response->status_line());
	}

	$data =~ s/\r//g;

	# for-loop over split avoids the shift-while idiom; split on \n is
	# faster than the /$/ms regex which re-evaluates $ anchors per character.
	for my $line (split /\n/, $data) {
		# LAST NAME, First Name; Place of Death; Newspaper date
		# index() is faster than regex for a pure literal substring check.
		return if index($line, 'Created by') >= 0;

		# Negated character classes prevent catastrophic backtracking that
		# greedy (.+) groups cause when the delimiter chars appear in the input.
		# The original (.+) for href could match " (allowing multi-pass backtrack);
		# [^"]+ is O(N) and semantically precise: URL values cannot contain ".
		# m{} delimiter used instead of // so that unescaped / may appear in
		# the pattern body and comments (e.g. </a>) without terminating the regex.
		next unless $line =~ m{
			^\s*<li><a\s+href="
			( [^"]+ )           # $1: relative URL - no unescaped " in href values
			">
			( [^,<>]+ )         # $2: last name - bounded by comma; no angle-brackets
			,\s+
			( [^<]+? )          # $3: first name - non-greedy; terminates before </a>
			\s+</a>\s+of\s+
			( .+? )             # $4: town - non-greedy; year anchor stops it correctly
			\s( \d{4} )         # $5: year - exactly 4 decimal digits; \s = separator
		}x;
		my ($page, $last, $first, $town, $year) = ($1, normalise_name($2), normalise_name($3), $4, $5);

		queue("freepages.rootsweb.com/~mrawson/genealogy/$page", $first, $last, "$town, Kent, England", $year);
	}
}

sub queue {
	my ($url, $first, $last, $town, $year) = @_;

	my $columns = {
		url   => $url,
		first => $first,
		town  => $town,
		year  => $year
	};

	# Both the Alias and / variants push an alternate-spelling entry then update $last.
	# The two-branch if/elsif had an identical body -- capture both matches into
	# ($alt, $primary), then execute the shared action once to eliminate the duplication.
	# Anchors (\A..\z) prevent substring match drift on multi-word names.
	# Non-greedy (.+?) splits on the FIRST Alias keyword (greedy would use the last).
	# \s+ tolerates multiple spaces around the keyword (older typesetting).
	# [^/]+ for the slash variant avoids backtracking (alias cannot itself contain /).
	my ($alt, $primary);
	if($last =~ / \A (.+?) \s+ Alias \s+ (.+) \z /x) {
		($alt, $primary) = ($1, $2);
	} elsif($last =~ m{ \A ( [^/]+ ) / (.+) \z }x) {
		($alt, $primary) = ($1, $2);
	}
	if(defined $alt) {
		push @queue, { %{$columns}, last => $alt };
		$last = $primary;
	}

	$columns->{'last'} = $last;

	# Handle "Ash next Sandwich" by adding both Ash and Sandwich as well.
	# .+ (not .*) requires at least one char per group — an empty place name is
	# meaningless. \s+ around "next" tolerates irregular whitespace in the source.
	if($town =~ m{
		^ ( .+ )        # $1: primary town (greedy; matches up to last "next" keyword)
		\s+ next \s+    # "next" with flexible surrounding whitespace
		( .+? )         # $2: secondary town (non-greedy; stops at comma)
		, \s+
		( .+ )          # $3: county/country suffix (county, country)
	}xi) {
		push @queue, $columns;
		push @queue, { %{$columns}, town => "$1, $3" };
		push @queue, { %{$columns}, town => "$1, $2, $3" };

		$columns = { %{$columns} };	# Clone as we push refs
		$columns->{'town'} = "$2, $3";
	}

	push @queue, $columns;
}

sub flush {
	my $dbh = shift;

	# Remove duplicates, preserving first occurrence
	my (%seen, @deduped);
	for my $item (@queue) {
		my $k = join('|', map { $item->{$_} // '' } qw(first middle last town year url));
		push @deduped, $item unless $seen{$k}++;
	}

	# prepare_cached reuses the compiled statement plan across flush() calls
	# rather than re-parsing the INSERT SQL each time.
	my $sth = $dbh->prepare_cached(
		'INSERT INTO wills(first, middle, last, town, year, url) VALUES (?, ?, ?, ?, ?, ?)'
	);

	for my $row (@deduped) {
		my ($first, $middle);
		# \S+ (non-whitespace) for the first token is more precise than .+? and
		# avoids any backtracking. \s+ handles double-spaced entries. \z is
		# strictly end-of-string; $ would match before a trailing newline.
		if($row->{'first'} =~ /^(\S+)\s+(.+)\z/) {
			($first, $middle) = ($1, $2);
		} else {
			$first = $row->{'first'};
		}
		try {
			$sth->execute($first, $middle, $row->{'last'}, $row->{'town'}, $row->{'year'}, $row->{'url'});
		} catch {
			Carp::croak("\nError in insert: $_");
		};
	}

	@queue = ();	# Release references so GC can reclaim processed rows
}

# Reduce the very large number of calls to Lingua::EN::NameCase
sub normalise_name {
	my $name = shift;
	state %cache;
	my $key = lc($name);
	return $cache{$key} if exists $cache{$key};
	return ($cache{$key} = nc($name));
}
