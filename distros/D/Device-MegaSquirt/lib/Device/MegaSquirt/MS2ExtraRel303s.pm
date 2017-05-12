package Device::MegaSquirt::MS2ExtraRel303s;
use strict;
use warnings;

use Carp;

use Text::LookUpTable;

use vars qw(@ISA);
@ISA = ('Device::MegaSquirt');

=head1 NAME

Device::MegaSquirt::MS2ExtraRel303s - operations for version 'MS2Extra Rel 3.0.3s'

=head1 SYNOPSIS

 $ms = Device::MegaSquirt->new($device);

 $tbl = $ms->read_advanceTable1();
 $res = $ms->write_advanceTable1($tbl);

 $tbl = $ms->read_veTable1();
 $res = $ms->write_veTable1($tbl);

 $val = $ms->read_crankingRPM();
 $res = $ms->write_crankingRPM($val);

 $data = $ms->read_BurstMode();

=head1 DESCRIPTION

This modules implements the version specific operations of Device::MegaSquirt
for version 'MS2Extra Rel 3.0.3s'.

=head1 OPERATONS

=cut

# {{{ new()

=head2 Device::MegaSquirt::MS2ExtraRel303s->new($mss)

  Returns object TRUE on success, FALSE on error

Given a Device::MegaSquirt::Serial object ($mss) it creates a
new object.

 $ms = Device::MegaSquirt::MS2ExtraRel303s->new($mss);

Normally this is called from MegaSquirt->new() and is not
called directly.

 $ms = Device::MegaSquirt->new($dev);

=cut

sub new {
	my ($class, $mss) = @_;
	# mss - mega squirt serial device

	bless {
		version => 'MS2Extra Rel 3.0.3s',
		mss => $mss,
	}, $class;
}

# }}}

# {{{ read_BurstMode()

=head2 $ms->read_BurstMode()

  Returns: TRUE on success, FALSE on error

Retrives one chunk of burst mode data.

  $data = $ms->read_BurstMode();
  print $data->{'pulseWidth1'} . "\n";

=cut


sub read_BurstMode {
	my $self = shift;
	my $mss = $self->{mss};

	my $num_bytes = 145;

	my $data = $mss->read_A($num_bytes);

	_parse_bin($data);
}

# {{{ _parse_bin()

# Parse the read data (binary) in to a Perl object.

# "A"
# (65) - MS2 sends the real time variables as an array of 152 bytes
# (will continues to change).  [2]
#
# The variable names and properties for each byte are described in the
# msn-extra.ini file shipped with each version of MS2/Extra.  [2]
#
# Open megaquirt-ii.ini  (found along with the firmware) and search for
# afr1 after the line [BurstMode]   [2]
#

