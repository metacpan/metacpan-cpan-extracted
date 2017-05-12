package IM::Engine::Plugin::State;
use 5.008001;
use Moose;
use MooseX::ABC;
extends 'IM::Engine::Plugin';
with 'IM::Engine::ExtendsObject::User';

our $VERSION = '0.01';

requires (
    'get_user_state',
    'set_user_state',
    'clear_user_state',
    'has_user_state',
);

sub constructor_arguments {
    my $self = shift;

    return (_state_plugin => $self);
}

sub traits {
    return (
        '+IM::Engine::Plugin::State::Trait::User::WithState',
    );
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__

=head1 NAME

IM::Engine::Plugin::State - Keep track of some state for each user

=head1 SYNOPSIS

    IM::Engine->new(
        interface => {
            ...
            incoming_callback => sub {
                my $incoming = shift;
                my $user     = $incoming->sender;

                my $last_time = $user->get_state('last_time');
                my $now = time;
                $user->set_state(last_time => $now);

                if ($last_time) {
                    return $incoming->reply("You last IMed me " . ($now - $last_time) . "s ago.");
                }
                else {
                    return $incoming->reply("Hi, IM me again!");
                }
            },
        },
        plugins => ['State::InMemory'],
    )->run;

=head1 DESCRIPTION

This module lets you store some state for each user. Right now the only backend
is L<IM::Engine::Plugin::State::InMemory> which seriously limits usability. But
more will come. I just want something with a useful API that I can continue to build up.

=head1 AUTHOR

Shawn M Moore, C<sartak@gmail.com>

=head1 SEE ALSO

=over 4

=item L<IM::Engine>

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2009 Shawn M Moore.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

