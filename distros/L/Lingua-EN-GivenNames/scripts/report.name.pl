#!/usr/bin/env perl

use feature qw/say unicode_strings/;
use open qw(:std :utf8);
use strict;
use warnings;
use warnings qw(FATAL utf8);

use Getopt::Long;

use Lingua::EN::GivenNames::Database;

use Pod::Usage;

# -----------------------------------------------

my($option_parser) = Getopt::Long::Parser -> new();

my(%option);

if ($option_parser -> getoptions
(
	\%option,
	'help',
	'name=s',
	'verbose:i',
) )
{
	pod2usage(1) if ($option{'help'});

	exit Lingua::EN::GivenNames::Database -> new(%option) -> report_name;
}
else
{
	pod2usage(2);
}

__END__

=pod

=head1 NAME

report.name.pl - Report all the information about one name

=head1 SYNOPSIS

report.name.pl [options]

	Options:
	-help
	-name $name
	-verbose $integer

All switches can be reduced to a single letter.

Exit value: 0.

=head1 OPTIONS

=over 4

=item o -help

Print help and exit.

=item o -name $name

Specify the name to be reported on. This option is mandatory.

Default: ''.

=item o -verbose => $integer

Print more or less progress reports.

Default: 0.

=back

=cut
