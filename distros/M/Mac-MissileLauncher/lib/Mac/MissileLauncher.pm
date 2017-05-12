package Mac::MissileLauncher;

use strict;
use warnings;
our $VERSION = '0.01';

use Carp;
use Inline (
    C => "DATA",
    LIBS => '-lusb',
    NAME => 'Mac::MissileLauncher',
#    VERSION => '0.01',
);


my $usb_init;
$usb_init = sub{
    _init();
    $usb_init = sub {};
};

sub new {
    my($class, %opt) = @_;
    $usb_init->();

    my $num = (($opt{num} || '') =~ /^\d+/) ? $opt{num} : 0;
    my $dev = _find_device($num) or croak "Unable to find device.";
    bless { %opt, dev => $dev }, $class;
}

sub do {
    my($self, $cmd) = @_;

    $cmd = ($cmd =~ /^(left|right|up|down|fire)$/) ? $cmd : 'stop';
    _do($self->{dev}, $cmd);
    $self;
}

{
    for my $meth (qw/ up down left right fire stop /) {
        no strict 'refs';
        *{$meth} = sub { shift->do($meth) };
    }
}

1;

__DATA__

__C__

#include <usb.h>

void _init () {
    usb_init();
}

SV *_find_device (int num) {
    int i;
    struct usb_bus *bus = NULL;
    struct usb_device *dev = NULL;

    usb_find_busses();
    usb_find_devices();

    for (bus = usb_get_busses(), i = 0; bus && !dev; bus = bus->next, i++) {
        for (dev = bus->devices; dev; dev = dev->next) {
            /*
            if (dev->descriptor.idVendor == 0x1130 && dev->descriptor.idProduct == 0x0202) {
                if (num == i) break;
            }
            */
            if (dev->descriptor.idVendor == 0x1941 && dev->descriptor.idProduct == 0x8021) {
                if (num == i) break;
            }
        }
    }
    if (!dev) {
        return &PL_sv_undef;
    }
    return newSViv((unsigned long) dev);
}

SV *_do (void *d, char *cmd) {
    struct usb_device *dev = (struct usb_device *) d;
    usb_dev_handle *handle;
    char msg[8];

    handle = usb_open(dev);
    if (handle == NULL) return &PL_sv_undef;
    if (usb_set_configuration(handle, 1) < 0) return &PL_sv_undef;

    memset(msg, 0, 8);
    switch (cmd[0]) {
      case 'u': msg[0] = 0x01; break; 
      case 'd': msg[0] = 0x02; break; 
      case 'l': msg[0] = 0x04; break; 
      case 'r': msg[0] = 0x08; break; 
      case 'f': msg[0] = 0x10; break; 
    };

    if (usb_control_msg(
            handle,
            USB_DT_HID,
            USB_REQ_SET_CONFIGURATION,
            USB_RECIP_ENDPOINT,
            0,
            msg,
            8,
            5000) != 8) return &PL_sv_undef;

    usb_release_interface(handle, 0);
    usb_close(handle);

    return newSViv(1);
}

__END__

=head1 NAME

Mac::MissileLauncher - interface to toy USB missile launchers for Mac

=head1 SYNOPSIS

  use Mac::MissileLauncher;

  my $missile = Mac::MissileLauncher->new(num => 0);
  $missile->up;
  $missile->down;
  $missile->left;
  $missile->right;
  $missile->fire;
  $missile->stop;

  $missile->up->down->left->right->fire;

=head1 DESCRIPTION

Mac::MissileLauncher is basic interface to the toy USB missile launchers for Mac.
It is possible to use it by USB Circus Cannon and USB Missile Launcher (2nd type).

=head1 AUTHOR

Kazuhiro Osawa E<lt>ko@yappo.ne.jpE<gt>

=head1 SEE ALSO

L<Device::USB>, L<Device::USB::MissileLauncher>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
