package Exobrain::Agent::Twitter::Response;
use Moose;
use Method::Signatures;

our $VERSION = '1.04'; # VERSION
# ABSTRACT: Spots respones bound for twitter, and sends them

with 'Exobrain::Agent::Twitter';
with 'Exobrain::Agent::Run';

method run() {
    # Watches for twitter responses, and translates them.

    $self->exobrain->watch_loop(
        class  => 'Intent::Response',
        filter => sub { $_->platform eq $self->component },
        then => sub {
            my $event = shift;
            my $text  = '@' . $event->to . ': ' . $event->text;
            $event->exobrain->intent('Tweet',
                to             => $event->to,
                in_response_to => $event->in_response_to,
                tweet          => $text,
                # TODO - Handle a DM (private) flag if passed
            );
        },
    );
}

1;

__END__

=pod

=head1 NAME

Exobrain::Agent::Twitter::Response - Spots respones bound for twitter, and sends them

=head1 VERSION

version 1.04

=head1 AUTHOR

Paul Fenwick <pjf@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Paul Fenwick.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
