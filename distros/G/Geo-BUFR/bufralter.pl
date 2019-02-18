#!/usr/bin/perl

# (C) Copyright 2010-2019 MET Norway
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
our %option = ();
GetOptions(
           \%option,
           'bufr_edition=i',
           'category=i',
           'centre=i',
           'compress=i',
           'data=s%',
           'day=i',
           'help',
           'hour=i',
           'int_subcategory=i',
           'loc_subcategory=i',
           'local_table_version=i',
           'master_table_version=i',
           'minute=i',
           'month=i',
           'observed=i',
           'outfile=s',
           'remove_qc',
           'remove_sec2',
           'second=i',
           'strict_checking=i',
           'subcategory=i',
           'subcentre=i',
           'tableformat=s',
           'tablepath=s',
           'update_number=i',
           'verbose=i',
           'year=i',
           'year_of_century=i',
       ) or pod2usage(-verbose => 0);

# User asked for help
pod2usage(-verbose => 1) if $option{help};

# Make sure there is an input file
pod2usage(-verbose => 0) unless @ARGV == 1;

my $infile = $ARGV[0];
open(my $IN, '<',$infile)
    or die "Cannot open $infile: $!";

# Default is to ignore 'recoverable' errors found in decoded or
# encoded BUFR format. This can be changed by setting strict_checking,
# which will then apply both to decoding and encoding.
my $strict_checking = defined $option{strict_checking}
    ? $option{strict_checking} : 0;
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

# Where to print the altered BUFR message(s)
my $OUT;
if ($option{outfile}) {
    open($OUT, '>', $option{outfile})
        or die "Cannot open $option{outfile} for writing: $!";
} else {
    $OUT = *STDOUT;
}
binmode($OUT);

# Change input separator to 'BUFR'
my $oldeol = $/;
$/ = 'BUFR';

# Read in everything before first 'BUFR'
my $out = <$IN>;

while (my $msg = <$IN>) {
    # Leave input unaltered if 'BUFR' is not start of a BUFR message
    if (length($msg) < 4) {
        $out .= $msg;
        next;
    }
    my $len = unpack 'N', "\0$msg";
    if ($len < 8 || $len > length($msg) + 4) {
        $out .= $msg;
        next;
    }
    if (substr($msg,$len-8,4) != '7777') {
        $out .= $msg;
        next;
    }

    # 'BUFR' is quite probably start of a valid BUFR message, so
    # transfer 'BUFR' from $out to $msg, transfer text following BUFR
    # message from $msg to $out, and try to alter $msg. Input
    # separator must be reverted before calling Geo::BUFR routines
    chomp $out;
    my $rest = substr($msg,$len-4);
    $msg = 'BUFR' . substr($msg,0,$len-4);

    $/ = $oldeol;
    my $bufr = Geo::BUFR->new($msg);

    $out .= alter($bufr);
    $out .= $rest;

    $bufr->fclose();
    $/ = 'BUFR';
}

print $OUT $out if $out;


# Extract data from BUFR file, possibly alter the data, and write the
# new messages to STDOUT.
sub alter {
    my $bufr = shift;           # BUFR object

    if ($option{remove_qc}) {
        Geo::BUFR->set_noqc();
    }

    my $new_bufr = Geo::BUFR->new();
    my @subset_data; # Will contain data values for subset 1,2...
    my @subset_desc; # Will contain the set of descriptors for subset 1,2...

 READLOOP:
    while (not $bufr->eof()) {

        # Read (and decode) next observation
        my ($data, $descriptors) = $bufr->next_observation();
        my $isub = $bufr->get_current_subset_number();
        my $nsubsets = $bufr->get_number_of_subsets();

        if ($isub == 1) {
            $new_bufr->copy_from($bufr,'metadata');
            @subset_data = ();
            @subset_desc = ();

            set_section1_data($bufr, $new_bufr);

            if (defined $option{observed}) {
                $new_bufr->set_observed_data($option{observed});
            }
            if (defined $option{compress}) {
                $new_bufr->set_compressed_data($option{compress});
            }
            if ($option{remove_sec2}) {
                $new_bufr->set_optional_section(0);
            }
            if ($option{remove_qc}) {
                remove_qc_from_unexpanded($new_bufr);
            }
        }

        if (defined $option{data}) {
          DESCRIPTOR: while (my ($desc, $value) = each %{$option{data}}) {
                for (my $i=0; $i < @$descriptors; $i++) {
                    if ($descriptors->[$i] == $desc) {
                        if ($value =~ /(.*)\+$/) {
                            $data->[$i] += $1;
                        } elsif ($value eq 'missing') {
                            $data->[$i] = undef;
                        } else {
                            $data->[$i] = $value;
                        }
                        next DESCRIPTOR;
                    }
                }
            }
        }
        $subset_data[$isub] = $data;
        $subset_desc[$isub] = $descriptors;

        if ($isub == $nsubsets) {
            return $new_bufr->encode_message(\@subset_data, \@subset_desc);
        }
    }
}

