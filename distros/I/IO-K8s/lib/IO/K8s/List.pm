package IO::K8s::List;
# ABSTRACT: Generic list container for Kubernetes API responses
our $VERSION = '1.009';
use v5.10;
use Moo;
use Types::Standard qw( ArrayRef InstanceOf Maybe Str );
use JSON::MaybeXS ();
use Scalar::Util qw(blessed);


has items => (
    is => 'ro',
    isa => ArrayRef,
    required => 1,
);


has metadata => (
    is => 'ro',
    isa => Maybe[InstanceOf['IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ListMeta']],
);


has _item_class => (
    is => 'ro',
    isa => Maybe[Str],
    init_arg => 'item_class',
);


sub api_version {
    my $self = shift;

    # Try to get from first item
    if (@{$self->items} && blessed($self->items->[0]) && $self->items->[0]->can('api_version')) {
        return $self->items->[0]->api_version;
    }

    # Fall back to deriving from item_class
    if (my $class = $self->_item_class) {
        if ($class =~ /^IO::K8s::Api::(\w+)::(\w+)::/) {
            my ($group, $version) = ($1, $2);
            $version = lc($version);
            return $group eq 'Core' ? $version : lc($group) . '/' . $version;
        }
    }

    return undef;
}


sub kind {
    my $self = shift;

    # Try to get from first item
    if (@{$self->items} && blessed($self->items->[0]) && $self->items->[0]->can('kind')) {
        return $self->items->[0]->kind . 'List';
    }

    # Fall back to deriving from item_class
    if (my $class = $self->_item_class) {
        if ($class =~ /::(\w+)$/) {
            return $1 . 'List';
        }
    }

    return undef;
}


sub TO_JSON {
    my $self = shift;
    my %data;

    $data{apiVersion} = $self->api_version if $self->api_version;
    $data{kind} = $self->kind if $self->kind;

    $data{items} = [
        map { blessed($_) && $_->can('TO_JSON') ? $_->TO_JSON : $_ } @{$self->items}
    ];

    if ($self->metadata && blessed($self->metadata) && $self->metadata->can('TO_JSON')) {
        $data{metadata} = $self->metadata->TO_JSON;
    }

    return \%data;
}

sub to_json {
    my $self = shift;
    state $json = JSON::MaybeXS->new->canonical;
    return $json->encode($self->TO_JSON);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::List - Generic list container for Kubernetes API responses

=head1 VERSION

version 1.009

=head1 SYNOPSIS

    use IO::K8s::List;

    my $list = IO::K8s::List->new(
        items => \@pods,
        metadata => $list_meta,
    );

    # apiVersion and kind are derived from items
    print $list->api_version;  # v1
    print $list->kind;         # PodList

=head1 DESCRIPTION

Generic container for Kubernetes list responses. Instead of having separate
PodList, ServiceList, DeploymentList classes, this single class handles all
list types.

The C<apiVersion> and C<kind> are automatically derived from the items.

=head2 items

Array of Kubernetes API objects. Required.

=head2 metadata

List metadata (L<IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ListMeta>).
Contains pagination info like C<continue> and C<resourceVersion>.

=head2 item_class

Optional. The class of items in the list. If not provided, derived from
the first item. Used for empty lists where the type can't be inferred.

=head2 api_version

Returns the Kubernetes API version, derived from items or item_class.

=head2 kind

Returns the Kubernetes kind (e.g., "PodList"), derived from items or item_class.

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
