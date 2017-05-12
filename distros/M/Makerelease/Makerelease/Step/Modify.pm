package Makerelease::Step::Modify;

use strict;
use Makerelease::Step;
use IO::File;

our $VERSION = '0.1';

our @ISA=qw(Makerelease::Step);

sub get_files {
    my ($self, $modify) = @_;

    my @files;

    my $files = $modify->{'files'};

    # XXX: fix this...  should be more accepting
    if (ref($files) eq 'ARRAY') {
	$files = $files->[0];
    }
    if (ref($files) eq 'HASH') {
	foreach my $fileref (@{$self->ensure_array($files->{'file'})}) {
	    push @files, glob($self->expand_parameters($fileref));
	}
    } else {
	foreach my $fileref ($self->expand_parameters($modify->{'files'})) {
	    push @files, glob($fileref);
	}
    }

    return \@files;
}

sub test {
    my ($self, $step, $parentstep, $counter) = @_;
    return 1 if ($self->require_piece($step, $parentstep, $counter,
				      'modifications', 'modify'));
    my $result = 0;
    for (my $i = 0; $i <= $#{$step->{'modifications'}[0]{'modify'}}; $i++) {
	$result = 
	  $self->WARN($step, "modification #$i contains no find clause")
	    if (!exists($step->{'modifications'}[0]{'modify'}[$i]{'find'}) ||
		$step->{'modifications'}[0]{'modify'}[$i]{'find'} eq '');
	$result = 
	  $self->WARN($step, "modification #$i contains no replace clause")
	    if (!exists($step->{'modifications'}[0]{'modify'}[$i]{'replace'}) ||
		$step->{'modifications'}[0]{'modify'}[$i]{'replace'} eq '');
	$result = 1
	  if ($self->require_piece($step->{'modifications'}[0]{'modify'}[$i],
				   $parentstep, $counter, 'files', 'file'));
    }
}

sub step {
    my ($self, $step, $parentstep, $counter) = @_;

    foreach my $modify (@{$step->{'modifications'}[0]{'modify'}}) {
	my $files = $self->get_files($modify);
	my $findregex = $self->expand_parameters($modify->{'find'});
	my $replaceregex = $self->expand_parameters($modify->{'replace'});

	my $asub = eval "sub { s/$findregex/$replaceregex/; }";

	foreach my $file (@$files) {

	    $self->output("modifying $file");

	    my $in = new IO::File();
	    my $out = new IO::File();
	    $in->open("<$file") || die "ack: couldn't open $file";
	    $out->open(">$file.mrnew") || die "ack: couldn't open $file.mrnew";

	    while (<$in>) {
		$asub->();
		print $out $_;
	    }

	    $in->close();
	    $out->close();
			
	    rename("$file","$file.bak");
	    rename("$file.mrnew","$file");
	}
    }
}

sub document_step {
    my ($self, $step, $parentstep, $counter) = @_;

    foreach my $modify (@{$step->{'modifications'}[0]{'modify'}}) {
	my $findregex = $self->expand_parameters($modify->{'find'});
	my $replaceregex = $self->expand_parameters($modify->{'replace'});
	$self->output("Modifying files:");
	$self->output("  replacing: '$findregex' with: '$replaceregex'\n");
	$self->output("  files:  glob=" .
		      $self->expand_parameters($modify->{'files'}));
	my $files = $self->get_files($modify);
	foreach my $file (@$files) {
	    $self->output("    " . $file);
	}
	$self->output("");
    }
}

1;

