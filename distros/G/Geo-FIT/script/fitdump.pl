#!/usr/bin/env perl
use strict;
use warnings;
use Carp;

our $VERSION = '1.08';

=encoding utf-8

=head1 NAME

fitdump.pl - script to print the contents of Garmin FIT files to standard output or a file

=head1 SYNOPSIS

    fitdump.pl --version
    fitdump.pl --help
    fitdump.pl $fit_file [ --mps_to_kph=$boole --semicircles_to_deg=$boole --use_gmtime=$boole --maybe_chained=$boole --force ] [ $output_file ]

=head1 DESCRIPTION

C<fitdump.pl> reads the contents of the Garmin FIT files specified on command line and prints them on standard output or in I<$output_file> if provided.

=cut

use Geo::FIT;
use Getopt::Long;

my ($mps_to_kph, $semicircles_to_deg, $use_gmtime, $maybe_chained, $force, $version, $help) = (1, 1, 0, 0, 0, 0, 0);
sub usage { "Usage: $0 [ --help --version --mps_to_kph=\$boole --semicircles_to_deg=\$boole --use_gmtime=\$boole --maybe_chained=\$boole --force ] \$input_file [ \$output_file ]\n" }

GetOptions( "mps_to_kph=i"          =>  \$mps_to_kph,
            "semicircles_to_deg=i"  =>  \$semicircles_to_deg,
            "use_gmtime=i"          =>  \$use_gmtime,
            "maybe_chained=i"       =>  \$maybe_chained,
            "force"                 =>  \$force,
            "version"               =>  \$version,
            "help"                  =>  \$help,
            )  or die usage();

if ($version) {
    print $0, " version: ", $VERSION, "\n";
    exit
}
die usage() if $help;

my ($input_file, $output_file);
if (@ARGV) {
    $input_file = shift @ARGV;
    @ARGV and $output_file = shift @ARGV
}

# disable warnings until I resolve them all, will soon delete this
local $SIG{__WARN__} = sub { };

my $fh;
if ($output_file) {
    if (-f $output_file) {
        croak "$output_file already exists (specify --force to overwrite)" unless $force
    }
    open( STDOUT, '>', $output_file) or die "cannot open $output_file: $!"
}

sub dump_it {
    my ($self, $desc, $v, $o_cbmap) = @_;

    if ($desc->{message_name} ne '') {
        my $o_cb = $o_cbmap->{$desc->{message_name}};
        ref $o_cb eq 'ARRAY' and ref $o_cb->[0] eq 'CODE' and $o_cb->[0]->($self, $desc, $v, @$o_cb[1 .. $#$o_cb])
    }

    print "Local message type: $desc->{local_message_type} ($desc->{message_length} octets";
    print ", message name: $desc->{message_name}" if $desc->{message_name} ne '';
    print ", message number: $desc->{message_number})\n";
    $self->print_all_fields($desc, $v, indent => '  ')
}

sub fetch_from {
    my ($input_file, $output_fh) = (shift, shift);

    my $obj = new Geo::FIT;

    $obj->mps_to_kph($mps_to_kph);
    $obj->semicircles_to_degree($semicircles_to_deg);
    $obj->use_gmtime($use_gmtime);
    $obj->maybe_chained($maybe_chained);
    $obj->file($input_file);

    my $o_cbmap = $obj->data_message_callback_by_name('');

    for my $msgname (keys %$o_cbmap) {
        $obj->data_message_callback_by_name($msgname, \&dump_it, $o_cbmap);
    }

    $obj->data_message_callback_by_name('', \&dump_it, $o_cbmap);

    unless ($obj->open) {
        print STDERR $obj->error, "\n";
        return
    }

    my $chained;

    for (;;) {
        my ($fsize, $proto_ver, $prof_ver, $h_extra, $h_crc_expected, $h_crc_calculated) = $obj->fetch_header;

        unless (defined $fsize) {
            $obj->EOF and $chained and last;
            print STDERR $obj->error, "\n";
            $obj->close;
            return
        }

        my $protocol_version          = $obj->protocol_version(      $proto_ver );
        my ($prof_major, $prof_minor) = $obj->profile_version_major( $prof_ver );

        print "\n" if $chained;
        printf "File size: %lu, protocol version: %u, profile_version: %u.%02u\n", $fsize, $protocol_version, $prof_major, $prof_minor;

        if ($h_extra ne '') {
            print "Hex dump of extra octets in the file header";
            my ($i, $n);
            for ($i = 0, $n = length($h_extra) ; $i < $n ; ++$i) {
                print "\n  " if !($i % 16);
                print ' ' if !($i % 4);
                printf " %02x", ord(substr($h_extra, $i, 1))
            }
            print "\n"
        }

        if (defined $h_crc_calculated) {
            printf "File header CRC: expected=0x%04X, calculated=0x%04X\n", $h_crc_expected, $h_crc_calculated
        }

        1 while ($obj->fetch);

        print STDERR $obj->error, "\n" if !$obj->end_of_chunk && !$obj->EOF;
        printf "CRC: expected=0x%04X, calculated=0x%04X\n", $obj->crc_expected, $obj->crc;

        if ($maybe_chained) {
            $obj->reset;
            $chained = 1
        } else {
            my $garbage_size = $obj->trailing_garbages;
            print "Trailing $garbage_size octets garbages skipped\n" if $garbage_size > 0;
            last
        }
    }
    $obj->close
}

fetch_from( $input_file, $fh );

=head2 Options

=over 4

=item C<--mps_to_kph=($boolean)>

=item C<--semicircle_to_deg=($boolean)>

=item C<--use_gmtime=($boolean)>

Options corresponding to object methods in L<Geo::FIT>. The first two default to true, C<-use_gmtime> to false.

=item C<--$maybe_chained=($boolean)>

Boolean to indicate that the input may be a chained FIT file (defaults to false).

=back

=head1 DEPENDENCIES

L<Geo::FIT>

=head1 SEE ALSO

L<Geo::FIT>

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to C<bug-geo-gpx@rt.cpan.org>, or through the web interface at L<http://rt.cpan.org>.

=head1 AUTHOR

Originally written by Kiyokazu Suto C<< suto@ks-and-ks.ne.jp >>.

This version is maintained by Patrick Joly C<< <patjol@cpan.org> >>.

Please visit the project page at: L<https://github.com/patjoly/geo-fit>.

=head1 VERSION

1.08

=head1 LICENSE AND COPYRIGHT

Copyright 2022, Patrick Joly C<< patjol@cpan.org >>. All rights reserved.

Copyright 2016-2022, Kiyokazu Suto C<< suto@ks-and-ks.ne.jp >>. All rights reserved.

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.

=cut

1;

