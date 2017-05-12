#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2016 -- leonerd@leonerd.org.uk

package Devel::MAT::Tool::IO;

use strict;
use warnings;
use base qw( Devel::MAT::Tool );

our $VERSION = '0.25';

use constant CMD => "io";

=head1 NAME

C<Devel::MAT::Tool::IO> - list or find an IO SV

=head1 DESCRIPTION

This C<Devel::MAT> tool operates on IO handle SVs.

=cut

=head1 COMMANDS

=cut

sub run_cmd
{
   my $self = shift;
   @_ or @_ = 'list';
   $self->_dispatch_sub( @_ );
}

=head2 io list

   pmat> io list
   Addr                           ifileno  ofileno
   IO() at 0x1bbf640              -1       -1
   IO() at 0x1bbf508              0        -1
   ...

Prints a list of all the IO handles that have filenumbers.

=cut

sub _by_fileno
{
   my ( $ai, $ao ) = split m{/}, $a;
   my ( $bi, $bo ) = split m{/}, $b;

   return $ai <=> $bi || $ao <=> $bo;
}

sub run_cmd_list
{
   my $self = shift;

   Devel::MAT::Cmd->printf( "%-30s %-8s %-8s\n", "Addr", "ifileno", "ofileno" );

   my %ios;

   foreach my $sv ( $self->{df}->heap ) {
      next unless $sv->type eq "IO";

      my $ifileno = $sv->ifileno // -1;
      my $ofileno = $sv->ofileno // -1;

      $ios{"$ifileno/$ofileno"} = $sv;
   }

   foreach ( sort _by_fileno keys %ios ) {
      my $sv = $ios{$_};

      Devel::MAT::Cmd->printf( "%-30s %-8s %-8s\n", $sv->desc_addr, $sv->ifileno // "-", $sv->ofileno // "-" );
   }
}

=head2 io find

   pmat> io find 2
   Addr                           ifileno  ofileno
   IO() at 0x1bbf598              2        2

Searches for an IO handle that is associated with the given filenumber.

=cut

sub run_cmd_find
{
   my $self = shift;
   my ( $num ) = @_;

   Devel::MAT::Cmd->printf( "%-30s %-8s %-8s\n", "Addr", "ifileno", "ofileno" );

   foreach my $sv ( $self->{df}->heap ) {
      next unless $sv->type eq "IO";

      next unless $sv->ifileno == $num or $sv->ofileno == $num;

      Devel::MAT::Cmd->printf( "%-30s %-8s %-8s\n", $sv->desc_addr, $sv->ifileno // "-", $sv->ofileno // "-" );
   }
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
