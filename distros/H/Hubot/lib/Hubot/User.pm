package Hubot::User;
$Hubot::User::VERSION = '0.2.8';
use strict;
use warnings;

sub new {
    my ( $class, $ref ) = @_;
    $ref->{name} ||= $ref->{id};
    bless $ref, $class;
}

sub TO_JSON { return { %{ shift() } } }

1;

=pod

=encoding utf-8

=head1 NAME

Hubot::User - storage object for hubot users.

=head1 VERSION

version 0.2.8

=head1 SYNOPSIS

    my $user = Hubot::User->new(
        id   => '1234',
        name => 'aanoaa',
    );

    $user->{something} = 'awesome';    # if you using external storage for Hubot::Brain
                                       # this will stored.

=head1 DESCRIPTION

L<Hubot::User> is a storage object to chat rooms user's data.

L<Hubot::Robot> has L<Hubot::User> pool.

    $robot->userForId($id, $data); # make new user with $data if not found $id

L<Hubot::Script::redisBrain> save users data to C<hubot:storage>.
so L<Hubot::Robot> can reuse it.

    $ redis-cli
    redis 127.0.0.1:6379> get hubot:storage
    ...

=head1 SEE ALSO

L<Hubot::Script::redisBrain>

=head1 AUTHOR

Hyungsuk Hong <hshong@perl.kr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Hyungsuk Hong.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
