package Hash::Fold;

use Carp qw(confess);
use Moose;
use Scalar::Util qw(refaddr);

use Sub::Exporter -setup => {
    exports => [
        (map { $_ => \&_build_unary_export } qw(fold unfold flatten unflatten)),
        (map { $_ => \&_build_nary_export  } qw(merge)),
    ],
};

use constant {
    ARRAY => 1,
    HASH  => 2,
    TYPE  => 0,
    VALUE => 1,
};

our $VERSION = '0.1.2';

has on_object => (
    isa      => 'CodeRef',
    is       => 'ro',
    default  => sub { sub { $_[1] } }, # return the value unchanged
);

has on_cycle => (
    isa      => 'CodeRef',
    is       => 'ro',
    default  => sub { sub { } }, # do nothing
);

has hash_delimiter => (
    isa      => 'Str',
    is       => 'ro',
    default  => '.',
);

has array_delimiter => (
    isa      => 'Str',
    is       => 'ro',
    default  => '.',
);

around BUILDARGS => sub {
    my $original = shift;
    my $class = shift;
    my $args = $class->$original(@_);
    my $delimiter = delete $args->{delimiter};

    if (defined $delimiter) {
        $args->{array_delimiter} = $delimiter
            unless (exists $args->{array_delimiter});

        $args->{hash_delimiter}  = $delimiter
            unless (exists $args->{hash_delimiter});
    }

    return $args;
};

sub fold {
    my $self = shift;
    my $hash = _check_hash(shift);
    my $prefix = undef;
    my $target = {};
    my $seen = {};

    return $self->_merge($hash, $prefix, $target, $seen);
}

sub unfold {
    my $self = shift;
    my $hash = _check_hash(shift);
    my $target = {};

    # sorting the keys should lead to better locality of reference,
    # for what that's worth here
    # XXX the sort order is connected with the ambiguity issue mentioned below
    for my $key (sort keys %$hash) {
        my $value = $hash->{$key};
        my $steps = $self->_split($key);
        $self->_set($target, $steps, $value);
    }

    return $target;
}

BEGIN {
    *flatten   = \&fold;
    *unflatten = \&unfold;
}

sub merge {
    my $self = shift;
    return $self->unfold({ map { %{ $self->fold(_check_hash($_)) } } @_ });
}

sub is_object {
    my ($self, $value) = @_;
    my $ref = ref($value);
    return $ref && ($ref ne 'HASH') && ($ref ne 'ARRAY');
}

sub _build_unary_export {
    my ($class, $name, $base_options) = @_;

    return sub {
        my $arg = shift;
        my $custom_options = @_ == 1 ? shift : { @_ };
        my $folder = $class->new({ %$base_options, %$custom_options });
        return $folder->$name($arg);
    }
}

sub _build_nary_export {
    my ($class, $name, $base_options) = @_;

    return sub {
        my ($args, $custom_options);

        if (@_ && (ref($_[0]) eq 'ARRAY')) {
            $args = shift;
            $custom_options = @_ == 1 ? shift : { @_ };
        } else {
            $args = [ @_ ];
            $custom_options = {};
        }

        my $folder = $class->new({ %$base_options, %$custom_options });
        return $folder->$name(@$args);
    }
}

sub _check_hash {
    my $hash = shift;
    my $ref = ref($hash);

    unless ($ref eq 'HASH') {
        my $type;

        if (defined $hash) {
            $type = length($ref) ? "'$ref'" : 'non-reference';
        } else {
            $type = 'undef';
        }

        confess "invalid argument: expected unblessed HASH reference, got: $type";
    }

    return $hash;
}

sub _join {
    my ($self, $prefix, $delimiter, $key) = @_;
    return defined($prefix) ? $prefix . $delimiter . $key : $key;
}

=begin comment

TODO: when the hash delimiter is the same as the array delimiter
(as it is by default), ambiguities can arise:

    {
        foo => 'bar',
        1   => 'aaagh!',
        baz => 'quux',
    }

In many cases, these can be smartly resolved by looking at the context: if
at least one step is non-numeric, then the container must be a hashref:

    foo.bar.baz
    foo.bar.0   <- must be a hash key
    foo.bar.quux

