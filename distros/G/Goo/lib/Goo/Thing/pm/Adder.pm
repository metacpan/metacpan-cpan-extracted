#!/usr/bin/perl

package Goo::Thing::pm::Adder;

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2005
# All Rights Reserved
#
# Author:       Nigel Hamilton
# Filename:     Goo::Thing::pm::Adder.pm
# Description:  Add stuff to a Perl program
#
# Date          Change
# ----------------------------------------------------------------------------
# 01/08/05      Factored out of ProgramEditor as part of the new Goo
# 09/08/2005    This is the first change that has been automatically added.
# 09/08/2005    Added the function that enables me to added changes like this. We
#               also need to test the line wrapping. Does it do a good job of
#               retaining the columns?
# 09/08/2005    I really like the way it handles automated dates - cool!
#
##############################################################################

use strict;

use Goo::Object;
use Goo::Prompter;
use Goo::Thing::pm::PerlCoder;
use Goo::Thing::pm::MethodMaker;
use Goo::Thing::pm::TypeChecker;

use base qw(Goo::Object);


###############################################################################
#
# run - keep adding a thing to the program
#
###############################################################################

sub run {

    my ($this, $thing, $option) = @_;

    if (Goo::Thing::pm::TypeChecker::is_perl6($thing)) {
        Goo::Thing::pm::Perl6Compiler->new()->run($thing, $option);
    } else {
        Goo::Thing::pm::Perl5Compiler->new()->run($thing . $option);
    }

}


1;


__END__

=head1 NAME

Goo::Thing::pm::Adder - Add stuff to a Perl program

=head1 SYNOPSIS

use Goo::Thing::pm::Adder;

=head1 DESCRIPTION



=head1 METHODS

=over

=item run

Delegate adding stuff to either Goo::Thing:pm::Perl5Adder or Goo::Thing::pm::Perl6Adder.

=back

=head1 AUTHOR

Nigel Hamilton <nigel@trexy.com>

=head1 SEE ALSO

