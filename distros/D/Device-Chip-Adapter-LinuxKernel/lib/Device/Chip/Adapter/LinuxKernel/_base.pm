package
   Device::Chip::Adapter::LinuxKernel::_base;

use strict;
use warnings;
use Carp qw/croak/;

our $VERSION = '0.00008';

use Carp;

sub new {
   my $class = shift;

   bless {@_ }, $class;
}

# Most modes have no GPIO on this system
sub list_gpios { return qw( ) }

sub write_gpios {
   my $self = shift;
   my ( $gpios ) = @_;

   foreach my $pin ( keys %$gpios ) {
         croak "Unrecognised GPIO pin name $pin";
   }
}

sub read_gpios {
   my $self = shift;
   my ( $gpios ) = @_;

   my @f;
   foreach my $pin ( @$gpios ) {
     croak "Unrecognised GPIO pin name $pin";
   }
}

# there's no more efficient way to tris_gpios than just read and ignore the result
sub tris_gpios
{
   my $self = shift;
   $self->read_gpios->then_done();
}
0x55AA;
