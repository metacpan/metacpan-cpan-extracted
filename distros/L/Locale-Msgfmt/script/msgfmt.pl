#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
use Locale::Msgfmt 0.15;

our $VERSION = '0.15';

my ( $opt_o, $opt_f, $opt_q, $opt_force );

GetOptions(
	"output-file|o=s" => \$opt_o,
	"use-fuzzy|f"     => \$opt_f,
	"quiet|q"         => \$opt_q,
	"force"           => \$opt_force,
);

msgfmt( {
	in      => $_[0],
	out     => $opt_o,
	fuzzy   => $opt_f,
	verbose => !$opt_q,
	force   => $opt_force,
} );

=head1 NAME

msgfmt.pl - Compile .po files to .mo files

=head1 SYNOPSIS

This script does the same thing as msgfmt from GNU gettext-tools,
except this is pure Perl. Because it's pure Perl, it's more portable
and more easily installed (via CPAN). It has two other advantages.
First, it supports directories, so you can have it process a full
directory of .po files. Second, it can guess the output file (if you
don't specify the -o option). If the input is a file, it will
s/po$/mo/ to figure out the output file. If the input is a directory,
it will write the .mo files to the same directory.

=head1 SEE ALSO

L<Locale::Msgfmt>

=cut
