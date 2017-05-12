package Exobrain::Agent::Run;
use Moose::Role;
use Method::Signatures;
use Try::Tiny;

# ABSTRACT: Role for agents which run 'continously'
our $VERSION = '1.08'; # VERSION

with 'Exobrain::Agent';

requires('run');
excludes('poll');


method start() {
    $self->run;

    my $class = ref($self);
    my $message = "Error: $class exited run() method unexpectedly.";

    try { $self->exobrain->notify($message, priority => 1); };

    die $message;

}

1;

__END__

=pod

=head1 NAME

Exobrain::Agent::Run - Role for agents which run 'continously'

=head1 VERSION

version 1.08

=head1 METHODS

=head2 start

Called automatically by exobrain. This just wraps the C<run> method,
and signals an error should that method ever return.

=head1 AUTHOR

Paul Fenwick <pjf@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Paul Fenwick.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
