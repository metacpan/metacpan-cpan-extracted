
=head1 NAME

Device::TNC - A generic interface to a TNC

=head1 DESCRIPTION

This module implements a generic interface to a Terminal Node Controller (TNC).

It loads sub classes that provide the low level interface for the appropriate
TNC to be used and provides higher level methods to return frames of data to the
user is human readable form.

=head1 SYNOPSIS

  use Device::TNC;
  my $tnc_type = 'KISS';
  my %tnc_config = (
    'port' => ($Config{'osname'} eq "MSWin32") ? "COM3" : "/dev/TNC-X",
    'baudrate' => 9600,
    'warn_malformed_kiss' => 1,
    'raw_log' => "raw_packet.log",
  );
  my $tnc = new Device::TNC($tnc_type, %tnc_config);
  die "Error: Something went wrong connecting to the TNC.\n" unless $tnc;

  while (1)
  {
    my $data = $tnc->read_frame();
    my $repeaters = join ", ", @{$data->{'ADDRESS'}->{'REPEATERS'}};
    my $info = join "", @{$data->{'INFO'}};
    print "From: $data->{'ADDRESS'}->{'SOURCE'} ";
    print "To: $data->{'ADDRESS'}->{'DESTINATION'} ";
    print "via $repeaters\n";
    print "Data: $info\n";
  }

=cut

package Device::TNC;

####################
# Standard Modules
use strict;
use Config;
use Data::Translate;
# Custom modules

####################
# Variables
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION);
@ISA = qw();
@EXPORT = qw();
@EXPORT_OK = qw();
$VERSION = 0.03;
$| = 1;

my $translator = new Data::Translate();

# I'm not sure what this was for... It came from the KISS2ASC program that I
# originally based a lot of this on. I've since updated everything that is here
# to match/comply with what the AX.25 standard doc says.
# I'm not using it now and will remove soon unless I find the reason it was in
# KISS2ASC.

# pollcode gives the flags used to represent the various sets of poll and final flags.
# It is indexed by three bits:
# pollcode[0x10 bit of control][0x80 bit of destcall][0x80 bit of fromcall]
#
# We use the following codes, Followed WA8DED:
#       ! Version 1 with poll/final
#       ^ Version 2 command without poll
#       + Version 2 command with poll
#       - Version 2 response with final
#       v Version 2 response without final
# 0 in the table indicates no charater is to be output.
#
my @m_pollcode;
$m_pollcode[0]->[0]->[0] = 0;
$m_pollcode[0]->[0]->[1] = 'v';
$m_pollcode[0]->[1]->[0] = '^';
$m_pollcode[0]->[1]->[1] = 0;
$m_pollcode[1]->[0]->[0] = '!';
$m_pollcode[1]->[0]->[1] = '-';
$m_pollcode[1]->[1]->[0] = '+';
$m_pollcode[1]->[1]->[1] = '!';

# This is how this array is used.
#my $val1 = ($control & 0x10) ? 1 : 0;
#my $val2 = (ord($frame[6]) & 0x80) ? 1 : 0;
#my $val3 = (ord($frame[13]) & 0x80) ? 1 : 0;
#$data{'POLLCHAR'} = $m_pollcode[$val1]->[$val2]->[$val3];

####################
# Functions

################################################################################

=head2 B<new()>

 my $type = "KISS";
 my %tnc_data = { 'option' => 'value' };
 my $tnc = new Device::TNC($type, %tnc_data);

The new method creates and returns a new Device::TNC object that can be
used to communicate with a Terminal Node Controller (TNC) of the type passed.

The method requires that the first passed argument be the type of TNC to connect
to. This will try and load the appropriate module for the TNC type.

The subsequent options are passed to the module that is loaded to connect to the
desired TNC.

For more details on these options see the module documentation for the TNC type.

=cut

sub new
{
	my $class = shift;
	my $type = uc(shift);
	my %tnc_data = @_;
	my $tnc = undef;

	unless (scalar $type)
	{
		warn "Error: No TNC type passed.\n";
		return undef;
	}

	my $load_module = "require Device::TNC::$type;\n";
	$load_module .= '$tnc' . " = new Device::TNC::$type(%tnc_data);\n";
	eval $load_module;
	if ($@)
	{
		warn "$@\n";
		warn "Error: Failed to load Device::TNC::$type\n";
	}

	return $tnc;
}

