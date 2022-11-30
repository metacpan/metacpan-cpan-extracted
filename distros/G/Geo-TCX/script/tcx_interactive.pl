#!/usr/bin/env perl
use strict;
use warnings;

our $VERSION = '1.03';

=encoding utf-8

=head1 NAME

tcx_interactive.pl - Script to use the L<Geo::TCX> module interactively from the command line or in the perl debugger

=head1 SYNOPSIS

  tcx_interactive.pl --help
  tcx_interactive.pl --src_dir=dir [ --help --recent=# --wrk_dir=dir --wpt_dir=dir --dev_dir=dir --tolerance_meters=# ]

=head1 DESCRIPTION

C<tcx_interactive.pl> is a utility script that is mostly useful after having saved an activity from a GPS training device onto a computer.

The script looks up recently saved TCX or FIT files in the path specified by C<--src_dir> and prompts the user for one to parse. It reads the selected file, intiates a L<Geo::TCX::Interactive> instance, and prompts the user for commonly used methods such as C<save_laps()> among other.

The user is subsequently prompted whether they wish to read recently saved waypoints from their GPS device (provided it is currently plugged in via USB cable), save these points in a *.gpx waypoints file located in C<--wpt_dir>, and whether they wish to add the end points of each lap to that waypoints file.

The user can also transfer the resulting waypoints file back to their device for use during their next activity (not yet enabled, coming soon).

=cut

use Geo::Gpx;
use Geo::TCX::Interactive;
use Getopt::Long;

my ( $recent, $tolerance_meters, $src_dir, $wrk_dir, $wpt_dir, $dev_dir, $chdir, $help ) = (25, 10);
sub usage { "Usage: $0 --src_dir=dir [ --help --tolerance=# --recent=# --wrk_dir=dir --wpt_dir=dir --dev_dir=dir ]\n" }
GetOptions( "recent=i"   =>  \$recent,
            "src_dir=s"  =>  \$src_dir,
            "wrk_dir=s"  =>  \$wrk_dir,
            "wpt_dir=s"  =>  \$wpt_dir,
            "dev_dir=s"  =>  \$dev_dir,
            "chdir=s"    =>  \$chdir,
            "help"       =>  \$help,
            "tolerance_meters=i" =>  \$tolerance_meters,
)  or die usage();
die usage() if $help;

# check that any specified *_dir exist. $src_dir will be checked by new()
# $chdir is undocumented and provided for debugging purposes
$src_dir =~ s/^\s*~/$ENV{HOME}/ if defined $src_dir;
$wrk_dir =~ s/^\s*~/$ENV{HOME}/ if defined $wrk_dir;
$wpt_dir =~ s/^\s*~/$ENV{HOME}/ if defined $wpt_dir;
$dev_dir =~ s/^\s*~/$ENV{HOME}/ if defined $dev_dir;
die "--wrk_dir: directory specified does not exists" if defined $wrk_dir and ! -d $wrk_dir;
die "--wpt_dir: directory specified does not exists" if defined $wpt_dir and ! -d $wpt_dir;
die "--dev_dir: directory specified does not exists" if defined $dev_dir and ! -d $dev_dir;
if ($chdir) { chdir $chdir or die "can't chdir to $chdir: $!" }

=head2 Options

=over 4

=item C<< --recent => # >>

specifies the number of recent files to look up in C<--src_dir>. The default is 25.

=item C<< --src_dir=I<$dir> >>

the directory where TCX or FIT files are located.

=item C<< --wrk_dir=I<$dir> >>

the directory where working files are to be saved, such as with the C<save_laps()> method.

=item C<< --wpt_dir=I<$dir> >>

If this option is specified, the script will attempt to load a waypoints file from the user's computer into the L<Geo::TCX::Interactive> instance. This option is used by a call to C<< gpx_load() >> which prompts the user to select a I<*.gpx> file from all such files found in I<$dir>.

The script will later prompt the user whether they wish to add other waypoints saved on the GPS device and also whether to add the begining and end position of each of the activity's laps parsed by the instance to the I<*.gpx> file.

=item C<< --dev_dir=I<$dir> >>

the directory on the GPS device where the waypoints are stored. On recent devices, this tends to be a C<Locations> folder and older devices it is sometimes named C<GPX/current>.

If C<< way_add_device() >> is called and I<$dir> is not specified, the method will search where this directory might be (provided the GPS device is plugged in).

=item C<< --tolerance_meters => # >>

the distance below which waypoints at the beginning or end of a lap are to be ignored when comparing with the waypoints file read in the instance. The default is 10 meters.

This option is only relevant for C<< way_add_endpoints() >>. It is not considered by C<< way_add_device() >> under the assumption that if a user marked a particular location manually on their device, it has some degree of importance and should not be overlooked. 

=back

=cut

my $o= Geo::TCX::Interactive->new( $src_dir, recent => $recent, work_dir => $wrk_dir );
$o->prompt_and_set_wd;
# $o->lap_summary($_) for ( 1 .. $o->laps );
$o->save_laps();

if ($wpt_dir) {
    my $gpx = $o->gpx_load( $wpt_dir );
    $o->way_add_device( $dev_dir );
    $o->way_add_endpoints( tolerance_meters => $tolerance_meters );
    $o->gpx_save();
}

=head1 DEPENDENCIES

This script is part of the L<Geo::TCX> module and relies on the L<Geo::TCX::Interactive> sub-class it provides.

L<Geo::FIT> is also required to parse FIT files and to add waypoints from a GPS device (except for some older models).

=head1 SEE ALSO

L<Geo::TCX::Interactive>, L<Geo::Gpx>, L<Geo::FIT>.

=head1 AUTHOR

Patrick Joly C<< <patjol@cpan.org> >>.

=head1 VERSION

1.03

=head1 LICENSE AND COPYRIGHT

Copyright 2022, Patrick Joly C<< patjol@cpan.org >>. All rights reserved.

This script is free software; you can redistribute it and/or modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.

=cut

1;
