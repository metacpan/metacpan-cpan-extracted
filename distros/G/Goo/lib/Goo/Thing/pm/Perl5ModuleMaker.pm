#!/usr/bin/perl

package Goo::Perl5ModuleMaker;

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2003
# All Rights Reserved
#
# Author:       Nigel Hamilton
# Filename:     Goo::Perl5ModuleMaker.pm
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

    # keep making modules --- don't ever stop!!! ;-)
    while (1) {

        # show the header --- use the Goo::Header instead
        Goo::Prompter::show_detailed_header("Perl5ModuleMaker", $filename);

        my $name = Goo::FileUtilities::get_prefix($filename);

        # employ a PerlCoder to help out!
        my $pc = Goo::PerlCoder->new($filename);

        # add the module name to start of the file: package MyModule;
        $pc->add_module_name($name);

        # add the comments header
        $pc->add_header($filename,
                        Goo::Prompter::pick_one("author?",
                                                Goo::TeamManager::get_programmer_names()
                                               ),
                        Goo::Prompter::pick_one("company?", Goo::TeamManager::get_companies()),
                        ucfirst(Goo::Prompter::ask("Enter a description of $name?")),
                        ucfirst(Goo::Prompter::ask("Enter a reason for creating $name?"))
                       );

        # what packages?
        my @packages = Goo::Prompter::keep_asking("Add a package?");

        # add the packages to the file
        $pc->add_packages(@packages);

        # do we inherit from anything?
        my $isa_package =
            Goo::Prompter::pick_one("Which package does $name inherit from?", @packages);

        if ($isa_package) {

            # add the isa_package
            $pc->add_isa($isa_package);

            # if so add a constructor
            if (Goo::Prompter::confirm("Add a constructor?", "Y")) {
                my @parameters =
                    Goo::Prompter::keep_asking(
                                            "enter a constructor parameter (mandatories first)?");
                $pc->add_constructor(@parameters);
            }
        }

        # keep asking for a new method
        while (my $method = Goo::Prompter::ask("Enter a method for $name?")) {
            last unless $method;
            my $description = Goo::Prompter::ask("Enter a description for $method?");
            my @parameters  =
                Goo::Prompter::keep_asking("enter a parameter for $method (mandatories first)?");
            $pc->add_method($method, $description, @parameters);
        }

        # add the returns true 1; at the bottom
        $pc->add_returns_true($name);

        Goo::Prompter::yell("Module $name created.");

        if (Goo::Prompter::confirm("Save module $name?", "Y")) {

            # save the code to disk
            $pc->save();
        }

        Goo::Prompter::yell("Module $name saved.");

        # create a unit test?
        if (Goo::Prompter::confirm("Create unit test?")) {
            my $tm = Goo::Thing::tpm::TestMaker->new($filename);
            $tm->create_test_for_module();
            Goo::Prompter::yell("Created unit test.");
        }

        # create another module!
        if (Goo::Prompter::confirm("Create another module?", "N")) {
            $filename = Goo::Prompter::ask("Enter the name of the new module?");
        } else {

            # finished!
            last;
        }

    }
}


1;


__END__

=head1 NAME

Goo::Perl5ModuleMaker - Command line utility for making Perl5 module skeletons faster

=head1 SYNOPSIS

use Goo::Perl5ModuleMaker;

=head1 DESCRIPTION



=head1 METHODS

=over

=item run

make the module skeleton

=back

=head1 AUTHOR

Nigel Hamilton <nigel@trexy.com>

=head1 SEE ALSO

