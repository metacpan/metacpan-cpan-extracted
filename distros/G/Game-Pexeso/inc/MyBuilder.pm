#!/usr/bin/perl

package inc::MyBuilder;


use strict;
use warnings;

use base 'Module::Build';
use File::Spec::Functions;


sub ACTION_install {
	my $self = shift;

	# Make sure that 'share/' has an installation path
	my $p = $self->{properties};
	if (! exists $p->{install_path}{share}) {
		my $script_dir = $self->install_destination('script');
		my @dirs = File::Spec->splitdir($script_dir);
		$dirs[-1] = 'share';
		$p->{install_path}{share} = File::Spec->catdir(@dirs);
	}

	# Proceed normally
	$self->SUPER::ACTION_install(@_);
}


sub ACTION_post_install {
	my $self = shift;
	print "Updating desktop database\n";
	system('update-desktop-database');
}


sub ACTION_build {
	my $self = shift;

	# Copy the files in share/
	foreach my $entry (@{ $self->rscan_dir('share') }) {

		# Skip hidden entries or folders
		next if $entry =~ m,(^|/)\., or -d $entry;

		$self->copy_if_modified(
			from => $entry,
			to   => catfile($self->blib, $entry) 
		);
	}

	# Proceed normally
	$self->SUPER::ACTION_build(@_);
}


# Return a true value
1;
