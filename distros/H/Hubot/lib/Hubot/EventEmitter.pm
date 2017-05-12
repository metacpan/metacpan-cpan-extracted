package Hubot::EventEmitter;
$Hubot::EventEmitter::VERSION = '0.2.8';
use Moose;
use namespace::autoclean;

has 'events' => ( is => 'rw', isa => 'HashRef', default => sub { {} }, );

sub emit {
    my ( $self, $name ) = ( shift, shift );
    if ( my $s = $self->events->{$name} ) {
        for my $cb (@$s) { $self->$cb(@_) }
    }
    return $self;
}

sub on {
    my ( $self, $name, $cb ) = @_;
    push @{ $self->{events}{$name} ||= [] }, $cb;
    return $cb;
}

__PACKAGE__->meta->make_immutable;

1;

=pod

=encoding utf-8

=head1 NAME

Hubot::EventEmitter

=head1 VERSION

version 0.2.8

=head1 SYNOPSIS

    package Foo;
    use Moose;
    extends 'Hubot::EventEmitter';

    package main;
    my $foo = Foo->new;
    $foo->on(
        'event1',
        sub {
            my ($e, @args) = @_;    # $e is event emitter. ignore.
            print "@args\n";    # 1 2 3 4
        }
    );

    $foo->emit('event1', 1, 2, 3, 4);

=head1 DESCRIPTION

subscribe event via C<on> then execute callback via C<emit>.

=head1 METHODS

=head2 on

args - C<event-name>, C<callback>

=head2 emit

args - C<event-name>, C<@arg-pass-to-callback>

=head1 AUTHOR

Hyungsuk Hong <hshong@perl.kr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Hyungsuk Hong.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
