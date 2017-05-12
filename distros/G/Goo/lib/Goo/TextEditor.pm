package Goo::TextEditor;

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2005
# All Rights Reserved
#
# Author:       Nigel Hamilton
# Filename:     Goo::TextEditor.pm
# Description:  Run Nano, or your favourite editor
#
# Date          Change
# -----------------------------------------------------------------------------
# 26/06/2005    Auto generated file
# 26/06/2005    Needed to abstract this into one place
# 15/10/2005    Create a hard symlink to: ln /home/search/dev/nanorc ~/.nanorc
#               for consist syntax highlighting on different machines
# 08/11/2005    Added method: editString
#
###############################################################################

use strict;

use Goo::Environment;
use Goo::FileUtilities;

my $editor_preference = { nigel => "/usr/bin/nano",
                          sven  => "/bin/vi"
                        };

my $viewer_preference = { nigel => "/usr/bin/nano -v" };


my $default_editor = "/usr/bin/nano";
my $default_viewer = "/usr/bin/nano -v";


###############################################################################
#
# edit - edit a file and save the results
#
###############################################################################

sub edit {

    my ($filename, $line_number) = @_;

    $line_number = $line_number || 1;

    my $programmer = Goo::Environment::get_user();

    # look up the editor for this programmer
    my $EDITOR = $editor_preference->{$programmer} || $default_editor;

    # edit it with your favourite editor - nano / emacs / vi
    system("$EDITOR +$line_number $filename");

}


###############################################################################
#
# view - just view a file
#
###############################################################################

sub view {

    my ($filename, $line_number) = @_;

    $line_number = $line_number || 1;

    my $programmer = Goo::Environment::get_user();

    # look up the editor for this programmer
    my $VIEWER = $viewer_preference->{$programmer} || $default_viewer;

    # edit it with your favourite editor - nano / emacs / vi
    system("$VIEWER +$line_number $filename");

}


###############################################################################
#
# edit_string - edit a string in a text_editor
#
###############################################################################

sub edit_string {

    my ($string) = @_;

    my $rand = rand(1000);

    # create a filename
    my $temp_filename = "/tmp/" . $rand . "-" . $$ . ".tmp";

    # write database value to a file
    Goo::FileUtilities::write_file($temp_filename, $string);

    # edit the value
    edit($temp_filename);

    # slurp the file back into RAM
    my $edited_string = Goo::FileUtilities::slurp($temp_filename);

    unlink($temp_filename);

    return $edited_string;

}

1;


__END__

=head1 NAME

Goo::TextEditor - Run Nano, or your favourite editor

=head1 SYNOPSIS

use Goo::TextEditor;

=head1 DESCRIPTION

Edit a file with your favourite external text editor (e.g., vi, vim, nano etc.).

=head1 METHODS

=over

=item edit

edit a file and save the results

=item view

just view a file

=item edit_string

edit a string inside a text_editor

=back

=head1 AUTHOR

Nigel Hamilton <nigel@trexy.com>

=head1 SEE ALSO

