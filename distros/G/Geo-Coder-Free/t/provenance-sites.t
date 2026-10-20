#!perl -w

# Every Geo::Location::Point this distribution builds for a caller carries the
# four provenance keys of section 2.1 of BI-Phase6-Dependency-Specs.md:
# geocoder, database, confidence and accuracy.
#
# t/consumer-contract.t checks that a backend file still sets the keys it
# promises, and it checks the file as a whole: one 'database' => anywhere in
# MaxMind.pm satisfies it.  The contract can therefore be lost without that test
# noticing.  Add a fifth backend, or a second return path inside a backend, and
# as long as some other line in the file still names the key, the file-level
# check passes while results from the new site carry no provenance at all.
#
# This test reads each construction site instead.  Every
# Geo::Location::Point->new() in lib/ and bin/ is found, its arguments are read,
# and the four keys have to be among them.  A site that has none of them is a
# failure naming the file, the line and the sub, so the keys are set at the site
# rather than remembered from the one that was checked by hand.
#
# Two kinds of site are exempt, and each is listed in %EXEMPT with its reason:
#
#   - a Point that is not a result: built to render a string with as_string(),
#     or to key the dataset's own index, and never handed to a caller;
#   - a Point built from a hash, where the four keys are assigned to that hash
#     earlier in the same sub.  That is not taken on trust: the test looks for
#     those four assignments itself, before the site.
#
# %EXEMPT is checked in both directions, so an entry that no longer names a site
# fails and the table cannot grow stale while sites it was written for change
# underneath it.
#
# Sites in t/ are not scanned.  A test builds a Point to hand to a backend, and
# a mock stands in for a result rather than being one.
#
#   prove -l t/provenance-sites.t

use strict;
use warnings;

use File::Find qw(find);
use File::Spec;
use FindBin qw($Bin);
use Test::Most;

# The provenance keys, as section 2.1 of BI-Phase6-Dependency-Specs.md names
# them.  Add a key here and every construction site in the distribution has to
# set it.
my @PROVENANCE = qw(geocoder database confidence accuracy);

# The files that can build a result.  Named so that a backend that disappears
# fails here, rather than leaving this test scanning nothing and passing.
my %BACKENDS = (
	'lib/Geo/Coder/Free/Local.pm'		=> 1,
	'lib/Geo/Coder/Free/OpenAddresses.pm'	=> 1,
	'lib/Geo/Coder/Free/MaxMind.pm'		=> 1,
);

# Construction sites that do not have to carry the keys, with the reason.  The
# key is the file, the sub the site is in, and the variable the call is handed.
my %EXEMPT = (
	'lib/Geo/Coder/Free/Local.pm' => {
		'new' => {
			'$row' => {
				reason => 'the key of the string index the constructor builds: the'
					. ' string recognises a row of the dataset and is never handed to a caller',
			},
		},
		'_result_for' => {
			'\%attributes' => {
				reason => 'the row is copied rather than blessed in place, so the four'
					. ' keys are assigned to %attributes and go in with it',
				hash   => '%attributes',
			},
		},
	},
	'lib/Geo/Coder/Free/MaxMind.pm' => {
		'reverse_geocode' => {
			'$_' => {
				reason => 'reverse_geocode answers with strings, not results: the Point'
					. ' exists only to be rendered by as_string()',
			},
			'$rc' => {
				reason => 'the same, for the single row the LIMIT 1 answer gives',
			},
		},
	},
);

# Under prove -t, $Bin is tainted; detaint before it reaches a file name.
my $root = do {
	(my $d = File::Spec->catdir($Bin, File::Spec->updir())) =~ /\A(.*)\z/s;
	$1;
};

# The check, on literal source
# ---------------------------------------------------------------------------
# The scan is only worth anything if it can tell a site with the keys from one
# without them, so it is run first on source whose answer is known.  Without
# this, a scan that found no construction sites at all would report no missing
# keys in any file and the test would pass whatever the backends said.

