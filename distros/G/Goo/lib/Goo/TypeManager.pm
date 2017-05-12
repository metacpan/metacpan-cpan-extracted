package Goo::TypeManager;

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2005 All Rights Reserved
#
# Author:       Nigel Hamilton
# Filename:     GooTypeManager.pm
# Description:  Manage all the different types of Things in The Goo
#               The type of a Thing is determined by its suffix (e.g., Thing.pm)
#               All valid types have a corresponding .goo file (e.g., pm.goo)
#               The .goo files are located in /home/search/goo/things/goo
#
# Date          Change
# -----------------------------------------------------------------------------
# 20/06/2005    Auto generated file
# 20/06/2005    Need to store global config parameters
# 23/08/2005    Added method: isValidThing
#
###############################################################################

use strict;

use Data::Dumper;
use Goo::ConfigFile;
use Goo::FileUtilities;


# load at BEGIN time
my @GOO_TYPES;

# where all the config files are stored
my $GOO_CONFIG_ROOT = "$ENV{HOME}/.goo/things/goo";


###############################################################################
#
# get_all_types - return the types of all thangs
#
###############################################################################

sub get_all_types {

    return @GOO_TYPES;

}


###############################################################################
#
# get_type_locations - return a list of directories where this thing is located
#
###############################################################################

sub get_type_locations {

    my ($type) = @_;

    # make sure we have the right type
    $type = ($type =~ /\.goo$/) ? $type : $type . ".goo";

    # load the configuration file for this type of Thing
    my $config_file = Goo::ConfigFile->new($type);

    # return the locations where Things of this type can be found
    return $config_file->get_locations();

}


###############################################################################
#
# is_valid_thing - is this a thing?
#
###############################################################################

sub is_valid_thing {

    my ($filename) = @_;

    foreach my $type (get_all_types()) {

        return 1 if ($filename =~ /\.$type/);
    }

    return 0;

}


###############################################################################
#
# BEGIN - load the configuration for the goo
#
###############################################################################

sub BEGIN {

    my $GOO_CONFIG_ROOT = "$ENV{HOME}/.goo/things/goo";

    # look for all the Goo config files
    foreach my $config_filename (Goo::FileUtilities::get_file_list($GOO_CONFIG_ROOT . "/*.goo")) {

        $config_filename =~ /.*\/(.*)\.goo/;
        push(@GOO_TYPES, $1);

    }

    #use Goo::Prompter;
    # Goo::Prompter::prompt("Found these types: " . join(" ", @GOO_TYPES));

}


1;


__END__

=head1 NAME

Goo::TypeManager - Manage all the different types of Things in The Goo

=head1 SYNOPSIS

use Goo::TypeManager;

=head1 DESCRIPTION


=head1 METHODS

=over

=item get_all_types

return the types of all Things

=item get_type_locations

return a list of directories where this Thing is located

=item is_valid_thing

is this a Thing?

=item BEGIN

load the configuration for The Goo

=back

=head1 AUTHOR

Nigel Hamilton <nigel@trexy.com>

=head1 SEE ALSO

