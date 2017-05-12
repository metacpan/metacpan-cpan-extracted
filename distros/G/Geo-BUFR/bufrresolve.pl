#!/usr/bin/perl -w

# (C) Copyright 2010-2016 MET Norway
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
# 02110-1301, USA.

# pod included at end of file

use strict;
use Getopt::Long;
use Pod::Usage qw(pod2usage);
use Geo::BUFR;

# Will be used if neither --tablepath nor $ENV{BUFR_TABLES} is set
use constant DEFAULT_TABLE_PATH => '/usr/local/lib/bufrtables';
# Ought to be your most up-to-date B table
use constant DEFAULT_TABLE => 'B0000000000000023000';

# Parse command line options
my %option = ();

GetOptions(
           \%option,
           'tablepath=s',# Set BUFR table path
           'code=s',     # Print the contents of code table
           'flag=i',     # Resolve the flag value given
           'help',       # Print help information and exit
           'noexpand',   # Don't expand D descriptors
           'partial',    # Expand D descriptors only once, ignoring
                         # replication
           'simple',     # Like 'partial', but displaying the resulting
                         # descriptors on one line
           'bufrtable=s',# Set BUFR tables
           'verbose=i',  # Display path and tables used
       ) or pod2usage(-verbose => 0);


# User asked for help
pod2usage(-verbose => 1) if $option{help};

# No arguments if --code or --flag, else there should be at least one argument
if (defined $option{code} or defined $option{flag}) {
    pod2usage(-verbose => 0) if @ARGV;
} else {
    pod2usage(-verbose => 0) if not @ARGV;
}

# If --flag is set, user must also provide code table
pod2usage(-verbose => 0) if defined $option{flag} and !defined $option{code};

# All arguments must be integers
foreach (@ARGV) {
    pod2usage("All arguments must be integers!") unless /^\d+$/;
}
if (defined $option{code} && $option{code} !~ /^\d+$/) {
    pod2usage("Code table is not a (positive) integer!");
}
if (defined $option{flag} && $option{flag} !~ /^\d+$/) {
    pod2usage("Flag value is not a (positive) integer!");
}


# Set verbosity level for the BUFR module
my $verbose = $option{verbose} ? 1 : 0;
Geo::BUFR->set_verbose($verbose);

# From version 1.32 a descriptor sequence ending in e.g. 106000 031001
# will be allowed unless strict checking is set, and we really want
# bufrresolve.pl to complain in this case
Geo::BUFR->set_strict_checking(2);

# Set BUFR table path
if ($option{tablepath}) {
    # Command line option --tablepath overrides all
    Geo::BUFR->set_tablepath($option{tablepath});
} elsif ($ENV{BUFR_TABLES}) {
    # If no --tablepath option, use the BUFR_TABLES environment variable
    Geo::BUFR->set_tablepath($ENV{BUFR_TABLES});
} else {
    # If all else fails, use the libbufr bufrtables
    Geo::BUFR->set_tablepath(DEFAULT_TABLE_PATH);
}

# BUFR table file to use
my $table = $option{bufrtable} || DEFAULT_TABLE;

my $bufr = Geo::BUFR->new();

if (defined $option{code}) {
    # Resolve flag value or dump code table
    my $code_table = $option{code};
    if (defined $option{flag}) {
        if ($option{flag} == 0) {
            print "No bits are set\n";
        } else {
            print $bufr->resolve_flagvalue($option{flag}, $code_table, $table);
        }
    } else {
        print $bufr->dump_codetable($code_table, $table);
    }
} else {
    # Resolve descriptor(s)
    $bufr->load_BDtables($table);
    if ($option{simple}) {
        print $bufr->resolve_descriptor('simply', @ARGV);
    } elsif ($option{partial}) {
        print $bufr->resolve_descriptor('partially', @ARGV);
    } elsif ($option{noexpand}) {
        print $bufr->resolve_descriptor('noexpand', @ARGV);
    } else {
        print $bufr->resolve_descriptor('fully', @ARGV);
    }
}

=pod

=encoding utf8

=head1 SYNOPSIS

  1) bufrresolve.pl <descriptor(s)>
     [--partial]
     [--simple]
     [--noexpand]
     [--bufrtable <name of BUFR B table]
     [--tablepath <path to BUFR tables>]
     [--verbose n]
     [--help]

  2) bufrresolve.pl --code <code or flag table>
     [--bufrtable <name of BUFR B table>]
     [--tablepath <path to BUFR tables>]
     [--verbose n]

  3) bufrresolve.pl --flag <value> --code <flag table>
     [--bufrtable <name of BUFR B table]
     [--tablepath <path to BUFR tables>]
     [--verbose n]

=head1 DESCRIPTION

Utility program for fetching info from BUFR tables.

Execute without arguments for Usage, with option C<--help> for some
additional info. See also L<https://wiki.met.no/bufr.pm/start> for
examples of use.

It is supposed that the code and flag tables are contained in a file
with same name as corresponding B table except for having prefix C
instead of B. The tables used can be chosen by the user with options
C<--bufrtable> and C<--tablepath>. Default is the hard coded
DEFAULT_TABLE in directory DEFAULT_TABLE_PATH, but this last one will
be overriden if the environment variable BUFR_TABLES is set. You
should consider edit the source code if you are not satisfied with the
defaults chosen.

=head1 OPTIONS

   --partial    Expand D descriptors only once, ignoring replication
   --simple     Like --partial, but displaying the resulting
                descriptors on one line
   --noexpand   Don't expand D descriptors at all

   --bufrtable <name of BUFR B or D table>  Set BUFR tables
   --tablepath <path to BUFR tables>  Set BUFR table path
   --verbose n  Display path and tables used if n > 0

   --help       Display Usage and explain the options used. Almost
                the same as consulting perldoc bufrresolve.pl

Usage 1): Resolves the given descriptor(s) fully into table B
descriptors, with name, unit, scale, reference value and width (in
bits) written on each line (except for --simple). --partial, --simple
and --noexpand are mutually exclusive (full expansion is default).

Usage 2): Prints the contents of the requested code or flag table
(named by the table B descriptor).

Usage 3): Displays the bits set when the data value for the requested
flag table is <value>.

Options may be abbreviated, e.g. C<--h> or C<-h> for C<--help>

=head1 NOTE ON --VERBOSE

n > 1 in C<--verbose n> does not provide any more output than n=1, so
demanding an argument to C<--verbose> looks funny. But if not, sooner
or later someone would type C<bufrresolve.pl 307080 --verbose 1> which
by Perl would be interpreted as if the arguments were C<307080 000001
--verbose>, which probably is not what the user intended.

=head1 AUTHOR

Pål Sannes E<lt>pal.sannes@met.noE<gt>

=head1 COPYRIGHT

Copyright (C) 2010-2016 MET Norway

=cut
