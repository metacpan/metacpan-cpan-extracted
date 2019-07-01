package Job::Async::Client::Redis;

use strict;
use warnings;

use mro;

use parent qw(Job::Async::Client);

our $VERSION = '0.003'; # VERSION

=head1 NAME

Job::Async::Client::Redis - L<Net::Async::Redis> client implementation for L<Job::Async::Client>

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

no indirect;

use Syntax::Keyword::Try;
use JSON::MaybeUTF8 qw(:v1);
use Ryu::Async;
use Job::Async::Utils;
use Net::Async::Redis 1.003;

use Log::Any qw($log);

# Our client has a single Redis connection, a UUID to
# represent the client, and expects to see job announcements
# on the pubsub channel client::$client_id. For each
# announcement, the payload represents the job ID, and we get
# the actual details from the job hash.

sub _add_to_loop {
    my ($self) = @_;
    $self->add_child(
        $self->{client} = Net::Async::Redis->new(
            uri => $self->uri,
        )
    );
    $self->add_child(
        $self->{subscriber} = Net::Async::Redis->new(
            uri => $self->uri,
        )
    );
    $self->add_child(
        $self->{submitter} = Net::Async::Redis->new(
            uri => $self->uri,
        )
    );
    $self->add_child(
        $self->{ryu} = Ryu::Async->new
    );
}

=head2 client

=cut

sub client { shift->{client} }

=head2 subscriber

=cut

sub subscriber { shift->{subscriber} }

=head2 submitter

=cut

sub submitter { shift->{submitter} }

sub ryu { shift->{ryu} }

sub prefix { shift->{prefix} //= 'jobs' }

sub prefixed_queue {
    my ($self, $q) = @_;
    return $q unless length(my $prefix = $self->prefix);
    return join '::', $self->prefix, $q;
}
sub queue { shift->{queue} //= 'pending' }

=head2 start

=cut

sub start {
    my ($self) = @_;
    local $log->{context}{client_id} = $self->id;
    try {
        $log->tracef("Client awaiting Redis connections via %s", '' . $self->uri);
        return Future->wait_all(
            $self->client->connect,
            $self->submitter->connect,
            $self->subscriber->connect
        )->then(sub {
            local $log->{context}{client_id} = $self->id;
            $log->tracef("Subscribing to notifications");
            return $self->subscriber
                ->subscribe('client::' . $self->id)
                ->on_done(
                    $self->curry::weak::on_subscribed
                );
        })
    } catch {
        $log->errorf('Failed on connection setup - %s', $@);
        die $@;
    }
}

=head2 on_subscribed

=cut

sub on_subscribed {
    my ($self, $sub) = @_;
    local $log->{context}{client_id} = $self->id;
    # Every time someone tells us they finished a job, we pull back the details
    # and check the results
    $sub->events
        ->map('payload')
        ->each(sub {
            my ($id) = @_;
            local @{$log->{context}}{qw(client_id job_id)} = ($self->id, $id);
            $log->tracef("Received job notification");
            my $job = $self->pending_job($id);
            my $client = $self->client;
            ($job ? $client->hmget('job::' . $id, 'result')->then(sub {
                    local @{$log->{context}}{qw(client_id job_id)} = ($self->id, $id);
                    my ($result) = @{$_[0]};
                    my $type = substr $result, 0, 1, '';
                    $result = decode_json_utf8($result) if $type eq 'J';
                    $log->tracef('Job result %s', $result);
                    $job->done($result);
            }) : Future->done)->then(sub {
                local @{$log->{context}}{qw(client_id job_id)} = ($self->id, $id);
                $log->tracef('Removing job data');
                $client->del('job::' . $id);
            })->on_fail(sub {
                local @{$log->{context}}{qw(client_id job_id)} = ($self->id, $id);
                $log
            })->retain;
        });

    $log->tracef("Redis connections established, starting client operations");
}

sub submit {
    my $self = shift;
    my $job = (@_ == 1)
        ? shift
        : do {
            Job::Async::Job->new(
                future => $self->loop->new_future,
                id => Job::Async::Utils::uuid(),
                data => { @_ },
            );
        };
    $self->{pending_job}{$job->id} = $job;
    my $code = sub {
        my $tx = shift;
        my $id = $job->id // die 'no job ID?';
        return Future->needs_all(
            $tx->hmset(
                'job::' . $id,
                _reply_to => $self->id,
                %{ $job->flattened_data }
            ),
            $tx->lpush($self->prefixed_queue($self->queue), $id)
                ->on_done(sub {
                    my ($count) = @_;
                    local @{$log->{context}}{qw(client_id job_id)} = ($self->id, $id);
                    $log->tracef('Job count for [%s] now %d', $self->queue, $count);
                    $self->queue_length
                        ->emit($count);
                })
        );
    };
    return (
        $self->use_multi
        ? $self->submitter->multi($code)
        : $code->($self->submitter)
    )->then(sub { $job->future })
     ->retain
}

sub queue_length {
    my ($self) = @_;
    $self->{queue_length} ||= $self->ryu->source(
        label => 'Currently pending events for ' . $self->queue
    );
}

sub use_multi { shift->{use_multi} }

sub pending_job {
    my ($self, $id) = @_;
    die 'no ID' unless defined $id;
    return delete $self->{pending_job}{$id}
}

sub configure {
    my ($self, %args) = @_;
    for (qw(queue uri use_multi prefix)) {
        $self->{$_} = delete $args{$_} if exists $args{$_};
    }
    $self->next::method(%args)
}

sub uri { shift->{uri} }

1;

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2016-2017. Licensed under the same terms as Perl itself.

