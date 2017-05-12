package Device::SaleaeLogic;

use 5.010001;
use strict;
use warnings;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Device::SaleaeLogic ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.02';

require XSLoader;
XSLoader::load('Device::SaleaeLogic', $VERSION);

# Preloaded methods go here.

sub new {
	my $self = shift;
	my $class = ref($self) || $self;
    my %args = @_;
    my $this = bless({%args}, $class);
    if ($args{verbose} or $args{debug}) {
        saleaeinterface_verbose();
    }
    my $obj = saleaeinterface_new($this);
    $this->{obj} = $obj;
    if (exists $args{on_connect} and ref $args{on_connect} eq 'CODE') {
        saleaeinterface_register_on_connect($obj, $args{on_connect});
    }
    if (exists $args{on_disconnect} and ref $args{on_disconnect} eq 'CODE') {
        saleaeinterface_register_on_disconnect($obj, $args{on_disconnect});
    }
    if (exists $args{on_readdata} and ref $args{on_readdata} eq 'CODE') {
        saleaeinterface_register_on_readdata($obj, $args{on_readdata});
    }
    if (exists $args{on_writedata} and ref $args{on_writedata} eq 'CODE') {
        saleaeinterface_register_on_writedata($obj, $args{on_writedata});
    }
    if (exists $args{on_error} and ref $args{on_error} eq 'CODE') {
        saleaeinterface_register_on_error($obj, $args{on_error});
    }
    if ($args{begin}) {
        saleaeinterface_begin_connect($obj);
    }
    return $this;
}

sub begin {
    saleaeinterface_begin_connect($_[0]->{obj});
}

sub DESTROY {
    saleaeinterface_DESTROY($_[0]->{obj}) if $_[0]->{obj};
}

sub is_usb2 {
    return saleaeinterface_is_usb2($_[0]->{obj}, $_[1]);
}

sub is_streaming {
    return saleaeinterface_is_streaming($_[0]->{obj}, $_[1]);
}

sub get_channel_count {
    return saleaeinterface_get_channel_count($_[0]->{obj}, $_[1]);
}

sub get_sample_rate {
    return saleaeinterface_get_sample_rate($_[0]->{obj}, $_[1]);
}

sub set_sample_rate {
    saleaeinterface_set_sample_rate($_[0]->{obj}, $_[1], $_[2]);
}

sub get_supported_sample_rates {
    return saleaeinterface_get_supported_sample_rates($_[0]->{obj}, $_[1]);
}

sub is_logic16 {
    return saleaeinterface_is_logic16($_[0]->{obj}, $_[1]);
}

sub is_logic {
    return saleaeinterface_is_logic($_[0]->{obj}, $_[1]);
}

sub get_device_id {
    return saleaeinterface_get_device_id($_[0]->{obj}, $_[1]);
}

sub read_start {
    saleaeinterface_read_start($_[0]->{obj}, $_[1]);
}

sub write_start {
    saleaeinterface_write_start($_[0]->{obj}, $_[1]);
}

sub stop {
    saleaeinterface_stop($_[0]->{obj}, $_[1]);
}

sub set_use5volts {
    saleaeinterface_set_use5volts($_[0]->{obj}, $_[1], $_[2] ? 1 : 0);
}

sub get_use5volts {
    return saleaeinterface_get_use5volts($_[0]->{obj}, $_[1]);
}

sub get_active_channels {
    return saleaeinterface_get_active_channels($_[0]->{obj}, $_[1]);
}

