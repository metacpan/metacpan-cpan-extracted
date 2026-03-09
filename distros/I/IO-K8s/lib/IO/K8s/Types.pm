package IO::K8s::Types;
# ABSTRACT: Type::Tiny type library for Kubernetes resources
our $VERSION = '1.008';
use Type::Library -base, -declare => qw( IntOrStr Quantity Time );
use Type::Utils -all;
use Types::Standard -types;

# Re-export common Types::Standard types
BEGIN { extends 'Types::Standard' }

# Kubernetes scalar types

declare IntOrStr, as Str;

declare Quantity, as Str,
    where { /\A[+-]?(\d+\.?\d*|\d*\.\d+)([eE][+-]?\d+|Ki|Mi|Gi|Ti|Pi|Ei|[mkMGTPE])?\z/ },
    message { "Value '$_' is not a valid Kubernetes Quantity" };

declare Time, as Str,
    where { /\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?(Z|[+-]\d{2}:\d{2})\z/ },
    message { "Value '$_' is not a valid RFC3339 timestamp" };

# Core V1 Types
class_type 'Pod', { class => 'IO::K8s::Api::Core::V1::Pod' };
class_type 'PodSpec', { class => 'IO::K8s::Api::Core::V1::PodSpec' };
class_type 'PodStatus', { class => 'IO::K8s::Api::Core::V1::PodStatus' };
class_type 'Container', { class => 'IO::K8s::Api::Core::V1::Container' };
class_type 'Service', { class => 'IO::K8s::Api::Core::V1::Service' };
class_type 'ServiceSpec', { class => 'IO::K8s::Api::Core::V1::ServiceSpec' };
class_type 'ConfigMap', { class => 'IO::K8s::Api::Core::V1::ConfigMap' };
class_type 'Secret', { class => 'IO::K8s::Api::Core::V1::Secret' };
class_type 'Namespace', { class => 'IO::K8s::Api::Core::V1::Namespace' };
class_type 'Node', { class => 'IO::K8s::Api::Core::V1::Node' };
class_type 'PersistentVolume', { class => 'IO::K8s::Api::Core::V1::PersistentVolume' };
class_type 'PersistentVolumeClaim', { class => 'IO::K8s::Api::Core::V1::PersistentVolumeClaim' };

# Apps V1 Types
class_type 'Deployment', { class => 'IO::K8s::Api::Apps::V1::Deployment' };
class_type 'DeploymentSpec', { class => 'IO::K8s::Api::Apps::V1::DeploymentSpec' };
class_type 'ReplicaSet', { class => 'IO::K8s::Api::Apps::V1::ReplicaSet' };
class_type 'StatefulSet', { class => 'IO::K8s::Api::Apps::V1::StatefulSet' };
class_type 'DaemonSet', { class => 'IO::K8s::Api::Apps::V1::DaemonSet' };

# Batch V1 Types
class_type 'Job', { class => 'IO::K8s::Api::Batch::V1::Job' };
class_type 'JobSpec', { class => 'IO::K8s::Api::Batch::V1::JobSpec' };
class_type 'JobStatus', { class => 'IO::K8s::Api::Batch::V1::JobStatus' };
class_type 'CronJob', { class => 'IO::K8s::Api::Batch::V1::CronJob' };
class_type 'CronJobSpec', { class => 'IO::K8s::Api::Batch::V1::CronJobSpec' };

# Networking V1 Types
class_type 'Ingress', { class => 'IO::K8s::Api::Networking::V1::Ingress' };
class_type 'IngressSpec', { class => 'IO::K8s::Api::Networking::V1::IngressSpec' };
class_type 'NetworkPolicy', { class => 'IO::K8s::Api::Networking::V1::NetworkPolicy' };

# RBAC V1 Types
class_type 'Role', { class => 'IO::K8s::Api::Rbac::V1::Role' };
class_type 'RoleBinding', { class => 'IO::K8s::Api::Rbac::V1::RoleBinding' };
class_type 'ClusterRole', { class => 'IO::K8s::Api::Rbac::V1::ClusterRole' };
class_type 'ClusterRoleBinding', { class => 'IO::K8s::Api::Rbac::V1::ClusterRoleBinding' };

# Meta V1 Types
class_type 'ObjectMeta', { class => 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta' };
class_type 'LabelSelector', { class => 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::LabelSelector' };
class_type 'Status', { class => 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::Status' };

# API Extensions Types
class_type 'CustomResourceDefinition', { class => 'IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::CustomResourceDefinition' };

# Export tags
our %EXPORT_TAGS = (
    k8s_scalars => [qw( IntOrStr Quantity Time )],
    core => [qw( Pod PodSpec PodStatus Container Service ServiceSpec
                 ConfigMap Secret Namespace Node
                 PersistentVolume PersistentVolumeClaim )],
    apps => [qw( Deployment DeploymentSpec ReplicaSet StatefulSet DaemonSet )],
    batch => [qw( Job JobSpec JobStatus CronJob CronJobSpec )],
    networking => [qw( Ingress IngressSpec NetworkPolicy )],
    rbac => [qw( Role RoleBinding ClusterRole ClusterRoleBinding )],
    meta => [qw( ObjectMeta LabelSelector Status )],
);

$EXPORT_TAGS{all} = [ map { @$_ } values %EXPORT_TAGS ];

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Types - Type::Tiny type library for Kubernetes resources

=head1 VERSION

version 1.008

=head1 SYNOPSIS

    use IO::K8s::Types qw( :core :batch );

    has pod => (
        is => 'ro',
        isa => Pod,
    );

    has jobs => (
        is => 'ro',
        isa => ArrayRef[Job],
    );

=head1 DESCRIPTION

This module provides Type::Tiny type constraints for all major Kubernetes
resource types. Types can be imported individually or by category using
export tags.

=head1 NAME

IO::K8s::Types - Type::Tiny type library for Kubernetes resources

=head1 EXPORT TAGS

=over 4

=item :core

Pod, PodSpec, Container, Service, ConfigMap, Secret, Namespace, Node, etc.

=item :apps

Deployment, ReplicaSet, StatefulSet, DaemonSet

=item :batch

Job, JobSpec, CronJob

=item :networking

Ingress, NetworkPolicy

=item :rbac

Role, RoleBinding, ClusterRole, ClusterRoleBinding

=item :meta

ObjectMeta, LabelSelector, Status

=item :all

All types

=back

=head1 SEE ALSO

L<IO::K8s>, L<Type::Tiny>

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
