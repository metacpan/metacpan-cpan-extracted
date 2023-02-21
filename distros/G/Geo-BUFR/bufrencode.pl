#!/usr/bin/perl

# (C) Copyright 2010-2023 MET Norway
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
           'data=s',
           'help',
           'metadata=s',
           'outfile=s',
           'strict_checking=i',
           'tableformat=s',
           'tablepath=s',
           'verbose=i',
       ) or pod2usage(-verbose => 0);

# User asked for help
pod2usage(-verbose => 1) if $option{help};

# Data or metadata file not provided
pod2usage(-verbose => 0) if not $option{data} or not $option{metadata};

my $data_file     =  $option{data};
my $metadata_file =  $option{metadata};

# Default is croak if (recoverable) error found in encoded BUFR format
my $strict_checking = defined $option{strict_checking}
    ? $option{strict_checking} : 2;
Geo::BUFR->set_strict_checking($strict_checking);

# Set verbosity level
Geo::BUFR->set_verbose($option{verbose}) if $option{verbose};

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

my $bufr = Geo::BUFR->new();

# Read metadata into $bufr
read_metadata($metadata_file, $bufr);

# Load B and D tables (table version inferred from metadata)
$bufr->load_BDtables();

# Get the data
my ($data_refs, $desc_refs, $num_subsets) = readdata($data_file);

$bufr->set_number_of_subsets($num_subsets);

# Print the encoded BUFR message
my $buffer = $bufr->encode_message($data_refs, $desc_refs);
if ($option{outfile}) {
    my $outfile = $option{outfile};
    open my $fh, '>', $outfile or die "Can't open $outfile: $!";
    binmode($fh);
    print $fh $buffer;
} else {
    binmode(STDOUT);
    print $buffer;
}

# See OPTIONS section in pod for format of metadata file
sub read_metadata {
    my ($file, $bufr) = @_;

    # Read metadata from file into a hash
    my %metadata;
    open (my $fh, '<', $file) or die "Cannot open $file: $!";
    while ( <$fh> ) {
        chomp;
        next if /^\s*$/;
        s/^\s+//;
        my ($key, $value) = split /\s+/, $_, 2;
        $metadata{$key} = $value;
    }
    close $fh or die "Cannot close $file: $!";

    # Load the metadata into the BUFR object
    my $m = \%metadata;

    my $bufr_edition = $m->{BUFR_EDITION};

    $bufr->set_bufr_edition($bufr_edition);
    $bufr->set_master_table($m->{MASTER_TABLE});
    $bufr->set_centre($m->{CENTRE});
    $bufr->set_subcentre($m->{SUBCENTRE});
    $bufr->set_update_sequence_number($m->{UPDATE_SEQUENCE_NUMBER});
    $bufr->set_optional_section($m->{OPTIONAL_SECTION});
    $bufr->set_data_category($m->{DATA_CATEGORY});
    if ( $bufr_edition < 4 ) {
        $bufr->set_data_subcategory($m->{DATA_SUBCATEGORY});
    } else {
        $bufr->set_int_data_subcategory($m->{INT_DATA_SUBCATEGORY});
        $bufr->set_loc_data_subcategory($m->{LOC_DATA_SUBCATEGORY});
    }
    $bufr->set_master_table_version($m->{MASTER_TABLE_VERSION});
    $bufr->set_local_table_version($m->{LOCAL_TABLE_VERSION});
    if ( $bufr_edition < 4 ) {
        $bufr->set_year_of_century($m->{YEAR_OF_CENTURY});
    } else {
        $bufr->set_year($m->{YEAR});
    }
    $bufr->set_month($m->{MONTH});
    $bufr->set_day($m->{DAY});
    $bufr->set_hour($m->{HOUR});
    $bufr->set_minute($m->{MINUTE});
    $bufr->set_second($m->{SECOND}) if $bufr_edition >= 4;
    $bufr->set_observed_data($m->{OBSERVED_DATA});
    $bufr->set_compressed_data($m->{COMPRESSED_DATA});
    $bufr->set_descriptors_unexpanded($m->{DESCRIPTORS_UNEXPANDED});
    $bufr->set_local_use($m->{LOCAL_USE}) if exists $m->{LOCAL_USE};

    return;
}

