package Developer::Dashboard::Pax::TypeAnnotationExtractor;

our $VERSION = '4.45';

use strict;
use warnings;

sub new {
    my ($class, %args) = @_;
    return bless {
        source_text => $args{source_text},
        native_shape => $args{native_shape} // {},
        region_name => $args{region_name} // 'unknown',
    }, $class;
}

sub extract {
    my ($self) = @_;

    my $explicit = $self->_extract_explicit_annotations;
    return $explicit if $explicit;

    return $self->_infer_from_native_shape;
}

# Parse explicit PAX type hints when the source carries them so later compiler
# stages can work from an operator-authored contract instead of pure inference.
sub _extract_explicit_annotations {
    my ($self) = @_;
    my $text = $self->{source_text};
    return if !defined $text || !length $text;

    my @params;
    my $return;

    while ($text =~ /^\s*#\s*pax-type:\s*(.+?)\s*$/mg) {
        my $payload = $1;
        if ($payload =~ /\bparams\s*=\s*([^\n]+?)(?=\s+\w+\s*=|$)/) {
            my $spec = $1;
            for my $item (split /\s*,\s*/, $spec) {
                next if !length $item;
                my ($name, $type) = split /\s*:\s*/, $item, 2;
                next if !defined $name || !defined $type;
                push @params, {
                    name => $name,
                    type => $type,
                };
            }
        }
        if ($payload =~ /\breturn\s*=\s*([A-Za-z_][A-Za-z0-9_:]*)/) {
            $return = $1;
        }
    }

    return if !@params && !defined $return;

    return {
        source => 'comment',
        confidence => 'explicit',
        region_name => $self->{region_name},
        params => \@params,
        return => $return // 'PerlScalar',
    };
}

# Infer the minimal typed contract PAX can safely promise today for native
# shapes it already understands, so the typed IR stage has a consistent entry
# point even when source annotations are absent.
sub _infer_from_native_shape {
    my ($self) = @_;
    my $shape = $self->{native_shape} // {};
    my $kind = $shape->{kind} // '';

    if ($kind eq 'i64_sum_loop' || $kind eq 'i64_masked_mix_accum_loop') {
        return {
            source => 'native_shape_inference',
            confidence => 'inferred',
            region_name => $self->{region_name},
            params => [
                { name => '$left', type => 'i64' },
            ],
            return => 'i64',
        };
    }

    if ($kind eq 'i64_binary_leaf') {
        return {
            source => 'native_shape_inference',
            confidence => 'inferred',
            region_name => $self->{region_name},
            params => [
                { name => '$left', type => 'i64' },
                { name => '$right', type => 'i64' },
            ],
            return => 'i64',
        };
    }

    return {
        source => 'unknown',
        confidence => 'none',
        region_name => $self->{region_name},
        params => [],
        return => 'PerlScalar',
    };
}

1;

__END__

=head1 NAME

Developer::Dashboard::Pax::TypeAnnotationExtractor - extract or infer typed parameter/return contracts for a region

=head1 SYNOPSIS

  use Developer::Dashboard::Pax::TypeAnnotationExtractor;

  my $extractor = Developer::Dashboard::Pax::TypeAnnotationExtractor->new(
      source_text  => $region_source,
      native_shape => $shape,
      region_name  => 'r1',
  );
  my $contract = $extractor->extract;

=head1 DESCRIPTION

C<extract> first scans C<source_text> for explicit C<# pax-type: params=$left:i64,$right:i64 return=i64>
comment annotations (an operator-authored contract, C<confidence =E<gt> 'explicit'>) and, only if none
are found, falls back to C<_infer_from_native_shape>: a small, deliberately conservative table that
knows the parameter/return types of the handful of C<native_shape> kinds PAX's own region selector can
already recognize (C<i64_sum_loop>, C<i64_masked_mix_accum_loop>, C<i64_binary_leaf>), returning
C<confidence =E<gt> 'inferred'>. An unrecognized shape with no explicit annotation returns
C<confidence =E<gt> 'none'> and an untyped C<PerlScalar> contract rather than guessing.

=head1 METHODS

=head2 new, extract

C<new> takes C<source_text>, C<native_shape>, and C<region_name>. C<extract>
takes no arguments and returns the typed-contract hash described above.

=head1 PURPOSE

Gives the typed-IR and native-compilation stages downstream a single,
explicit answer to "what are this region's parameter and return types, and
how sure are we" - explicit source annotations when the author supplied
them, a safe shape-based inference otherwise, and an honest untyped answer
when neither is available, rather than each downstream stage re-deriving
its own guess.

=head1 WHY IT EXISTS

Native compilation (see L<Developer::Dashboard::Pax::Tier1>) and typed IR
construction (see L<Developer::Dashboard::Pax::TypedIR>) both need to know
concrete parameter/return types before they can emit real machine-level
code; Perl itself carries no such types. Centralizing extraction/inference
here, with an explicit C<confidence> field on every result, means a
downstream stage can choose to trust an C<inferred> contract for a loop
shape it already knows how to natively compile while refusing to act on a
C<none> contract for something PAX has never seen before.

=head1 WHEN TO USE

Edit this file when adding a C<# pax-type:> annotation syntax variant, when
teaching the inference table about a new C<native_shape> kind PAX's region
selector has learned to recognize, or when the confidence levels a caller
can rely on need to change.

=head1 HOW TO USE

Construct with the region's raw source text (for explicit-annotation
scanning) and its C<native_shape> hash (for the inference fallback), then
call C<extract> once per region. Always read the returned C<confidence>
field before trusting C<params>/C<return> - a C<none> result means no real
type information was available and callers should treat the region as
untyped rather than natively compile it.

=head1 WHAT USES IT

PAX's guarded-SSA and native compilation pipeline (Tier1's C<compile>) and
the LLVM backend planning path use this to get typed parameter/return
contracts for a region before attempting to emit native code for it.

=head1 EXAMPLES

Example 1:

  my $extractor = Developer::Dashboard::Pax::TypeAnnotationExtractor->new(
      source_text => "# pax-type: params=\$left:i64,\$right:i64 return=i64\n",
  );
  my $contract = $extractor->extract;
  # $contract->{source} eq 'comment', $contract->{confidence} eq 'explicit'

Example 2:

  my $extractor = Developer::Dashboard::Pax::TypeAnnotationExtractor->new(
      native_shape => { kind => 'i64_binary_leaf' },
  );
  my $contract = $extractor->extract;
  # no annotation present, so this falls back to shape inference:
  # $contract->{confidence} eq 'inferred', $contract->{return} eq 'i64'

=cut
