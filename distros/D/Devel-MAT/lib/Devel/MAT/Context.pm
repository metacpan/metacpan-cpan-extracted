#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2013-2026 -- leonerd@leonerd.org.uk

package Devel::MAT::Context 0.55;

use v5.20;
use warnings;

use feature qw( postderef signatures );
no warnings qw( experimental::postderef experimental::signatures );

use Carp;
use Scalar::Util qw( weaken );

=head1 NAME

C<Devel::MAT::Context> - represent a single call context state

=head1 DESCRIPTION

Objects in this class represent a single level of state from the call context.
These contexts represent function calls between perl functions.

=cut

my %types;
sub register_type ( $pkg, $id )
{
   $types{$id} = $pkg;
   # generate the ->type constant method
   ( my $typename = $pkg ) =~ s/^Devel::MAT::Context:://;
   no strict 'refs';
   *{"${pkg}::type"} = sub (@) { $typename };
}

sub new ( $class, $type, $df, $bytes, $, $strs )
{
   $types{$type} or croak "Cannot load unknown CTX type $type";

   my $self = bless {}, $types{$type};
   weaken( $self->{df} = $df );

   ( $self->{gimme}, $self->{line} ) = unpack "C $df->{uint_fmt}", $bytes;
   ( $self->{file} ) = @$strs;

   return $self;
}

sub load_v0_1 ( $class, $type, $df )
{
   $types{$type} or croak "Cannot load unknown CTX type $type";

   my $self = bless {}, $types{$type};
   weaken( $self->{df} = $df );

   # Standard fields all Contexts have
   $self->{gimme} = $df->_read_u8;
   $self->{file}  = $df->_read_str;
   $self->{line}  = $df->_read_uint;

   $self->_load_v0_1( $df );

   return $self;
}

=head1 COMMON METHODS

=for highlighter language=perl

=cut

=head2 gimme

   $gimme = $ctx->gimme;

Returns the gimme value of the call context.

=cut

my @GIMMES = ( undef, qw( void scalar array ) );
sub gimme ( $self )
{
   return $GIMMES[ $self->{gimme} ];
}

=head2 file

=head2 line

=head2 location

   $file = $ctx->file;

   $line = $ctx->line;

   $location = $ctx->location;

Returns the file, line or location as (C<FILE line LINE>).

=cut

sub file ( $self ) { return $self->{file} }
sub line ( $self ) { return $self->{line} }

sub location ( $self )
{
   return "$self->{file} line $self->{line}";
}

package Devel::MAT::Context::SUB 0.55;
use base qw( Devel::MAT::Context );
__PACKAGE__->register_type( 1 );

=head1 Devel::MAT::Context::SUB

Represents a context which is a subroutine call.

=cut

sub load ( $self, $bytes, $ptrs, $ )
{
   my $df = $self->{df};

   ( $self->{olddepth} ) = unpack "$df->{u32_fmt}", $bytes;

   ( $self->{cv_at}, $self->{args_at} ) = @$ptrs;

   undef $self->{args_at} if $df->perlversion ge "5.23.8";
}

sub _load_v0_1 ( $self, $df )
{
   $self->{olddepth} = -1;

   $self->{cv_at}   = $df->_read_ptr;
   $self->{args_at} = $df->_read_ptr;

   undef $self->{args_at} if $df->perlversion ge "5.23.8";
}

=head2 cv

   $cv = $ctx->cv;

Returns the CV which this call is to.

=head2 args

   $args = $ctx->args;

Returns the arguments AV which represents the C<@_> argument array.

=head2 olddepth

   $olddepth = $ctx->olddepth;

Returns the old depth of the context (that is, the depth the CV would be at
after this context returns).

=head2 depth

   $depth = $ctx->depth;

Returns the actual depth of the context. This is inferred at load time by
considering the C<olddepth> of the next inner-nested call to the same CV, or
from the actual C<depth> of the CV is no other call exists.

=cut

sub cv ( $self )  { return $self->{df}->sv_at( $self->{cv_at} ) }

sub args ( $self )
{
   # Perl 5.23.8 removed blk_sub.argarray so we have to go the long way round
   $self->{args_at} //= do {
      my $cv = $self->cv;
      my $args = $cv->pad( $self->depth )->elem( 0 );
      $args->addr;
   };

   return $self->{df}->sv_at( $self->{args_at} );
}

sub olddepth ( $self ) { return $self->{olddepth} }

sub _set_depth ( $self, $depth ) { $self->{depth} = $depth }
sub depth      ( $self )         { return $self->{depth} }

package Devel::MAT::Context::TRY 0.55;
use base qw( Devel::MAT::Context );
__PACKAGE__->register_type( 2 );

=head1 Devel::MAT::Context::TRY

Represents a context which is a block C<eval {}> call.

=cut

sub load ( $self, $, $, $ ) {}

sub _load_v0_1 ( $self, $ ) {}

package Devel::MAT::Context::EVAL 0.55;
use base qw( Devel::MAT::Context );
__PACKAGE__->register_type( 3 );

=head1 Devel::MAT::Context::EVAL

Represents a context which is a string C<eval EXPR> call.

=cut

sub load ( $self, $, $ptrs, $ )
{
   ( $self->{code_at} ) = @$ptrs;
}

sub _load_v0_1 ( $self, $df )
{
   $self->{code_at} = $df->_read_ptr;
}

=head2 code

   $sv = $ctx->code;

Returns the SV containing the text string being evaluated.

=cut

sub code ( $self ) { return $self->{df}->sv_at( $self->{code_at} ) }

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
