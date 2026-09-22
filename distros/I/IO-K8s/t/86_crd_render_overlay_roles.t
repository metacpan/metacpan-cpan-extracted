#!/usr/bin/env perl
# The `with:` lines in maint/crd-render/<Provider>.yaml must agree with the
# roles the shipped class for that Kind actually composes.
#
# Those overlays are the emitter's input: maint/crd-drift-check.pl --render
# copies each Kind's `with` list verbatim into the rendered class. Nothing
# else reads them, so an overlay that names a role the hand-written class
# dropped stays wrong until someone re-renders -- and the render then
# silently reinstates the dropped role. k106 is the worked example:
# splitting MiddlewareBuilder into an HTTP and a TCP role changed
# Traefik::V1alpha1::MiddlewareTCP's `with` line, and the overlay still
# pointed at the HTTP role.
#
# Every Kind named in every overlay resolves to a bundled, shipped class
# through its provider's resource_map (asserted below, so a future overlay
# entry for a Kind this distribution deliberately does not ship fails here
# and gets a decision rather than slipping past the role check).
use strict;
use warnings;
use Test::More;
use FindBin;
use YAML::PP;
use Module::Runtime qw( use_module );

use IO::K8s;

# '' when the module loads, the failure message otherwise -- captured before
# any Test::More call can touch $@.
sub load_error {
    my ($module) = @_;
    return eval { use_module($module); 1 } ? '' : "$@";
}

my $dir = "$FindBin::Bin/../maint/crd-render";
plan skip_all => "no $dir in this checkout" unless -d $dir;

my @overlays = sort glob "$dir/*.yaml";
plan skip_all => "no overlay files in $dir" unless @overlays;

my $yp = YAML::PP->new;

for my $file (@overlays) {
    my ($provider) = $file =~ m{([^/]+)\.yaml\z};
    my $pkg = "IO::K8s::$provider";

    subtest "$provider.yaml: every with: role is composed by its Kind's class" => sub {
        # The provider package is named by the overlay's file name, not by
        # its `base:` key -- Cilium.yaml has no `base:` at all, because
        # render_gvk() derives one per served version.
        my $err = load_error($pkg);
        ok(!$err, "provider $pkg loads") or do { diag($err); return };

        my $data  = $yp->load_file($file);
        my $kinds = $data->{kinds} || {};
        ok(scalar keys %$kinds, "$provider.yaml declares Kinds") or return;

        my $k8s = IO::K8s->new(with => [$pkg]);
        my $map = $pkg->resource_map;

        for my $kind (sort keys %$kinds) {
            # Asserted against the resource_map, not just expand_class:
            # expand_class falls back to IO::K8s::<Kind> for a name it does
            # not know, so only the map answers "does this provider ship a
            # class for that Kind at all".
            ok(exists $map->{$kind}, "$provider.yaml: $kind is in $pkg\'s resource_map")
                or next;

            my $class = eval { $k8s->expand_class($kind) };
            my $resolve_err = $class ? '' : ($@ || "expand_class returned nothing\n");
            ok($class, "$provider.yaml: $kind resolves to a class")
                or do { diag($resolve_err); next };

            my $class_err = load_error($class);
            ok(!$class_err, "$provider.yaml: $kind -> $class loads")
                or do { diag($class_err); next };

            for my $role (@{ $kinds->{$kind}{with} || [] }) {
                my $role_err = load_error($role);
                ok(!$role_err, "$provider.yaml: $kind names role $role, which loads")
                    or do { diag($role_err); next };
                ok($class->does($role),
                    "$provider.yaml: $kind names role $role, and $class composes it");
            }
        }
    };
}

done_testing;
