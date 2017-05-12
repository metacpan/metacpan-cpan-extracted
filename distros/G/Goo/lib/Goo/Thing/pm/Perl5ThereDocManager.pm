package Goo::Thing::pm::Perl5ThereDocManager;

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2005
# All Rights Reserved
#
# Author:       Nigel Hamilton
# Filename:     Goo::Thing::pm::Perl5ThereDocManager.pm
# Description:  Process ThereDocs embedded in Things
#
# Date          Change
# -----------------------------------------------------------------------------
# 16/08/2005    Auto generated file
# 16/08/2005    Needed a way to jump from Here to There
# 23/10/2005    Created test file: ThereDocManagerTest.tpm
#
###############################################################################

use strict;

use Goo::Loader;
use Goo::Prompter;
use Goo::ThereDocManager;
use Goo::Thing::pm::ScopeMatcher;
use Goo::Thing::pm::MethodMatcher;

use base qw(Goo::ThereDocManager);


###############################################################################
#
# find_package_and_method - return the method and package the there_doc is targetting
#
###############################################################################

sub find_package_and_method {

    my ($this, $target, $filename, $full_path, $target_line_number) = @_;

    # a simple method call in this package
    if ($target =~ /\s+(\w+)\(/) {

        # package, method
        return ($filename, $1);
    }

    # a sub call in another package (e.g., Database::get_row())
    if ($target =~ /(\w+)::(\w+)\(/) {

        # package, method
        return ($1 . ".pm", $2);
    }

    # a constructor call
    if ($target =~ /(\w+)\->(new)\(/) {

        # package, method
        return ($1 . ".pm", $2);
    }

    # a method call
    if ($target =~ /(\w+)\->(\w+)\(/) {

        my $referent = $1;
        my $method   = $2;

        # package, method
        return ($filename, $method) if ($referent =~ /\$(this|self)/);

        # where is the referent from?
        # look for it in the current scope
        my $current_scope =
            Goo::Thing::pm::ScopeMatcher::get_scope_of_line($target_line_number, $full_path);

        # For example, what is the package for $car?
        # my $car = Car->new()
        if ($current_scope =~ /my\s+\$$referent\s+=\s+(\w+)\->new\(/) {

            # the referent is constructed in this scope
            # jump to this package
            return ($1 . ".pm", $method);

        }

        # check if the referent is a package method
        # my $car = CarFactory::get_car();
        if ($current_scope =~ /my\s+\$$referent\s+=\s+(\w+)::(\w+)/) {
            ### look up the referent in the current scope?
            # e.g. my $car = CarFactory::getCar
            return ($1 . ".pm", $2);
        }

    }

}


###############################################################################
#
# process - given a string, look for there_docs and then do things if you
#           find one!
#
###############################################################################

sub process {

    my ($this, $thing) = @_;

    # match the string the ThereDoc is  targetting <<< this bit
    my ($mode, $target_string, $theredoc_line_number) =
        $this->find_there_doc($thing->get_full_path());

    # Prompter::notify("found there_doc with mode $mode at $target_string + $theredoc_line_number");

    # which package and method is the ThereDoc targetting?
    my ($package, $method) =
        $this->find_package_and_method($target_string,          $thing->get_filename(),
                                       $thing->get_full_path(), $theredoc_line_number);


    if ($package && $method) {

        # Prompter::notify("ThereDoc targets: $package, $method");

        my $target_thing       = Goo::Loader::load($package);
        my $target_line_number =
            Goo::Thing::pm::MethodMatcher::get_line_number($method, $target_thing->get_file());

        # jump back to where we were before we did the jump?
        return ($theredoc_line_number, $target_thing, $mode, $target_line_number);


    }

    # does the user want to jump to another Thing?
    return $this->SUPER::process($thing->get_full_path());


}

1;


__END__

=head1 NAME

Goo::Thing::pm::Perl5ThereDocManager - Process ThereDocs embedded in Perl5 programs

=head1 SYNOPSIS

use Goo::Thing::pm::Perl5ThereDocManager;

=head1 DESCRIPTION



=head1 METHODS

=over

=item find_package_and_method

return the method and package the ThereDoc is targetting

=item process

given a string, look for ThereDocs and then carry out the first ThereDoc action.

=back

=head1 AUTHOR

Nigel Hamilton <nigel@trexy.com>

=head1 SEE ALSO

