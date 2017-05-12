package Goo::FileThing;

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2005
# All Rights Reserved
#
# Author:       Nigel Hamilton
# Filename:     Goo::FileThing.pm
# Description:  A new generic type of "Thing" in The Goo based on global config
#               files. A Thing is a handle on an underlying Thing.
#
# Date          Change
# -----------------------------------------------------------------------------
# 01/11/2005    Subclassed Thing - I wanted to avoid this ... but now it does
#               make sense - may use composition later.
#
###############################################################################

use strict;

use Goo::Thing;
use Goo::FileUtilities;

use base qw(Goo::Thing);


###############################################################################
#
# new - constructor
#
###############################################################################

sub new {

    my ($class, $full_path) = @_;

    unless ($full_path) {
        die("No file location specified: " . caller());
    }

    # pull apart the path
    $full_path =~ /(.*)\/(.*)$/;

    my $location = $1;
    my $filename = $2;

    # start making this Thing
    my $this = $class->SUPER::new($filename);

    # remember where this Thing can be found
    $this->{location}  = $location;
    $this->{full_path} = $full_path;
    $this->{filename}  = $filename;

    return $this;

}


###############################################################################
#
# get_file - get the full contents of the file
#
###############################################################################

sub get_file {

    my ($this) = @_;

    return Goo::FileUtilities::get_file_as_string($this->{full_path});

}


###############################################################################
#
# get_full_path - where is this thang located?
#
###############################################################################

sub get_full_path {

    my ($this) = @_;

    # return the current location
    return $this->{full_path};

}


###############################################################################
#
# get_filename - return the filename
#
###############################################################################

sub get_filename {

    my ($this) = @_;

    return $this->{filename};

}


###############################################################################
#
# get_location - return the directory this thing is located in
#
###############################################################################

sub get_location {

    my ($this) = @_;

    return $this->{location};

}

1;


__END__

=head1 NAME

Goo::FileThing - A "Thing" that is found in the filesystem and has a location

=head1 SYNOPSIS

use Goo::FileThing;

=head1 DESCRIPTION

A FileThing has a location in the file system.

=head1 METHODS

=over

=item new

constructor

=item get_file

return the full contents of the file

=item get_full_path

return the full file system path

=item get_filename

return the filename

=item get_location

return the directory this Thing is located in

=back

=head1 AUTHOR

Nigel Hamilton <nigel@trexy.com>

=head1 SEE ALSO

