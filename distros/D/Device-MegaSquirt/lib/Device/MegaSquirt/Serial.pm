package Device::MegaSquirt::Serial;

use strict;
use warnings;
use Carp;

use Time::HiRes qw(usleep);
use Device::SerialPort;

=head1 NAME

Device::MegaSquirt::Serial - Low level serial commands for MegaSquirt.

=head1 SYNOPSIS

 use Device::MegaSquirt::Serial;
 $mss = new Device::MegaSquirt::Serial('/dev/ttyUSB0');

 @data = $mss->read_r(9, 0, 0, 256);

=head1 DESCRIPTION

This library is used for the low level serial commands needed
to communicate with a MegaSquirt [2] controller.

The only concern at this level is how the data is read and written.
The specific details of what the data actually represents is not
defined here.  That should be defined at a higher level where
defintions are made relevant to the Megasquirt version number.

=cut

=head1 OPERATIONS

=cut

# {{{ new()

=head2 Device::MegaSquirt::Serial->new($serial)

    Returns: defined object on success, FALSE otherwise

The I<new> constructor takes a single argument specifying which
serial device to use (e.g. '/dev/ttyUSB0').
If initiation of the device is successful the returned objected
can be used to call other functions.

=cut

sub new {
	my $class = shift;
	my $port_name = shift;

	unless (-e $port_name) {
		carp "ERROR: port '$port_name' does not exist.";
		return;
	}

	my $serial = Device::SerialPort->new($port_name, undef, undef);
	if (!$serial) {
		carp "Can't open $port_name: $!";
		return;
	}

	$serial->baudrate(115200);
	$serial->parity("none");
	$serial->databits(8);
	$serial->stopbits(1);
	$serial->handshake("none");

    $serial->user_msg('ON');
    $serial->error_msg('ON');

    $serial->read_const_time(200);


	bless {serial => $serial}, $class;
}
# }}}

# {{{ read_Q()

=head2 $mss->read_Q()

    Returns: the Megasquirt version number, FALSE on error

Executes the I<Q> command [1] to read the version number.

  $version = $mss->read_Q();


Q' and 'S' commands (both caps) are used to retrieve two indicators of the MS-II
code version. The first is the 20-byte ASCII string for the Rev Number of the
code version, the second is for a 32-byte Signature string. The latter is changed
in the code whenever a new feature is added, the first is changed in the code
whenever there has been an input parameter or output variable added. [1]

=cut

sub read_Q {
	my $self = shift;
	my $serial = $self->{serial};

	my $num_bytes = 20;

	my $num_write = $serial->write("Q");

	my ($num_read, $read) = $serial->read($num_bytes);

	if ($num_read != $num_bytes) {
		carp "ERROR: $num_read bytes read but was expecting $num_bytes.";
		return undef;
	}

	return $read;
}

# }}}

# {{{ read_S()

=head2 $mss->read_S()

    Returns: the Megasquirt signature, FALSE on error

Executes the I<S> command [1] to read the signature.

  $version = $mss->read_S();

See also documentation of read_Q();

=cut

sub read_S {
	my $self = shift;
	my $serial = $self->{serial};

	my $num_bytes = 60;

	my $num_write = $serial->write("S");

	my ($num_read, $read) = $serial->read($num_bytes);

	if ($num_read != $num_bytes) {
		carp "ERROR: $num_read bytes read but was expecting $num_bytes.";
		return undef;
	}

	return $read;
}

# }}}

# {{{ read_A() (burst mode)

=head2 $mss->read_A($num_bytes)

    Returns: hash reference of bytes on success, FALSE on error

Executes the I<A> command [1] (Burst Mode) to read a frame of live variables.

  $dat = $mss->read_A($num_bytes);
  # process $dat elsewhere

The values of the data that is returned is dependent on the Megasquirt
version so the data is returned in its raw form and processing
must be done at a higher level.

The size of data is also version dependent so this is given as an argument
so that it can it can be tested here to see if the correct amount of
data was read.

=cut

sub read_A {
	my $self = shift;
	my $num_bytes = shift;
	my $serial = $self->{serial};

	my $num_write = $serial->write("A");

	my ($num_read, $read) = $serial->read($num_bytes);

	if ($num_read != $num_bytes) {
		carp "ERROR: $num_read bytes read but was expecting $num_bytes.";
		return undef;
	}

	return $read;
}

# }}}

# {{{ read_r()

=head2 $mss->read_r($tbl_idx, $offset, $num_bytes)

	Returns: array of bytes on success, FALSE on error

