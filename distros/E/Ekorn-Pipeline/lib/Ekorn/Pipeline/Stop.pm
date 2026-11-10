use v5.36;

package Ekorn::Pipeline::Stop;

use Carp     qw(croak);
use Exporter qw(import);

use namespace::clean -except => 'import';

use overload '""' => sub { "Stop used outside a pipeline\n" }, fallback => 1;

our @EXPORT = qw(Stop);    ## no critic (Modules::ProhibitAutomaticExportation)

# Syntactic sugar throwing the exception that stops a pipeline early.
sub Stop (@data) {
    return __PACKAGE__->throw(@data);
}

# Throws an exception that stops a pipeline early.
sub throw ($class, @data) {
    croak bless([$class, @data], $class);
}

1;
__END__

=encoding utf8

=head1 NAME

Ekorn::Pipeline::Stop - end a pipeline early

=head1 SYNOPSIS

    use Ekorn::Pipeline::Stop;

    # In a stage of a pipeline
    sub ($value) { Stop() if $done; ... }

    # Stop, passing on a last value
    sub ($user) { $user->{id} == $wanted ? Stop($user) : () }

    # The same, without importing Stop
    sub ($value) { Ekorn::Pipeline::Stop->throw if $done; ... }

=head1 DESCRIPTION

A stop is the exception that ends a pipeline early and quietly. The
rest of the stage that throws it doesn't run. The values already out
of the pipeline are kept, and the values the stop carries go on
through the stages after it. Nothing else is processed. Stages after
the one that stopped still have their end functions called, if they
were made with L<Ekorn::Pipeline::Gather>.

=head1 FUNCTIONS

=head2 Stop

    Stop();
    Stop(@values);

Throws a stop carrying C<@values>, the last values of the stage that
throws it. It's the same as
C<< Ekorn::Pipeline::Stop->throw(@values) >>. It's exported by
default.

To keep it out of your namespace:

    use Ekorn::Pipeline::Stop ();

=head1 METHODS

=head2 throw

    Ekorn::Pipeline::Stop->throw;
    Ekorn::Pipeline::Stop->throw(@values);
    My::Stop->throw(@values);

Throws a stop carrying C<@values>, blessed into the class it was
called on. A subclass of Ekorn::Pipeline::Stop throws a stop of its
own class.

=head1 THE STOP

A stop is an array reference, blessed into its class. Its first element
is that class, and the rest are the values it was thrown with:

    eval { Ekorn::Pipeline::Stop->throw(1, 2) };
    my $stop = $@;    # bless ['Ekorn::Pipeline::Stop', 1, 2], 'Ekorn::Pipeline::Stop'

A pipeline sends those values on through the stages after the one that
threw it, as that stage's last values.

As a string, a stop is "Stop used outside a pipeline", with a newline.
That's what a user sees if one is thrown with nothing to catch it.

A stop that isn't an array, made without C<throw> (by blessing a hash
into the class, say), still stops the pipeline, but carries nothing.

=head2 Catching errors in a stage

A pipeline recognises a stop with C<isa>, so a subclass of
Ekorn::Pipeline::Stop stops it too. A stage that catches errors
itself, with C<eval> or C<try>, should throw a stop again:

    sub ($value) {
        try { ... }
        catch ($e) {
            die $e if $e isa 'Ekorn::Pipeline::Stop';
            ...
        }
    }

=head1 DIAGNOSTICS

=over

=item Stop used outside a pipeline

A stop was thrown where no pipeline was running to catch it.

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
