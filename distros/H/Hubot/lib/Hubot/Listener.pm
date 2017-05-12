package Hubot::Listener;
$Hubot::Listener::VERSION = '0.2.8';
use Moose;
use namespace::autoclean;

use Hubot::Response;

has 'robot' => ( is => 'ro', isa => 'Hubot::Robot', );
has 'matcher' => (
    traits  => ['Code'],
    is      => 'rw',
    isa     => 'CodeRef',
    handles => { matching => 'execute', },
);
has 'callback' => (
    traits  => ['Code'],
    is      => 'rw',
    isa     => 'CodeRef',
    handles => { cb => 'execute', },
);

sub call {
    my ( $self, $message ) = @_;
    if ( my @match = $self->matching($message) ) {
        $self->cb(
            new Hubot::Response(
                robot   => $self->robot,
                message => $message,
                match   => \@match,
            )
        );

        return 1;
    }
    else {
        return 0;
    }
}

__PACKAGE__->meta->make_immutable;

1;

=pod

=encoding utf-8

=head1 NAME

Hubot::Listener

=head1 VERSION

version 0.2.8

=head1 SYNOPSIS

    Nope.

=head1 DESCRIPTION

base class of L<Hubot::TextListener>

try to match all registered regex then execute callback with matching result and input messages.

=head1 SEE ALSO

L<Hubot::TextListener>

=head1 AUTHOR

Hyungsuk Hong <hshong@perl.kr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Hyungsuk Hong.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