# {{{ %dat_def
# Definition of the data in a BurstMode packet.
my %dat_def = (
	seconds => {
		packt => 'n',     # perl 'pack' type
		offset => 0,      # offset in bytes
		mtype => 'U16',   # Megasuirt type in .ini
		units => 's',     # units
		#conv_fn => sub { $_[0] * 0.000666 }, # function to convert value from raw data
		mult => 1.0,     # value to multiply by, default 1
		scale => 0,       # value to add to
	},
	pulseWidth1 => {
		packt => 'n',
		offset => 2,
		mtype => 'U16',
		units => 's',
		mult => 0.000666,
	},
	pulseWidth2 => {
		packt => 'n',
		offset => 4,
		mtype => 'U16',
		units => 's',
		mult => 0.000666,
	},
	rpm => {
		packt => 'n',
		offset => 6,
		mtype => 'U16',
		units => 'RPM',
	},
	advance => {
		packt => 'n',
		offset => 8,
		mtype => 'S16',
		units => 'deg',
		mult => 0.100,
	},
	squirt => {
		packt => 'B8',  # 8 bit byte
		offset => 10,
		mtype => 'U08',
		units => 'bit',
	},
	engine => {
		packt => 'B8',
		offset => 11,
		mtype => 'U08',
		units => 'bit',
	},
	afrtgt1 => {
		packt => 'C',
		offset => 12,
		mtype => 'U08',
		units => 'AFR',
		mult => 10.00,
	},
	afrtgt2 => {
		packt => 'C',
		offset => 13,
		mtype => 'U08',
		units => 'AFR',
		mult => 10.00,
	},
	wb02_en1 => {
		packt => 'C',
		offset => 14,
		mtype => 'U08',
		units => '',
	},
	wb02_en2 => {
		packt => 'C',
		offset => 15,
		mtype => 'U08',
		units => '',
	},
	barometer => {
		packt => 'n',
		offset => 16,
		mtype => 'S16',
		units => 'kPa',
		mult => '0.100',
	},
	map => {
		packt => 'n',
		offset => 18,
		mtype => 'S16',
		units => 'kPa',
		mult => '0.100',
	},
	mat => {
		packt => 'n',
		offset => 20,
		mtype => 'S16',
		units => '°F',
		mult => '0.100',
	},
	coolant => {
		packt => 'n',
		offset => 22,
		mtype => 'S16',
		units => '°F',
		mult => '0.100',
	},
	tps => {
		packt => 'n',
		offset => 24,
		mtype => 'S16',
		units => '%',
		mult => '0.100',
	},
	batteryVoltage => {
		packt => 'n',
		offset => 26,
		mtype => 'S16',
		units => 'v',
		mult => '0.100',
	},
	afr1 => {
		packt => 'n',
		offset => 28,
		mtype => 'S16',
		units => 'AFR',
		mult => 0.100,
	},
	afr2 => {
		packt => 'n',
		offset => 30,
		mtype => 'S16',
		units => 'AFR',
		mult => 0.100,
	},
	egoCorrection1 => {
		packt => 'n',
		offset => 36,
		mtype => 'S16',
		units => '%',
		mult => 0.1000,
	},
	airCorrection => {
		packt => 'n',
		offset => 38,
		mtype => 'S16',
		units => '%',
	},
	warmupEnrich => {
		packt => 'n',
		offset => 40,
		mtype => 'S16',
		units => '%',
	},

	# TODO more tedious work adding entries from megasquirt-ii.ini.ms2extra
);
# }}}

sub _parse_bin {
    my $bin = shift;

	my %data = ();

	foreach my $name (keys %dat_def) {
		my $def = $dat_def{$name};	

		my $packt = $def->{packt};
		my $offset = $def->{offset};

		my ($val) = unpack('@' . $offset . $packt, $bin);

		# Convert the raw value in to something more meaningful.
		if (exists $def->{'conv_fn'}) {
			my $fn = $def->{'conf_fn'};
			$val = $fn->($val);
		} else {
			if (exists $def->{'scale'}) {
				$val += $def->{'scale'};	
			}
			if (exists $def->{'mult'}) {
				$val *= $def->{'mult'};	
			}
		}

		$data{$name} = $val;
	}

	return \%data;
#	my ($seconds, $pulseWidth1, $pulseWidth2, $rpm, $advance, $squirt, $engine,
#	$afrtgt1, $afrtgt2, $wbo2_en1, $wbo2_en2, $barometer, $map,
#	$mat, $coolant, $tps) =
#	unpack("nnnnnB8B8CCCCnnnnn", $data);
	#
	#{
	#	seconds => $seconds,
	#	pulseWidth1 => $pulseWidth1,
	#};
}

# }}}

# }}}

# {{{ read_advanceTable1() :-)

=head2 $ms->read_advanceTable1()

  Returns: Text::LookUpTable object (TRUE) on success, FALSE on error

  $tbl = $ms->read_advanceTable1();

=cut

