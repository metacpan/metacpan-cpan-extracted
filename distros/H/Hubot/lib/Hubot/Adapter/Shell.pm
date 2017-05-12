package Hubot::Adapter::Shell;
$Hubot::Adapter::Shell::VERSION = '0.2.8';
use Moose;
use namespace::autoclean;

use Encode 'decode_utf8';

extends 'Hubot::Adapter';

use AnyEvent;

use Hubot::Message;

has 'robot' => ( is => 'ro', isa => 'Hubot::Robot', );

has '_prompt' => ( is => 'rw', isa => 'Str', writer => 'setPrompt', );

has 'cv' => ( is => 'ro', lazy_build => 1, );

sub _build_cv { AnyEvent->condvar }

sub close { shift->cv->send }

sub send {
    my ( $self, $user, @strings ) = @_;
    print "$_\n" for @strings;
}

sub reply {
    my ( $self, $user, @strings ) = @_;
    @strings = map { $user->{name} . ": $_" } @strings;
    $self->send( $user, @strings );
}

sub exist {
    my ( $self, $user, $nick ) = @_;
    return $self->userForName($nick);
}

sub run {
    my $self = shift;

    local $| = 1;
    binmode STDOUT, ':encoding(UTF-8)';

    $self->emit('connected');
    $self->setPrompt( $self->robot->name . "> " );
    print $self->_prompt;
    my $w;
    $w = AnyEvent->io(
        fh   => \*STDIN,
        poll => 'r',
        cb   => sub {
            local $| = 1;
            chomp( my $input = decode_utf8(<STDIN>) );
            if ( lc($input) eq 'exit' ) {
                $self->robot->shutdown;
                exit;
            }

            my $user
                = $self->userForId( 1, { name => 'Shell', room => 'Shell', } );

            $self->receive(
                new Hubot::TextMessage( { user => $user, text => $input, } ) );

            print $self->_prompt;
        }
    );

    $self->cv->recv;
    exit;
}

__PACKAGE__->meta->make_immutable;

1;

=pod

=encoding utf-8

=head1 NAME

Hubot::Adapter::Shell - Shell adapter for L<Hubot>

=head1 VERSION

version 0.2.8

=head1 SYNOPSIS

    $ hubot
    $ hubot -a shell    # same
    hubot> exit

=head1 DESCRIPTION

The shell adapter is an adapter that provides a simple REPL for interacting with a hubot locally. It is useful for testing scripts before deploying them.

=head1 SEE ALSO

L<https://github.com/github/hubot/wiki/Adapter:-Shell>

=head1 AUTHOR

Hyungsuk Hong <hshong@perl.kr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Hyungsuk Hong.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
