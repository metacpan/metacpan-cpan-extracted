package Job::Manager::Job;
{
  $Job::Manager::Job::VERSION = '0.16';
}
BEGIN {
  $Job::Manager::Job::AUTHORITY = 'cpan:TEX';
}
# ABSTRACT: baseclass for any Job manaed by Job::Manager

use 5.010_000;
use mro 'c3';
use feature ':5.10';

use Moose;
use namespace::autoclean;

# use IO::Handle;
# use autodie;
# use MooseX::Params::Validate;

has 'config' => (
    'is'       => 'ro',
    'isa'      => 'Config::Yak',
    'required' => 0,
);

has 'logger' => (
    'is'       => 'rw',
    'isa'      => 'Log::Tree',
    'required' => 1,
);

has 'worker' => (
    'is'      => 'rw',
    'isa'     => 'Job::Manager::Worker',
    'lazy'    => 1,
    'builder' => '_init_worker',
);

sub forked {
    my $self = shift;

    $self->logger()->forked();

    return 1;
}

sub _startup {
    my $self = shift;

    # Nothing to do
    return 1;
}

sub run {
    my $self = shift;

    $self->_startup();

    return $self->worker()->run();
}

sub _init_worker {
    die('Abstract base class. Go, get your own derviate class!');
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

=pod

=encoding utf-8

=head1 NAME

Job::Manager::Job - baseclass for any Job manaed by Job::Manager

=head1 DESCRIPTION

This class implements an abstract Job that can be fed to Job::Manager::JobQueue.

=head1 METHODS

=head2 run

This sub is called when this Job begins execution.

=head2 _init_worker

Subclasses need to override this sub. It should return a subclass of Job::Manager::Worker.

=head2 forked

Invoked just before run but after the fork().

=head1 NAME

Job::Manager::Job - Abstract Job class

=head1 AUTHOR

Dominik Schulz <dominik.schulz@gauner.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__


1; # End of Job::Manager::Job
