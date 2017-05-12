package Goo::Thing::pm::PerlTidyManager;

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2005
# All Rights Reserved
#
# Author:       Nigel Hamilton
# Filename:     Goo::Thing::pm::PerlTidyManager
# Description:  Tidy up a Perl program - make sure the indentation is correct
#               The tidy parameters are set on a per directory basis in the
#              	perltidyrc file - if there is not one in the current directory
#               it looks in the home directory of the current user.
#               Update the perltidyrc file to change the main parts of perltidy.
#               The format is based on the Best Practices written by Damian
#               Conway - "Perl Best Practices"..
#
# Date          Change
# -----------------------------------------------------------------------------
# 05/09/2005    Auto generated file
# 05/09/2005    Needed to wrap the Perl Tidy utility with my own options
#
###############################################################################

use strict;

use Perl::Tidy;
use Goo::Prompter;
use Goo::TabConverter;
use Goo::FileUtilities;


###############################################################################
#
# process - tidy a file
#
###############################################################################

sub process {

    my ($filename) = @_;

    unless ( -e $filename ) {
        die("$filename does not exist. Unable to tidy.");
    }

    my $tidy_file = $filename . ".tdy";

    # call perltidy on the file
    `perltidy -pro='$ENV{HOME}/.goo/perltidyrc' $filename > $tidy_file`;

    unless ( -e $tidy_file ) {
        Goo::Prompter::notify("perltidy failed to generate $tidy_file");
        exit;
    }

    # add an extra space between subs
    # $file =~ s/^\}/\}\n/gms;

    my @tidier_lines;

    foreach my $line (Goo::FileUtilities::get_file_as_lines($tidy_file)) {
    
        # find any tabs in comments
        if ($line =~ /^\#.*\t/) {

			# convert tabs to 4 spaces
            $line = Goo::TabConverter::tabs_to_spaces($line, 4);
        }

        push(@tidier_lines, $line);        

    }

    Goo::FileUtilities::write_lines_as_file($filename, @tidier_lines);

    # remove the .tdy file
    unlink($tidy_file);

}

1;


__END__

=head1 NAME

Goo::Thing::pm::PerlTidyManager - Tidy up a Perl program using PerlTidy

=head1 SYNOPSIS

use Goo::Thing::pm::PerlTidyManager;

=head1 DESCRIPTION


=head1 METHODS

=over

=item process

tidy up a file after we've finished editing it


=back

=head1 AUTHOR

Nigel Hamilton <nigel@trexy.com>

=head1 SEE ALSO

Perl::Tidy
