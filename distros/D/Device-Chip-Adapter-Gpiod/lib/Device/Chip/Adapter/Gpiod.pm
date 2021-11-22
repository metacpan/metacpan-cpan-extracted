use strict;
use warnings;
package Device::Chip::Adapter::Gpiod;
use base qw(Device::Chip::Adapter);
use Carp;

# ABSTRACT: Device::Chip::Adapter implementation for Linux GPIO character devices
our $VERSION = 'v0.1.0';

require XSLoader;
XSLoader::load();

=head1 NAME

Device::Chip::Adapter::Gpiod - Device::Chip::Adapter implementation for Linux GPIO character devices

=head1 DESCRIPTION

This module allows L<Device::Chip> to use Linux GPIO character devices through the libgpiod library.

=head1 CONSTRUCTOR

=head2 new

  my $adapter = Device::Chip::Adapter::Gpiod->new(device => "gpiochip0");

Returns a new C<Device::Chip::Adapter::Gpiod> instance. The
C<device> argument indicates the GPIO chip to use. It is passed to
C<gpiod_chip_open_lookup()>, which takes either a device node name,
full path, or chip number. For example, it is possible to use either
C<"gpiochip2">, C<"/dev/gpiochip2">, or C<2> to open the same device.

=cut

sub new {
    my $class = shift;
    my %args = @_;

    die "No device specified" unless defined $args{device};

    my $gpiod_chip = gpiod_open($args{device});

    if ($gpiod_chip)
    {
        return bless { gpiod_chip => $gpiod_chip }, $class;
    } else
    {
        return undef;
    }
}

sub DESTROY {
    my $self = shift;

    $self->shutdown;
}

=head1 PROTOCOLS

Only the C<GPIO> protocol is supported:

  my $protocol = $adapter->make_protocol('GPIO');

=cut

sub make_protocol {
    my ($self, $pname) = @_;

    if ($pname eq 'GPIO')
    {
        Future->done($self);
    } else
    {
        croak "Protocol $pname not supported";
    }
}

sub shutdown {
    my $self = shift;

    if(defined $self->{gpiod_chip})
    {
        gpiod_close($self->{gpiod_chip});
        $self->{gpiod_chip} = undef;
    }
}

sub configure {
    my $self = shift;
    my %args = @_;

}

sub list_gpios {
    my $self = shift;

    if (!defined $self->{gpiod_chip})
    {
        return undef;
    }

    my $num_lines = gpiod_num_lines($self->{gpiod_chip});
    return map {"line$_"} (0..$num_lines-1);
}

sub read_gpios {
    my $self = shift;
    my $lines = shift;

    if (!defined $self->{gpiod_chip})
    {
        return Future->done(undef);
    }

    my @lines = map {/line(\d+)/ && $1} @$lines;
    my @values = gpiod_read_lines($self->{gpiod_chip}, @lines);

    if (@values == @lines)
    {
        my %return;
        for (my $i=0; $i<=$#lines; $i++)
        {
            $return{$lines->[$i]} = $values[$i];
        }

        Future->done(\%return);
    } else
    {
        Future->done(undef);
    }
}

sub write_gpios {
    my $self = shift;
    my $lines = shift;

    if (!defined $self->{gpiod_chip})
    {
        return Future->done;
    }

    my @lines_values;
    for my $line(sort {$a<=>$b} map{/line(\d+)/ && $1} keys %$lines)
    {
        push @lines_values, $line, $lines->{"line$line"};
    }
    gpiod_write_lines($self->{gpiod_chip}, @lines_values);

    Future->done;
}

=head1 BUGS AND LIMITATIONS

The C<meta_gpios> method is not yet supported.

The C<tris_gpios> method is not yet supported.

Libgpiod supports passing a C<consumer> string when GPIO lines are
opened that can identify the application using them. This is currently
always set to C<"Device::Chip">.

=head1 AUTHOR

Stephen Cavilia E<lt>sac@atomicradi.usE<gt>

=head1 COPYRIGHT

Copyright 2021 Stephen Cavilia

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.


=cut

1;
