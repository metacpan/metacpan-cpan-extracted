#!/usr/bin/env perl
# k133 (Weg 1): maint/crd-drift-check.pl's --check gained an ACCEPTED
# DIVERGENCE bucket -- a DIFFERS whose file is listed in the
# accept_structural_divergence exceptions category is reclassified as a
# deliberate, documented divergence: it is not counted as a failing differ
# and does not fail the check. This category is DELIBERATELY separate from
# ignore_cosmetic_differs: it accepts a GENUINE k8s-declaration difference
# (the k55/k120 typed-empty-vs-opaque-hash UUIDSpec case), so it is NOT gated
# on _structural_signature. Its only scope limit is exactness -- provider +
# exact path -- so it can never mask structural drift on any file it does not
# name. This test proves exactly that: a listed file is accepted and does not
# fail the check, while an UNLISTED file with the same kind of structural
# drift still trips as a real DIFFERS and still fails.
#
# As in t/99, the script has no `unless caller` guard and its body runs on
# load, so the relevant subs are lifted out of the source text and evaluated
# on their own -- deliberate, and also an assertion: rename or restructure any
# of them and this test says so instead of quietly testing nothing.
use strict;
use warnings;
use Test::More;
use FindBin;
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use File::Basename qw(dirname);

my $script = "$FindBin::Bin/../maint/crd-drift-check.pl";
ok(-f $script, 'maint/crd-drift-check.pl is there to test')
    or BAIL_OUT('missing maint/crd-drift-check.pl');

my $source = do {
    open my $fh, '<:raw', $script or die "cannot read $script: $!";
    local $/;
    <$fh>;
};

# The functional core -- check_for and everything it calls -- plus the
# file-scoped $DOUBLE_ENCODED_RUN that _slurp closes over.
my ($dblrun) = $source =~ /^(my \$DOUBLE_ENCODED_RUN = qr\{.*?^\}x;)$/ms;
ok($dblrun, 'found $DOUBLE_ENCODED_RUN definition in the script')
    or BAIL_OUT('maint/crd-drift-check.pl no longer defines $DOUBLE_ENCODED_RUN');

my @wanted = qw(
    _slurp _diff_lines _structural_signature
    cosmetic_differ_excepted accept_divergence_excepted unrendered_excepted
    check_for
);
my $code = "$dblrun\n";
for my $name (@wanted) {
    my ($sub) = $source =~ /^(sub \Q$name\E \{.*?^\})$/ms;
    ok($sub, "found sub $name in the script")
        or BAIL_OUT("maint/crd-drift-check.pl no longer defines sub $name");
    $code .= "$sub\n";
}

{
    package T100;
    use strict;
    use warnings;
    use File::Spec;
    use File::Find;
    use Encode;
    ## no critic
    eval "$code\n1;"
        or die "cannot eval the check subs out of the script: $@";
}

# Two emitter-shaped classes that differ only in a k8s DECLARATION -- the
# exact k55/k120 UUIDSpec shape: lib names an empty struct, the render types
# it opaquely. Structurally different, so the cosmetic guard could never
# suppress it; only accept_structural_divergence can.
sub lib_named {
    my ($pkg, $plural, $type) = @_;
    return <<"PM";
package IO::K8s::T100Prov::V1::$pkg;
# ABSTRACT: $pkg, hand-authored wording
our \$VERSION = '1.108';
use IO::K8s::APIObject
    api_version     => 'test.example.com/v1',
    resource_plural => '$plural';

k8s spec => '$type';

1;
PM
}

sub render_opaque {
    my ($pkg, $plural) = @_;
    return <<"PM";
package IO::K8s::T100Prov::V1::$pkg;
# ABSTRACT: $pkg
our \$VERSION = '1.108';
use IO::K8s::APIObject
    api_version     => 'test.example.com/v1',
    resource_plural => '$plural';

k8s spec => { Str => 1 };

1;
PM
}

# Write a { rel => lib_source } tree under a fresh temp lib and run check_for
# against a { rel => render_source } map with the given exceptions. Returns
# the check result.
sub run_check {
    my ($lib_files, $rendered, $exceptions) = @_;
    my $lib = tempdir(CLEANUP => 1);
    for my $rel (keys %$lib_files) {
        my $path = "$lib/$rel";
        make_path(dirname($path));
        open my $fh, '>:encoding(UTF-8)', $path or die "cannot write $path: $!";
        print $fh $lib_files->{$rel};
        close $fh;
    }
    return T100::check_for({ lib => $lib }, 'T100Prov', $rendered, $exceptions);
}

my %exceptions = (
    ignore_cosmetic_differs      => [],
    ignore_unrendered            => [],
    accept_structural_divergence => [
        { provider => 'T100Prov',
          path     => 'IO/K8s/T100Prov/V1/Accepted.pm',
          reason   => 'k133 Weg 1 test entry' },
    ],
);

