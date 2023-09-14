#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2016-2023 -- leonerd@leonerd.org.uk

use v5.26;
use warnings;
use Object::Pad 0.800;

package Device::Chip::PCF857x 0.06;
class Device::Chip::PCF857x
   :isa(Device::Chip);

use constant PROTOCOL => "I2C";

use Future::AsyncAwait;

method I2C_options
{
   my %opts = @_;

   my $addr = $opts{addr} // 0x20;
   $addr = oct $addr if $addr =~ m/^0/;

   return (
      addr        => $addr,
      max_bitrate => 100E3,
   );
}

async method write ( $v )
{
   await $self->protocol->write( pack( $self->PACKFMT, $v ) );
}

async method read
{
   return unpack $self->PACKFMT, await $self->protocol->read( $self->READLEN );
}

method as_adapter
{
   return Device::Chip::PCF857x::_Adapter->new( chip => $self );
}

class # hide from indexer
   Device::Chip::PCF857x::_Adapter;
# Can't 'extend' yet because D:C:A itself has no sub new
use base qw( Device::Chip::Adapter );

use Carp;

use Future;

field $_chip :param;
field $_mask;
field $_gpiobits;

ADJUST
{
   $_mask = $_chip->DEFMASK;
   $_gpiobits = $_chip->GPIOBITS;
}

async method power ( $on )
{
   await $_chip->protocol->power( $on );
}

async method make_protocol_GPIO { return $self }

method list_gpios
{
   return sort keys %{ $_gpiobits };
}

async method write_gpios ( $gpios )
{
   my $newmask = $_mask;

   foreach my $pin ( keys %$gpios ) {
      my $bit = $_gpiobits->{$pin} or
         croak "Unrecognised GPIO pin name $pin";

      $newmask &= ~$bit;
      $newmask |=  $bit if $gpios->{$pin};
   }

   return if $newmask == $_mask;

   await $_chip->write( $_mask = $newmask );
}

async method read_gpios ( $gpios )
{
   my $mask = await $_chip->read;

   my %ret;
   foreach my $pin ( @$gpios ) {
      my $bit = $_gpiobits->{$pin} or
         croak "Unrecognised GPIO pin name $pin";

      $ret{$pin} = !!( $mask & $bit );
   }

   return \%ret;
}

async method tris_gpios ( $gpios )
{
   await $self->write_gpios( { map { $_ => 1 } @$gpios } );
}

0x55AA;