################################################################################

=head2 B<read_frame()>

 my $frame_data = $tnc->read_frame();
 my %frame_data = $tnc->read_frame();

This method reads a HDLC frame from the TNC and returns a structure as either a
hash or a hash reference that contains the fields of the frame.

The structure of the returned data is like the following.

  {
    'INFO' => [
      '/', '0', '6', '4', '6', '5', '8', 'h', '3', '3', '5', '0', '.', '0', '0',
      'S', '\\', '1', '5', '1', '1', '2', '.', '0', '0', 'E', 'O', '2', '2', '6',
      '/', '0', '0', '0', '/', 'A', '=', '0', '0', '0', '1', '1', '1'
    ],
    'PID' => 'F0',
    'CONTROL' => {
      'POLL_FINAL' => 0,
      'FIELD_TYPE' => 'UI',
      'FRAME_TYPE' => 'U'
    },
    'ADDRESS' => {
      'DESTINATION' => 'APT311',
      'REPEATERS' => [
        'WIDE1-1',
        'WIDE2-2'
        ],
      'SOURCE' => 'VK2KFJ-7'
    }
  }

While developing this module I only received U (UI) type frames and so
development of the code to work with I and S frames didn't really progress.
If anyone want's to read I or S frames please let me know and I'll have a look
at implementing them. Please create a KISS log of the data and email it to me.

=cut

