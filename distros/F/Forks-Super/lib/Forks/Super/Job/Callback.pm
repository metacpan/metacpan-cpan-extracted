#
# Forks::Super::Job::Callback - manage callback functions
#    that are called in the parent at certain points in the
#    lifecycle of a child process
# implements
#    fork { callback => \&sub }
#    fork { callback => { event => code , event => code , ... } }


package Forks::Super::Job::Callback;
use Forks::Super::Util qw(qualify_sub_name);
use Forks::Super::Debug qw(:all);
use Carp;
use Exporter;
use strict;
use warnings;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(run_callback);
our %EXPORT_TAGS = (all => \@EXPORT_OK);
our $VERSION = '0.95';
our $IN_CALLBACK;

sub run_callback {
    my ($job, $callback) = @_;
    my $key = "_callback_$callback";
    local $IN_CALLBACK = $callback;
    if (!defined $job->{$key}) {
	return;
    }
    if ($job->{debug}) {
	debug('run_callback: Job ',$job->{pid}," running $callback callback");
    }
    my $ref = ref $job->{$key};
    if ($ref ne 'CODE' && ref ne '') {
	carp "Forks::Super::Job::run_callback: invalid callback $callback. ",
	    "Got $ref, expected CODE or subroutine name\n";
	return;
    }

    $job->{"callback_time_$callback"} = Time::HiRes::time();
    $callback = delete $job->{$key};

    if (ref $callback eq 'HASH') {
	Carp::confess "bad callback: $callback ",
	    '(did you forget to specify "sub" { }?)';
    } else {
	no strict 'refs';
	$callback->($job, $job->{pid});
    }
    return;
}

sub _preconfig_callbacks {
    my $job = shift;

    if (defined $job->{suspend}) {
	$job->{suspend} = qualify_sub_name $job->{suspend};
    }
    if (defined($job->{callback}) && 
        (ref $job->{callback} eq '' || ref $job->{callback} eq 'CODE')) {
	$job->{callback} = { finish => $job->{callback} };
    }
    # on_start, on_queue, on_fail, on_finish, etc. are top-level synonyms for
    # callback { start => ..., queue => ..., fail => ..., finish => ... }
    foreach my $syn (qw(start queue fail finish reaped)) {
        if (defined $job->{"on_" . $syn}) {
            $job->{callback}{$syn} ||= delete $job->{"on_" . $syn};
        }
    }
    if (!defined $job->{callback}) {
	return;
    }
    if (defined $job->{callback}{finish} && $job->{daemon}) {
	carp 'Forks::Super::_preconfig_callbacks: ',
              "'finish' callback is not going to be called ",
              "with a daemon process";
    }
    foreach my $callback_type (qw(finish start queue fail)) {
	if (defined $job->{callback}{$callback_type}) {
	    $job->{'_callback_' . $callback_type} =
		qualify_sub_name($job->{callback}{$callback_type});
	    if ($job->{debug}) {
		debug("_preconfig_callbacks: ",
		      "registered callback type $callback_type");
	    }
	}
    }
    return;
}

sub Forks::Super::Job::_config_callback_child {
    my $job = shift;
    for my $callback (grep { /^callback/ || /^_callback/ } keys %$job) {
	# this looks odd, but it clears up a SIGSEGV that was happening here
	$job->{$callback} = '';
	delete $job->{$callback};
    }
    return;
}

1;