my $accepted_rel = 'IO/K8s/T100Prov/V1/Accepted.pm';
my $unlisted_rel = 'IO/K8s/T100Prov/V1/Unlisted.pm';
my $same_rel     = 'IO/K8s/T100Prov/V1/Same.pm';

# Scenario 1: only a LISTED file diverges (plus one clean MATCH). The listed
# divergence must be reclassified and the check must NOT fail.
{
    my %lib = (
        $accepted_rel => lib_named('Accepted', 'accepteds',
            '+IO::K8s::T100Prov::V1::AcceptedSpec'),
        $same_rel => render_opaque('Same', 'sames'),
    );
    my %rendered = (
        $accepted_rel => render_opaque('Accepted', 'accepteds'),
        $same_rel     => render_opaque('Same', 'sames'),
    );
    my $c = run_check(\%lib, \%rendered, \%exceptions);
    my %by = map { $_->{path} => $_ } @{ $c->{rows} };

    is($by{$accepted_rel}{status}, 'ACCEPTED DIVERGENCE',
        'a listed structural divergence is reclassified as ACCEPTED DIVERGENCE');
    ok($by{$accepted_rel}{excepted}, 'the accepted row is marked excepted');
    is($by{$accepted_rel}{reason}, 'k133 Weg 1 test entry',
        'the accepted row carries its reason for --verbose');
    ok(@{ $by{$accepted_rel}{diff} // [] },
        'the accepted row keeps its diff so --verbose shows what is accepted');
    is($by{$same_rel}{status}, 'MATCH', 'an identical file still matches');
    ok(!$c->{bad},
        'an accepted divergence alone does not fail --check (exit stays 0)');
}

# Scenario 2: the SAME accepted file plus an UNLISTED file with the identical
# kind of structural drift. The accepted one is still suppressed, but the
# unlisted one must still trip as a real DIFFERS and must still fail the
# check -- the category masks nothing it does not name.
{
    my %lib = (
        $accepted_rel => lib_named('Accepted', 'accepteds',
            '+IO::K8s::T100Prov::V1::AcceptedSpec'),
        $unlisted_rel => lib_named('Unlisted', 'unlisteds',
            '+IO::K8s::T100Prov::V1::UnlistedSpec'),
    );
    my %rendered = (
        $accepted_rel => render_opaque('Accepted', 'accepteds'),
        $unlisted_rel => render_opaque('Unlisted', 'unlisteds'),
    );
    my $c = run_check(\%lib, \%rendered, \%exceptions);
    my %by = map { $_->{path} => $_ } @{ $c->{rows} };

    is($by{$accepted_rel}{status}, 'ACCEPTED DIVERGENCE',
        'the listed file is still accepted alongside an unlisted differ');
    is($by{$unlisted_rel}{status}, 'DIFFERS',
        'an UNLISTED structural drift still surfaces as a real DIFFERS');
    ok(!$by{$unlisted_rel}{excepted},
        'the unlisted differ is not marked excepted');
    ok($c->{bad},
        'an unlisted structural drift still fails --check -- the category masks nothing it does not name');
}

# The matcher itself is strictly provider + exact path (mirrors t/99's
# cosmetic_differ_excepted contract): the file-exactness that scopes the
# whole category.
subtest 'accept_divergence_excepted matches provider + path, honours narrowing' => sub {
    my @entries = (
        { provider => 'ExternalSecrets',
          path     => 'IO/K8s/ExternalSecrets/V1alpha1/UUID.pm',
          reason   => 'accepted here' },
        { path => 'IO/K8s/Anywhere/V1/Loose.pm', reason => 'any provider' },
    );

    my ($ok, $reason) = T100::accept_divergence_excepted(
        'ExternalSecrets', 'IO/K8s/ExternalSecrets/V1alpha1/UUID.pm', \@entries);
    ok($ok, 'a listed provider+path is accepted');
    is($reason, 'accepted here', 'the reason comes back with the match');

    ok(!(T100::accept_divergence_excepted(
            'VolumeSnapshot', 'IO/K8s/ExternalSecrets/V1alpha1/UUID.pm', \@entries))[0],
        'a provider-narrowed entry does not match a different provider');

    ok((T100::accept_divergence_excepted(
            'SomeProvider', 'IO/K8s/Anywhere/V1/Loose.pm', \@entries))[0],
        'an entry with no provider matches in any provider');

    ok(!(T100::accept_divergence_excepted(
            'ExternalSecrets', 'IO/K8s/ExternalSecrets/V1alpha1/NotListed.pm', \@entries))[0],
        'an unlisted path is not accepted -- nothing broad is masked');
};

done_testing;
