#!/usr/bin/perl

# Copyright (C) 2010-2026 MET Norway
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

# Parse command line options
my %option = ();
GetOptions(
    \%option,
    'ahl=s',           # Extract BUFR messages with AHL matching <ahl_regexp> only
    'gts',             # Include full gts message envelope if present
    'filter=s',        # Extract BUFR messages meeting the <metadata criteria> only
    'help',            # Print help information and exit
    'only_ahl',        # Extract AHLs only
    'outfile=s',       # Print to file instead of STDOUT
    'verbose=i',       # Set verbose level to n, 0<=n<=6 (default 0)
    'without_ahl',     # Print the BUFR messages only, skipping AHLs
    ) or pod2usage(-verbose => 0);

# User asked for help
pod2usage(-verbose => 1) if $option{help};

# only_ahl and without_ahl are mutually exclusive
pod2usage( -message => "Options only_ahl, without_ahl and gts are mutually exclusive",
           -exitval => 2,
           -verbose => 0)
    if ( ($option{only_ahl} && ($option{without_ahl} || $option{gts}))
         || ($option{without_ahl} && ($option{only_ahl} || $option{gts}))
         || ($option{gts} && ($option{only_ahl} || $option{without_ahl})) );

# Make sure there is at least one input file
pod2usage(-verbose => 0) unless @ARGV;

# Set verbosity level
Geo::BUFR->set_verbose($option{verbose}) if $option{verbose};

# For filtering on ahl
my $ahl_regexp;
if ($option{ahl}) {
    eval { $ahl_regexp = qr/$option{ahl}/ };
    die "Argument to --ahl is not a valid Perl regular expression: $@" if $@;
}

# For filtering on metadata in section 0/1
my $filter = $option{filter} ? $option{filter} : '';
my $or_criteria_ref = get_filter_criteria($filter);

# Where to direct output (including verbose output, but not output to STDERR)
my $OUT;
if ($option{outfile}) {
    open($OUT, '>', $option{outfile})
        or die "Cannot open $option{outfile} for writing: $!";
} else {
    $OUT = *STDOUT;
}
binmode($OUT);

# No need to decode section 4 here
Geo::BUFR->set_nodata(1);

# Loop for processing of BUFR input files
foreach my $inputfname ( @ARGV ) {
    my $bufr = Geo::BUFR->new();

    # Could alternatively have merged filtering on ahl and metadata into
    # one single callback function, but that would be a rather complex
    # one, so we prefer to do the filtering on metadata later
    $bufr->set_filter_cb(\&filter_on_ahl, $ahl_regexp) if $option{ahl};

    # Open BUFR file
    $bufr->fopen($inputfname);

    # Process input file
    extract($bufr);
    $bufr->fclose();
}


# Extract BUFR messages and/or AHLs from BUFR file
sub extract {
    my $bufr = shift;          # BUFR object

    my ($current_message_number, $current_ahl);
  READLOOP:
    while (not $bufr->eof()) {

        # Read next observation. If an error is encountered during
        # decoding, skip this observation while printing the error
        # message to STDERR, also displaying ahl of bulletin if found
        # (but skip error message if the message should be skipped on
        # --ahl anyway).
        eval {
            $bufr->next_observation();
        };
        if ($@) {
            $current_ahl = $bufr->get_current_ahl() || '';
            next READLOOP if $option{ahl} && $current_ahl !~ $ahl_regexp;

            warn $@;
            # Try to extract message number and ahl of the bulletin
            # where the error occurred
            $current_message_number = $bufr->get_current_message_number();
            if (defined $current_message_number) {
                my $error_msg = "In message $current_message_number";
                $error_msg .= " contained in bulletin with ahl $current_ahl\n"
                    if $current_ahl;
                warn $error_msg if $error_msg;
            }
            next READLOOP;
        }

	# Filtering on ahl
        next READLOOP if $option{ahl} && $bufr->is_filtered();

	# Filtering on metadata
        next READLOOP if $or_criteria_ref && not or_filter($bufr, $or_criteria_ref);

        # Skip messages where stated length of BUFR message is sure to
        # be erroneous, unless we want ahls only (or should we skip
        # message in this case also? Hard choice...)
        next READLOOP if !$option{only_ahl} && $bufr->bad_bufrlength();

        my $current_subset_number = $bufr->get_current_subset_number();
        # If next_observation() did find a BUFR message, subset number
        # should have been set to at least 1 (even in a 0 subset message)
        last READLOOP if $current_subset_number == 0;

        $current_message_number = $bufr->get_current_message_number();
        $current_ahl = $bufr->get_current_ahl() || '';
        my $gts_eom = '';

        if ($current_ahl) {
            if ($option{only_ahl}) {
                print $OUT $current_ahl, "\n";
            } elsif (!$option{without_ahl}) {
                if ($option{gts}) {
                    my $current_gts_starting_line = $bufr->get_current_gts_starting_line() || '';
                    print $OUT $current_gts_starting_line;
                    $gts_eom = $bufr->get_current_gts_eom() || '';
                }
                # Use \r\r\n after AHL, since this is the standard
                # sequence used in GTS bulletins
                print $OUT $current_ahl . "\r\r\n";
            }
        }
        next READLOOP if $option{only_ahl};

        my $msg = $bufr->get_bufr_message();
        print $OUT $msg, $gts_eom;
  }
}

