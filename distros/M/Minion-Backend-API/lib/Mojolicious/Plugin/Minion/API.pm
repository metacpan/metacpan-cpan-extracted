package Mojolicious::Plugin::Minion::API;
use Mojo::Base 'Mojolicious::Plugin';

use Carp 'croak';

our $VERSION = 0.05;

sub register {
    my ($self, $app, $config) = @_;

    # minion required
    $config->{minion} ||= eval { $app->minion } || croak 'A minion instance is required';

    # set helper minion, if not defined
    $app->helper('minion' => sub {
        return $config->{minion};
    }) unless $app->can('minion');

    # set helper backend
    $app->helper('backend' => sub {
        return $config->{minion}->backend;
    });

    # save tasks
    $app->hook(before_routes => sub {
         my $c = shift;

         if ($c->req->json && $c->req->json->{tasks}) {
            $config->{minion}->tasks->{$_} = 1 for @{$c->req->json->{tasks}};
         }
    });

    # enable all origin
    $app->hook(before_render => sub {
        my $c = shift;

        $c->res->headers->header('Access-Control-Allow-Origin' => '*') if $c->req->method ne 'OPTIONS';
    });

    # global
    $app->routes->options('/:all' => [all => qr/.+/] => sub {
        my $c = shift;

        # headers
        $c->res->headers->header('Access-Control-Allow-Origin' => '*');
        $c->res->headers->header('Access-Control-Allow-Credentials' => 'true');
        $c->res->headers->header('Access-Control-Allow-Methods' => 'OPTIONS, GET, POST, DELETE, PUT, PATCH');
        $c->res->headers->header('Access-Control-Allow-Headers' => 'Content-Type, Authorization');

        # return status 200 to options
        $c->respond_to(any => {data => '', status => 200});
    });

    # router api
    my $api = $app->routes->under($config->{pattern} ? $config->{pattern} : '/');

    # broadcast
    $api->put('/broadcast' => sub {
        my $c = shift;

        my $command = $c->req->json->{command};
        my $args    = $c->req->json->{args};
        my $ids     = $c->req->json->{ids};

        &_render($c, $app->backend->broadcast($command, $args, $ids));
    });

    # dequeue
    $api->post('/dequeue' => sub {
        my $c = shift;

        my $id      = $c->req->json->{id};
        my $wait    = $c->req->json->{wait};
        my $options = $c->req->json->{options};

        &_render($c, $app->backend->dequeue($id, $wait, $options));
    });

    # enqueue
    $api->post('/enqueue' => sub {
        my $c = shift;

        my $task    = $c->req->json->{task};
        my $args    = $c->req->json->{args};
        my $options = $c->req->json->{options};

        &_render($c, $app->backend->enqueue($task, $args, $options));
    });

    # fail_job
    $api->patch('/fail-job' => sub {
        my $c = shift;

        my $id      = $c->req->json->{id};
        my $retries = $c->req->json->{retries};
        my $result  = $c->req->json->{result};

        &_render($c, $app->backend->fail_job($id, $retries, $result));
    });

    # finish_job
    $api->patch('/finish-job' => sub {
        my $c = shift;

        my $id      = $c->req->json->{id};
        my $retries = $c->req->json->{retries};
        my $result  = $c->req->json->{result};

        &_render($c, $app->backend->finish_job($id, $retries, $result));
    });

    # history
    $api->get('/history' => sub {
        my $c = shift;

        &_render($c, $app->backend->history);
    });

    # list_jobs
    $api->get('/list-jobs' => sub {
        my $c = shift;

        my $offset  = $c->req->json->{offset};
        my $limit   = $c->req->json->{limit};
        my $options = $c->req->json->{options};

        &_render($c, $app->backend->list_jobs($offset, $limit, $options));
    });

    # list_locks
    $api->get('/list-locks' => sub {
        my $c = shift;

        my $offset  = $c->req->json->{offset};
        my $limit   = $c->req->json->{limit};
        my $options = $c->req->json->{options};

        &_render($c, $app->backend->list_locks($offset, $limit, $options));
    });

    # list_workers
    $api->get('/list-workers' => sub {
        my $c = shift;

        my $offset  = $c->req->json->{offset};
        my $limit   = $c->req->json->{limit};
        my $options = $c->req->json->{options};

        &_render($c, $app->backend->list_workers($offset, $limit, $options));
    });

    # lock
    $api->get('/lock' => sub {
        my $c = shift;

        my $name     = $c->req->json->{name};
        my $duration = $c->req->json->{duration};
        my $options  = $c->req->json->{options};

        &_render($c, $app->backend->lock($name, $duration, $options));
    });

    # note
    $api->patch('/note' => sub {
        my $c = shift;

        my $id    = $c->req->json->{id};
        my $merge = $c->req->json->{merge};

        &_render($c, $app->backend->note($id, $merge));
    });

    # receive
    $api->patch('/receive' => sub {
        my $c = shift;

        my $id = $c->req->json->{id};

        &_render($c, $app->backend->receive($id));
    });

    # register_worker
    $api->post('/register-worker' => sub {
        my $c = shift;

        my $id      = $c->req->json->{id};
        my $options = $c->req->json->{options};

        &_render($c, $app->backend->register_worker($id, $options));
    });

    # remove_job
    $api->delete('/remove-job' => sub {
        my $c = shift;

        my $id = $c->req->json->{id};

        &_render($c, $app->backend->remove_job($id));
    });

    # repair
    $api->post('/repair' => sub {
        my $c = shift;

        &_render($c, $app->backend->repair);
    });

    # reset
    $api->post('/reset' => sub {
        my $c = shift;

        my $options = $c->req->json->{options};

        &_render($c, $app->backend->reset($options));
    });

    # retry_job
    $api->put('/retry-job' => sub {
        my $c = shift;

        my $id      = $c->req->json->{id};
        my $retries = $c->req->json->{retries};
        my $options = $c->req->json->{options};

        &_render($c, $app->backend->retry_job($id, $retries, $options));
    });

    # stats
    $api->get('/stats' => sub {
        my $c = shift;

        &_render($c, $app->backend->stats);
    });

    # unlock
    $api->delete('/unlock' => sub {
        my $c = shift;

        my $name = $c->req->json->{name};

        &_render($c, $app->backend->unlock($name));
    });

    # unregister_worker
    $api->delete('/unregister-worker' => sub {
        my $c = shift;

        my $id = $c->req->json->{id};

        &_render($c, $app->backend->unregister_worker($id));
    });
}

