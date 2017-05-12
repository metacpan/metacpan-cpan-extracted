#!/usr/bin/env perl

use strict;
use warnings;
use warnings qw(FATAL utf8); # Fatalize encoding glitches.

use Getopt::Long;

use GraphViz2::Marpa::Demo;

use Pod::Usage;

# -----------------------------------------------

my($option_parser) = Getopt::Long::Parser -> new();

my(%option);

if ($option_parser -> getoptions
(
	\%option,
	'authortest=i',
	'help',
) )
{
	pod2usage(1) if ($option{'help'});

	exit GraphViz2::Marpa::Demo -> new(%option) -> generate_demo_index;
}
else
{
	pod2usage(2);
}

__END__

=pod

=head1 NAME

generate.demo.pl - Generate GraphViz2::Marpa's html/index.html.

=head1 SYNOPSIS

generate.demo.pl [options]

	Options:
	-authortest $Boolean
	-help

Exit value: 0 for success, 1 for failure. Die upon error.

=head1 OPTIONS

=over 4

=item o -authortest $Boolean

Specify whether (1) or not (0) to generate the author tests demo age.

See scripts/generate.demo.sh.

Default: 0.

=item o -help

Print help and exit.

=back

=cut
