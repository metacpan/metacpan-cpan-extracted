package List::Haystack;
use 5.008001;
use strict;
use warnings;
use Carp qw/croak/;

our $VERSION = "0.01";

sub new {
    my ($class, $list, $options) = @_;

    if (not defined $list) {
        $list = [];
    }

    if (ref $list ne 'ARRAY') {
         croak 'Type of given argument `$list` is not suitable. It must be array reference.';
    }

    my $self = bless {
        list => $list,
    }, $class;

    my $lazy = defined $options && ref($options) eq 'HASH' && $options->{lazy};
    if (not $lazy) {
        $self->_construct_haystack;
    }

    return $self;
}

sub haystack {
    my ($self) = @_;

    my $haystack = $self->{haystack};
    if (defined $haystack) {
        return $haystack;
    }

    # For lazy building
    return $self->_construct_haystack;
}

sub find {
    my ($self, $needle) = @_;

    return exists($self->haystack->{$needle}) ? 1 : 0;
}

sub cnt {
    my ($self, $needle) = @_;

    return $self->haystack->{$needle} || 0;
}

sub _construct_haystack {
    my ($self) = @_;

    my %haystack;
    for my $item (@{($self->{list})}) {
        $haystack{$item}++;
    }

    $self->{haystack} = \%haystack;
}

1;
__END__

=encoding utf-8

=head1 NAME

List::Haystack - A immutable list utility to find element

=head1 SYNOPSIS

=head3 Basic (not lazy mode)

    use List::Haystack;

    my $haystack = List::Haystack->new([qw/foo bar foo/]); # <= create internal structure here

    $haystack->find('foo'); # <= 1 (true value)
    $haystack->find('bar'); # <= 1 (true value)
    $haystack->find('xxx'); # <= 0 (false value)

    $haystack->cnt('foo'); # <= 2 (number of occurrences)
    $haystack->cnt('bar'); # <= 1 (number of occurrences)
    $haystack->cnt('xxx'); # <= 0 (number of occurrences)

=head3 Lazy

    use List::Haystack;

    my $haystack = List::Haystack->new([qw/foo bar foo/], {lazy => 1});

    $haystack->find('foo'); # <= 1 (true value, create internal structure here)
    $haystack->find('bar'); # <= 1 (true value)
    $haystack->find('xxx'); # <= 0 (false value)

    $haystack->cnt('foo'); # <= 2 (number of occurrences)
    $haystack->cnt('bar'); # <= 1 (number of occurrences)
    $haystack->cnt('xxx'); # <= 0 (number of occurrences)

=head1 DESCRIPTION

List::Haystack is a utility to find element for list. This module works B<immutably>.

This module converts the given list to internal structure to find the element fast. This conversion runs only at once.
That is to say, if you want to modify the target of list, you must create new instance of this module.

=head1 METHODS

=head2 C<new($list: ArrayRef|undef, $option: HashRef): List::Haystack>

A constructor.  C<$list> is a target of list to find. It must be ArrayRef or undef; if undef is given, C<find> and C<cnt> always return 0.

C<$option> is an HashRef argument of option. If you specify C<lazy>, it puts off creation the internal structure until instance method is called (i.e. constructor doesn't create internal structure).

e.g.
    List::Haystack->new([...], {lazy => 1}

=head2 C<haystack(): HashRef>

A getter method. This method returns a HashRef that contains element as key and number of occurrences as value.

=head2 C<find($element: Any): Bool>

This method returns whether given list contains C<$element> or not.

=head2 C<cnt($element: Any): Int>

This method returns number of occurrences of given C<$element>.

=head1 LICENSE

Copyright (C) moznion.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

moznion E<lt>moznion@gmail.comE<gt>

=cut

