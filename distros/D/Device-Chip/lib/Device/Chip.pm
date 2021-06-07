#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2015-2020 -- leonerd@leonerd.org.uk

use v5.26;
use Object::Pad 0.19;

package Device::Chip 0.18;
class Device::Chip :repr(HASH);

use Carp;

use Future::AsyncAwait 0.38; # async method

=head1 NAME

C<Device::Chip> - an abstraction of a hardware chip IO driver

=head1 DESCRIPTION

=over 2

B<Note>: this document is currently under heavy development. Details will be
added, changed, and evolved as it progresses. Be warned that currently
anything may be changed from one version to the next.

=back

This package describes an interface that classes can use to implement a driver
to talk to a specific hardware chip or module. An instance implementing this
interface would communicate with the actual hardware device via some instance
of the related interface, L<Device::Chip::Adapter>.

The documentation in this file is aimed primarily at users of C<Device::Chip>
subclasses. For more information on authoring such a module, see instead
L<Device::Chip::Authoring>.

=head2 USING A CHIP DRIVER

To actually use a chip driver to talk to a specific piece of hardware that is
connected to the computer, an adapter must be supplied. This will be an
instance of some class that satisfies the L<Device::Chip::Adapter> interface.
The chip driver will use this adapter instance to access the underlying
hardware port used to electrically connect to the chip and communicate with
it. This is supplied by invoking the L</mount> method. For example:

   my $chip = Device::Chip::MAX7219->new;

   my $adapter = Device::Chip::Adapter::FTDI->new;

   await $chip->mount( $adapter );

=cut

=head1 CONSTRUCTOR

=cut

=head2 new

   $chip = Device::Chip->new

Returns a new instance of a chip driver object.

=cut

=head1 METHODS

The following methods documented in an C<await> expression return L<Future>
instances.

This allows them to easily be used as a simple synchronous method by using the
trailing L<Future/get> call. Alternatively, if the underlying adapter allows a
fully asynchronous mode of operation, they can be combined in the usual ways
for futures to provide more asynchronous use of the device.

=cut

has $_adapter;
method adapter
{
   return $_adapter //
      croak "This chip has not yet been mounted on an adapter";
}

has $_protocol;
method protocol
{
   return $_protocol //
      croak "This chip has not yet been connected to a protocol";
}

=head2 mount

   $chip = await $chip->mount( $adapter, %params );

Supplies the chip driver with the means to actually communicate with the
connected device, via some electrical interface connected to the computer.

The parameters given in C<%params> will vary depending on the specific chip in
question, and should be documented there.

=cut

async method mount ( $adapter, %params )
{
   $_adapter = $adapter;

   my $pname = $self->PROTOCOL;

   $_protocol = await $_adapter->make_protocol( $pname );

   my $code = $self->can( "${pname}_options" ) or
      return $self;

   await $self->protocol->configure(
      $self->$code( %params )
   );

   return $self;
}

sub _parse_options ( $, $str )
{
   return map { m/^([^=]+)=(.*)$/ ? ( $1 => $2 ) : ( $_ => 1 ) }
          split m/,/, $str // "";

}

=head2 mount_from_paramstr

   $chip = await $chip->mount_from_paramstr( $adapter, $paramstr );

A variant of L</mount> that parses its options from the given string. This
string should be a comma-separated list of parameters, where each is given as
a name and value separated by equals sign. If there is no equals sign, the
value is implied as C<1>, as a convenience for parameters that are simple
boolean flags.

=cut

async method mount_from_paramstr ( $adapter, $paramstr )
{
   await $self->mount( $adapter, $self->_parse_options( $paramstr ) );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
