#!/usr/bin/env perl
# Registry guard test — catches missing or misrouted attribute target
# classes at build time, before they surface as "Can't locate ... in @INC"
# at inflate time. This is the test that would have caught karr tickets #1
# (apiextensions.k8s.io/v1 union types), #2 (KubeAggregator prefix did not
# match) and #3 (StorageVersionSpec was never shipped) together, rather
# than one at a time on the consumer side.
#
# Strategy: after every shipped class has been loaded, walk the global
# attribute registry and assert every referenced class is loadable. We do
# not care HOW it is loaded — that is Resource.pm's job — only that the
# symbol is findable. This catches:
#
#   * a declared class that was never shipped  (ticket #3)
#   * a class shipped under one namespace but declared under another
#     because _expand_class fell through to the default expansion
#     (ticket #2, before the prefix-match fix)
#   * a self-inflating union class that the attribute side still
#     references via the type spec (ticket #1)
#
# The registry is built lazily by `k8s` DSL calls at module load time, so
# we must load every class first. `t/02_compile_all.t` already walks the
# tree; this test reuses the same path so we can run in isolation.

use strict;
use warnings;
use Test::More;

use File::Find;
use lib 'lib';

# Load every shipped .pm so the registry is populated.
# Collect both the absolute path (for require) and the module name (for
# the loadability check) from one walk.
my @pm_paths;
my @module_names;
find(
    {
        wanted   => sub { push @pm_paths, $File::Find::name if /\.pm$/ },
        no_chdir => 1,
    },
    'lib/IO/K8s',
);

for my $path (sort @pm_paths) {
    (my $mod = $path) =~ s|^lib/||;
    $mod =~ s|/|::|g;
    $mod =~ s|\.pm$||;
    require_ok($mod);
    push @module_names, $mod;
}

my %loadable = map { $_ => 1 } @module_names;

my $registry = \%IO::K8s::Resource::_attr_registry;

# Inline-generated structs (Resource.pm `_generate_inline_struct`) are not
# shipped as .pm files — they materialise as packages when the parent class
# is loaded. We accept any target that has a `k8s` function in its symbol
# table, regardless of whether there's a .pm on disk for it.
sub is_inline_struct_available {
    my ($target) = @_;
    return 1 if $loadable{$target};
    no strict 'refs';
    return defined &{"${target}::k8s"};
}

my @missing;
for my $class (sort keys %$registry) {
    for my $attr (sort keys %{$registry->{$class}}) {
        my $info = $registry->{$class}{$attr};
        my $target = $info->{class} or next;          # scalar / array-of-str
        next if $target =~ /^(Str|Int|Bool|Quantity|Time|IntOrStr)\b/;
        next if is_inline_struct_available($target);

        push @missing, sprintf("  %-70s  %s  -> %s", "$class->$attr",
            ($info->{is_array_of_objects} ? '[obj]'
              : $info->{is_hash_of_objects}  ? '{obj}'
              : $info->{is_object}           ? 'obj'
              : '???'),
            $target);
    }
}

if (@missing) {
    diag("Attribute targets that are declared but not loadable:");
    diag($_) for @missing;
}

is(scalar @missing, 0,
    'every k8s-attribute target class is loadable (would have caught karr tickets #1, #2, #3)')
    or BAIL_OUT(scalar(@missing) . " attribute target(s) not loadable");

done_testing;