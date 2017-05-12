package Makerelease::Step::Include;

use strict;
use Makerelease::Step;
use Makerelease::Step::Section;
use XML::Simple;

our $VERSION = '0.1';

# includes are really just a special type of Section
our @ISA=qw(Makerelease::Step::Section);

# sub-includes don't skip on the dry-runs...  only executing steps do.
sub possibly_skip_dryrun {
    my ($self, $step, $parentstep, $counter) = @_;
    return 0;
}

sub load_em_up {
    my ($self, $step, $parentstep, $counter) = @_;
    return if ($step->{'__loaded'});
    $step->{'__loaded'} = 1;
    $step->{'file'} = $step->{'file'}[0] if (ref($step->{'file'}) eq 'ARRAY');
    my $substeps = XMLin($step->{'file'}, @main::XMLinopts);
    $step->{'steps'} = $substeps->{'steps'};
}

sub test {
    my ($self, $step, $parentstep, $counter) = @_;

    $step->{'file'} = $step->{'file'}[0] if (ref($step->{'file'}) eq 'ARRAY');

    if (!exists($step->{'file'})) {
	print "Step $parentstep$counter is missing the file clause\n";
	return 1;
    }

    if (! -f $step->{'file'}) {
	print "Step $parentstep$counter: couldn't find the \"$step->{'file'}\" file\n";
	return 1;
    }

    print "loading: $step->{'file'}\n";
    load_em_up(@_);
    Makerelease::Step::Section::test(@_);
}

sub step {
    my ($self, $step, $parentstep, $counter) = @_;
    load_em_up(@_);
    return Makerelease::Step::Section::step(@_);
}

sub print_toc_header {
    my ($self, $step, $parentstep, $counter) = @_;
    load_em_up(@_);
    return Makerelease::Step::Section::print_toc_header(@_);
}


1;

