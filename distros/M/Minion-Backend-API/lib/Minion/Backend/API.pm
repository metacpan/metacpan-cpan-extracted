package Minion::Backend::API;
use Mojo::Base 'Minion::Backend';
use Mojo::URL;
use Mojo::UserAgent;
use Carp 'croak';

our $VERSION = 1.00;

has 'ua';
has 'url';
has 'authentication';
has 'slow' => 0.5;
has '_url_authentication';

sub broadcast {
    my ($self, $command, $args, $ids) = (shift, shift, shift || [], shift || []);

    my $res = $self->ua->put(
        $self->_url . '/broadcast'
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
        $self->_url . '/dequeue'
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
        $self->_url . '/enqueue'
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
        $self->_url . '/fail-job'
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
        $self->_url . '/finish-job'
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

    my $res = $self->ua->get($self->_url . '/history');

    $self->_result($res);
}

sub list_jobs {
    my ($self, $offset, $limit, $options) = @_;

    my $res = $self->ua->get(
        $self->_url . '/list-jobs'
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
        $self->_url . '/list-locks'
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
        $self->_url . '/list-workers'
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
        $self->_url . '/lock'
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

    my $ua = Mojo::UserAgent->new;
    my $authentication;
    my $total = scalar(@args);

    if ($total > 1) {
        for (my $i = 1; $i < $total; $i++) {
            $authentication = $args[$i], next if $args[$i] =~ /^[^:]+:[^:]+$/;
            $ua             = $args[$i] if $args[$i]->isa('Mojo::UserAgent');
        }
    }

    my $url = $args[0];
    $url    =~ s/\/$//;

    return $self->SUPER::new(
        ua             => $ua,
        url            => $url,
        authentication => $authentication
    );
}

sub note {
    my ($self, $id, $merge) = @_;

    my $res = $self->ua->patch(
        $self->_url . '/note'
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
        $self->_url . '/receive'
        => json => {
            id => $id
        }
    );

    $self->_result($res);
}

sub register_worker {
    my ($self, $id, $options) = (shift, shift, shift || {});

    my $res = $self->ua->post(
        $self->_url . '/register-worker'
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
        $self->_url . '/remove-job'
        => json => {
            id => $id
        }
    );

    $self->_result($res);
}

sub repair {
    my $self = shift;

    my $res = $self->ua->post(
        $self->_url . '/repair'
    );

    $self->_result($res);
}

sub reset {
    my ($self, $options) = (shift, shift // {});

    my $res = $self->ua->post(
        $self->_url . '/reset'
        => json => {
            options => $options
        }
    );

    $self->_result($res);
}

sub retry_job {
    my ($self, $id, $retries, $options) = (shift, shift, shift, shift || {});

    my $res = $self->ua->put(
        $self->_url . '/retry-job'
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

    my $res = $self->ua->get($self->_url . '/stats');

    $self->_result($res);
}

sub unlock {
    my ($self, $name) = @_;

    my $res = $self->ua->delete(
        $self->_url . '/unlock'
        => json => {
            name => $name
        }
    );

    $self->_result($res);
}

sub unregister_worker {
    my ($self, $id) = @_;

    my $res = $self->ua->delete(
        $self->_url . '/unregister-worker'
        => json => {
            id => $id
        }
    );

    $self->_result($res);
}

sub _url {
    my $self = shift;

    return $self->url unless $self->authentication;

    # set userinfo if not setted
    unless ($self->_url_authentication->isa('Mojo::URL')) {
        my $url = Mojo::URL->new($self->url)->userinfo($self->authentication);
        $self->_url_authentication($url);
    }

    return $self->_url_authentication;
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

    # using authentication
    my $backend = Minion::Backend::API->new('https://my-api.com', 'user:pass');
    my $backend = Minion::Backend::API->new('https://my-api.com', 'user:pass', $ua);
    my $backend = Minion::Backend::API->new('https://my-api.com', $ua, 'user:pass');

=head1 DESCRIPTION

L<Minion::Backend::API> is a backend for L<Minion> based on L<Mojo::UserAgent>.
This module need be used together with the module L<Mojolicious::Plugin::Minion::API>,
access it to see manual.

=head1 ATTRIBUTES

L<Minion::Backend::API> inherits all attributes from L<Minion::Backend> and
implements the following new ones.

=head2 url

    my $url = $backend->url;
    $backend->url('https://my-api.com');

=head2 ua

    my $ua = $backend->ua;
    $backend->ua(Mojo::UserAgent->new);

=head2 authentication

    my $authentication = $backend->authentication;
    $backend->authentication('user:pass');

It makes basic authentication.

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