The ambiguity can either be resolved here/in unfold with a bit of static
analysis or resolved lazily/dynamically in _set (need to sort the keys so
that non-integers (if any) are unpacked before integers (if any)).

Currently, the example above is unpacked correctly :-)

=end comment

=cut

sub _split {
    my ($self, $path) = @_;
    my $hash_delimiter = $self->hash_delimiter;
    my $array_delimiter = $self->array_delimiter;
    my $hash_delimiter_pattern = quotemeta($hash_delimiter);
    my $array_delimiter_pattern = quotemeta($array_delimiter);
    my $same_delimiter = $array_delimiter eq $hash_delimiter;
    my $split_pattern = length($hash_delimiter) >= length($array_delimiter)
        ? qr{((?:$hash_delimiter_pattern)|(?:$array_delimiter_pattern))}
        : qr{((?:$array_delimiter_pattern)|(?:$hash_delimiter_pattern))};
    my @split = split $split_pattern, $path;
    my @steps;

    # since we require the argument to fold (and unfold) to be a hashref,
    # the top-level keys must always be hash keys (strings) rather than
    # array indices (numbers)
    push @steps, [ HASH, shift @split ];

    while (@split) {
        my $delimiter = shift @split;
        my $step = shift @split;

        if ($same_delimiter) {
            # tie-breaker
            if (($step eq '0') || ($step =~ /^[1-9]\d*$/)) { # no leading 0
                push @steps, [ ARRAY, $step ];
            } else {
                push @steps, [ HASH, $step ];
            }
        } else {
            if ($delimiter eq $array_delimiter) {
                push @steps, [ ARRAY, $step ];
            } else {
                push @steps, [ HASH, $step ];
            }
        }
    }

    return \@steps;
}

sub _merge {
    my ($self, $value, $target_key, $target, $_seen) = @_;

    # "localize" the $seen hash: we want to catch circular references (i.e.
    # an unblessed hashref or arrayref which contains (at some depth) a
    # reference to itself), but don't want to prevent repeated references
    # e.g. { foo => $object, bar => $object } is OK. To achieve this, we need
    # to "localize" the $seen hash i.e. do the equivalent of "local $seen".
    # However, perl doesn't allow lexical variables to be localized, so we have
    # to do it manually.

    # isolate from the caller's $seen hash and allow scoped additions
    my $seen = { %$_seen };

    if ($self->is_object($value)) {
        $value = $self->on_object->($self, $value);
    }

    my $ref = ref($value);
    my $refaddr = refaddr($value);

    if ($refaddr && $seen->{$refaddr}) { # seen HASH or ARRAY
        # we've seen this unblessed hashref/arrayref before: possible actions
        #
        #     1) (do nothing and) treat it as a terminal
        #     2) warn and treat it as a terminal
        #     3) die (and treat it as a terminal :-)
        #
        # if the callback doesn't raise a fatal exception,
        # treat the value as a terminal
        $self->on_cycle->($self, $value); # might warn or die
        $target->{$target_key} = $value; # treat as a terminal
    } elsif ($ref eq 'HASH') {
        my $delimiter = $self->hash_delimiter;

        $seen->{$refaddr} = 1;

        if (%$value) {
            # sorting the keys ensures a deterministic order,
            # which (at the very least) is required for unsurprising
            # tests
            for my $hash_key (sort keys %$value) {
                my $hash_value = $value->{$hash_key};
                $self->_merge(
                    $hash_value,
                    $self->_join($target_key, $delimiter, $hash_key),
                    $target, $seen
                );
            }
        } else {
            $target->{$target_key} = {};
        }
    } elsif ($ref eq 'ARRAY') {
        my $delimiter = $self->array_delimiter;

        $seen->{$refaddr} = 1;

        if (@$value) {
            for my $index (0 .. $#$value) {
                my $array_element = $value->[$index];

                $self->_merge(
                    $array_element,
                    $self->_join($target_key, $delimiter, $index),
                    $target, $seen
                );
            }
        } else {
            $target->{$target_key} = [];
        }
    } else { # terminal
        $target->{$target_key} = $value;
    }

    return $target;
}

