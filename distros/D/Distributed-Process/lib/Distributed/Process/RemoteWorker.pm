package Distributed::Process::RemoteWorker;

use strict;
use warnings;

=head1 NAME

Distributed::Process::RemoteWorker - a class to control from the server side a worker object running on the client side.

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use Distributed::Process;
import Distributed::Process;

use threads;
use Thread::Queue;
use IO::Select;
use Distributed::Process::Interface;
use Distributed::Process::BaseWorker;
our @ISA = qw/ Distributed::Process::BaseWorker Distributed::Process::Interface /;

sub new {

    my $class = shift;
    my $self = $class->SUPER::new(@_);

    $self->ignore_queue();
    $self;
}

sub out_handle {

    my $self = shift;
    $self->in_handle(@_);
}

=head2 Methods

=over 4

=cut

sub go_remote {

    my $self = shift;
    no strict 'refs';
    no warnings 'redefine';

    my $package = ref($self) || $self;
    *{$package . '::run'} = *run;
}

sub is_ready {

    my $self = shift;
    return defined($self->id());
}

sub get_id {

    my $self = shift;

    $self->id((split /\s+/, ($self->wait_for_pattern(qr|^/worker|))[-1])[-1]);
}

sub available_for_reading {

    my $self = shift;

    return 1 if $self->is_ignoring_queue();
    my $s = new IO::Select $self->in_handle();
    while ( 1 ) {
	return 1 if $s->can_read($self->timeout() || .1);
	return 0 if $self->in_queue()->pending();
    }
}

sub ignore_queue { shift->{_ignore_queue} = 1 }
sub heed_queue { shift->{_ignore_queue} = 0 }
sub is_ignoring_queue { shift->{_ignore_queue} }
sub is_heeding_queue { !(shift->{_ignore_queue}) }

sub run {

    my $self = shift;
    async {
	while ( 1 ) {
#	    my $msg = $self->in_queue()->dequeue();
#	    die "Unexpected order from master" unless $msg eq '/run';

#	    $self->send('/run');
	    while ( 1 ) {
		$self->heed_queue();
		my @res = $self->wait_for_pattern(qr{^/(?:run_method|synchro|run_done|delay)});
		if ( @res ) {
		    my ($command, @arg) = split /\s+/, $res[0];

		    for ( $command ) {
			$_ eq '/run_method' and do {
			    my $method = shift @arg;
			    my @r = $self->$method(@arg);
			    $self->send('/begin_method_result', @r, 'ok');
			    last;
			};
			$_ eq '/synchro' || $_ eq '/delay' and do {
			    $self->out_queue()->enqueue($res[0]);
			    $self->in_queue()->dequeue();
			    $self->send($res[0]);
			    last;
			};
			$_ eq '/run_done' and do {
			    $self->out_queue()->enqueue('/run_done');
			    1 until $self->in_queue()->pending();
			    last;
			};
		    }
		}
		else {
		    my $cmd = $self->in_queue()->dequeue();
		    $cmd eq '/run' and $self->send('/run');
		    $cmd eq '/reset' and $self->send('/reset');
		    $cmd eq '/quit' and $self->send('/quit'), return;
		}
	    }
	}
    }->detach();
}

sub result {

    my $self = shift;

    $self->send('/get_results');
    $self->ignore_queue();
    $self->wait_for_pattern(qr{^/begin_result});
    my @result = $self->wait_for_pattern(qr/^ok$/);
    pop @result;
    return @result;
}

=back

=head2 Attributes

The following list describes the attributes of this class. They must only be
accessed through their accessors.  When called with an argument, the accessor
methods set their attribute's value to that argument and return its former
value. When called without arguments, they return the current value.

=over 4

=item B<master>

=item B<in_queue>

=item B<out_queue>

=item B<timeout>

=cut

foreach my $method ( qw/ master in_queue out_queue timeout / ) {

    no strict 'refs';
    *$method = sub {
	my $self = shift;
	my $old = $self->{"_$method"};
	$self->{"_$method"} = $_[0] if @_;
	return $old;
    };
}

=back

=head1 SEE ALSO

L<Distributed::Process::LocalWorker>, L<Distributed::Process::RemoteWorker>,
L<Distributed::Process::Master>

=head1 AUTHOR

Cédric Bouvier, C<< <cbouvi@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-distributed-process@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically
be notified of progress on your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2005 Cédric Bouvier, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Distributed::Process::RemoteWorker