# Filter routines

sub filter_on_ahl {
    my $bufr = shift;
    my $ahl_regexp = shift;
    my $ahl = $bufr->get_current_ahl() || '';
    return $ahl =~ $ahl_regexp ? 0 : 1;
}

# Get the list of alternative metadata criteria (these are separated
# by '|', see pod)
sub get_filter_criteria {
    my $filter = shift;
    return ('') if ! $filter;

    my @or_criteria;
    my @criteria = split /[|]/, $filter;
    foreach my $cr (@criteria) {
        $cr =~ s/^\s+//;
        $cr =~ s/\s+$//;
        if ($cr ne '') {
            push @or_criteria, $cr;
        }
    }
    return \@or_criteria;
}

# Return true (1) if the BUFR message is matching all @and_criteria
# (to be extracted) for at least one of the @or_criteria
sub or_filter {
    my ($bufr, $or_criteria_ref) = @_;

    my $be = $bufr->get_bufr_edition() || return 0;
    my $dc = $bufr->get_data_category();
    # Choose to equate data_subcategory with int_data_subcategory, but
    # not quite sure about this
    my $ic = ($be == 4) ? $bufr->get_int_data_subcategory()
                        : $bufr->get_data_subcategory();
    my $lc = $bufr->get_loc_data_subcategory();
    my $oc = $bufr->get_centre();
    my $os = $bufr->get_subcentre();
    my $mt = $bufr->get_master_table_version();
    my $lt = $bufr->get_local_table_version();
    # This will not work for edition 3 when year is before 2000,
    # but hard to find a better way...
    my $ye = ($be == 4) ? $bufr->get_year()
                        : $bufr->get_year_of_century + 2000;
    my $mo = $bufr->get_month();
    my $da = $bufr->get_day();
    my $ho = $bufr->get_hour();
    my $mi = $bufr->get_minute();
    my $se = ($be == 4) ? $bufr->get_second() : 0;

    my $include = 0;
  OR:
    foreach my $or_criterium (@$or_criteria_ref) {
        my $all_ok = 1;
        my @and_criteria = split /\s+/, $or_criterium;
      AND:
        foreach my $and_criterium (@and_criteria) {
            my ($c, $list) = split /=/, $and_criterium;
            my @list = split /,/, $list;
            if ($c eq 'be') {
                if (not grep { $_ eq $be } @list) {
                    $all_ok = 0;
                    last AND;
                }
            } elsif ($c eq 'dc') {
                if (not grep { $_ eq $dc } @list) {
                    $all_ok = 0;
                    last AND;
                }
            } elsif ($c eq 'ic') {
                if (not grep { $_ eq $ic } @list) {
                    $all_ok = 0;
                    last AND;
                }
            } elsif ($c eq 'lc') {
                # Not in BUFR edition 3
                if (!(defined $lc) || not grep { $_ eq $lc } @list) {
                    $all_ok = 0;
                    last AND;
                }
            } elsif ($c eq 'oc') {
                if (not grep { $_ eq $oc } @list) {
                    $all_ok = 0;
                    last AND;
                }
            } elsif ($c eq 'os') {
                if (not grep { $_ eq $os } @list) {
                    $all_ok = 0;
                    last AND;
                }
            } elsif ($c eq 'mt') {
                if (not grep { $_ eq $mt } @list) {
                    $all_ok = 0;
                    last AND;
                }
            } elsif ($c eq 'lt') {
                if (not grep { $_ eq $lt } @list) {
                    $all_ok = 0;
                    last AND;
                }
            } elsif ($c eq 'ye') {
                if (not grep { $_ eq $ye } @list) {
                    $all_ok = 0;
                    last AND;
                }
            } elsif ($c eq 'mo') {
                if (not grep { $_ eq $mo } @list) {
                    $all_ok = 0;
                    last AND;
                }
            } elsif ($c eq 'da') {
                if (not grep { $_ eq $da } @list) {
                    $all_ok = 0;
                    last AND;
                }
            } elsif ($c eq 'ho') {
                if (not grep { $_ eq $ho } @list) {
                    $all_ok = 0;
                    last AND;
                }
            } elsif ($c eq 'mi') {
                if (not grep { $_ eq $mi } @list) {
                    $all_ok = 0;
                    last AND;
                }
            } elsif ($c eq 'se') {
                if (not grep { $_ eq $se } @list) {
                    $all_ok = 0;
                    last AND;
                }
            }  else {
                die "Metadata '$c' not recognized, check `perldoc bufrextract.pl`"
                    . " for the full list of 2-letter abbreviations accepted!";
            }
      } # end AND
        if ($all_ok == 1) {
            # BUFR message has met all conditions in this
            # or-criterium, so no need to check the others
            $include = 1;
            last OR;
      }

  } # end OR

    return $include;
}



