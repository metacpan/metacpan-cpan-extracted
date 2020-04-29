#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2020 -- leonerd@leonerd.org.uk

package Metrics::Any::Adapter;

use 5.010;  # //
use strict;
use warnings;

our $VERSION = '0.03';

sub import
{
   my $pkg = shift;
   my $caller = caller;
   $pkg->import_into( $caller, @_ );
}

my $adaptertype = "Null";
my @adapterargs;

sub import_into
{
   my ( $pkg, $caller, @args ) = @_;

   ( $adaptertype, @adapterargs ) = @args if @args;
}

my $adapter;

sub adapter
{
   shift;

   return $adapter //= do {
      my $class = "Metrics::Any::Adapter::$adaptertype";
      unless( $class->can( 'new' ) ) {
         ( my $file = "$class.pm" ) =~ s{::}{/}g;
         require $file;
      }
      $class->new( @adapterargs );
   };
}

0x55AA;
