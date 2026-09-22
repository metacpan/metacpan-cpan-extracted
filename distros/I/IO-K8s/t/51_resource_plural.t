#!/usr/bin/env perl
# k33: IO::K8s::Role::APIObject::resource_plural used to return undef
# for every shipped Kubernetes class, so consumers that need Kind -> plural
# (RBAC speaks plurals, the API speaks Kinds) fell back to an lc+"s"
# heuristic. A wrong plural there is indistinguishable from a denied
# permission, so the plurals now come from tables generated off the upstream
# spec's REST paths (maint/spec-resource-plural-gen.pl) rather than from any
# string transformation.
#
# k36 added the second tier. The lookup is:
#
#   1. "$api_version/$Kind"  -- the exact GVK, still authoritative
#   2. "$group|$Kind"        -- the GroupResource, for Kinds on API tracks
#                               upstream no longer serves
#
# Tier 2 is not a loosening of tier 1's key for the consumer this exists
# for: RBAC addresses resources by apiGroups + resources, with no version in
# the rule at all, so the plural is a property of the group and the Kind.
# The generator only emits a tier-2 entry where every version of that group
# in the spec agrees on the plural, so no value in it is invented.
#
# What these tests claim:
#   * the non-derivable plurals are right (this is the whole point -- every
#     one of them breaks lc+"s")
#   * the fallback is keyed on group+Kind, never on the bare Kind: a Kind
#     that belongs to another group does not borrow that group's plural
#   * the 15 classes on dropped API tracks now resolve, through tier 2
#   * anything without a plural in either tier stays undef and is never
#     guessed
#   * an explicit per-class resource_plural (CRD import, AutoGen option, a
#     hand-written sub) still wins over both tiers
#   * class_namespaces subclasses inherit through @ISA, like api_version
#
# Pure local fixtures -- no network, no cluster.

use strict;
use warnings;
use Test::More;
use FindBin;
use File::Find;
use lib "$FindBin::Bin/../lib";

use IO::K8s;
use Role::Tiny ();

# ----------------------------------------------------------------------------
# Test-local classes
# ----------------------------------------------------------------------------

# A class_namespaces subclass of a built-in, plus a second level, to
# exercise the recursive @ISA walk. Seeded into %INC so IO::K8s::load_class
# treats them as loaded.
{
    package My::K8s::Api::Core::V1::Pod;
    use parent qw(IO::K8s::Api::Core::V1::Pod);
    BEGIN { $INC{'My/K8s/Api/Core/V1/Pod.pm'} = __FILE__ }
}
{
    # -norequire: the parent is this same file, compiled just above.
    package My::K8s::Deep::Pod;
    use parent -norequire, 'My::K8s::Api::Core::V1::Pod';
}

# A subclass that declares its own plural: an explicit value must beat the
# one it would otherwise inherit from the built-in table.
{
    package My::K8s::Override::Pod;
    use parent qw(IO::K8s::Api::Core::V1::Pod);
    sub resource_plural { 'mypods' }
}

# A CRD declared the documented way (lib/IO/K8s.pm CRD contract).
{
    package My::K8s::StaticWebSite;
    use IO::K8s::APIObject
        api_version     => 'homelab.example.com/v1',
        resource_plural => 'staticwebsites';
    k8s spec => { Str => 1 };
}

# A CRD that declares no plural at all: still undef, never guessed.
{
    package My::K8s::Unplural;
    use IO::K8s::APIObject api_version => 'homelab.example.com/v1';
    k8s spec => { Str => 1 };
}

# k36 tripwire. This class does not exist upstream and never will: it
# puts the Kind "Ingress" in the batch group, on a version nobody serves.
# Both tiers must miss it -- "batch/v1alpha9/Ingress" is not a served GVK
# and "batch|Ingress" is not a GroupResource. A fallback keyed on the bare
# Kind would happily hand it networking.k8s.io's "ingresses", which is the
# exact simplification this file exists to catch. Its name is in the
# IO::K8s::Api:: namespace because that is the only namespace
# _api_version_from_class() derives a group from; it is seeded into %INC so
# nothing ever tries to load a file for it.
{
    package IO::K8s::Api::Batch::V1alpha9::Ingress;
    BEGIN { $INC{'IO/K8s/Api/Batch/V1alpha9/Ingress.pm'} = __FILE__ }
    use IO::K8s::APIObject;
}