Executes the I<r> command [1] to read bytes from the controller.

    $tbl_idx - table index/offset; also called 'page'
    $offset - offset
    $num_bytes - the number of bytes to request

=cut

sub read_r {
	my $self = shift;
	my ($tbl_idx, $offset, $num_bytes) = @_;
	my $serial = $self->{serial};

    # If the amount read/written is 0 this may be fixed by
    # waiting and trying again.
    # Partial reads do not appear to occure so they are
    # not handled.

    my $n = 0;
    my $read;
    my $num_read_err = 0;
    my $num_write_err = 0;
    my $success = 0; # default false

    while ($num_read_err < 5 and $num_write_err < 5) {

        # 114 -> 'r'
        my $to_write = pack("CCCnn", 114, 0, $tbl_idx, $offset, $num_bytes);
        my $num_out = $serial->write($to_write);
        if ($num_out != 7) {
            $num_write_err++;
            usleep(100000);  # sleep 100 ms (mili seconds)
            next;
        }

        # 200 ms delay required when switching pages (or anytime)
        usleep(200000);  # sleep 200 ms (mili seconds)
                         # 200 ms -> 200000 us (micro seconds)

        my $num_read;
        ($num_read, $read) = $serial->read($num_bytes);

        if ($num_read != $num_bytes) {
            $num_read_err++;
            next;
            #return;
        } else {
            $success = 1;
            last;
        }
    }

    if (! $success) {
        carp "ERROR: unrecoverable error when using read_r (errors read/write = $num_read_err/$num_write_err)";
        return;
    }

	return $read;
}

# }}}

# {{{ write_w()

=head2 $mss->write_w($tbl_idx, $offset, @bytes)

  Returns: TRUE on success, FALSE on error

Executes the I<w> command [1] to write bytes to the controller.

  $tbl_idx - table index/offset; also called 'page'
  $offset - offset
  @bytes - data bytes to be written

It is expected that @bytes are only 1 byte chunks.
For example to write a two byte integer it must be broken
down in to 2 bytes.

 $pack = pack("n", $integer);
 @bytes = unpack("CC", $pack);

=cut

sub write_w {
	my $self = shift;
	my ($tbl_idx, $offset, @data) = @_;
	my $serial = $self->{serial};

    my $num_bytes = @data;

    unless ($num_bytes > 0) {
        carp "no bytes to write";
        return;
    }

    # If the amount read/written is 0 this may be fixed by
    # waiting and trying again.
    # Partial writes are not accounted for.

    my $n = 0;
    my $read;
    my $num_write_err = 0;
    my $success = 0; # default false

    # Check that the values are not too large to be packed correctly.
    for (my $i = 0; $i < @data; $i++) {
        if ($data[$i] > 255) {
            carp "Data at offset $i is too large to pack, it must be less than or equal to 255.";
            return;
        }
    }

    while ($num_write_err < 3) {

        # 119 -> 'w'
        my $to_write = pack("CCCnnC*", 119, 0, $tbl_idx, $offset, $num_bytes, @data);
        # If the @data values are larger than a char (C) the following error will occur
        #   Character in 'C' format wrapped in pack at <some file> line 33.

        my $num_out = $serial->write($to_write);
        if ($num_out != (7 + $num_bytes)) {
            carp "num_out = $num_out";
            $num_write_err++;
            usleep(100000);  # sleep 100 ms (mili seconds)
            next;
        }

        $success = 1;
        last;
    }

    if (! $success) {
        carp "ERROR: unrecoverable error when using write_w (errors write = $num_write_err)";
        return;
    }

	return 1;  # success
}

# }}}

#
# (src)/ms2extra/is2_sci.s
#   documents commands    
#


=head1 PREREQUISITES

 Module                Version
 ------                -------
 Device::SerialPort    1.04
  
 The version number given has been tested and shown to work.
 Other version may also work.

=head1 REFERENCES

  [1]  RS232 communication with Megasquirt 2-Extra
       http://home.comcast.net/~whaussmann/RS232_MS2E/RS232_MS2_E.htm

  [2]  MegaSquirt Engine Management System
       http://www.msextra.com/

=head1 AUTHOR

    Jeremiah Mahler
    CPAN ID: JERI
    mailto:jmmahler@gmail.com
    http://www.google.com/profiles/jmmahler#about 

=head1 COPYRIGHT

Copyright (c) 2010, Jeremiah Mahler. All Rights Reserved.
This module is free software.  It may be used, redistributed
and/or modified under the same terms as Perl itself.

=head1 SEE ALSO

Device::SerialPort

=cut

# vim:foldmethod=marker

1;
