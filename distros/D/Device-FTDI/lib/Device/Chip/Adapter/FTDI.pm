#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2015-2016 -- leonerd@leonerd.org.uk

package Device::Chip::Adapter::FTDI;

use strict;
use warnings;
use base qw( Device::Chip::Adapter );

use Device::FTDI qw( PID_FT232H );

=head1 NAME

C<Device::Chip::Adapter::FTDI> - a C<Device::Chip::Adapter> implementation

=head1 DESCRIPTION

This class implements the L<Device::Chip::Adapter> interface for the I<FDTI>
communication devices, allowing an instance of a L<Device::Chip> driver to
communicate with the actual chip hardware by using an I<FDTI> USB-attached
chip as a hardware adapter.

=cut

=head1 CONSTRUCTOR

=cut

=head2 new

    $adapter = Device::Chip::Adapter::FTDI->new( %args )

Returns a new instance of a C<Device::Chip::Adapter::FTDI>. Takes the same
named argmuents as L<Device::FTDI/new>.

This module applies a default product ID of that of the I<FT232H> (value
0x6014); as this is more likely to be the sort of chip used for synchronous
serial protocols like SPI as well as UART connections.

=cut

sub new
{
    my $class = shift;
    my %args = @_;

    $args{product} //= PID_FT232H;

    my $ftdi = Device::FTDI->new( %args );

    return bless { ftdi => $ftdi }, $class;
}

sub new_from_description
{
    my $class = shift;
    my %opts = @_;

    # VID/PID values are usually in hex
    defined $_ and $_ =~ m/^0/ and $_ = oct $_
        for $opts{vendor}, $opts{product};

    return $class->new(
        map { $_ => $opts{$_} } qw( vendor product serial index )
    );
}

sub shutdown { }

sub make_protocol_GPIO
{
    my $self = shift;

    require Device::FTDI::MPSSE;

    my $mpsse = Device::Chip::Adapter::FTDI::_base->new(
        Device::FTDI::MPSSE->new( ftdi => $self->{ftdi} ),
    );

    $self->{protocol} = $mpsse;

    Future->done( $mpsse );
}

sub make_protocol_SPI
{
    my $self = shift;
    my $spi = Device::Chip::Adapter::FTDI::_SPI->new( ftdi => $self->{ftdi} );

    $self->{protocol} = $spi;

    Future->done( $spi );
}

sub make_protocol_I2C
{
    my $self = shift;

    # TODO: allow multiple connection
    my $i2c = Device::Chip::Adapter::FTDI::_I2C->new(
        ftdi => $self->{ftdi},

        clock_rate => 100E3,
    );

    $self->{protocol} = $i2c;

    Future->done( $i2c );
}

package
    Device::Chip::Adapter::FTDI::_base;

use Carp;

use Device::FTDI::MPSSE qw( DBUS CBUS );

sub new
{
    my $class = shift;
    my ( $mpsse ) = @_;

    return bless {
        mpsse => $mpsse,
    }, $class;
}

sub sleep
{
    my $self = shift;
    $self->{mpsse}->sleep( @_ );
}

# Basic FTDI has no control of power
sub power { Future->done }

sub list_gpios
{
    return ( map { "D$_" } 0 .. 7 ),
           ( map { "C$_" } 0 .. 7 );
}

sub write_gpios
{
    my $self = shift;
    my ( $gpios ) = @_;

    my %val;
    my %mask;

    foreach my $gpio ( keys %$gpios ) {
        my ( $bus, $num ) = $gpio =~ m/^([DC])([0-7])$/ or
            croak "Unrecognised GPIO name $gpio";

        my $bit = 1 << $num;

        $val {$bus} |= $gpios->{$gpio} ? $bit : 0;
        $mask{$bus} |= $bit;
    }

    my @f;

    push @f, $self->{mpsse}->write_gpio( DBUS, $val{D}, $mask{D} ) if $mask{D};
    push @f, $self->{mpsse}->write_gpio( CBUS, $val{C}, $mask{C} ) if $mask{C};

    Future->needs_all( @f );
}