sub set_active_channels {
    return unless ref $_[2] eq 'ARRAY';
    saleaeinterface_set_active_channels($_[0]->{obj}, $_[1], $_[2]);
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

Device::SaleaeLogic - Perl extension for accessing the Logic or Logic16 devices made by Saleae Logic.

=head1 VERSION

0.02

=head1 SYNOPSIS

  use strict;
  use warnings;
  use Device::SaleaeLogic;

  my $obj = Device::SaleaeLogic->new(
                on_connect => sub {
                    my ($self, $id) = @_;
                    #... do something here #
                },
                on_disconnect => sub {
                    my ($self, $id) = @_;
                    #... do something here #
                },
                on_readdata => sub {
                    my ($self, $id, $data, $len) = @_;
                    if ($len > 0) {
                        use bytes;
                        print "length: ", length($data), "\n";
                        print "length: $len\n";
                    }
                },
                on_error => sub {
                    my ($self, $id) = @_;
                },
                verbose => 1,
            );
  ##... have an event loop here or something ...

=head1 DESCRIPTION

=head2 WHAT CAN THE SDK DO ?

The SDK provided by Saleae Logic registers a bunch of callbacks and then invokes
them with some inputs like data and the device identifiers. Multiple devices can
be handled with the same callback functions. The device SDK creates a separate
thread to manage its callbacks. The SDK supports Logic and Logic16 devices.

We mimic the same functionality where one object created by
C<Device::SaleaeLogic> can handle any number of Saleae Logic devices
simultaneously connected to the computer via USB port. Hence, you will see each
callback having 2 default arguments: the object itself and a device ID.

Due to limitations of XS not handling 64-bit numbers natively on 32-bit systems,
the XS module provides its own 32-bit device ID instead of the pure 64-bit
device ID provided by the Saleae Device SDK. The user can use the method
C<get_device_id($id)> to retrieve the actual Saleae Device SDK ID in a string form.

=head2 THE OBJECT ORIENTED INTERFACE

=over 4

=item C<new(%options)>

You should use this function to create a Device::SaleaeLogic object and
setup the callbacks to be invoked by the Device SDK.
The following are the callbacks and other options that you need or may want to setup:

=over 8

=item C<on_connect>

This callback is invoked by the SDK when a new device gets connected to the
system. It has the signature

    sub on_connect {
        my ($self, $id) = @_;
    }

Here the B<$id> is the ID provided for the current device that has just been
connected. Note that this is different from the actual device id which needs to
be retrieved using the method C<get_device_id($id)>. Each new device connected will
have a different B<$id> value.

This B<$id> value is necessary for invoking any of the other accessor methods
provided that give device information or provide ways of setting device
properties.

=item C<on_disconnect>

This callback is invoked by the SDK when a connected device gets disconnected to the
system. It has the signature

    sub on_disconnect {
        my ($self, $id) = @_;
    }

=item C<on_error>

This callback is invoked by the SDK when a connected device errors out in the
device SDK. This callback is invoked directly by the Saleae Device SDK and
unfortunately, there seems to be no error message provided.

    sub on_error {
        my ($self, $id) = @_;
    }

=item C<on_readdata>

This callback is invoked by the SDK when a connected device starts receiving
data on its active channels. Reading from the device has to be started by the
user using the method C<read_start()> described later in this document.


    sub on_readdata {
        my ($self, $id, $data, $len) = @_;

        ## $data is not an array but a string of bytes
        use bytes;
        if ($len == length($data)) {
            # ... do something ...
        }
    }

=item C<on_writedata>

This callback is B<only> supported on the Logic device and I<not> on the Logic16
device. 

B<NOTE>: This is not supported on the Logic16 device. Since I do not have a
Logic device to test, I have not tested writing to the Logic device. If you
happen to have a Logic device, you can read the SDK docs and figure out how to
test it yourself. Refer to C<write_start()> method for more details.

    sub on_writedata {
        my ($self, $id, $data, $len) = @_;
    }

=item C<verbose>

This option when set to 1 will turn on verbose logging from within the XS
module. This can be useful for debugging or just learning how the XS module
works.

=item C<begin>

This option when set to 1 invokes the C<begin()> method immediately. This may not be necessary
and it is much safer to invoke the C<begin()> method explicitly.

=back

=item C<begin()>

This method starts the Saleae Device SDK thread that will watch for devices and
perform all the work internally. It is better to call this explicitly rather
than using the option in the C<new()> function, since it gives the user more
control on how and when to invoke the SDK thread.

The way to invoke this method is as below:

    $self->begin();

This method should B<not> be invoked from any callback provided to the C<new()>
function. It has to be invoked from outside of the callbacks as shown in
F<share/example.pl> in the distribution.

=item C<DESTROY()>

This method gets automatically called by Perl when destroying the object created
by C<new()>. This will clean up all the memory created in the XS code. If that
doesn't happen, please let me know by giving me a reproducible example.

=item C<get_device_id($id)>

This returns the actual device ID provided by the Saleae Device SDK for the
device with ID C<$id> that is connected. It is unique to the device and is in string form.
This can be useful to manage devices. It returns C<undef> if no ID is available.

The way to invoke this method is as below:

    my $dev_id = $self->get_device_id($id);

This method can be invoked from any callback provided to the C<new()> function
or from outside the callbacks as long as you have a copy of the
Device::SaleaeLogic object created by C<new()> and a copy of the C<$id> as well.

=item C<is_usb2($id)>

This method informs the user if the Saleae Logic device is connected via a USB
2.0 port or not. If true, the value returned is 1 else the value returned is 0.

If the C<$id> is invalid, the value returned will still be 0.

The way to invoke this method is as below:

    if ($self->is_usb2($id)) {
        # ... do something or nothing ...
        # ... checking for USB 2.0 may not be that useful except ...
        # ... when say using an computer with an older USB port ...
        # ... it may determine the speed with which you may be able to sample
        # ... but it is still not very useful
    }

This method can be invoked from any callback provided to the C<new()> function
or from outside the callbacks as long as you have a copy of the
Device::SaleaeLogic object created by C<new()> and a copy of the C<$id> as well.

=item C<is_streaming($id)>

This method informs the user whether the device with ID C<$id> is streaming data
or not. This is useful to know before calling methods like C<read_start()>,
C<write_start()> and C<stop()>. It returns 1 if streaming is going on and 0
otherwise.

The way to invoke this method is as below:

    if ($self->is_streaming($id)) {
        # ... do something ...
        # ... look at the section for read_start() for an example ...
    }

This method can be invoked from any callback provided to the C<new()> function
or from outside the callbacks as long as you have a copy of the
Device::SaleaeLogic object created by C<new()> and a copy of the C<$id> as well.

=item C<get_channel_count($id)>

This method returns the number of channels on the device with ID C<$id>. Most
likely it will be 8 or 16. If it is any number or 0 then the device is either
malfunctioning or just not supported by the SDK yet.

The way to invoke this method is as below:

    my $chcnt = $self->get_channel_count($id);

This method can be invoked from any callback provided to the C<new()> function
or from outside the callbacks as long as you have a copy of the
Device::SaleaeLogic object created by C<new()> and a copy of the C<$id> as well.

=item C<get_sample_rate($id)>

This method returns the current sampling rate of the device with ID C<$id> in
Hz. It should return a valid number. If it returns 0, then the device is
malfunctioning, invalid or not supported.

The way to invoke this method is as below:

    my $rate = $self->get_sample_rate($id);

This method can be invoked from any callback provided to the C<new()> function
or from outside the callbacks as long as you have a copy of the
Device::SaleaeLogic object created by C<new()> and a copy of the C<$id> as well.

=item C<set_sample_rate($id, $rate)>

This method sets the sampling rate to the value C<$rate> in Hz for the device
with ID C<$id>. It does not return anything. To check if it succeeded, call the
C<get_sample_rate($id)> method.

The way to invoke this method is as below:

    my $rate = 500000;    
    $self->set_sample_rate($id, $rate);

This method can be invoked from any callback provided to the C<new()> function
or from outside the callbacks as long as you have a copy of the
Device::SaleaeLogic object created by C<new()> and a copy of the C<$id> as well.

=item C<get_supported_sample_rates($id)>

This method returns an array reference of all the supported sample rates for the
device with ID C<$id>. All the sample rates are in Hz. If the return reference
is C<undef> or empty then the device is malfunctioning, invalid or not supported
yet.

The way to invoke this method is as below:

    my $rates = $self->get_supported_sample_rates($id);
    print "Supported rates in Hz: ", join (", ", @$rates), "\n";

This method can be invoked from any callback provided to the C<new()> function
or from outside the callbacks as long as you have a copy of the
Device::SaleaeLogic object created by C<new()> and a copy of the C<$id> as well.

=item C<is_logic16($id)>

This method returns the value 1 if the device with ID C<$id> is a Logic16
device. A return value of 0 may mean anything except that it is not a Logic16
device, such as it is a Logic device or an unsupported one or an invalid one.

The way to invoke this method is as below:
    
    print "I am a Logic16 device\n" if $self->is_logic16($id);

This method can be invoked from any callback provided to the C<new()> function
or from outside the callbacks as long as you have a copy of the
Device::SaleaeLogic object created by C<new()> and a copy of the C<$id> as well.

=item C<is_logic($id)>

This method returns the value 1 if the device with ID C<$id> is a Logic device.
This will return 0 if the device is a Logic16 device. For that you need to check
with the method C<is_logic16($id)>.

The way to invoke this method is as below:
    
    print "I am a Logic device\n" if $self->is_logic($id);

This method can be invoked from any callback provided to the C<new()> function
or from outside the callbacks as long as you have a copy of the
Device::SaleaeLogic object created by C<new()> and a copy of the C<$id> as well.

=item C<get_use5volts($id)>

This method returns 1 or 0, if the Logic16 device with ID C<$id> is running in 5V mode.
This function is B<only> valid for the Logic16 device. For any other device it
will return 0. By default, the device is running in a lower voltage mode like
1.8V or 2.5V or 3.3V.

The way to invoke this method is as below:

    print "I am in 5V mode\n" if $self->get_use5volts($id);

This method can be invoked from any callback provided to the C<new()> function
or from outside the callbacks as long as you have a copy of the
Device::SaleaeLogic object created by C<new()> and a copy of the C<$id> as well.

=item C<set_use5volts($id, $flag)>

This method sets the 5V mode to be either 1 or 0 for the Logic16 device given by
device ID C<$id>. This method is B<only> valid for the Logic16 device.
For any other device, this method does nothing.

B<NOTE>: You need to read the Logic16 device documentation to know what you're
doing here.

The way to invoke this method is as below:

    $self->set_use5volts($id, 1);

This method can be invoked from any callback provided to the C<new()> function
or from outside the callbacks as long as you have a copy of the
Device::SaleaeLogic object created by C<new()> and a copy of the C<$id> as well.

=item C<get_active_channels($id)>

This method returns an array reference of the indexes of all the active channels
for the Logic16 device with ID C<$id>. For any other device or an invalid C<$id>
it will return C<undef>. It internally checks for whether the device is a
Logic16 device or not. This method is B<only> valid for the Logic16 device.

The way to invoke this method is as below:

    my $channels = $self->get_active_channels($id);
    print "Active Channels: ", join (", ", @$channels), "\n" if $channels;

This method can be invoked from any callback provided to the C<new()> function
or from outside the callbacks as long as you have a copy of the
Device::SaleaeLogic object created by C<new()> and a copy of the C<$id> as well.

=item C<set_active_channels($id, $aref)>

This method takes an array reference C<$aref> with the values being the indexes
of all the active channels that the user wants to set on the Logic16 device
with ID C<$id>. For any other device or an invalid C<$id> it will do nothing.
The user can then verify that they were set by calling the
C<get_active_channels($id)> method. This method is B<only> valid for a Logic16
device.

The way to invoke this method is as below:

    my $channels = [0, 2, 4, 8, 10, 12, 14 ];
    $self->set_active_channels($id, $channels);

This method can be invoked from any callback provided to the C<new()> function
or from outside the callbacks as long as you have a copy of the
Device::SaleaeLogic object created by C<new()> and a copy of the C<$id> as well.

=item C<read_start($id)>

This method starts the data sampling from the Logic or Logic16 device given by
the ID C<$id>. This should be called only once and to check for whether to call
it or not the user should use C<is_streaming($id)> before that.

The way to invoke this method is as below:

    unless ($self->is_streaming($id)) {
        $self->read_start($id);
    }

This method should B<not> be invoked from any callback provided to the C<new()>
function. It has to be invoked from outside of the callbacks as shown in
F<share/example.pl> in the distribution.

=item C<stop($id)>

This method stops the data streaming that is currently happening for the Logic
or Logic16 device given by the device ID C<$id>. This should be called after
checking with C<is_streaming($id)>. 

The way to invoke this method is as below:

    if ($self->is_streaming($id)) {
        $self->stop($id);
    }

This method can be invoked from any callback provided to the C<new()> function
or from outside the callbacks as long as you have a copy of the
Device::SaleaeLogic object created by C<new()> and a copy of the C<$id> as well.

=item C<write_start($id)>

This method starts the data writing to the Logic device given by
the ID C<$id>. This should be called only once.

B<NOTE>: This is not supported on the Logic16 device. Since I do not have a
Logic device to test, I have not tested writing to the Logic device. If you
happen to have a Logic device, you can read the SDK docs and figure out how to
test it yourself.

The way to invoke it is this:

    $self->write_start($id);

This method should B<not> be invoked from any callback provided to the C<new()>
function. It has to be invoked from outside of the callbacks.

=back

=head2 EXPORT

None by default since this is an Object Oriented API.

=head1 SEE ALSO

The github repository is at
L<https://github.com/vikasnkumar/p5-device-saleaelogic>. Feel free to provide
patches.

Find me on IRC: I<#hardware> on L<irc://irc.perl.org> as user name B<vicash>.

=head1 AUTHOR

Vikas Kumar, E<lt>vikas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Vikas Kumar

This library is under the MIT license. Please refer the LICENSE file for more
information provided with the distribution.


=cut