# the action depends on the number of steps:
#
#     1: e.g. [ 'foo' ]:
#
#        $context->{foo} = $value
#
#     2: e.g. [ 'foo', 42 ]:
#
#        $context = $context->{foo} ||= []
#        $context->[42] = $value
#
#     3 (or more): e.g. [ 'foo', 42, 'bar' ]:
#
#        $context = $context->{foo} ||= []
#        return $self->_set($context, [ 42, 'bar' ], $value)
#
# Note that the 2 case can be implemented in the same way as the 3
# (or more) case.

sub _set {
    my ($self, $context, $steps, $value) = @_;
    my $step = shift @$steps;

    if (@$steps) { # recursive case
        # peek i.e. look-ahead to the step that will be processed in
        # the tail call and make sure its container exists
        my $next_step = $steps->[0];
        my $next_step_container = sub { $next_step->[TYPE] == ARRAY ? [] : {} };

        $context = ($step->[TYPE] == ARRAY) ?
            ($context->[ $step->[VALUE] ] ||= $next_step_container->()) : # array index
            ($context->{ $step->[VALUE] } ||= $next_step_container->());  # hash key
    } else { # base case
        if ($step->[TYPE] == ARRAY) {
            $context->[ $step->[VALUE] ] = $value; # array index
        } else {
            $context->{ $step->[VALUE] } = $value; # hash key
        }
    }

    return @$steps ? $self->_set($context, $steps, $value) : $value;
}

__PACKAGE__->meta->make_immutable;

1;

=head1 NAME

Hash::Fold - flatten and unflatten nested hashrefs

=head1 SYNOPSIS

    use Hash::Fold qw(flatten unflatten);

    my $object = bless { foo => 'bar' };

    my $nested = {
        foo => $object,
        baz => {
            a => 'b',
            c => [ 'd', { e => 'f' }, 42 ],
        },
    };

    my $flattened = flatten($nested);

    is_deeply $flattened, {
        'baz.a'     => 'b',
        'baz.c.0'   => 'd',
        'baz.c.1.e' => 'f',
        'baz.c.2'   => 42,
        'foo'       => $object,
    };

    my $roundtrip = unflatten($flattened);

    is_deeply $roundtrip, $nested;

=head1 DESCRIPTION

This module provides functional and OO interfaces which can be used to flatten,
unflatten and merge nested hashrefs.

Unless noted, the functions listed below are also available as methods. Options
provided to the Hash::Fold constructor can be supplied to the functions e.g.:

    use Hash::Fold;

    my $folder = Hash::Fold->new(delimiter => '/');

    $folder->fold($hash);

is equivalent to:

    use Hash::Fold qw(fold);

    my $folded = fold($hash, delimiter => '/');

Options (and constructor args) can be supplied as a list of key/value pairs or
a hashref, so the following are equivalent:

    my $folded = fold($hash,   delimiter => '/'  );
    my $folded = fold($hash, { delimiter => '/' });

In addition, Hash::Fold uses L<Sub::Exporter>, which allows functions to be
imported with options baked in e.g.:

    use Hash::Fold fold => { delimiter => '/' };

    my $folded = fold($hash);

=head1 OPTIONS

As described above, the following options can be supplied as constructor args,
import args, or per-function overrides. Under the hood, they are (L<Moose>)
attributes which can be wrapped and overridden like any other attributes.

=head2 array_delimiter

B<Type>: Str, ro, default: "."

The delimiter prefixed to array elements when flattening and unflattening.

=head2 hash_delimiter

B<Type>: Str, ro, default: "."

The delimiter prefixed to hash elements when flattening and unflattening.

=head2 delimiter

B<Type>: Str

This is effectively a write-only attribute which assigns the same string to
L<"array_delimiter"> and L<"hash_delimiter">. It can only be supplied as a
constructor arg or function option (which are equivalent) i.e. Hash::Fold
instances have no C<delimiter> method.

=head2 on_cycle

