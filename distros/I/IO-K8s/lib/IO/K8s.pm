package IO::K8s;
# ABSTRACT: Objects representing things found in the Kubernetes API

use v5.10;
use Moo;
use Module::Runtime qw(require_module);
use JSON::MaybeXS;
use Scalar::Util ();
use namespace::clean;

our $VERSION = '1.006';

# Track which classes we've auto-generated
my %_autogen_cache;

# Default resource map - maps short names to class paths relative to IO::K8s
my %DEFAULT_RESOURCE_MAP = (
    # Core API resources
    Binding => 'Api::Core::V1::Binding',
    ComponentStatus => 'Api::Core::V1::ComponentStatus',
    ConfigMap => 'Api::Core::V1::ConfigMap',
    Endpoints => 'Api::Core::V1::Endpoints',
    Event => 'Api::Core::V1::Event',
    LimitRange => 'Api::Core::V1::LimitRange',
    Namespace => 'Api::Core::V1::Namespace',
    Node => 'Api::Core::V1::Node',
    PersistentVolume => 'Api::Core::V1::PersistentVolume',
    PersistentVolumeClaim => 'Api::Core::V1::PersistentVolumeClaim',
    Pod => 'Api::Core::V1::Pod',
    PodTemplate => 'Api::Core::V1::PodTemplate',
    ReplicationController => 'Api::Core::V1::ReplicationController',
    ResourceQuota => 'Api::Core::V1::ResourceQuota',
    Secret => 'Api::Core::V1::Secret',
    Service => 'Api::Core::V1::Service',
    ServiceAccount => 'Api::Core::V1::ServiceAccount',
    # Apps
    ControllerRevision => 'Api::Apps::V1::ControllerRevision',
    DaemonSet => 'Api::Apps::V1::DaemonSet',
    Deployment => 'Api::Apps::V1::Deployment',
    ReplicaSet => 'Api::Apps::V1::ReplicaSet',
    StatefulSet => 'Api::Apps::V1::StatefulSet',
    # Batch
    CronJob => 'Api::Batch::V1::CronJob',
    Job => 'Api::Batch::V1::Job',
    # Networking
    Ingress => 'Api::Networking::V1::Ingress',
    IngressClass => 'Api::Networking::V1::IngressClass',
    NetworkPolicy => 'Api::Networking::V1::NetworkPolicy',
    # Storage
    CSIDriver => 'Api::Storage::V1::CSIDriver',
    CSINode => 'Api::Storage::V1::CSINode',
    CSIStorageCapacity => 'Api::Storage::V1::CSIStorageCapacity',
    StorageClass => 'Api::Storage::V1::StorageClass',
    VolumeAttachment => 'Api::Storage::V1::VolumeAttachment',
    # Authorization
    LocalSubjectAccessReview => 'Api::Authorization::V1::LocalSubjectAccessReview',
    SelfSubjectAccessReview => 'Api::Authorization::V1::SelfSubjectAccessReview',
    SelfSubjectRulesReview => 'Api::Authorization::V1::SelfSubjectRulesReview',
    SubjectAccessReview => 'Api::Authorization::V1::SubjectAccessReview',
    # Authentication
    SelfSubjectReview => 'Api::Authentication::V1::SelfSubjectReview',
    TokenRequest => 'Api::Authentication::V1::TokenRequest',
    TokenReview => 'Api::Authentication::V1::TokenReview',
    # RBAC
    ClusterRole => 'Api::Rbac::V1::ClusterRole',
    ClusterRoleBinding => 'Api::Rbac::V1::ClusterRoleBinding',
    Role => 'Api::Rbac::V1::Role',
    RoleBinding => 'Api::Rbac::V1::RoleBinding',
    # Policy
    Eviction => 'Api::Policy::V1::Eviction',
    PodDisruptionBudget => 'Api::Policy::V1::PodDisruptionBudget',
    # Autoscaling
    HorizontalPodAutoscaler => 'Api::Autoscaling::V2::HorizontalPodAutoscaler',
    Scale => 'Api::Autoscaling::V1::Scale',
    # Certificates
    CertificateSigningRequest => 'Api::Certificates::V1::CertificateSigningRequest',
    # Coordination
    Lease => 'Api::Coordination::V1::Lease',
    # Discovery
    EndpointSlice => 'Api::Discovery::V1::EndpointSlice',
    # Scheduling
    PriorityClass => 'Api::Scheduling::V1::PriorityClass',
    # Node
    RuntimeClass => 'Api::Node::V1::RuntimeClass',
    # Flowcontrol
    FlowSchema => 'Api::Flowcontrol::V1::FlowSchema',
    PriorityLevelConfiguration => 'Api::Flowcontrol::V1::PriorityLevelConfiguration',
    # Admissionregistration
    MutatingWebhookConfiguration => 'Api::Admissionregistration::V1::MutatingWebhookConfiguration',
    ValidatingAdmissionPolicy => 'Api::Admissionregistration::V1::ValidatingAdmissionPolicy',
    ValidatingAdmissionPolicyBinding => 'Api::Admissionregistration::V1::ValidatingAdmissionPolicyBinding',
    ValidatingWebhookConfiguration => 'Api::Admissionregistration::V1::ValidatingWebhookConfiguration',
    # Extension APIs (different base paths)
    CustomResourceDefinition => 'ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::CustomResourceDefinition',
    APIService => 'KubeAggregator::Pkg::Apis::Apiregistration::V1::APIService',
);

