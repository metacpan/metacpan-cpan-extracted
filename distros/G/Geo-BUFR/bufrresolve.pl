#!/usr/bin/perl

# (C) Copyright 2010-2025 MET Norway
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
use warnings;
use Getopt::Long;
use Pod::Usage qw(pod2usage);
use Geo::BUFR;

# This is actually default in BUFR.pm, but provided here to make it
# easier for users to change to 'ECCODES' if preferred
use constant DEFAULT_TABLE_FORMAT => 'BUFRDC';

# Will be used if neither --tablepath nor $ENV{BUFR_TABLES} is set
use constant DEFAULT_TABLE_PATH_BUFRDC => '/usr/local/lib/bufrtables';
use constant DEFAULT_TABLE_PATH_ECCODES => '/usr/local/share/eccodes/definitions/bufr/tables';

# Parse command line options
my %option = ();

GetOptions(
           \%option,
           'bufrtable=s',# Set BUFR tables
           'code=s',     # Print the contents of code table
           'flag=i',     # Resolve the flag value given
           'help',       # Print help information and exit
           'noexpand',   # Don't expand D descriptors
           'partial',    # Expand D descriptors only once, ignoring
                         # replication
           'simple',     # Like 'partial', but displaying the resulting
                         # descriptors on one line
           'tableformat=s',  # Set BUFR table format
           'tablepath=s',# Set BUFR table path
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

# Set BUFR table format
my $tableformat = (defined $option{tableformat}) ? uc $option{tableformat} : DEFAULT_TABLE_FORMAT;
Geo::BUFR->set_tableformat($tableformat);

# Set BUFR table path
if ($option{tablepath}) {
    # Command line option --tablepath overrides all
    Geo::BUFR->set_tablepath($option{tablepath});
} elsif ($ENV{BUFR_TABLES}) {
    # If no --tablepath option, use the BUFR_TABLES environment variable
    Geo::BUFR->set_tablepath($ENV{BUFR_TABLES});
} else {
    # If all else fails, use the default tablepath in BUFRDC/ECCODES
    if ($tableformat eq 'BUFRDC') {
        Geo::BUFR->set_tablepath(DEFAULT_TABLE_PATH_BUFRDC);
    } elsif ($tableformat eq 'ECCODES')  {
        Geo::BUFR->set_tablepath(DEFAULT_TABLE_PATH_ECCODES);
    }
}

# BUFR table file to use
my $table = $option{bufrtable} || Geo::BUFR->get_max_table_version();

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
     [--bufrtable <name of BUFR table]
     [--tableformat <BUFRDC|ECCODES>]
     [--tablepath <path to BUFR tables>]
     [--verbose n]
     [--help]

  2) bufrresolve.pl --code <code or flag table>
     [--bufrtable <name of BUFR table>]
     [--tableformat <BUFRDC|ECCODES>]
     [--tablepath <path to BUFR tables>]
     [--verbose n]

  3) bufrresolve.pl --flag <value> --code <flag table>
     [--bufrtable <name of BUFR table]
     [--tableformat <BUFRDC|ECCODES>]
     [--tablepath <path to BUFR tables>]
     [--verbose n]

=head1 DESCRIPTION

Utility program for fetching info from BUFR tables.

Execute without arguments for Usage, with option C<--help> for some
additional info. See also L<https://wiki.met.no/bufr.pm/start> for
examples of use.

The tables used can be selected by the user with options
C<--bufrtable>, C<--tablepath> and C<--tableformat>. Default
tableformat in Geo::BUFR is BUFRDC, while default tablepath in
bufrresolve.pl will be overridden if the environment variable
BUFR_TABLES is set. You should consider edit the source code of
bufrresolve.pl if you are not satisfied with the defaults chosen for
tablepath and bufrtable (search for 'DEFAULT').

For tableformat ECCODES, see
L<http://search.cpan.org/dist/Geo-BUFR/lib/Geo/BUFR.pm#BUFR-TABLE-FILES>
for more info on how to set C<--tablepath>.

For the table name in C<--bufrtable> in BUFRDC, use basename of B
table, e.g.  B0000000000098013001.TXT. Replacing B with D or C, or
omitting this prefix altogether, or even omitting the trailing '.TXT'
(i.e. 0000000000098013001) will also work.

For the table name in C<--bufrtable> in ECCODES, use last significant part
of table location, e.g. '0/wmo/29' for WMO master tables or
'0/local/8/78/236' for local tables on Unix-like systems. For looking
up local sequence descriptors, you might need to provide both a master
and the local table to get the full expansion, e.g.
'0/wmo/29,0/local/8/78/236'.

See also L</"CAVEAT"> below for more about the C<--bufrtable> option.

=head1 OPTIONS

   --partial    Expand D descriptors only once, ignoring replication
   --simple     Like --partial, but displaying the resulting
                descriptors on one line
   --noexpand   Don't expand D descriptors at all
   --bufrtable <name of BUFR B or D table>  Set BUFR tables
   --tableformat Currently supported are BUFRDC and ECCODES (default is BUFRDC)
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

=head1 CAVEAT

The C<--bufrtable> option could be considered mandatory, since there
is no guarantee that the same BUFR descriptor resolves the same way
for different BUFR tables. However, as soon as a new BUFR descriptor
is introduced in a BUFR table, it is extremely rare that the
descriptor is redefined in later versions. So for convenience,
bufrresolve.pl uses a default table (adding option C<--verbose 1> will
show you the tables used). If this is the wrong table for your purpose
(most common case will be if the descriptor was added in a higher
version than that of the default table), you should definitely use
C<--bufrtable> with the appropriate table.

=head1 AUTHOR

Pål Sannes E<lt>pal.sannes@met.noE<gt>

=head1 COPYRIGHT

Copyright (C) 2010-2025 MET Norway

=cut
