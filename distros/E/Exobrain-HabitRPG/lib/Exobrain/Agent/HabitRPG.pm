package Exobrain::Agent::HabitRPG;
use Moose::Role;
use Method::Signatures;

with 'Exobrain::Agent';

# ABSTRACT: Roles for to HabitRPG agents
our $VERSION = '0.01'; # VERSION


sub component_name { "HabitRPG" }


has habitrpg => (
    isa => 'WebService::HabitRPG', is => 'ro', lazy => 1, builder => '_build_habit',
);

method _build_habit() {
    my $config = $self->config;

    my $api_token = $config->{api_token} or die "API token not found";
    my $user_id   = $config->{user_id}   or die "User ID not found";

    # Lazy load our module
    eval "use WebService::HabitRPG; 1;" or die $@;

    return WebService::HabitRPG->new(
        api_token => $api_token,
        user_id   => $user_id,
    );
}

1;

__END__

=pod

=head1 NAME

Exobrain::Agent::HabitRPG - Roles for to HabitRPG agents

=head1 VERSION

version 0.01

=head1 SYNOPSIS

    use Moose;
    with 'Exobrain::Agent::HabitRPG'

=head1 DESCRIPTION

This role provides useful methods and attributes for agents wishing
to integrate with the HabitRPG web service.

=head1 METHODS

=head2 habitrpg

    my $tasks = $self->habitrpg->tasks;

Returns an authenticated, connected, L<WebService::HabitRPG> object.

=for Pod::Coverage component_name

=head1 AUTHOR

Paul Fenwick <pjf@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Paul Fenwick.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
