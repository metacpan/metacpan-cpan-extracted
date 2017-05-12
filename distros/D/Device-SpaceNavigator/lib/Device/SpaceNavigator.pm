package Device::SpaceNavigator;
use strict;
use Carp;
use IO::Select;

our $VERSION = '0.02';
our $AUTOLOAD;

sub new {
    my ($class, $device) = @_;

    my $self = {
        device => "/dev/input/by-id/usb-3Dconnexion_SpaceNavigator-event-if00",
        events => ['x', 'y', 'z', 'pitch', 'roll', 'yaw'],
        buttons => ['left_button', 'right_button'],
        connected => 0,
    };

    foreach (@{$self->{'events'}}, @{$self->{'buttons'}}) {
        $self->{$_} = 0;
    }

    
    bless $self, $class;
}

sub open {
    my ($self, $device) = @_;

    if ($device) {
        $self->{'device'} = $device;
    }

    open($self->{'_fh'}, $self->{'device'}) || croak("$!");
    binmode $self->{'_fh'};

    $self->{'_select'} = IO::Select->new($self->{'_fh'});
}

sub close {
    my ($self) = @_;

    if ($self->{'_fh'}) {
        CORE::close $self->{'_fh'} || croak("$!");
    }
}

sub update {
    my ($self, $wait) = @_;
    my $str;

    if (!$self->{'_fh'}) {
        $self->open();
    }

    $self->{'_select'}->can_read( defined($wait) ? $wait : 1 ) || return;
    if(read($self->{'_fh'}, $str, 8) != 8) {
        CORE::close $self->{'_fh'};
        return 1;
    }

    my @s = unpack("C*", $str);

    # Handle button
    if ($s[0] == 1 && $s[1] == 0) {
        if ($self->{'buttons'}->[$s[2]]) {
            $self->{$self->{'buttons'}->[$s[2]]} = $s[4];
        }
    }

    # Handle move
    if ($s[0] == 2 && $s[1] == 0) {
        my $value = unpack("s",chr($s[4]).chr($s[5]));
        if ($self->{'events'}->[$s[2]]) {
            $self->{$self->{'events'}->[$s[2]]} = $value;
        } 
    }

    return 1;
}

sub AUTOLOAD {
    my $self = shift;
    my $type = ref($self)
            or croak "$self is not an object";

    my $name = $AUTOLOAD;
    $name =~ s/.*://;   # strip fully-qualified portion

    return if $AUTOLOAD =~ /::DESTROY$/;

    unless (exists $self->{$name} ) {
        croak "Can't access `$name' field in class $type";
    }

    return $self->{$name};
}   

1;

__END__

=encoding utf-8

=head1 NAME

Device::SpaceNavigator - Read data from 3Dconnexion SpaceNavigator

=head1 SYNOPSIS

  use Device::SpaceNavigator;

  my $nav = Device::SpaceNavigator->new();

  while ($nav->update()) {
      printf "Pitch:%i / Roll:%i / Yaw:%i X:%i / Y:%i / Z:%i Left button:%s Right button:%s\n",
          $nav->pitch(), $nav->roll(), $nav->yaw(),
          $nav->x(), $nav->y(), $nav->z(),
          $nav->left_button ? 'Pressed' : 'Released',
          $nav->right_button ? 'Pressed' : 'Released';

  }

=head1 DESCRIPTION

This module gives you a interface to read values from a connected 3Dconnexion SpaceNavigator. This awsome device
has 6 axes; x, y, z, pitch, roll and yaw. In addition, it has two buttons.

=head1 METHODS


=head2 Device::SpaceNavigator-E<gt>new()

Creates a new object for reading events from the device. Takes no arguments. Returns a new object.

=head2 $nav-E<gt>open( [ $device ] )

Opens a new socket to the device. 

C<$device> The path to the device. Default: /dev/input/by-id/usb-3Dconnexion_SpaceNavigator-event-if00

=head2 $nav-E<gt>close()

Closes the socket.

=head2 $nav-E<gt>update( [ $timeout ] )

Reads and parse event from device. C<$nav-E<gt>update()> will call open if the socket for some reason is closed.

C<$timeout> Number of secounds C<$nav-E<gt>update()> should wait for a event from the device before returning.


=head2 $nav-E<gt>x()

Returns the value for the X axe. (3Dconnexion calls this for "Pan left/right")

=head2 $nav-E<gt>y()

Returns the value for the Y axe (Zoom).

=head2 $nav-E<gt>z()

Returns the value for the Z axe (Pan up/down).

=head2 $nav-E<gt>pitch()

Returns the value for the pitch (Tilt).

=head2 $nav-E<gt>roll()

Returns the value for the roll.

=head2 $nav-E<gt>yaw()

Returns the value for yaw (spin).

=head2 $nav-E<gt>left_button()

Returns the state of the left button. 

=head2 $nav-E<gt>right_button()

Returns the state of the right button. 

=head1 AUTHOR

Kay Bærulfsen, E<lt>kaysb@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

'L<SpaceNavigator|http://www.3dconnexion.com/products/spacenavigator.html>' is a trademark of 3Dconnexion.

Copyright (C) 2010 by Kay Bærulfsen, E<lt>kaysb@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
