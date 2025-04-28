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
	'verbose:i',
) )
{
	pod2usage(1) if ($option{'help'});

	exit Lingua::EN::GivenNames::Database::Import -> new(%option) -> parse_derivations;
}
else
{
	pod2usage(2);
}

__END__

=pod

=head1 NAME

parse.name.pages.pl - Extract name derivations from web pages.

=head1 SYNOPSIS

parse.name.pages.pl [options]

	Options:
	-help
	-verbose $integer

All switches can be reduced to a single letter.

Exit value: 0.

Input: data/derivations.txt. Input comes from extract.derivations.pl.

Output: data/matches.log, data/mismatches.log, data/parse.log.

Specifically, pages of female names from 1 to 20 are processed,
and male names from 1 to 17 are too.

=head1 OPTIONS

=over 4

=item o -help

Print help and exit.

=item o -verbose => $integer

Print more or less progress reports.

Default: 0.

=back

=cut
