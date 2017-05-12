package Goo::Loader;

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2005
# All Rights Reserved
#
# Author:       Nigel Hamilton
# Filename:     Goo::Loader.pm
# Description:  Load a Thing from Goo Space
#
# Date          Change
# -----------------------------------------------------------------------------
# 28/06/2005    Auto generated file
# 28/06/2005    Need a simple loader
# 17/10/2005    Added method: get_maker
# 17/10/2005    Added method: get_suffix
# 12/11/2005    Needed to make the loader be more specifc
#
###############################################################################

use strict;

use Cwd;

use Goo::Database;
use Goo::Prompter;

use Goo::FileThing;
use Goo::ConfigFile;
use Goo::DatabaseThing;
use Goo::FileThing::Finder;


###############################################################################
#
# load - return a thang
#
###############################################################################

sub load {

    my ($filename) = @_;

    # special allowance for the mighty perl!
    # map packages to filenames
    $filename =~ s/::/\//g;

    # grab the config file for this type of Thing
    my $config_file = Goo::ConfigFile->new(get_suffix($filename) . ".goo");

    # need to return a Thing
    my $thing;

    # it must be a file based Thing
    if ($config_file->has_locations()) {

        my $full_path;

        if (-e $filename) {

            # is the filename relative or absolute? return the path
            $full_path =
                ($filename =~ /^\//)
                ? $filename
                : getcwd() . "/" . $filename;

        } else {

            # file doesn't exist in current location - lets go looking
            $full_path = Goo::FileFinder::find($filename, $config_file->get_locations());
        }

        # we have a full_path to this FileThing
        $thing = Goo::FileThing->new($full_path);

    } elsif ($config_file->has_table()) {

        # this is a DatabaseThing look it up in the database
        # for example grab a bug (e.g., 12.bug)
        $thing = Goo::DatabaseThing->new($filename);

    } else {

        # this is a GooThing with no location
        # for example: care.goo - base it on the .goo file
        # this enables us to have controller Things without
        # a location - [Z]one, Care[O]Meter etc.
        $thing = Goo::Thing->new($filename);

    }

    unless ($thing->isa("Goo::Thing")) {
        die("Unable to load Thing for $filename.");
    }

    return $thing;

}


###############################################################################
#
# get_maker - things must be made first!
#
###############################################################################

sub get_maker {

    my ($filename) = @_;

    print "FILENAME: $filename\n";

    # get the config file for this Thing!
    my $config_file = Goo::ConfigFile->new(get_suffix($filename) . '.goo');

    # get the Maker that creates this Thing
    my $maker = $config_file->get_program('M');

    if ($maker ne '') {

        # dynamically load the maker - remove absolute path later
        my $require_filename = $maker;

        # convert package to directories
        $require_filename =~ s/::/\//g;

        require "$require_filename";

        # strip any .pm off the end
        $maker =~ s/.pm$//;

        # return the maker object
        return $maker->new();
    }

}

###############################################################################
#
# get_prefix - return the goo prefix
#
###############################################################################

sub get_prefix {

    my ($filename) = @_;

    # strip the path if there is one
    $filename =~ s!.*/!!;

    # match the suffix
    $filename =~ m/(.*)\.*$/;

    # match the suffix (.pm) or the whole Thing (task)
    return $1 || $filename;

}


###############################################################################
#
# get_suffix - return the goo prefix
#
###############################################################################

sub get_suffix {

    my ($filename) = @_;

    # strip the path if there is one
    $filename =~ s!.*/!!;

    # match the suffix
    $filename =~ m/.*\.(.*)$/;

    # match the suffix (.pm) or the whole Thing (task)
    return $1 || $filename;

}


###############################################################################
#
# run_driver - drive the module from the command line
#
###############################################################################

sub run_driver {

    my $thing = load("care.goo");
    print $thing->to_string();

}

# called from the command line
run_driver(@ARGV) unless (caller());


1;


__END__

=head1 NAME

Goo::Loader - Load a Thing from Goo space

=head1 SYNOPSIS

use Goo::Loader;

=head1 DESCRIPTION

Look for a Thing, load it and return it.

=head1 METHODS

=over

=item load

return a Thing

=item get_maker

Some Things must be made first! Return a maker for a Thing.

=item get_prefix

return the goo prefix

=item get_suffix

return the goo prefix

=item run_driver

drive this module from the command line

=back

=head1 AUTHOR

Nigel Hamilton <nigel@trexy.com>

=head1 SEE ALSO

