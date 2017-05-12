#!/usr/bin/perl

package Goo::Thing::pm::Perl6Runner;

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2005
# All Rights Reserved
#
# Author:       Nigel Hamilton
# Filename:     Perl6Runner.pm
# Description:  Run a Perl program
#
# Date          Change
# ----------------------------------------------------------------------------
# 01/08/2005    Factored out of ProgramEditor as part of the new Goo
#
##############################################################################

use Goo::Object;
use Goo::Prompter;

use base qw(Goo::Object);


###############################################################################
#
# run - keep adding a thing to the program
#
###############################################################################

sub run {

    my ($this, $thing, $target) = @_;

    my $filename = $thing->get_full_path();
    my $name     = $thing->get_filename();

    Goo::Prompter::say("Running $filename ...");

    # execute perl
    print `/usr/bin/pugs $filename`;

    Goo::Prompter::notify("Finished running $name. Press a key.");

}

1;


__END__

=head1 NAME

Goo::Thing::pm::Perl6Runner - Run a Perl program

=head1 SYNOPSIS

use Goo::Thing::pm::Perl6Runner;

=head1 DESCRIPTION



=head1 METHODS

=over

=item run

keep adding a thing to the program


=back

=head1 AUTHOR

Nigel Hamilton <nigel@trexy.com>

=head1 SEE ALSO

