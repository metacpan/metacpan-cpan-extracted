package IO::K8s::List;
# ABSTRACT: Generic list container for Kubernetes API responses
our $VERSION = '1.108';
use v5.10;
use Moo;
with 'IO::K8s::Role::Resource';
use Module::Runtime ();
use Types::Standard qw( Str );
use JSON::MaybeXS ();
use Scalar::Util ();


has items => (
    is => 'ro',
    isa => Types::Standard::ArrayRef,
    required => 1,
);


has metadata => (
    is => 'ro',
    isa => Types::Standard::Maybe[
        Types::Standard::InstanceOf['IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ListMeta']
    ],
);


has _item_class => (
    is => 'ro',
    isa => Types::Standard::Maybe[Str],
    init_arg => 'item_class',
);


# Strip the '+' convention this distribution uses everywhere else to mean
# "this is already a full class name" (k49). Returns undef if there is
# no item_class at all, same as _item_class itself.
sub _resolved_item_class {
    my ($self) = @_;
    my $class = $self->_item_class;
    return undef unless defined $class;
    $class =~ s/\A\+//;
    return $class;
}

sub api_version {
    my ($self) = @_;

    # Try to get from first item
    if (@{$self->items} && Scalar::Util::blessed($self->items->[0]) && $self->items->[0]->can('api_version')) {
        return $self->items->[0]->api_version;
    }

    # Fall back to the item_class's own api_version class method, which
    # knows the full wire group (rbac.authorization.k8s.io, storage.k8s.io,
    # apiextensions.k8s.io, ...). undef unless the class loads, has an
    # api_version method and answers without error.
    if (my $class = $self->_resolved_item_class) {
        eval { Module::Runtime::require_module($class) };
        return undef if $@;
        return undef unless $class->can('api_version');
        my $api_version = eval { $class->api_version };
        return undef if $@;
        return $api_version;
    }

    return undef;
}


sub kind {
    my $self = shift;

    # Try to get from first item
    if (@{$self->items} && Scalar::Util::blessed($self->items->[0]) && $self->items->[0]->can('kind')) {
        return $self->items->[0]->kind . 'List';
    }

    # Fall back to deriving from item_class -- but only when api_version()
    # can also answer for it. kind() and api_version() derive from the same
    # item_class, and this class must never serialize a kind without an
    # apiVersion alongside it (k49): a short or unloadable item_class
    # (e.g. 'Pod' instead of 'IO::K8s::Api::Core::V1::Pod') would otherwise
    # still produce a Kind by regex here while api_version() -- which
    # actually has to load the class -- came back undef.
    if (my $class = $self->_resolved_item_class) {
        return undef unless defined $self->api_version;

        if ($class =~ /::(\w+)$/) {
            return $1 . 'List';
        }

        # No '::' at all: a CRD registered as a single-segment top-level
        # package, so the whole name is the last segment -- the same
        # derivation IO::K8s::Role::APIObject::kind() makes (k38). This
        # is the empty-list case item_class exists for, and without it
        # TO_JSON emits apiVersion but no kind: (k41).
        if ($class =~ /\A(\w+)\z/) {
            return $1 . 'List';
        }
    }

    return undef;
}



my $LIST_META = 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ListMeta';

# Mirrors IO::K8s::_die_resolution_error()'s message format exactly, so a
# caller can't tell whether a GVK failure came from a top-level entry point
# or from inside a List's own item inflation. Kept local rather than
# reaching into IO::K8s's private subs -- this class does not otherwise
# depend on IO::K8s internals beyond the $k8s instance it is handed.
sub _die_gvk {
    my ($kind, $api_version) = @_;
    my $display = !defined($api_version) ? '<undef>'
        : length($api_version) ? $api_version
        : '<empty>';
    die "Cannot resolve Kubernetes GVK: kind '$kind', apiVersion '$display'\n";
}

