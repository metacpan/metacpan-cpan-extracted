#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2022 -- leonerd@leonerd.org.uk

package Devel::MAT::Tool::ListDanglingPtrs 0.53;

use v5.14;
use warnings;
use base qw( Devel::MAT::Tool );

use List::Util qw( pairs );

use constant CMD => "list-dangling-ptrs";
use constant CMD_DESC => "Show pointers in SVs that don't lead anywhere";

=head1 NAME

C<Devel::MAT::Tool::ListDanglingPtrs> - display a list of SV pointer fields that do not point at known SVs

=head1 DESCRIPTION

This C<Devel::MAT> tool displays a list of fields from known SVs containing
non-NULL addresses, but which do not point to other known SVs. These are so-called
"dangling pointers".

=cut

=head1 COMMANDS

=head2 list-dangling-ptrs

   pmat> list-dangling-ptrs
   CODE(proto) at 0x55b9d83ae3d8 has no constval SV at addr 0x55b9d83963f0
   ...

Prints a list of fields in SVs which do not point at other valid SVs.

=cut

my %methodcache;
sub methods_of
{
   my ( $pkg ) = @_;
   my $methods = $methodcache{$pkg} //= do {
      no strict 'refs';
      my @syms = keys %{"${pkg}::"};
      [
         ( grep { *{"${pkg}::$_"}{CODE} } @syms ),
         map { methods_of( $_ ) } @{"${pkg}::ISA"}
      ]
   };
   return @$methods;
}

sub run
{
   my $self = shift;

   my $df = $self->df;

   my %roots_at;
   foreach ( pairs $df->roots ) {
      my ( $name, $sv ) = @$_;
      $sv and
         $roots_at{ $sv->addr } = $name;
   }

   my $test_ptr = sub {
      my $self = shift;
      my ( $sv, $name, $addr ) = @_;

      $addr or return;
      $roots_at{$addr} and return;
      $df->{heap}{$addr} and return;

      Devel::MAT::Cmd->printf( "%s has no %s SV at addr 0x%x\n",
         Devel::MAT::Cmd->format_sv( $sv ),
         $name,
         $addr,
      );
   };

   foreach my $sv ( $self->df->heap ) {
      # Quite a bit of cheating here. We'll presume that any _at method gives
      # a number that should be a raw SV pointer address
      foreach my $meth ( methods_of ref $sv ) {
         if( $meth eq "field" ) {
            # Struct fields might or mightnot be SV pointers. We'll have to ask them
            my $fields = $sv->structtype->fields;
            foreach my $idx ( 0 .. $#$fields ) {
               my $field = $fields->[$idx];
               if( $field->type == 0 ) {
                  $self->$test_ptr( $sv, "field <${\$field->name}>", $sv->$meth( $idx ) );
               }
            }
         }

         next unless $meth =~ m/^([^_].*)_at$/;
         my $outref = $1;

         if( $outref eq "elem" ) {
            $self->$test_ptr( $sv, "$outref [$_]", $sv->$meth( $_ ) ) for 0 .. $sv->elems-1;
         }
         elsif( $outref eq "value" ) {
            $self->$test_ptr( $sv, "$outref {$_}", $sv->$meth( $_ ) ) for $sv->keys;
         }
         else {
            $self->$test_ptr( $sv, $outref, $sv->$meth );
         }
      }
   }
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
