package Hubot::Adapter;
$Hubot::Adapter::VERSION = '0.2.8';
use Moose;
use namespace::autoclean;

extends 'Hubot::EventEmitter';

has 'robot' => ( is => 'ro', isa => 'Hubot::Robot' );

sub send    { }
sub whisper { }
sub reply   { }
sub run     { }
sub close   { }
sub exist   { }

sub receive              { shift->robot->receive(@_) }
sub users                { shift->robot->users }
sub userForId            { shift->robot->userForId(@_) }
sub userForName          { shift->robot->userForName(@_) }
sub usersForFuzzyRawName { shift->robot->usersForFuzzyRawName(@_) }
sub usersForFuzzyName    { shift->robot->usersForFuzzyName(@_) }
sub http                 { shift->robot->http(@_) }

__PACKAGE__->meta->make_immutable;

1;

=pod

=encoding utf-8

=head1 NAME

Hubot::Adapter - specific interface to a chat source for robots.

=head1 VERSION

version 0.2.8

=head1 SYNOPSIS

    use Hubot::Robot;
    my $robot = Hubot::Robot->new({
        adapter => 'Shell',
        name    => 'hubot'
    });

    $robot->adapter->on('connected', sub {
        ## do something
    });

    ## Hubot::Adapter::XXX
    ## `ADAPTER` must implements `run` method
    sub run {
        my $self = shift;
        ## do something
        $self->emit('connected');
    }

=head1 DESCRIPTION

Adapters are the interface to the service you want your hubot to run on.

=head1 AVAILABLE ADAPTERS

=head2 BUILT IN

=over

=item L<Shell|Hubot::Adapter::Shell>

=item L<IRC|Hubot::Adapter::Irc>

=item L<Campfire|Hubot::Adapter::Campfire>

=back

=head1 AUTHOR

Hyungsuk Hong <hshong@perl.kr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Hyungsuk Hong.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