# ----------------------------------------------------------------------------

subtest 'plurals that no lc+"s" heuristic can produce' => sub {
    my %expected = (
        'IO::K8s::Api::Core::V1::Endpoints'           => 'endpoints',
        'IO::K8s::Api::Networking::V1::NetworkPolicy' => 'networkpolicies',
        'IO::K8s::Api::Networking::V1::Ingress'       => 'ingresses',
        'IO::K8s::Api::Scheduling::V1::PriorityClass' => 'priorityclasses',
        'IO::K8s::Api::Storage::V1::StorageClass'     => 'storageclasses',
        'IO::K8s::Api::Core::V1::ComponentStatus'     => 'componentstatuses',
        'IO::K8s::Api::Storage::V1::CSIStorageCapacity' => 'csistoragecapacities',
        'IO::K8s::Api::Node::V1::RuntimeClass'        => 'runtimeclasses',
        'IO::K8s::Api::Resource::V1::DeviceClass'     => 'deviceclasses',
        'IO::K8s::Api::Networking::V1::IPAddress'     => 'ipaddresses',
    );

    for my $class (sort keys %expected) {
        IO::K8s->load_class($class);
        my $want = $expected{$class};
        is($class->resource_plural, $want, "$class -> $want (class method)");

        # And the heuristic this replaces really would have been wrong.
        my $naive = lc($class->kind) . 's';
        isnt($naive, $want, "  lc+'s' would have produced '$naive'");
    }
};

subtest 'plurals a heuristic happens to get right are still correct' => sub {
    my %expected = (
        'IO::K8s::Api::Core::V1::Pod'          => 'pods',
        'IO::K8s::Api::Core::V1::Secret'       => 'secrets',
        'IO::K8s::Api::Apps::V1::Deployment'   => 'deployments',
        'IO::K8s::Api::Apps::V1::StatefulSet'  => 'statefulsets',
        'IO::K8s::Api::Batch::V1::CronJob'     => 'cronjobs',
        'IO::K8s::Api::Rbac::V1::ClusterRole'  => 'clusterroles',
        'IO::K8s::Api::Rbac::V1::RoleBinding'  => 'rolebindings',
    );
    for my $class (sort keys %expected) {
        IO::K8s->load_class($class);
        is($class->resource_plural, $expected{$class},
            "$class -> $expected{$class}");
    }
};

subtest 'instance method agrees with class method' => sub {
    IO::K8s->load_class('IO::K8s::Api::Networking::V1::Ingress');
    my $ingress = IO::K8s::Api::Networking::V1::Ingress->new;
    is($ingress->resource_plural, 'ingresses', 'instance -> ingresses');
    is($ingress->resource_plural, IO::K8s::Api::Networking::V1::Ingress->resource_plural,
        'instance and class method agree');
};

subtest 'both tiers are group-qualified, neither is a bare Kind' => sub {
    IO::K8s->load_class('IO::K8s::Api::Core::V1::Event');
    IO::K8s->load_class('IO::K8s::Api::Events::V1::Event');

    is(IO::K8s::Api::Core::V1::Event->api_version, 'v1', 'core Event apiVersion');
    is(IO::K8s::Api::Events::V1::Event->api_version, 'events.k8s.io/v1',
        'events.k8s.io Event apiVersion');

    # Same Kind name, two groups. Tier 1 keys them apart by apiVersion and
    # tier 2 keys them apart by group -- core is the empty group, not a
    # missing one -- so the k33 disambiguation survives the widening.
    is(IO::K8s::Api::Core::V1::Event->resource_plural, 'events',
        'core/v1 Event -> events');
    is(IO::K8s::Api::Events::V1::Event->resource_plural, 'events',
        'events.k8s.io/v1 Event -> events');

    # The assertion that catches a fallback "simplified" to a bare Kind:
    # Ingress is a networking.k8s.io GroupResource, so a batch-group Ingress
    # on an unserved version must miss both tiers.
    is(IO::K8s::Api::Batch::V1alpha9::Ingress->api_version, 'batch/v1alpha9',
        'synthetic tripwire class sits in the batch group');
    is(IO::K8s::Api::Networking::V1::Ingress->resource_plural, 'ingresses',
        'Ingress does have a plural -- in networking.k8s.io');
    is(IO::K8s::Api::Batch::V1alpha9::Ingress->resource_plural, undef,
        'batch/v1alpha9 Ingress -> undef (a bare-Kind fallback would say "ingresses")');
};

