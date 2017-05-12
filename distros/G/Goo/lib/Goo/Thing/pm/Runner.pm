#!/usr/bin/perl

package Goo::Thing::pm::Runner;

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2005
# All Rights Reserved
#
# Author:       Nigel Hamilton
# Filename:     Runner.pm
# Description:  Run a Perl program
#
# Date          Change
# ----------------------------------------------------------------------------
# 01/08/2005    Factored out of ProgramEditor as part of the new Goo
#
##############################################################################

use Goo::Object;
use Goo::Prompter;
use Goo::Thing::pm::TypeChecker;
use Goo::Thing::pm::Perl5Runner;
use Goo::Thing::pm::Perl6Runner;

use base qw(Goo::Object);


###############################################################################
#
# run - keep adding a thing to the program
#
###############################################################################

sub run {

    my ($this, $thing, $target) = @_;

  	if (Goo::Thing::pm::TypeChecker::is_perl6($thing)) {
        Goo::Thing::pm::Perl6Runner->new()->run($thing, $target);
    } else {
        Goo::Thing::pm::Perl5Runner->new()->run($thing, $target);

    }

}


1;


__END__

=head1 NAME

Goo::Thing::pm::Runner - Run a Perl program

=head1 SYNOPSIS

use Goo::Thing::pm::Runner;

=head1 DESCRIPTION



=head1 METHODS

=over

=item run

Delegate running a Perl program to either Goo::Thing::pm::Perl6Runner or 
Goo::Thing::pm::Perl5Runner.

=back

=head1 AUTHOR

Nigel Hamilton <nigel@trexy.com>

=head1 SEE ALSO

