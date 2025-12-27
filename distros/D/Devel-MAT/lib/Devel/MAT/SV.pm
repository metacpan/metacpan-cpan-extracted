#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2013-2024 -- leonerd@leonerd.org.uk

package Devel::MAT::SV 0.54;

use v5.14;
use warnings;

use Carp;
use Scalar::Util qw( weaken );

use Syntax::Keyword::Match;

# Load XS code
require Devel::MAT;

use constant immortal => 0;

use List::Util qw( first );

use Struct::Dumb 0.07 qw( readonly_struct );
readonly_struct Reference => [qw( name strength sv )];
readonly_struct Magic     => [qw( type obj ptr vtbl )];

=head1 NAME

C<Devel::MAT::SV> - represent a single SV from a heap dump

=head1 DESCRIPTION

Objects in this class represent individual SV variables found in the arena
during a heap dump. Actual types of SV are represented by subclasses, which
are documented below.

=cut

my $CONSTANTS;
BEGIN {
   $CONSTANTS = {
      STRENGTH_STRONG   => (1 << 0),
      STRENGTH_WEAK     => (1 << 1),
      STRENGTH_INDIRECT => (1 << 2),
      STRENGTH_INFERRED => (1 << 3),
   };
   $CONSTANTS->{STRENGTH_DIRECT} = $CONSTANTS->{STRENGTH_STRONG}|$CONSTANTS->{STRENGTH_WEAK};
   $CONSTANTS->{STRENGTH_ALL}    = $CONSTANTS->{STRENGTH_STRONG}|$CONSTANTS->{STRENGTH_WEAK}|$CONSTANTS->{STRENGTH_INDIRECT}|$CONSTANTS->{STRENGTH_INFERRED};
}
use constant $CONSTANTS;

my %types;
sub register_type
{
   $types{$_[1]} = $_[0];
   # generate the ->type constant method
   ( my $typename = $_[0] ) =~ s/^Devel::MAT::SV:://;
   no strict 'refs';
   *{"$_[0]::type"} = sub () { $typename } unless defined *{"$_[0]::type"}{CODE};
}

sub new
{
   shift;
   my ( $type, $df, $header, $ptrs, $strs ) = @_;

   my $class = $types{$type} or croak "Cannot load unknown SV type $type";

   my $self = bless {}, $class;

   $self->_set_core_fields(
      $type, $df,
      ( unpack "$df->{ptr_fmt} $df->{u32_fmt} $df->{uint_fmt}", $header ),
      $ptrs->[0],
   );

   return $self;
}

=head1 COMMON METHODS

=cut

=head2 type

   $type = $sv->type;

Returns the major type of the SV. This is the class name minus the
C<Devel::MAT::SV::> prefix.

=cut

=head2 basetype

   $type = $sv->basetype;

Returns the inner perl API type of the SV. This is one of

   SV AV HV CV GV LV PVIO PVFM REGEXP INVLIST OBJ

=head2 desc

   $desc = $sv->desc;

Returns a string describing the type of the SV and giving a short detail of
its contents. The exact details depends on the SV type.

=cut

=head2 desc_addr

   $desc = $sv->desc_addr;

Returns a string describing the SV as with C<desc> and giving its address in
hex. A useful way to uniquely identify the SV when printing.

=cut

sub desc_addr
{
   my $self = shift;
   return sprintf "%s at %#x", $self->desc, $self->addr;
}

=head2 addr

   $addr = $sv->addr;

Returns the address of the SV

=cut

# XS accessor

=head2 refcnt

   $count = $sv->refcnt;;

Returns the C<SvREFCNT> reference count of the SV

=head2 refcount_adjusted

   $count = $sv->refcount_adjusted;

Returns the reference count of the SV, adjusted to take account of the fact
that the C<SvREFCNT> value of the backrefs list of a hash or weakly-referenced
object is artificially high.

=cut

# XS accessor

sub refcount_adjusted { shift->refcnt }

=head2 blessed

   $stash = $sv->blessed;

If the SV represents a blessed object, returns the stash SV. Otherwise returns
C<undef>.

=cut

sub blessed
{
   my $self = shift;
   return $self->df->sv_at( $self->blessed_at );
}

=head2 symname

   $name = $sv->symname;

Called on an SV which is a member of the symbol table, this method returns the
perl representation of the full symbol name, including sigil. Otherwise,
returns C<undef>.

A leading C<main::> prefix is removed for symbols in packages other than
C<main>.

=cut

my $mksymname = sub {
   my ( $sigil, $glob ) = @_;

   my $stashname = $glob->stashname;
   $stashname =~ s/^main::// if $stashname =~ m/^main::.+::/;
   return $sigil . $stashname;
};

sub symname {}

=head2 size

   $size = $sv->size;

Returns the (approximate) size in bytes of the SV

=cut

# XS accessor

=head2 magic

   @magics = $sv->magic;

Returns a list of magic applied to the SV; each giving the type and target SVs
as struct fields:

   $type = $magic->type;
   $sv = $magic->obj;
   $sv = $magic->ptr;
   $ptr = $magic->vtbl;

=cut

sub magic
{
   my $self = shift;
   return unless my $magic = $self->{magic};

   my $df = $self->df;
   return map {
      my ( $type, undef, $obj_at, $ptr_at, $vtbl_ptr ) = @$_;
      Magic( $type, $df->sv_at( $obj_at ), $df->sv_at( $ptr_at ), $vtbl_ptr );
   } @$magic;
}

=head2 magic_svs

   @svs = $sv->magic_svs;

A more efficient way to retrieve just the SVs associated with the applied
magic.

=cut

sub magic_svs
{
   my $self = shift;
   return unless my $magic = $self->{magic};

   my $df = $self->df;
   return map {
      my ( undef, undef, $obj_at, $ptr_at ) = @$_;
      ( $obj_at ? ( $df->sv_at( $obj_at ) ) : () ),
      ( $ptr_at ? ( $df->sv_at( $ptr_at ) ) : () )
   } @$magic;
}

=head2 backrefs

   $av_or_rv = $sv->backrefs;

Returns backrefs SV, which may be an AV containing the back references, or
if there is only one, the REF SV itself referring to this.

=cut

sub backrefs
{
   my $self = shift;

   return undef unless my $magic = $self->{magic};

   foreach my $mg ( @$magic ) {
      my ( $type, undef, $obj_at ) = @$mg;
      # backrefs list uses "<" magic type
      return $self->df->sv_at( $obj_at ) if $type eq "<";
   }

   return undef;
}

=head2 rootname

   $rootname = $sv->rootname;

If the SV is a well-known root, this method returns its name. Otherwise
returns C<undef>.

=cut

sub rootname
{
   my $self = shift;
   return $self->{rootname};
}

# internal
sub more_magic
{
   my $self = shift;
   my ( $type, $flags, $obj_at, $ptr_at, $vtbl_ptr ) = @_;

   push @{ $self->{magic} }, [ $type => $flags, $obj_at, $ptr_at, $vtbl_ptr ];
}

sub _more_annotations
{
   my $self = shift;
   my ( $val_at, $name ) = @_;

   push @{ $self->{annotations} }, [ $val_at, $name ];
}

# DEBUG_LEAKING_SCALARS
sub _debugdata
{
   my $self = shift;
   my ( $serial, $line, $file ) = @_;
   $self->{debugdata} = [ $serial, $line, $file ];
}

sub debug_serial
{
   my $self = shift;
   return $self->{debugdata} && $self->{debugdata}[0];
}

sub debug_line
{
   my $self = shift;
   return $self->{debugdata} && $self->{debugdata}[1];
}

sub debug_file
{
   my $self = shift;
   return $self->{debugdata} && $self->{debugdata}[2];
}

=head2 outrefs

   @refs = $sv->outrefs;

Returns a list of Reference objects for each of the SVs that this one refers
to, either directly by strong or weak reference, indirectly via RV, or
inferred by C<Devel::MAT> itself.

Each object is a structure of three fields:

=over 4

=item name => STRING

A human-readable string for identification purposes.

=item strength => "strong"|"weak"|"indirect"|"inferred"

Identifies what kind of reference it is. C<strong> references contribute to
the C<refcount> of the referrant, others do not. C<strong> and C<weak>
references are SV addresses found directly within the referring SV structure;
C<indirect> and C<inferred> references are extra return values added here for
convenience by examining the surrounding structure.

=item sv => SV

The referrant SV itself.

=back

=cut

sub _outrefs_matching
{
   my $self = shift;
   my ( $match, $no_desc ) = @_;

   # In scalar context we're just counting so we might as well count just SVs
   $no_desc ||= !wantarray;

   my @outrefs = $self->_outrefs( $match, $no_desc );

   if( $match & STRENGTH_WEAK and my $blessed = $self->blessed ) {
      push @outrefs, $no_desc ? ( weak => $blessed ) :
         Reference( "the bless package", weak => $blessed );
   }

   foreach my $mg ( @{ $self->{magic} || [] } ) {
      my ( $type, $flags, $obj_at, $ptr_at ) = @$mg;

      if( my $obj = $self->df->sv_at( $obj_at ) ) {
         my $is_strong = ( $flags & 0x01 );
         if( $match & ( $is_strong ? STRENGTH_STRONG : STRENGTH_WEAK ) ) {
            my $strength = $is_strong ? "strong" : "weak";
            push @outrefs, $no_desc ? ( $strength => $obj ) :
               Reference( "'$type' magic object", $strength => $obj );
         }
      }

      if( $match & STRENGTH_STRONG and my $ptr = $self->df->sv_at( $ptr_at ) ) {
         push @outrefs, $no_desc ? ( strong => $ptr ) :
            Reference( "'$type' magic pointer", strong => $ptr );
      }
   }

   foreach my $ann ( @{ $self->{annotations} || [] } ) {
      my ( $val_at, $name ) = @$ann;
      my $val = $self->df->sv_at( $val_at ) or next;

      push @outrefs, $no_desc ? ( strong => $val ) :
         Reference( $name, strong => $val );
   }

   return @outrefs / 2 if !wantarray;
   return @outrefs;
}

