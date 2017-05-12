package Exobrain::Agent::Depends;
use Moose::Role;
use Method::Signatures;

# ABSTRACT: Allow agents to declare run-time dependencies
our $VERSION = '1.08'; # VERSION


requires 'depends';

method check_dependencies() {
    # Returns true if dependencies could be loaded, false otherwise
    return eval { $self->load_dependencies; 1; }
}

method load_dependencies() {
    foreach my $dep ($self->depends) {
        eval "use Exobrain::$dep; 1;" or die $@;
    }
}

no warnings 'redefine';

sub BUILD {};

after BUILD => method(...) {
    $self->load_dependencies;
};

1;

__END__

=pod

=head1 NAME

Exobrain::Agent::Depends - Allow agents to declare run-time dependencies

=head1 VERSION

version 1.08

=head1 SYNOPSIS

    use Moose;
    with 'Exobrain::Agent::Depends';

    sub depends { return qw(Measurement::Foo Intent::bar) }

=head1 DESCRIPTION

This role allows an agent to declare run-time dependencies. This has the
following advantages:

=over

=item *

It allows agents to be written which do not cause hard dependencies
in their distribution. This avoids dependency bloat.

=item *

It allows the exobrain framework to determine if it could conceivably
run an agent, allowing it not to be shown if the dependencies are
not satisfied

=item *

It allows for all the dependencies to be pre-loaded upon agent creation,
resulting in a "fail-fast" operation if goes awry.

=back

All dependencies are currently prefixed with C<Exobrain::>.

=for Pod::Coverage BUILD

=head1 AUTHOR

Paul Fenwick <pjf@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Paul Fenwick.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