=pod

=encoding utf8

=head1 SYNOPSIS

  bufrextract.pl <bufr file(s)>
      [--ahl <ahl_regexp>]
      [--only_ahl | --without_ahl | --gts]
      [--filter <metadata criteria>]
      [--outfile <filename>]
      [--help]
      [--verbose n]

=head1 DESCRIPTION

Extract all BUFR messages and/or corresponding AHLs from BUFR file(s),
possibly filtering on AHL and/or metadata in section 1.

The AHL (Abbreviated Header Line) is recognized as the TTAAii CCCC
YYGGgg [BBB] immediately preceding the BUFR message.

Execute without arguments for Usage, with option C<--help> for some
additional info. See also L<https://wiki.met.no/bufr.pm/start> for
examples of use.


=head1 OPTIONS

   --ahl <ahl_regexp> Extract BUFR messages and/or AHLs with AHL
                      matching <ahl_regexp> only
   --gts              Include full gts message envelope if present
   --only_ahl         Extract AHLs only
   --without_ahl      Extract BUFR messages only
   --filter <metadata criteria>
                      Extract BUFR messages matching the <metadata criteria> only
   --outfile <filename>
                      Will print to <filename> instead of STDOUT
   --help             Display Usage and explain the options used. For even
                      more info you might prefer to consult perldoc bufrextract.pl
   --verbose n        Set verbose level to n, 0<=n<=6 (default 0)

Options may be abbreviated, e.g. C<--h> or C<-h> for C<--help>.

For option C<--ahl> the <ahl_regexp> should be a Perl regular
expression. E.g. C<--ahl 'ISS... ENMI'> will decode only SHIP BUFR
(ISS) from CCCC=ENMI.

Use option C<--gts> if you want the full GTS message envelope (if
present) to be included in output. There are 2 main variations on this
envelope (SOH/ETX and ZCZC notation), for details see the Manual on
the GTS: Attachment II-4. Format of Meteorological Messages.

Using C<--filter> makes it possible to filter based on almost any of
the metadata present in section 1 (and 0) of the BUFR messages. Some few
examples which hopefully are enough to illustrate how to write the
<metadata criteria>: according to Common Code Table C-13 of
WMO-no. 306, "dc=0 ic=0,1,2,6" should take care of synoptic and
one-hour observations from fixed-land stations, while "dc=1 ic=0,6"
should do the same for marine stations. If you want to extract both,
use for <metadata criteria>: "dc=0 ic=0,1,2,6 | dc=1 ic=0,6".

Here is the full list of metadata available for filtering (the first
2-letter abbreviation is what should be used in the <metadata criteria>):

  be = BUFR edition
  oc = Originating centre
  os = Originating subcentre
  dc = Data category (table A)
  ic = International data subcategory
  lc = Local data subcategory
  mt = Master table version number
  lt = Local table version number
  ye = Year
  mo = Month
  da = Day
  ho = Hour
  mi = Minute
  se = Second

Note that no bufrtables are needed for running bufrextract.pl, since
section 4 in BUFR message will not be decoded (which also speeds up
execution quite a bit).

=head1 HINTS

With a little knowledge of Perl you could easily extend bufrextract.pl
to extract BUFR messages based on whatever information is available in
section 0-3, by making your own copy of bufrextract.pl and then
employing one of the many C<get_> subroutines in BUFR.pm. For example,
to extract only BUFR messages with TM315009, add the following
line just before calling C<is_filtered()> in code:

  next if $bufr->get_descriptors_unexpanded() ne '315009';

=head1 CAVEAT

Sometimes GTS bulletins are erroneously issued with extra characters
between the GTS AHL and the start of BUFR message (besides the
standard character sequence CRCRLF), likely leading bufrextract.pl to
miss the AHL.

=head1 AUTHOR

Pål Sannes E<lt>pal.sannes@met.noE<gt>

=head1 COPYRIGHT

Copyright (C) 2010-2026 MET Norway

=cut
