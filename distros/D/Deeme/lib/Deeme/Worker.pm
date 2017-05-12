package Deeme::Worker;
use Deeme::Obj "Deeme";
use constant DEBUG => $ENV{DEEME_DEBUG} || 0;

sub jobs {
    my $j;
    return ( $j = shift->backend->events_get(shift) ) ? scalar @$j : 0;
}

sub dequeue_event {
    my ( $self, $name ) = @_;
    if ( my $s = $self->backend->events_get($name) ) {
        warn
            "Worker -- dequeue $name in @{[blessed $self]} (@{[scalar @$s]})\n"
            if DEBUG;
        my @onces = $self->backend->events_onces($name);
        my $i     = 0;
        for my $cb (@$s) {
            ( $onces[$i] == 1 )
                ? ( splice( @onces, $i, 1 )
                    and $self->_unsubscribe_index( $name => $i ) )
                : $i++;
            push(
                @{ $self->{'queue'} },
                Deeme::Job->new(
                    deeme => $self,
                    cb    => $cb
                )
            );
        }
    }
    return @{ $self->{'queue'} };
}

sub dequeue {
    my ( $self, $name ) = @_;

    if ( my $s = $self->backend->events_get($name) ) {
        warn
            "Worker -- dequeue $name in @{[blessed $self]} safely (@{[scalar @$s]})\n"
            if DEBUG;
        my $cb = Deeme::Job->new(
            deeme => $self,
            cb    => @$s[0]
        );
        $self->_unsubscribe_index( $name, 0 );
        push( @{ $self->{'queue'} }, $cb );
    }
    return @{ $self->{'queue'} }[0];
}

sub process {
    my $self = shift;
    return @{ $self->{'queue'} } > 0
        ? @{ $self->{'queue'} }[0]->process(@_)
        : undef;
}

sub process_all {
    my $self = shift;
    my @args = @_;
    my @returns;
    while ( my $job = shift @{ $self->{'queue'} } ) {
        push( @returns, $job->process(@args) );
    }
    return @returns;
}

sub add { return shift->once(@_) }
1;
__END__

=encoding utf-8

=head1 NAME

Deeme::Worker - represent a Deeme worker that process jobs

=head1 SYNOPSIS

  package JobQueue;
  use Deeme::Obj 'Deeme::Worker';
  use Deeme::Backend::Mango;

  # app1.pl
  package main;
  # Subscribe to events in an application (thread, fork, whatever)
  my $worker_tiger = JobQueue->new(backend=> Deeme::Backend::Mango->new(...) ); #or you can just do Deeme->new
  $worker_tiger->add(roar => sub {
    my ($worker_tiger, $times) = @_;
    say 'RAWR!' for 1 .. $times;
  });

   ...

  #then, later in another application
  # app2.pl
  my $worker_tiger = JobQueue->new(backend=> Deeme::Backend::Mango->new(...));
  while(my $Job=$worker_tiger->dequeue("roar")){
    $Job->process(@args);
  }

  ...
  #or

  my $worker_tiger = JobQueue->new(backend=> Deeme::Backend::Mango->new(...));
  while($worker_tiger->dequeue("roar")){
    $worker_tiger->process(@args);
  }

  #or
  $worker_tiger->dequeue_events("roar");
  $worker_tiger->process_all(1);

=head1 DESCRIPTION

Deeme is a database-agnostic driven event emitter base-class.
Deeme::Worker allows you to use deem to act also like a jobqueue.

=head1 EVENTS

L<Deeme::Worker> inherits all events from L<Deeme>

=head1 METHODS

L<Deeme::Worker> inherits all methods from L<Deeme> and
implements the following new ones.

=head2 add

  $e = $e->add(test1=> sub {...});

Subscribe to L</"test1"> jobqueue.

=head2 jobs

  $n = $e->jobs('test1');

Returns the number of jobs in the queue

=head2 dequeue

  $Job = $e->dequeue('test1');

Dequeue a job from the L</"test1"> jobqueue, can be accessible also calling C<$e->process(@args)>, it has the same effect calling C<$job->process(@args)> after the dequeuing.

=head2 dequeue_event

  @Jobs = $e->dequeue_event('test1');

Dequeue all jobs from the L</"test1"> jobqueue;

=head2 process

  $return=$e->process('foo'); #if already dequeued
  $return=$Job->process('foo', 123);

Execute job with provided args.

=head2 process_all

  my @returns=$e->process_all('foo',1,2);

Process all dequeued jobs with provided args and return an array of return values(corrisponding to the jobs).

=head1 DEBUGGING

You can set the C<DEEME_DEBUG> environment variable to get some
advanced diagnostics information printed to C<STDERR>.

  DEEME_DEBUG=1

=head1 AUTHOR

mudler E<lt>mudler@dark-lab.netE<gt>

=head1 COPYRIGHT

Copyright 2014- mudler

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Deeme>, L<Deeme::Backend::Mango>, L<Deeme::Backend::Meerkat>,  L<Deeme::Backend::Memory>, L<Mojo::EventEmitter>, L<Mojolicious>

=cut
