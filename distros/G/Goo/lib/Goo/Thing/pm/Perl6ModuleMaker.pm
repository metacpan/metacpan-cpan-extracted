#!/usr/bin/perl

package Goo::Perl6ModuleMaker;

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2003
# All Rights Reserved
#
# Author:       Nigel Hamilton
# Filename:     Goo::Perl6ModuleMaker.pm
# Description:  Command line utility for making module skeletons faster
#
# Date          Change
# -----------------------------------------------------------------------------
# 14/8/2005     Version 1
#
###############################################################################

use strict;

use Goo::Prompter;
use Goo::TeamManager;
use Goo::Thing::pm::PerlCoder;

use base qw(Goo::Object);


###############################################################################
#
# run - interface method
#
###############################################################################

sub run {

    my ($this, $filename) = @_;

	Goo::Prompter::notify("The Perl6ModuleMaker is not implemented yet.");

}


1;


__END__

=head1 NAME

Goo::Perl6ModuleMaker - Command line utility for making Perl6 module skeletons faster

=head1 SYNOPSIS

use Goo::Perl6ModuleMaker;

=head1 DESCRIPTION

=head1 METHODS

=over

=item run

Not implemented yet.

=back

=head1 AUTHOR

Nigel Hamilton <nigel@trexy.com>

=head1 SEE ALSO

