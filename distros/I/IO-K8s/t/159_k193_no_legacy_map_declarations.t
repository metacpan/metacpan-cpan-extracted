#!/usr/bin/env perl
# k193: the legacy `{ X => 1 }` map spelling is gone from the shipped tree; maps
# are declared HashRef[X] (typed) or HashRef[Str] (strict string map).
#
#  1. Registry: after loading every shipped class no field carries
#     is_hash_of_str_lenient, the flag only the legacy `{ Str => 1 }` sets
#     (lib/IO/K8s/Resource.pm). This catches a field that went through the
#     legacy form at load time, in any shipped class.
#  2. Source scan: the lenient flag exists only for Str; `{ Quantity => 1 }`
#     and the object-map forms leave no trace in the registry, so every lib
#     file is scanned for a `k8s name => { X => 1 }` statement. Option hashes
#     (`Int, { minimum => 1 }`) follow a comma and never match.
#  3. maint/crd-drift-check.pl: _structural_signature must no longer equate
#     HashRef[X] with `{ X => 1 }` -- the normalisation existed only because
#     lib still carried the legacy form.
#
# No network, no cluster.

use strict;
use warnings;
use Test::More;
use File::Find;
use FindBin;
use lib "$FindBin::Bin/../lib";

my $root = "$FindBin::Bin/..";

my @files;
find({ no_chdir => 1, wanted => sub { push @files, $File::Find::name if /\.pm\z/ } },
    "$root/lib/IO/K8s");
@files = sort @files;
cmp_ok(scalar @files, '>', 500, 'found the shipped classes') or BAIL_OUT('lib walk failed');

# ---- 1. registry ----------------------------------------------------------
for my $path (@files) {
    (my $mod = $path) =~ s{^\Q$root\E/lib/}{};
    $mod =~ s{/}{::}g;
    $mod =~ s{\.pm\z}{};
    eval "require $mod; 1" or diag "cannot load $mod: $@";
}

subtest 'no shipped field carries the legacy lenient string-map flag' => sub {
    my @lenient;
    my $classes = 0;
    for my $class (sort keys %IO::K8s::Resource::_attr_registry) {
        next unless $class =~ /^IO::K8s::/;
        $classes++;
        my $attrs = $IO::K8s::Resource::_attr_registry{$class};
        for my $attr (sort keys %$attrs) {
            push @lenient, "$class->$attr" if $attrs->{$attr}{is_hash_of_str_lenient};
        }
    }
    cmp_ok($classes, '>', 500, 'registry is populated');
    is_deeply(\@lenient, [], 'no is_hash_of_str_lenient field')
        or diag scalar(@lenient) . ' fields, first: '
            . join ', ', @lenient[0 .. ($#lenient > 9 ? 9 : $#lenient)];
};

# ---- 2. source scan -------------------------------------------------------
my $legacy_re = qr/^\s*k8s\s+(?:\w+|'[^']+'|"[^"]+")\s*=>\s*\{\s*\w+\s*=>\s*1\s*\}/;

subtest 'scan pattern sanity (it must bite, and spare option hashes)' => sub {
    like('k8s labels => { Str => 1 };', $legacy_re, 'legacy Str map matches');
    like('k8s   requests   =>   {Quantity=>1};', $legacy_re, 'legacy Quantity map matches');
    unlike('k8s size => Int, { minimum => 1 };', $legacy_re, 'option hash does not match');
    unlike('k8s labels => HashRef[Str];', $legacy_re, 'new spelling does not match');
};

subtest 'no lib file declares a map as { X => 1 }' => sub {
    my @hits;
    for my $path (@files) {
        open my $fh, '<:raw', $path or die "cannot read $path: $!";
        my $src = do { local $/; <$fh> };
        close $fh;
        my $in_pod = 0;
        my $n      = 0;
        for my $line (split /\n/, $src, -1) {
            $n++;
            if ($line =~ /^=cut\b/) { $in_pod = 0; next }
            if ($line =~ /^=\w/)    { $in_pod = 1; next }
            next if $in_pod || $line =~ /^\s*#/;
            if ($line =~ $legacy_re) {
                (my $rel = $path) =~ s{^\Q$root\E/}{};
                push @hits, "$rel:$n";
            }
        }
    }
    is_deeply(\@hits, [], 'no legacy map declaration')
        or diag scalar(@hits) . ' hits, first: '
            . join ', ', @hits[0 .. ($#hits > 9 ? 9 : $#hits)];
};

# ---- 3. crd-drift-check _structural_signature -----------------------------
my $script = "$root/maint/crd-drift-check.pl";
my $source = do {
    open my $fh, '<:raw', $script or die "cannot read $script: $!";
    local $/;
    <$fh>;
};
my ($sig_sub) = $source =~ /^(sub _structural_signature \{.*?^\})$/ms;
ok($sig_sub, 'found sub _structural_signature') or BAIL_OUT('sub _structural_signature gone');
{
    package T159;
    use strict;
    use warnings;
    ## no critic
    eval "$sig_sub\n1;" or die "cannot eval _structural_signature: $@";
}

sub sig { T159::_structural_signature(@_) }

subtest '_structural_signature no longer equates HashRef[X] with { X => 1 }' => sub {
    isnt(sig("k8s labels => HashRef[Str];\n"), sig("k8s labels => { Str => 1 };\n"),
        'HashRef[Str] differs from { Str => 1 }');
    isnt(sig("k8s requests => HashRef[Quantity];\n"), sig("k8s requests => { Quantity => 1 };\n"),
        'HashRef[Quantity] differs from { Quantity => 1 }');
    isnt(sig("k8s weights => HashRef[Foo];\n"), sig("k8s weights => { Foo => 1 };\n"),
        'object-map spellings differ too');
    is(sig("k8s labels => HashRef[Str];\n"), sig("k8s labels   =>   HashRef[Str];\n"),
        'whitespace-only change still equal');
    isnt(sig("k8s labels => HashRef[Str];\n"), sig("k8s labels => HashRef[Int];\n"),
        'different value types still differ');
};

done_testing;