sub _render {
    my ($c, $result) = @_;

    $c->render(
        json => {
            success => 1,
            result => $result || ''
        }
    );
}

1;

=encoding utf8

=head1 NAME

Mojolicious::Plugin::Minion::API - Plugin to receive requests from Minion::Backend::API

=head1 SYNOPSIS

    use Mojolicious::Lite;
    use Minion;

    plugin 'Minion::API' => {
        minion => Minion->new(Pg => 'postgresql://postgres@/test')
    };

    app->start;

=head1 DESCRIPTION

L<Mojolicious::Plugin::Minion::API> is a plugin L<Mojolicious>.
This module provides an API to receive request from L<Minion::Backend::API>

=head1 OPTIONS

L<Mojolicious::Plugin::Minion::API> supports the following options.

=head2 minion

    # Mojolicious::Lite
    plugin 'Minion' => {
        mysql => 'mysql://user@127.0.0.1/minion_jobs'
    };

    plugin 'Minion::API' => {
        minion => app->minion
    };

L<Minion> object to handle backend, this option is mandatory.

=head2 pattern

    # Mojolicious::Lite
    plugin 'Minion::API' => {
        pattern => '/minion-api' # https://my-api.com/minion-api
    };

This option is to set pattern in url, see more L<Mojolicious::Routes::Route#under>

=head1 SEE ALSO

L<Minion::Backend::API>, L<Minion>, L<Mojolicious::Guides>, L<https://mojolicious.org>.

=head1 AUTHOR

Lucas Tiago de Moraes C<lucastiagodemoraes@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Lucas Tiago de Moraes.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut
