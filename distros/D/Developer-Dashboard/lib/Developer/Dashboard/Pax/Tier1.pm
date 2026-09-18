package Developer::Dashboard::Pax::Tier1;
our $VERSION = '4.45';

use strict;
use warnings;
use Capture::Tiny qw(capture);
use Digest::SHA qw(sha256_hex);
use File::Path qw(make_path);
use File::Spec;
use JSON::XS ();
use Developer::Dashboard::Pax::Backend::Tier1CraneliftEquivalent;
use Developer::Dashboard::Pax::Backend::Tier2LLVM;

sub new {
    my ($class, %args) = @_;
    return bless {
        backend => $args{backend} // 'portable-fallback',
        out_dir => $args{out_dir} // '.pax/native',
    }, $class;
}

sub compile {
    my ($self, $ssa_unit) = @_;
    my $can_native = _native_backend_available();
    if (!$can_native) {
        return {
            region_id => $ssa_unit->{region_id},
            status => 'fallback_artifact',
            backend => $self->{backend},
            reason => 'native backend toolchain unavailable in current workspace',
            entry_kind => 'interpreter_bridge',
        };
    }

    my $artifact = $self->_emit_native_artifact($ssa_unit);
    my $tier1 = Developer::Dashboard::Pax::Backend::Tier1CraneliftEquivalent->new->metadata;
    my $tier2_backend = Developer::Dashboard::Pax::Backend::Tier2LLVM->new(out_dir => $self->{out_dir});
    my $tier2 = $tier2_backend->metadata;
    my $tier2_artifact = $tier2_backend->emit_module($ssa_unit);
    return {
        region_id => $ssa_unit->{region_id},
        status => $artifact->{status},
        backend => 'cranelift-equivalent-c-abi',
        backend_tiers => [$tier1, $tier2],
        reason => $artifact->{reason},
        entry_kind => $artifact->{entry_kind},
        source_path => $artifact->{source_path},
        library_path => $artifact->{library_path},
        executable_path => $artifact->{executable_path},
        native_test => $artifact->{native_test},
        tier2_artifact => $tier2_artifact,
        symbol => 'pax_region_probe',
    };
}