sub read_advanceTable1 {
	my $ms = shift;

    my $mss = $ms->get_mss();

    #
    # doc/ini/megasquirt-ii.ms2extra.alpha_3.0.3u_20100522.ini
    # page = 3
    #   advanceTable1 = array , S16, 000, [12x12], "deg", 0.10000, 0.0
    #
    # page = 3 -> table_idx 7
    # 
    # read_r(<tble_idx, ...
    my $packed_bytes = $mss->read_r(_page_to_table(3), 0, 288);

    my @vals = unpack("n*", $packed_bytes);  # S16

    my $num_rcvd = @vals;
    if ($num_rcvd != 144) {
        carp "ERROR: received $num_rcvd bytes but was expecting 144.";
        return;
    }

    # convert values
    @vals = map { $_ * 0.100; } @vals;

    # Start with a blank table of the correct dimensions
    # and then set the values accordingly.

    my $tbl = Text::LookUpTable->load_blank(12, 12, "rpm", "load");

    my @xs = $ms->read_srpm_table1();
    my @ys = $ms->read_smap_table1();

    $tbl->set_x_coords(@xs);
    $tbl->set_y_coords(@ys);

    my $n = 0;
    for (my $i = 0; $i < 12; $i++) {
        for (my $j = 0; $j < 12; $j++) {
            $tbl->set($j, $i, $vals[$n]);
            $n++;
        }
    }

    return $tbl;
}

# {{{ read_srpm_table1() :-)

#
# Returns: @list on success, FALSE on error
#
# Reads the values of the rpm coordinates for advanceTable1.
#

sub read_srpm_table1 {
	my $ms = shift;

    my $mss = $ms->get_mss();

    #
    # doc/ini/megasquirt-ii.ms2extra.alpha_3.0.3u_20100522.ini
    # page = 3, tble_idx = 7
    #
    #   srpm_table1     = array ,  U16,    576,    [   12], "RPM",      1.00000,   0.00000,  0.00,15000.00, 
    #
    #
    my $read = $mss->read_r(_page_to_table(3), 576, 24);
    my @bytes = unpack("n*", $read);  # U16
    #my @bytes = unpack("v*", $read);  # U16
    #my @bytes = unpack("s*", $read);  # U16
    #my @bytes = unpack("S*", $read);  # U16
    my $num_rcvd = @bytes;
    if ($num_rcvd != 12) {
        carp "ERROR: received $num_rcvd value but was expecting 12.";
        return;
    }

    # no processing, pass on data as is

    return @bytes;
}

# }}}

# {{{ read_smap_table1() :-)

#
# Returns: @list on success, FALSE on error
#
# Reads the values of the map coordinates for advanceTable1.
#

sub read_smap_table1 {
	my $ms = shift;

    my $mss = $ms->get_mss();

    #
    # doc/ini/megasquirt-ii.ms2extra.alpha_3.0.3u_20100522.ini
    #
    # page = 3
    #  smap_table1 = array ,  S16,    624,    [   12], "%",      0.10000,   0.00000,  0.00,  400.00,      1 ; * ( 24 bytes)
    #
    my $read = $mss->read_r(_page_to_table(3), 624, 24);
    my @bytes = unpack("n*", $read);  # U16
    my $num_rcvd = @bytes;
    if ($num_rcvd != 12) {
        carp "ERROR: received $num_rcvd value but was expecting 12.";
        return;
    }

    @bytes = map { ($_ * 0.100); } @bytes;

    # the bytes are backwards, not sure why, fix them
    @bytes = reverse @bytes;

    return @bytes;
}

# }}}

# }}}

# {{{ write_advanceTable1() :-)

=head2 $ms->write_advanceTable1()

  Returns: TRUE on success, FALSE on error

  $ms->write_advanceTable1($tbl);

=cut

# TODO - write srpm, smap

sub write_advanceTable1 {
	my $ms = shift;
    my $tbl = shift;

    my $mss = $ms->get_mss();

    my @vals = $tbl->flatten();

    # un-convert values
    @vals = map { $_ / 0.100; } @vals;

    my $pack = pack("n*", @vals);
    my @bytes = unpack("C*", $pack);

    unless (288 == @bytes) {
        carp "wrong number of bytes";
        return;
    }

    $mss->write_w(_page_to_table(3), 0, @bytes);
}

