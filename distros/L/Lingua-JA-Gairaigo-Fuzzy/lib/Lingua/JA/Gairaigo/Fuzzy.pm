package Lingua::JA::Gairaigo::Fuzzy;
use warnings;
use strict;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw/same_gairaigo/;
our %EXPORT_TAGS = (
    all => \@EXPORT_OK,
);
our $VERSION = '0.08';
use utf8;

use Text::Fuzzy 'fuzzy_index';
use Lingua::JA::Moji 'kana2romaji';

sub same_gairaigo
{
    my ($kana, $n, $debug) = @_;
    if ($kana eq $n) {
	return 1;
    }
    if (chouon ($kana, $n)) {
	my $gotcha = usual_suspect ($kana, $n, $debug);
	if ($gotcha) {
	    return 1;
	}
    }
    return undef;
}

# Check a few likely things

sub usual_suspect
{
    my ($kana, $n, $debug) = @_;

    # The following is an undocumented routine in Text::Fuzzy.

    my ($dist, $edits) = fuzzy_index ($kana, $n, 1);

    # Is this a likely candidate?

    my $gotcha;

    if ($edits =~ /ii|dd|rr/) {

	# A double delete, double insertion, or double replace means
	# this is unlikely to be the same word.

	if ($debug) {
	    print "$kana has double delete, insert, or replace; rejecting.\n";
	}

	return undef;
    }
    my @kana = split //, $kana;
    my @nkana = split //, $n;
    my @edits = split //, $edits;

    if ($debug) {
	printf ("Lengths of a and b: %d %d\n", scalar (@kana), scalar (@nkana));
    }

    # $i is the offset in @kana, and $j is the offset in @nkana. Note
    # that @kana and @nkana may have different lengths and the offsets
    # are adjusted as we look though what edit is necessary to change
    # "$kana" to "$n".

    my $i = 0;
    my $j = 0;

    for my $edit (@edits) {

	if ($debug) {
	    print "Offsets i = $i, j = $j, edit = $edit\n";
	}
	if ($edit eq 'r') {

	    # Replaced $k with $q.

	    my $k = $kana[$i];
	    my $q = $nkana[$j];
	    if ($debug) {
		print "Replace $k with $q\n";
	    }
	    if ($k =~ /[ーィイ]/ && $q =~ /[ーィイ]/) {

		# Check whether the previous kana ends in "e", so it
		# is something like "ヘイ" and "ヘー".

		if (ends_in_e (\@kana, $i)) {
		    $gotcha = 1;
		}
		if (($k eq 'ー' && $q eq 'イ') ||
		    ($q eq 'ー' && $k eq 'イ')) {
		    if (ends_in_i (\@kana, $i)) {
			$gotcha = 1;
		    }
		}
	    }
	    if ($k =~ /[ーッ]/ && $q =~ /[ーッ]/) {

		# A chouon has been replaced with a sokuon, or
		# vice-versa.

		$gotcha = 1;
	    }
	    if (($k eq 'ー' && $q eq 'ウ') ||
		($q eq 'ー' && $k eq 'ウ')) {
		if (ends_in_ou (\@kana, $i)) {
		    $gotcha = 1;
		}
	    }

	    # Whatever we had, increment $i and $j equally because a
	    # character was replaced.

	    $i++;
	    $j++;
	}
	elsif ($edit eq 'd') {

	    # Character $k was deleted from $kana to get $n, so we
	    # just increment $i.

	    my $k = $kana[$i];
	    if ($k eq 'ー' || $k eq '・' || $k eq 'ッ') {

		# A chouon, nakaguro, or sokuon was deleted from $kana
		# to get $n.

		$gotcha = 1;
	    }
	    # Check we are not at the end of the string.
	    if ($j < scalar (@kana)) {
		my $q = $kana[$j];
		if ($q =~ /[ーィイ]/) {
		    if (ends_in_e (\@kana, $i)) {
			$gotcha = 1;
		    }
		}
	    }
	    $i++;
	}
	elsif ($edit eq 'i') {

	    # Character $k was inserted into $n, so we just increment
	    # $j, not $i.

	    my $k = $nkana[$j];
	    if ($k eq 'ー' || $k eq '・' || $k eq 'ッ') {

		# A chouon, nakaguro, or sokuon was inserted into
		# $kana to get $n.

		$gotcha = 1;
	    }
	    $j++;
	}
	elsif ($edit eq 'k') {

	    # The two strings are the same at this point, so do not do
	    # any checking but just increment the offsets.

	    $i++;
	    $j++;
	}
    }

    # Check we did not make a mistake scanning the two strings.

    if ($i != scalar @kana) {
	warn "Bug: Mismatch $i";
    }
    if ($j != scalar @nkana) {
	warn "Bug: Mismatch $j";
    }
    return $gotcha;
}

# Work out whether the kana before the one at $i ends in "e".

sub ends_in_e
{
    my ($kana_ref, $i) = @_;
    my $prev;
    if ($i >= 1) {
	$prev = $kana_ref->[$i - 1];
	$prev = kana2romaji ($prev);
	if ($prev =~ /e$/) {
	    return 1;
	}
    }
    return undef;
}

# Work out whether the kana before the one at $i ends in "ou".

sub ends_in_ou
{
    my ($kana_ref, $i) = @_;
    my $prev;
    if ($i >= 1) {
	$prev = $kana_ref->[$i - 1];
	$prev = kana2romaji ($prev);
	if ($prev =~ /[ou]$/) {
	    return 1;
	}
    }
    return undef;
}
# Work out whether the kana before the one at $i ends in "e".

sub ends_in_i
{
    my ($kana_ref, $i) = @_;
    my $prev;
    if ($i >= 1) {
	$prev = $kana_ref->[$i - 1];
	$prev = kana2romaji ($prev);
	if ($prev =~ /i$/) {
	    return 1;
	}
    }
    return undef;
}
# Work out whether $x and $y differ in the ways we expect.

# The name "chouon" is a misnomer.

sub chouon
{
    my ($x, $y) = @_;
    my %xa = alph ($x);
    my %ya = alph ($y);
    my $found;
    my $mismatch = check (\%xa, \%ya, \$found);
    if ($mismatch) {
	return undef;
    }
    $mismatch = check (\%ya, \%xa, \$found);
    if ($mismatch) {
	return undef;
    }
    if ($found) {
	return 1;
    }
    return undef;
}

# Given a word $x, make an alphabet of its consituent letters.

sub alph
{
    my ($x) = @_;
    my %xa;
    my @xl = split //, $x;
    @xa{@xl} = @xl;
    return %xa;
}

# Go through the keys of $ya, and check whether the keys which are not
# in $xa are the right kind of keys.

sub check
{
    my ($xa, $ya, $found) = @_;
    my $ok;
    for my $k (keys %$ya) {
	next if $xa->{$k};
	if ($k eq 'ー' ||
	    $k eq 'イ' ||
	    $k eq 'ィ' ||
	    $k eq '・' ||
	    $k eq 'ッ' || 
	    $k eq 'ウ') {
	    $ok = 1;
	    next;
	}
	return $k;
    }
    if ($ok) {
	$$found = $ok;
    }
    return;
}

1;
