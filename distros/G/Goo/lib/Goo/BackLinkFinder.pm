package Goo::BackLinkFinder;

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2005
# All Rights Reserved
#
# Author:       Nigel Hamilton
# Filename:     BackLinkFinder.pm
# Description:  Find all the backlinks for a given "Thing"
#
# Date          Change
# -----------------------------------------------------------------------------
# 01/07/2005    Auto generated file
# 01/07/2005    Need to find backlinks easily!
#
###############################################################################

use strict;

use Goo::Grepper;
use Goo::TypeManager;

#use Smart::Comments;


###############################################################################
#
# get_back_links - return a list of backlinks to this thing
#
###############################################################################

sub get_back_links {

    my ($filename) = @_;

    # show match Perl6 and Perl5 use statements
    my $pattern = ($filename =~ /(.*)\.pm$/) ? "use.*?$1" : $filename;

    # remember the things that match
    my $things = {};

    ### go through all the different $types of Things
    foreach my $type (Goo::TypeManager::get_all_types()) {

        #print "looking for this $type \n";
        ### go through all the different locations
        foreach my $location (Goo::TypeManager::get_type_locations($type)) {

            #print "looking for this $type in this $location \n";
            ### grep all the Goo locations for matching files
            my @files = Goo::Grepper::find_files($pattern, $location, $type);

            ### find all the files that contain the pattern
            foreach my $file (@files) {

                ## print "found $file \n";

                # split the filename into location and Thing
                $file =~ m/^(.*)\/(.*)$/;

                # my $location = $1;
                my $thing = $2 || $file;

                # store it in a hash to remove repeats
                $things->{$thing} = 1;

            }

        }

    }

    ##use Goo::Prompter;
    ##Goo::Prompter::dump($things);

    ### found these %$things
    return sort keys %$things;

}


1;


__END__

=head1 NAME

Goo::BackLinkFinder - Find all the backlinks for a given "Thing"

=head1 SYNOPSIS

use Goo::BackLinkFinder;

=head1 DESCRIPTION

Use a simple grep to find backlinks.

=head1 METHODS

=over

=item get_back_links

return a list of backlinks to this Thing

=back

=head1 AUTHOR

Nigel Hamilton <nigel@trexy.com>

=head1 SEE ALSO

