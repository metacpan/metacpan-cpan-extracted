#!/usr/bin/perl

##############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2004
# All Rights Reserved
#
# Author:       Nigel Hamilton
# Filename:     goo.pl
# Description:  Stick Things together with The Goo
#
# Date          Change
# -----------------------------------------------------------------------------
# 08/03/2004    Auto generated file
# 08/03/2004    Make code creation and all my jobs faster
# 29/10/2004    Revisited to add new command line controller with
#               plug in options - so I can incrementally build this sucker.
# 02/02/2005    Added a "delete" object option
# 01/08/2005    Added new flexible options based on new Goo format
#               Simplified this part of the system.
# 01/11/2005    Small fixups
#
###############################################################################

use strict;

#use lib $ENV{GOOBASE};

use Goo;
use Goo::Shell;
use Goo::CommandLineManager;

my $clm = Goo::CommandLineManager->new(@ARGV);

my $option = uc($clm->get_selected_option());    # default to Edit

# the filename is the last parameter!
my $filename = $clm->get_last_parameter();

# get any remaining parameters
my @parameters = $clm->get_parameters();

if ($option eq "Z") {

    # [Z]one is the tail of the trail
    $option   = "P";
    $filename = "tail.trail";

} elsif ($option eq "O") {

    # Care[O]Meter is special view on Things we care about (care.goo)
	# it helps answer the question: what do I do next?
    $option   = "O";
    $filename = "care.goo";

}

#print "$option ---- $filename \n";
if ($option && $filename) {

    # pass the command line options to The Goo
    my $goo = Goo->new();
    $goo->do_action($option, $filename, @parameters);

} else {

    # jump to the shell
    Goo::Shell::do();
    exit;

}

__END__

=head1 NAME

 - GOO = Generate OO code

=head1 SYNOPSIS

use ;

=head1 DESCRIPTION



=head1 METHODS


=head1 AUTHOR

Nigel Hamilton <nigel@trexy.com>

=head1 SEE ALSO

