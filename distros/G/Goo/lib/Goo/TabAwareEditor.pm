package TabAwareEditor;

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2005
# All Rights Reserved
#
# Author:       Nigel Hamilton
# Filename:     TabAwareEditor.pm
# Description:  Use the TabConverter to fix characters
#
# Date          Change
# -----------------------------------------------------------------------------
# 01/10/2005    Auto generated file
# 01/10/2005    Wanted to apply this to Javascript files
# 01/10/2005    Added method: run
# 15/10/2005    Created test file: TabAwareEditorTest.tpm
#
###############################################################################

use strict;

use Goo::Object;
use Goo::TextEditor;
use Goo::TabConverter;
use Goo::ThereDocManager;


use base qw(Goo::Object);


###############################################################################
#
# run - edit a file
#
###############################################################################

sub run {

    my ($this, $thing, $line_number) = @_;

    while (1) {

        # edit text
        Goo::TextEditor::edit($thing->get_full_path(), $line_number);

        my $new_lines;

        foreach my $line (Goo::FileUtilities::getFileAsLines($thing->get_full_path())) {

            $new_lines .= Goo::TabConverter::tabs_to_spaces($line);

        }

        # write tab-adjusted file
        Goo::FileUtilities::writeFile($thing->get_full_path(), $new_lines);

        my ($theredoc_line_number, $target_thing, $target_action) =
            Goo::ThereDocManager->new()->process($thing->get_full_path());

        # Prompter::notify("------------ $theredoc_line_number, $target_thing, $target_action");

        last unless ($target_thing);

        # switch to this Thing
        $target_thing->do_action($target_action);

        # return to the originating line
        $line_number = $theredoc_line_number;

    }


}

1;


__END__

=head1 NAME

TabAwareEditor - Use the TabConverter to fix characters

=head1 SYNOPSIS

use TabAwareEditor;

=head1 DESCRIPTION

Wrap an external editor like vi or nano. Replace tab characters with four space characters as 
per Damian Conway's "Perl Best Practices".

=head1 METHODS

=over

=item run

call an external editor. Replace tabs with four spaces.

=back

=head1 AUTHOR

Nigel Hamilton <nigel@trexy.com>

=head1 SEE ALSO

