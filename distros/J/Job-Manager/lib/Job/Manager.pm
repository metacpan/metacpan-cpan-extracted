package Job::Manager;
{
  $Job::Manager::VERSION = '0.16';
}
BEGIN {
  $Job::Manager::AUTHORITY = 'cpan:TEX';
}
# ABSTRACT: a parallel job execution manager

use 5.010_000;
use mro 'c3';
use feature ':5.10';

use Moose;
use namespace::autoclean;

# use IO::Handle;
# use autodie;
# use MooseX::Params::Validate;

use Sys::ForkQueue;

has 'concurrency' => (
    'is'       => 'rw',
    'isa'      => 'Int',
    'required' => 1,
);

has 'jobs' => (
    'is'      => 'ro',
    'isa'     => 'ArrayRef[Job::Manager::Job]',
    'default' => sub { [] },
);

with qw(Log::Tree::RequiredLogger);

sub add {
    my $self = shift;
    my $job  = shift;

    if ( $job && ref($job) && $job->isa('Job::Manager::Job') ) {
        push( @{ $self->jobs() }, $job );
        return 1;
    }
    else {
        $self->logger()->log( message => 'Job is not a subtype of Job::Manager::Job but ' . ref($job) . '. Can not add it.', level => 'warning', );
        return;
    }
}

sub add_batch {
    my ( $self, @jobs ) = @_;

    my $i = 0;
    foreach my $job (@jobs) {
        $self->add($job) and $i++;
    }
    return $i;
}

# run a single job
sub _exec {
    my $self = shift;
    my $num  = shift;

    return unless defined($num);

    $self->logger()->log( message => 'Running Job #' . $num, level => 'debug', );

    if ( $self->jobs() && $self->jobs()->[$num] ) {
        $self->logger()->log( message => 'Running Job #' . $num, level => 'debug', );

        # detach any ressources this job may have shared w/ the parent
        # this are e.g. filehandles, dbhandles or logfiles
        $self->jobs()->[$num]->forked();
        return $self->jobs()->[$num]->run();
    }
    else {
        $self->logger()->log( message => 'Job #' . $num . ' not found.', level => 'warning', );
        return;
    }
}

sub run {
    my $self = shift;

    # each job needs a unique name, just use montonous increasing numbers
    my $i    = 0;
    my @jobs = map { $i++ } @{ $self->jobs() };
    my $FQ   = Sys::ForkQueue::->new(
        {
            'jobs'            => \@jobs,
            'code'            => sub { $self->_exec(@_); },
            'logger'          => $self->logger(),
            'concurrency'     => $self->concurrency(),
            'redirect_output' => 0,
        },
    );
    return $FQ->run();
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Job::Manager - a parallel job execution manager

=head1 SYNOPSIS

    use Job::Manager;
    use Job::Manager::Job;

    my $Mgm = Job::Manager::->new({
	'logger' => $logger,
	'concurrency' => '4',
    });
    foreach my $i ( 1 .. 60 ) {
	my $Job = Job::Manager::Job::->new({
	    'logger' => $logger,
	});
	$Mgm->add($Job);
    }
    $Mgm->run();

=head1 METHODS

=head2 add

Add a single job to the queue.

=head2 add_batch

Add a list of jobs to the queue.

=head2 run

Process the whole job queue.

=head1 NAME

Job::Manager - Parallel job execution manager.

=head1 AUTHOR

Dominik Schulz <dominik.schulz@gauner.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
