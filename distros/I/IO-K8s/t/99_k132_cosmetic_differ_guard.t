#!/usr/bin/env perl
# k132: maint/crd-drift-check.pl's --check can reclassify a DIFFERS as
# COSMETIC when the file is listed in ignore_cosmetic_differs -- but ONLY
# when its structural content (the k8s declarations plus the identity/scope
# import and roles) still matches the emitter render after whitespace is
# normalised away. That guard is what keeps a documented cosmetic exception
# from ever hiding a real change: change a field's type, required-ness, enum,
# name, api_version or roles and the file must trip as a real DIFFERS again,
# however the ABSTRACT/POD/whitespace happen to differ.
#
# _structural_signature and cosmetic_differ_excepted carry that contract.
# The script has no `unless caller` guard and its main body runs on load, so
# each sub is lifted out of the source text and evaluated on its own (as
# t/89 does for _slurp) -- deliberate, and also an assertion: rename or
# restructure either sub and this test says so instead of quietly testing
# nothing.
use strict;
use warnings;
use Test::More;
use FindBin;

my $script = "$FindBin::Bin/../maint/crd-drift-check.pl";
ok(-f $script, 'maint/crd-drift-check.pl is there to test')
    or BAIL_OUT('missing maint/crd-drift-check.pl');

my $source = do {
    open my $fh, '<:raw', $script or die "cannot read $script: $!";
    local $/;
    <$fh>;
};

my ($sig_sub) = $source =~ /^(sub _structural_signature \{.*?^\})$/ms;
ok($sig_sub, 'found sub _structural_signature in the script')
    or BAIL_OUT('maint/crd-drift-check.pl no longer defines sub _structural_signature');

my ($exc_sub) = $source =~ /^(sub cosmetic_differ_excepted \{.*?^\})$/ms;
ok($exc_sub, 'found sub cosmetic_differ_excepted in the script')
    or BAIL_OUT('maint/crd-drift-check.pl no longer defines sub cosmetic_differ_excepted');

{
    package T99;
    use strict;
    use warnings;
    ## no critic
    eval "$sig_sub\n$exc_sub\n1;"
        or die "cannot eval the guard subs out of the script: $@";
}

# The emitter's shape for a small top-level CRD class: k8s declarations
# grouped above their POD, tight =>-alignment, one-line qw() enum.
my $render = <<'PM';
package IO::K8s::Demo::V1::Widget;
# ABSTRACT: Widget is a thing that does stuff, at length, in the upstream words
our $VERSION = '1.108';
use IO::K8s::APIObject
    api_version     => 'demo.example.com/v1',
    resource_plural => 'widgets';

k8s size    => Int;
k8s enabled => Bool;
k8s mode    => Str, { required => 'schema', enum => [qw(fast slow steady)] };

=attr size

size, one wording.

=cut

1;
PM

# The hand-maintained lib shape: shorter ABSTRACT, a =description block, an
# extra explanatory comment, the k8s lines interleaved with their POD, looser
# alignment, and the qw() enum wrapped across several lines. All cosmetic.
my $lib_cosmetic = <<'PM';
package IO::K8s::Demo::V1::Widget;
# ABSTRACT: Widget is a thing
our $VERSION = '1.108';
use IO::K8s::APIObject
    api_version     => 'demo.example.com/v1',
    resource_plural => 'widgets';

=description

Widget is a thing that does stuff.

=cut

# a retained explanatory comment (k110-style)
k8s size => Int;

=attr size

size, a different wording that wraps
across two lines.

=cut

k8s enabled => Bool;

k8s mode => Str, { required => 'schema', enum => [qw(
    fast slow steady
)] };

1;
PM

is(
    T99::_structural_signature($render),
    T99::_structural_signature($lib_cosmetic),
    'ABSTRACT / POD / comment / alignment / qw-wrap differences do not change the structural signature'
);

# Each structural mutation must break the signature match -- these are the
# name/type/required/enum/scope/roles the guard exists to protect.
my %structural = (
    'a changed field type (Int -> Str)' =>
        do { my $s = $render; $s =~ s/k8s size    => Int;/k8s size    => Str;/; $s },
    'a dropped required option' =>
        do { my $s = $render; $s =~ s/, \{ required => 'schema', enum/, { enum/; $s },
    'a changed enum member set' =>
        do { my $s = $render; $s =~ s/qw\(fast slow steady\)/qw(fast slow)/; $s },
    'a renamed field' =>
        do { my $s = $render; $s =~ s/k8s enabled => Bool;/k8s active => Bool;/; $s },
    'a changed api_version (scope)' =>
        do { my $s = $render; $s =~ s{demo.example.com/v1}{demo.example.com/v2}; $s },
    'an added role (with)' =>
        do { my $s = $render; $s =~ s/(resource_plural => 'widgets';\n)/$1\nwith 'IO::K8s::Role::Namespaced';\n/; $s },
    'an object type vs an opaque hash (the k120 UUIDSpec shape)' =>
        do { my $s = $render; $s =~ s/k8s size    => Int;/k8s spec => '+IO::K8s::Demo::V1::WidgetSpec';/;
             my $t = $render; $t =~ s/k8s size    => Int;/k8s spec => { Str => 1 };/;
             [$s, $t] },
);

for my $what (sort keys %structural) {
    my $val = $structural{$what};
    my ($a, $b) = ref $val eq 'ARRAY' ? @$val : ($render, $val);
    isnt(
        T99::_structural_signature($a),
        T99::_structural_signature($b),
        "structural change is visible to the guard: $what"
    );
}

subtest 'cosmetic_differ_excepted matches provider + path, honours narrowing' => sub {
    my @entries = (
        { provider => 'VolumeSnapshot', path => 'IO/K8s/VolumeSnapshot/V1/VolumeSnapshotInfo.pm',
          reason => 'cosmetic here' },
        { path => 'IO/K8s/Anywhere/V1/Loose.pm', reason => 'any provider' },
    );

    my ($ok, $reason) = T99::cosmetic_differ_excepted(
        'VolumeSnapshot', 'IO/K8s/VolumeSnapshot/V1/VolumeSnapshotInfo.pm', \@entries);
    ok($ok, 'a listed provider+path is excepted');
    is($reason, 'cosmetic here', 'the reason comes back with the match');

    ok(!(T99::cosmetic_differ_excepted(
            'ExternalSecrets', 'IO/K8s/VolumeSnapshot/V1/VolumeSnapshotInfo.pm', \@entries))[0],
        'a provider-narrowed entry does not match a different provider');

    ok((T99::cosmetic_differ_excepted(
            'SomeProvider', 'IO/K8s/Anywhere/V1/Loose.pm', \@entries))[0],
        'an entry with no provider matches in any provider');

    ok(!(T99::cosmetic_differ_excepted(
            'VolumeSnapshot', 'IO/K8s/VolumeSnapshot/V1/NotListed.pm', \@entries))[0],
        'an unlisted path is not excepted');
};

done_testing;
