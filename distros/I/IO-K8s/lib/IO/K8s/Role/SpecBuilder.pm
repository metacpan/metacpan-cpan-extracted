package IO::K8s::Role::SpecBuilder;
# ABSTRACT: Role for deep-path spec manipulation on CRD objects
our $VERSION = '1.108';
use Scalar::Util qw(blessed);
use Carp qw(croak);
use Module::Runtime qw(use_module);
# Imports above `use Moo::Role` on purpose: Role::Tiny treats subs already in
# the package as not-methods, so their names stay off every consumer. A `use`
# below that line composes its exports onto all shipped classes (k118).
use Moo::Role;

# ---------------------------------------------------------------------------
# A node on a spec path is one of: a plain hashref, a plain arrayref, or an
# IO::K8s object (anything composing IO::K8s::Role::Resource). Segments are
# dot-separated. An integer segment indexes an array; -1 is the last element,
# or the one created on an empty array. Anything else is a hash key or, on an
# object, a JSON field name mapped to its attribute through the registry (so
# '$ref' reaches _ref). A field an object does not declare lives in its
# _unknown_fields bag (D1) and is reachable like any other key.
#
# Before 1.108 every method assumed spec was a hashref: on a modeled spec
# spec_set replaced the struct with {} and wrote into an orphan (k90).
# ---------------------------------------------------------------------------

# Run a Moo constructor or accessor call from inside a walk and re-raise
# its failure with the spec path in front: Moo and Type::Tiny name the
# attribute, never the path the caller wrote, and a "Missing required
# arguments" from a class the walk tried to vivify would otherwise be
# reported against this file's line number (k101). Type::Tiny's multi-line
# validation errors put "at FILE line N" on the *first* line and then
# append several explanation lines after it, so the strip below is
# unanchored and global -- every embedded "at FILE line N" fragment goes,
# wherever it sits, while the explanation lines stay. croak still appends
# its own single trailing "at CALLER line N." to the re-raised message;
# that one is correct (it points at the caller of the spec_* method) and
# is left alone.
#
# Detecting failure from eval's own return value, not from $@'s truthiness,
# matters here: $code->() can legitimately `die 0` or `die ""`, and either
# one sets $@ to a value that is itself FALSE, so a bare `unless $@` check
# would read that as success and hand back an undef $result as if nothing
# had gone wrong. Stringifying $@ only inside this block, once eval's own
# return value has confirmed a failure, also avoids coercing an exception
# object to a string before it is known there is one to report.
sub _sb_guard {
    my ($path, $what, $code) = @_;
    my $result;
    unless (eval { $result = $code->(); 1 }) {
        my $err = "$@";
        $err =~ s/ at \S+ line \d+\.?//g;
        $err =~ s/\s+\z//;
        croak "spec path '$path': $what: $err";
    }
    return $result;
}

sub _sb_is_obj { blessed($_[0]) && $_[0]->can('_k8s_attr_info') }

sub _sb_is_index { defined $_[0] && $_[0] =~ /\A-?\d+\z/ }

