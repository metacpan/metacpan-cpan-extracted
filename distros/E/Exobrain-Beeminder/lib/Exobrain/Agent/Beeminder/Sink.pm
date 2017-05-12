package Exobrain::Agent::Beeminder::Sink;
use Moose;
use Method::Signatures;
use WebService::Beeminder;

with 'Exobrain::Agent::Beeminder';
with 'Exobrain::Agent::Run';

# ABSTRACT: Send exobrain intents to Beeminder
our $VERSION = '1.06'; # VERSION

method run() {
    my $bee = WebService::Beeminder->new(
        token => $self->config->{auth_token}
    );

    $self->exobrain->watch_loop(
        class => 'Intent::Beeminder',
        then  => sub {
            my $event = shift;
            $bee->add_datapoint(
                goal    => $event->goal,
                value   => $event->value,
                comment => $event->comment // "",
            );
        }
    );
}

1;

__END__

=pod

=head1 NAME

Exobrain::Agent::Beeminder::Sink - Send exobrain intents to Beeminder

=head1 VERSION

version 1.06

=head1 AUTHOR

Paul Fenwick <pjf@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Paul Fenwick.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
