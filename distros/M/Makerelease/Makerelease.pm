package Makerelease;

use strict;

our $VERSION = '0.1';

# conditionally use Text::Wrap
my $havewrap = eval { require Text::Wrap; };
if ($havewrap) {
    import Text::Wrap qw(wrap);
}


# note: this new clause is used by most sub-modules too, altering it
# will alter them.
sub new {
    my $type = shift;
    my ($class) = ref($type) || $type;
    my $self = {};
    %$self = @_;
    bless($self, $class);
    return $self;
}

# this loads the needed perl module (dynamically) for a given step
sub load_step {
    my ($self, $step) = @_;
    # make sure we can load it before bailing with -n
    my $steptype = $step->{'type'};
    my $steptypecap = $steptype;
    $steptypecap =~ s/^(.)/uc($1)/e;
    my $module = "Makerelease::Step::$steptypecap";
    my $haveit = eval "require $module";
    if (!$haveit) {
	print STDERR
	  "Could not load a module for release step type \"$steptype\";\n";
	print STDERR
	  "  Tried: $module\n";
	print STDERR
	  "  Error: $@\n";
	die;
    }

    # create a module instance
    my $stepmodule = eval "new $module";
    if (!$stepmodule) {
	print STDERR
	  "Can't create an instance of the \"step\" module\n";
	print STDERR
	  "  Tried: $module\n";
	print STDERR
	  "  Error: $@\n";
	die;
    }

    # auto-inherit some parameters
    $stepmodule->{'opts'} = $self->{'opts'};
    $stepmodule->{'parameters'} = $self->{'parameters'};
    $stepmodule->{'master'} = $self;

    return $stepmodule;
}

sub start_step {
    my ($self, $vernum, $vername) = @_;
    $self->output_raw("STEP: $vernum: $vername\n\n");
}

sub test_steps {
    my ($self, $relinfo, $parentstep) = @_;
    my $counter;
    my $result = 0;
    foreach my $step (@{$relinfo->{'steps'}[0]{'step'}}) {
	$counter++;
	my $stepmodule = $self->load_step($step);
	$result = 1 if ($stepmodule->test($step, "$parentstep$counter"));
    }
    return $result;
}

sub process_steps {
    my ($self, $relinfo, $parentstep) = @_;
    my $counter;
    foreach my $step (@{$relinfo->{'steps'}[0]{'step'}}) {
	$counter++;

	# print the step header
	$self->start_step("$parentstep$counter", $step->{'title'});

	my $stepmodule = $self->load_step($step);
	
	# print description of the step if it exists
	$stepmodule->print_description($step);

	next if ($stepmodule->possibly_skip($step, $parentstep, $counter));

	# XXX: skip up to step based on number here

	# XXX: skip up to step based on nmae here

	$self->DEBUG("processing step: $parentstep.$counter: type=$step->{'type'}\n");

	$stepmodule->step($step, $parentstep, $counter);
	$stepmodule->finish_step($step, $parentstep, $counter);
    }
}

sub print_toc {
    my ($self, $relinfo, $parentstep) = @_;
    my $counter;
    foreach my $step (@{$relinfo->{'steps'}[0]{'step'}}) {
	$counter++;

	my $stepmodule = $self->load_step($step);
	
	# print the step header
	$stepmodule->print_toc_header($step, $parentstep, $counter);
    }
}

sub print_toc_header {
    my ($self, $step, $parentstep, $counter) = @_;
    $self->output_raw(sprintf("%-15.15s %s\n",
			      "$parentstep$counter", $step->{title}));
}

sub getinput {
    my ($self, $prompt) = @_;
    $self->output_raw("$prompt ") if ($prompt);
    my $bogus = <STDIN>;
    chomp($bogus);
    return $bogus;
}

sub DEBUG {
    my ($self, @args) = @_;
    if ($self->{'opts'}{'v'}) {
	$self->output(@args);
    }
}

sub output {
    my $self = shift;
    my @text = @_;
    my @output;

    if ($havewrap) {
	foreach my $text (@text) {
	    foreach my $section (split(/\n\n/,$text)) {
		push @output, wrap("  ", "  ", $section);
	    }
	}
	print STDERR join("\n\n",@output),"\n\n";
    } else {
	print STDERR "  ",@_;
    }
}

sub output_raw {
    my $self = shift;
    print STDERR @_;
}

sub ensure_array {
    my ($self, $something) = @_;
    return $something if (ref($something) eq 'ARRAY');
    return [$something];
}

1;

=head1 NAME

Makerelease - A base perl module for Makerelease Plugins

=head1 SYNOPSIS



=head1 DESCRIPTION



=cut



