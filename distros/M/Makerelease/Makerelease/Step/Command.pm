package Makerelease::Step::Command;

use strict;
use Makerelease::Step;

our $VERSION = '0.1';

our @ISA=qw(Makerelease::Step);

sub get_command_string {
    my ($self, $commandstart) = @_;

    my $command;

    if (ref($commandstart) eq 'HASH') {
	$command = $commandstart->{'content'};
    } else {
	$command = $commandstart;
    }
    $command =~ s/^\s*//;
    $command =~ s/\s*$//;
    return $self->expand_parameters($command);
}

sub test {
    my ($self, $step, $parentstep, $counter) = @_;
    return 1 if ($self->require_piece($step, $parentstep, $counter,
				      'commands', 'command'));
    return 0;
}

sub step {
    my ($self, $step, $parentstep, $counter) = @_;

    foreach my $command (@{$step->{'commands'}[0]{'command'}}) {
	my $status = 1;

	# run it till we get a succeesful result or they bail on us
		
	while ($status ne '0') {

	    my $ignoreerror = 0;
	    $ignoreerror = 1
	      if (ref($command) eq 'HASH' && $command->{'ignoreerror'});

	    my $cmdstr = $self->get_command_string($command);

	    $self->output("running '$cmdstr'");
	    system("$cmdstr");
	    $status = $?;
	    $status = 0 if ($ignoreerror);

	    if ($status ne 0 ) {
		# command failed, prompt for what to do?
		my $dowhat = '';

		while ($dowhat eq '') {
		    $dowhat =
		      $self->getinput("failed: status=$? what now (c,r,q)?");
			
		    # if answered:
		    #   c => continue
		    #   q => quit
		    if ($dowhat eq 'c') {
			$status = 0;
		    } elsif ($dowhat eq 'q') {
			$self->output("Quitting at step '$parentstep$counter' as requested");
			exit 1;
		    } elsif ($dowhat eq 'r') {
			$self->output("-- re-running ----------");
		    } else {
			$self->output("unknown response: $dowhat");
			$dowhat = '';
		    }
		}
	    }
	    $self->output("");
	}
    }
}

sub document_step {
    my ($self, $step, $parentstep, $counter) = @_;

    $self->output("Commands to execute:");
    foreach my $command (@{$step->{'commands'}[0]{'command'}}) {
	$self->output("  " . $self->get_command_string($command));
    }
}

1;

