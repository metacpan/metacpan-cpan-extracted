package Hopkins::Worker::Native;

use strict;

=head1 NAME

Hopkins::Worker::Native - perl worker

=head1 DESCRIPTION

Hopkins::Worker::Native represents the special case of a
worker that will be executing a perl task.  it wraps the
execution in order to return results to hopkins.  it also
does pre-execution cleansing of the log4perl environment.

=cut

use base 'Class::Accessor::Fast';

__PACKAGE__->mk_accessors(qw(work status filter));

=head1 METHODS

=over 4

=item new

=cut

sub new
{
	my $self = shift->SUPER::new(@_);

	# create a POE::Filter object; status information will
	# be reported back to the controlling worker object via
	# this filter.

	$self->filter(new POE::Filter::Reference 'YAML');
	$self->status({});

	return sub { $self->execute };
}

=item execute

=cut

sub execute
{
	my $self = shift;

	# begin processing

	eval { $self->_execute };

	if (my $err = $@) {
		Hopkins->log_worker_stderr($self->work->task->name, "execution failed: $err");
		$self->status->{error} = $err unless $self->status->{terminated};
	}

	$self->report;

	# POE::Wheel::Run doesn't execute DESTROY and END blocks
	# since it exits the child process by using POSIX::_exit
	# instead of exit().  this prevents log4perl appenders
	# such as Log::Dispatch::Email from flushing buffers.
	# although the task may not be using log4perl, there's
	# no harm in calling it explicitly.  it will probably
	# save the user some headache.

	Log::Log4perl::Logger::cleanup();
}

sub _execute
{
	my $self = shift;

	$SIG{TERM} = sub { $self->status->{terminated} = 1; die 'terminated' };

	my $class	= $self->work->task->class;
	my $file	= "$class.pm";

	$file =~ s{::}{/}g;

	# immediately undefine the log4perl config watcher.
	# the logic in Log::Log4perl->init_and_watch will
	# use the existing configuration if it is called at
	# a later time.  this will cause problems if any of
	# the perl workers use init_and_watch.
	#
	# this should probably be considered a bug.  it's
	# not init()ing and watching.  just more watching.

	$Log::Log4perl::Config::WATCHER = undef;

	# redirect STDOUT to STDERR so that we can use
	# the original STDOUT pipe to report status
	# information back to hopkins via YAML

	open STATUS, '>&STDOUT';
	open STDOUT, '>&STDERR';

	eval { require $file; $class->new({ options => $self->work->options })->run };

	my $err = $@;

	$SIG{TERM} = 'IGNORE';

	if ($err) {
		print STDERR $err;
		$self->status->{error} = $err unless $self->status->{terminated};
		Hopkins->log_worker_stderr($self->work->task->name, $err);
	}
}

sub report
{
	my $self = shift;

	# make sure to close the handle so that hopkins will
	# receive the information before the child exits.

	print STATUS $self->filter->put([ $self->status ])->[0];
	close STATUS;
}

=back

=head1 AUTHOR

Mike Eldridge <diz@cpan.org>

=head1 LICENSE

This program is free software; you may redistribute it
and/or modify it under the same terms as Perl itself.

=cut

1;
