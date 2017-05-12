package Linux::USBKeyboard;
BEGIN {
  our $VERSION = 0.04;
}

use warnings;
use strict;
use Carp;

=head1 NAME

Linux::USBKeyboard - access devices pretending to be qwerty keyboards

=head1 SYNOPSIS

Use `lsusb` to discover the vendor id, product id, busnum, and/or devnum.
See also `udevinfo` or /sys/bus/usb/devices/* for more advanced info.

=head1 ABOUT

This module gives you access to usb barcode scanners, magstripe readers,
numpads and other "pretend I'm a keyboard" hardware.

It bypasses the keyboard driver so that your dvorak or international
keymap won't get in the way.  It also allows you to distinguish one
device from another, run as a daemon (not requiring X/console focus),
and other good things.

=head1 CAVEATS

This module assumes that you want the device to use a qwerty keymap.  In the
case of magstripes and barcode scanners, this is almost definitely the
case.  A tenkey pad won't matter.  For some kind of secondary usermode
keyboard (e.g. gaming, etc) maybe you actually want to be able to apply
a keymap?

I'm not sure how to let the main hid driver have the device back.  You
have to unplug it and plug it back in or run `libhid-detach-device`.

Patches welcome.

=head1 SETUP

You'll need a fairly modern Linux, Inline.pm, and libusb.

  cpan Inline
  aptitude install libusb-dev

You should setup udev to give the device `plugdev` group permissions or
whatever (rather than developing perl code as root.)  One way to do this
would be to add the following to /etc/udev/permissions.rules:

  SUBSYSTEM=="usb_device", GROUP="plugdev"

=cut

use Inline (
  C => Config =>
  LIBS => '-lusb',
  NAME    => __PACKAGE__,
  #VERSION => __PACKAGE__->VERSION,
  #FORCE_BUILD => 1,
  #CLEAN_AFTER_BUILD => 0,
);

BEGIN {
my $base = __FILE__; $base =~ s{.pm$}{/};
Inline->import(C => "$base/functions.c");
$ENV{DBG} and warn "ready\n";
}

sub DESTROY {
  my $self = shift;
  $self->_destroy;
}

=head1 Constructor


=head2 new

  my $kb = Linux::USBKeyboard->new($vendor_id, $product_id);

  my $kb = Linux::USBKeyboard->new(busnum => 1, devnum => 2);

  my $kb = Linux::USBKeyboard->new(vendor => $vendor_id, busnum => 1);

etc

You may pass the vendor and product IDs as raw parameters, or you may
pass any combination of vendor, product, busnum, devnum, and/or iface as
named parameters.  At least one parameter other than iface must be
specified.  iface is the interface to claim on the device, and it
defaults to 0.  No other parameters have defaults.

=cut

sub new {
  my $class = shift;
  my $self = {$class->_check_args(@_)};
  bless($self, $class);
  $self->_usb_init();   # set up USB stuff
  return($self);
} # end subroutine new definition
########################################################################

=head2 _check_args

Hex numbers passed as strings must include the leading '0x', otherwise
they are assumed to be integers.

Arguments may also be a hash (vendor => $v, product => $p) or
(busnum => $b, $devnum => $d) or any mixture thereof.

  my ($hash) = $class->_check_args(@_);

=cut

sub _check_args {
  my $class = shift;
  my (@args) = @_;

  my $d = sub {$_[0] =~ m/^\d/};
  my $hexit = sub {
    my ($n) = @_;
    return($n) unless($n =~ m/^0x/i or $n =~ m/\D/);
    $n =~ m/^0x[a-f0-9]+$/i or croak("'$n' is not hex-like");
    return(hex($n));
  };
  if(scalar(@args) == 2 and $d->($args[0]) and $d->($args[1])) {
    # explicit vendor/product pair
    return(
      selector => {
        vendor => $hexit->($args[0]), product => $hexit->($args[1])
      }
    );
  }

  # hash arguments
  (@args % 2) and croak("odd number of elements in argument hash");
  my %sel;
  my %hash = (@args, selector => \%sel);
  for(qw(vendor product busnum devnum)) {
    $sel{$_} = $hexit->(delete($hash{$_})) if($hash{$_});
  }
  %sel or croak("vendor, product, busnum, or devnum required");
  exists $hash{iface} and $sel{iface} = delete($hash{iface});

  return %hash;
} # end subroutine _check_args definition
########################################################################

=head2 open

Get a filehandle to a forked process.

  my $fh = Linux::USBKeyboard->open(@spec);

The @spec has the same format as in new().
The filehandle is an object from a subclass of IO::Handle.  It has the
method $fh->pid if you need the process id.  The subprocess will be
automatically killed by the object's destructor.

I've tested reading with readline($fh) and getc($fh) (both of which will
block.)  See examples/multi.pl for an example of IO::Select non-blocking
multi-device usage.

=cut

sub open :method {
  my $package = shift;
  # TODO I think I want to pass a subref in here which allows you to
  # have your own handling of the codes - e.g. to read F1 and such with
  # readline.

  my $fh = Linux::USBKeyboard::FileHandle->new;
  my $pid = open($fh, '-|');
  unless($pid) {
    undef($fh); # destroy that
    my $kb = Linux::USBKeyboard->new(@_);
    local $| = 1;
    $SIG{HUP} = sub { exit; };
    while(1) {
      my $c = $kb->char;
      print $c if(length($c));
    }
    exit;
  }
  $fh->init(pid => $pid);
  return($fh);
} # end subroutine open definition
########################################################################


=head2 open_keys

Similar to open(), but returns one keypress (plus "bucky bits") per
line, with single-character names where applicable and long names for
all of the function keys, direction keys, enter, space, backspace,
numpad, &c.

  my $fh = Linux::USBKeyboard->open_keys(@spec);

The "bucky bits" ('shift', 'ctrl', 'alt', and 'super') will be appended
after the keyname and joined with spaces.  Both the short name (e.g.
'alt') and a form preceded by 'right_' and/or 'left_' will be present.
Mapping these into a hash allows you to ignore (or not) whether the
shift key was pressed on the right or left of the keyboard.

  chomp($line);
  my ($k, @bits) = split(/ /, $line);
  my %bucky = map({$_ => 1} @bits);

For now, the character keys will simply be shifted as per open()

For key names, see the source code of this module.  The names are common
abbreviations in lowercase except for F1-F12.

=cut

{
my %cmap = reverse(
  escape  => 1,
  map({('F'.$_ => 58+$_)} 1..10),
  F11 => 87,
  F12 => 88,
  sysreq => 99,
  scroll => 70,
  break  => 119,
  backspace => 14,
  tab    => 15,
  capslock => 58,
  insert => 110,
  delete => 111,
  home   => 102,
  end    => 107,
  pgup   => 104,
  pgdn   => 109,
  left   => 105,
  right  => 106,
  up     => 103,
  down   => 108,
  select => 127,

  space  => 57,
  enter  => 28,
  tab    => 15,

  num_lock  => 69,
  num_slash => 98,
  num_star  => 55,
  num_minus => 74,
  num_plus  => 78,
  num_dot   => 83,
  num_7     => 71,
  num_8     => 72,
  num_9     => 73,
  num_4     => 75,
  num_5     => 76,
  num_6     => 77,
  num_1     => 79,
  num_2     => 80,
  num_3     => 81,
  num_0     => 82,
  num_enter => 96,
);
my %smap = (
  left_ctrl   => 0x01,
  right_ctrl  => 0x10,
  left_shift  => 0x02,
  right_shift => 0x20,
  left_alt    => 0x04,
  right_alt   => 0x40,
  left_super  => 0x08,
  right_super => 0x80,
);
sub open_keys {
  my $package = shift;
  my $fh = Linux::USBKeyboard::FileHandle->new;
  my $pid = open($fh, '-|');
  unless($pid) {
    undef($fh); # destroy that
    my $kb = Linux::USBKeyboard->new(@_);

    local $| = 1;
    $SIG{HUP} = sub { exit; };

    my $xmap = $kb->{xmap};

    while(1) {
      my ($c, $s) = $kb->keycode;
      next if($c <= 0);
      my %sbits;
      if($s) {
        %sbits = map({$s & $smap{$_} ? ($_ => 1) : ()} keys %smap);
        foreach my $key (qw(shift ctrl alt super)) {
          $sbits{$key} = 1
            if($sbits{"right_$key"} or $sbits{"left_$key"});
        }
      }
      my $k;
      if($k = $cmap{$c}) { # named keys and the numpad
        # now the shift key doesn't change the output, but might be of
        # importance to the listener
      }
      else {
        $k = code_to_key($sbits{shift}, $c);
        next if($k eq "\0"); # XXX bah
        delete($sbits{shift});
      }

      if($xmap) {
        $k = $xmap->{$k} if(exists($xmap->{$k}));
      }
      print "$k" .
        (%sbits ? join(' ', '', sort(keys %sbits)) : '') .
        "\n";
    }
    exit;
  }
  $fh->init(pid => $pid);
  return($fh);
}} # end subroutine open_keys definition
########################################################################

=head1 Methods

=head2 char

Returns the character (with shift bit applied) for a pressed key.

  print $k->char;

Note that this returns the empty string for any keys which are
non-normal characters (e.g. backspace, esc, F1.)  The 'Enter' key is
returned as "\n".

=cut

*char = *_char;

=head2 keycode

Get the raw keycode.  This allows access to things like numlock, but
also returns keyup events (0).  Returns -1 if there was no event before
the timeout.

Note that this can only detect the press of a single key.  The device
does send extra data if two keys are pressed at the same time (e.g. "a"
and "x"), but at some point the code becomes ambiguous anyway because
keyboards do not contain 105 wires (and every device is different.)

  my ($code, $shiftbits) = $kb->keycode;

=cut

sub keycode {
  my $self = shift;
  my (%args) = @_;
  return($self->_keycode($args{timeout}||1000));
} # end subroutine keycode definition
########################################################################


{
package Linux::USBKeyboard::FileHandle;

use base 'IO::Handle';

my %handles;
sub init {
  my $self = shift;
  $handles{$self} = {@_};
}
sub pid {
  my $self = shift;
  return($handles{$self}{pid});
}
sub DESTROY {
  my $self = shift;
  my $data = delete($handles{$self}) or return;
  kill('HUP', $data->{pid});
}
} # end package


=head1 AUTHOR

Eric Wilhelm @ <ewilhelm at cpan dot org>

http://scratchcomputing.com/

=head1 BUGS

If you found this module on CPAN, please report any bugs or feature
requests through the web interface at L<http://rt.cpan.org>.  I will be
notified, and then you'll automatically be notified of progress on your
bug as I make changes.

If you pulled this development version from my /svn/, please contact me
directly.

=head1 COPYRIGHT

Copyright (C) 2007 Eric L. Wilhelm, All Rights Reserved.

=head1 NO WARRANTY

Absolutely, positively NO WARRANTY, neither express or implied, is
offered with this software.  You use this software at your own risk.  In
case of loss, no person or entity owes you anything whatsoever.  You
have been warned.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# vi:ts=2:sw=2:et:sta
1;
