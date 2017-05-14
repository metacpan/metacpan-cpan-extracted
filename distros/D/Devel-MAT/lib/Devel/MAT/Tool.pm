#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2016 -- leonerd@leonerd.org.uk

package Devel::MAT::Tool;

use strict;
use warnings;

our $VERSION = '0.26';

sub new
{
   my $class = shift;
   my ( $pmat ) = @_;

   return bless {
      pmat => $pmat,
      df   => $pmat->dumpfile,
   }, $class;
}

sub _dispatch_sub
{
   my $self = shift;
   my ( $cmd, @args ) = @_;

   my $meth = (caller 1)[3];

   if( my $code = $self->can( "${meth}_${cmd}" ) ) {
      return $self->$code( @args );
   }
   else {
      die "$self has no $cmd sub-command\n";
   }
}

0x55AA;
