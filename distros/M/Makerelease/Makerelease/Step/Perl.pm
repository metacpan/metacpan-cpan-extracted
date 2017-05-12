package Makerelease::Step::Perl;

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
    return $self->expand_parameters($command);
}

sub test {
    my ($self, $step, $parentstep, $counter) = @_;
    return 1 if ($self->require_piece($step, $parentstep, $counter,
				      'perl', 'code'));
    return 0;
}

sub step {
    my ($self, $step, $parentstep, $counter) = @_;

    foreach my $code (@{$step->{'perl'}[0]{'code'}}) {
	my $status = 1;

	# run it till we get a succeesful result or they bail on us
		
	while ($status ne '0') {

	    $self->output("evaluating specified perl code");
	    $status = eval $code;
	    if ($@) {
		print STDERR "error evaluating code in Step $parentstep$counter: $@\n";
	    }

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
	    $self->output("\n");
	}
    }
}

sub document_step {
    my ($self, $step, $parentstep, $counter) = @_;

    $self->output("Internal perl code will be executed");
}

1;