# See OPTIONS section in pod for format of data file
sub readdata {
    my $file = shift;
    open (my $fh, '<', $file) or die "Cannot open $file: $!";

    my ($data_refs, $desc_refs);
    my $subset = 0;
    while ( <$fh> ) {
        s/^\s+//;
        # Lines not starting with a number are ignored
        next if not /^\d/;
        my ($n, $desc, $value) = split /\s+/, $_, 3;
        $subset++ if $n == 1;
        # Some operator descriptors are written on unnumbered lines
        # without a value
        if (!defined $desc || $desc !~ /^\d/) {
            next unless $n >= 200000 && $n < 300000; # Better to die here?
            $desc = $n;
            $value = undef;
        } else {
            $value =~ s/\s+$//;
            $value = undef if $value eq '' or $value eq 'missing';
        }
        push @{$data_refs->[$subset]}, $value;
        push @{$desc_refs->[$subset]}, $desc;
    }
    close $fh or die "Cannot close $file: $!";

    return ($data_refs, $desc_refs, $subset);
}

=pod

=encoding utf8

=head1 SYNOPSIS

  bufrencode.pl --data <data file> --metadata <metadata file>
      [--outfile <file to print encoded BUFR message to>]
      [--strict_checking n]
      [--tableformat <BUFRDC|ECCODES>]
      [--tablepath <path to BUFR tables>]
      [--verbose n]
      [--help]

=head1 DESCRIPTION

Encode a BUFR message, reading data and metadata from files. The
resulting BUFR message will be printed to STDOUT unless option
C<--outfile> is set.

Execute without arguments for Usage, with option --help for some
additional info. See also L<https://wiki.met.no/bufr.pm/start> for
examples of use.

=head1 OPTIONS

   --help               Display Usage and explain the options. Almost
                        the same as consulting perldoc bufrencode.pl
   --outfile <filename> Will print the encoded BUFR message to <filename>
                        instead of STDOUT
   --strict_checking n  n=0 Disable strict checking of BUFR format
                        n=1 Issue warning if (recoverable) error in
                            BUFR format
                        n=2 (default) Croak if (recoverable) error in BUFR format.
                            Nothing more in this message will be encoded.
   --tableformat        Currently supported are BUFRDC and ECCODES (default is BUFRDC)
   --tablepath <path to BUFR tables>
                        If used, will set path to BUFR tables. If not
                        set, will fetch tables from the environment
                        variable BUFR_TABLES, or if this is not set:
                        will use DEFAULT_TABLE_PATH_<tableformat>
                        hard coded in source code.
   --verbose n          Set verbose level to n, 0<=n<=6 (default 0).
                        Verbose output is sent to STDOUT, so ought to
                        be combined with option --outfile

=head2 Required options

=head4 --metadata <metadata file>

For the metadata file, use this as a prototype and change the values
as desired:

  BUFR_EDITION  4
  MASTER_TABLE  0
  CENTRE  88
  SUBCENTRE  0
  UPDATE_SEQUENCE_NUMBER  0
  OPTIONAL_SECTION  0
  DATA_CATEGORY  0
  INT_DATA_SUBCATEGORY  2
  LOC_DATA_SUBCATEGORY  255
  MASTER_TABLE_VERSION  14
  LOCAL_TABLE_VERSION  0
  YEAR  2008
  MONTH  9
  DAY  1
  HOUR  6
  MINUTE  0
  SECOND  0
  OBSERVED_DATA  1
  COMPRESSED_DATA  0
  DESCRIPTORS_UNEXPANDED  308004 012005 002002

For BUFR edition < 4, replace the lines INT_DATA_SUBCATEGORY,
LOC_DATA_SUBCATEGORY, YEAR and SECOND with new lines DATA_SUBCATEGORY
and YEAR_OF_CENTURY (the order of lines doesn't matter).

=head4 --data <data file>

For the data file, use the same format as would result if you did run
on the generated BUFR message

    bufrread.pl <bufr file> --data_only | cut -c -31

or if you use bufrread.pl with C<--width n>, replace 31 with n+16.
For example, the file might begin with

     1  001195          Newport
     2  005002            51.55
     3  006002            -2.99
     4  004001             2008
...

Every time a new line starting with the number 1 is met, a new subset
will be generated in the BUFR message. Lines not starting with a
number are ignored.

For missing values, use 'missing' or stop the line after the BUFR
descriptor.

Associated values should use BUFR descriptor 999999, and operator
descriptors 22[2345]000 and 23[2567]000 should not have a value,
neither should this line be numbered, e.g.

   160  011002          missing
        222000
   161  031002              160
   162  031031                0
...

To encode a NIL subset, all delayed replication factors should be
nonzero, and all other values set to missing except for the
descriptors defining the station.

Options may be abbreviated, e.g. C<--h> or C<-h> for C<--help>

=head1 AUTHOR

Pål Sannes E<lt>pal.sannes@met.noE<gt>

=head1 COPYRIGHT

Copyright (C) 2010-2023 MET Norway

=cut
