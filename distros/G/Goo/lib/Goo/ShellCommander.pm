#!/usr/bin/perl

package Goo::ShellCommander;

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2005
# All Rights Reserved
#
# Author: 		Nigel Hamilton
# Filename:		Goo::ShellCommander.pm
# Description: 	Run a command in the shell
#
# Date	 		Change
# ----------------------------------------------------------------------------
# 01/08/05		Factored out of ProgramEditor as part of the new Goo
#
##############################################################################

use Goo::Object;
use Goo::Prompter;

use base qw(Goo::Object);


###############################################################################
#
# run - keep adding a thing to the program
#
###############################################################################

sub run { 

	my ($this, $thing, $target) = @_; 
	
	my $command = Goo::Prompter::ask("Enter a shell command>"); 
	
	print `$command`; 

	Goo::Prompter::notify("Command complete. Press a key to continue.");
	
} 

1;


__END__

=head1 NAME

Goo::ShellCommander - Run a command in the shell

=head1 SYNOPSIS

use Goo::ShellCommander;

=head1 DESCRIPTION

=head1 METHODS

=over

=item run

keep adding a Thing to the program

=back

=head1 AUTHOR

Nigel Hamilton <nigel@trexy.com>

=head1 SEE ALSO
