#!/usr/bin/perl -w
# Program to show cdtext, similar to examples/cdtext.c
#
#  Copyright (C) 2012, 2017 Rocky Bernstein <rocky@gnu.org>
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.

# use Enbugger; Enbugger->load_debugger('trepan'); Enbugger->stop;

use strict;
use lib '../blib/lib';
use lib '../blib/arch';
use perlcdio;
use Device::Cdio;
use Device::Cdio::Device;

sub print_cdtext_track_info($$)
{
    my ($cdtext_ref, $t) = @_;

    if ($t != 0) {
	printf("Track #%2d\n", $t);
    } else {
	printf "CD-Text title for Disc\n";
    }

    foreach my $field (sort keys %{$cdtext_ref}) {
	printf "\t%s: %s\n", $Device::Cdio::CDTEXT_FIELD_by_id{$field},
	    $cdtext_ref->{$field} if defined($cdtext_ref->{$field});
    }
}

my $drive_name;
my $d;
if ($ARGV[0]) {
    $drive_name = $ARGV[0];
    $d = Device::Cdio::Device->new($drive_name);
    if (!$d) {
	print "Problem opening CD-ROM: $drive_name\n";
	exit 1;
    }
} else {
    $d = Device::Cdio::Device->new(undef, $perlcdio::DRIVER_UNKNOWN);
    if ($d) {
	$drive_name = $d->get_device();
    } else {
	print "Problem finding a CD-ROM\n";
	exit 1;
    }
}

my $i_tracks = $d->get_num_tracks();
my $first_track = $d->get_first_track;
my $last_track = $d->get_last_track();

$perlcdio::VERSION_NUM >= 10100 or die "Your version of libcdio is too old\n";

my $langs =  $d->cdtext_list_languages();
if ($langs) {
    foreach my $lang (@$langs) {
	if ($lang != $perlcdio::CDTEXT_LANGUAGE_UNKNOWN) {
	    printf "Language: %s\n", $Device::Cdio::CDTEXT_LANGUAGE_by_id{$lang};
	    my $text = $d->get_disc_cdtext();
	    print_cdtext_track_info($text, 0);

	    for (my $track=$first_track->{track}; $track <= $last_track->{track}; $track++) {
		my $text = $d->get_track_cdtext($track);
		print_cdtext_track_info($text, $track);
	    }
	}
    }
}