sub outrefs { $_[0]->_outrefs_matching( STRENGTH_ALL, $_[1] ) }

=head2 outrefs_strong

   @refs = $sv->outrefs_strong;

Returns the subset of C<outrefs> that are direct strong references.

=head2 outrefs_weak

   @refs = $sv->outrefs_weak;

Returns the subset of C<outrefs> that are direct weak references.

=head2 outrefs_direct

   @refs = $sv->outrefs_direct;

Returns the subset of C<outrefs> that are direct strong or weak references.

=head2 outrefs_indirect

   @refs = $sv->outrefs_indirect;

Returns the subset of C<outrefs> that are indirect references via RVs.

=head2 outrefs_inferred

   @refs = $sv->outrefs_inferred;

Returns the subset of C<outrefs> that are not directly stored in the SV
structure, but instead inferred by C<Devel::MAT> itself.

=cut

sub outrefs_strong   { $_[0]->_outrefs_matching( STRENGTH_STRONG,   $_[1] ) }
sub outrefs_weak     { $_[0]->_outrefs_matching( STRENGTH_WEAK,     $_[1] ) }
sub outrefs_direct   { $_[0]->_outrefs_matching( STRENGTH_DIRECT,   $_[1] ) }
sub outrefs_indirect { $_[0]->_outrefs_matching( STRENGTH_INDIRECT, $_[1] ) }
sub outrefs_inferred { $_[0]->_outrefs_matching( STRENGTH_INFERRED, $_[1] ) }

=head2 outref_named

   $ref = $sv->outref_named( $name );

I<Since version 0.49.>

Looks for a reference whose name is exactly that given, and returns it if so.

Throws an exception if the SV has no such outref of that name.

=head2 maybe_outref_named

   $ref = $sv->maybe_outref_named( $name );

I<Since version 0.49.>

As L</outref_named> but returns C<undef> if there is no such reference.

=cut

sub maybe_outref_named
{
   my $self = shift;
   my ( $name ) = @_;

   return first { $_->name eq $name } $self->outrefs;
}

sub outref_named
{
   my $self = shift;
   my ( $name ) = @_;

   return $self->maybe_outref_named( $name ) // croak "No outref named $name";
}

=head2 is_mortal

   $mortal = $sv->is_mortal;

Returns true if this SV is referenced by the temps stack.

=cut

sub _set_is_mortal
{
   my $self = shift;
   $self->{is_mortal} = 1;
}

sub is_mortal
{
   my $self = shift;
   return $self->{is_mortal};
}

=head1 IMMORTAL SVs

Three special SV objects exist outside of the heap, to represent C<undef> and
boolean true and false. They are

=over 4

=item * Devel::MAT::SV::UNDEF

=item * Devel::MAT::SV::YES

=item * Devel::MAT::SV::NO

=back

=cut

package Devel::MAT::SV::Immortal 0.54;
use base qw( Devel::MAT::SV );
use constant immortal => 1;
use constant basetype => "SV";
sub new {
   my $class = shift;
   my ( $df, $addr ) = @_;
   my $self = bless {}, $class;
   $self->_set_core_fields( 0, $df, $addr, 0, 0, 0 );
   return $self;
}
sub _outrefs { () }

package Devel::MAT::SV::UNDEF 0.54;
use base qw( Devel::MAT::SV::Immortal );
sub desc { "UNDEF" }
sub type { "UNDEF" }

package Devel::MAT::SV::YES 0.54;
use base qw( Devel::MAT::SV::Immortal );
sub desc { "YES" }
sub type { "SCALAR" }

# Pretend to be 1 / "1"
sub uv { 1 }
sub iv { 1 }
sub nv { 1.0 }
sub pv { "1" }
sub rv { undef }
sub is_weak { '' }

package Devel::MAT::SV::NO 0.54;
use base qw( Devel::MAT::SV::Immortal );
sub desc { "NO" }
sub type { "SCALAR" }

# Pretend to be 0 / ""
sub uv { 0 }
sub iv { 0 }
sub nv { 0.0 }
sub pv { "0" }
sub rv { undef }
sub is_weak { '' }

package Devel::MAT::SV::Unknown 0.54;
use base qw( Devel::MAT::SV );
__PACKAGE__->register_type( 0xff );

sub desc { "UNKNOWN" }

sub _outrefs {}

package Devel::MAT::SV::GLOB 0.54;
use base qw( Devel::MAT::SV );
__PACKAGE__->register_type( 1 );
use constant $CONSTANTS;
use constant basetype => "GV";

=head1 Devel::MAT::SV::GLOB

Represents a glob; an SV of type C<SVt_PVGV>.

=cut

sub load
{
   my $self = shift;
   my ( $header, $ptrs, $strs ) = @_;
   my $df = $self->df;

   my ( $line, $name_hek ) =
      unpack "$df->{uint_fmt} $df->{ptr_fmt}", $header;

   $self->_set_glob_fields(
      @{$ptrs}[0..7],
      $name_hek // 0, $line, $strs->[1],
      $strs->[0],
   );
}

sub _fixup
{
   my $self = shift;

   $_ and $_->_set_glob_at( $self->addr ) for $self->scalar, $self->array, $self->hash, $self->code;
}

=head2 file

=head2 line

=head2 location

   $file = $gv->file;

   $line = $gv->line;

   $location = $gv->location;

Returns the filename, line number, or combined location (C<FILE line LINE>)
that the GV first appears at.

=head2 name

   $name = $gv->name;

Returns the value of the C<GvNAME> field, for named globs.

=cut

# XS accessors

sub location
{
   my $self = shift;
   my $file = $self->file;
   my $line = $self->line;
   defined $file ? "$file line $line" : undef
}

=head2 stash

   $stash = $gv->stash;

Returns the stash to which the GV belongs.

=cut

sub stash  { my $self = shift; $self->df->sv_at( $self->stash_at  ) }

=head2 scalar

=head2 array

=head2 hash

=head2 code

=head2 egv

=head2 io

=head2 form

   $sv = $gv->scalar;

   $av = $gv->array;

   $hv = $gv->hash;

   $cv = $gv->code;

   $gv = $gv->egv;

   $io = $gv->io;

   $form = $gv->form;

Return the SV in the various glob slots.

=cut

sub scalar { my $self = shift; $self->df->sv_at( $self->scalar_at ) }
sub array  { my $self = shift; $self->df->sv_at( $self->array_at  ) }
sub hash   { my $self = shift; $self->df->sv_at( $self->hash_at   ) }
sub code   { my $self = shift; $self->df->sv_at( $self->code_at   ) }
sub egv    { my $self = shift; $self->df->sv_at( $self->egv_at    ) }
sub io     { my $self = shift; $self->df->sv_at( $self->io_at     ) }
sub form   { my $self = shift; $self->df->sv_at( $self->form_at   ) }

sub stashname
{
   my $self = shift;
   my $name = $self->name;
   $name =~ s(^([\x00-\x1f])){"^" . chr(64 + ord $1)}e;
   return $self->stash->stashname . "::" . $name;
}

sub desc
{
   my $self = shift;
   my $sigils = "";
   $sigils .= '$' if $self->scalar;
   $sigils .= '@' if $self->array;
   $sigils .= '%' if $self->hash;
   $sigils .= '&' if $self->code;
   $sigils .= '*' if $self->egv;
   $sigils .= 'I' if $self->io;
   $sigils .= 'F' if $self->form;

   return "GLOB($sigils)";
}

sub _outrefs
{
   my $self = shift;
   my ( $match, $no_desc ) = @_;

   my @outrefs;

   if( $match & STRENGTH_STRONG ) {
      foreach my $slot (qw( scalar array hash code io form )) {
         my $sv = $self->$slot or next;
         push @outrefs, $no_desc ? ( strong => $sv ) :
            Devel::MAT::SV::Reference( "the $slot", strong => $sv );
      }
   }

   if( my $egv = $self->egv ) {
      # the egv is weakref if if it points back to itself
      my $egv_is_self = $egv == $self;

      if( $match & ( $egv_is_self ? STRENGTH_WEAK : STRENGTH_STRONG ) ) {
         my $strength = $egv_is_self ? "weak" : "strong";
         push @outrefs, $no_desc ? ( $strength => $egv ) :
            Devel::MAT::SV::Reference( "the egv", $strength => $egv );
      }
   }

   foreach my $saved ( @{ $self->{saved} } ) {
      my $sv = $self->df->sv_at( $saved->[1] );

      push @outrefs, $no_desc ? ( inferred => $sv ) :
         Devel::MAT::SV::Reference( "saved value of " . Devel::MAT::Cmd->format_note( $saved->[0] ) . " slot",
            "inferred", $sv );
   }

   return @outrefs;
}

sub _more_saved
{
   my $self = shift;
   my ( $slot, $addr ) = @_;

   push @{ $self->{saved} }, [ $slot => $addr ];
}

package Devel::MAT::SV::SCALAR 0.54;
use base qw( Devel::MAT::SV );
__PACKAGE__->register_type( 2 );
use constant $CONSTANTS;
use constant basetype => "SV";

=head1 Devel::MAT::SV::SCALAR

Represents a non-referential scalar value; an SV of any of the types up to and
including C<SVt_PVMV> (that is, C<IV>, C<NV>, C<PV>, C<PVIV>, C<PVNV> or
C<PVMG>). This includes all numbers, integers and floats, strings, and dualvars
containing multiple parts.

