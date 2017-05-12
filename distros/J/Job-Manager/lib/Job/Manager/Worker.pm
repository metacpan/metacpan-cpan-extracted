package Job::Manager::Worker;
{
  $Job::Manager::Worker::VERSION = '0.16';
}
BEGIN {
  $Job::Manager::Worker::AUTHORITY = 'cpan:TEX';
}
# ABSTRACT: baseclass for any Worker managed by Job::Manager

use 5.010_000;
use mro 'c3';
use feature ':5.10';

use Moose;
use namespace::autoclean;

# use IO::Handle;
# use autodie;
# use MooseX::Params::Validate;

use Sys::Run;

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

has 'sys' => (
    'is'      => 'rw',
    'isa'     => 'Sys::Run',
    'lazy'    => 1,
    'builder' => '_init_sys',
);

has '_ppid' => (
    'is'      => 'ro',
    'isa'     => 'Int',
    'lazy'    => 1,
    'builder' => '_init_ppid',
);

sub _init_ppid {
    return getppid();
}

sub BUILD {
    my $self = shift;

    # IMPORTANT: initialize our ppid!
    $self->_ppid();

    return 1;
}

sub _init_sys {
    my $self = shift;

    my $Sys = Sys::Run::->new( { 'logger' => $self->logger(), } );

    return $Sys;
}

sub _parent_alive {
    if(-e '/proc/'.$_[0]->_ppid()) {
        return 1;
    }

    return;
}

sub run {
    my $self = shift;

    if ( ref($self) eq 'Job::Manager::Worker' ) {
        die('Abstract base class. Go, get your own derviate class!');
    }
    else {
        return;
    }
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Job::Manager::Worker - baseclass for any Worker managed by Job::Manager

=head1 SYNOPSIS

Invoked by Job::Manager::Job.

=head1 METHODS

=head2 run

Invoked when the Job::Manager decides to run this Job.

=head2 BUILD

This method initialized our ppid.

=head1 NAME

Job::Manager::Worker - An abstract worker class.

=head1 AUTHOR

Dominik Schulz <dominik.schulz@gauner.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
