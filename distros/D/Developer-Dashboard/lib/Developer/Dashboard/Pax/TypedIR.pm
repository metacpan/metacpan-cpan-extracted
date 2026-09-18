package Developer::Dashboard::Pax::TypedIR;

our $VERSION = '4.45';

use strict;
use warnings;

sub new {
    my ($class, %args) = @_;
    return bless {}, $class;
}

sub lower_unit {
    my ($self, $ssa_unit, %args) = @_;
    my $annotations = $args{type_annotations} || {};
    my $shape = $ssa_unit->{native_shape} // $ssa_unit->{source}{native_shape} // {};
    my $kind = $shape->{kind} // '';

    return {
        status => 'untyped',
        reason => 'no native shape available for typed lowering',
    } if !$kind;

    my $op = _typed_op_for_shape($shape);
    return {
        status => 'untyped',
        reason => 'native shape has no typed IR lowering',
    } if !$op;

    return {
        status => 'typed_ir',
        region_id => $ssa_unit->{region_id},
        region_name => $ssa_unit->{region_name},
        source => $annotations->{source} // 'unknown',
        confidence => $annotations->{confidence} // 'none',
        params => $annotations->{params} || [],
        return => $annotations->{return} // 'PerlScalar',
        ops => [
            {
                op => $op,
                shape_kind => $kind,
            },
        ],
    };
}

sub _typed_op_for_shape {
    my ($shape) = @_;
    my $kind = $shape->{kind} // '';
    return 'typed_i64_binary_leaf' if $kind eq 'i64_binary_leaf';
    return 'typed_i64_sum_loop' if $kind eq 'i64_sum_loop';
    return 'typed_i64_masked_mix_accum_loop' if $kind eq 'i64_masked_mix_accum_loop';
    return;
}

1;

__END__

=head1 NAME

Developer::Dashboard::Pax::TypedIR - lower a native-capable SSA unit into one typed intermediate op

=head1 SYNOPSIS

  use Developer::Dashboard::Pax::TypedIR;

  my $lowerer = Developer::Dashboard::Pax::TypedIR->new;
  my $ir = $lowerer->lower_unit($ssa_unit, type_annotations => $contract);

=head1 DESCRIPTION

C<lower_unit> takes an SSA unit's C<native_shape> and maps it, via
C<_typed_op_for_shape>, onto one of a small fixed set of typed op names
(C<typed_i64_binary_leaf>, C<typed_i64_sum_loop>,
C<typed_i64_masked_mix_accum_loop>) - the same three shape kinds
L<Developer::Dashboard::Pax::Tier1> and
L<Developer::Dashboard::Pax::TypeAnnotationExtractor> already recognize.
When a shape is present but has no matching typed op, or no shape is
present at all, the result is C<status =E<gt> 'untyped'> with a reason
rather than a guess; a match instead returns C<status =E<gt> 'typed_ir'>
carrying the region's id/name, the caller-supplied type contract
(C<source>/C<confidence>/C<params>/C<return> from
C<TypeAnnotationExtractor>), and a one-element C<ops> list naming the typed
op and the shape kind it came from.

=head1 METHODS

=head2 new, lower_unit

C<new> takes no arguments. C<lower_unit> takes one SSA unit hash plus a
C<type_annotations> hash (typically the result of
L<Developer::Dashboard::Pax::TypeAnnotationExtractor/extract>) and returns
the typed-IR hash described above.

=head1 PURPOSE

Gives PAX's native-compilation and LLVM-backend-planning stages one small,
explicit typed instruction to act on instead of the raw, untyped SSA unit -
this is the boundary where "we recognize this shape and know its types"
becomes a concrete op name the backends can dispatch on.

=head1 WHY IT EXISTS

Guarded SSA construction and native-shape detection happen upstream of any
notion of concrete types; a native/LLVM backend, in contrast, needs a
typed instruction before it can emit real machine code. This module is the
single place that bridges the two, so a backend never has to re-derive "is
this shape one we know how to type" from the untyped SSA unit itself, and
adding support for a new shape means teaching exactly this module (and its
paired L<TypeAnnotationExtractor>) about it, not every backend
individually.

=head1 WHEN TO USE

Edit this file when adding a new typed op for a native shape
L<Developer::Dashboard::Pax::TypeAnnotationExtractor> or
L<Developer::Dashboard::Pax::Tier1> has learned to recognize, or when the
fields carried on a C<typed_ir> result need to change.

=head1 HOW TO USE

Call C<lower_unit> once per SSA unit after type annotations have already
been extracted (see L<Developer::Dashboard::Pax::TypeAnnotationExtractor>);
pass that extractor's result as C<type_annotations>. Always check
C<status> before reading C<ops> - an C<untyped> result carries no C<ops>
entry and the caller should fall back to interpreted execution for that
region rather than attempt native compilation.

=head1 WHAT USES IT

PAX's native compilation and LLVM backend planning paths call this after
region selection and type annotation extraction, to get the one typed op
those backends dispatch native-code emission on.

=head1 EXAMPLES

Example 1:

  my $lowerer = Developer::Dashboard::Pax::TypedIR->new;
  my $ir = $lowerer->lower_unit(
      { region_id => 'r1', native_shape => { kind => 'i64_binary_leaf' } },
      type_annotations => { source => 'native_shape_inference', confidence => 'inferred', return => 'i64' },
  );
  # $ir->{status} eq 'typed_ir', $ir->{ops}[0]{op} eq 'typed_i64_binary_leaf'

Example 2:

  my $ir = $lowerer->lower_unit({ region_id => 'r2', native_shape => {} });
  # no shape kind at all: $ir->{status} eq 'untyped'

=cut