# }}}

# {{{ read_veTable1() :-)

=head2 $ms->read_veTable1()

  Returns: Text::LookUpTable object (TRUE) on success, FALSE on error

  $tbl = $ms->read_veTable1();

=cut

sub read_veTable1 {
	my $ms = shift;

    my $mss = $ms->get_mss();

    #
    # doc/ini/megasquirt-ii.ms2extra.alpha_3.0.3u_20100522.ini
    # page = 5
    #  veTable1 = array , U08, 0, [16x16], "%", 1.00000, 0.00000, 0.00, 255.00,      0 ; * (144 bytes)
    #
    my $read = $mss->read_r(_page_to_table(5), 0, 256);
    my @bytes = unpack("C*", $read);
    my $num_rcvd = @bytes;
    if ($num_rcvd != 256) {
        carp "ERROR: received $num_rcvd bytes but was expecting 256.";
        return;
    }

    my $tbl = Text::LookUpTable->load_blank(16, 16, "rpm", "load");

    my @xs = $ms->read_frpm_table1();
    my @ys = $ms->read_fmap_table1();

    $tbl->set_x_coords(@xs);
    $tbl->set_y_coords(@ys);

    my $n = 0;

    for (my $i = 0; $i < 16; $i++) {
        for (my $j = 0; $j < 16; $j++) {
            $tbl->set($j, $i, $bytes[$n]);
            $n++;
        }
    }

    return $tbl;
}

# {{{ read_frpm_table1() :-)

#
# Returns list of values on SUCCESS, FALSE on error
#
# Reads the rpm coordinate values for veTable1.
#

sub read_frpm_table1 {
	my $ms = shift;

    my $mss = $ms->get_mss();

    #
    # doc/ini/megasquirt-ii.ms2extra.alpha_3.0.3u_20100522.ini
    # page = 5
    #
    # frpm_table1     = array ,  U16,    768,    [   16], "RPM",      1.00000,   0.00000,  0.00,15000.00,      0 ; * ( 24 bytes)
    #
    my $read = $mss->read_r(_page_to_table(5), 768, 32);
    my @bytes = unpack("n*", $read);  # U16
    my $num_rcvd = @bytes;
    if ($num_rcvd != 16) {
        carp "ERROR: received $num_rcvd bytes but was expecting 16.";
        return;
    }

    # no process, pass on data as is

    return @bytes;
}

# }}}

# {{{ read_fmap_table1() :-)

#
# Returns list of values on SUCCESS, FALSE on error
#
# Reads the map coordinate values for veTable1.
#

sub read_fmap_table1 {
	my $ms = shift;

    my $mss = $ms->get_mss();

    #
    # doc/ini/megasquirt-ii.ms2extra.alpha_3.0.3u_20100522.ini
    # page = 5
    #
    # fmap_table1     = array ,  S16,    864,    [   16], "%",      0.10000,   0.00000,  0.00,  400.00,      1 ; * ( 24 bytes)
    #
    # page 5 -> table_idx = 9
    #
    my $read = $mss->read_r(_page_to_table(5), 864, 32);
    my @bytes = unpack("n*", $read);  # U16
    my $num_rcvd = @bytes;
    if ($num_rcvd != 16) {
        carp "ERROR: received $num_rcvd bytes but was expecting 16.";
        return;
    }

    @bytes = map { ($_ * 0.100); } @bytes;

    # the bytes are backwards, not sure why, fix them
    @bytes = reverse @bytes;

    return @bytes;
}

# }}}

# }}}

# {{{ write_veTable1() :-)

=head2 $ms->write_veTable1()

  Returns TRUE on success, FALSE on error

  $ms->write_veTable1($tbl);

=cut

# TODO - write frpm, fmap

sub write_veTable1 {
	my $ms = shift;
    my $tbl = shift;

    my $mss = $ms->get_mss();

    my @bytes = $tbl->flatten();

    $mss->write_w(_page_to_table(5), 0, @bytes);
}

# }}}