sub read_frame
{
	my $self = shift;
	my %data;
	my ($type, @frame) = $self->read_hdlc_frame();

	my $location = 0;
	# Get the destination
	for (my $loc = 0; $loc < 7; $loc++)
	{
		my $byte = ord($frame[$location]);
		if ($byte != 0x40)
		{
			my $shift_byte = ($byte >> 1);
			my ($s, $ascii) = $translator->h2a(sprintf("%X",$shift_byte));
			if ($loc == 6)
			{
				my $ssid = ($byte & 0x1E) >> 1;
				$data{'ADDRESS'}->{'DESTINATION'} .= "-$ssid" if $ssid > 0;
			}
			else
			{
				$data{'ADDRESS'}->{'DESTINATION'} .= $ascii;
			}
		}
		$location++;
	}
	# Get the source
	for (my $loc = 0; $loc < 7; $loc++)
	{
		my $byte = ord($frame[$location]);
		if ($byte != 0x40)
		{
			my $shift_byte = ($byte >> 1);
			my ($s, $ascii) = $translator->h2a(sprintf("%X",$shift_byte));
			if ($loc == 6)
			{
				my $ssid = ($byte & 0x1E) >> 1;
				$data{'ADDRESS'}->{'SOURCE'} .= "-$ssid" if $ssid > 0;
			}
			else
			{
				$data{'ADDRESS'}->{'SOURCE'} .= $ascii;
			}
		}
		$location++;
	}

	# Find the repeaters if any.
	@{$data{'ADDRESS'}->{'REPEATERS'}} = ();
	my $control = ord($frame[$location]);
	while (($control & 1) == 0)
	{
		my $repeater = "";
		for (my $loc = 0; $loc < 7; $loc++)
		{
			my $byte = ord($frame[$location]);
			if ($byte != 0x40)
			{
				my $shift_byte = ($byte >> 1);
				my ($s, $ascii) = $translator->h2a(sprintf("%X",$shift_byte));
				if ($loc == 6)
				{
					my $ssid = ($byte & 0x1E) >> 1;
					#printf(" SSID: %d\n", $ssid);
					$repeater .= "-$ssid" if $ssid > 0;
				}
				else
				{
					$repeater .= $ascii;
				}
			}
			$location++;
		}
		push @{$data{'ADDRESS'}->{'REPEATERS'}}, $repeater;
		$control = ord($frame[$location]);
	}

	# Now find the frame type
	$location++;
	if (($control & 1) == 0) # Information (I) frame found
	{
		# No data gathered to work with here.

		# Control field is 1 or 2 bytes
#		push @{$data{'CONTROL'}}, $control, ord($frame[$location]);
#		push @{$data{'CRAP'}->{'CONTROL_BIN'}}, $translator->d2b($control), $translator->d2b(ord($frame[$location]));

#		$data{'CRAP'}->{'FRAME_TYPE'} = sprintf("I%d%d", (($control & 0xE0) >> 5), (($control & 0x0E) >> 1));
#		$data{'PID'} = sprintf("%02X", (ord($frame[$location]) & 0xFF));
#		while ( (my $byte = $frame[$location]) and ( ($location ne $#frame) or ($location ne $#frame - 1)) )
#		{
#			#my ($s, $ascii) = $translator->h2a(sprintf("%X",$byte));
#			push @{$data{'INFO'}},  $byte;
#			$location++;
#		}
	}
	elsif (($control & 3) == 1) # Supervisory (S) frame found
	{
		# No data gathered to work with here.

		# Control field is 1 or 2 bytes
#		push @{$data{'CONTROL'}}, $control, ord($frame[$location]);
#		push @{$data{'CRAP'}->{'CONTROL_BIN'}}, $translator->d2b($control), $translator->d2b(ord($frame[$location]));

#		$data{'CRAP'}->{'FRAME_TYPE'} = sprintf("%s%d", (($control & 0x0C) >> 2), (($control & 0xE0) >> 5) );
#		$data{'CRAP'}->{'FRAME_TYPE'} .= sprintf(" FRAME TYPE IN HEX = %X for 0C or maybe %X for EF it's number is %d", ($control & 0x0C), ($control & 0xEF), (($control & 0xE0) >> 5) );
	}
	elsif (($control & 0xEF) == 0x03) # Unnumbered (U) frame found
	{
		# Control field is 1 byte
		$data{'CONTROL'}->{'FRAME_TYPE'} = "U";
		$data{'CONTROL'}->{'POLL_FINAL'} = ($control & 0x10) ? 1 : 0;
		$data{'CONTROL'}->{'FIELD_TYPE'} = "SABM" if ($control & 0xEF) == 0x2F;
		$data{'CONTROL'}->{'FIELD_TYPE'} = "DISC" if ($control & 0xEF) == 0x43;
		$data{'CONTROL'}->{'FIELD_TYPE'} = "DM" if ($control & 0xEF) == 0x0F;
		$data{'CONTROL'}->{'FIELD_TYPE'} = "UA" if ($control & 0xEF) == 0x63;
		$data{'CONTROL'}->{'FIELD_TYPE'} = "FRMR" if ($control & 0xEF) == 0x87;
		$data{'CONTROL'}->{'FIELD_TYPE'} = "UI" if ($control & 0xEF) == 0x03;
		$data{'CONTROL'}->{'FIELD_TYPE'} = "XID" if ($control & 0xEF) == 0xAF;
		$data{'CONTROL'}->{'FIELD_TYPE'} = "TEST" if ($control & 0xEF) == 0xE3;

		$data{'PID'} = sprintf("%02X", ord($frame[$location]));
		$location++;
		while ($location <= $#frame)
		{
			my $byte = $frame[$location];
			#my ($s, $ascii) = $translator->h2a(sprintf("%X",$byte));
			push @{$data{'INFO'}},  $byte;
			$location++;
		}
	}
	else
	{
		warn "Error: Couldn't determine the frame type.\n";
	}

	#Finally get the Frame Check Sequence which is the last two bytes of the frame
	#$data{'FCS'} = sprintf("%02X", ord($frame[$#frame - 1])) . sprintf("%02X", ord($frame[$#frame]));

	if (wantarray)
	{
		return %data;
	}
	else
	{
		return \%data;
	}
}

1;

__END__

=head1 SEE ALSO

 Device::TNC::KISS

AX.25 Link-Layer Protocol Specification L<http://www.tapr.org/pub_ax25.html>

=head1 AUTHOR

R Bernard Davison E<lt>bdavison@asri.org.auE<gt>

=head1 COPYRIGHT

Copyright (C) 2007, Australian Space Research Institute.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
