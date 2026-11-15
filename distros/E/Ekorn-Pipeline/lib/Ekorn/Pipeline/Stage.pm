use v5.36;

package Ekorn::Pipeline::Stage;

use parent 'Ekorn::Pipeline::Element';

use experimental            qw(builtin);
use builtin                 qw(blessed);
use overload                qw();
use Ref::Util               qw(is_coderef);
use Ekorn::Pipeline::Errors qw(croakf);
use namespace::clean;

# Croak at the line that called Ekorn::Pipeline.
our @CARP_NOT = @Ekorn::Pipeline::Errors::INTERNAL;

# Return a stage of the code given, which is kept as it is, never
# blessed: a code reference, or an object called as one that isn't
# itself one of Ekorn's types. An object's code is found once, here, as
# a run takes a step that's a code reference.
sub new ($class, $code) {
    my $callable
        = is_coderef($code) || (blessed($code) && overload::Method($code, '&{}'));
    croakf 'Expected a code reference' unless $callable;
    croakf q(Expected a code reference, not one of Ekorn's types)
        if $code isa 'Ekorn::Pipeline::Element';
    return bless {call => is_coderef($code) ? $code : \&$code, code => $code},
        $class;
}


# Return the code the stage was made of.
sub code ($self) {
    return $self->{code};
}


# Return the stage's step for a new run: its code, as a code reference.
sub EKORN_STAGE ($self) {
    return $self->{call};
}

1;

__END__

=encoding utf8

=head1 NAME

Ekorn::Pipeline::Stage - a stage, as an object

=head1 SYNOPSIS

    use Ekorn::Pipeline::Stage;

    my $upper = Ekorn::Pipeline::Stage->new(sub { uc });

    Ekorn::Pipeline->new($upper)->('a', 'b');    # A B

=head1 DESCRIPTION

A stage is a code reference, called with each value, in C<$_> and as
its argument, returning a list: nothing to drop the value, one to pass
it on, several to pass on each. L<Ekorn::Pipeline/new> keeps each
code reference it's given as a stage object, of this class, so that
every part of a pipeline is one of Ekorn's types. You needn't make one
yourself.

Called directly, as a code reference, a stage calls its code with what
it's given, as its arguments, but doesn't set C<$_>: only a run does.

The code it's made of is kept as it is, never blessed, so the same code
reference can go on being used elsewhere. A stage is the same code in
every run; a stage that keeps state from one value to the next is made
with L<Ekorn::Pipeline::Gather>, made afresh for each run.

The word C<stage {...}>, in L<Ekorn::Pipeline::Factories>, makes one of
these from a block.

=head1 METHODS

=head2 new

    my $stage = Ekorn::Pipeline::Stage->new($code);

Returns a stage of C<$code>: a code reference, or an object that can
be called as one, other than one of Ekorn's own types, which are
already what they are. Anything else croaks.

=head2 code

    my $code = $stage->code;

Returns the code the stage was made of.

=head2 EKORN_STAGE

    my $step = $stage->EKORN_STAGE;

Returns the stage's step for a new run: its code, or, for an object
called as a code reference, the code it gives. A run calls it as it
starts; you needn't.

=head1 DIAGNOSTICS

=over

=item Expected a code reference

L</new> was given something that can't be called as code, such as a
string.

=item Expected a code reference, not one of Ekorn's types

L</new> was given one of Ekorn's own types, which is already what it
is.

=back

=head1 SEE ALSO

L<Ekorn::Pipeline>, L<Ekorn::Pipeline::Gather>

=head1 AUTHOR

Iain Campbell E<lt>cpanic@cpan.orgE<gt>

=head1 LICENSE

Copyright (c) 2024-2026 by Iain Campbell.

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.

=cut