# JSON key -> (attribute name, registry info) on an object; empty list when
# the object declares no such field.
sub _sb_attr {
    my ($node, $key) = @_;
    my $info = $node->_k8s_attr_info;
    for my $attr (keys %$info) {
        return ($attr, $info->{$attr}) if ($info->{$attr}{json_key} // $attr) eq $key;
    }
    return;
}

# Resolve an index against an array for writing. -1 on an empty array is the
# slot a new element goes into; any other index outside the array croaks
# rather than letting Perl autovivify a hole or die on a negative subscript.
sub _sb_index {
    my ($array, $seg, $path) = @_;
    croak "spec path '$path': '$seg' is not an array index" unless _sb_is_index($seg);
    return $seg if $seg >= 0 && $seg <= @$array;
    return 0 if $seg == -1 && !@$array;
    my $resolved = @$array + $seg;
    croak "spec path '$path': index $seg is out of range for an array of " . scalar(@$array)
        if $seg < 0 && $resolved < 0;
    croak "spec path '$path': index $seg is beyond the end of an array of " . scalar(@$array)
        if $seg > @$array;
    return $resolved;
}

# Read one segment. Returns the child, or undef when it is not there. Never
# creates anything.
sub _sb_child {
    my ($node, $seg) = @_;
    if (_sb_is_obj($node)) {
        my ($attr) = _sb_attr($node, $seg);
        return $node->$attr if defined $attr;
        return $node->_unknown_fields->{$seg};
    }
    if (ref $node eq 'ARRAY') {
        return undef unless _sb_is_index($seg);
        return undef if $seg < -@$node || $seg > $#$node;
        return $node->[$seg];
    }
    return $node->{$seg} if ref $node eq 'HASH';
    return undef;
}

# Hand a plain hashref (or an array/hash of them) to a typed slot as objects.
# Uses the shared default IO::K8s instance the way FROM_HASH does: registry
# class names are already fully expanded, so no per-instance resolution is
# involved. Scalars and already-blessed values pass through.
sub _sb_inflate {
    my ($info, $value) = @_;
    return $value unless $info && ref $value;
    my $k8s = IO::K8s::Role::Resource::_default_k8s();
    if ($info->{is_object}) {
        return ref $value eq 'HASH'
            ? $k8s->_struct_to_object_expanded($info->{class}, $value)
            : $value;
    }
    if ($info->{is_array_of_objects} && ref $value eq 'ARRAY') {
        return [ map { _sb_elem($info->{class}, $_) } @$value ];
    }
    if ($info->{is_hash_of_objects} && ref $value eq 'HASH') {
        return { map { $_ => _sb_elem($info->{class}, $value->{$_}) } keys %$value };
    }
    return $value;
}

# One element of an array/hash of objects: a hashref becomes $elem_class.
sub _sb_elem {
    my ($elem_class, $value) = @_;
    return $value unless $elem_class && ref $value eq 'HASH';
    return IO::K8s::Role::Resource::_default_k8s()->_struct_to_object_expanded($elem_class, $value);
}

# Store $value under $seg of $node. A declared field on an object goes
# through its accessor (hashrefs inflated first, so the type constraint sees
# an object); an undeclared one goes into the _unknown_fields bag. Returns
# the value as stored.
sub _sb_store {
    my ($node, $seg, $value, $path, $elem_class) = @_;
    if (_sb_is_obj($node)) {
        my ($attr, $info) = _sb_attr($node, $seg);
        if (defined $attr) {
            $value = _sb_inflate($info, $value);
            _sb_guard($path, "cannot set '$seg'", sub { $node->$attr($value) });
            return $value;
        }
        return $node->_unknown_fields->{$seg} = $value;
    }
    if (ref $node eq 'ARRAY') {
        my $i = _sb_index($node, $seg, $path);
        return $node->[$i] = _sb_elem($elem_class, $value);
    }
    if (ref $node eq 'HASH') {
        return $node->{$seg} = _sb_elem($elem_class, $value);
    }
    croak "spec path '$path': cannot store '$seg' in a " . (ref($node) || 'scalar');
}

# The class of the elements under an array/hash-of-objects field, when the
# node is an object and the field is one; undef otherwise.
sub _sb_elem_class {
    my ($node, $seg) = @_;
    return undef unless _sb_is_obj($node);
    my (undef, $info) = _sb_attr($node, $seg);
    return undef unless $info;
    return $info->{class} if $info->{is_array_of_objects} || $info->{is_hash_of_objects};
    return undef;
}

# What to create in an empty slot so a walk can continue. On an object the
# registry decides: the declared class for a struct/object field, [] or {}
# for the container forms, croak for a scalar. Inside an array or hash of
# objects the element class. Elsewhere the next segment decides: an index
# means an array, anything else a hash.
sub _sb_fresh {
    my ($node, $seg, $next, $elem_class, $path) = @_;
    if (_sb_is_obj($node)) {
        my (undef, $info) = _sb_attr($node, $seg);
        if ($info) {
            return _sb_guard($path, "cannot create $info->{class} for '$seg'", sub { use_module($info->{class})->new })
                if $info->{is_object};
            return [] if grep { $info->{$_} } qw(
                is_array_of_objects is_array_of_str is_array_of_int
                is_array_of_bool is_array_of_hash is_array_of_array
                is_array_of_num is_array_of_quantity is_array_of_time
                is_array_of_int_or_string
            );
            return {} if grep { $info->{$_} } qw(
                is_hash_of_str is_hash_of_objects is_hash_of_int is_hash_of_num
                is_hash_of_bool is_hash_of_quantity is_hash_of_time
                is_hash_of_int_or_string
            );
            croak "spec path '$path': cannot descend through scalar field '$seg'";
        }
    }
    return _sb_guard($path, "cannot create $elem_class for '$seg'", sub { use_module($elem_class)->new })
        if $elem_class;
    return _sb_is_index($next) ? [] : {};
}

# The spec node. With $vivify, create it when missing: the declared class
# when spec is a typed field of this object, a plain hash otherwise.
#
# Every spec_* entry point comes through here, so this is also the one
# place that has to answer for a consumer with no `spec` field at all --
# 32 of the shipped Kinds carry none (ConfigMap, Secret, Endpoints, the
# four RBAC kinds, ...). Since the role is composed onto every APIObject
# rather than only onto CRD classes (k103) they all have the spec_*
# methods, and without this guard the first thing such a call hits is
# Moo's "Can't locate object method spec", reported against this file's
# line number instead of naming the class that has no spec.
#
# Checked per call rather than declared as `requires 'spec'`: the role is
# composed at `use IO::K8s::APIObject` time, before the class's own
# `k8s spec => ...` line has run, so a requires would reject every
# consumer including the ones that do declare a spec.
sub _sb_root {
    my ($self, $vivify, $path) = @_;
    croak((ref($self) || $self)
        . ' has no spec field: the spec_* methods need one to read or build')
        unless $self->can('spec');
    my $spec = $self->spec;
    return $spec if ref $spec;
    return undef unless $vivify;
    my (undef, $info) = _sb_is_obj($self) ? _sb_attr($self, 'spec') : ();
    $spec = $info && $info->{is_object}
        ? _sb_guard($path, "cannot create $info->{class} for 'spec'", sub { use_module($info->{class})->new })
        : {};
    $self->spec($spec);
    return $spec;
}

# Walk to the parent of the last segment, creating what is missing. Returns
# ($parent, $last_segment, $elem_class): $elem_class names the class a new
# element of $parent must be when $parent is an array or hash of objects.
sub _sb_walk_vivify {
    my ($self, $path) = @_;
    my @segs = split /\./, $path;
    my $last = pop @segs;
    croak "spec path '$path' is empty" unless defined $last && length $last;
    my $node = $self->_sb_root(1, $path);
    my $elem_class;
    for my $i (0 .. $#segs) {
        my $seg  = $segs[$i];
        my $next = $i < $#segs ? $segs[$i + 1] : $last;
        my $child = _sb_child($node, $seg);
        if (defined $child && !ref $child) {
            croak "spec path '$path': cannot descend through scalar field '$seg'";
        }
        my $child_elem_class = _sb_elem_class($node, $seg);
        unless (ref $child) {
            $child = _sb_fresh($node, $seg, $next, $elem_class, $path);
            $child = _sb_store($node, $seg, $child, $path, $elem_class);
        }
        # Elements of a container we just entered are typed only when the
        # object we came from declared the container as one of objects.
        $elem_class = $child_elem_class;
        $node = $child;
    }
    return ($node, $last, $elem_class);
}


sub spec_get {
    my ($self, $path) = @_;
    my $node = $self->_sb_root(0);
    return undef unless ref $node;
    for my $seg (split /\./, $path) {
        return undef unless ref $node;
        $node = _sb_child($node, $seg);
        return undef unless defined $node;
    }
    return $node;
}


sub spec_set {
    my ($self, $path, $value) = @_;
    my ($parent, $last, $elem_class) = $self->_sb_walk_vivify($path);
    _sb_store($parent, $last, $value, $path, $elem_class);
    return $self;
}


sub spec_array {
    my ($self, $path) = @_;
    my ($parent, $last, $elem_class) = $self->_sb_walk_vivify($path);
    my $array = _sb_child($parent, $last);
    return $array if ref $array eq 'ARRAY';
    croak "spec path '$path': '$last' holds a non-array value" if defined $array;
    return _sb_store($parent, $last, [], $path, $elem_class);
}


sub spec_hash {
    my ($self, $path) = @_;
    my ($parent, $last, $elem_class) = $self->_sb_walk_vivify($path);
    my $node = _sb_child($parent, $last);
    return $node if ref $node;
    croak "spec path '$path': '$last' holds a scalar" if defined $node;
    my $fresh = _sb_fresh($parent, $last, undef, $elem_class, $path);
    return _sb_store($parent, $last, $fresh, $path, $elem_class);
}


sub spec_push {
    my ($self, $path, @values) = @_;
    my $array = $self->spec_array($path);
    my ($parent, $last) = $self->_sb_walk_vivify($path);
    my $item_class = _sb_elem_class($parent, $last);
    push @$array, map { _sb_elem($item_class, $_) } @values;
    return $self;
}


sub spec_merge {
    my ($self, %data) = @_;
    for my $key (keys %data) {
        my $root = $self->_sb_root(1, $key);
        _sb_store($root, $key, $data{$key}, $key);
    }
    return $self;
}


sub spec_delete {
    my ($self, $path) = @_;
    my $node = $self->_sb_root(0);
    return $self unless ref $node;
    my @segs = split /\./, $path;
    my $last = pop @segs;
    for my $seg (@segs) {
        $node = _sb_child($node, $seg);
        return $self unless ref $node;
    }
    if (_sb_is_obj($node)) {
        my ($attr) = _sb_attr($node, $last);
        if (defined $attr) {
            _sb_guard($path, "cannot clear '$last'", sub { $node->$attr(undef) });
        } else {
            delete $node->_unknown_fields->{$last};
        }
    } elsif (ref $node eq 'ARRAY') {
        return $self unless _sb_is_index($last) && @$node;
        return $self if $last < -@$node || $last > $#$node;
        splice @$node, $last, 1;
    } elsif (ref $node eq 'HASH') {
        delete $node->{$last};
    }
    return $self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Role::SpecBuilder - Role for deep-path spec manipulation on CRD objects

=head1 VERSION

version 1.108

=head1 SYNOPSIS

    package My::App;
    use Moo;
    with 'IO::K8s::Role::SpecBuilder';

    has spec => ( is => 'rw' );

    sub BUILD { $_[0]->spec({ routes => [] }) }

    package main;
    my $app = My::App->new;
    $app->spec_push('routes', { match => 'Host(`x`)' });
    $app->spec_set('routes.0.match', 'Host(`y`)');
    print $app->spec_get('routes.0.match');

=head1 DESCRIPTION

This role provides dotted-path get/set/push/merge/delete operations against
a consumer class's C<spec> attribute. It exists so callers building
arbitrary CRDs (IngressRoute, HTTPRoute, Gateway listeners, ...) can reach
deeply-nested fields without writing the indexing by hand each time; since
1.108 the built-in Kinds reach theirs the same way.

Path syntax: dot-separated segments. On a plain hashref/arrayref node each
segment is a hash key or an array index; on an object node -- a typed
C<spec>, or any nested typed field reached along the way -- a segment is
instead the JSON field name mapped to its attribute through the registry,
or, for a key the class does not declare, read and written through the
object's C<_unknown_fields> bag (D1) exactly as it would be on a plain
hash. A purely numeric segment is always an array index: it counts from
the end when negative, so C<-1> addresses the last element, or (on an
empty array) the one C<spec_set>/C<spec_array>/C<spec_push> create there;
any other index that resolves outside the array croaks rather than
autovivifying a hole.

C<spec_set>, C<spec_array>, C<spec_hash> and C<spec_push> vivify missing
intermediate structure as they walk: a plain hashref/arrayref on an
untyped node, or, on a typed node, whatever the attribute registry
declares for that field (an inline struct or referenced class, an
array/hash container), with a hashref handed to a typed slot inflated the
same way C<FROM_HASH> does. C<spec_get> and C<spec_delete> never vivify.

Every failure raised while walking or vivifying begins with the spec
path and carries no internal file or line (k101) -- C<spec path 'PATH':>
in front of the reason, or, for a path that is itself empty, C<spec path
'PATH' is empty> on its own. A Moo/Type::Tiny failure hit while vivifying
or writing a declared field is re-raised with that prefix, such as:

    spec path 'PATH': cannot set 'SEG': ORIGINAL MESSAGE
    spec path 'PATH': cannot create CLASS for 'SEG': ORIGINAL MESSAGE
    spec path 'PATH': cannot clear 'SEG': ORIGINAL MESSAGE

The walk's own checks use the same C<spec path 'PATH':> prefix for the
failures they detect directly, too: an invalid or out-of-range array
index, a scalar blocking further descent (whether hit while walking or
while storing into it), and C<spec_array>/C<spec_hash> finding a
non-array or scalar value already at the path. C<spec_merge> bypasses
the path machinery entirely and shallow-merges into the top level only.

L<IO::K8s::Role::APIObject> composes this role, so every top-level Kind
has it: the built-in Kubernetes kinds, CRD classes declared via
C<use IO::K8s::APIObject api_version =E<gt> ..., ...>, and the classes
L<IO::K8s::AutoGen> builds at runtime, which compose
L<IO::K8s::Role::APIObject> directly. Before 1.108 only CRD classes got
it, and composing one of the builder roles
(L<IO::K8s::Role::CertManaged>, L<IO::K8s::Role::Routable>, ...) onto a
class without it failed at the first C<spec_*> call rather than at
composition time; those roles now C<require> the C<spec_*> methods they
use, which is only correct because every APIObject has them (k103).

A Kind that declares no C<spec> field at all -- 32 of the shipped ones,
carrying C<data>/C<rules>/C<subjects> instead: C<ConfigMap>, C<Secret>,
C<Endpoints>, the four RBAC kinds, ... -- still has the methods, and
every one of them croaks

    IO::K8s::Api::Core::V1::ConfigMap has no spec field: the spec_* methods need one to read or build

naming the class, at the caller's line. Composition does not fail for
those Kinds: this role is composed before the class's own
C<k8s spec =E<gt> ...> line runs, so a C<requires 'spec'> would reject
every consumer, including the ones that do declare one.

=head2 spec_get

    my $value = $obj->spec_get($path);

Reads a value from the object's C<spec> at the dotted path C<$path>. Each
segment is a hash key, an array index (a purely numeric segment, C<-1> for
the last element), or a JSON field name on a typed C<spec> node -- an
inline struct, a referenced class, or an array/hash of either. A terminal
that is itself typed comes back as that object, not a hashref -- C<spec_get>
never serializes what it finds. Returns C<undef> if any segment along the
way is missing, C<spec> itself is unset, or the terminal value is not
defined. Never vivifies.

    my $match = $ir->spec_get('routes.0.match');

=head2 spec_set

    $obj->spec_set($path, $value);

Writes C<$value> into the object's C<spec> at the dotted path C<$path>.
Vivifies missing intermediate structure along the way: on a plain hash spec
as a hashref (or arrayref, for a numeric segment), and on a typed spec as
whatever the attribute registry declares for that field -- an inline
struct or referenced class, an array/hash container, or (via the
C<_unknown_fields> bag, D1) a plain hash for a field the class does not
declare. A hashref handed to a declared object/array/hash-of-objects slot
is inflated through the registry the same way C<FROM_HASH> would, and the
final write goes through the target's ordinary accessor, so a declared
field's own type constraint validates the value -- the wrong type croaks
the same way a direct C<< ->attr($value) >> call would. Returns C<$self>
for chaining.

Vivifying a typed intermediate constructs the declared class with no
arguments; a class with required attributes (k101) cannot be built that
way, and the call croaks naming the spec path instead -- build that object
yourself and hand it to C<spec_set> as the value.

    $ir->spec_set('tls.secretName', 'my-cert');

=head2 spec_array

    my $arrayref = $obj->spec_array($path);

Vivifies and returns the arrayref at the dotted path C<$path> -- the same
intermediate vivification as C<spec_set>, but returning the container
itself rather than storing a value into it, so the caller can push, splice
or iterate in place. Croaks if the path already holds a defined,
non-array value. Vivifies intermediates the same way C<spec_set> does,
including the required-attribute croak described there.

    push @{ $ir->spec_array('entryPoints') }, 'websecure';

=head2 spec_hash

    my $hashref = $obj->spec_hash($path);

Vivifies and returns the container at the dotted path C<$path>, so the
caller can read or write it directly: a plain hashref on an untyped node
or an opaque map field, or the struct/object itself when the declared
field is a typed struct or referenced class. Croaks if the path already
holds a defined scalar. Vivifies intermediates the same way C<spec_set>
does, including the required-attribute croak described there.

    $ir->spec_hash('tls')->{secretName} = 'my-cert';

=head2 spec_push

    $obj->spec_push($path, @values);

Appends C<@values> onto the arrayref located at the dotted path C<$path>,
vivifying it (and its parent structure, including the required-attribute
croak described under C<spec_set>) as needed via C<spec_array>; pushing
onto a path that already holds a defined, non-array value croaks rather
than replacing it. A hashref value handed to an array-of-objects slot is
inflated to the element class, same as C<spec_set>; an already-blessed
value is kept as is. Returns C<$self> for chaining.

    $ir->spec_push('routes', { match => 'Host(`api.example.com`)' });

=head2 spec_merge

    $obj->spec_merge(key1 => $value1, key2 => $value2, ...);

Shallow-merges the given key/value pairs into the top-level C<spec>,
creating it first if the object has none. On a typed spec each key is
written through its declared accessor (with inflation, as C<spec_set>
does) when the class declares it, and into the C<_unknown_fields> bag
(D1) otherwise. Existing keys are overwritten; keys not mentioned in the
merge are left alone. Returns C<$self> for chaining.

    $ir->spec_merge(entryPoints => ['web', 'websecure']);

=head2 spec_delete

    $obj->spec_delete($path);

Removes the value at the dotted path C<$path>. For a hash parent the key
is deleted; for a declared field on a typed node there is nothing to
remove, so it is cleared to C<undef> through its accessor instead --
which croaks on a C<required> field, because its type constraint is not
C<Maybe>-wrapped and rejects C<undef> the same as any other bad value.
For an array parent the indexed element is spliced out. If
the path does not resolve -- C<spec> is unset, a parent is missing, or the
terminal is undefined -- the call is a no-op. Returns C<$self> for
chaining.

    $ir->spec_delete('tls');

=head1 SEE ALSO

L<IO::K8s::APIObject>, L<IO::K8s::Role::ResourceMap>

=cut

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