sub set_section1_data {
    my ($bufr, $new_bufr) = @_;

    if (defined $option{centre}) {
        $new_bufr->set_centre($option{centre});
    }
    if (defined $option{subcentre}) {
        $new_bufr->set_subcentre($option{subcentre});
    }
    if (defined $option{update_number}) {
        if ($option{update_number} >= 0) {
            $new_bufr->set_update_sequence_number($option{update_number});
        } else {
            my $old_number = $bufr->get_update_sequence_number();
            my $update_number = $option{update_number};
            if ($option{update_number} == -1) {
                $new_bufr->set_update_sequence_number($old_number + 1);
            } elsif ($option{update_number} == -2) {
                $new_bufr->set_update_sequence_number($old_number - 1);
            } else {
                pod2usage(-verbose => 1);
            }
        }
    }
    if (defined $option{category}) {
        $new_bufr->set_data_category($option{category});
    }
    if (defined $option{subcategory}) {
        $new_bufr->set_data_subcategory($option{subcategory});
    }
    if (defined $option{int_subcategory}) {
        $new_bufr->set_int_data_subcategory($option{int_subcategory});
    }
    if (defined $option{loc_subcategory}) {
        $new_bufr->set_loc_data_subcategory($option{loc_subcategory});
    }
    if (defined $option{master_table_version}) {
        $new_bufr->set_master_table_version($option{master_table_version});
    }
    if (defined $option{local_table_version}) {
        $new_bufr->set_local_table_version($option{local_table_version});
    }
    if (defined $option{year}) {
        $new_bufr->set_year($option{year});
    }
    if (defined $option{year_of_century}) {
        $new_bufr->set_year_of_century($option{year_of_century});
    }
    if (defined $option{month}) {
        $new_bufr->set_month($option{month});
    }
    if (defined $option{day}) {
        $new_bufr->set_day($option{day});
    }
    if (defined $option{hour}) {
        $new_bufr->set_hour($option{hour});
    }
    if (defined $option{minute}) {
        $new_bufr->set_minute($option{minute});
    }
    if (defined $option{second}) {
        $new_bufr->set_second($option{second});
    }
    # Should be processed last of the change metadata options,
    # because setting of BUFR edition may depend on other
    # metadata which user has opted to set
    if (defined $option{bufr_edition}) {
        set_bufr_edition($option{bufr_edition}, $bufr, $new_bufr);
    }
    return;
}

sub remove_qc_from_unexpanded {
    my $bufr = shift;
    my $desc = $bufr->get_descriptors_unexpanded();
    $desc =~ s/ 222000.*//;
    $bufr->set_descriptors_unexpanded($desc);
}

# If user hasn't provided the new metadata required for the new bufr
# edition, we make some educated guesses of these new metadata.
sub set_bufr_edition {
    my ($new_bufr_edition, $bufr, $new_bufr) = @_;

    my $old_bufr_edition = $bufr->get_bufr_edition();

    if ($old_bufr_edition == 4 and $new_bufr_edition < 4) {
        if (!defined $new_bufr->get_data_subcategory()) {
            $new_bufr->set_data_subcategory($bufr->get_loc_data_subcategory());
        }
        # get_year_of_century() fetches from YEAR if YEAR_OF_CENTURY isn't set
        $new_bufr->set_year_of_century($new_bufr->get_year_of_century());
    } elsif ($old_bufr_edition < 4 and $new_bufr_edition == 4) {
         if (!defined $new_bufr->get_loc_data_subcategory()) {
             $new_bufr->set_loc_data_subcategory($bufr->get_data_subcategory());
         }
         if (!defined $new_bufr->get_int_data_subcategory()) {
             $new_bufr->set_int_data_subcategory(255); # Undefined value
         }
         if (!defined $new_bufr->get_year()) {
             # Should work most of the time
             $new_bufr->set_year($bufr->get_year_of_century() + 2000);
         }
         if (!defined $new_bufr->get_second()) {
             $new_bufr->set_second(0);
         }
    }

    $new_bufr->set_bufr_edition($new_bufr_edition);
}