{
	my $source = <<'SOURCE';
package Example;

=head1 SYNOPSIS

    my $point = Geo::Location::Point->new({ geocoder => GEOCODER, database => 'Example' });

=cut

# Geo::Location::Point->new({ lat => 1, long => 2 });

sub complete {
	return Geo::Location::Point->new({
		location   => 'Somewhere',
		geocoder   => GEOCODER,
		database   => __PACKAGE__,
		confidence => 1.0,
		accuracy   => Geo::Location::Point::accuracy_for(qw(house_number road)),
	});
}

sub missing_one {
	my $row = shift;

	# A parenthesis inside a string, and a nested call, in the arguments.
	return Geo::Location::Point->new({
		'lat'        => $row->{'latitude'},
		'note'       => 'the usual case (nearest match)',
		'geocoder'   => GEOCODER,
		'database'   => __PACKAGE__,
		'confidence' => 1.0,
	});
}

sub from_a_hash {
	my $row = shift;
	my %attributes = %{$row};
	$attributes{'geocoder'}   = GEOCODER;
	$attributes{'database'}   = __PACKAGE__;
	$attributes{'confidence'} = 1.0;
	$attributes{'accuracy'}   = Geo::Location::Point::accuracy_for(keys %attributes);

	return Geo::Location::Point->new(\%attributes);
}

sub from_a_hash_missing_one {
	my $row = shift;
	my %attributes = %{$row};
	$attributes{'geocoder'}   = GEOCODER;
	$attributes{'database'}   = __PACKAGE__;
	$attributes{'confidence'} = 1.0;

	return Geo::Location::Point->new(\%attributes);
}
SOURCE

	my $sites = _sites(_masked($source));

	is(scalar(@{ $sites }), 4, 'the POD example and the commented-out call are not construction sites');

	my %by_sub = map { $_->{'sub'} => $_ } @{ $sites };

	is_deeply([_missing_keys($by_sub{'complete'})], [],
		'a site with all four keys has none missing');

	is_deeply([_missing_keys($by_sub{'missing_one'})], ['accuracy'],
		'a site without one key is missing exactly that key');

	is_deeply([_missing_keys($by_sub{'from_a_hash'})], [@PROVENANCE],
		'a site handed a hash literal has none of the keys in its own arguments');

	is($by_sub{'missing_one'}{'line'}, 25, 'the line of a site is the line the constructor is on')
		or diag("got line $by_sub{'missing_one'}{'line'}");

	is_deeply([_unassigned_in_hash($by_sub{'from_a_hash'}, '%attributes')], [],
		'a hash-built site counts as carrying the keys when the hash is assigned all four');

	is_deeply([_unassigned_in_hash($by_sub{'from_a_hash_missing_one'}, '%attributes')], ['accuracy'],
		'and is missing the key that was never assigned to the hash');
}

# Every construction site in the distribution
# ---------------------------------------------------------------------------

my %exemption_used;
my %scanned;
my $sites_checked = 0;

foreach my $file(_files()) {
	$scanned{$file} = 1;

	my $path = File::Spec->catfile($root, split(m{/}, $file));
	my $text = _slurp($path);

	ok(defined($text), "$file is readable");
	next unless defined($text);

	my $sites = _sites(_masked($text));
	my $result_sites = 0;

	foreach my $site(@{ $sites }) {
		$sites_checked++;

		my $where = "$file:$site->{'line'}";
		my $in = length($site->{'sub'}) ? " in sub $site->{'sub'}" : '';

		if(!defined($site->{'args'})) {
			fail("$where$in builds a Geo::Location::Point whose arguments cannot be read");
			diag('    The call has no closing parenthesis: one is nested past the end of the file.');
			next;
		}

		my @missing = _missing_keys($site);

		if(!@missing) {
			$result_sites++;
			pass("$where$in sets all four provenance keys");
			next;
		}

		my $exempt = $EXEMPT{$file}{$site->{'sub'}}{defined($site->{'token'}) ? $site->{'token'} : ''};

		if($exempt) {
			$exemption_used{join("\t", $file, $site->{'sub'}, $site->{'token'})} = 1;
			pass("$where$in is exempt: $exempt->{'reason'}");

			if(my $hash = $exempt->{'hash'}) {
				my @unassigned = _unassigned_in_hash($site, $hash);

				ok(!@unassigned, "$where$in is handed a $hash that has all four keys before it")
					or diag("    $hash is missing " . join(', ', @unassigned) . ' before this site.');
			}

			next;
		}

		fail("$where$in builds a Geo::Location::Point without " . join(', ', @missing));
		diag('    The result of this call reaches a caller without provenance.');
		diag('    Set the keys here, as every other result site does:');
		diag('        geocoder   => GEOCODER,');
		diag('        database   => __PACKAGE__,');
		diag('        confidence => $confidence,');
		diag('        accuracy   => Geo::Location::Point::accuracy_for(@matched_columns),   # the fields that matched');
		diag('    A site that is not a result - one built only to render a string, say - goes in');
		diag('    %EXEMPT at the top of this test with the reason it has none.');
	}

	cmp_ok($result_sites, '>', 0, "$file has a result site that sets all four provenance keys")
		if($BACKENDS{$file});
}

