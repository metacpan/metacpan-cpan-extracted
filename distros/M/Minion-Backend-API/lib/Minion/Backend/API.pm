package Minion::Backend::API;
use Mojo::Base 'Minion::Backend';
use Mojo::UserAgent;
use Carp 'croak';

our $VERSION = 0.06;

has 'ua';
has 'url';
has 'slow' => 0.5;

sub broadcast {
    my ($self, $command, $args, $ids) = (shift, shift, shift || [], shift || []);

    my $res = $self->ua->put(
        $self->url . '/broadcast'
        => json => {
            command => $command,
            args    => $args,
            ids     => $ids
        }
    );

    $self->_result($res);
}

sub dequeue {
    my ($self, $id, $wait, $options) = @_;

    # slows down
    select(undef, undef, undef, $self->slow);

    my $res = $self->ua->post(
        $self->url . '/dequeue'
        => json => {
            id      => $id,
            wait    => $wait,
            options => $options,
            tasks   => [keys %{$self->minion->tasks}]
        }
    );

    $self->_result($res);
}

sub enqueue {
    my ($self, $task, $args, $options) = (shift, shift, shift || [], shift || {});

    my $res = $self->ua->post(
        $self->url . '/enqueue'
        => json => {
            task    => $task,
            args    => $args,
            options => $options
        }
    );

    $self->_result($res);
}

sub fail_job {
    my ($self, $id, $retries, $result) = @_;

    my $res = $self->ua->patch(
        $self->url . '/fail-job'
        => json => {
            id      => $id,
            retries => $retries,
            result  => $result
        }
    );

    $self->_result($res);
}

sub finish_job {
    my ($self, $id, $retries, $result) = @_;

    my $res = $self->ua->patch(
        $self->url . '/finish-job'
        => json => {
            id      => $id,
            retries => $retries,
            result  => $result
        }
    );

    $self->_result($res);
}

sub history {
    my $self = shift;

    my $res = $self->ua->get($self->url . '/history');

    $self->_result($res);
}

sub list_jobs {
    my ($self, $offset, $limit, $options) = @_;

    my $res = $self->ua->get(
        $self->url . '/list-jobs'
        => json => {
            offset  => $offset,
            limit   => $limit,
            options => $options
        }
    );

    $self->_result($res);
}

sub list_locks {
    my ($self, $offset, $limit, $options) = @_;

    my $res = $self->ua->get(
        $self->url . '/list-locks'
        => json => {
            offset  => $offset,
            limit   => $limit,
            options => $options
        }
    );

    $self->_result($res);
}

sub list_workers {
    my ($self, $offset, $limit, $options) = @_;

    my $res = $self->ua->get(
        $self->url . '/list-workers'
        => json => {
            offset  => $offset,
            limit   => $limit,
            options => $options
        }
    );

    $self->_result($res);
}

sub lock {
    my ($self, $name, $duration, $options) = (shift, shift, shift, shift // {});

    my $res = $self->ua->get(
        $self->url . '/lock'
        => json => {
            name     => $name,
            duration => $duration,
            options  => $options
        }
    );

    $self->_result($res);
}

sub new {
    my ($self, @args) = @_;

    my $ua = $args[1] && $args[1]->isa('Mojo::UserAgent')
           ? $args[1]
           : Mojo::UserAgent->new;

    my $url = $args[0];
    $url    =~ s/\/$//;

    return $self->SUPER::new(ua => $ua, url => $url);
}

sub note {
    my ($self, $id, $merge) = @_;

    my $res = $self->ua->patch(
        $self->url . '/note'
        => json => {
            id    => $id,
            merge => $merge
        }
    );

    $self->_result($res);
}

sub receive {
    my ($self, $id) = @_;

    my $res = $self->ua->patch(
        $self->url . '/receive'
        => json => {
            id => $id
        }
    );

    $self->_result($res);
}

sub register_worker {
    my ($self, $id, $options) = (shift, shift, shift || {});

    my $res = $self->ua->post(
        $self->url . '/register-worker'
        => json => {
            id      => $id,
            options => $options
        }
    );

    $self->_result($res);
}

sub remove_job {
    my ($self, $id) = @_;

    my $res = $self->ua->delete(
        $self->url . '/remove-job'
        => json => {
            id => $id
        }
    );

    $self->_result($res);
}

sub repair {
    my $self = shift;

    my $res = $self->ua->post(
        $self->url . '/repair'
    );

    $self->_result($res);
}

sub reset {
    my ($self, $options) = (shift, shift // {});

    my $res = $self->ua->post(
        $self->url . '/reset'
        => json => {
            options => $options
        }
    );

    $self->_result($res);
}

sub retry_job {
    my ($self, $id, $retries, $options) = (shift, shift, shift, shift || {});

    my $res = $self->ua->put(
        $self->url . '/retry-job'
        => json => {
            id      => $id,
            retries => $retries,
            options => $options
        }
    );

    $self->_result($res);
}

sub stats {
    my $self = shift;

    my $res = $self->ua->get($self->url . '/stats');

    $self->_result($res);
}

sub unlock {
    my ($self, $name) = @_;

    my $res = $self->ua->delete(
        $self->url . '/unlock'
        => json => {
            name => $name
        }
    );

    $self->_result($res);
}

sub unregister_worker {
    my ($self, $id) = @_;

    my $res = $self->ua->delete(
        $self->url . '/unregister-worker'
        => json => {
            id => $id
        }
    );

    $self->_result($res);
}

sub _result {
    my ($self, $res) = @_;

    my $result = $res->result;

    if ($result->is_success) {
        my $data = $result->json;

        return $data->{result} || undef if $data->{success};
    }

    croak $result->message if $result->is_error;

    return;
}

1;

=encoding utf8

=head1 NAME

Minion::Backend::API - API Rest backend

=head1 SYNOPSIS

    # simple
    use Minion::Backend::API;

    my $backend = Minion::Backend::API->new('https://my-api.com');

    # using with your own Mojo::UserAgent
    use Mojo::UserAgent;
    use Minion::Backend::API;

    my $ua = Mojo::UserAgent->new;
    my $backend = Minion::Backend::API->new('https://my-api.com', $ua);

=head1 DESCRIPTION

L<Minion::Backend::API> is a backend for L<Minion> based on L<Mojo::UserAgent>.
This module need be used together with the module L<Mojolicious::Plugin::Minion::API>,
access it to see manual.

=head1 ATTRIBUTES

L<Minion::Backend::API> inherits all attributes from L<Minion::Backend> and
implements the following new ones.

=head2 url

  my $url  = $backend->url;
  $backend = $backend->url('https://my-api.com');

=head2 ua

  my $ua   = $backend->ua;
  $backend = $backend->ua(Mojo::UserAgent->new);

=head2 slow

  $backend->slow(0.2);

Slows down each request of dequeue. Default is 0.5 (half a second).

=head1 SEE MORE OPTIONS

L<Minion::Backend::Pg>

=head1 SEE ALSO

L<Mojolicious::Plugin::Minion::API>, L<Mojo::UserAgent>, L<Minion>, L<Mojolicious::Guides>, L<https://mojolicious.org>.

=head1 AUTHOR

Lucas Tiago de Moraes C<lucastiagodemoraes@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Lucas Tiago de Moraes.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut
