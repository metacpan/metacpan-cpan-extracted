#!/usr/bin/perl
# -*- Mode: cperl; mode: folding; -*-

package Goo::Thing::pl::ScriptMaker;

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2003
# All Rights Reserved
#
# Author: 		Nigel Hamilton
# Filename:		ScriptMaker.pm
# Description:  Command line utility for making scripts faster
#
# Date	 		Change
# -----------------------------------------------------------------------------
# 14/8/2003		Version 1
# 02/2/2005		Updated to use the Prompter
# 03/2/2005		Added a ProgramMaker - removed tons of cruft.
#
###############################################################################

use strict;

use Goo::Thing::pm::ProgramMaker;

our @ISA = qw(Goo::Thing::pm::ProgramMaker);


###############################################################################
#
# generate - override superclass
#
###############################################################################

sub generate {

	my ($this) = @_;

	$this->SUPER::generate_header();
	
	# make sure this loads first
	$this->SUPER::generate_main();
	
	$this->SUPER::generate_methods();
	
}	
	

###############################################################################
#
# run - interface method
#
###############################################################################

sub run {

	my ($this) = @_;
	
	$this->generate();	
	
}

1;


__END__

=head1 NAME

Goo::Thing::pl::ScriptMaker - Command line utility for making scripts faster

=head1 SYNOPSIS

use Goo::Thing::pl::ScriptMaker;

=head1 DESCRIPTION



=head1 METHODS

=over

=item generate

override superclass

=item run

interface method


=back

=head1 AUTHOR

Nigel Hamilton <nigel@turbo10.com>

=head1 SEE ALSO

