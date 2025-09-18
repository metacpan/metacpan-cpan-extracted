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

# Parse command line options
my %option = ();
GetOptions(
           \%option,
           'ahl=s',        # Extract BUFR messages with AHL matching <ahl_regexp> only
           'gts',          # Include full gts message envelope if present
           'help',         # Print help information and exit
           'only_ahl',     # Extract AHLs only
           'outfile=s',    # Print to file instead of STDOUT
           'verbose=i',    # Set verbose level to n, 0<=n<=6 (default 0)
           'without_ahl',  # Print the BUFR messages only, skipping AHLs
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

my $ahl_regexp;
if ($option{ahl}) {
    eval { $ahl_regexp = qr/$option{ahl}/ };
    die "Argument to --ahl is not a valid Perl regular expression: $@" if $@;
}

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
    $bufr->set_filter_cb(\&filter_on_ahl,$ahl_regexp) if $option{ahl};

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

        next if $option{ahl} && $bufr->is_filtered();
        # Skip messages where stated length of BUFR message is sure to
        # be erroneous, unless we want ahls only (or should we skip
        # message in this case also? Hard choice...)
        next if !$option{only_ahl} && $bufr->bad_bufrlength();

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


=pod

=encoding utf8

=head1 SYNOPSIS

  bufrextract.pl <bufr file(s)>
      [--ahl <ahl_regexp>]
      [--only_ahl] | [--without_ahl] | [--gts]
      [--outfile <filename>]
      [--help]
      [--verbose n]

=head1 DESCRIPTION

Extract all BUFR messages and/or corresponding AHLs from BUFR file(s),
possibly filtering on AHL.

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
   --outfile <filename>
                      Will print to <filename> instead of STDOUT
   --help             Display Usage and explain the options used. For even
                      more info you might prefer to consult perldoc bufrextract.pl
   --verbose n        Set verbose level to n, 0<=n<=6 (default 0)

Options may be abbreviated, e.g. C<--h> or C<-h> for C<--help>.

For option C<--ahl> the <ahl_regexp> should be a Perl regular
expression. E.g. C<--ahl 'ISS... ENMI'> will decode only BUFR SHIP
(ISS) from CCCC=ENMI.

Use option C<--gts> if you want the full GTS message envelope (if
present) to be included in output. There are 2 main variations on this
envelope (SOH/ETX and ZCZC notation), for details see the Manual on
the GTS: Attachment II-4. Format of Meteorological Messages.

No bufrtables are needed for running bufrextract.pl, since section 4
in BUFR message will not be decoded (which also speeds up execution
quite a bit).

=head1 HINTS

With a little knowledge of Perl you could easily extend bufrextract.pl
to extract BUFR messages based on whatever information is available in
section 0-3, by making your own copy of bufrextract.pl and then
employing one of the many C<get_> subroutines in BUFR.pm. For example,
to extract only BUFR messages with data category 1, add the following
line just before calling C<is_filtered()> in code:

  next if $bufr->get_data_category() != 1;

Or to extract BUFR messages with TM315009 only:

  next if bufr->get_descriptors_unexpanded() ne '315009';

=head1 CAVEAT

Sometimes GTS bulletins are erroneously issued with extra characters
between the GTS AHL and the start of BUFR message (besides the
standard character sequence CRCRLF), likely leading bufrextract.pl to
miss the AHL.

=head1 AUTHOR

Pål Sannes E<lt>pal.sannes@met.noE<gt>

=head1 COPYRIGHT

Copyright (C) 2010-2025 MET Norway

=cut