B<Type>: (Hash::Fold, Ref) -> None, ro

A callback invoked whenever L<"fold"> encounters a circular reference i.e. a
reference which contains itself as a nested value.

The callback takes two arguments: the Hash::Fold instance and the value e.g.:

    sub on_cycle {
        my ($folder, $value) = @_;
        warn 'self-reference found: ', Dumper(value), $/;
    }

    my $folder = Hash::Fold->new(on_cycle => \&on_cycle);

Note that circular references are handled correctly i.e. they are treated as
terminals and not traversed. This callback merely provides a mechanism to
report them (e.g. by issuing a warning).

The default callback does nothing.

=head2 on_object

B<Type>: (Hash::Fold, Ref) -> Any, ro

A callback invoked whenever L<"fold"> encounters a value for which the
L<"is_object"> method returns true i.e. any reference that isn't an unblessed
arrayref or unblessed hashref. This callback can be used to modify
the value e.g. to return a traversable value (e.g. unblessed hashref)
in place of a terminal (e.g.  blessed hashref).

The callback takes two arguments: the Hash::Fold instance and the object e.g.:

    use Scalar::Util qw(blessed);

    sub on_object {
        my ($folder, $value) = @_;

        if (blessed($value) && $value->isa('HASH')) {
            return { %$value }; # unbless
        } else {
            return $value;
        }
    }

    my $folder = Hash::Fold->new(on_object => \&on_object);

The default callback returns its value unchanged.

=head1 EXPORTS

Nothing by default. The following functions can be imported.

=head2 fold

B<Signature>: (HashRef [, Hash|HashRef ]) -> HashRef

Takes a nested hashref and returns a single-level hashref with (by default)
dotted keys. The delimiter can be overridden via the L<"delimiter">,
L<"array_delimiter"> and L<"hash_delimiter"> options.

Unblessed arrayrefs and unblessed hashrefs are traversed. All other values
(e.g. strings, regexps, objects &c.) are treated as terminals and passed
through verbatim, although this can be overridden by supplying a suitable
L<"on_object"> callback.

=head2 flatten

B<Signature>: (HashRef [, Hash|HashRef ]) -> HashRef

Provided as an alias for L<"fold">.

=head2 unfold

B<Signature>: (HashRef [, Hash|HashRef ]) -> HashRef

Takes a flattened hashref and returns the corresponding nested hashref.

=head2 unflatten

B<Signature>: (HashRef [, Hash|HashRef ]) -> HashRef

Provided as an alias for L<"unfold">.

=head2 merge

B<Signature>: (HashRef [, HashRef... ]) -> HashRef

B<Signature>: (ArrayRef[HashRef] [, Hash|HashRef ]) -> HashRef

Takes a list of hashrefs which are then flattened, merged into one (in the
order provided i.e.  with precedence given to the rightmost arguments) and
unflattened i.e. shorthand for:

    unflatten { map { %{ flatten $_ } } @_ }

To provide options to the C<merge> subroutine, pass the hashrefs in an
arrayref, and the options (as usual) as a list of key/value pairs or a hashref:

    merge([ $hash1, $hash2, ... ],   delimiter => ...  )
    merge([ $hash1, $hash2, ... ], { delimiter => ... })

=head1 METHODS

=head2 is_object

B<Signature>: Any -> Bool

This method is called from L<"fold"> to determine whether a value should be
passed to the L<"on_object"> callback.

It is passed each value encountered while traversing a hashref and returns true
for all references (e.g.  regexps, globs, objects &c.) apart from unblessed
arrayrefs and unblessed hashrefs, and false for all other
values (i.e. unblessed hashrefs, unblessed arrayrefs, and non-references).

=head1 VERSION

0.1.2

=head1 SEE ALSO

=over

=item * L<CGI::Expand>

=item * L<Hash::Flatten>

=item * L<Hash::Merge>

=item * L<Hash::Merge::Simple>

=back

=head1 AUTHOR

chocolateboy <chocolate@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2014-2015, chocolateboy.

This module is free software. It may be used, redistributed and/or modified
under the same terms as Perl itself.

=cut
