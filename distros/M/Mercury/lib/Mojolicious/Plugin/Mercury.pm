package Mojolicious::Plugin::Mercury;
our $VERSION = '0.015';
# ABSTRACT: Plugin for Mojolicious to add Mercury functionality

#pod =head1 SYNOPSIS
#pod
#pod     # myapp.pl
#pod     use Mojolicious::Lite;
#pod     plugin 'Mercury';
#pod
#pod =head1 DESCRIPTION
#pod
#pod This plugin adds L<Mercury> to your L<Mojolicious> application, allowing you
#pod to build a websocket message broker customized to your needs.
#pod
#pod After adding the plugin, you can add basic messaging patterns by using the Mercury
#pod controllers, or you can mix and match your patterns using the Mercury::Pattern
#pod classes.
#pod
#pod Controllers handle establishing the websocket connections and giving
#pod them to the right Pattern object, and the Pattern object handles passing
#pod messages between the connected sockets. Controllers can create multiple
#pod instances of a single Pattern to isolate messages to a single topic.
#pod
#pod B<NOTE>: You should read L<the DESCRIPTION section of the main Mercury broker
#pod documentation|mercury/DESCRIPTION> before reading further.
#pod
#pod =head2 Controllers
#pod
#pod Controllers are L<Mojolicious::Controller> subclasses with route handlers
#pod to establish websocket connections and add them to a Pattern. The built-in
#pod Controllers each handle one pattern, but you can add one socket to multiple
#pod Patterns to customize your message passing.
#pod
#pod B<NOTE>: Since Mercury does not yet have a way for brokers to share messages,
#pod you must run Mercury as a single process. You cannot run Mercury under
#pod L<Hypnotoad> like other Mojolicious applications, nor C<prefork> or other
#pod multi-processing schemes. See L<https://github.com/preaction/Mercury/issues/35>
#pod to track the clustering feature.
#pod
#pod The built-in controllers are:
#pod
#pod =over
#pod
#pod =item L<Mercury::Controller::PubSub>
#pod
#pod Establish a L<PubE<sol>Sub pattern|Mercury::Pattern::PubSub> on a topic.
#pod Pub/Sub allows publishers to publish messages that will be received by
#pod all subscribers, useful for event notifications.
#pod
#pod =item L<Mercury::Controller::PubSub::Cascade>
#pod
#pod Establish a L<PubE<sol>Sub pattern|Mercury::Pattern::PubSub> on a topic in
#pod a heirarchy, with subscribers to parent topics receiving messages sent
#pod to child topics. More efficient when dealing with large numbers of
#pod topics.
#pod
#pod =item L<Mercury::Controller::PushPull>
#pod
#pod Establish a L<PushE<sol>Pull pattern|Mercury::Pattern::PushPull> on a topic.
#pod Push/Pull allows publishers to publish messages that will be received by
#pod one and only one subscriber in a round-robin fashion, useful for job
#pod workers
#pod
#pod =item L<Mercury::Controller::Bus>
#pod
#pod Establish a L<message bus pattern|Mercury::Pattern::Bus> on a topic.
#pod The message bus shares all messages sent by connected clients with all
#pod other clients, useful for chat and games, and sharing state changes
#pod between peers.
#pod
#pod =back
#pod
#pod =head2 Patterns
#pod
#pod The Pattern objects handle transmission of messages on a single topic.
#pod Pattern objects take in L<Mojo::Transaction::WebSocket> objects (gotten
#pod by the controller using C<< $c->tx >> inside a C<websocket> route).
#pod
#pod The built-in patterns are:
#pod
#pod =over
#pod
#pod =item L<Mercury::Pattern::PubSub>
#pod
#pod A pub/sub pattern has each message sent by a publisher delivered to all
#pod connected subscribers. This pattern is useful for event notifications.
#pod
#pod =item L<Mercury::Pattern::PushPull>
#pod
#pod A push/pull pattern has each message sent by a pusher delivered to one
#pod and only one puller. This pattern is useful for job workers.
#pod
#pod =item L<Mercury::Pattern::Bus>
#pod
#pod A bus pattern has each message sent by a client received by all other
#pod connected clients. This pattern is useful for chat, and is similar to
#pod combining the publish and subscribe sides of PubSub into a single
#pod connection.
#pod
#pod =back
#pod
#pod =head1 SEE ALSO
#pod
#pod =over
#pod
#pod =item L<Mercury>
#pod
#pod =item L<Mojolicious::Plugins>
#pod
#pod =back
#pod
#pod =cut

use Mojo::Base 'Mojolicious::Plugin';

#=attr _patterns
#
# A repository for pattern objects to share between controller
# instances.
#
#=cut

has _patterns => sub { {} };