sub FROM_STRUCT {
    my ($class, $struct, $k8s) = @_;

    $k8s //= do { require IO::K8s; IO::K8s->new };

    my $kind        = $struct->{kind};
    my $api_version = $struct->{apiVersion};

    # item_class as an explicit override -- checked before any derivation,
    # exactly like the empty-list case item_class already covers for a
    # hand-built list. Same '+' handling as everywhere else (k49).
    my $resolved_item_class;
    if (defined(my $override = $struct->{item_class})) {
        $override =~ s/\A\+//;
        $resolved_item_class = $override;
    }
    elsif (defined $kind && $kind =~ /\A(.+)List\z/) {
        my $item_kind = $1;
        $resolved_item_class = $k8s->expand_class($item_kind, $api_version);
        _die_gvk($item_kind, $api_version) unless defined $resolved_item_class;
    }
    # else: a bare 'kind: List' (or no kind at all) with no override -- items
    # are only inflatable if the list turns out to be empty; see below.

    my $metadata;
    if (defined(my $meta_struct = $struct->{metadata})) {
        # $LIST_META is already a final class name -- go straight to the
        # pre-expanded path so it is not re-interpreted by expand_class()
        # (k35), same reasoning IO::K8s::_inflate_struct applies to
        # every nested object it inflates.
        $metadata = $k8s->_struct_to_object_expanded($LIST_META, $meta_struct);
    }

    my @items;
    for my $item_struct (@{ $struct->{items} // [] }) {
        die "Cannot inflate item in List payload: kind '"
            . (defined $kind ? $kind : '<undef>')
            . "' has no derivable item type and no 'item_class' override was given\n"
            unless defined $resolved_item_class;
        # Already resolved above (via expand_class() or the override) --
        # the pre-expanded path, for the same k35 reason as metadata.
        push @items, $k8s->_struct_to_object_expanded($resolved_item_class, $item_struct);
    }

    # Any top-level key besides the ones this envelope itself understands
    # (kind/apiVersion, consumed above to derive item_class; metadata/items,
    # handled below) is forwarded straight into ->new(). List composes
    # IO::K8s::Role::Resource for exactly this: its `BUILD` bags an
    # undeclared key into _unknown_fields, or dies under strict -- the
    # same envelope-level handling every non-list resource already gets
    # (k99). Items themselves already round-trip through their own class's
    # composition of the role; this only covers the list wrapper.
    my %known_top_level = map { $_ => 1 } qw(kind apiVersion metadata items item_class);
    my %extra = map { $_ => $struct->{$_} } grep { !$known_top_level{$_} } keys %$struct;

    return $class->new(
        items => \@items,
        (defined $metadata          ? (metadata   => $metadata)          : ()),
        (defined $resolved_item_class ? (item_class => $resolved_item_class) : ()),
        %extra,
    );
}


sub TO_JSON {
    my $self = shift;
    my %data;

    $data{apiVersion} = $self->api_version if $self->api_version;
    $data{kind} = $self->kind if $self->kind;

    $data{items} = [
        map { Scalar::Util::blessed($_) && $_->can('TO_JSON') ? $_->TO_JSON : $_ } @{$self->items}
    ];

    if ($self->metadata && Scalar::Util::blessed($self->metadata) && $self->metadata->can('TO_JSON')) {
        $data{metadata} = $self->metadata->TO_JSON;
    }

    # Unknown top-level fields ride along (D1/k99), the same bag every
    # Role::Resource class re-emits from TO_JSON -- List composes the role
    # for this mechanism even though it keeps its own TO_JSON. A declared
    # field above wins on a name clash, same rule as everywhere else.
    # _copy_one_level is the role's, reached unqualified because composing
    # the role installed it into this package too (k54 depth).
    my $extra = $self->_unknown_fields;
    if ($extra && %$extra) {
        for my $key (keys %$extra) {
            next if exists $data{$key};
            $data{$key} = _copy_one_level($extra->{$key});
        }
    }

    return \%data;
}

sub to_json {
    my $self = shift;
    # utf8 => 1, so this emits a UTF-8 byte string -- the same convention every
    # IO::K8s::Role::Resource class uses (k53), and exactly what
    # L</from_json> reads back. A character string here would round-trip
    # non-ASCII data to mojibake once it hit a byte-oriented sink (k64).
    state $json = JSON::MaybeXS->new(utf8 => 1, canonical => 1);
    return $json->encode($self->TO_JSON);
}



sub from_json {
    my ($class, $json_str, $k8s) = @_;
    state $json = JSON::MaybeXS->new(utf8 => 1);
    return $class->FROM_STRUCT($json->decode($json_str), $k8s);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::List - Generic list container for Kubernetes API responses

=head1 VERSION

version 1.108

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
the first item. Used for empty lists where the type can't be inferred, or
to override the item type L</FROM_STRUCT> would otherwise derive.

Accepted only as a fully-qualified class name, exactly like every other
class-name-taking parameter in this distribution: a leading C<+> is
stripped before use ("this is already a full class name"), and a short or
partially-qualified name is not guessed at -- L</kind> and L</api_version>
simply have nothing to derive from it (k49).

=head2 api_version

Returns the Kubernetes API version, derived from items or item_class.

=head2 kind

Returns the Kubernetes kind (e.g., "PodList"), derived from items or item_class.
For an C<item_class> the Kind is its last C<::> segment, or the whole name for
a single-segment class such as a CRD registered as C<+Widget> -- but only when
L</api_version> can also resolve for the same item_class; otherwise C<undef>,
never a Kind with no apiVersion to go with it (k49).

=head2 FROM_STRUCT

    my $list = IO::K8s::List->FROM_STRUCT($struct, $k8s);

Inflation hook called by L<IO::K8s/inflate> (and so by C<json_to_object> and
C<struct_to_object>) whenever the wire C<kind> is C<List> or ends in
C<List> -- the shape every real Kubernetes API list response has, and the
generic C<kind: List> wrapper besides. Upstream a list response carries no
C<apiVersion>/C<kind> on the individual items (the API server omits them
there), so the item type is derived from the LIST's own Kind and
apiVersion: C<kind: PodList, apiVersion: v1> means items are C<v1/Pod>.

C<item_class> travels as a sibling key of C<kind>/C<apiVersion>/C<items> in
the struct to override the derived type -- the same "use this class, don't
derive one" meaning it already has for an empty list built directly via
C<new>. It is the only way to inflate a bare C<kind: List> payload, whose
Kind minus its C<List> suffix is empty and so derives nothing on its own.

Fails closed (k39/k46): an item Kind that cannot be resolved to a
class dies with the same "Cannot resolve Kubernetes GVK" error every other
entry point in this distribution uses, naming the ITEM's kind/apiVersion,
never a silently empty or half-inflated list.

=head2 TO_JSON

    my $struct = $list->TO_JSON;

Returns the canonical wire-format hashref for the list: C<apiVersion>
and C<kind> when L</api_version> and L</kind> can derive them, plus an
C<items> array of each entry's own C<TO_JSON> (untouched when an item is
not a blessed object with a C<TO_JSON> method) and C<metadata> when set.
This is the inverse of L</FROM_STRUCT> and the input L</to_json> runs
through its JSON encoder.

=head2 to_json

    my $json_bytes = $list->to_json;

Serializes the List to a canonical JSON document as a B<UTF-8 encoded byte
string> -- the same convention every L<IO::K8s::Role::Resource> class uses
(k53), and the input L</from_json> reads back (k64).

=head2 from_json

    my $list = IO::K8s::List->from_json($json_bytes);
    my $list = IO::K8s::List->from_json($json_bytes, $k8s);

Builds a List from a JSON document, symmetric to L</to_json>. The argument
is a B<UTF-8 encoded byte string> -- exactly what C<to_json> emits -- and is
decoded and handed to L</FROM_STRUCT>, so the items inflate to typed objects
the same way L<IO::K8s/inflate> does. Pass an L<IO::K8s> instance as the
second argument when the item types must resolve through that instance's
providers or C<class_namespaces>; without one a shared default instance is
used, as FROM_STRUCT does.

List composes L<IO::K8s::Role::Resource> (since k99) so its top-level
envelope gets the same C<_unknown_fields> bag and C<strict> handling as
every other resource, but it is a container, not an API object with its
own GVK, so C<to_json>/C<from_json>/C<TO_JSON>/C<FROM_STRUCT> stay
hand-rolled overrides rather than the role's own -- C<kind>/C<api_version>
derive from the items, not from a class name. C<< $k8s->inflate >> reaches
the same FROM_STRUCT path from a full wire payload and remains the entry
point when the Kind is only known at runtime.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/pplu/io-k8s-p5/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHORS

=over 4

=item *

Torsten Raudssus <getty@cpan.org>

=item *

Jose Luis Martinez Torres <jlmartin@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2026 by Jose Luis Martinez Torres <jlmartin@cpan.org>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