sub read_gpios
{
    my $self = shift;
    my ( $gpios ) = @_;

    my %mask = ( D => 0, C => 0 );

    foreach my $gpio ( @$gpios ) {
        my ( $bus, $num ) = $gpio =~ m/^([DC])([0-7])$/ or
            croak "Unrecognised GPIO name $gpio";

        my $bit = 1 << $num;

        $mask{$bus} |= $bit;
    }

    Future->needs_all(
        $mask{D} ? $self->{mpsse}->read_gpio( DBUS, $mask{D} ) : Future->done(0),
        $mask{C} ? $self->{mpsse}->read_gpio( CBUS, $mask{C} ) : Future->done(0),
    )->then( sub {
        my ( $dbus, $cbus ) = @_;

        my %vals;

        foreach my $num ( 0 .. 7 ) {
            my $bit = 1 << $num;

            $vals{"D$num"} = !!( $dbus & $bit ) if $mask{D} & $bit;
            $vals{"C$num"} = !!( $cbus & $bit ) if $mask{C} & $bit;
        }

        Future->done( \%vals );
    });
}

sub tris_gpios
{
    my $self = shift;
    my ( $gpios ) = @_;

    my %mask = ( D => 0, C => 0 );

    foreach my $gpio ( @$gpios ) {
        my ( $bus, $num ) = $gpio =~ m/^([DC])([0-7])$/ or
            croak "Unrecognised GPIO name $gpio";

        my $bit = 1 << $num;

        $mask{$bus} |= $bit;
    }

    Future->needs_all(
        $mask{D} ? $self->{mpsse}->tris_gpio( DBUS, $mask{D} ) : Future->done(0),
        $mask{C} ? $self->{mpsse}->tris_gpio( CBUS, $mask{C} ) : Future->done(0),
    )->then_done();
}

package
    Device::Chip::Adapter::FTDI::_SPI;
use base qw( Device::Chip::Adapter::FTDI::_base );

use Carp;

sub new
{
    my $class = shift;

    require Device::FTDI::SPI;
    return $class->SUPER::new( Device::FTDI::SPI->new( @_ ) );
}

sub configure
{
    my $self = shift;
    my %args = @_;

    my $mode        = delete $args{mode};
    my $max_bitrate = delete $args{max_bitrate};

    croak "Unrecognised configuration options: " . join( ", ", keys %args )
        if %args;

    my $spi = $self->{mpsse};
    $spi->set_spi_mode( $mode )          if defined $mode;
    $spi->set_clock_rate( $max_bitrate ) if defined $max_bitrate;

    Future->done;
}

sub write     { my $self = shift; $self->{mpsse}->write( @_ ) }
sub readwrite { my $self = shift; $self->{mpsse}->readwrite( @_ ) }

sub assert_ss  { my $self = shift; $self->{mpsse}->assert_ss }
sub release_ss { my $self = shift; $self->{mpsse}->release_ss }

sub write_no_ss     { my $self = shift; $self->{mpsse}->write_bytes( @_ ) }
sub readwrite_no_ss { my $self = shift; $self->{mpsse}->readwrite_bytes( @_ ) }

package
    Device::Chip::Adapter::FTDI::_I2C;
use base qw( Device::Chip::Adapter::FTDI::_base );

use Carp;

sub new
{
    my $class = shift;

    require Device::FTDI::I2C;
    return $class->SUPER::new( Device::FTDI::I2C->new( @_ ) );
}

# TODO - addr ought to be a mount option somehow
sub configure
{
    my $self = shift;
    my %args = @_;

    my $addr        = delete $args{addr};
    my $max_bitrate = delete $args{max_bitrate};

    croak "Unrecognised configuration options: " . join( ", ", keys %args )
        if %args;

    $self->{addr} = $addr if defined $addr;
    $self->{mpsse}->set_clock_rate( $max_bitrate ) if defined $max_bitrate;

    Future->done;
}

sub write
{
    my $self = shift;
    $self->{mpsse}->write( $self->{addr}, @_ );
}

sub read
{
    my $self = shift;
    $self->{mpsse}->read( $self->{addr}, @_ );
}

sub write_then_read
{
    my $self = shift;
    $self->{mpsse}->write_then_read( $self->{addr}, @_ );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
