#!/usr/bin/env perl
use strict;
use warnings;

our $VERSION = '1.04';

=encoding utf-8

=head1 NAME

locations2gpx.pl - script to convert a FIT locations file to gpx format

=head1 SYNOPSIS

  locations2gpx.pl --help
  locations2gpx.pl [ --outfile=$filename --force --indent=# --time_offset=# ] $fit_locations_file

=head1 DESCRIPTION

C<locations2gpx.pl> reads the contents of a FIT file containing the locations saved on a GPS device and converts it to a GPX file as waypoints.

The converted file will have the same basename as the I<$fit_locations_file> but with a I<*.gpx> extension. The name of the converted file may be overriden with with option C<--outfile>.

=cut

use Geo::FIT;
use Getopt::Long;
use HTML::Entities qw( encode_entities encode_entities_numeric );

my ($force, $time_offset, $indent_n, $indent, $outfile, $help) = (0, 0, 2);
sub usage { "Usage: $0 [ --help --outfile=<fname> --force --indent=# --time_offset=# ] fit_locations_file\n" }
GetOptions( "outfile=s"      =>  \$outfile,
            "indent=i"       =>  \$indent_n,
            "force"          =>  \$force,
            "time_offset=i"  =>  \$time_offset,
            "help"           =>  \$help,
)  or die usage();
die usage() if $help;
$indent = " " x $indent_n;

my ($file, $gpx_file);
for (@ARGV) {
    $file = $_ if /(?i:\.fit)$/;
    die "No FIT input file provided" unless $file;
    die "No file named $file found"  unless -f $file
}

if (defined $outfile) {
    $gpx_file = $outfile
} else {
    ($gpx_file = $file) =~ s/(?i:.fit)$/.gpx/i
}
die "File $gpx_file already exists\n" if -f $gpx_file and !$force;

=head2 Options

=over 4

=item C<< --outfile=I<$filename> >>

specifies the name of the converted file instead of the default to simply change the extension to I<*.gpx>.

=item C<< --force >>

overwrites an existing file if true.

=item C<< --indent=# >>

specifies the number of spaces to use for indentation of the XML in the GPX file. The default is 2.

=item C<< --time_offset=I<#> >>

adds a time offset to the timestamp of waypoints, where I<#> refers to the number of seconds by which to offset by.

=back

=cut

my ($fit, @id, @locations);

$fit = Geo::FIT->new();
$fit->file($file);

$fit->use_gmtime(1);
$fit->numeric_date_time(1);
$fit->semicircles_to_degree(1);
$fit->mps_to_kph(1);
$fit->without_unit(1);
$fit->maybe_chained(0);
$fit->drop_developer_data(1);
$fit->data_message_callback_by_name('',
    sub {
        my ($msg, $name) = _message(@_);
        if ($msg) {
            push @id, $msg        if $name eq "file_id";
            push @locations, $msg if $name eq "location"
        }
        return 1
    }
);
$fit->open() or die $fit->error();

my ($f_size) = $fit->fetch_header();
unless (defined $f_size) {
    $fit->error("can't read FIT header") unless defined $fit->error();
    die $fit->error()
}
1 while $fit->fetch();

my (%device, $oem, $prod, $desc);
%device = %{$id[0]};
$oem  = defined $device{manufacturer} ? $device{manufacturer} :  "Unknown OEM";
$prod = defined $device{garmin_product} ? $device{garmin_product} : "unknown";
$desc = ucfirst "recorded on a $oem $prod device";

if (@locations) {
    open (my $fh, ">", $gpx_file) or die "cannot open $gpx_file: $!";
    select $fh;
    printf "<?xml %s?>\n", 'version="1.0" encoding="UTF-8"';
    _write_header();
    _write_meta();
    _write_waypoints();
    printf "</gpx>\n";
    select STDOUT
}

sub _message {
	my ($fit, $desc, $v) = @_;

	my $m_name = $desc->{message_name};
	return undef unless $m_name;

	my $msg = {};

	for my $i_name (keys %$desc) {
		next if $i_name !~ /^i_/;
		my $name = $i_name;

		$name =~ s/^i_//;

		my $attr  = $desc->{'a_' . $name};
		my $tname = $desc->{'t_' . $name};
		my $pname = $name;

		if (ref $attr->{switch} eq 'HASH') {
			my $t_attr = $fit->switched($desc, $v, $attr->{switch});

			if (ref $t_attr eq 'HASH') {
				$attr = $t_attr;
				$tname = $attr->{type_name};
				$pname = $attr->{name}
			}
		}

		my $i = $desc->{$i_name};
		my $c = $desc->{'c_' . $name};
		my $type = $desc->{'T_' . $name};
		my $invalid = $desc->{'I_' . $name};
		my $j;

		my $len = @$v;
		for ($j = 0 ; $j < $c ; $j++) {
			my $ij = $i + $j;
			$ij >= $len && next;
			Geo::FIT->isnan($v->[$ij]) && next;
			$v->[$ij] != $invalid && last
		}
		if ($j < $c) { # skip invalid
			if ($type == FIT_STRING) {
				$msg->{$pname} = $fit->string_value($v, $i, $c)
			}
			else {
				# return only the first value if array
				$msg->{$pname} = $fit->value_cooked($tname, $attr, $invalid, $v->[$i])
			}
		}
	}
	return ($msg, $m_name)
}

sub _enc {
  return encode_entities_numeric( $_[0] );
}

# https://www.topografix.com/GPX/1/1/#element_gpx
sub _write_header {
	printf "<gpx %s", 'version="1.1" creator="locations2gpx.pl"';
	my $loc = 'xsi:schemaLocation="';
	$loc = $loc . "http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd";
	$loc = $loc . " http://www.garmin.com/xmlschemas/GpxExtensions/v3 http://www8.garmin.com/xmlschemas/GpxExtensionsv3.xsd";
	$loc = $loc . " http://www.garmin.com/xmlschemas/TrackPointExtension/v1 http://www8.garmin.com/xmlschemas/TrackPointExtensionv1.xsd";
	$loc = $loc . " http://www.garmin.com/xmlschemas/WaypointExtension/v1 http://www8.garmin.com/xmlschemas/WaypointExtensionv1.xsd";
	$loc = $loc . " http://www.cluetrust.com/XML/GPXDATA/1/0 http://www.cluetrust.com/Schemas/gpxdata10.xsd";
	$loc = $loc . '"';
	printf " %s", $loc;
	printf " %s", 'xmlns="http://www.topografix.com/GPX/1/1"';
	printf " %s", 'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"';
	# garmin_ext
	printf " %s", 'xmlns:gpxx="http://www.garmin.com/xmlschemas/GpxExtensions/v3"';
	printf " %s", 'xmlns:gpxtrx="http://www.garmin.com/xmlschemas/GpxExtensions/v3"';
	printf " %s", 'xmlns:gpxtpx="http://www.garmin.com/xmlschemas/TrackPointExtension/v1"';
	printf " %s", 'xmlns:gpxwpx="http://www.garmin.com/xmlschemas/WaypointExtension/v1"';
	printf ">\n";
}

# https://www.topografix.com/GPX/1/1/#type_metadataType
sub _write_meta {
	my $name;   # none for now but declaring so it can be easily assigned
	printf "%s<metadata>\n",          $indent;
	printf "%s<name>%s</name>\n",     $indent x 2, _enc( $name ) if defined $name;
	printf "%s<desc>%s</desc>\n",     $indent x 2, _enc( $desc );

	my $author_name = 'Converted from Locations.fit by locations2gpx.pl';
	printf "%s<author>\n",            $indent x 2;
	printf "%s<name>%s</name>\n",     $indent x 3, _enc( $author_name );
	printf "%s</author>\n",           $indent x 2;

	my ($url, $text, $type);     # none for now but declaring so they can be easily assigned
	if (defined $url) {
		printf "%s<link href=\"%s\">\n",  $indent x 2, _enc( $url  ) ;
		printf "%s<text>%s</text>\n",     $indent x 3, _enc( $text ) if defined $text;
		printf "%s<type>%s</type>\n",     $indent x 3, $type if defined $type;
		printf "%s</link>\n",             $indent x 2;
	}
	printf "%s</metadata>\n",        $indent
}

sub _write_waypoints {
	if (@locations) {
		my $ai = 0; # alt index
		for (@locations) {
			_print_wpt(\%$_, $ai);
			$ai++
		}
	}
}

sub _print_wpt {
	my ($m, $alt_index) = @_;     # alt_index is not used

	# https://www.topografix.com/GPX/1/1/#type_wptType

	my ($time, $lon, $lat, $ele, $name, $desc);
	while (my ($key, $val) = each %{$m}) {
        # print "\$key is: $key, \$val is $val \n";
		if ($key eq "timestamp") { $time = $val + $time_offset } # + $timeoffs;
		elsif ($key eq "position_long") { $lon = $val }
		elsif ($key eq "position_lat")  { $lat = $val }
		elsif ($key eq "altitude" and !defined $ele) { $ele = $val }
		elsif ($key eq "enhanced_altitude") {
			if (defined $val) { $ele = $val } # only if valid
		}
		elsif ($key eq "name") { $name = $val }
		elsif ($key eq "unknown6") { $desc = $val }
	}
    # TODO: dump other unknown\d keys to STDERR

	printf "%s<wpt lat=\"%s\" lon=\"%s\">\n", $indent, $lat, $lon;
	printf "%s<ele>%s</ele>\n", $indent x 2, $ele if defined $ele;
	if (defined $time) {
		printf "%s<time>%s</time>\n", $indent x 2, $fit->date_string($time);
	}
	printf "%s<name>%s</name>\n", $indent x 2, _enc( $name ) if defined $name;
	printf "%s<desc>%s</desc>\n", $indent x 2, _enc( $desc ) if defined $desc;
	printf "%s</wpt>\n", $indent
}

=head1 DEPENDENCIES

L<Geo::FIT>

=head1 SEE ALSO

L<Geo::Gpx>

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to C<bug-geo-gpx@rt.cpan.org>, or through the web interface at L<http://rt.cpan.org>.

=head1 AUTHOR

Patrick Joly

=head1 VERSION

1.04

=head1 LICENSE AND COPYRIGHT

Copyright 2022, Patrick Joly C<< patjol@cpan.org >>. All rights reserved.

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.

=cut

1;
