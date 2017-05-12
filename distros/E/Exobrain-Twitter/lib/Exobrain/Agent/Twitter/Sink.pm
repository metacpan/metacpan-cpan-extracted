package Exobrain::Agent::Twitter::Sink;
use Moose;
use Method::Signatures;

our $VERSION = '1.04'; # VERSION
# ABSTRACT: Sink agent for exobrain/twitter

with 'Exobrain::Agent::Twitter';
with 'Exobrain::Agent::Run';

method run() {
    # Start by initialising our twitter object, so we fail
    # quickly if anything might go wrong there.

    $self->twitter;

    # Now watch for intents and process them.

    $self->exobrain->watch_loop(
        class => 'Intent::Tweet',
        then => sub {
            my $event = shift;

            if (my $reply = $event->in_response_to) {
                $self->twitter->update({
                    status                => $event->tweet,
                    in_reply_to_status_id => $reply,
                });
            }
            else {
                $self->twitter->update($event->tweet);
            }
        },
    );
}

1;

__END__

=pod

=head1 NAME

Exobrain::Agent::Twitter::Sink - Sink agent for exobrain/twitter

=head1 VERSION

version 1.04

=head1 AUTHOR

Paul Fenwick <pjf@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Paul Fenwick.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
