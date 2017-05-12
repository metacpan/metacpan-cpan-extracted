#!/usr/bin/env perl
use strict;
use warnings;
use Mesos::Messages;
use Mesos::Scheduler;
use Mesos::SchedulerDriver;
use Mojo::IOLoop;
use Mojolicious::Lite;

package MyScheduler {
    use List::MoreUtils qw(any);
    use UUID::Tiny ':std';
    use Moo;
    extends 'Mesos::Scheduler';

    has framework => (
        is      => 'ro',
        default => sub { "Mojo Framework - $$" },
    );

    has master => (
        is      => 'ro',
        default => 'localhost:5050',
    );

    has user => (
        is      => 'ro',
        default => sub { $ENV{USER} },
    );

    has driver => (
        is      => 'ro',
        lazy    => 1,
        builder => '_build_driver',
    );
    sub _build_driver {
        my ($self) = @_;
        return Mesos::SchedulerDriver->new(
            dispatcher => 'Mojo',
            framework  => {name => $self->framework, user => $self->user},
            master     => $self->master,
            scheduler  => $self,
        );
    }

    has callbacks => (
        is      => 'ro',
        default => sub { {} },
    );

    has queue => (
        is      => 'ro',
        default => sub { [] },
    );

    has tasks => (
        is      => 'ro',
        default => sub { {} },
    );

    sub matchOffer {
        my ($self, $task, $offers) = @_;
        my %required = map {$_->{name} => $_->{scalar}{value}} @{$task->{resources}};

        for my $offer (@$offers) {
            my %available = map {$_->{name} => $_} @{$offer->{resources}};
            # check if the offer has the required resources
            next if any {
                my $name     = $_;
                my $resource = $available{$name};
                $resource->{scalar}{value} < $required{$name};
            } keys %required;

            # claim resources from the offer
            for my $name (keys %required) {
                my $resource = $available{$name};
                $resource->{scalar}{value} -= $required{$name};
            }

            # assign slave id to task
            $task->{slave_id} = $offer->{slave_id};
            return $offer->{id}{value};
        }
        return undef;
    }

    sub queueTask {
        my ($self, $cmd, $end, %resources) = @_;

        %resources = (mem => 128, cpus => 0.1, disk => 256, %resources);
        my @mesos_resources = map {
            my $type = $_;
            Mesos::Resource->new({
                name   => $type,
                type   => Mesos::Value::Type::SCALAR,
                scalar => {value => $resources{$type}},
            });
        } sort keys %resources;

        my $task = Mesos::TaskInfo->new({
            command   => {value => $cmd},
            name      => $cmd,
            resources => \@mesos_resources,
            task_id   => {value => create_uuid_as_string(UUID_RANDOM)},
        });
        $self->callbacks->{$task->{task_id}{value}} = $end;
        push @{$self->queue}, $task;

        my $driver = $self->driver;
        $driver->reviveOffers();

        return $end;
    }

    sub resourceOffers {
        my ($self, $driver, $offers) = @_;

        my (@requeueing, %launching);
        for my $task (@{$self->queue}) {
            my $offer_id = $self->matchOffer($task, $offers);
            if (not(defined $offer_id)) {
                # requeue tasks that couldn't be scheduled
                push @requeueing, $task;
                next;
            }

            $self->tasks->{$task->{task_id}{value}} = $task;
            push @{$launching{$offer_id}||=[]}, $task;
        }
        @{$self->queue} = @requeueing;

        # decline unused offers
        for my $offer_id (map {$_->{id}{value}} @$offers) {
            next if exists $launching{$offer_id};
            $driver->declineOffer({value => $offer_id});
        }

        for my $offer_id (keys %launching) {
            my $tasks = $launching{$offer_id};
            $driver->launchTasks([{value => $offer_id}], $tasks);
        }

    }

    sub statusUpdate {
        my ($self, $driver, $status) = @_;
        my $task_id = $status->{task_id}{value};

        my $done = any {$status->{state} == $_}
            Mesos::TaskState::TASK_ERROR,
            Mesos::TaskState::TASK_FAILED,
            Mesos::TaskState::TASK_FINISHED,
            Mesos::TaskState::TASK_KILLED,
            Mesos::TaskState::TASK_LOST;
        return unless $done;

        my $cb   = delete $self->callbacks->{$task_id};
        my $task = delete $self->tasks->{$task_id};
        $cb->($status, $task) if $cb;
    }

    sub BUILD {
        my ($self) = @_;
        $self->driver->start();
    }

    sub DEMOLISH {
        my ($self, $in_global_destruction) = @_;
        return if $in_global_destruction;

        $self->driver->stop();
    }
};

package Mojolicious::Plugin::Mesos {
    use Mojo::Base 'Mojolicious::Plugin';
    use Mojo::IOLoop;

    sub register {
        my ($self, $app, $conf) = @_;
        # use timer to run mesos code after forking
        Mojo::IOLoop->timer(0 => sub {
            my $scheduler = MyScheduler->new(%$conf);
            $app->helper(mesos => sub { $scheduler });
        });
    }
};

post '/run' => sub {
    my ($c) = @_;
    my $command   = $c->req->json('/command');
    my $resources = $c->req->json('/resources') || {};
    if (not $command) {
        $c->res->code(400);
        $c->finish;
        return;
    }

    $c->delay(
        sub {
            my ($delay) = @_;
            my $mesos = $c->mesos;
            $mesos->queueTask(
                $command,
                $delay->begin(0),
                %$resources,
            );
        },
        sub {
            my ($delay, $status, $task) = @_;
            $c->render(text => "$status->{message}\n");
        },
    );
};

plugin 'Mesos';
app->start;
