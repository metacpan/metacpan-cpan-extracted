package Goo::Grepper;

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2005
# All Rights Reserved
#
# Author:       Nigel Hamilton
# Filename:     Goo::Grepper.pm
# Description:  Grep all the files in a directory for a pattern
#
# Date          Change
# -----------------------------------------------------------------------------
# 15/06/2005    Auto generated file
# 15/06/2005    Needed to do fast backlink calculations for The Goo!
#
###############################################################################

use strict;

use Goo::Prompter;
use File::Grep qw(fdo);


###############################################################################
#
# find_files - find all the files that match a pattern in a directory
#
###############################################################################

sub find_files {

    my ($pattern, $directory, $suffix) = @_;

    my @files = glob "$directory/*.$suffix";
    my @filenames;

    fdo {
        my ($file, $pos, $line) = @_;    # iterate all given filenames
        if ($line =~ qr/$pattern/ &&     # if any line in a filename matches $pattern AND
            $files[$file] =~ /([^\/]+)$/
            ) {                          # we can extract just the filename
                                         # print "found match $1 \n";
            push @filenames, $1;         # push it to list of filenames
        }
        }
        @files;

    # print "found these filenames " . join("\n", @filenames);
    return @filenames;

}

1;


__END__

=head1 NAME

Goo::Grepper - Grep all the files in a directory for a pattern

=head1 SYNOPSIS

use Goo::Grepper;

=head1 DESCRIPTION

Grep through files trying to find a string.

=head1 METHODS

=over

=item find_files

find all the files in a directory that match a pattern

=back

=head1 AUTHOR

Nigel Hamilton <nigel@trexy.com>

=head1 SEE ALSO