=pod

=encoding utf8

=head1 SYNOPSIS

  bufralter.pl <bufr file>
      [--data <descriptor=value[+]>]
      [--bufr_edition <value>]
      [--centre <value>]
      [--subcentre <value>]
      [--update_number <value>]
      [--category <value>]
      [--subcategory <value>]
      [--int_subcategory <value>]
      [--loc_subcategory <value>]
      [--master_table_version <value>]
      [--local_table_version <value>]
      [--year <value>]
      [--year_of_century <value>]
      [--month <value>]
      [--day <value>]
      [--hour <value>]
      [--minute <value>]
      [--second <value>]
      [--observed 0|1]
      [--compress 0|1]
      [--remove_sec2]
      [--remove_qc]
      [--outfile <file>]
      [--strict_checking n]
      [--tableformat <BUFRDC|ECCODES>]
      [--tablepath <path to BUFR tables>]
      [--verbose n]
      [--help]

=head1 DESCRIPTION

Will alter the BUFR messages in <bufr file> according to what is
specified by the options provided. The modified file (text surrounding
the BUFR messages will not be affected) will be printed to STDOUT
(unless C<--outfile> is set).

Execute without arguments for Usage, with option C<--help> for some
additional info.

=head1 OPTIONS

   --data <descriptor=value[+]> Set (first) data value in section 4 for
                    descriptor. A trailing '+' means that the value
                    should be added to existing value. Use 'missing'
                    to set a missing value. Repeat the option if more
                    sequence descriptors are to be set. Example:
                    --data 004004=-1+ --data 004005=50 --data
                    012101=missing This will set the data value for
                    first (and only first!) occurrence of these 3
                    descriptors in every subset and every message in
                    <bufr file> to the given value (subtracting 1 from
                    the existing value for 004004)
   --bufr_edition <value> Set BUFR edition to <value>. If the new edition
                    involves some metadata not present in the old edition,
                    some educated guesses for these new metadata are made,
                    but you should also consider setting these new metadata
                    explicitely
   --centre <value> Set originating centre to <value>
   --subcentre <value>
                    Set originating subcentre to <value>
   --update_number <value>
                    Set update sequence number to <value>. Use the special
                    value -1 to increment existing update sequence number,
                    -2 to decrement it
   --category <value> Set data category to <value>
   --subcategory <value> Set data sub-category to <value>
   --int_subcategory <value> Set international data sub-category to <value>
   --loc_subcategory <value> Set local data sub-category to <value>
   --master_table_version <value>
                    Set master table version number to <value>
   --local_table_version <value>
                    Set local table version number to <value>
   --<time_var> <value> Set <time_var> (= year | year_of_century | month |
                    day | hour | minute | second) in section 1 to <value>
   --observed 0|1   Set observed data in section 3 to 0 or 1
   --compress 0|1   Set compression in section 3 to 0 or 1
   --remove_sec2    Remove optional section 2 if present
   --remove_qc      Remove all quality control information,
                    i.e. remove all descriptors from 222000 on
   --outfile <filename>
                    Will print to <filename> instead of STDOUT
   --strict_checking n   n=0 (default) Disable strict checking of BUFR format
                         n=1 Issue warning if (recoverable) error in
                             BUFR format
                         n=2 Croak if (recoverable) error in BUFR format.
                             Nothing more in this message will be
                             decoded/encoded.
   --tableformat    Currently supported are BUFRDC and ECCODES (default is BUFRDC)
   --tablepath <path to BUFR tables>
                    Set path to BUFR tables (overrides $ENV{BUFR_TABLES})
   --verbose n      Set verbose level to n, 0<=n<=6 (default 0). Verbose
                    output is sent to STDOUT, so ought to be combined with
                    option --outfile
   --help           Display Usage and explain the options used. Almost
                    the same as consulting perldoc bufralter.pl

Options may be abbreviated, e.g. C<--he> or C<-he> for C<--help>.

To avoid having to use the C<--tablepath> option, you are adviced to
set the environment variable BUFR_TABLES to the directory where your
BUFR tables are located (unless the default path provided by
bufralter.pl works for you). For tableformat ECCODES, se
L<http://search.cpan.org/dist/Geo-BUFR/lib/Geo/BUFR.pm#BUFR-TABLE-FILES>
for more info on how to set C<--tablepath> (or BUFR_TABLES).

=head1 AUTHOR

Pål Sannes E<lt>pal.sannes@met.noE<gt>

=head1 COPYRIGHT

Copyright (C) 2010-2019 MET Norway

=cut
