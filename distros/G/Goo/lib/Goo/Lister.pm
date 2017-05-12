package Goo::Lister;

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2005
# All Rights Reserved
#
# Author:       Nigel Hamilton
# Filename:     Goo::Lister.pm
# Description:  Load a whole list of Things at once - is this wise?
#
# Date          Change
# -----------------------------------------------------------------------------
# 28/06/2005    Auto generated file
# 28/06/2005    Need a simple loader
#
###############################################################################

use strict;

use Goo::Loader;
use Goo::ConfigFile;


###############################################################################
#
# get - return a list of things
#
###############################################################################

sub get {

    my ($suffix) = @_;

    # look up the master goo file that describes this type of object
    my $config_file = Goo::ConfigFile->new($suffix . ".goo");

    my @list;

    foreach my $location ($config_file->get_locations()) {
        foreach my $file (FileUtilities::get_file_list($location)) {
            # print caller()." goo lister loading $file from $directory \n";
            push(@list, Goo::Loader::load($file));
        }
    }

    # return a list of Things
    return @list;

}

1;


__END__

=head1 NAME

Goo::Lister - Load a whole list of Things in one go

=head1 SYNOPSIS

use Goo::Lister;

=head1 DESCRIPTION

=head1 METHODS

=over

=item get

return a list of Things

=back

=head1 AUTHOR

Nigel Hamilton <nigel@trexy.com>

=head1 SEE ALSO

