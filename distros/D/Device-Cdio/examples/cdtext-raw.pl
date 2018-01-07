#!/usr/bin/perl -w
#  Example demonstrating the parsing of raw CD-Text files
#
#  Copyright (C) 2017 Rocky Bernstein <rocky@gnu.org>
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

sub print_cdtext_info($)
{
    my $cdtext = shift;
    my $cdtext_fields = {};
    for (my $field=$perlcdio::MIN_CDTEXT_FIELD;
	 $field <= $perlcdio::MAX_CDTEXT_FIELDS; $field++) {
	$cdtext_fields->{$field} = perlcdio::cdtext_get_const($cdtext, $field, 0);
    }
    print_cdtext_track_info($cdtext_fields, 0);
}

sub read_cdtext($)
{
    my ($path) = @_;

    if (!open(FP, "<:raw", $path)) {
	print STDERR "cannot open $path for input: $!";
	exit(3);
    }

    my $size = read FP, my $cdt_data, 9220;
    close(FP);


    if ($size < 5) {
	print STDERR sprintf("file `%s' is too small to contain CD-TEXT\n", $path);
	exit(1);
    }

    # Truncate header when it is too large. The standard is ambiguous here
    $size -= 4 if ord(substr($cdt_data, 0, 1)) > 0x80;


    # ignore trailing 0
    $size -= 1 if (1 == $size % 18);

    # init cdtext */
    my $cdt = perlcdio::cdtext_init();
    my $rc = Device::Cdio::Device::cdtext_data_init($cdt, $cdt_data, $size);
    if ($rc !=0 ) {
	printf STDERR "failed to parse CD-Text file `%s'\n", $path;
	return undef;
    }

    return $cdt;
}


die "usage: $0 cdtext.data" if @ARGV != 1;
my $cdt_path=$ARGV[0];

my $cdt = read_cdtext($cdt_path);
print_cdtext_info($cdt) if $cdt;