#pod =method pattern
#pod
#pod     my $pattern = $c->mercury->pattern( PushPull => $topic );
#pod     $c->mercury->pattern( PushPull => $topic => $pattern );
#pod
#pod Accessor for the pattern repository. Pattern objects track a single topic
#pod and are registered by a namespace (likely the pattern type).
#pod
#pod =cut

sub pattern {
    my ( $self, $namespace, $topic, $pattern ) = @_;
    if ( $pattern ) {
        $self->_patterns->{ $namespace }{ $topic } = $pattern;
        return;
    }
    return $self->_patterns->{ $namespace }{ $topic };
}

#pod =method register
#pod
#pod Register the plugin with the Mojolicious app. Called automatically by Mojolicious
#pod when you use C<< $app->plugin( 'Mercury' ) >>.
#pod
#pod =cut

sub register {
    my ( $self, $app, $conf ) = @_;
    $app->helper( 'mercury.pattern' => sub { shift; $self->pattern( @_ ) } );
    push @{$app->routes->namespaces}, 'Mercury::Controller';
}

1;

__END__

=pod

=head1 NAME

Mojolicious::Plugin::Mercury - Plugin for Mojolicious to add Mercury functionality

=head1 VERSION

version 0.015

=head1 SYNOPSIS

    # myapp.pl
    use Mojolicious::Lite;
    plugin 'Mercury';

=head1 DESCRIPTION

This plugin adds L<Mercury> to your L<Mojolicious> application, allowing you
to build a websocket message broker customized to your needs.

After adding the plugin, you can add basic messaging patterns by using the Mercury
controllers, or you can mix and match your patterns using the Mercury::Pattern
classes.

Controllers handle establishing the websocket connections and giving
them to the right Pattern object, and the Pattern object handles passing
messages between the connected sockets. Controllers can create multiple
instances of a single Pattern to isolate messages to a single topic.

B<NOTE>: You should read L<the DESCRIPTION section of the main Mercury broker
documentation|mercury/DESCRIPTION> before reading further.

=head2 Controllers

Controllers are L<Mojolicious::Controller> subclasses with route handlers
to establish websocket connections and add them to a Pattern. The built-in
Controllers each handle one pattern, but you can add one socket to multiple
Patterns to customize your message passing.

B<NOTE>: Since Mercury does not yet have a way for brokers to share messages,
you must run Mercury as a single process. You cannot run Mercury under
L<Hypnotoad> like other Mojolicious applications, nor C<prefork> or other
multi-processing schemes. See L<https://github.com/preaction/Mercury/issues/35>
to track the clustering feature.

The built-in controllers are:

=over

=item L<Mercury::Controller::PubSub>

Establish a L<PubE<sol>Sub pattern|Mercury::Pattern::PubSub> on a topic.
Pub/Sub allows publishers to publish messages that will be received by
all subscribers, useful for event notifications.

=item L<Mercury::Controller::PubSub::Cascade>

Establish a L<PubE<sol>Sub pattern|Mercury::Pattern::PubSub> on a topic in
a heirarchy, with subscribers to parent topics receiving messages sent
to child topics. More efficient when dealing with large numbers of
topics.

=item L<Mercury::Controller::PushPull>

Establish a L<PushE<sol>Pull pattern|Mercury::Pattern::PushPull> on a topic.
Push/Pull allows publishers to publish messages that will be received by
one and only one subscriber in a round-robin fashion, useful for job
workers

=item L<Mercury::Controller::Bus>

Establish a L<message bus pattern|Mercury::Pattern::Bus> on a topic.
The message bus shares all messages sent by connected clients with all
other clients, useful for chat and games, and sharing state changes
between peers.

=back

=head2 Patterns

The Pattern objects handle transmission of messages on a single topic.
Pattern objects take in L<Mojo::Transaction::WebSocket> objects (gotten
by the controller using C<< $c->tx >> inside a C<websocket> route).

The built-in patterns are:

=over

=item L<Mercury::Pattern::PubSub>

A pub/sub pattern has each message sent by a publisher delivered to all
connected subscribers. This pattern is useful for event notifications.

=item L<Mercury::Pattern::PushPull>

A push/pull pattern has each message sent by a pusher delivered to one
and only one puller. This pattern is useful for job workers.

=item L<Mercury::Pattern::Bus>

A bus pattern has each message sent by a client received by all other
connected clients. This pattern is useful for chat, and is similar to
combining the publish and subscribe sides of PubSub into a single
connection.

=back

=head1 METHODS

=head2 pattern

    my $pattern = $c->mercury->pattern( PushPull => $topic );
    $c->mercury->pattern( PushPull => $topic => $pattern );

Accessor for the pattern repository. Pattern objects track a single topic
and are registered by a namespace (likely the pattern type).

=head2 register

Register the plugin with the Mojolicious app. Called automatically by Mojolicious
when you use C<< $app->plugin( 'Mercury' ) >>.

=head1 SEE ALSO

=over

=item L<Mercury>

=item L<Mojolicious::Plugins>

=back

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
