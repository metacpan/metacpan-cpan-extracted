use v5.36;

package Ekorn::Pipeline::Pipes;

use Ekorn::Pipeline qw();

our $VERSION = 'v0.4.2';

# Return what a run of the stages gives, the invocant its one value, as
# a pipeline of them called with it gives it, in either context: what
# comes out of the last stage; in scalar context, how many did, or a
# sink's result.
sub pipe ($self, @stages) {    ## no critic (Subroutines::ProhibitBuiltinHomonyms)
    return Ekorn::Pipeline->new(@stages)->($self);
}

# Run the invocant through a pipeline of stages for their side effects, and
# return the invocant.
sub tap ($self, @stages) {
    my $pipeline = Ekorn::Pipeline->new(@stages);
    $pipeline->($self);
    return $self;
}

1;
__END__

=encoding utf8

=for stopwords invocant

=head1 NAME

Ekorn::Pipeline::Pipes - pipe and tap methods, running an object through stages

=head1 SYNOPSIS

    package My::Client;

    use parent 'Ekorn::Pipeline::Pipes';

    package main;

    my $client = My::Client->new;

    # What the stages make of the object
    my @names = $client->pipe(
        sub { $_->users },
        sub { $_->{name} },
    );

    # The object itself, after the stages have run for their side effects
    $client->tap(sub { $_->log('started') })->run;

=head1 DESCRIPTION

A parent class that gives its children two methods, C<pipe> and
C<tap>. Each runs the object it's called on through a pipeline of
stages, as described in L<Ekorn::Pipeline>. The first stage is called
with the object, in C<$_> and as its argument.

L<DBIx::Squirrel>'s database and statement handles have the same two
methods, and are where they began.

=head1 METHODS

=head2 pipe

    @results = $object->pipe(@stages);
    $count   = $object->pipe(@stages);
    ($first) = $object->pipe(@stages);
    $first   = $object->pipe(@stages, keep_first);

Runs the invocant through a pipeline of C<@stages>, and returns what
the run gives, as C<< Ekorn::Pipeline->new(@stages)->($object) >>
would, in either context: what comes out of the last stage; in scalar
context, how many results came out, or, if a sink is last, the sink's
result, a list sink's as an array reference, as
L<Ekorn::Pipeline/new> describes. For one value, read it in list
context, or end with a sink of one, such as C<keep_first>. With no
stages, it gives the invocant, or, in scalar context, 1.

The stages are what L<Ekorn::Pipeline/new> takes: code references
and pipelines, not names. To use a named pipeline, pass
C<pipeline('clean')> (see L<Ekorn::Pipeline::Factories/pipeline>).

Until v0.4.0, in scalar context, it gave the first result, or
C<undef>, unlike a pipeline; a list sink's first value, not its
list. Code that reads one value from it in scalar context, as
C<< my $name = $object->pipe(sub { $_->name }) >>, reads it in list
context now, C<< my($name) = ... >>, or ends with C<keep_first>.

=head2 tap

    $object = $object->tap(@stages);

Runs the invocant through a pipeline of C<@stages> for their side
effects, and returns the invocant, whatever the stages return. A chain
of method calls can carry on after it.

=head1 SEE ALSO

L<Ekorn::Pipeline>, L<Ekorn::Pipeline::Stages::Taps>

=head1 AUTHOR

Iain Campbell E<lt>cpanic@cpan.orgE<gt>

=head1 LICENSE

Copyright (c) 2024-2026 by Iain Campbell.

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.

=cut
