#!/usr/bin/perl

package Goo::Thing::pm::Perl5Compiler;

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2005
# All Rights Reserved
#
# Author:       Nigel Hamilton
# Filename:     Goo::Thing::pm::Perl5Compiler.pm
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
use Goo::Prompter;

use base qw(Goo::Object);

# constant!
my $last_error_file = "/tmp/last-goo-error.txt";


###############################################################################
#
# run - keep adding a thing to the program
#
###############################################################################

sub run {

    my ($this, $thing) = @_;

    my $filename = $thing->get_full_path();

    Goo::Prompter::say("Compiling ...");

    # remove any previous erros
    unlink($last_error_file);

    # redirect STDERR to STDOUT
    my $results = `/usr/bin/perl -I$ENV{HOME}/.goo -c $filename 2 &> $last_error_file`;

    # do we have any errors?
    if (-e $last_error_file) {

        # oops - compilation included an error - lets jump to it
        process_error($thing);
    }

    Goo::Prompter::notify("Finished compiling.\nPress a key to continue.");


}


###############################################################################
#
# process_error - enable the user to jump to the last error
#
###############################################################################

sub process_error {

    my ($thing) = @_;

    my $error_report = Goo::FileUtilities::slurp($last_error_file);

    # show the errors!
    print $error_report;

    if ($error_report =~ m/.*line\s+(\d+)/s) {

        my $error_on_line = $1;

        if (Goo::Prompter::confirm("Jump to error on line $error_on_line?")) {

            # there was an error - jump to the line
            $thing->do_action("J", $error_on_line);
        }

    }


}


1;


__END__

=head1 NAME

Goo::Thing::pm::Perl5Compiler - Compile a Perl program

=head1 SYNOPSIS

use Goo::Thing::pm::Perl5Compiler;

=head1 DESCRIPTION


=head1 METHODS

=over

=item run

call /usr/bin/perl -c to compile the code.

=item process_error

catch any error so the user can jump to the last error

=back

=head1 AUTHOR

Nigel Hamilton <nigel@trexy.com>

=head1 SEE ALSO
