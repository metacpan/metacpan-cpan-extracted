package Makerelease::Step::Prompt;

use strict;
use Makerelease::Step;
use IO::File;

our $VERSION = '0.1';

our @ISA=qw(Makerelease::Step);

# the only time we allow things to be skipped are with -n
sub possibly_skip {

    my $self = shift;

    my ($step, $parentstep, $counter) = @_;

    # handle -n
    return 1 if ($self->possibly_skip_dryrun(@_));

    return 0;
}

sub test {
    my ($self, $step, $parentstep, $counter) = @_;
    my $ret = 0;
    $ret = 1 if ($self->require_attribute($step, $parentstep, $counter,
					  'parameter'));
    return $ret;
}

sub step {
    my ($self, $step, $parentstep, $counter) = @_;

    my $done = 0;
    my $answer;

    # default to anything specified previously (or via command line)
    my $default;

    $default = $self->{'parameters'}{$step->{'parameter'}}
      if (exists($self->{'parameters'}{$step->{'parameter'}}));

    # allow a default on the param token
    $default = $step->{'default'}
      if (exists($step->{'default'}) && !defined($default));


    # set up the prompt
    my $prompt = $step->{'prompt'};

    # modify the prompt if there was a default
    $prompt = "$prompt [$default]" if ($default);


    # ask the question till the answer is valid
    while (!$done) {
	$done = 1;

	$answer = $self->getinput($prompt);

	$answer = $default if ($answer eq '');

	if ($step->{'values'} && $answer !~ $step->{'values'}) {
	    $self->output("Illegal value; must match: $step->{'values'}");
	    $done = 0;
	}
    }
    $self->{'parameters'}{$step->{'parameter'}} = $answer;
}

sub document_step {
    my ($self, $step, $parentstep, $counter) = @_;

    $self->output("Decide on a value for parameter '$step->{parameter}'");
    $self->output("  parameter: $step->{parameter}");
    $self->output("  prompt:    $step->{prompt}");
    $self->output("  legal:     $step->{values}") if ($self->{'values'});
}

1;

