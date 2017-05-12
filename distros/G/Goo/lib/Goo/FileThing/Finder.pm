package Goo::FileFinder;

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2005
# All Rights Reserved
#
# Author:       Nigel Hamilton
# Filename:     Goo::FileFinder.pm
# Description:  Go looking for files
#
# Date          Change
# -----------------------------------------------------------------------------
# 17/11/2005    Find files given locations
#
###############################################################################

use strict;
use Goo::Prompter;


###############################################################################
#
# find  - return a location for a Thing - look for it in Goo space!!
#
###############################################################################

sub find {

    my ($filename, @locations) = @_;

    my @found_locations;

    # check all the locations where this Thing can be found
    foreach my $location (@locations) {

        ### checking a location location
        my $file_location = $location . "/" . $filename;

        if (-e $file_location) {
            ### return the first file we find of that name
            push(@found_locations, $file_location);
        }

    }

    if (scalar(@found_locations) > 1) {

        my $selected_location = Goo::Prompter::pick_one("Select which file?", @found_locations);
        foreach my $location (@found_locations) {
            next if $location eq $selected_location;

            #if (Goo::Prompter::confirm("Delete $location", "N")) {
            #   unlink($location);
            #}
        }

        return $selected_location;

    } else {
        return pop(@found_locations);
    }

}


###############################################################################
#
# run_driver
#
###############################################################################

sub run_driver {

    print find("FileFinder.pm", ("/home/goo/src/Goo"));

}

# called from the command line
run_driver(@ARGV) unless (caller());

1;


__END__

=head1 NAME

Goo::FileFinder - Go looking for files

=head1 SYNOPSIS

use Goo::FileFinder;

=head1 DESCRIPTION



=head1 METHODS

=over


=back

=head1 AUTHOR

Nigel Hamilton <nigel@trexy.com>

=head1 SEE ALSO