subtest 'k36: Kinds on API tracks upstream dropped resolve by group' => sub {
    # Every one of these is a shipped class whose exact GVK is not in
    # upstream v1.36 any more, so tier 1 misses. Tier 2 answers with the
    # plural its served same-group siblings use -- read off a real
    # collection path in the same spec, not derived from the Kind.
    my %expected = (
        'IO::K8s::Api::Admissionregistration::V1alpha1::ValidatingAdmissionPolicy'
            => 'validatingadmissionpolicies',
        'IO::K8s::Api::Admissionregistration::V1alpha1::ValidatingAdmissionPolicyBinding'
            => 'validatingadmissionpolicybindings',
        'IO::K8s::Api::Admissionregistration::V1beta1::ValidatingAdmissionPolicy'
            => 'validatingadmissionpolicies',
        'IO::K8s::Api::Admissionregistration::V1beta1::ValidatingAdmissionPolicyBinding'
            => 'validatingadmissionpolicybindings',
        'IO::K8s::Api::Authentication::V1alpha1::SelfSubjectReview'
            => 'selfsubjectreviews',
        'IO::K8s::Api::Authentication::V1beta1::SelfSubjectReview'
            => 'selfsubjectreviews',
        'IO::K8s::Api::Coordination::V1alpha1::LeaseCandidate'
            => 'leasecandidates',
        'IO::K8s::Api::Flowcontrol::V1beta3::FlowSchema'
            => 'flowschemas',
        'IO::K8s::Api::Flowcontrol::V1beta3::PriorityLevelConfiguration'
            => 'prioritylevelconfigurations',
        'IO::K8s::Api::Resource::V1alpha3::DeviceClass'
            => 'deviceclasses',
        'IO::K8s::Api::Resource::V1alpha3::ResourceClaim'
            => 'resourceclaims',
        'IO::K8s::Api::Resource::V1alpha3::ResourceClaimTemplate'
            => 'resourceclaimtemplates',
        'IO::K8s::Api::Resource::V1alpha3::ResourceSlice'
            => 'resourceslices',
        'IO::K8s::Api::Storage::V1alpha1::VolumeAttributesClass'
            => 'volumeattributesclasses',
        'IO::K8s::Api::Storagemigration::V1alpha1::StorageVersionMigration'
            => 'storageversionmigrations',
    );

    is(scalar(keys %expected), 15, 'all 15 classes named in k36 are covered');

    for my $class (sort keys %expected) {
        IO::K8s->load_class($class);
        is($class->resource_plural, $expected{$class},
            "$class -> $expected{$class}");
    }

    # The tier-2 answer is the same one the served sibling gets from tier 1;
    # that is what makes it upstream data rather than a guess.
    for my $pair (
        [ 'IO::K8s::Api::Resource::V1alpha3::ResourceClaim',
          'IO::K8s::Api::Resource::V1::ResourceClaim' ],
        [ 'IO::K8s::Api::Flowcontrol::V1beta3::FlowSchema',
          'IO::K8s::Api::Flowcontrol::V1::FlowSchema' ],
        [ 'IO::K8s::Api::Storage::V1alpha1::VolumeAttributesClass',
          'IO::K8s::Api::Storage::V1::VolumeAttributesClass' ],
    ) {
        my ($dropped, $served) = @$pair;
        IO::K8s->load_class($_) for $dropped, $served;
        is($dropped->resource_plural, $served->resource_plural,
            "$dropped agrees with its served sibling");
    }
};

