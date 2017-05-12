package Exobrain::Agent::Action::Ping;
use Moose;
use Method::Signatures;

with 'Exobrain::Agent::Run';

# ABSTRACT: Automatically respond to any 'ping' tag sent to us.
our $VERSION = '1.08'; # VERSION

method run() {
    $self->exobrain->watch_loop(
        class  => 'Measurement::Social',
        filter => sub { $_->to_me and grep { /^ping$/ } @{ $_->tags } },
        then   => sub { $_->respond("Ack (via exobrain)"); },
    );
}

1;

__END__

=pod

=head1 NAME

Exobrain::Agent::Action::Ping - Automatically respond to any 'ping' tag sent to us.

=head1 VERSION

version 1.08

=head1 AUTHOR

Paul Fenwick <pjf@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Paul Fenwick.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
