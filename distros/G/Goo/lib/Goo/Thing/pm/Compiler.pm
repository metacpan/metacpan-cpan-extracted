##!/usr/bin/perl

package Goo::Thing::pm::Compiler;

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2005
# All Rights Reserved
#
# Author:       Nigel Hamilton
# Filename:     Compiler.pm
# Description:  Compile a Perl program
#
# Date          Change
# ----------------------------------------------------------------------------
# 01/08/05      Factored out of ProgramEditor as part of the new Goo
# 30/08/2005    Added method: processError
#
##############################################################################

use strict;

use Goo::Object;

use Goo::Thing::pm::TypeChecker;
use Goo::Thing::pm::Perl5Compiler;
use Goo::Thing::pm::Perl6Compiler;

use base qw(Goo::Object);


###############################################################################
#
# run - keep adding a thing to the program
#
###############################################################################

sub run {

    my ($this, $thing) = @_;

    if (Goo::Thing::pm::TypeChecker::is_perl6($thing)) {
        Goo::Thing::pm::Perl6Compiler->new()->run($thing);
    } else {
        Goo::Thing::pm::Perl5Compiler->new()->run($thing);

    }

}

1;


__END__

=head1 NAME

Goo::Thing::pm::Compiler - Compile a Perl program

=head1 SYNOPSIS

use Goo::Thing::pm::Compiler;

=head1 DESCRIPTION



=head1 METHODS

=over

=item run

Delegate compiling a Perl program to either a Goo::Thing::pm::Perl6Compiler or 
Goo::Thing::pm::Perl5Compiler.

=back

=head1 AUTHOR

Nigel Hamilton <nigel@trexy.com>

=head1 SEE ALSO

