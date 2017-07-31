package Lingua::JA::Name::Splitter;
use warnings;
use strict;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw/split_kanji_name split_romaji_name/;
our %EXPORT_TAGS = ('all' => \@EXPORT_OK);
our $VERSION = '0.09';
use utf8;
use Carp;
use Lingua::JA::Moji ':all';

# The probabilities that these characters are part of the family name.

my %known;

my $file = __FILE__;
$file =~ s/Splitter\.pm/probabilities.txt/;
open my $in, "<:encoding(utf8)", $file or die $!;
while (<$in>) {
    my ($kanji, $prob) = split /\s/, $_;
    $known{$kanji} = $prob;
}
close $in or die $!;

# The weight to give the position in the kanji if it is a known
# kanji.

our $length_weight = 0.736; # 42030 successes

# The cutoff for splitting the name

our $split_cutoff = 0.5;

sub split_kanji_name
{
    my ($kanji) = @_;
    # Validate the user's input
    if (! $kanji) {
	carp "No valid name was provided to split_kanji_name";
	return undef;
    }
    if (length $kanji == 1) {
	carp "$kanji is only one character long, so there is nothing to split";
	return ($kanji, '');
    }
    if ($kanji !~ /^(\p{InCJKUnifiedIdeographs}|\p{InKana})+$/) {
	carp "$kanji does not look like a kanji/kana name";
    }
    if (! wantarray ()) {
        carp "The return value of split_kanji_name is an array";
    }
    # If the name is only two characters, there is only one possibility.
    if (length $kanji == 2) {
	return split '', $kanji;
    }

    # What we guess is the given name part of the name
    my $given;
    # What we guess is the family name part of the name
    my $family;
    # The characters in the name, which may not be kanji.
    my @kanji = split '', $kanji;
    # Probability this character is part of the family name.
    my @probability;
    # First character is definitely part of the family name.
    $probability[0] = 1;
    # Last character is definitely part of the given name.
    $probability[$#kanji] = 0;
    my $length = length $kanji;
    # Loop from the second kanji to the second-from-last kanji
    for my $i (1..$#kanji - 1) {
        my $p = 1 - $i / ($length - 1);
        my $moji = $kanji[$i];
        if (is_kana ($moji)) {
            # Assume that hiragana is not part of surname (not correct
            # in practice).
            $p = 0;
        }
        elsif ($known{$moji}) {
            $p = $length_weight * $p + (1 - $length_weight) * $known{$moji};
        }
        $probability[$i] = $p;
    }
#    print "@probability\n";
#    print "@kanji\n";
    my $in_given;
    for my $i (0..$#kanji) {
        if ($probability[$i] < $split_cutoff) {
            $in_given = 1;
        }
        if ($in_given) {
            $given .= $kanji[$i];
        }
        else {
            $family .= $kanji[$i];
        }
    }
    return ($family, $given);
}

sub split_romaji_name
{
    my ($name) = @_;
    if (! $name) {
	carp "No name given to split_romaji_name";
	return undef;
    }
    if (! wantarray ()) {
        carp "The return value of split_romaji_name is an array";
    }

    # What we guess is the family name
    my $last;
    # What we guess is the personal name
    my $first;
    if ($name !~ /\s|,/) {
        if ($name =~ /^([A-Z][a-z]+)([A-Z]+)$/) {
            $first = $1;
            $last = $2;
        }
        else {
            # If there is no space or comma, assume that this is the last name.
            $first = '';
            $last = $name;
        }
    }
    else {
        # Remove leading and trailing spaces.
        $name =~ s/^\s+|\s+$//g;
        my @parts = split /,?\s+/, $name;
	for (@parts) {
	    if (! is_romaji_strict ($_)) {
		carp "'$_' doesn't look like Japanese romaji";
	    }
	}
        # If there are more than two parts to the name after splitting by spaces
        if (@parts > 2) {
            carp "Strange Japanese name '$name' with middle name?";
        }
        # If the last name is capitalized, or if there is a comma in the
        # name.
        if ($parts[0] =~ /^[A-Z]+$/ || $name =~ /,/) {
            $last = $parts[0];
            $first = $parts[1];
        }
        else {
            $last = $parts[1];
            $first = $parts[0];
        }
    }
    # Regularise the name
    $first = ucfirst lc $first;
    $last = ucfirst lc $last;
    return ($first, $last);
}

1;