has json => (is => 'ro', default => sub {
    return JSON::MaybeXS->new(utf8 => 1, canonical => 1);
});

# Resource map - can be customized per instance
# Returns a copy so add() can safely mutate without affecting other instances
has resource_map => (
    is => 'ro',
    lazy => 1,
    default => sub { +{ %DEFAULT_RESOURCE_MAP } },
);

# OpenAPI spec for auto-generating unknown types
has openapi_spec => (
    is => 'ro',
    predicate => 1,
);

# External resource map providers to merge at construction time
# e.g. with => ['IO::K8s::Cilium'] or with => [IO::K8s::Cilium->new]
has with => (
    is => 'ro',
    default => sub { [] },
);

# User namespaces to search for pre-built classes (checked before IO::K8s::)
# e.g. ['MyProject::K8s'] will look for MyProject::K8s::HelmChart before IO::K8s::...
has class_namespaces => (
    is => 'ro',
    default => sub { [] },
);

# Internal: unique autogen namespace for this instance (isolated, collision-free)
has _autogen_namespace => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;
        # Create unique identifier based on object address
        my $id = sprintf('%x', 0 + $self);
        return "IO::K8s::_AUTOGEN_$id";
    },
);

# Class method to get default resource map
sub default_resource_map { \%DEFAULT_RESOURCE_MAP }

sub BUILD {
    my ($self) = @_;
    $self->add(@{$self->with}) if @{$self->with};
}

# Merge external resource maps into this instance
# Accepts: class names, objects with resource_map(), or plain hashrefs
sub add {
    my ($self, @providers) = @_;
    my $map = $self->resource_map;

    for my $provider (@providers) {
        my $ext_map;
        if (ref $provider eq 'HASH') {
            $ext_map = $provider;
        } else {
            my $obj = ref $provider ? $provider : do {
                require_module($provider); $provider->new;
            };
            $ext_map = $obj->resource_map;
        }

        for my $kind (keys %$ext_map) {
            my $class_path = $ext_map->{$kind};

            # Resolve full class name for api_version lookup
            my $full_class = $class_path =~ /^\+/
                ? substr($class_path, 1) : "IO::K8s::$class_path";

            # Try to load the class and get its api_version
            my $api_version;
            if (_class_exists($full_class) && $full_class->can('api_version')) {
                $api_version = $full_class->api_version;
            }

            if (exists $map->{$kind}) {
                # COLLISION: short name already taken
                # Ensure the original entry also has a domain-qualified key
                my $orig_path = $map->{$kind};
                my $orig_class = $orig_path =~ /^\+/
                    ? substr($orig_path, 1) : "IO::K8s::$orig_path";
                if (_class_exists($orig_class) && $orig_class->can('api_version')) {
                    my $orig_av = $orig_class->api_version;
                    if ($orig_av && !exists $map->{"$orig_av/$kind"}) {
                        $map->{"$orig_av/$kind"} = $orig_path;
                    }
                }
                # New entry: domain-qualified only (no short name)
                if ($api_version) {
                    $map->{"$api_version/$kind"} = $class_path;
                }
            } else {
                # No collision: register short name
                $map->{$kind} = $class_path;
                # Also register domain-qualified
                if ($api_version) {
                    $map->{"$api_version/$kind"} = $class_path;
                }
            }
        }
    }
    return $self;
}