# The files the scan is supposed to cover
# ---------------------------------------------------------------------------
# A backend that has been renamed or moved is not scanned, and a scan that does
# not look at a file cannot find anything wrong with it.  So the files that must
# build results are named here as well as in the per-file check above.

foreach my $file(sort keys %BACKENDS) {
	ok($scanned{$file}, "$file is one of the files scanned for construction sites");
}

# An exemption that no longer names a site
# ---------------------------------------------------------------------------

foreach my $file(sort keys %EXEMPT) {
	foreach my $sub(sort keys %{ $EXEMPT{$file} }) {
		foreach my $token(sort keys %{ $EXEMPT{$file}{$sub} }) {
			ok($exemption_used{join("\t", $file, $sub, $token)},
				"the exemption for $file sub $sub, a Point built from $token, still names a site")
				or diag('    No construction site matches it any more: delete the entry.');
		}
	}
}

cmp_ok($sites_checked, '>', 0, 'construction sites were found to check');

done_testing();

# ---------------------------------------------------------------------------

# Every file that could build a result: the modules under lib/, and the scripts,
# which are in bin/ and in lib/Geo/Coder/Free/bin/.
sub _files
{
	my @files;

	find({
		no_chdir => 1,
		wanted   => sub {
			return unless -f $_;
			my $path = $File::Find::name;
			$path =~ s{\A\./}{};
			push @files, $path if(($path =~ /\.p[lm]\z/) || ($path =~ m{(?:\A|/)bin/}));
		},
	}, qw(lib bin));

	return sort @files;
}

sub _slurp
{
	my $file = shift;

	# The path came from the filesystem, which is tainted under prove -t;
	# matching it untaints the capture.
	my ($path) = $file =~ /\A(.*)\z/s;

	open(my $fh, '<', $path) or return;
	local $/;
	my $text = <$fh>;
	close($fh);

	return $text;
}

# The source with POD, whole-line comments and anything after __END__ blanked
# out, so a constructor named in prose is not read as code.  Each blanked line
# is replaced by spaces of the same length, which keeps every offset and so
# every line number in the result the same as in the original.
sub _masked
{
	my $text = shift;

	my @lines = split(/\n/, $text, -1);
	my $in_pod = 0;
	my $after_end = 0;

	for my $index(0 .. $#lines) {
		my $line = $lines[$index];

		# A POD directive starts at column 0, and =cut is the one that ends it.
		if($line =~ /^=(\w+)/) {
			$in_pod = ($1 ne 'cut');
		} elsif($line =~ /^__(?:END|DATA)__\s*\z/) {
			$after_end = 1;
		} elsif(!$after_end && !$in_pod && $line !~ /^\s*#/) {
			next;
		}

		$lines[$index] = ' ' x length($line);
	}

	return join("\n", @lines);
}

