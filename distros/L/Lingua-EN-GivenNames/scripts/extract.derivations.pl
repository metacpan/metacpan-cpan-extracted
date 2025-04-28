#!/usr/bin/env perl

use feature qw/say unicode_strings/;
use open qw(:std :utf8);
use strict;
use warnings;
use warnings qw(FATAL utf8);

use Getopt::Long;

use Lingua::EN::GivenNames::Database::Import;

use Pod::Usage;

# -----------------------------------------------

my($option_parser) = Getopt::Long::Parser -> new();

my(%option);

if ($option_parser -> getoptions
(
	\%option,
	'help',
	'page_number=i',
	'sex=s',
	'verbose:i',
) )
{
	pod2usage(1) if ($option{'help'});

	exit Lingua::EN::GivenNames::Database::Import -> new(%option) -> extract_derivations;
}
else
{
	pod2usage(2);
}

__END__

=pod

=head1 NAME

extract.derivations.pl - Extract name derivations from web pages.

=head1 SYNOPSIS

extract.derivations.pl [options]

	Options:
	-help
	-page_number $integer
	-sex male | female
	-verbose $integer

All switches can be reduced to a single letter.

Exit value: 0.

Input: data/female_english_names.htm etc.

Output: data/derivations.raw. Output goes into parse.derivations.pl.

Specifically, pages of female names from 1 to 20 are processed,
and male names from 1 to 17 are too.

=head1 OPTIONS

=over 4

=item o -help

Print help and exit.

=item o -page_number => $integer

The page number of the file to process.

1 .. 20 for females and 1 .. 17 for males.

Default: 1.

=item o -sex male | female

Which sex to process.

Default: ''.

=item o -verbose => $integer

Print more or less progress reports.

Default: 0.

=back

=cut