# {{{ read_arpm_table1() :-)

sub read_arpm_table1 {
	my $ms = shift;

    my $mss = $ms->get_mss();

    #
    # doc/ini/megasquirt-ii.ms2extra.alpha_3.0.3u_20100522.ini
    #
    # page = 1
    #  arpm_table1     = array ,  U16,    374,    [   12], "RPM",      1.00000,   0.00000,  0.00,15000.00,      0 ; * ( 24 bytes)
    #
    #

    my $read = $mss->read_r(_page_to_table(1), 374, 24);
    unless ($read) {
        carp "read_arpm_table1() read_r error\n";
        return;
    }

    my @bytes = unpack("n*", $read);  # U16

    my $num_rcvd = @bytes;

    if ($num_rcvd != 12) {
        carp "ERROR: received $num_rcvd value but was expecting 12.";
        return;
    }

    # no need to process, pass on data as is

    return @bytes;
}

# }}}

# {{{ read_crankingRPM() :-)

=head2 $ms->read_crankingRPM()

  Returns $val on success, FALSE on error

 $val = $ms->read_crankingRPM();

=cut

sub read_crankingRPM {
	my $ms = shift;

    my $mss = $ms->get_mss();

    my $read = $mss->read_r(_page_to_table(1), 20, 2);
    unless ($read) {
        carp "read_crankingRPM() read_r error\n";
        return;
    }

    my @bytes = unpack("n", $read);  # S16

    my $num_rcvd = @bytes;

    if ($num_rcvd != 1) {
        carp "ERROR: received $num_rcvd value but was expecting 1.";
        return;
    }

    # no need to process, pass on data as is

    return $bytes[0];
}

# }}}

# {{{ write_crankingRPM() :-)

=head2 $ms->write_crankingRPM($val)

  Returns TRUE on success, FALSE on error

 $res = $ms->write_crankingRPM($val);

=cut

sub write_crankingRPM {
	my $ms = shift;
    my $val = shift;

    unless (defined $val) {
        carp "a value must be given to write_crankingRPM";
        return;
    }

    my $mss = $ms->get_mss();

    # write_w expects values in bytes but crankRPM is
    # a two byte integer.  re-pack it accordingly
    my $pack = pack("n", $val);
    my @bytes = unpack("CC", $pack);

    unless (2 == @bytes) {
        my $n = @bytes;
        carp "wrong number of bytes: $n ";
    }

    my $write = $mss->write_w(_page_to_table(1), 20, @bytes);
    unless ($write) {
        carp "write_crankingRPM() write_w error\n";
        return;
    }

    return 1;  # success
}

# }}}

# {{{ _page_to_table() :-)

#
#  Some commands require "table_idx" but in the .ini
#  it is specified as "page.
#  _page_to_table provides this conversion.
#
#  The conversions described in [2] are apparantley out of date
#  because some of them do not work.
#
#  These conversions were found through trial and error.
#

sub _page_to_table {
	my $page = shift;

    my $table;
    if (1 == $page) {
        $table = 4;
    } elsif (3 == $page) {
        $table = 10;
    } elsif (5 == $page) {
        $table = 9;
    } else {
        carp "ERROR: undefined page '$page' for _page_to_table()";
        return;
    }

    return $table;
}

# }}}

=head1 REFERENCES

  [1]  MegaSquirt Engine Management System
       http://www.msextra.com/

  [2]  http://home.comcast.net/~whaussmann/RS232_MS2E/RS232_MS2_tables.htm#adv_tbl

=head1 AUTHOR

    Jeremiah Mahler <jmmahler@gmail.com>
    CPAN ID: JERI
    http://www.google.com/profiles/jmmahler#about

=head1 COPYRIGHT

Copyright (c) 2010, Jeremiah Mahler. All Rights Reserved.
This module is free software.  It may be used, redistributed
and/or modified under the same terms as Perl itself.

=head1 SEE ALSO

Text::LookUpTable, Device::MegaSquirt

=cut

# vim:foldmethod=marker

1;