=cut

sub load
{
   my $self = shift;
   my ( $header, $ptrs, $strs ) = @_;
   my $df = $self->df;

   my ( $flags, $uv, $nvbytes, $pvlen ) =
      unpack "C $df->{uint_fmt} A$df->{nv_len} $df->{uint_fmt}", $header;
   my $nv = unpack "$df->{nv_fmt}", $nvbytes;

   # $strs->[0] will be swiped

   $self->_set_scalar_fields( $flags, $uv, $nv,
      $strs->[0], $pvlen,
      $ptrs->[0], # OURSTASH
   );

   # $strs->[0] is now undef

   $flags &= ~0x1f;
   $flags and die sprintf "Unrecognised SCALAR flags %02x\n", $flags;
}

=head2 uv

   $uv = $sv->uv;

Returns the integer numeric portion as an unsigned value, if valid, or C<undef>.

=head2 iv

   $iv = $sv->iv;

Returns the integer numeric portion as a signed value, if valid, or C<undef>.

=head2 nv

   $nv = $sv->nv;

Returns the floating numeric portion, if valid, or C<undef>.

=head2 pv

   $pv = $sv->pv;

Returns the string portion, if valid, or C<undef>.

=head2 pvlen

   $pvlen = $sv->pvlen;

Returns the length of the string portion, if valid, or C<undef>.

=cut

# XS accessors

=head2 qq_pv

   $str = $sv->qq_pv( $maxlen );

Returns the PV string, if defined, suitably quoted. If C<$maxlen> is defined
and the PV is longer than this, it is truncated and C<...> is appended after
the containing quote marks.

=cut

