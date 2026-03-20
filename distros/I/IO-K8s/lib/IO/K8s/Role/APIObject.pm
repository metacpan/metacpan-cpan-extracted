package IO::K8s::Role::APIObject;
# ABSTRACT: Role for top-level Kubernetes API objects
our $VERSION = '1.009';
use Moo::Role;
use Types::Standard qw( InstanceOf Maybe );
use Scalar::Util qw(blessed);

has metadata => (
    is => 'rw',
    isa => Maybe[InstanceOf['IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta']],
);


# Map IO::K8s short group names to full Kubernetes API group names
my %API_GROUP_MAP = (
    rbac                  => 'rbac.authorization.k8s.io',
    networking            => 'networking.k8s.io',
    storage               => 'storage.k8s.io',
    admissionregistration => 'admissionregistration.k8s.io',
    certificates          => 'certificates.k8s.io',
    coordination          => 'coordination.k8s.io',
    events                => 'events.k8s.io',
    scheduling            => 'scheduling.k8s.io',
    authentication        => 'authentication.k8s.io',
    authorization         => 'authorization.k8s.io',
    node                  => 'node.k8s.io',
    discovery             => 'discovery.k8s.io',
    flowcontrol           => 'flowcontrol.apiserver.k8s.io',
);

# Derive apiVersion from class name
# IO::K8s::Api::Core::V1::Pod -> v1
# IO::K8s::Api::Apps::V1::Deployment -> apps/v1
# IO::K8s::Api::Rbac::V1::Role -> rbac.authorization.k8s.io/v1
# IO::K8s::ApiextensionsApiserver::...::V1::CustomResourceDefinition -> apiextensions.k8s.io/v1
# IO::K8s::KubeAggregator::...::V1::APIService -> apiregistration.k8s.io/v1
sub api_version {
    my ($self) = @_;
    my $class = ref($self) || $self;

    # Standard API: IO::K8s::Api::Group::Version::Kind
    if ($class =~ /^IO::K8s::Api::(\w+)::(\w+)::/) {
        my ($group, $version) = ($1, $2);
        $version = lc($version);
        return $version if $group eq 'Core';
        my $group_lc = lc($group);
        return ($API_GROUP_MAP{$group_lc} // $group_lc) . '/' . $version;
    }

    # Apiextensions: IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::Version::Kind
    if ($class =~ /^IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::(\w+)::/) {
        return 'apiextensions.k8s.io/' . lc($1);
    }

    # KubeAggregator: IO::K8s::KubeAggregator::Pkg::Apis::Apiregistration::Version::Kind
    if ($class =~ /^IO::K8s::KubeAggregator::Pkg::Apis::Apiregistration::(\w+)::/) {
        return 'apiregistration.k8s.io/' . lc($1);
    }

    return undef;
}


sub kind {
    my ($self) = @_;
    my $class = ref($self) || $self;

    if ($class =~ /::(\w+)$/) {
        return $1;
    }
    return undef;
}


sub resource_plural { undef }


sub _is_resource { 1 }

sub to_yaml {
    my ($self) = @_;
    require YAML::PP;
    my $yp = YAML::PP->new(schema => [qw/JSON/], boolean => 'JSON::PP');
    return $yp->dump_string($self->TO_JSON);
}


sub save {
    my ($self, $file) = @_;
    open my $fh, '>', $file or die "Cannot write to $file: $!";
    print $fh $self->to_yaml;
    close $fh;
    return $self;
}


# ============================================================
# Label & annotation convenience methods
# ============================================================

sub _ensure_metadata {
    my ($self) = @_;
    unless ($self->metadata) {
        require IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta;
        $self->metadata(IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta->new);
    }
    return $self->metadata;
}


sub add_label {
    my ($self, $key, $value) = @_;
    my $meta = $self->_ensure_metadata;
    my $labels = $meta->labels // {};
    $labels->{$key} = $value;
    $meta->labels($labels);
    return $self;
}


sub add_labels {
    my ($self, %pairs) = @_;
    my $meta = $self->_ensure_metadata;
    my $labels = $meta->labels // {};
    @{$labels}{keys %pairs} = values %pairs;
    $meta->labels($labels);
    return $self;
}


sub label {
    my ($self, $key) = @_;
    my $labels = $self->metadata ? $self->metadata->labels : undef;
    return defined $labels ? $labels->{$key} : undef;
}


sub has_label {
    my ($self, $key) = @_;
    my $labels = $self->metadata ? $self->metadata->labels : undef;
    return defined $labels && exists $labels->{$key} ? 1 : 0;
}


sub remove_label {
    my ($self, $key) = @_;
    if ($self->metadata && $self->metadata->labels) {
        delete $self->metadata->labels->{$key};
    }
    return $self;
}


sub match_labels {
    my ($self, %expected) = @_;
    my $labels = $self->metadata ? $self->metadata->labels : undef;
    return 0 unless defined $labels;
    for my $key (keys %expected) {
        return 0 unless exists $labels->{$key} && $labels->{$key} eq $expected{$key};
    }
    return 1;
}


sub add_annotation {
    my ($self, $key, $value) = @_;
    my $meta = $self->_ensure_metadata;
    my $annotations = $meta->annotations // {};
    $annotations->{$key} = $value;
    $meta->annotations($annotations);
    return $self;
}


sub annotation {
    my ($self, $key) = @_;
    my $annotations = $self->metadata ? $self->metadata->annotations : undef;
    return defined $annotations ? $annotations->{$key} : undef;
}


sub has_annotation {
    my ($self, $key) = @_;
    my $annotations = $self->metadata ? $self->metadata->annotations : undef;
    return defined $annotations && exists $annotations->{$key} ? 1 : 0;
}


sub remove_annotation {
    my ($self, $key) = @_;
    if ($self->metadata && $self->metadata->annotations) {
        delete $self->metadata->annotations->{$key};
    }
    return $self;
}

# ============================================================
# Status condition convenience methods
# ============================================================

sub _extract_conditions {
    my ($self) = @_;
    return [] unless $self->can('status') && defined $self->status;
    my $status = $self->status;

    # Typed status object with conditions accessor
    if (blessed($status) && $status->can('conditions')) {
        my $conds = $status->conditions;
        return $conds if ref $conds eq 'ARRAY';
        return [];
    }

    # Opaque hashref (CRDs)
    if (ref $status eq 'HASH' && ref $status->{conditions} eq 'ARRAY') {
        return $status->{conditions};
    }

    return [];
}

sub _condition_field {
    my ($cond, $field) = @_;
    if (blessed($cond) && $cond->can($field)) {
        return $cond->$field;
    }
    if (ref $cond eq 'HASH') {
        return $cond->{$field};
    }
    return undef;
}


sub conditions {
    my ($self) = @_;
    return $self->_extract_conditions;
}


sub get_condition {
    my ($self, $type) = @_;
    for my $cond (@{ $self->_extract_conditions }) {
        my $ctype = _condition_field($cond, 'type');
        return $cond if defined $ctype && $ctype eq $type;
    }
    return undef;
}


sub is_condition_true {
    my ($self, $type) = @_;
    my $cond = $self->get_condition($type);
    return 0 unless defined $cond;
    my $status = _condition_field($cond, 'status');
    return defined $status && $status eq 'True' ? 1 : 0;
}


sub is_ready {
    my ($self) = @_;
    return 1 if $self->is_condition_true('Ready');
    return 1 if $self->is_condition_true('Available');
    return 0;
}


sub condition_message {
    my ($self, $type) = @_;
    my $cond = $self->get_condition($type);
    return undef unless defined $cond;
    return _condition_field($cond, 'message');
}

# ============================================================
# Owner reference convenience methods
# ============================================================


sub set_owner {
    my ($self, $owner) = @_;
    require IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::OwnerReference;
    my $meta = $self->_ensure_metadata;
    my $refs = $meta->ownerReferences // [];

    my $ref = IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::OwnerReference->new(
        apiVersion => $owner->api_version,
        kind       => $owner->kind,
        name       => $owner->metadata->name,
        uid        => $owner->metadata->uid // '',
        controller => 1,
    );

    $meta->ownerReferences([@$refs, $ref]);
    return $self;
}


sub is_owned_by {
    my ($self, $owner) = @_;
    my $refs = $self->owner_refs;
    my $owner_uid  = $owner->metadata ? $owner->metadata->uid  : undef;
    my $owner_name = $owner->metadata ? $owner->metadata->name : undef;
    my $owner_kind = $owner->kind;

    for my $ref (@$refs) {
        my ($rname, $ruid, $rkind);
        if (blessed($ref) && $ref->can('name')) {
            $rname = $ref->name;
            $ruid  = $ref->uid;
            $rkind = $ref->kind;
        } elsif (ref $ref eq 'HASH') {
            $rname = $ref->{name};
            $ruid  = $ref->{uid};
            $rkind = $ref->{kind};
        }

        # Match by UID if both have it, otherwise by name+kind
        if (defined $owner_uid && $owner_uid ne '' && defined $ruid && $ruid ne '') {
            return 1 if $ruid eq $owner_uid;
        } elsif (defined $owner_name && defined $rname && defined $owner_kind && defined $rkind) {
            return 1 if $rname eq $owner_name && $rkind eq $owner_kind;
        }
    }
    return 0;
}


sub owner_refs {
    my ($self) = @_;
    return [] unless $self->metadata;
    return $self->metadata->ownerReferences // [];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Role::APIObject - Role for top-level Kubernetes API objects

=head1 VERSION

version 1.009

=head2 metadata

Standard object's metadata. See L<IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta>.

=head2 api_version

Returns the Kubernetes API version derived from the class name.

    $pod->api_version;  # "v1"
    $deployment->api_version;  # "apps/v1"

=head2 kind

Returns the Kubernetes kind derived from the class name.

    $pod->kind;  # "Pod"
    $deployment->kind;  # "Deployment"

=head2 resource_plural

Returns the plural resource name for URL building, or C<undef> to use
automatic pluralization. Override this in CRD classes where the plural
name is not simply the lowercased kind with an "s" appended:

    sub resource_plural { 'staticwebsites' }

=head2 to_yaml

    my $yaml = $pod->to_yaml;

Serialize the object to YAML format suitable for C<kubectl apply -f>.

=head2 save

    $pod->save('pod.yaml');

Save the object to a YAML file. Returns the object for chaining.

=head2 add_label

    $obj->add_label(app => 'web');

Add a single label. Returns C<$self> for chaining.

=head2 add_labels

    $obj->add_labels(app => 'web', tier => 'frontend');

Add multiple labels at once. Returns C<$self> for chaining.

=head2 label

    my $val = $obj->label('app');  # => 'web'

Get the value of a single label, or C<undef> if missing.

=head2 has_label

    $obj->has_label('app');  # => 1

Returns true if the label key exists.

=head2 remove_label

    $obj->remove_label('tier');

Remove a label by key. Returns C<$self> for chaining.

=head2 match_labels

    $obj->match_labels(app => 'web', tier => 'frontend');  # => Bool

Returns true if all given key/value pairs match the object's labels.

=head2 add_annotation

    $obj->add_annotation('prometheus.io/scrape' => 'true');

Add a single annotation. Returns C<$self> for chaining.

=head2 annotation

    my $val = $obj->annotation('prometheus.io/scrape');

Get the value of a single annotation, or C<undef> if missing.

=head2 has_annotation

    $obj->has_annotation('prometheus.io/scrape');  # => 1

Returns true if the annotation key exists.

=head2 remove_annotation

    $obj->remove_annotation('prometheus.io/scrape');

Remove an annotation by key. Returns C<$self> for chaining.

=head2 conditions

    my $conds = $obj->conditions;  # => ArrayRef

Returns all status conditions as an arrayref.

=head2 get_condition

    my $cond = $obj->get_condition('Ready');  # => hashref/object or undef

Get a single condition by type name.

=head2 is_condition_true

    $obj->is_condition_true('Available');  # => Bool

Returns true if the named condition has C<status = "True">.

=head2 is_ready

    $obj->is_ready;  # => Bool

Returns true if the C<Ready> or C<Available> condition is true.

=head2 condition_message

    my $msg = $obj->condition_message('Ready');

Returns the message string for the named condition, or C<undef>.

=head2 set_owner

    $pod->set_owner($deployment);

Add an ownerReference pointing to another API object.
Returns C<$self> for chaining.

=head2 is_owned_by

    $pod->is_owned_by($deployment);  # => Bool

Returns true if this object has an ownerReference matching the given object.

=head2 owner_refs

    my $refs = $obj->owner_refs;  # => ArrayRef

Returns the ownerReferences array, or an empty arrayref.

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

Jose Luis Martinez Torres <jlmartin@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2026 by Jose Luis Martinez Torres <jlmartin@cpan.org>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
