use v5.36;

package Ekorn::Pipeline::Pipes;

use Ekorn::Pipeline qw();

# Run the invocant through a pipeline of stages.
sub pipe ($self, @stages) {    ## no critic (Subroutines::ProhibitBuiltinHomonyms)
    my $pipeline = Ekorn::Pipeline->new(@stages);
    my @results  = $pipeline->($self);
    return wantarray ? @results : $results[0];
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
    my @names = $client->pipe(sub { $_->users }, sub { $_->{name} });

    # The object itself, after the stages have run for their side effects
    $client->tap(sub { $_->log('started') })->run;

=head1 DESCRIPTION

A parent class giving its children two methods, C<pipe> and C<tap>,
which run the object they're called on through a pipeline of stages,
as L<Ekorn::Pipeline> describes. The first stage is called with the
object, in C<$_> and as its argument.

L<DBIx::Squirrel>'s database and statement handles have the same two
methods, and are where they began.

=head1 METHODS

=head2 pipe

    @results = $object->pipe(@stages);
    $first   = $object->pipe(@stages);

Runs the invocant through a pipeline of C<@stages>, and returns what
comes out of the last one. In scalar context, it returns the first of
them, or C<undef> if there are none. With no stages, it returns the
invocant.

=head2 tap

    $object = $object->tap(@stages);

Runs the invocant through a pipeline of C<@stages> for their side
effects, and returns the invocant, whatever comes out of the stages,
so a chain of method calls can carry on after it.

=head1 SEE ALSO

L<Ekorn::Pipeline>, L<Ekorn::Pipeline::Stages::Taps>

=head1 AUTHOR

Iain Campbell E<lt>cpanic@cpan.orgE<gt>

=head1 LICENSE

Copyright (c) 2024-2026 by Iain Campbell.

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.

=cut