# Expand short class name to full class path
# Supports:
#   'Pod'                    -> lookup in resource_map -> IO::K8s::Api::Core::V1::Pod
#   'Api::Core::V1::Pod'     -> IO::K8s::Api::Core::V1::Pod
#   'IO::K8s::...'           -> returned as-is
#   '+MyApp::K8s::Resource'  -> MyApp::K8s::Resource (+ prefix = full class name)
#
# Search order:
#   1. User's class_namespaces (if class exists)
#   2. IO::K8s built-in (resource_map or relative path)
#   3. Auto-generate from openapi_spec (if available)
sub expand_class {
    my ($self, $class, $api_version) = @_;

    # +FullClassName - strip + and use as-is
    return substr($class, 1) if $class =~ /^\+/;

    # Already a full IO::K8s class name - return as-is
    return $class if $class =~ /^IO::K8s::/;

    # Already a loaded class (e.g. CRD class passed by ref) - return as-is
    return $class if _class_exists($class);

    my $map = ref($self) ? $self->resource_map : \%DEFAULT_RESOURCE_MAP;

    # Domain-qualified string: 'cilium.io/v2/NetworkPolicy'
    if ($class =~ m{/}) {
        if (my $mapped = $map->{$class}) {
            return $mapped =~ /^\+/ ? substr($mapped, 1) : "IO::K8s::$mapped";
        }
        return undef;
    }

    # Short name + api_version disambiguation: 'NetworkPolicy' + 'cilium.io/v2'
    if ($api_version) {
        my $qualified = "$api_version/$class";
        if (my $mapped = $map->{$qualified}) {
            return $mapped =~ /^\+/ ? substr($mapped, 1) : "IO::K8s::$mapped";
        }
    }

    # Short name like "Pod" - look up in resource_map
    if (my $mapped = $map->{$class}) {
        # Mapped value with + prefix = full class name
        return substr($mapped, 1) if $mapped =~ /^\+/;

        my $rel_path = $mapped;

        # 1. Check user's class_namespaces first
        if (ref($self)) {
            for my $ns (@{$self->class_namespaces}) {
                my $user_class = "${ns}::${rel_path}";
                return $user_class if _class_exists($user_class);
            }
        }

        # 2. Check IO::K8s built-in
        my $builtin_class = 'IO::K8s::' . $rel_path;
        return $builtin_class if _class_exists($builtin_class);

        # 3. Try auto-generation if we have openapi_spec
        if (ref($self) && $self->has_openapi_spec) {
            my $autogen = $self->_autogen_class_for($class);
            return $autogen if $autogen;
        }

        # Fall back to IO::K8s:: path (might not exist, but let load_class handle error)
        return $builtin_class;
    }

    # Not in resource_map - might be a CRD or relative path
    # 1. Check user's class_namespaces
    if (ref($self)) {
        for my $ns (@{$self->class_namespaces}) {
            my $user_class = "${ns}::${class}";
            return $user_class if _class_exists($user_class);
        }
    }

    # 2. Check IO::K8s relative path
    my $builtin_class = 'IO::K8s::' . $class;
    return $builtin_class if _class_exists($builtin_class);

    # 3. Try auto-generation for unknown types
    if (ref($self) && $self->has_openapi_spec) {
        my $autogen = $self->_autogen_class_for($class);
        return $autogen if $autogen;
    }

    # Fall back
    return $builtin_class;
}

# Check if a class exists (is loaded or can be loaded)
sub _class_exists {
    my ($class) = @_;
    # Check if already loaded
    return 1 if $class->can('new');
    # Try to load it
    eval { require_module($class) };
    return !$@;
}

# Auto-generate a class from OpenAPI spec for unknown type
sub _autogen_class_for {
    my ($self, $kind) = @_;

    return unless $self->has_openapi_spec;

    my $spec = $self->openapi_spec;
    my $defs = $spec->{definitions} // {};

    # Find the definition for this kind
    my $def_name = $self->_find_definition_for_kind($kind, $defs);
    return unless $def_name;

    # Check cache first
    my $cache_key = $self->_autogen_namespace . '::' . $def_name;
    return $_autogen_cache{$cache_key} if $_autogen_cache{$cache_key};

    # Generate the class
    require IO::K8s::AutoGen;
    my $class = IO::K8s::AutoGen::get_or_generate(
        $def_name,
        $defs->{$def_name},
        $defs,
        $self->_autogen_namespace,
    );

    $_autogen_cache{$cache_key} = $class;
    return $class;
}

# Find OpenAPI definition name for a given kind
sub _find_definition_for_kind {
    my ($self, $kind, $defs) = @_;

    # Direct match by kind name at end of definition
    for my $def_name (keys %$defs) {
        my $def = $defs->{$def_name};
        # Check x-kubernetes-group-version-kind
        if (my $gvk_list = $def->{'x-kubernetes-group-version-kind'}) {
            for my $gvk (@$gvk_list) {
                if ($gvk->{kind} eq $kind) {
                    return $def_name;
                }
            }
        }
        # Also check if definition name ends with the kind
        if ($def_name =~ /\.\Q$kind\E$/) {
            return $def_name;
        }
    }

    return undef;
}

sub load_class {
    my ($self, $class) = @_;
    require_module $class;
}

sub json_to_object {
    my ($self, $class_or_json, $json) = @_;

    # If only one argument, auto-detect class from kind
    if (!defined $json) {
        return $self->inflate($class_or_json);
    }

    # Two arguments: class and JSON
    my $class = $self->expand_class($class_or_json);
    my $struct = $self->json->decode($json);
    return $self->struct_to_object($class, $struct);
}

sub struct_to_object {
    my ($self, $class_or_struct, $params) = @_;

    # If only one argument (a hashref), auto-detect class from kind
    if (!defined $params && ref($class_or_struct) eq 'HASH') {
        return $self->inflate($class_or_struct);
    }

    # Two arguments: class and params
    my $class = $self->expand_class($class_or_struct);

    # Already an object of the right class — pass through as-is
    return $params if Scalar::Util::blessed($params) && $params->isa($class);

    $self->load_class($class);
    my $inflated = $self->_inflate_struct($class, $params);
    return $class->new(%$inflated);
}

sub inflate {
    my ($self, $data) = @_;

    # Accept both JSON string and hashref
    my $struct = ref($data) eq 'HASH' ? $data : $self->json->decode($data);

    my $kind = $struct->{kind}
        or die "Cannot inflate: missing 'kind' field in data";
    my $api_version = $struct->{apiVersion};

    my $class = $self->expand_class($kind, $api_version);
    $self->load_class($class);
    my $inflated = $self->_inflate_struct($class, $struct);
    return $class->new(%$inflated);
}

