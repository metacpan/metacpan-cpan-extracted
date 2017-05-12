package IPC::PubSub;
$IPC::PubSub::VERSION = '0.29';

use 5.006;
use strict;
use warnings;
use IPC::PubSub::Cacheable;
use IPC::PubSub::Publisher;
use IPC::PubSub::Subscriber;
use base qw/Class::Accessor::Fast/;

__PACKAGE__->mk_accessors(qw/_cache/);

sub new {
    my $self = bless {}, shift;

    my $backend = shift || 'PlainHash';

    local $@;
    eval { require "IPC/PubSub/Cache/$backend.pm" }
        or die "Cannot load backend module: IPC::PubSub::Cache::$backend: $@";

    $self->_cache(IPC::PubSub::Cacheable->new($backend => \@_));
    return $self;
}

sub new_publisher {
    my $self = shift;
    IPC::PubSub::Publisher->new($self->_cache, @_ ? @_ : '');
}

sub new_subscriber {
    my $self = shift;
    IPC::PubSub::Subscriber->new($self->_cache, @_ ? @_ : '');
}

sub fetch      { ( +shift )->_cache->fetch(@_) }
sub store      { ( +shift )->_cache->store(@_) }
sub lock       { ( +shift )->_cache->lock(@_) }
sub unlock     { ( +shift )->_cache->unlock(@_) }
sub modify     { ( +shift )->_cache->modify(@_) }
sub disconnect { ( +shift )->_cache->disconnect }

1;

__END__

=head1 NAME

IPC::PubSub - Interprocess Publish/Subscribe channels

=head1 SYNOPSIS

    # A new message bus with the DBM::Deep backend
    # (Other possible backends include Memcached and PlainHash)
    my $bus = IPC::PubSub->new(DBM_Deep => '/tmp/pubsub.db');

    # A channel is any arbitrary string
    my $channel = '#perl6';

    # Register a new publisher (you can publish to multiple channels)
    my $pub = $bus->new_publisher("#perl6", "#moose");

    # Publish a message (may be a complex object) to those channels
    $pub->msg("This is a message");

    # Register a new subscriber (you can subscribe to multiple channels)
    my $sub = $bus->new_subscriber("#moose");

    # Publish an object to channels
    $pub->msg("This is another message");

    # Set all subsequent messages from this publisher to expire in 30 seconds
    $pub->expiry(30);
    $pub->msg("This message will go away in 30 seconds");

    # Simple get: Returns the messages sent since the previous get,
    # but only for the first channel.
    my @msgs = $sub->get;

    # Simple get, with an explicit channel key (must be among the ones
    # it initially subscribed to)
    my @moose_msgs = $sub->get("#moose");

    # Complex get: Returns a hash reference from channels to array
    # references of [timestamp, message].
    my $hash_ref = $sub->get_all;

    # Changing the list of channels we subscribe to
    $sub->subscribe('some-other-channel');
    $sub->unsubscribe('some-other-channel');

    # Changing the list of channels we publish to
    $pub->publish('some-other-channel');
    $pub->unpublish('some-other-channel');

    # Listing and checking if we are in a channel
    my @sub_channels = $sub->channels;
    my @pub_channels = $pub->channels;
    print "Sub is in #moose" if $sub->channels->{'#moose'};
    print "Pub is in #moose" if $pub->channels->{'#moose'};

    # Raw cache manipulation APIs (not advised; use ->modify instead)
    $bus->lock('channel');
    $bus->unlock('channel');
    my @timed_msgs = $bus->fetch('key1', 'key2', 'key3');
    $bus->store('key', 'value', time, 30);

    # Atomic updating of cache content; $_ is stored back on the
    # end of the callback.
    my $rv = $bus->modify('key' => sub { delete $_->{foo} });

    # Shorthand for $bus->modify('key' => sub { $_ = 'val' });
    $bus->modify('key' => 'val');

    # Shorthand for $bus->modify('key' => sub { $_ });
    $bus->modify('key');

    # Disconnect the backend connection explicitly
    $bus->disconnect;

=head1 DESCRIPTION

This module provides a simple API for publishing messages to I<channels>
and for subscribing to them.

When a I<message> is published on a channel, all subscribers currently in
that channel will get it on their next C<get> or C<get_all> call.

Currently, it offers four backends: C<DBM_Deep> for on-disk storage,
C<Memcached> for possibly multi-host storage, C<Jifty::DBI> for
database-backed storage, and C<PlainHash> for single-process storage.

Please see the tests in F<t/> for this distribution, as well as L</SYNOPSIS>
above, for some usage examples; detailed documentation is not yet available.

=head1 SEE ALSO

L<IPC::DirQueue>, where the subscribers divide the published messages among
themselves, so different subscribers never see the same message.

=head1 AUTHORS

Audrey Tang E<lt>cpan@audreyt.orgE<gt>

=head1 COPYRIGHT

Copyright 2006, 2007 by Audrey Tang E<lt>cpan@audreyt.orgE<gt>.

This software is released under the MIT license cited below.

=head2 The "MIT" License

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.

=cut