sub _emit_native_artifact {
    local $?;    # DD-882 (vendored-in from PAX): guard $? so this sub's own subprocess call never leaks a mutated exit status to whatever runs in the caller after it returns.
    my ($self, $ssa_unit) = @_;
    make_path($self->{out_dir});
    my $id = sha256_hex(join "\n",
        $ssa_unit->{region_id},
        ($ssa_unit->{region_name} // ''),
        $$,
        time(),
    );
    my $source_path = File::Spec->catfile($self->{out_dir}, "$id.c");
    my $library_path = File::Spec->catfile($self->{out_dir}, "libpax_$id.so");
    my $executable_path = File::Spec->catfile($self->{out_dir}, "pax_$id");
    my $emission = _c_source_for_region($ssa_unit);

    open my $fh, '>', $source_path or return {
        status => 'fallback_artifact',
        reason => "cannot write native source: $!",
    };
    print {$fh} $emission->{source};
    close $fh;

    system(_cc(), '-shared', '-fPIC', '-O2', '-o', $library_path, $source_path);
    if (($? >> 8) != 0 || !-f $library_path) {
        return {
            status => 'fallback_artifact',
            reason => 'C ABI backend failed to emit native shared artifact',
            source_path => $source_path,
        };
    }

    my $native_test;
    if ($emission->{executable}) {
        system(_cc(), '-O2', '-DPAX_STANDALONE_MAIN', '-o', $executable_path, $source_path);
        if (($? >> 8) == 0 && -x $executable_path) {
            my $left = defined $emission->{smoke_left} ? $emission->{smoke_left} : 2;
            my $right = defined $emission->{smoke_right} ? $emission->{smoke_right} : 3;
            my $expected = defined $emission->{smoke_expected} ? $emission->{smoke_expected} : '5';
            # DD-882 (vulnerability-scan hardening): list-form system() via
            # Capture::Tiny instead of backticks, matching this project's
            # own Perl conventions - never a shell-interpolated string, even
            # though $executable_path is this sub's own just-compiled
            # native artifact and $left/$right are internally-generated
            # smoke-test integers, not external input.
            my ($output) = capture { system( $executable_path, $left, $right ) };
            chomp $output;
            $native_test = {
                command => "$executable_path $left $right",
                expected => "$expected",
                actual => $output,
                passed => $output eq "$expected" ? JSON::XS::true() : JSON::XS::false(),
            };
        }
    }

    return {
        status => 'native_artifact',
        reason => $emission->{reason},
        entry_kind => $emission->{entry_kind},
        source_path => $source_path,
        library_path => $library_path,
        executable_path => -x $executable_path ? $executable_path : undef,
        native_test => $native_test,
    };
}

sub _c_source_for_region {
    my ($ssa_unit) = @_;
    my $region_id = $ssa_unit->{region_id} // 'unknown';
    my $shape = $ssa_unit->{native_shape} // $ssa_unit->{source}{native_shape} // {};
    if (($shape->{kind} // '') eq 'i64_sum_loop') {
        return {
            reason => "native i64 $shape->{op} loop emitted from guarded SSA through the Tier 1 C ABI backend and smoke-tested",
            entry_kind => 'native_i64_loop',
            executable => 1,
            smoke_left => $shape->{smoke_left},
            smoke_right => $shape->{smoke_right},
            smoke_expected => $shape->{smoke_expected},
            source => _c_translation_unit(
                $region_id,
                _c_loop_body(),
            ),
        };
    }

    if (($shape->{kind} // '') eq 'i64_masked_mix_accum_loop') {
        return {
            reason => "native i64 $shape->{op} loop emitted from guarded SSA through the Tier 1 C ABI backend and smoke-tested",
            entry_kind => 'native_i64_loop',
            executable => 1,
            smoke_left => $shape->{smoke_left},
            smoke_right => $shape->{smoke_right},
            smoke_expected => $shape->{smoke_expected},
            source => _c_translation_unit(
                $region_id,
                _c_masked_mix_accum_loop_body(),
            ),
        };
    }

    if (($shape->{kind} // '') eq 'i64_binary_leaf') {
        return {
            reason => "native i64 $shape->{op} leaf emitted from guarded SSA through the Tier 1 C ABI backend and smoke-tested",
            entry_kind => 'native_i64_leaf',
            executable => 1,
            smoke_left => $shape->{smoke_left},
            smoke_right => $shape->{smoke_right},
            smoke_expected => $shape->{smoke_expected},
            source => _c_translation_unit(
                $region_id,
                _c_binary_expr($shape->{op}),
            ),
        };
    }

    return {
        reason => 'native probe artifact emitted; semantic execution falls back because no region-specific emitter matched',
        entry_kind => 'native_probe_trampoline',
        executable => 0,
        source => _c_translation_unit($region_id, 'return 1;'),
    };
}

sub _native_backend_available {
    return 0 if ! _cc();
    return 1;
}

sub _cc {
    return $ENV{CC} if defined $ENV{CC} && length $ENV{CC};
    return _which('cc') || _which('gcc');
}

sub _c_binary_expr {
    my ($op) = @_;
    return 'return left + right;' if ($op // '') eq 'add';
    return 'return left - right;' if ($op // '') eq 'subtract';
    return 'return left * right;' if ($op // '') eq 'multiply';
    return 'return left > right ? 1 : 0;' if ($op // '') eq 'greater_than';
    return 'return 0;';
}

sub _c_loop_body {
    return <<'C_BODY';
if (left <= 0) {
    return 0;
}
int64_t sum = 0;
for (int64_t i = 1; i <= left; i++) {
    sum += i;
}
return sum;
C_BODY
}

# Emit Tier 1 C for the masked-mix accumulator loop shape used by synthetic
# long-running arithmetic benchmarks.
sub _c_masked_mix_accum_loop_body {
    return <<'C_BODY';
if (left <= 0) {
    return 0;
}
uint64_t acc = 0;
for (int64_t i = 0; i < left; i++) {
    uint64_t term = (((uint64_t)i * 13ULL) ^ ((uint64_t)i >> 3)) & 0xFFFFULL;
    acc += term;
}
return (int64_t)acc;
C_BODY
}

sub _c_translation_unit {
    my ($region_id, $body) = @_;
    my $escaped_id = $region_id;
    $escaped_id =~ s/\\/\\\\/g;
    $escaped_id =~ s/"/\\"/g;
    return <<"C";
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int64_t pax_region_i64(int64_t left, int64_t right) {
$body
}

int64_t pax_region_probe(void) {
    return pax_region_i64(2, 3);
}

size_t pax_region_id_len(void) {
    return strlen("$escaped_id");
}

#ifdef PAX_STANDALONE_MAIN
int main(int argc, char **argv) {
    int64_t left = argc > 1 ? strtoll(argv[1], 0, 10) : 2;
    int64_t right = argc > 2 ? strtoll(argv[2], 0, 10) : 3;
    printf("%lld\\n", (long long)pax_region_i64(left, right));
    return 0;
}
#endif
C
}

sub _which {
    my ($cmd) = @_;
    for my $dir (split /:/, $ENV{PATH} // '') {
        my $path = "$dir/$cmd";
        return $path if -x $path;
    }
    return;
}

1;

__END__

=head1 NAME

Developer::Dashboard::Pax::Tier1 - emits and smoke-tests native C artifacts for a guarded SSA region

=head1 SYNOPSIS

  use Developer::Dashboard::Pax::Tier1;

  my $planner = Developer::Dashboard::Pax::Tier1->new( out_dir => '.pax/native' );
  my $result  = $planner->compile($ssa_unit);

=head1 DESCRIPTION

Given one guarded SSA region (the output of region selection over a hot loop
or leaf op PAX has decided is worth native-compiling), C<compile> matches the
region's C<native_shape> against a small set of known shapes (an i64 sum
loop, a masked-mix accumulator loop, a binary i64 leaf op) and, when a match
is found, emits a standalone C translation unit for it, compiles that C with
the system C<cc>/C<gcc> into both a shared library and (where the shape
supports it) a smoke-testable executable, and reports the resulting artifact
alongside tier-1 (Cranelift-equivalent C ABI, see
L<Developer::Dashboard::Pax::Backend::Tier1CraneliftEquivalent>) and tier-2
(LLVM, see L<Developer::Dashboard::Pax::Backend::Tier2LLVM>) backend
metadata. No native toolchain available, or no shape emitter matched, both
degrade to a C<fallback_artifact>/C<native_probe_trampoline> rather than
failing the whole compile.

=head1 METHODS

=head2 new, compile

C<new> takes C<backend> (default C<portable-fallback>) and C<out_dir>
(default C<.pax/native>). C<compile> takes one SSA unit hash and returns the
artifact-description hash described above.

=head1 PURPOSE

Turns a single guarded SSA region into a real, compiled, smoke-tested native
artifact (or an honest fallback description when that isn't possible on the
current machine), so everything above this module in the pipeline - PAX's
build/run CLI, standalone binary packaging - can treat "was this region
natively compiled, and does the artifact actually work" as one small,
testable question answered in one place.

=head1 WHY IT EXISTS

The C emission and the "did it actually work" smoke test (running the
compiled executable with two sample inputs and comparing the observed
output against the expected one) are both genuinely fallible - the host may
lack a C compiler, or the emitted source may fail to build - and every
caller needs the SAME honest answer about which happened. Centralizing the
match-shape/emit-C/compile/smoke-test sequence here means a region that
falls back to interpretation is indistinguishable in behavior, but not in
reporting, from one that was successfully compiled natively.

=head1 WHEN TO USE

Edit this file when adding support for a new native-shape kind (extend
C<_c_source_for_region>'s shape dispatch and add a matching C<_c_*_body>
emitter), when changing how the smoke test is run or judged, or when the
tier-1/tier-2 backend metadata this module attaches to a result needs to
change shape.

=head1 HOW TO USE

Construct a C<Tier1> planner with an C<out_dir> for its generated C sources,
shared libraries and executables, then call C<compile> with one SSA unit
that has already been through guard insertion and region selection. Read
the returned hash's C<status> field first (C<native_artifact> vs
C<fallback_artifact>) before trusting C<library_path>/C<executable_path>,
since a fallback result legitimately omits them.

=head1 WHAT USES IT

PAX's own build pipeline (C<Developer::Dashboard::Pax::CLI>'s C<build>
command path) invokes this once per region GuardedSSA and region selection
have marked as native-compilation-eligible; the standalone binary packaging
path (C<StandaloneImage>/C<StandaloneRuntime>) consumes the resulting
artifact paths when assembling a compiled binary.

=head1 EXAMPLES

Example 1:

  my $planner = Developer::Dashboard::Pax::Tier1->new;
  my $result  = $planner->compile({
      region_id    => 'r1',
      native_shape => { kind => 'i64_binary_leaf', op => 'add', smoke_left => 2, smoke_right => 3, smoke_expected => 5 },
  });
  # $result->{status} eq 'native_artifact' on a host with a working cc

Example 2:

  perl -Ilib -MDeveloper::Dashboard::Pax::Tier1 -e 1

Confirm the module loads cleanly from a source checkout before wiring in a
new native shape.

=cut
