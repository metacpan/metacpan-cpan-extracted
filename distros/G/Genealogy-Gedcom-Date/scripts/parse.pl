#!/usr/bin/env perl

use strict;
use utf8;
use warnings qw(FATAL utf8); # Fatalize encoding glitches.

use Getopt::Long;

use Genealogy::Gedcom::Date;

use Pod::Usage;

# -----------------------------------------------

my($option_parser) = Getopt::Long::Parser -> new();

my(%option);

if ($option_parser -> getoptions
(
	\%option,
	'canonical=i',
	'date=s',
	'help',
	'maxlevel=s',
	'minlevel=s',
) )
{
	pod2usage(1) if ($option{help});

	Genealogy::Gedcom::Date -> new(%option) -> parse;

	# Return 0 for success and 1 for failure.

	exit 0;
}
else
{
	pod2usage(2);
}

__END__

=pod

=encoding utf8

=head1 NAME

parse.pl - Run Genealogy::Gedcom::Date.

=head1 SYNOPSIS

parse.pl [options]

	Options:
	-canonical $integer
	-date aDate
	-help
	-maxlevel logOption1
	-minlevel logOption2

Exit value: 0 for success, 1 for failure. Die upon error.

=head1 OPTIONS

=over 4

=item o -canonical $integer

Note: You must use one of:

=over 4

=item o canonical => 0

Data::Dumper::Concise's Dumper() prints the output of the parse.

=item o canonical => 1

canonical_form() is called on the output of parse() to print a string.

=item o canonical => 2

canonocal_date() is called on each element in the result from parser), on separate lines.

=back

Default: 0.

Try these:

	perl scripts/parse.pl -max debug -d 'From 21 Jun 1950 to @#dGerman@ 05.Dez.2015'

	perl scripts/parse.pl -max debug -d 'From 21 Jun 1950 to @#dGerman@ 05.Dez.2015' -c 0

	perl scripts/parse.pl -max debug -d 'From 21 Jun 1950 to @#dGerman@ 05.Dez.2015' -c 1

	perl scripts/parse.pl -max debug -d 'From 21 Jun 1950 to @#dGerman@ 05.Dez.2015' -c 2

=item o -date aDate

A date in Gedcom format. Protect spaces from the shell by using single-quotes.

Note: You may have trouble with your shell inputting German dates containing 'Mär' on the command
line. Adding 'use open qw(:std :utf8);' to your script won't help. At least, it does not help me
on my Debian machine running bash.

This option is mandatory.

Default: ''.

=item o -help

Print help and exit.

=item o -maxlevel logOption1

This option affects Log::Handler.

See the Log::handler docs.

Typical values are: 'error', 'notice', 'info' and 'debug'.

The default produces no output.

Default: 'notice'.

=item o -minlevel logOption2

This option affects Log::Handler.

See the Log::handler docs.

Default: 'error'.

No lower levels are used.

=back

=cut