# Every Geo::Location::Point->new() in the source, with the sub it is in and the
# text of the arguments it is handed.
sub _sites
{
	my $text = shift;

	my @subs = _subs($text);
	my @sites;

	while($text =~ /Geo::Location::Point\s*(?:->|::)new\s*\(/g) {
		my $offset = $-[0];
		my $open = $+[0] - 1;

		my ($args) = _arguments($text, $open);
		my ($sub, $sub_start) = _enclosing_sub(\@subs, $offset);
		my $token = defined($args) ? _leading_token($args) : undef;

		push @sites, {
			offset => $offset,
			line   => _line_at($text, $offset),
			sub    => $sub,
			before => substr($text, $sub_start, $offset - $sub_start),
			args   => $args,
			token  => $token,
		};
	}

	return \@sites;
}

# The named subs of the source, in the order they appear.
sub _subs
{
	my $text = shift;

	my @subs;

	while($text =~ /^sub\s+([\w:]+)/mg) {
		push @subs, [$1, $-[0]];
	}

	return @subs;
}

# The sub a position is in: the last one declared before it.  A position before
# the first sub is in no sub at all, and is named as the empty string.
sub _enclosing_sub
{
	my ($subs, $offset) = @_;

	my ($name, $start) = ('', 0);

	foreach my $sub(@{ $subs }) {
		last if($sub->[1] > $offset);
		($name, $start) = @{ $sub };
	}

	return ($name, $start);
}

# The text between the parentheses of a call, and whether the closing one was
# found.  Strings are stepped over, so a parenthesis inside one does not end the
# call, and a comment is skipped, so the prose in it is not read as code.
sub _arguments
{
	my ($text, $open) = @_;

	my $length = length($text);
	my $depth = 0;
	my $quote;
	my $close;

	for(my $i = $open; $i < $length; $i++) {
		my $char = substr($text, $i, 1);

		if(defined($quote)) {
			if($char eq '\\') {
				$i++;	# the escaped character is not the closing quote
			} elsif($char eq $quote) {
				$quote = undef;
			}
			next;
		}

		if(($char eq "'") || ($char eq '"')) {
			$quote = $char;
			next;
		}

		if($char eq '#') {
			my $newline = index($text, "\n", $i);
			$i = ($newline < 0) ? $length : $newline;
			next;
		}

		if($char eq '(') {
			$depth++;
		} elsif($char eq ')') {
			$depth--;
			if(!$depth) {
				$close = $i;
				last;
			}
		}
	}

	return (undef, undef) unless defined($close);

	return (substr($text, $open + 1, $close - $open - 1), 1);
}

# A line as it reads in either file: a comment in a site's arguments is not a
# key, and must not be counted as one.
sub _without_comments
{
	my $text = shift;

	my $length = length($text);
	my $quote;
	my $out = '';

	for(my $i = 0; $i < $length; $i++) {
		my $char = substr($text, $i, 1);

		if(defined($quote)) {
			$out .= $char;
			if($char eq '\\') {
				$out .= substr($text, ++$i, 1);
			} elsif($char eq $quote) {
				$quote = undef;
			}
			next;
		}

		if(($char eq "'") || ($char eq '"')) {
			$quote = $char;
			$out .= $char;
			next;
		}

		if($char eq '#') {
			my $newline = index($text, "\n", $i);
			my $end = ($newline < 0) ? $length : $newline;
			$out .= ' ' x ($end - $i);
			$i = $end - 1;
			next;
		}

		$out .= $char;
	}

	return $out;
}

# Which of the four keys a site does not carry.
sub _missing_keys
{
	my $site = shift;

	return grep { !_sets_key($site->{'args'}, $_) } @PROVENANCE;
}

# True when the arguments set the key, in any of the spellings a site might use:
# key => value, 'key' => value.
sub _sets_key
{
	my ($args, $key) = @_;

	return 0 unless defined($args);

	my $text = _without_comments($args);

	return $text =~ /(?:^|[\s(,{])(?:['"])?\Q$key\E(?:['"])?\s*=>/m ? 1 : 0;
}

# Which of the four keys are not assigned to the hash a site is handed, before
# the site.  A hash-built site is only exempt because the keys are put into that
# hash, and this is where the test checks that they are.
sub _unassigned_in_hash
{
	my ($site, $hash) = @_;

	# The exemption names the hash, %attributes; an element of it is assigned
	# through the scalar $attributes{'key'}, so the sigil changes with the
	# spelling the code has to use.
	my $scalar = $hash;
	$scalar =~ s/\A[\$@%]//;

	my $before = $site->{'before'};

	return grep {
		$before !~ /\$\Q$scalar\E\s*(?:->)?\s*\{\s*(?:['"])?\Q$_\E(?:['"])?\s*\}\s*=(?!=|~)/m;
	} @PROVENANCE;
}

# The variable a call is handed, when it is handed one, so that an exemption can
# name the site.  A call handed a hash literal has no such variable: it builds
# its own arguments, and so has to carry the keys itself.
sub _leading_token
{
	my $args = shift;

	return $1 if($args =~ /\A\s*((?:\\?[\$@%])[\w:]+)/);

	return;
}

sub _line_at
{
	my ($text, $offset) = @_;

	my $prefix = substr($text, 0, $offset);

	return ($prefix =~ tr/\n//) + 1;
}
