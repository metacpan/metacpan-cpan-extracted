use v5.36;

package Ekorn::Pipeline::Element;

use namespace::clean;

# Called as a code reference, an element calls the closure it holds,
# which never refers to the element itself, so the element is freed as
# soon as nothing else holds it.
use overload '&{}' => sub ($self, @) { $self->{call} }, fallback => 1;

# Call the element, as calling it as a code reference does.
sub call ($self, @arguments) {
    return $self->{call}->(@arguments);
}


1;

__END__

=encoding utf8

=head1 NAME

Ekorn::Pipeline::Element - what Ekorn's types are made from

=head1 SYNOPSIS

    my $p = Ekorn::Pipeline->new(sub { uc });

    $p->('a', 'b');           # called as a code reference
    $p->call('a', 'b');       # the same, as a method

=head1 DESCRIPTION

Each of Ekorn's types is an element: a pipeline, a stage, a gather, a
source, a sink and an iterator. An element is an object that can be
called as a code reference, and what that does is each type's own: a
pipeline runs the values it's given through its stages; an iterator
hands out its next value.

An element holds the closure it's called as, and that closure never
refers to the element itself. So an element is freed as soon as
nothing else holds it, and an iterator let go ends its run there and
then.

You needn't make an element, or know that one is: give Ekorn's types
where they go. A part of your own that should work with Ekorn offers
its role methods instead, as
L<Ekorn::Pipeline::Manual::Reference/Delivering parts for Ekorn>
describes, and needn't be an element.

=head1 METHODS

=head2 call

    $element->call(@arguments)

Calls the element with C<@arguments>, as calling it as a code
reference does, and returns what that returns.

=head1 SEE ALSO

L<Ekorn::Pipeline>, L<Ekorn::Pipeline::Stage>,
L<Ekorn::Pipeline::Gather>, L<Ekorn::Pipeline::Source>,
L<Ekorn::Pipeline::Sink> and L<Ekorn::Pipeline::Iterator>

=head1 AUTHOR

Iain Campbell E<lt>cpanic@cpan.orgE<gt>

=head1 LICENSE

Copyright (c) 2024-2026 by Iain Campbell.

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.

=cut