sub new_object {
    my ($self, $short_class, @args) = @_;

    # Support:
    #   ->new_object('Pod', { ... })
    #   ->new_object('Pod', foo => 'bar')
    #   ->new_object('Pod', { ... }, 'cilium.io/v2')  # with api_version
    my ($params, $api_version);
    if (@args >= 2 && ref($args[0]) eq 'HASH' && !ref($args[1])) {
        ($params, $api_version) = @args;
    } elsif (@args == 1 && ref($args[0]) eq 'HASH') {
        $params = $args[0];
    } else {
        $params = { @args };
    }

    my $class = $self->expand_class($short_class, $api_version);
    return $self->struct_to_object($class, $params);
}

sub _inflate_struct {
    my ($self, $class, $params) = @_;

    # Blessed objects should be caught by struct_to_object before reaching
    # here.  If one does slip through (defensive), extract its data rather
    # than silently returning {} which would create an empty object.
    if (Scalar::Util::blessed($params)) {
        return $params->TO_JSON if $params->can('TO_JSON');
        return {};
    }

    return {} unless ref $params eq 'HASH';

    # Opaque fields that should be passed through as-is (complex JSON structures)
    my %opaque_fields = map { $_ => 1 } qw(fieldsV1 rawExtension raw);

    # Get attribute info from the registry (keyed by Perl attr name)
    my $attr_info = IO::K8s::Resource::_k8s_attr_info($class);

    # Build reverse map: JSON key → Perl attr name (for sanitized names)
    my %json_to_perl;
    for my $perl_name (keys %$attr_info) {
        my $json_key = $attr_info->{$perl_name}{json_key} // $perl_name;
        $json_to_perl{$json_key} = $perl_name;
    }

    my %args;

    for my $attr (keys %$params) {
        my $value = $params->{$attr};
        next unless defined $value;

        # Pass through opaque fields without type coercion
        if ($opaque_fields{$attr}) {
            $args{$attr} = $value;
            next;
        }

        # Look up by Perl attr name (handles sanitized JSON keys like x-kubernetes-*)
        my $perl_name = $json_to_perl{$attr} // $attr;
        my $info = $attr_info->{$perl_name} // {};

        if ($info->{is_array_of_objects}) {
            my $inner_class = $info->{class};
            $args{$attr} = [ map { $self->struct_to_object($inner_class, $_) } @$value ];
        } elsif ($info->{is_hash_of_objects}) {
            my $inner_class = $info->{class};
            $args{$attr} = { map { $_ => $self->struct_to_object($inner_class, $value->{$_}) } keys %$value };
        } elsif ($info->{is_object}) {
            $args{$attr} = $self->struct_to_object($info->{class}, $value);
        } elsif ($info->{is_bool}) {
            $args{$attr} = (ref($value) eq '' && lc($value) eq 'true') || $value ? 1 : 0;
        } else {
            $args{$attr} = $value;
        }
    }

    return \%args;
}

sub object_to_struct {
    my ($self, $object) = @_;
    return $object->TO_JSON;
}

sub object_to_json {
    my ($self, $object) = @_;
    return $object->to_json;
}

sub load {
    my ($self, $file) = @_;

    require IO::K8s::Manifest;

    # Set k8s instance for DSL functions
    local $IO::K8s::Manifest::_k8s_instance = $self;

    return IO::K8s::Manifest->_load_file($file, $self);
}

