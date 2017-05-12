package Goo::Thing::pm::Maker;

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2003
# All Rights Reserved
#
# Author:       Nigel Hamilton
# Filename:     Goo::Thing::pm::Maker.pm
# Description:  Command line utility for making module skeletons faster
#
# Date          Change
# -----------------------------------------------------------------------------
# 14/8/2003     Version 1
# 02/2/2005     Added a Prompter for consistent text highlighting and questions
# 13/6/2005     Added a run() method for working with the new meta description
#               provided by "The Goo"
# 16/10/2005    Inheritance was getting in the way - needed to make this
#               simple - like with profiles
#               This has been seriously refactored - new version coming soon
#
###############################################################################

use strict;

use Goo::Thing::pm::Perl6ModuleMaker;
use Goo::Thing::pm::Perl5ModuleMaker;


###############################################################################
#
# run - interface method
#
###############################################################################

sub run {

    my ($this, $thing) = @_;

    if (Goo::Thing::TypeChecker::is_perl6($thing)) {
        Goo::Thing::pm::Perl6ModuleMaker->new()->run($thing);
    } else {
        Goo::Thing::pm::Perl5ModuleMaker->new()->run($thing);
    }

}

1;


__END__

=head1 NAME

Goo::Thing::pm::Maker - Command line utility for making module skeletons faster

=head1 SYNOPSIS

use Goo::Thing::pm::Maker;

=head1 DESCRIPTION



=head1 METHODS

=over

=item run

Delegating making Perl modules to either Goo::Thing::pm::Perl6ModuleMaker or 
Goo::Thing::pm::Perl5ModuleMaker.

=back

=head1 AUTHOR

Nigel Hamilton <nigel@trexy.com>

=head1 SEE ALSO

