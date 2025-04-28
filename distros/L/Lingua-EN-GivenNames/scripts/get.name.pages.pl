#!/usr/bin/env perl

use feature qw/say unicode_strings/;
use open qw(:std :utf8);
use strict;
use warnings;
use warnings qw(FATAL utf8);

use Getopt::Long;

use Lingua::EN::GivenNames::Database::Download;

use Pod::Usage;

# -----------------------------------------------

my($option_parser) = Getopt::Long::Parser -> new();

my(%option);

if ($option_parser -> getoptions
(
	\%option,
	'help',
	'sex=s',
	'verbose:i',
) )
{
	pod2usage(1) if ($option{'help'});

	exit Lingua::EN::GivenNames::Database::Download -> new(%option) -> get_name_pages;
}
else
{
	pod2usage(2);
}

__END__

=pod

=head1 NAME

get.name.pages.pl - Get http://www.20000-names.com male and female name pages

=head1 SYNOPSIS

get.name.pages.pl [options]

	Options:
	-help
	-sex male | female
	-verbose $integer

All switches can be reduced to a single letter.

Exit value: 0.

L<Input: http://www.20000-names.com/female_english_names.htm> etc.

Output: data/female_english_names.htm etc.

Specifically, pages of female names from 1 to 20 are downloaded,
and male names from 1 to 17 are too.

=head1 OPTIONS

=over 4

=item o -help

Print help and exit.

=item o -sex male | female

Which sex to process.

Default: ''.

=item o -verbose => $integer

Print more or less progress reports.

Default: 0.

=back

=cut
