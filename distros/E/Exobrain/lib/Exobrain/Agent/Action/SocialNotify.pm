package Exobrain::Agent::Action::SocialNotify;
use Moose;
use Method::Signatures;

# ABSTRACT: Notify user of social events directed at them.
our $VERSION = '1.08'; # VERSION

with 'Exobrain::Agent::Run';

method run {
    $self->exobrain->watch_loop(
        class  => 'Measurement::Social',
        filter => sub { $_->to_me },
        then   => sub {
            $self->exobrain->notify( $_->summary )
        },
    );
}

1;

__END__

=pod

=head1 NAME

Exobrain::Agent::Action::SocialNotify - Notify user of social events directed at them.

=head1 VERSION

version 1.08

=head1 AUTHOR

Paul Fenwick <pjf@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Paul Fenwick.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