sub qq_pv
{
   my $self = shift;
   my ( $maxlen ) = @_;

   defined( my $pv = $self->pv ) or return undef;
   $pv = substr( $pv, 0, $maxlen ) if defined $maxlen and $maxlen < length $pv;

   my $truncated = $self->pvlen > length $pv;

   if( $pv =~ m/^[\x20-\x7e]*$/ ) {
      $pv =~ s/(['\\])/\\$1/g;
      $pv = qq('$pv');
   }
   else {
      $pv =~ s{(\")     | (\r)     | (\n)     | ([\x00-\x1f\x80-\xff])}
              {$1?'\\"' : $2?"\\r" : $3?"\\n" : sprintf "\\x%02x", ord $4}egx;
      $pv = qq("$pv");
   }
   $pv .= "..." if $truncated;

   return $pv;
}

=head2 ourstash

   $stash = $sv->ourstash;

Returns the stash of the SCALAR, if it is an 'C<our>' variable.

After perl 5.20 this is no longer used, and will return C<undef>.

=cut

sub ourstash { my $self = shift; return $self->df->sv_at( $self->ourstash_at ) }

sub symname
{
   my $self = shift;
   return unless my $glob_at = $self->glob_at;
   return $mksymname->( '$', $self->df->sv_at( $glob_at ) );
}

sub type
{
   my $self = shift;
   return "SCALAR" if defined $self->uv or defined $self->iv or defined $self->nv or defined $self->pv;
   return "UNDEF";
}

sub desc
{
   my $self = shift;

   my @flags;
   push @flags, "UV" if defined $self->uv;
   push @flags, "IV" if defined $self->iv;
   push @flags, "NV" if defined $self->nv;
   push @flags, "PV" if defined $self->pv;
   local $" = ",";
   return "UNDEF()" unless @flags;
   return "SCALAR(@flags)";
}

sub _set_shared_hek_at { my $self = shift; $self->{shared_hek_at} = $_[0]; }

sub shared_hek { my $self = shift; return $self->{shared_hek_at}; }

sub _outrefs
{
   my $self = shift;
   my ( $match, $no_desc ) = @_;

   my @outrefs;

   if( $match & STRENGTH_STRONG and my $ourstash = $self->ourstash ) {
      push @outrefs, $no_desc ? ( strong => $ourstash ) :
         Devel::MAT::SV::Reference( "the our stash", strong => $ourstash );
   }

   return @outrefs;
}

package Devel::MAT::SV::REF 0.54;
use base qw( Devel::MAT::SV );
__PACKAGE__->register_type( 3 );
use constant $CONSTANTS;
use constant basetype => "SV";

=head1 Devel::MAT::SV::REF

Represents a referential scalar; any SCALAR-type SV with the C<SvROK> flag
set.

=cut

sub load
{
   my $self = shift;
   my ( $header, $ptrs, $strs ) = @_;

   ( my $flags ) =
      unpack "C", $header;

   $self->_set_ref_fields(
      @{$ptrs}[0,1], # RV, OURSTASH
      $flags & 0x01, # RV_IS_WEAK
   );

   $flags &= ~0x01;
   $flags and die sprintf "Unrecognised REF flags %02x\n", $flags;
}

=head2 rv

   $svrv = $sv->rv;

Returns the SV referred to by the reference.

=cut

sub rv { my $self = shift; return $self->df->sv_at( $self->rv_at ) }

=head2 is_weak

   $weak = $sv->is_weak;

Returns true if the SV is a weakened RV reference.

=cut

# XS accessor

=head2 ourstash

   $stash = $sv->ourstash;

Returns the stash of the SCALAR, if it is an 'C<our>' variable.

=cut

sub ourstash { my $self = shift; return $self->df->sv_at( $self->ourstash_at ) }

sub desc
{
   my $self = shift;

   return sprintf "REF(%s)", $self->is_weak ? "W" : "";
}

*symname = \&Devel::MAT::SV::SCALAR::symname;

sub _outrefs
{
   my $self = shift;
   my ( $match, $no_desc ) = @_;

   my @outrefs;

   my $is_weak = $self->is_weak;
   if( $match & ( $is_weak ? STRENGTH_WEAK : STRENGTH_STRONG ) and my $rv = $self->rv ) {
      my $strength = $is_weak ? "weak" : "strong";
      push @outrefs, $no_desc ? ( $strength => $rv ) :
         Devel::MAT::SV::Reference( "the referrant", $strength => $rv );
   }

   if( $match & STRENGTH_STRONG and my $ourstash = $self->ourstash ) {
      push @outrefs, $no_desc ? ( strong => $ourstash ) :
         Devel::MAT::SV::Reference( "the our stash", strong => $ourstash );
   }

   return @outrefs;
}

package Devel::MAT::SV::BOOL 0.54;
use base qw( Devel::MAT::SV::SCALAR );

sub type { return "BOOL" }

sub desc
{
   my $self = shift;
   return "BOOL(YES)" if $self->uv;
   return "BOOL(NO)";
}

package Devel::MAT::SV::ARRAY 0.54;
use base qw( Devel::MAT::SV );
__PACKAGE__->register_type( 4 );
use constant $CONSTANTS;
use constant basetype => "AV";

=head1 Devel::MAT::SV::ARRAY

Represents an array; an SV of type C<SVt_PVAV>.

=cut

sub refcount_adjusted
{
   my $self = shift;
   # AVs that are backrefs lists have an SvREFCNT artificially high
   return $self->refcnt - ( $self->is_backrefs ? 1 : 0 );
}

sub load
{
   my $self = shift;
   my ( $header, $ptrs, $strs ) = @_;
   my $df = $self->df;

   my ( $n, $flags ) =
      unpack "$df->{uint_fmt} C", $header;

   $self->_set_array_fields( $flags || 0, [ $n ? $df->_read_ptrs($n) : () ] );
}

sub _more_saved
{
   my $self = shift;
   my ( $index, $addr ) = @_;

   push @{ $self->{saved} }, [ $index => $addr ];
}

=head2 is_unreal

   $unreal = $av->is_unreal;

Returns true if the C<AvREAL()> flag is not set on the array - i.e. that its
SV pointers do not contribute to the C<SvREFCNT> of the SVs it points at.

=head2 is_backrefs

   $backrefs = $av->is_backrefs;

Returns true if the array contains the backrefs list of a hash or
weakly-referenced object.

=cut

# XS accessors

sub symname
{
   my $self = shift;
   return unless my $glob_at = $self->glob_at;
   return $mksymname->( '@', $self->df->sv_at( $glob_at ) );
}

=head2 elems

   @svs = $av->elems;

Returns all of the element SVs in a list

=cut

sub elems
{
   my $self = shift;

   my $n = $self->n_elems;
   return $n unless wantarray;

   my $df = $self->df;
   return map { $df->sv_at( $self->elem_at( $_ ) ) } 0 .. $n-1;
}

=head2 elem

   $sv = $av->elem( $index );

Returns the SV at the given index

=cut

sub elem
{
   my $self = shift;
   return $self->df->sv_at( $self->elem_at( $_[0] ) );
}

sub desc
{
   my $self = shift;

   my @flags = $self->n_elems;

   push @flags, "!REAL" if $self->is_unreal;

   $" = ",";
   return "ARRAY(@flags)";
}

sub _outrefs
{
   my $self = shift;
   my ( $match, $no_desc ) = @_;

   my $n = $self->n_elems;

   my @outrefs;

   if( $self->is_unreal ) {
      if( $match & STRENGTH_WEAK ) {
         foreach my $idx ( 0 .. $n-1 ) {
            my $sv = $self->elem( $idx ) or next;

            push @outrefs, $no_desc ? ( weak => $sv ) :
               Devel::MAT::SV::Reference( "element " . Devel::MAT::Cmd->format_value( $idx, index => 1 ), weak => $sv );
         }
      }
   }
   else {
      foreach my $idx ( 0 .. $n-1 ) {
         my $sv = $self->elem( $idx ) or next;

         my $name = $no_desc ? undef :
            "element " . Devel::MAT::Cmd->format_value( $idx, index => 1 );
         if( $match & STRENGTH_STRONG ) {
            push @outrefs, $no_desc ? ( strong => $sv ) :
               Devel::MAT::SV::Reference( $name, strong => $sv );
         }
         if( $match & STRENGTH_INDIRECT and $sv->type eq "REF" and !$sv->{magic} and my $rv = $sv->rv ) {
            push @outrefs, $no_desc ? ( indirect => $rv ) :
               Devel::MAT::SV::Reference( $name . " via RV", indirect => $rv );
         }
      }
   }

   foreach my $saved ( @{ $self->{saved} } ) {
      my $sv = $self->df->sv_at( $saved->[1] );

      push @outrefs, $no_desc ? ( inferred => $sv ) :
         Devel::MAT::SV::Reference( "saved value of element " . Devel::MAT::Cmd->format_value( $saved->[0], index => 1 ),
            inferred => $sv );
   }

   return @outrefs;
}

package Devel::MAT::SV::PADLIST 0.54;
# Synthetic type
use base qw( Devel::MAT::SV::ARRAY );
use constant type => "PADLIST";
use constant $CONSTANTS;

=head1 Devel::MAT::SV::PADLIST

A subclass of ARRAY, this is used to represent the PADLIST of a CODE SV.

=cut

sub padcv { my $self = shift; return $self->df->sv_at( $self->padcv_at ) }

sub desc
{
   my $self = shift;
   return "PADLIST(" . $self->n_elems . ")";
}

# Totally different outrefs format than ARRAY
sub _outrefs
{
   my $self = shift;
   my ( $match, $no_desc ) = @_;

   my @outrefs;

   if( $match & STRENGTH_STRONG ) {
      my $df = $self->df;
      my $n = $self->n_elems;

      if( my $padnames = $df->sv_at( $self->elem_at( 0 ) ) ) {
         push @outrefs, $no_desc ? ( strong => $padnames ) :
            Devel::MAT::SV::Reference( "the padnames", strong => $padnames );
      }

      foreach my $idx ( 1 .. $n-1 ) {
         my $pad = $df->sv_at( $self->elem_at( $idx ) ) or next;

         push @outrefs, $no_desc ? ( strong => $pad ) :
            Devel::MAT::SV::Reference( "pad at depth $idx", strong => $pad );
      }
   }

   return @outrefs;
}

package Devel::MAT::SV::PADNAMES 0.54;
# Synthetic type
use base qw( Devel::MAT::SV::ARRAY );
use constant type => "PADNAMES";
use constant $CONSTANTS;

=head1 Devel::MAT::SV::PADNAMES

A subclass of ARRAY, this is used to represent the PADNAMES of a CODE SV.

=cut

sub padcv { my $self = shift; return $self->df->sv_at( $self->padcv_at ) }

=head2 padname

   $padname = $padnames->padname( $padix );

Returns the name of the lexical at the given index, or C<undef>

=cut

sub padname
{
   my $self = shift;
   my ( $padix ) = @_;
   my $namepv = $self->elem( $padix ) or return undef;
   $namepv->type eq "SCALAR" or return undef;
   return $namepv->pv;
}

=head2 padix_from_padname

   $padix = $padnames->padix_from_padname( $padname );

Returns the index of the lexical with the given name, or C<undef>

=cut

sub padix_from_padname
{
   my $self = shift;
   my ( $padname ) = @_;

   foreach my $padix ( 1 .. scalar( $self->elems ) - 1 ) {
      my $namepv;
      return $padix if $namepv = $self->elem( $padix ) and
                       $namepv->type eq "SCALAR" and
                       $namepv->pv eq $padname;
   }

   return undef;
}

sub desc
{
   my $self = shift;
   return "PADNAMES(" . scalar($self->elems) . ")";
}

# Totally different outrefs format than ARRAY
sub _outrefs
{
   my $self = shift;
   my ( $match, $no_desc ) = @_;

   my @outrefs;

   if( $match & STRENGTH_STRONG ) {
      my $df = $self->df;
      my $n = $self->n_elems;

      foreach my $idx ( 1 .. $n-1 ) {
         my $padname = $df->sv_at( $self->elem_at( $idx ) ) or next;

         push @outrefs, $no_desc ? ( strong => $padname ) :
            Devel::MAT::SV::Reference( "padname " . Devel::MAT::Cmd->format_value( $idx, index => 1 ), strong => $padname );
      }
   }

   return @outrefs;
}

package Devel::MAT::SV::PAD 0.54;
# Synthetic type
use base qw( Devel::MAT::SV::ARRAY );
use constant type => "PAD";
use constant $CONSTANTS;

=head1 Devel::MAT::SV::PAD

A subclass of ARRAY, this is used to represent a PAD of a CODE SV.

=cut

sub desc
{
   my $self = shift;
   return "PAD(" . scalar($self->elems) . ")";
}

=head2 padcv

   $cv = $pad->padcv;

Returns the C<CODE> SV for which this is a pad.

=cut

sub padcv { my $self = shift; return $self->df->sv_at( $self->padcv_at ) }

=head2 lexvars

   ( $name, $sv, $name, $sv, ... ) = $pad->lexvars;

Returns a name/value list of the lexical variables in the pad.

=cut

sub lexvars
{
   my $self = shift;
   my $padcv = $self->padcv;

   my @svs = $self->elems;
   return map {
      my $padname = $padcv->padname( $_ );
      $padname ? ( $padname->name => $svs[$_] ) : ()
   } 1 .. $#svs;
}

=head2 maybe_lexvar

   $sv = $pad->maybe_lexvar( $padname );

I<Since version 0.49.>

Returns the SV associated with the given padname if one exists, or C<undef> if
not.

Used to be named C<lexvar>.

=cut

sub maybe_lexvar
{
   my $self = shift;
   my ( $padname ) = @_;

   my $padix = $self->padcv->padix_from_padname( $padname ) or return undef;
   return $self->elem( $padix );
}

*lexvar = \&maybe_lexvar;

# Totally different outrefs format than ARRAY
sub _outrefs
{
   my $self = shift;
   my ( $match, $no_desc ) = @_;

   my $padcv = $self->padcv;

   my @svs = $self->elems;

   my @outrefs;

   if( $match & STRENGTH_STRONG and my $argsav = $svs[0] ) {
      push @outrefs, $no_desc ? ( strong => $argsav ) :
         Devel::MAT::SV::Reference( "the " . Devel::MAT::Cmd->format_note( '@_', 1 ) . " av", strong => $argsav );
   }

   foreach my $idx ( 1 .. $#svs ) {
      my $sv = $svs[$idx] or next;

      my $name;
      if( !$no_desc ) {
         my $padname = $padcv->padname( $idx );
         $name = $padname ? $padname->name : undef;
         if( $name ) {
            $name = "the lexical " . Devel::MAT::Cmd->format_note( $name, 1 );
         }
         else {
            $name = "pad temporary $idx";
         }
      }

      if( $match & STRENGTH_STRONG ) {
         push @outrefs, $no_desc ? ( strong => $sv ) :
            Devel::MAT::SV::Reference( $name, strong => $sv );
      }
      if( $match & STRENGTH_INDIRECT and $sv->type eq "REF" and !$sv->{magic} and my $rv = $sv->rv ) {
         push @outrefs, $no_desc ? ( indirect => $rv ) :
            Devel::MAT::SV::Reference( $name . " via RV", indirect => $rv );
      }
   }

   return @outrefs;
}

package Devel::MAT::SV::HASH 0.54;
use base qw( Devel::MAT::SV );
__PACKAGE__->register_type( 5 );
use constant $CONSTANTS;
use constant basetype => "HV";

=head1 Devel::MAT::SV::HASH

Represents a hash; an SV of type C<SVt_PVHV>. The C<Devel::MAT::SV::STASH>
subclass is used to represent hashes that are used as stashes.

=cut

sub load
{
   my $self = shift;
   my ( $header, $ptrs, $strs ) = @_;
   my $df = $self->df;

   ( my $n ) =
      unpack "$df->{uint_fmt} a*", $header;

   my $df_has_hek_ptr = $df->{format_minor} >= 6;

   my %values_at;
   foreach ( 1 .. $n ) {
      my $key = $df->_read_str;
      my $hek_ptr = $df_has_hek_ptr ? $df->_read_ptr : undef;
      $values_at{$key} = [ $hek_ptr, $df->_read_ptr ];
   }

   $self->_set_hash_fields(
      $ptrs->[0], # BACKREFS
      \%values_at,
   );

}

# Back-compat. for loading old .pmat files that didn't store AvREAL
sub _fixup
{
   my $self = shift;

   if( my $backrefs = $self->backrefs ) {
      $backrefs->_set_backrefs( 1 ) if $backrefs->type eq "ARRAY";
   }
}

sub _more_saved
{
   my $self = shift;
   my ( $keyaddr, $valaddr ) = @_;

   push @{ $self->{saved} }, [ $keyaddr, $valaddr ];
}

sub symname
{
   my $self = shift;
   return unless my $glob_at = $self->glob_at;
   return $mksymname->( '%', $self->df->sv_at( $glob_at ) );
}

# HVs have a backrefs field directly, rather than using magic
sub backrefs
{
   my $self = shift;
   return $self->df->sv_at( $self->backrefs_at );
}

=head2 keys

   @keys = $hv->keys;

Returns the set of keys present in the hash, as plain perl strings, in no
particular order.

=cut

# XS accessor

=head2 value

   $sv = $hv->value( $key );

Returns the SV associated with the given key

=cut

sub value
{
   my $self = shift;
   my ( $key ) = @_;
   return $self->df->sv_at( $self->value_at( $key ) );
}

=head2 values

   @svs = $hv->values;

Returns all of the SVs stored as values, in no particular order (though, in an
order corresponding to the order returned by C<keys>).

=cut

sub values
{
   my $self = shift;
   return $self->n_values if !wantarray;

   my $df = $self->df;
   return map { $df->sv_at( $_ ) } $self->values_at;
}

sub desc
{
   my $self = shift;
   my $named = $self->{name} ? " named $self->{name}" : "";
   return "HASH(" . $self->n_values . ")";
}

sub _outrefs
{
   my $self = shift;
   my ( $match, $no_desc ) = @_;

   my $df = $self->df;

   my @outrefs;

   if( my $backrefs = $self->backrefs ) {
      # backrefs are optimised so if there's only one backref, it is stored
      # in the backrefs slot directly
      if( $backrefs->type eq "ARRAY" ) {
         if( $match & STRENGTH_STRONG ) {
            push @outrefs, $no_desc ? ( strong => $backrefs ) :
               Devel::MAT::SV::Reference( "the backrefs list", strong => $backrefs );
         }

         if( $match & STRENGTH_INDIRECT ) {
            foreach my $sv ( $self->backrefs->elems ) {
               push @outrefs, $no_desc ? ( indirect => $sv ) :
                  Devel::MAT::SV::Reference( "a backref", indirect => $sv );
            }
         }
      }
      else {
         if( $match & STRENGTH_WEAK ) {
            push @outrefs, $no_desc ? ( weak => $backrefs ) :
               Devel::MAT::SV::Reference( "a backref", weak => $backrefs );
         }
      }
   }

   foreach my $key ( $self->keys ) {
      my $sv = $df->sv_at( $self->value_at( $key ) ) or next;
      my $name = $no_desc ? undef :
         "value " . Devel::MAT::Cmd->format_value( $key, key => 1 );

      if( $match & STRENGTH_STRONG ) {
         push @outrefs, $no_desc ? ( strong => $sv ) :
            Devel::MAT::SV::Reference( $name, strong => $sv );
      }
      if( $match & STRENGTH_INDIRECT and $sv->type eq "REF" and !$sv->{magic} and my $rv = $sv->rv ) {
         push @outrefs, $no_desc ? ( indirect => $sv ) :
            Devel::MAT::SV::Reference( $name . " via RV", indirect => $rv );
      }
   }

   foreach my $saved ( @{ $self->{saved} } ) {
      my $keysv = $self->df->sv_at( $saved->[0] );
      my $valsv = $self->df->sv_at( $saved->[1] );

      push @outrefs, $no_desc ? ( inferred => $keysv ) :
         Devel::MAT::SV::Reference( "a key for saved value",
            inferred => $keysv );
      push @outrefs, $no_desc ? ( inferred => $valsv ) :
         Devel::MAT::SV::Reference( "saved value of value " . Devel::MAT::Cmd->format_value( $keysv->pv, key => 1 ),
            inferred => $valsv );
   }

   return @outrefs;
}

package Devel::MAT::SV::STASH 0.54;
use base qw( Devel::MAT::SV::HASH );
__PACKAGE__->register_type( 6 );
use constant $CONSTANTS;

=head1 Devel::MAT::SV::STASH

Represents a hash used as a stash; an SV of type C<SVt_PVHV> whose C<HvNAME()>
is non-NULL. This is a subclass of C<Devel::MAT::SV::HASH>.

=cut

sub load
{
   my $self = shift;
   my ( $header, $ptrs, $strs ) = @_;
   my $df = $self->df;

   my ( $hash_bytes, $hash_ptrs, $hash_strs ) = @{ $df->{sv_sizes}[5] };

   $self->SUPER::load(
      substr( $header, 0, $hash_bytes, "" ),
      [ splice @$ptrs, 0, $hash_ptrs ],
      [ splice @$strs, 0, $hash_strs ],
   );

   @{$self}{qw( mro_linearall_at mro_linearcurrent_at mro_nextmethod_at mro_isa_at )} =
      @$ptrs;

   ( $self->{name} ) =
      @$strs;
}

=head2 mro_linear_all

=head2 mro_linearcurrent

=head2 mro_nextmethod

=head2 mro_isa

   $hv = $stash->mro_linear_all;

   $sv = $stash->mro_linearcurrent;

   $sv = $stash->mro_nextmethod;

   $av = $stash->mro_isa;

Returns the fields from the MRO structure

=cut

sub mro_linearall     { my $self = shift; return $self->df->sv_at( $self->{mro_linearall_at} ) }
sub mro_linearcurrent { my $self = shift; return $self->df->sv_at( $self->{mro_linearcurrent_at} ) }
sub mro_nextmethod    { my $self = shift; return $self->df->sv_at( $self->{mro_nextmethod_at} ) }
sub mro_isa           { my $self = shift; return $self->df->sv_at( $self->{mro_isa_at} ) }

=head2 value_code

   $cv = $stash->value_code( $key );

Returns the CODE associated with the given symbol name, if it exists, or
C<undef> if not. This is roughly equivalent to

   $cv = $stash->value( $key )->code;

Except that it is aware of the direct reference to CVs that perl 5.22 will
optimise for. This method should be used in preference to the above construct.

=cut

sub value_code
{
   my $self = shift;
   my ( $key ) = @_;

   my $sv = $self->value( $key ) or return undef;
   if( $sv->type eq "GLOB" ) {
      return $sv->code;
   }
   elsif( $sv->type eq "REF" ) {
      return $sv->rv;
   }

   die "TODO: value_code on non-GLOB, non-REF ${\ $sv->desc }";
}

=head2 stashname

   $name = $stash->stashname;

Returns the name of the stash

=cut

sub stashname
{
   my $self = shift;
   return $self->{name};
}

sub desc
{
   my $self = shift;
   my $desc = $self->SUPER::desc;
   $desc =~ s/^HASH/STASH/;
   return $desc;
}

sub _outrefs
{
   my $self = shift;
   my ( $match, $no_desc ) = @_;

   my @outrefs = $self->SUPER::_outrefs( @_ );

   if( $match & STRENGTH_STRONG ) {
      if( my $sv = $self->mro_linearall ) {
         push @outrefs, $no_desc ? ( strong => $sv ) :
            Devel::MAT::SV::Reference( "the mro linear all HV",  strong => $sv );
      }
      if( my $sv = $self->mro_linearcurrent ) {
         push @outrefs, $no_desc ? ( strong => $sv ) :
            Devel::MAT::SV::Reference( "the mro linear current", strong => $sv );
      }
      if( my $sv = $self->mro_nextmethod ) {
         push @outrefs, $no_desc ? ( strong => $sv ) :
            Devel::MAT::SV::Reference( "the mro next::method",   strong => $sv );
      }
      if( my $sv = $self->mro_isa ) {
         push @outrefs, $no_desc ? ( strong => $sv ) :
            Devel::MAT::SV::Reference( "the mro ISA cache",      strong => $sv );
      }
   }

   return @outrefs;
}

package Devel::MAT::SV::CODE 0.54;
use base qw( Devel::MAT::SV );
__PACKAGE__->register_type( 7 );
use constant $CONSTANTS;
use constant basetype => "CV";

use Carp;

use List::Util 1.44 qw( uniq );

use Struct::Dumb 0.07 qw( struct );
struct Padname => [qw( name ourstash flags fieldix fieldstash_at )];
{
   no strict 'refs';
   *{__PACKAGE__."::Padname::is_outer"}  = sub { shift->flags & 0x01 };
   *{__PACKAGE__."::Padname::is_state"}  = sub { shift->flags & 0x02 };
   *{__PACKAGE__."::Padname::is_lvalue"} = sub { shift->flags & 0x04 };
   *{__PACKAGE__."::Padname::is_typed"}  = sub { shift->flags & 0x08 };
   *{__PACKAGE__."::Padname::is_our"}    = sub { shift->flags & 0x10 };

   # Internal flags, not appearing in the file itself
   *{__PACKAGE__."::Padname::is_field"}  = sub { shift->flags & 0x100 };
}

=head1 Devel::MAT::SV::CODE

Represents a function or closure; an SV of type C<SVt_PVCV>.

=cut

sub load
{
   my $self = shift;
   my ( $header, $ptrs, $strs ) = @_;
   my $df = $self->df;

   my ( $line, $flags, $oproot, $depth, $name_hek ) =
      unpack "$df->{uint_fmt} C $df->{ptr_fmt} $df->{u32_fmt} $df->{ptr_fmt}", $header;

   defined $depth or $depth = -1;
   $name_hek //= 0;

   $self->_set_code_fields( $line, $flags, $oproot, $depth, $name_hek,
      @{$ptrs}[0, 2..4], # STASH, OUTSIDE, PADLIST, CONSTVAL
      @{$strs}[0, 1],    # FILE, NAME
   );
   $self->_set_glob_at( $ptrs->[1] );

   # After perl 5.20 individual padname structs are no longer arena-allocated
   $self->{padnames} = [] if $df->{perlver} > ( ( 5 << 24 ) | ( 20 << 16 ) | 0xffff );

   while( my $type = $df->_read_u8 ) {
      match( $type : == ) {
         case( 1 ) { push @{ $self->{consts_at} }, $df->_read_ptr }
         case( 2 ) { push @{ $self->{constix} }, $df->_read_uint }
         case( 3 ) { push @{ $self->{gvs_at} }, $df->_read_ptr }
         case( 4 ) { push @{ $self->{gvix} }, $df->_read_uint }
         case( 5 ) { my $padix = $df->_read_uint;
                     $self->{padnames}[$padix] = _load_padname( $df ); }
         case( 6 ) { # ignore - used to be padsvs_at
                     $df->_read_uint; $df->_read_uint; $df->_read_ptr; }
         case( 7 ) { $self->_set_padnames_at( $df->_read_ptr ); }
         case( 8 ) { my $depth = $df->_read_uint;
                     $self->{pads_at}[$depth] = $df->_read_ptr; }
         case( 9 )  { my $padname = $self->{padnames}[ $df->_read_uint ];
                      $padname->flags = $df->_read_u8; }
         case( 10 ) { my $padname = $self->{padnames}[ $df->_read_uint ];
                      $padname->flags |= 0x100;
                      $padname->fieldix = $df->_read_uint;
                      $padname->fieldstash_at = $df->_read_ptr; }
         default {
            die "TODO: unhandled CODEx type $type";
         }
      }
   }
}

sub _load_padname
{
   my ( $df ) = @_;

   return Padname( $df->_read_str, $df->_read_ptr, 0, 0, 0 );
}

sub _fixup
{
   my $self = shift;

   my $df = $self->df;

   my $padlist = $self->padlist;
   if( $padlist ) {
      bless $padlist, "Devel::MAT::SV::PADLIST";
      $padlist->_set_padcv_at( $self->addr );
   }

   my $padnames;
   my @pads;

   # 5.18.0 onwards has a totally different padlist arrangement
   if( $df->{perlver} >= ( ( 5 << 24 ) | ( 18 << 16 ) ) ) {
      $padnames = $self->padnames_av;

      @pads = map { $df->sv_at( $_ ) } @{ $self->{pads_at} };
      shift @pads; # always zero
   }
   elsif( $padlist ) {
      # PADLIST[0] stores the names of the lexicals
      # The rest stores the actual pads
      ( $padnames, @pads ) = $padlist->elems;
      $self->_set_padnames_at( $padnames->addr );
   }

   if( $padnames ) {
      bless $padnames, "Devel::MAT::SV::PADNAMES";
      $padnames->_set_padcv_at( $self->addr );

      $self->{padnames} = \my @padnames;

      foreach my $padix ( 1 .. $padnames->elems - 1 ) {
         my $padnamesv = $padnames->elem( $padix ) or next;
         $padnamesv->immortal and next; # UNDEF

         $padnames[$padix] = Padname( $padnamesv->pv, $padnamesv->ourstash, 0, 0, 0 );
      }
   }

   foreach my $pad ( @pads ) {
      next unless $pad;

      bless $pad, "Devel::MAT::SV::PAD";
      $pad->_set_padcv_at( $self->addr );
   }

   $self->{pads} = \@pads;

   # Under ithreads, constants and captured GVs are actually stored in the first padlist
   if( $df->ithreads ) {
      my $pad0 = $pads[0];

      foreach my $type (qw( const gv )) {
         my $idxes  = $self->{"${type}ix"} or next;
         my $svs_at = $self->{"${type}s_at"} ||= [];

         @$svs_at = map { my $e = $pad0->elem($_);
                          $e ? $e->addr : undef } uniq @$idxes;
      }
   }

   if( $self->is_cloned and my $oproot = $self->oproot ) {
      if( my $protosub = $df->{protosubs_by_oproot}{$oproot} ) {
         $self->_set_protosub_at( $protosub->addr );
      }
   }
}

=head2 stash

=head2 glob

=head2 file

=head2 line

=head2 scope

=head2 padlist

=head2 constval

=head2 oproot

=head2 depth

   $stash = $cv->stash;

   $gv = $cv->glob;

   $filename = $cv->file;

   $line = $cv->line;

   $scope_cv = $cv->scope;

   $av = $cv->padlist;

   $sv = $cv->constval;

   $addr = $cv->oproot;

   $depth = $cv->depth;

Returns the stash, glob, filename, line number, scope, padlist, constant value,
oproot or depth of the code.

=cut

sub stash    { my $self = shift; return $self->df->sv_at( $self->stash_at ) }
sub glob     { my $self = shift; return $self->df->sv_at( $self->glob_at ) }
# XS accessors: file, line
sub scope    { my $self = shift; return $self->df->sv_at( $self->outside_at ) }
sub padlist  { my $self = shift; return $self->df->sv_at( $self->padlist_at ) }
sub constval { my $self = shift; return $self->df->sv_at( $self->constval_at ) }
# XS accessors: oproot, depth

=head2 location

   $location = $cv->location;

Returns C<FILE line LINE> if the line is defined, or C<FILE> if not.

=cut

sub location
{
   my $self = shift;
   my $line = $self->line;
   my $file = $self->file;
   # line 0 is invalid
   return $line ? "$file line $line" : $file;
}

=head2 is_clone

=head2 is_cloned

=head2 is_xsub

=head2 is_weakoutside

=head2 is_cvgv_rc

=head2 is_lexical

   $clone = $cv->is_clone;

   $cloned = $cv->is_cloned;

   $xsub = $cv->is_xsub;

   $weak = $cv->is_weakoutside;

   $rc = $cv->is_cvgv_rc;

   $lexical = $cv->is_lexical;

Returns the C<CvCLONE()>, C<CvCLONED()>, C<CvISXSUB()>, C<CvWEAKOUTSIDE()>,
C<CvCVGV_RC()> and C<CvLEXICAL()> flags.

=cut

# XS accessors

=head2 protosub

   $protosub = $cv->protosub;

Returns the protosub CV, if known, for a closure CV.

=cut

sub protosub { my $self = shift; return $self->df->sv_at( $self->protosub_at ); }

=head2 constants

   @svs = $cv->constants;

Returns a list of the SVs used as constants or method names in the code. On
ithreads perl the constants are part of the padlist structure so this list is
constructed from parts of the padlist at loading time.

=cut

sub constants
{
   my $self = shift;
   my $df = $self->df;
   return map { $df->sv_at($_) } @{ $self->{consts_at} || [] };
}

=head2 globrefs

   @svs = $cv->globrefs;

Returns a list of the SVs used as GLOB references in the code. On ithreads
perl the constants are part of the padlist structure so this list is
constructed from parts of the padlist at loading time.

=cut

sub globrefs
{
   my $self = shift;
   my $df = $self->df;
   return map { $df->sv_at($_) } @{ $self->{gvs_at} };
}

sub stashname { my $self = shift; return $self->stash ? $self->stash->stashname : undef }

sub symname
{
   my $self = shift;

   # CvLEXICALs or CVs with non-reified CvGVs may still have a hekname
   if( defined( my $hekname = $self->hekname ) ) {
      my $stashname = $self->stashname;
      $stashname =~ s/^main:://;
      return '&' . $stashname . "::" . $hekname;
   }
   elsif( my $glob = $self->glob ) {
      return '&' . $glob->stashname;
   }

   return undef;
}

=head2 padname

   $padname = $cv->padname( $padix );

Returns the name of the $padix'th lexical variable, or C<undef> if it doesn't
have a name.

The returned padname is a structure of the following fields:

   $name = $padname->name;

   $bool = $padname->is_outer;
   $bool = $padname->is_state;
   $bool = $padname->is_lvalue;
   $bool = $padname->is_typed;
   $bool = $padname->is_our;
   $bool = $padname->is_field;

=cut

sub padname
{
   my $self = shift;
   my ( $padix ) = @_;

   return $self->{padnames}[$padix];
}

=head2 padix_from_padname

   $padix = $cv->padix_from_padname( $padname );

Returns the index of the first lexical variable with the given pad name, or
C<undef> if one does not exist.

=cut

sub padix_from_padname
{
   my $self = shift;
   my ( $padname ) = @_;

   my $padnames = $self->{padnames};

   foreach my $padix ( 1 .. $#$padnames ) {
      my $thisname;

      return $padix if defined $padnames->[$padix] and
                       defined( $thisname = $padnames->[$padix]->name ) and
                       $thisname eq $padname;
   }

   return undef;
}

=head2 max_padix

   $max_padix = $cv->max_padix;

Returns the maximum valid pad index.

This is typically used to create a list of potential pad indexes, such as

   0 .. $cv->max_padix;

Note that since pad slots may contain things other than lexical variables, not
every pad slot between 0 and this index will necessarily contain a lexical
variable or have a pad name.

=cut

sub max_padix
{
   my $self = shift;
   return $#{ $self->{padnames} };
}

=head2 padnames_av

   $padnames_av = $cv->padnames_av;

Returns the AV reference directly which stores the pad names.

After perl version 5.20, this is no longer used directly and will return
C<undef>. The individual pad names themselves can still be found via the
C<padname> method.

=cut

sub padnames_av
{
   my $self = shift;

   return $self->df->sv_at( $self->padnames_at or return undef )
      // croak "${\ $self->desc } PADNAMES is not accessible";
}

=head2 pads

   @pads = $cv->pads;

Returns a list of the actual pad AVs.

=cut

sub pads
{
   my $self = shift;
   return $self->{pads} ? @{ $self->{pads} } : ();
}

=head2 pad

   $pad = $cv->pad( $depth );

Returns the PAD at the given depth (given by 1-based index).

=cut

sub pad
{
   my $self = shift;
   my ( $depth ) = @_;
   return $self->{pads} ? $self->{pads}[$depth-1] : undef;
}

=head2 maybe_lexvar

   $sv = $cv->maybe_lexvar( $padname, $depth );

I<Since version 0.49.>

Returns the SV on the PAD associated with the given padname, at the
optionally-given depth (1-based index). If I<$depth> is not provided, the
topmost live PAD will be used. If no variable exists of the given name returns
C<undef>.

Used to be called C<lexvar>.

=cut

sub maybe_lexvar
{
   my $self = shift;
   my ( $padname, $depth ) = @_;

   $depth //= $self->depth;
   $depth or croak "Cannot fetch current pad of a non-live CODE";

   return $self->pad( $depth )->maybe_lexvar( $padname );
}

*lexvar = \&maybe_lexvar;

sub desc
{
   my $self = shift;

   my @flags;
   push @flags, "PP"    if $self->oproot;
   push @flags, "CONST" if $self->constval;
   push @flags, "XS"    if $self->is_xsub;

   push @flags, "closure" if $self->is_cloned;
   push @flags, "proto"   if $self->is_clone;

   local $" = ",";
   return "CODE(@flags)";
}

sub _outrefs
{
   my $self = shift;
   my ( $match, $no_desc ) = @_;

   my $pads = $self->{pads};

   my $maxdepth = $pads ? scalar @$pads : 0;

   my $have_padlist = defined $self->padlist;

   my @outrefs;

   my $is_weakoutside = $self->is_weakoutside;
   if( $match & ( $is_weakoutside ? STRENGTH_WEAK : STRENGTH_STRONG ) and my $scope = $self->scope ) {
      my $strength = $is_weakoutside ? "weak" : "strong";
      push @outrefs, $no_desc ? ( $strength => $scope ) :
         Devel::MAT::SV::Reference( "the scope", $strength => $scope );
   }

   if( $match & STRENGTH_WEAK and my $stash = $self->stash ) {
      push @outrefs, $no_desc ? ( weak => $stash ) :
         Devel::MAT::SV::Reference( "the stash", weak => $stash );
   }

   my $is_strong_gv = $self->is_cvgv_rc;
   if( $match & ( $is_strong_gv ? STRENGTH_STRONG : STRENGTH_WEAK ) and my $glob = $self->glob ) {
      my $strength = $is_strong_gv ? "strong" : "weak";
      push @outrefs, $no_desc ? ( $strength => $glob ) :
         Devel::MAT::SV::Reference( "the glob", $strength => $glob );
   }

   if( $match & STRENGTH_STRONG and my $constval = $self->constval ) {
      push @outrefs, $no_desc ? ( strong => $constval ) :
         Devel::MAT::SV::Reference( "the constant value", strong => $constval );
   }

   if( $match & STRENGTH_INFERRED and my $protosub = $self->protosub ) {
      push @outrefs, $no_desc ? ( inferred => $protosub ) :
         Devel::MAT::SV::Reference( "the protosub", inferred => $protosub );
   }

   # Under ithreads, constants and captured GVs are actually stored in the
   # first padlist, so they're only here.
   my $ithreads = $self->df->ithreads;

   if( $match & ( $ithreads ? STRENGTH_INDIRECT : STRENGTH_STRONG ) ) {
      my $strength = $ithreads ? "indirect" : "strong";

      foreach my $sv ( $self->constants ) {
         $sv or next;
         push @outrefs, $no_desc ? ( $strength => $sv ) :
            Devel::MAT::SV::Reference( "a constant", $strength => $sv );
      }
      foreach my $sv ( $self->globrefs ) {
         $sv or next;
         push @outrefs, $no_desc ? ( $strength => $sv ) :
            Devel::MAT::SV::Reference( "a referenced glob", $strength => $sv );
      }
   }

   if( $match & STRENGTH_STRONG and $have_padlist ) {
      push @outrefs, $no_desc ? ( strong => $self->padlist ) :
         Devel::MAT::SV::Reference( "the padlist", strong => $self->padlist );
   }

   # If we have a PADLIST then its contents are indirect; if not then they
   #   are direct strong
   if( $match & ( $have_padlist ? STRENGTH_INDIRECT : STRENGTH_STRONG ) ) {
      my $strength = $have_padlist ? "indirect" : "strong";

      if( my $padnames_av = $self->padnames_av ) {
         push @outrefs, $no_desc ? ( $strength => $padnames_av ) :
            Devel::MAT::SV::Reference( "the padnames", $strength => $padnames_av );
      }

      foreach my $depth ( 1 .. $maxdepth ) {
         my $pad = $pads->[$depth-1] or next;

         push @outrefs, $no_desc ? ( $strength => $pad ) :
            Devel::MAT::SV::Reference( "pad at depth $depth", $strength => $pad );
      }
   }

   return @outrefs;
}

package Devel::MAT::SV::IO 0.54;
use base qw( Devel::MAT::SV );
__PACKAGE__->register_type( 8 );
use constant $CONSTANTS;
use constant basetype => "IO";

=head1 Devel::MAT::SV::IO

Represents an IO handle; an SV type of C<SVt_PVIO>.

=cut

sub load
{
   my $self = shift;
   my ( $header, $ptrs, $strs ) = @_;
   my $df = $self->df;

   @{$self}{qw( ifileno ofileno )} =
      unpack "$df->{uint_fmt}2", $header;

   defined $_ and $_ == $df->{minus_1} and 
      $_ = -1 for @{$self}{qw( ifileno ofileno )};

   @{$self}{qw( topgv_at formatgv_at bottomgv_at )} =
      @$ptrs;
}

=head2 ifileno

=head2 ofileno

   $ifileno = $io->ifileno;

   $ofileno = $io->ofileno;

Returns the input or output file numbers.

=cut

sub ifileno { my $self = shift; return $self->{ifileno} }
sub ofileno { my $self = shift; return $self->{ofileno} }

sub topgv    { my $self = shift; $self->df->sv_at( $self->{topgv_at}    ) }
sub formatgv { my $self = shift; $self->df->sv_at( $self->{formatgv_at} ) }
sub bottomgv { my $self = shift; $self->df->sv_at( $self->{bottomgv_at} ) }

sub desc { "IO()" }

sub _outrefs
{
   my $self = shift;
   my ( $match, $no_desc ) = @_;

   my @outrefs;

   if( $match & STRENGTH_STRONG ) {
      if( my $gv = $self->topgv ) {
         push @outrefs, $no_desc ? ( strong => $gv ) :
            Devel::MAT::SV::Reference( "the top GV",    strong => $gv );
      }
      if( my $gv = $self->formatgv ) {
         push @outrefs, $no_desc ? ( strong => $gv ) :
            Devel::MAT::SV::Reference( "the format GV", strong => $gv );
      }
      if( my $gv = $self->bottomgv ) {
         push @outrefs, $no_desc ? ( strong => $gv ) :
            Devel::MAT::SV::Reference( "the bottom GV", strong => $gv );
      }
   }

   return @outrefs;
}

package Devel::MAT::SV::LVALUE 0.54;
use base qw( Devel::MAT::SV );
__PACKAGE__->register_type( 9 );
use constant $CONSTANTS;
use constant basetype => "LV";

sub load
{
   my $self = shift;
   my ( $header, $ptrs, $strs ) = @_;
   my $df = $self->df;

   ( $self->{type}, $self->{off}, $self->{len} ) =
      unpack "a1 $df->{uint_fmt}2", $header;

   ( $self->{targ_at} ) =
      @$ptrs;
}

sub lvtype { my $self = shift; return $self->{type} }
sub off    { my $self = shift; return $self->{off} }
sub len    { my $self = shift; return $self->{len} }
sub target { my $self = shift; return $self->df->sv_at( $self->{targ_at} ) }

sub desc { "LVALUE()" }

sub _outrefs
{
   my $self = shift;
   my ( $match, $no_desc ) = @_;

   my @outrefs;

   if( $match & STRENGTH_STRONG and my $sv = $self->target ) {
      push @outrefs, $no_desc ? ( strong => $sv ) :
         Devel::MAT::SV::Reference( "the target", strong => $sv );
   }

   return @outrefs;
}

package Devel::MAT::SV::REGEXP 0.54;
use base qw( Devel::MAT::SV );
use constant basetype => "REGEXP";
__PACKAGE__->register_type( 10 );

sub load {}

sub desc { "REGEXP()" }

sub _outrefs { () }

package Devel::MAT::SV::FORMAT 0.54;
use base qw( Devel::MAT::SV );
use constant basetype => "PVFM";
__PACKAGE__->register_type( 11 );

sub load {}

sub desc { "FORMAT()" }

sub _outrefs { () }

package Devel::MAT::SV::INVLIST 0.54;
use base qw( Devel::MAT::SV );
use constant basetype => "INVLIST";
__PACKAGE__->register_type( 12 );

sub load {}

sub desc { "INVLIST()" }

sub _outrefs { () }

# A hack to compress files
package Devel::MAT::SV::_UNDEFSV 0.54;
use base qw( Devel::MAT::SV::SCALAR );
__PACKAGE__->register_type( 13 );

sub load
{
   my $self = shift;

   bless $self, "Devel::MAT::SV::SCALAR";

   $self->_set_scalar_fields( 0, 0, 0,
      "", 0,
      0,
   );
}

package Devel::MAT::SV::_YESSV 0.54;
use base qw( Devel::MAT::SV::BOOL );
__PACKAGE__->register_type( 14 );

sub load
{
   my $self = shift;

   bless $self, "Devel::MAT::SV::BOOL";

   $self->_set_scalar_fields( 0x01, 1, 1.0,
      "1", 1,
      0,
   );
}

package Devel::MAT::SV::_NOSV 0.54;
use base qw( Devel::MAT::SV::BOOL );
__PACKAGE__->register_type( 15 );

sub load
{
   my $self = shift;

   bless $self, "Devel::MAT::SV::BOOL";

   $self->_set_scalar_fields( 0x01, 0, 0,
      "", 0,
      0,
   );
}

package Devel::MAT::SV::OBJECT 0.54;
use base qw( Devel::MAT::SV );
__PACKAGE__->register_type( 16 );
use constant $CONSTANTS;
use constant basetype => "OBJ";

=head1 Devel::MAT::SV::OBJECT

Represents an object instance; an SV of type C<SVt_PVOBJ>. These are only
present in files from perls with C<feature 'class'>.

=cut

sub load
{
   my $self = shift;
   my ( $header, $ptrs, $strs ) = @_;
   my $df = $self->df;

   my ( $n ) =
      unpack "$df->{uint_fmt} a*", $header;

   my @fields_at = $n ? $df->_read_ptrs( $n ) : ();
   $self->_set_object_fields( \@fields_at );
}

=head2 fields

   @svs = $obj->fields;

Returns all the values of all the fields in a list.

Note that to find the names of the fields you'll have to enquire with the
class

=cut

sub fields
{
   my $self = shift;

   my $n = $self->n_fields;
   return $n unless wantarray;

   my $df = $self->df;
   return map { $df->sv_at( $self->field_at( $_ ) ) } 0 .. $n-1;
}

=head2 field

   $sv = $obj->field( $name_or_fieldix );

Returns the value of the given field; which may be specified by name or
index directly.

=cut

sub field
{
   my $self = shift;
   my ( $name_or_fieldix ) = @_;

   my $fieldix;
   if( $name_or_fieldix =~ m/^\d+$/ ) {
      $fieldix = $name_or_fieldix;
   }
   else {
      $fieldix = $self->blessed->field( $name_or_fieldix )->fieldix;
   }

   return $self->df->sv_at( $self->field_at( $fieldix ) );
}

sub desc
{
   my $self = shift;

   return "OBJ()";
}

sub _outrefs
{
   my $self = shift;
   my ( $match, $no_desc ) = @_;

   my $n = $self->n_fields;

   my @outrefs;

   foreach my $field ( $self->blessed->fields ) {
      my $sv = $self->field( $field->fieldix ) or next;

      my $name = $no_desc ? undef :
         "the " . Devel::MAT::Cmd->format_note( $field->name, 1 ) . " field";
      if( $match & STRENGTH_STRONG ) {
         push @outrefs, $no_desc ? ( strong => $sv ) :
            Devel::MAT::SV::Reference( $name, strong => $sv );
      }
      if( $match & STRENGTH_INDIRECT and $sv->type eq "REF" and !$sv->{magic} and my $rv = $sv->rv ) {
         push @outrefs, $no_desc ? ( indirect => $rv ) :
            Devel::MAT::SV::Reference( $name . " via RV", indirect => $rv );
      }
   }

   return @outrefs;
}

package Devel::MAT::SV::CLASS 0.54;
use base qw( Devel::MAT::SV::STASH );
__PACKAGE__->register_type( 17 );
use constant $CONSTANTS;

use Carp;

use Struct::Dumb 0.07 qw( readonly_struct );
readonly_struct Field => [qw( fieldix name )];

use List::Util qw( first );

=head1 Devel::MAT::SV::CLASS

Represents a class; a sub-type of stash for implementing object classes. These
are only present in files from perls with C<feature 'class'>.

=cut

sub load
{
   my $self = shift;
   my ( $header, $ptrs, $strs ) = @_;
   my $df = $self->df;

   my ( $stash_bytes, $stash_ptrs, $stash_strs ) = @{ $df->{sv_sizes}[6] };

   $self->SUPER::load(
      substr( $header, 0, $stash_bytes, "" ),
      [ splice @$ptrs, 0, $stash_ptrs ],
      [ splice @$strs, 0, $stash_strs ],
   );

   @{$self}{qw( adjust_blocks_at )} =
      @$ptrs;

   while( my $type = $df->_read_u8 ) {
      match( $type : == ) {
         case( 1 ) { push @{ $self->{fields} }, [ $df->_read_uint, $df->_read_str ] }
         default {
            die "TODO: unhandled CLASSx type $type";
         }
      }
   }
}

sub adjust_blocks { my $self = shift; return $self->df->sv_at( $self->{adjust_blocks_at} ) }

=head2 fields

   @fields = $class->fields;

Returns a list of the field definitions of the class, in declaration order.
Each is a structure whose form is given below.

=cut

sub fields
{
   my $self = shift;
   return map { Field( @$_ ) } @{ $self->{fields} };
}

=head2 field

   $field = $class->field( $name_or_fieldix );

Returns the field definition of the given field; which may be specified by
name or index directly. Throws an exception if none such exists.

The returned field is a structure of the following fields:

   $fieldix = $field->fieldix;
   $name    = $field->name;

=head2 maybe_field

   $field = $class->maybe_field( $name_or_fieldix );

I<Since version 0.49.>

Similar to L</field> but returns undef if none such exists.

=cut

sub maybe_field
{
   my $self = shift;
   my ( $name_or_fieldix ) = @_;

   if( $name_or_fieldix =~ m/^\d+$/ ) {
      return first { $_->fieldix == $name_or_fieldix } $self->fields;
   }
   else {
      return first { $_->name eq $name_or_fieldix } $self->fields
   }
}

sub field
{
   my $self = shift;
   return $self->maybe_field( @_ ) // do {
      my ( $name_or_fieldix ) = @_;
      croak "No field at index $name_or_fieldix" if $name_or_fieldix =~ m/^\d+$/;
      croak "No field named '$name_or_fieldix'";
   };
}

sub _outrefs
{
   my $self = shift;
   my ( $match, $no_desc ) = @_;

   my @outrefs = $self->SUPER::_outrefs( @_ );

   if( $match & STRENGTH_STRONG ) {
      if( my $sv = $self->adjust_blocks ) {
         push @outrefs, $no_desc ? ( strong => $sv ) :
            Devel::MAT::SV::Reference( "the ADJUST blocks AV", strong => $sv );
      }
   }

   return @outrefs;
}

# A "SV" type that isn't really an SV, but has many of the same methods. These
# aren't created by core perl, but are used by XS extensions
package Devel::MAT::SV::C_STRUCT 0.54;
use base qw( Devel::MAT::SV );
__PACKAGE__->register_type( 0x7F );
use constant $CONSTANTS;
use constant {
   FIELD_PTR  => 0x00,
   FIELD_BOOL => 0x01,
   FIELD_U8   => 0x02,
   FIELD_U32  => 0x03,
   FIELD_UINT => 0x04,
};
use Carp;
use List::Util qw( first );

=head1 Devel::MAT::SV::C_STRUCT

Represents a C-level c<struct> type.

=cut

sub desc
{
   my $self = shift;
   my $typename = $self->structtype->name;

   "C_STRUCT($typename)";
}

sub load
{
   my $self = shift;
   my ( $fields ) = @_;

   my $df = $self->df;

   my @vals;

   foreach my $field ( @$fields ) {
      push @vals, my $type = $field->type;

      if( $type == FIELD_PTR ) {
         push @vals, $df->_read_ptr;
      }
      elsif( $type == FIELD_BOOL or $type == FIELD_U8 ) {
         push @vals, $df->_read_u8;
      }
      elsif( $type == FIELD_U32 ) {
         push @vals, $df->_read_u32;
      }
      elsif( $type == FIELD_UINT ) {
         push @vals, $df->_read_uint;
      }
      else {
         croak "TODO: load struct field type = $type\n";
      }
   }

   $self->_set_struct_fields( @vals );
}

=head2 fields

   @kvlist = $struct->fields;

Returns an even-sized name/value list of all the field values stored by the
struct; each preceeded by its field type structure.

=cut

sub fields
{
   my $self = shift;

   my $df = $self->df;

   my $fields = $self->structtype->fields;

   return map {
      my $field = $fields->[$_];

      if( $field->type == FIELD_PTR ) {
         $field => $df->sv_at( $self->field( $_ ) )
      }
      else {
         $field => $self->field( $_ );
      }
   } 0 .. $#$fields;
}

=head2 field_named

   $val = $struct->field_named( $name );

Looks for a field whose name is exactly that given, and returns its value.

Throws an exception if the struct has no such field of that name.

=head2 maybe_field_named

   $val = $struct->maybe_field_named( $name );

I<Since version 0.49.>

As L</field_named> but returns C<undef> if there is no such field.

=cut

sub maybe_field_named
{
   my $self = shift;
   my ( $name ) = @_;

   my $fields = $self->structtype->fields;

   defined( my $idx = first { $fields->[$_]->name eq $name } 0 .. $#$fields )
      or return undef;

   my $field = $fields->[$idx];

   if( $field->type == FIELD_PTR ) {
      return $self->df->sv_at( $self->field( $idx ) );
   }
   else {
      return $self->field( $idx );
   }
}

sub field_named
{
   my $self = shift;
   my ( $name ) = @_;

   return $self->maybe_field_named( $name ) // croak "No field named $name";
}

=head2 structtype

   $structtype = $struct->structtype;

Returns a metadata structure describing the type of the struct itself.

Has the following named accessors

=over 4

=item name => STRING

The name of the struct type, as given by the dumpfile.

=item fields => ARRAY[ Field ]

An ARRAY reference containing the definitions of each field in turn

=back

=cut

sub structtype
{
   my $self = shift;
   return $self->df->structtype( $self->structid );
}

sub _outrefs
{
   my $self = shift;
   my ( $match, $no_desc ) = @_;

   return unless $match & STRENGTH_STRONG;

   my $df = $self->df;

   my @outrefs;

   my $fields = $self->structtype->fields;
   foreach my $idx ( 0 .. $#$fields ) {
      my $field = $fields->[$idx];
      $field->type == FIELD_PTR or next; # Is PTR

      my $sv = $df->sv_at( $self->field( $idx ) ) or next;

      push @outrefs, $no_desc ? ( strong => $sv ) :
         Devel::MAT::SV::Reference( $field->name, strong => $sv );
   }

   return @outrefs;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