subtest 'subresources have no plural of their own' => sub {
    # pods/eviction, deployments/scale, serviceaccounts/token: RBAC names
    # these as a subresource of their parent, never as a resource. They are
    # filtered out of both generated tables by trailing path segment, so
    # neither tier can hand them anything.
    my %subresource = (
        'IO::K8s::Api::Policy::V1::Eviction'             => 'Eviction',
        'IO::K8s::Api::Autoscaling::V1::Scale'           => 'Scale',
        'IO::K8s::Api::Authentication::V1::TokenRequest' => 'TokenRequest',
    );
    for my $class (sort keys %subresource) {
        IO::K8s->load_class($class);
        is($class->resource_plural, undef, "$subresource{$class} -> undef");
    }
};

subtest 'embedded template types have no plural' => sub {
    # k45: these carry metadata but compose IO::K8s::Resource, not
    # IO::K8s::Role::APIObject -- upstream's OpenAPI schema for them has no
    # apiVersion/kind, only metadata and spec, so TO_JSON must not stamp a
    # GVK into them. Without Role::APIObject they have no resource_plural
    # method at all (not one that resolves to undef). Note resource.k8s.io
    # does have a ResourceClaimTemplate GroupResource; the *Spec type next
    # to it is a different Kind string and must not pick it up.
    for my $class (qw(
        IO::K8s::Api::Core::V1::PodTemplateSpec
        IO::K8s::Api::Core::V1::PersistentVolumeClaimTemplate
        IO::K8s::Api::Batch::V1::JobTemplateSpec
        IO::K8s::Api::Resource::V1::ResourceClaimTemplateSpec
        IO::K8s::Api::Resource::V1alpha3::ResourceClaimTemplateSpec
        IO::K8s::Api::Resource::V1beta1::ResourceClaimTemplateSpec
        IO::K8s::Api::Resource::V1beta2::ResourceClaimTemplateSpec
    )) {
        IO::K8s->load_class($class);
        ok(!$class->can('resource_plural'),
            "$class -> no resource_plural method");
    }

    IO::K8s->load_class('IO::K8s::Api::Resource::V1::ResourceClaimTemplate');
    is(IO::K8s::Api::Resource::V1::ResourceClaimTemplate->resource_plural,
        'resourceclaimtemplates',
        'the real ResourceClaimTemplate next to them still resolves');
};

subtest 'explicit per-class resource_plural wins' => sub {
    # 1. Shipped CRD class (Cilium declares its own at import time)
    IO::K8s->load_class('IO::K8s::Cilium::V2alpha1::CiliumEndpointSlice');
    is(IO::K8s::Cilium::V2alpha1::CiliumEndpointSlice->resource_plural,
        'ciliumendpointslices', 'Cilium CRD keeps its declared plural');
    IO::K8s->load_class('IO::K8s::Cilium::V2::CiliumLoadBalancerIPPool');
    is(IO::K8s::Cilium::V2::CiliumLoadBalancerIPPool->new->resource_plural,
        'ciliumloadbalancerippools', 'Cilium CRD instance too');

    # 2. User CRD via the documented import parameters
    is(My::K8s::StaticWebSite->resource_plural, 'staticwebsites',
        'user CRD import parameter');

    # 3. A hand-written override on a subclass of a built-in beats the
    #    plural the subclass would otherwise inherit through @ISA.
    is(IO::K8s::Api::Core::V1::Pod->resource_plural, 'pods', 'parent still pods');
    is(My::K8s::Override::Pod->resource_plural, 'mypods',
        'subclass override wins over the inherited table value');

    # 4. A CRD that declares nothing stays undef -- never guessed from the
    #    class name.
    is(My::K8s::Unplural->resource_plural, undef,
        'CRD without a declared plural -> undef');
};

subtest 'AutoGen resource_plural option wins' => sub {
    require IO::K8s::AutoGen;
    my %defs = (
        'com.example.v1.Widget' => {
            type       => 'object',
            properties => { spec => { type => 'object' } },
        },
    );
    my $class = IO::K8s::AutoGen::get_or_generate(
        'com.example.v1.Widget', $defs{'com.example.v1.Widget'}, \%defs,
        'IO::K8s::_AUTOGEN',
        api_version     => 'example.com/v1',
        kind            => 'Widget',
        resource_plural => 'widgeten',
    );
    is($class->resource_plural, 'widgeten', 'AutoGen option installs the plural');
};

