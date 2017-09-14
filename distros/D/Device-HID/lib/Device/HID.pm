use strict;
use warnings;
package Device::HID;

# ABSTRACT: Perl Interface to HIDAPI
our $VERSION = '0.005'; # VERSION

use Carp;
use Device::HID::XS qw(:all);

=pod

=encoding utf8

=head1 NAME

Device::HID - Perl Interface to HIDAPI


=head1 SYNOPSIS

    use Device::HID;
    use Data::Hexdumper;

    my $dev = Device::HID->new(vendor => 0x1337, product => 0x4242) or die "No such device!\n";
    $dev->timeout = 0.1;
    my $buf;
    while (defined (my $in = $dev->read_data($buf, $len)) {
        if ($in == 0) {
            print "Timeout!\n";
            next;
        }

        print Hexdumper($buf), "\n";
    }


=head1 METHODS AND ARGUMENTS

=over 4

=item new()

Opens specified device and returns the corresponding object reference. Returns undef
if an attempt to open the device has failed. Accepts following parameters:
 
=over 4
 
=item B<vendor>
 
Vendor ID.
 
=item B<product>
 
Product ID.
 
=item B<serial>
 
Device serial number. By default undefined.
 
=item B<autodie>
 
if true, methods on this instance will use L<Carp/croak> on failure. Default is 0,
where C<undef> is returned on failure. 
 
=back
 
=cut

sub new {
	my $class = shift;
    my $self = {
        autodie => 0,
    };

    if (@_ == 1) {
        $self = { %$self, path => @_ };
    } else {
        $self = { %$self, @_ };
        croak "vendor and product can not be null" unless defined $self->{vendor} && defined $self->{product};
    }

    _open($self) or return;

	bless $self, $class;
	return $self;
}

sub _open {
    my $self = shift;

    if (defined $self->{path}) {
        $self->{handle} = hid_open_path($self->{path});
    } else {
        $self->{handle} = hid_open($self->{vendor}, $self->{product}, $self->{serial});
    }

    unless (defined $self->{handle}) {
        my $msg = "Failed to hid_open "; # FIXME: use hid_error
        $self->{autodie} and croak $msg or carp $msg;
        return 0;
    }

    return 1;
}

=item read_data
 
    $dev->read_data($buffer, $size)
 
Reads data from the device (up to I<$size> bytes) and stores it in I<$buffer>.
 
Returns number of bytes read or C<0> on timeout. Returns C<undef> on error unless C<autodie> is in effect.
 
=cut
 
sub read_data {
    my $self = shift;
    my ( undef, $size ) = @_;
    my $timeout = defined $self->{timeout} ? int($self->{timeout} * 1000) : -1;
retry:
    my $ret = hid_read_timeout(
    $self->{handle},
    $_[0],
    $size,
    $timeout );

    if ($ret == 0 && $self->{renew}) {
        hid_close($self->{handle});
        _open($self);
        goto retry;
    }
    if ($ret == -1) {
        my $msg = "Error in read_data"; # fixme use hid_error!
        $self->{autodie} and croak $msg or carp $msg;
        return;
    }
    if ($self->{renew}) {
        $self->{renew} = 0;
        $self->{timeout} = undef;
    }
    return $ret;
}

=item timeout
 
    $dev->timeout = 0.1; # seconds (=100 ms)
    printf "Timeout is %d\n", $dev->timeout;
 
Lvalue subroutine that can be used to set and get the timeout in seconds for C<read_data>. Granularity is 1 millisecond.

Default value is C<undef>, which means wait indefinitely.
 
=cut

sub timeout : lvalue {
        my $self = shift;
    return $self->{timeout};
}


=item write_data
 
    $dev->write_data($reportid, $data)
 
Writes data to the device.
 
Returns actual number of bytes written or C<undef> on error unless C<autodie> is in effect.
 
=cut
 
sub write_data {
    my $self = shift;
    my ( undef, $size ) = @_;
    my $ret = hid_write( $self->{handle}, $_[0], length $_[0]);
    if ($ret == -1) {
        my $msg = "Error in write_data"; # fixme use hid_error!
        $self->{autodie} and croak $msg or carp $msg;
    }
    return $ret;
}

=item autodie
 
    $dev->autodie = 1;
 
Lvalue subroutine that can be used to set whether the module L<Carp/croak>s on failure.

Default value is C<0>.
 
=cut

sub autodie : lvalue {
    my $self = shift;
    return $self->{autodie};
}

=item renew_on_timeout
 
    $dev->renew_on_timeout;
 
Closes HIDAPI handle and opens a new one transparently at C<read_data> timeout and retries reading. When C<read_data> returns successfully the first time, C<renew_on_timeout> is reset and timeout is set to C<undef>, but can be manually adjusted.

For reasons unknown to me, Valve's Steam controller needs a couple of C<hid_open> calls before C<hid_read> manages to read data. None of the prior C<hid_open> calls fail, they just block indefinitely. For devices that ought to report periodically what they're up to, set the C<timeout> in C<new> to a sensible value and call C<renew_on_timeout> on the handle. The following C<hid_read> will then be retried till data can be read.

=cut

sub renew_on_timeout  {
    my $self = shift;
    $self->{renew} = 1;
    defined $self->{timeout} or croak "Thou shalt not call renew_on_timeout when timeout is not in sight.";

    return $self;
}

sub DESTROY {
    my $self = shift;
    hid_close($self->{handle}) if defined $self->{handle};
}

# Usually, no need to call this one directly
sub init {
    hid_init() == 0 or croak "Failed to initialize HIDAPI";
}

sub exit {
    hid_exit()
}

1;
__END__

=back

=head1 TODO

Use C<hid_error> in croak/carp. Wrap the other information retrieval function. Till then, you can use the XSUBs in L<Device::HID::XS>.

=head1 GIT REPOSITORY

L<http://github.com/athreef/Device-HID>

=head1 SEE ALSO

L<Device::HID::XS>

L<Alien::HIDAPI>

The API of this module was modelled after L<Device::FTDI> by Pavel Shaydo.

=head1 AUTHOR

Ahmad Fatoum C<< <athreef@cpan.org> >>, L<http://a3f.at>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 Ahmad Fatoum

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

