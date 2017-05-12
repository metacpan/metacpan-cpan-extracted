#!/usr/bin/env perl

use strict;
use warnings;
use warnings qw(FATAL utf8); # Fatalize encoding glitches.
use open     qw(:std :utf8); # Undeclared streams in UTF-8.

use Getopt::Long;

use GraphViz2::Marpa::PathUtils::Demo;

use Pod::Usage;

# -----------------------------------------------

my($option_parser) = Getopt::Long::Parser -> new();

my(%option);

if ($option_parser -> getoptions
(
	\%option,
	'help',
) )
{
	pod2usage(1) if ($option{'help'});

	exit GraphViz2::Marpa::PathUtils::Demo -> new(%option) -> generate_demo;
}
else
{
	pod2usage(2);
}

__END__

=pod

=head1 NAME

generate.demo.pl - Generate GraphViz2::Marpa::PathUtils' html/index.html.

=head1 SYNOPSIS

generate.demo.pl [options]

	Options:
	-help

Exit value: 0 for success, 1 for failure. Die upon error.

=head1 OPTIONS

=over 4

=item o -help

Print help and exit.

=back

=cut
