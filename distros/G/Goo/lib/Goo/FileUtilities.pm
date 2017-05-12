package Goo::FileUtilities;

###############################################################################
# trexy.com - handle files
#
# Copyright Nigel Hamilton 2002
# All Rights Reserved
#
# Author:       Nigel Hamilton
# Filename:     Goo::FileUtilities.pm
# Description:  General file handling utilities
#
#
# Date          Change
# -----------------------------------------------------------------------------
# 17/06/2002    Version 1
# 07/07/2004    Added simple file writing method
# 10/03/2005    Added mtime on checker
# 01/07/2005    Added getPath - smarter regex handling
# 01/07/2005    Added getSuffix
# 17/10/2005    Added method: getCWD
# 02/12/2005    Added getLastLines - tail replacement
#
###############################################################################

use strict;

use Cwd;
use File::Spec;
use File::stat;

###############################################################################
#
# get_mtime - get file modification time
#
###############################################################################

sub get_mtime {

    my ($filename) = @_;

    my $file_info = stat($filename);

    return $file_info->mtime();

}

###############################################################################
#
# get_file_hash - return a hash of files and their contents
#
###############################################################################

sub get_file_hash {

    my ($directory) = @_;

    my $filehash = {};

    my @files = get_file_list($directory);

    foreach my $file (@files) {
        $filehash->{$file} = get_file_as_string($file);
    }

    return $filehash;

}

###############################################################################
#
# get_short_file_list - filenames list only
#
###############################################################################

sub get_short_file_list {

    my ($directory) = @_;

    return map { $_ =~ s!^.*/!! } get_file_list($directory);

}

###############################################################################
#
# get_file_list - return a list of file based on a directory glob
#
###############################################################################

sub get_file_list {

    my $directory = shift;

    # restore line mode
    $/ = "\n";

    # read in all files from directory like with `ls $directory`
    opendir THISDIR, $directory;
    my @newfiles = sort { lc $a cmp lc $b}
                   grep !/^\./, readdir THISDIR;
    closedir THISDIR;

    return @newfiles;

}

###############################################################################
#
# get_file_as_string_ref - grab a file as a string
#
###############################################################################

sub get_file_as_string_ref {

    my ($filename) = @_;

    local $/;    # put PERL into slurp mode

    open(FILE, "< $filename")
        or die("[" . caller() . "] Can't open file for reading: $filename\n");

    my $filecontents = <FILE>;    # slurp int entire file

    close(FILE);

    return \$filecontents;

}

###############################################################################
#
# get_file_as_string - grab a file as a string
#
###############################################################################

sub get_file_as_string {

    my ($filename) = @_;

    local $/;    # put PERL into slurp mode

    open(FILE, "< $filename")
        or die("[" . caller() . "] Can't open file for reading: $filename\n");

    # suggested by Damian Conway's Best Practices
    my $filecontents = do { local $/; <FILE>; };    # slurp int entire file

    close(FILE);

    return $filecontents;

}

###############################################################################
#
# write_file - write a file
#
###############################################################################

sub write_file {

    my ($filename, $string) = @_;

    open(FILE, "> $filename")
        or die("[" . caller() . "] Can't open file for writing: $filename\n");

    print FILE $string;

    close(FILE);

}

###############################################################################
#
# get_file_as_lines - grab a file as an array of lines
#
###############################################################################

sub get_file_as_lines {

    my ($filename) = @_;

    open(FILE, "< $filename")
        or die("[" . caller() . "] Can't open file for reading: $filename\n)");

    my @lines = <FILE>;    # slurp int entire file

    close(FILE);

    return @lines;

}

###############################################################################
#
# write_lines_as_file - write an array of lines to a file
#
###############################################################################

sub write_lines_as_file {

    my ($filename, @lines) = @_;

    open(FILE, "> $filename")
        or die("[" . caller() . "] Can't open file for writing: $filename\n)");

    foreach my $line (@lines) {

        if ($line !~ m/\n$/) {
            $line .= "\n";
        }

        print FILE $line;

    }

    close(FILE);

}

###############################################################################
#
# get_suffix - return the suffix of this filename
#
###############################################################################

sub get_suffix {

    my ($filename) = @_;

    # strip trailing whitespace
    $filename =~ s/\s+$//;

    # grab the suffix
    $filename =~ m/.*\.(.*)$/;

    return $1;

}

###############################################################################
#
# get_path - return the path portion of the filename
#
###############################################################################

sub get_path {

    my ($filename) = @_;

    my ($volume, $directories, $file) = File::Spec->splitpath($filename);

    my $path = File::Spec->catpath($volume, $directories);

    return $path;

}

###############################################################################
#
# slurp - synonym for get_file_as_string
#
###############################################################################

sub slurp {

    my ($filename) = @_;

    return get_file_as_string($filename);

}

###############################################################################
#
# get_cwd - return the current working directory
#
###############################################################################

sub get_cwd {

    return getcwd();

}

###############################################################################
#
# get_last_lines - return the n last lines from a file
#
###############################################################################

sub get_last_lines {

    my ($filename, $n) = @_;

    # set default number of lines
    $n ||= 10;

    ###TODO### could be rewriten to only hold $n lines at one time

    my @lines = get_file_as_lines($filename);

    return split(@lines, -$n, $n);

}

1;


__END__

=head1 NAME

Goo::FileUtilities - General file handling utilities

=head1 SYNOPSIS

use Goo::FileUtilities;

=head1 DESCRIPTION

File utility functions.

=head1 METHODS

=over

=item get_mtime

get file modification time

=item get_file_hash

return a hash of files and their contents

=item get_short_file_list

return a list of filenames in a directory

=item get_file_list

return a list of file based on a directory glob

=item get_file_as_string_ref

return a string_ref to the contents of a file

=item get_file_as_string

return the file contents as a string

=item write_file

write a file

=item get_file_as_lines

return the file contents as an array of lines

=item write_lines_as_file

write an array of lines to a file

=item get_suffix

return the suffix of this filename

=item get_path

return the path portion of the filename

=item slurp

Perl6 synonym for get_file_as_string

=item get_cwd

return the current working directory

=item get_last_lines

return the last n lines from a file

=back

=head1 AUTHOR

Nigel Hamilton <nigel@trexy.com>

=head1 SEE ALSO

