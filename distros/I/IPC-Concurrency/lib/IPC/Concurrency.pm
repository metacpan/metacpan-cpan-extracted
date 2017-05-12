package IPC::Concurrency;

use warnings;
use strict;

use Carp;
use IPC::ShareLite ':lock';

=head1 NAME

IPC::Concurrency - Concurrency guard for processes.

=head1 VERSION

Version 0.5

=cut

our $VERSION = '0.5';

=head1 SYNOPSIS

This module allows you to specify how many processes of given kind you want to run in parallel.

May be usefull when you want to prevent machine overload or provide exclusive access to some resource.

This is NOT a forker.

    use IPC::Concurrency;
    
    my $name = 'PROC';
    my $c = IPC::Concurrency->new($name);
    
    # your process will end if there are already 4 processes registered as 'PROC' running
    exit unless $c->get_slot(4);
    
    # otherwise it will run as usual
    do_some_tasks();

=head2 System requirements

Your system must support SysV IPC shared memory and semaphores as well as kill command.

If you pass the test suite for L<IPC::ShareLite> then you're ready to go :)

=head2 Containers

Containers are used to name and group processes (like 'PROC' in SYNOPSIS).
They are located in shared memory and are accessible by any user.

Containers must be named as exactly 4 characters from A-Z range (uppercase).

=head1 FAQ

B<Q:> Can i change $0 variable?

B<A:> Yes. You can change $0 variable during runtime if you want.
Finding amount of running processes of given kind is totally 'ps ux' independent.

--

B<Q:> Can i use the same $name for processes running on different users?

B<A:> Yes. For example you can restrict them to access some shared device one at a time.

Example:

    package Scanner::GUI;
    
    use IPC::Concurrency;
    
    my $c = IPC::Concurrency->new('SCNR');
    
    while (not $c->get_slot(1)) {
        print 'Scanner is busy', $/;
        sleep 4;
    }
    
    run_scanner_gui();

This code will wait till every other 'SCNR' processes are not active.
It's much more simple approach than grepping 'ps aux' table or creating lockfiles.

--

B<Q:> Can i register my process under many names?

B<A:> Yes. For example you may want to run no more that 4 parsers and no more than 32 processes on some machine.

Example:

    package Parser;
    
    use IPC::Concurrency;
    
    my $c1 = IPC::Concurrency->new('PARS');
    my $c2 = IPC::Concurrency->new('GLOB');
    
    exit unless $c1->get_slot(4) and $c2->get_slot(32);

--

B<Q:> What is the limit for number of containers?

B<A:> You can make as many containers as your system allows. You will get C<< Carp::confess('No space left on device') >> if you exceed available memory or semaphores.

--

B<Q:> What is the limit for number of processes registered in one container?

B<A:> You can request C<< $c2->get_slot(1024) >> max.

--

B<Q:> Can i use this module for limiting child processes?

B<A:> Yes. In the following example child process doesn't know
how many other child processes have been spawned. But it can use get_slot()
to prevent exceeding 10 live child processes.

Example:

    package Scraper;
    
    use IPC::Concurrency;
    
    my $c1 = IPC::Concurrency->new('SCRA');
    
    unless ( my $pid = fork() ) {
        exit unless $c1->get_slot(10);
    }


=head1 FUNCTIONS

=head2 new

    my $name = 'PROC';
    my $c = IPC::Concurrency->new($name);

Creates new object and allocates Shared Memory container under C<< $name >>.

L<Carp::confess> will be called on failure.

=cut

sub new {
    my ( $class, $name ) = @_;
    my $self = {};

    confess 'Name missing' unless defined $name;
    confess 'Name must be exactly 4 characters from A-Z range (uppercase)'
      unless $name =~ m/^[A-Z]{4}$/;

    $self->{'concurrency'} = IPC::ShareLite->new(
        '-key'     => $name,
        '-create'  => 'yes',
        '-destroy' => 'no'
    ) or confess $!;

    return bless $self, $class;
}

=head2 get_slot

    $count = 1;
    exit unless $c->get_slot($count);

Request slot. You will get it if there are no more than C<< $count - 1 >> processes registered under given C<< $name >>.

=cut

sub get_slot {
    my ( $self, $count ) = @_;

    confess 'Count missing' unless defined $count;
    confess 'Count should be positive integer' unless $count =~ m/^\d+$/;
    confess 'Count should be in 1..1024 range'
      unless $count >= 1
      and $count <= 1024;

    $self->{'concurrency'}->lock( LOCK_EX );

    my %pids = map { $_ => 1 } split /,/, $self->{'concurrency'}->fetch();

    for my $pid ( keys %pids ) {
        not kill 0, $pid and delete $pids{$pid};
    }

    $pids{$$}++ if int keys %pids < $count;

    $self->{'concurrency'}->store( join ',', keys %pids );
    $self->{'concurrency'}->unlock();

    return defined $pids{$$};
}

=head1 AUTHOR

Pawel (bbkr) Pabian, C<< <cpan at bbkr.org> >>

Private website: L<http://bbkr.org>

Company website: L<http://implix.com>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ipc-concurrency at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=IPC-Concurrency>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

B<PID rollover problem>

PIDs of processes are stored in containers.
Once get_slot() is called it checks how many processes are still active.
This is done by sending C<< kill 0, PID >> signals to all processes on ths list.
Not responding PIDS are cleared from container and slot is gained if number of PIDs left
is smaller than number of concurrent processes required.
That makes logic vulnerable to PIDs rollover.

=head1 TODO

Encrypt/validate container content.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc IPC::Concurrency


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=IPC-Concurrency>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/IPC-Concurrency>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/IPC-Concurrency>

=item * Search CPAN

L<http://search.cpan.org/dist/IPC-Concurrency>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008 Pawel bbkr Pabian, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1;    # End of IPC::Concurrency
