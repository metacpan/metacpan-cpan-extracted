package HPCD::uni::Run;

### INCLUDES ######################################################################################

# safe Perl
use warnings;
use strict;
use Carp;

use Moose;

sub _register_status {
}

sub _collect_job_stats {
}

with 'HPCI::Run' => { theDriver => 'HPCD::uni' };

has 'stats_keys' => (
	is => 'ro',
	isa => 'ArrayRef[Str]',
	init_arg => undef,
	default  => sub { [ ] },
);

sub _get_submit_command {
	my $self         = shift;

	my $stage        = $self->stage;
	my $shell_script = $stage->script_file;
	my $output_file  = $self->_stdout;
	my $error_file   = $self->_stderr;

	return "exec $shell_script >$output_file 2>$error_file",
	    $stage->_get_submit_timeouts;
};

1;