subtest 'class_namespaces subclasses inherit through @ISA' => sub {
    is(My::K8s::Api::Core::V1::Pod->api_version, 'v1',
        'subclass inherits api_version (existing behaviour)');
    is(My::K8s::Api::Core::V1::Pod->resource_plural, 'pods',
        'subclass inherits the plural the same way');
    is(My::K8s::Deep::Pod->resource_plural, 'pods',
        'two levels up the @ISA chain still resolves');

    # And through the real resolution path a consumer uses.
    my $k8s = IO::K8s->new(class_namespaces => ['My::K8s']);
    my $class = $k8s->expand_class('Pod');
    is($class, 'My::K8s::Api::Core::V1::Pod', 'expand_class picks the subclass');
    is($class->resource_plural, 'pods', 'and it reports the built-in plural');

    my $obj = $k8s->new_object('Pod');
    isa_ok($obj, 'My::K8s::Api::Core::V1::Pod', 'new_object');
    is($obj->resource_plural, 'pods', 'inflated subclass instance -> pods');
};

subtest 'coverage over the default resource map' => sub {
    # Regression guard for a bad regeneration: every short name in the
    # built-in map must resolve to a plural except the three subresources.
    # Unchanged by k36 -- the short names all point at served versions,
    # so they were already answered by tier 1.
    my $map = IO::K8s->default_resource_map;
    my @short = grep { !m{/} } sort keys %$map;

    my @without;
    for my $kind (@short) {
        my $class = IO::K8s->expand_class($kind);
        IO::K8s->load_class($class);
        push @without, $kind unless defined $class->resource_plural;
    }

    is_deeply(\@without, [qw(Eviction Scale TokenRequest)],
        'exactly the three subresources have no plural');
    is(scalar(@short) - scalar(@without), 77,
        '77 of the 80 short names carry an upstream plural');
};

subtest 'coverage over every shipped upstream API class' => sub {
    # The guard k36 is actually about: the whole shipped surface the
    # generated tables are supposed to cover, not just the short names in
    # the default resource map. Anything in one of the three namespaces
    # _api_version_from_class() understands, composing Role::APIObject.
    #
    # k45: the seven embedded template types (PodTemplateSpec,
    # JobTemplateSpec, PersistentVolumeClaimTemplate, and the four
    # ResourceClaimTemplateSpec versions) now compose IO::K8s::Resource
    # instead of Role::APIObject -- upstream's schema for them carries no
    # apiVersion/kind -- so they no longer satisfy does('...Role::APIObject')
    # and drop out of @api entirely, rather than landing in @without.
    my $lib = "$FindBin::Bin/../lib";
    my @classes;
    find(sub {
        return unless /\.pm\z/;
        my $path = $File::Find::name;
        $path =~ s{\A\Q$lib\E/}{};
        $path =~ s{\.pm\z}{};
        $path =~ s{/}{::}g;
        push @classes, $path;
    }, $lib);

    my @api;
    for my $class (sort @classes) {
        next unless $class =~ /\AIO::K8s::(?:Api|ApiextensionsApiserver|KubeAggregator)::/;
        IO::K8s->load_class($class);
        next if Role::Tiny->is_role($class);
        next unless $class->can('does') && $class->does('IO::K8s::Role::APIObject');
        push @api, $class;
    }

    my @without = grep { !defined $_->resource_plural } @api;

    is(scalar @api, 124, '124 shipped upstream API object classes (113 before the v1.37 sync, karr k72)');
    is(scalar(@api) - scalar(@without), 121,
        '121 of them carry an upstream plural (110 before the v1.37 sync, karr k72)');

    # The exact miss list: just the 3 subresources now. The 7 embedded
    # template types are no longer Role::APIObject classes at all, so they
    # never reach @api to be filtered into @without.
    is_deeply(\@without, [qw(
        IO::K8s::Api::Authentication::V1::TokenRequest
        IO::K8s::Api::Autoscaling::V1::Scale
        IO::K8s::Api::Policy::V1::Eviction
    )], 'exactly the subresources stay undef');
};

done_testing;
