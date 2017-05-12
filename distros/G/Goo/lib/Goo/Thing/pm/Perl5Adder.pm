#!/usr/bin/perl

package Goo::Thing::pm::Perl5Adder;

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2005
# All Rights Reserved
#
# Author:  	 	Nigel Hamilton
# Filename: 	Perl5Adder.pm
# Description:  Add stuff to a program
#
# Date      	Change
# ----------------------------------------------------------------------------
# 01/08/2005  	Factored out of ProgramEditor as part of the new Goo
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
	
use base qw(Goo::Object);


###############################################################################
#
# run - keep adding a thing to the program
#
###############################################################################

sub run {

    my ($this, $thing, $option) = @_;

    unless ($option) {
        $option = Goo::Prompter::pick_command("[M]ethod, [C]hange Log or [P]ackage", "M");
    }

    my $pc = Goo::Thing::pm::PerlCoder->new({ filename => $thing->get_full_path() 
});

    if ($option eq "P") {

        my @packages = Goo::Prompter::keep_asking("Add a package?");
        foreach my $package (@packages) {

            # keep adding packages to the program
            $pc->add_package($package);
        }

    } elsif ($option eq "M") {

        my $mm = Goo::Thing::pm::MethodMaker->new();
        foreach my $method ($mm->generate_methods()) {
            $pc->add_method($method);
        }

    } elsif ($option eq "C") {

        my $change = Goo::Prompter::ask("Describe a change:");
        $pc->add_change_log($change);

        # save any code changes

    } else {
        Goo::Prompter::notify("Nothing added.");
        return;
    }

    $pc->save();
    return;

}


1;


__END__

=head1 NAME

Goo::Thing::pm::Perl5Adder - Add stuff to a Perl5 program

=head1 SYNOPSIS

use Goo::Thing::pm::Perl5Adder;

=head1 DESCRIPTION



=head1 METHODS

=over

=item run

Action handler for adding methods, packages or change log entries to a Perl5 program (i.e., 
[A]dd).

=back

=head1 AUTHOR

Nigel Hamilton <nigel@trexy.com>

=head1 SEE ALSO

