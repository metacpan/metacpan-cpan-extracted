package TestLoader;

###############################################################################
# Turbo10.com
#
# Copyright Nigel Hamilton 2005
# All Rights Reserved
#
# Author:       Nigel Hamilton
# Filename:     TestLoader.pm
# Description:  Load a test from disk to run
#
# Date          Change
# -----------------------------------------------------------------------------
# 14/02/2005    Auto generated file
# 14/02/2005    Needed to make TestRunner a little simpler
# 05/05/2005    Added tcgi for testing CGI scripts
#
###############################################################################

use strict;

use Thing;
use FileUtilities;


###############################################################################
#
# load_test - can we run it? - this raises exceptions
#
###############################################################################

sub load_test {

    my ($filename) = @_;

    # print "trying to load ... $filename !!\n";
    unless ($filename =~ /\.t?pm$/) {
        die("$filename is not a valid module.");
    }

    my $module = $filename;

    # strip the path
    $module =~ s!.*/!!;

    # strip the last suffix
    $module =~ s/\..*$//;

    # add the special suffix for module tests
    $module .= ".tpm";

    # load the module - tried eval in a code block { } but it didn't work
    # watch this if BUG from evalling twice?
    eval("require '$filename';");

    if ($@) { die("Failed to require $module: $@"); }

    $module =~ s/\.tpm$//g;

    # calling this ...
    #print "	my $module->new($module); \n";

    my $test = $module->new($module);

    unless ($test->isa("Tester")) {
        die("$module is not a Tester module");
    }

    unless ($test->can("do")) {
        die("$module does not contain a do method");
    }

    return $test;

}

1;



__END__

=head1 NAME

TestLoader - Load a test from disk to run

=head1 SYNOPSIS

use TestLoader;

=head1 DESCRIPTION



=head1 METHODS

=over

=item load_test

can we run it? - this raises exceptions


=back

=head1 AUTHOR

Nigel Hamilton <nigel@turbo10.com>

=head1 SEE ALSO