sub load_yaml {
    my ($self, $file_or_string, %opts) = @_;

    require YAML::PP;

    my $content;
    if ($file_or_string !~ /\n/ && -f $file_or_string) {
        # It's a file path
        open my $fh, '<', $file_or_string or die "Cannot open $file_or_string: $!";
        $content = do { local $/; <$fh> };
        close $fh;
    } else {
        # It's YAML content
        $content = $file_or_string;
    }

    # Parse multi-document YAML (Load returns all docs in list context)
    my @docs = YAML::PP::Load($content);

    my $collect_errors = $opts{collect_errors};
    my @objects;
    my @errors;

    # Inflate each document - this validates types!
    for my $i (0 .. $#docs) {
        my $doc = $docs[$i];
        next unless $doc && ref($doc) eq 'HASH';

        if ($collect_errors) {
            eval { push @objects, $self->inflate($doc) };
            if ($@) {
                my $name = $doc->{metadata}{name} // "document $i";
                my $kind = $doc->{kind} // 'unknown';
                push @errors, "$kind/$name: $@";
            }
        } else {
            push @objects, $self->inflate($doc);
        }
    }

    # In collect_errors mode, return (objects, errors) in list context
    if ($collect_errors) {
        return (\@objects, \@errors);
    }

    return \@objects;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s - Objects representing things found in the Kubernetes API

=head1 VERSION

version 1.006

=head1 SYNOPSIS

  use IO::K8s;

  my $k8s = IO::K8s->new;

  # Load .pk8s manifest files (Perl DSL)
  my $resources = $k8s->load('myapp.pk8s');

  # Load and validate YAML manifests
  my $resources = $k8s->load_yaml('deployment.yaml');

  # Validate with error collection
  my ($objs, $errors) = $k8s->load_yaml($yaml, collect_errors => 1);

  # Create objects programmatically
  my $pod = $k8s->new_object('Pod',
      metadata => { name => 'my-pod', namespace => 'default' },
      spec => { containers => [{ name => 'app', image => 'nginx' }] }
  );

  # Export to YAML and save
  print $pod->to_yaml;
  $pod->save('pod.yaml');

  # Inflate JSON/struct into typed objects
  my $svc = $k8s->json_to_object('Service', '{"kind":"Service",...}');
  my $obj = $k8s->inflate($json_with_kind);  # Auto-detect class from 'kind'

  # Serialize back
  my $json = $k8s->object_to_json($svc);
  my $struct = $k8s->object_to_struct($pod);

  # With OpenAPI spec for Custom Resources (CRDs)
  my $k8s = IO::K8s->new(openapi_spec => $spec_from_cluster);
  my $helmchart = $k8s->inflate($helmchart_json);  # Auto-generates class!

  # With external resource map providers (e.g. IO::K8s::Cilium)
  my $k8s = IO::K8s->new(with => ['IO::K8s::Cilium']);

  # Or add at runtime
  $k8s->add('IO::K8s::Cilium');           # class name
  $k8s->add(IO::K8s::Cilium->new);        # instance
  $k8s->add({ MyThing => '+My::Thing' }); # raw hashref

  # Disambiguate colliding kind names (e.g. both core and Cilium have NetworkPolicy)
  $k8s->new_object('NetworkPolicy', { ... });                  # core (first-registered)
  $k8s->new_object('NetworkPolicy', { ... }, 'cilium.io/v2');  # Cilium
  $k8s->new_object('cilium.io/v2/NetworkPolicy', { ... });     # domain-qualified

  # inflate() auto-uses apiVersion from the data for disambiguation
  $k8s->inflate('{"kind":"NetworkPolicy","apiVersion":"cilium.io/v2",...}');

=head1 DESCRIPTION

This module provides objects and serialization / deserialization methods that represent
the structures found in the Kubernetes API L<https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.31/>

Kubernetes API is strict about input types. When a value is expected to be an integer,
sending it as a string will cause rejection. This module ensures correct value types
in JSON that can be sent to Kubernetes.

It also inflates JSON returned by Kubernetes into typed Perl objects.

=head1 NAME

IO::K8s - Objects representing things found in the Kubernetes API

=head1 CLASS ARCHITECTURE

IO::K8s uses a layered architecture. Understanding these layers helps when
working with built-in resources or writing your own CRD classes.

=head2 IO::K8s::Resource (base layer)

All Kubernetes objects inherit from L<IO::K8s::Resource>. It provides:

=over 4

=item * L<Moo> class setup

=item * The C<k8s> DSL for declaring attributes with Kubernetes types

=item * C<TO_JSON> / C<to_json> serialization

=item * Type registry for inflation (JSON -> objects)

=back

The C<k8s> DSL supports these type specifications:

  k8s name     => 'Str';                   # string attribute
  k8s replicas => 'Int';                   # integer attribute
  k8s ready    => 'Bool';                  # boolean attribute
  k8s spec     => 'Core::V1::PodSpec';     # nested IO::K8s object
  k8s ports    => ['Core::V1::ServicePort']; # array of objects
  k8s labels   => { Str => 1 };            # hash of strings
  k8s items    => ['+Full::Class::Name'];  # array with full class (+ prefix)

=head2 IO::K8s::APIObject (top-level resources)

L<IO::K8s::APIObject> extends C<IO::K8s::Resource> for top-level API objects
(Pod, Deployment, Service, etc.) by applying L<IO::K8s::Role::APIObject>.
This adds:

=over 4

=item * C<metadata> attribute (L<IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta>)

=item * C<api_version()> - derived from class name for built-in types, or set via import parameter for CRDs

=item * C<kind()> - derived from the last segment of the class name

=item * C<resource_plural()> - returns C<undef> (auto-pluralize) by default, override for CRDs

=item * C<to_yaml()> - serialize to YAML suitable for C<kubectl apply -f>

=item * C<save($file)> - write YAML to file

=back

=head2 IO::K8s::Role::Namespaced (marker role)

L<IO::K8s::Role::Namespaced> is a marker role for namespace-scoped resources.
L<Kubernetes::REST> checks this to build the correct URL path (with or without
C</namespaces/{ns}/>).

=head1 WRITING CRD CLASSES

To use Custom Resource Definitions with L<Kubernetes::REST>, write a Perl
class using C<IO::K8s::APIObject>. This is the same base used by all built-in
Kubernetes types like Pod, Deployment, and Service.

=head2 Minimal CRD class

  package My::StaticWebSite;
  use IO::K8s::APIObject
      api_version     => 'homelab.example.com/v1',
      resource_plural => 'staticwebsites';
  with 'IO::K8s::Role::Namespaced';

  k8s spec   => { Str => 1 };
  k8s status => { Str => 1 };
  1;

That's it - 6 lines of actual code. This class now supports:

  my $site = My::StaticWebSite->new(
      metadata => $meta_object,
      spec     => { domain => 'blog.example.com', image => 'nginx' },
  );
  $site->kind;          # "StaticWebSite"
  $site->api_version;   # "homelab.example.com/v1"
  $site->to_yaml;       # full YAML output
  $site->TO_JSON;       # hashref for JSON encoding

=head2 Import parameters

C<use IO::K8s::APIObject> accepts these parameters:

=over 4

=item C<api_version> (required for CRDs)

The CRD's C<group/version>, e.g. C<'homelab.example.com/v1'>. For built-in
types this is derived from the class name (C<IO::K8s::Api::Core::V1::Pod>
gives C<v1>), but CRDs must specify it explicitly since their class names
don't follow the C<IO::K8s::Api::*> convention.

=item C<resource_plural> (recommended for CRDs)

The plural resource name for URL building, e.g. C<'staticwebsites'>. Must
match the CRD's C<spec.names.plural>. If omitted, L<Kubernetes::REST>
auto-pluralizes the kind name (C<StaticWebSite> -> C<staticwebsites>), but
this heuristic doesn't work for all names.

=back

=head2 Namespaced vs cluster-scoped

Apply C<IO::K8s::Role::Namespaced> for namespace-scoped CRDs (the common
case). Omit it for cluster-scoped CRDs:

  # Namespaced CRD (most CRDs):
  package My::StaticWebSite;
  use IO::K8s::APIObject api_version => 'homelab.example.com/v1', ...;
  with 'IO::K8s::Role::Namespaced';

  # Cluster-scoped CRD (rare):
  package My::ClusterBackupPolicy;
  use IO::K8s::APIObject api_version => 'backup.example.com/v1', ...;
  # No 'with Namespaced' - this is cluster-wide

=head2 Registering with Kubernetes::REST

Register your CRD class in the resource map using the C<+> prefix (which
means "use this full class name as-is"):

  use Kubernetes::REST::Kubeconfig;
  use My::StaticWebSite;

  my $api = Kubernetes::REST::Kubeconfig->new->api;
  $api->resource_map->{StaticWebSite} = '+My::StaticWebSite';

  # Now use it like any built-in resource
  my $site = $api->create($api->new_object(StaticWebSite =>
      metadata => { name => 'my-blog', namespace => 'default' },
      spec     => { domain => 'blog.example.com', image => 'nginx' },
  ));

See L<Kubernetes::REST::Example> for complete CRUD examples with CRDs.

=head1 AUTO-GENERATION

IO::K8s can automatically generate classes for Custom Resources and other
types not included in the built-in classes. This is an alternative to
writing CRD classes by hand.

=head2 From cluster OpenAPI spec

Provide the cluster's OpenAPI spec and IO::K8s will auto-generate classes
on demand:

  use IO::K8s;
  use Kubernetes::REST::Kubeconfig;

  # Get OpenAPI spec from cluster
  my $api = Kubernetes::REST::Kubeconfig->new->api;
  my $resp = $api->_request('GET', '/openapi/v2');
  my $spec = JSON::MaybeXS->new->decode($resp->content);

  # Create IO::K8s with auto-generation enabled
  my $k8s = IO::K8s->new(openapi_spec => $spec);

  # Now inflate works for ANY type in the cluster
  my $addon = $k8s->inflate($k3s_addon_json);   # k3s.cattle.io/v1 Addon
  my $chart = $k8s->inflate($helmchart_json);   # helm.cattle.io/v1 HelmChart

Auto-generated classes are placed in a unique namespace per IO::K8s instance
(e.g., C<IO::K8s::_AUTOGEN_abc123::...>) to avoid collisions.

=head2 Explicit generation with IO::K8s::AutoGen

For more control, use L<IO::K8s::AutoGen> directly:

  use IO::K8s::AutoGen;

  my $class = IO::K8s::AutoGen::get_or_generate(
      'com.example.homelab.v1.StaticWebSite',  # definition name
      $schema,                                   # OpenAPI schema
      {},                                        # all definitions
      'MyApp::K8s',                              # namespace
      api_version     => 'homelab.example.com/v1',
      kind            => 'StaticWebSite',
      resource_plural => 'staticwebsites',
      is_namespaced   => 1,
  );

  # Register with Kubernetes::REST
  $api->resource_map->{StaticWebSite} = "+$class";

=head2 Custom Class Namespaces

You can provide your own pre-built classes that take precedence over both
built-in and auto-generated classes:

  my $k8s = IO::K8s->new(
      class_namespaces => ['MyApp::K8s'],
      openapi_spec => $spec,
  );

With this configuration, the class lookup order is:

  1. MyApp::K8s::...          (your classes)
  2. IO::K8s::...             (built-in classes)
  3. IO::K8s::_AUTOGEN_...    (auto-generated)

This lets you create optimized or customized classes for specific resources
while falling back to auto-generation for everything else.

=head1 ATTRIBUTES

=head2 with

Optional. ArrayRef of external resource map providers to merge at construction
time. Each entry can be a class name (string) or an object instance. Classes
must consume L<IO::K8s::Role::ResourceMap> or otherwise provide a
C<resource_map()> method.

    my $k8s = IO::K8s->new(with => ['IO::K8s::Cilium']);

When kinds collide (e.g. both core and Cilium have C<NetworkPolicy>), the
first-registered entry keeps the short name. All entries are always reachable
via domain-qualified names (C<api_version/Kind>).

=head2 openapi_spec

Optional. The OpenAPI v2 specification from a Kubernetes cluster. When provided,
enables auto-generation of classes for types not found in the built-in classes.

=head2 class_namespaces

Optional. ArrayRef of namespace prefixes to search for classes before checking
IO::K8s built-ins. Useful for providing your own implementations.

=head2 resource_map

HashRef mapping short names (like C<Pod>) and domain-qualified names
(like C<networking.k8s.io/v1/NetworkPolicy>) to class paths. Defaults to
built-in mappings for standard Kubernetes resources. Each instance gets its
own copy, so modifications via C<add()> do not affect other instances.

=head1 METHODS

=head2 add

    $k8s->add('IO::K8s::Cilium');             # class name
    $k8s->add(IO::K8s::Cilium->new);          # instance
    $k8s->add({ MyKind => '+My::Class' });     # raw hashref
    $k8s->add($provider1, $provider2);         # multiple at once

Merge external resource maps into this instance. Accepts class names, object
instances with a C<resource_map()> method, or plain hashrefs.

When a kind name already exists in the resource map (collision), the
first-registered entry keeps the short name. Both the existing and new
entries are registered under domain-qualified names (C<api_version/Kind>)
so they remain reachable.

Returns C<$self> for chaining.

=head2 load

    my $resources = $k8s->load('myapp.pk8s');

Load a C<.pk8s> manifest file and return an ArrayRef of IO::K8s objects.

The C<.pk8s> file format is Perl code with a DSL for defining Kubernetes
resources:

    # myapp.pk8s
    ConfigMap {
        name => 'my-config',
        namespace => 'default',
        data => { key => 'value' }
    };

    Deployment {
        name => 'my-app',
        namespace => 'default',
        spec => {
            replicas => 3,
            selector => { matchLabels => { app => 'my-app' } },
            template => {
                metadata => { labels => { app => 'my-app' } },
                spec => {
                    containers => [{
                        name => 'app',
                        image => 'my-app:latest',
                    }],
                },
            },
        }
    };

Inside C<{}> blocks, C<name>, C<namespace>, C<labels>, and C<annotations>
are automatically moved to C<metadata>.

With CRDs (requires openapi_spec):

    my $k8s = IO::K8s->new(openapi_spec => $spec);
    my $resources = $k8s->load('helmchart.pk8s');

=head2 load_yaml

    my $resources = $k8s->load_yaml('manifest.yaml');
    my $resources = $k8s->load_yaml($yaml_string);

Load a YAML manifest file (or YAML string) and return an ArrayRef of IO::K8s
objects. Supports multi-document YAML (separated by C<--->).

This method validates the YAML against the Kubernetes types. If a field has
the wrong type or an unknown field is used, an error is thrown. This is useful
for validating manifests before applying them to a cluster.

    # Validate a manifest file
    eval {
        my $objs = $k8s->load_yaml('deployment.yaml');
        say "Valid! Contains " . scalar(@$objs) . " resources";
    };
    if ($@) {
        say "Invalid manifest: $@";
    }

B<Options:>

=over 4

=item collect_errors => 1

Collect all validation errors instead of stopping at the first one. Returns
a list of C<(objects, errors)> where C<objects> contains successfully parsed
resources and C<errors> is an ArrayRef of error messages.

    my ($objs, $errors) = $k8s->load_yaml($yaml, collect_errors => 1);
    if (@$errors) {
        say "Found " . scalar(@$errors) . " errors:";
        say "  - $_" for @$errors;
    }

=back

=head2 new_object

    my $pod = $k8s->new_object('Pod', %args);
    my $pod = $k8s->new_object('Pod', \%args);
    my $np  = $k8s->new_object('NetworkPolicy', \%args, 'cilium.io/v2');
    my $np  = $k8s->new_object('cilium.io/v2/NetworkPolicy', \%args);

Create a new Kubernetes object of the given type. The type can be a short name
(like C<Pod>), a domain-qualified name (like C<cilium.io/v2/NetworkPolicy>),
or a full class path.

An optional third argument specifies the C<api_version> to disambiguate when
multiple providers register the same kind name.

=head2 inflate

    my $obj = $k8s->inflate($json_string);
    my $obj = $k8s->inflate(\%hashref);

Inflate a JSON string or hashref into a typed IO::K8s object. The class is
auto-detected from the C<kind> field in the data. When external resource maps
have been added via C<add()>, the C<apiVersion> field is used to disambiguate
colliding kind names.

=head2 json_to_object

    my $obj = $k8s->json_to_object($json_with_kind);
    my $obj = $k8s->json_to_object('Pod', $json_string);

Convert JSON to an IO::K8s object. With one argument, auto-detects the class
from C<kind>. With two arguments, uses the specified class.

=head2 struct_to_object

    my $obj = $k8s->struct_to_object(\%hashref_with_kind);
    my $obj = $k8s->struct_to_object('Pod', \%hashref);

Convert a Perl hashref to an IO::K8s object. With one argument, auto-detects
the class from C<kind>. With two arguments, uses the specified class.

=head2 object_to_json

    my $json = $k8s->object_to_json($obj);

Serialize an IO::K8s object to JSON.

=head2 object_to_struct

    my $hashref = $k8s->object_to_struct($obj);

Convert an IO::K8s object to a plain Perl hashref.

=head1 CILIUM CRD SUPPORT

IO::K8s includes L<IO::K8s::Cilium> with 23 Cilium CRD classes covering
C<cilium.io/v2> (12 CRDs) and C<cilium.io/v2alpha1> (11 CRDs). These are
not loaded by default -- opt in at construction:

  my $k8s = IO::K8s->new(with => ['IO::K8s::Cilium']);

  my $cnp = $k8s->new_object('CiliumNetworkPolicy',
      metadata => { name => 'allow-dns', namespace => 'kube-system' },
      spec => { endpointSelector => { matchLabels => { app => 'dns' } } },
  );

  print $cnp->to_yaml;

All Cilium kinds are C<Cilium>-prefixed, so there are no collisions with
core Kubernetes kind names.

=head1 EXTERNAL RESOURCE MAPS

IO::K8s supports merging resource maps from external packages (like
L<IO::K8s::Cilium> for Cilium CRDs). This allows multiple packages to
provide typed Kubernetes objects that work together.

=head2 Writing a resource map provider

Create a class that consumes L<IO::K8s::Role::ResourceMap>:

  package My::CRD::Provider;
  use Moo;
  with 'IO::K8s::Role::ResourceMap';

  sub resource_map {
      return {
          MyCustomKind => '+My::CRD::V1::MyCustomKind',
      };
  }

See L<IO::K8s::Cilium> for a real-world example with 23 CRD classes.

=head2 Collision handling

When two providers register the same kind name, the first-registered entry
keeps the short name. Both entries are always reachable via domain-qualified
names (C<api_version/Kind>):

  my $k8s = IO::K8s->new(with => ['My::Firewall::Provider']);

  # Short name -> core (first-registered)
  $k8s->expand_class('NetworkPolicy');
  # -> IO::K8s::Api::Networking::V1::NetworkPolicy

  # Domain-qualified -> specific version
  $k8s->expand_class('firewall.example.com/v1/NetworkPolicy');
  # -> My::Firewall::V1::NetworkPolicy

  # api_version parameter for disambiguation
  $k8s->expand_class('NetworkPolicy', 'firewall.example.com/v1');
  # -> My::Firewall::V1::NetworkPolicy

=head2 Disambiguation in pk8s DSL

In C<.pk8s> manifest files, pass the api_version as a second argument:

  # Core NetworkPolicy (default)
  NetworkPolicy { name => 'deny-all', spec => { ... } };

  # Firewall NetworkPolicy (disambiguated, no comma - like grep/map syntax)
  NetworkPolicy { name => 'deny-all', spec => { ... } } 'firewall.example.com/v1';

=head1 UPGRADING FROM PREVIOUS VERSIONS

B<WARNING: Version 1.00 contains breaking changes!>

This version has been completely rewritten. Key changes that may affect your code:

=over 4

=item * B<Moose to Moo migration>

All classes now use L<Moo> instead of L<Moose>. This means faster startup and
lighter dependencies, but Moose-specific features (meta introspection, etc.)
are no longer available.

=item * B<List classes removed>

Individual C<*List> classes (e.g., C<IO::K8s::Api::Core::V1::PodList>) have been
replaced with the unified L<IO::K8s::List> class. The old class names still exist
as deprecation stubs that emit warnings.

=item * B<Updated to Kubernetes v1.31 API>

API objects have been updated from v1.14 to v1.31. Some fields may have changed,
been added, or removed according to upstream Kubernetes API changes.

=item * B<New Role for namespaced resources>

Resources that are namespaced now consume L<IO::K8s::Role::Namespaced>. Use
C<< $class->does('IO::K8s::Role::Namespaced') >> to check if a resource is
namespace-scoped.

=back

=head1 SEE ALSO

L<Kubernetes::REST> - REST client for the Kubernetes API, uses IO::K8s for typed request/response objects

L<Kubernetes::REST::Example> - Comprehensive examples for using Kubernetes::REST with IO::K8s against a real cluster (Minikube, K3s, etc.)

L<https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.31/>

=head1 BUGS and SOURCE

The source code is located here: L<https://github.com/pplu/io-k8s-p5>

Please report bugs to: L<https://github.com/pplu/io-k8s-p5/issues>

=head1 COPYRIGHT and LICENSE

Copyright (c) 2018 by Jose Luis Martinez
Copyright (c) 2026 by Torsten Raudssus

This code is distributed under the Apache 2 License. The full text of the
license can be found in the LICENSE file included with this module.

=head1 AUTHORS

=over 4

=item *

Torsten Raudssus <torsten@raudssus.de> (current maintainer)

=item *

Jose Luis Martinez <jlmartin@cpan.org> (original author)

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/pplu/io-k8s-p5/issues>.

=head2 IRC

Join C<#kubernetes> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHORS

=over 4

=item *

Torsten Raudssus <torsten@raudssus.de>

=item *

Jose Luis Martinez <jlmartin@cpan.org> (original author, inactive)

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Jose Luis Martinez.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
