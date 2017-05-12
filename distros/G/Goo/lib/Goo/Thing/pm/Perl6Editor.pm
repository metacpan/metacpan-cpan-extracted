package Goo::Thing::pm::Perl6Editor;

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2005
# All Rights Reserved
#
# Author:       Nigel Hamilton
# Filename:     Goo::Thing::pm::Perl6Editor.pm
# Description:  Edit a program interactively as fast as possible
#
# Date          Change
# -----------------------------------------------------------------------------
# 15/02/2005    Auto generated file
# 15/02/2005    Wanted to boost my code-cutting productivity and accuracy
#               Other things to add - renaming methods automatically changes
#               tests and 'link backs' from other modules
# 16/02/2005    Added deleteMethod method - this is a bit of a mind bend!
# 05/05/2005    Added a TypeLessTranslator to make typing quicker - think
#               phone txt 4 code! The idea is write shrt read looonger.
# 01/07/2005    Integrated new model of "Things"
# 01/08/2005    New command-based system caused massive refactoring of this
#               module. It used a whopping 16 other modules - crazy!
# 07/08/2005    Want to add ThereDocs back into the mix
# 17/08/2005    Added method: doTypeLessTranslation
# 17/08/2005    Added method: doThereDoc
# 02/11/2005    Now returns to the location of the original ThereDoc
#               Handles all actions a Thing can do: e > >  p > >  l > >
# 03/11/2005    Preparing for CPAN alpha release
#
###############################################################################

use strict;

use Data::Dumper;

# top level utility functions
use Goo::Differ;
use Goo::Object;
use Goo::Prompter;
use Goo::TextEditor;
use Goo::FileUtilities;

# thing specific modules
use Goo::ThereDocManager;
use Goo::Thing::pm::ExecDocManager;
use Goo::Thing::pm::PerlTidyManager;
use Goo::Thing::pm::TypeLessTranslator;

use base qw(Goo::Object);


###############################################################################
#
# run - edit a program
#
###############################################################################

sub run {

    my ($this, $thing, $line_number) = @_;

    # continuously edit if they use ThereDocs
    while (1) {

        #my @old_file = FileUtilities::getFileAsLines($thing->get_full_path());

        # clear the page
        Goo::Prompter::clear();

        # can we write to this Thing?
        unless (-W $thing->get_full_path()) {

            # just view the file then
            Goo::TextEditor::view($thing->get_full_path(), $line_number);
            last;

        }

        # edit the file
        Goo::TextEditor::edit($thing->get_full_path(), $line_number);

        # process any ThereDocs
        my ($theredoc_line_number, $target_thing, $target_action, $target_line_number) =
            Goo::ThereDocManager->new()->process($thing);

        # jump out - no other action to take
        unless ($target_thing) {

            # ok ... let's tidy this up
            # this does mean some modules may not be tidied
            # if a user exited at a different location
			# does perl tidy work on perl6?
            Goo::Thing::pm::PerlTidyManager::process($thing->get_full_path());
            last;
        }

        Goo::Prompter::notify("Looking for target thing " . Dumper($target_thing));

        # carry out the action
        Goo::Prompter::notify("$target_thing->do_action($target_action, $target_line_number);");
        $target_thing->do_action($target_action, $target_line_number);

        # return to the editor from where we came >>
        $line_number = $theredoc_line_number;

    }


    # does it contain any "execdocs"?
    # ExecDocManager::process($thing);
    #my @new_file = FileUtilities::getFileAsLines($thing->get_full_path());
    #my $diff = Differ->new();
    # take the diff
    #$diff->diff(\@old_file, \@new_file);
    # check for TypeLessTranslation
    #foreach my $line_number ($diff->get_line_numbers()) {
    # change array in place
    #    $new_file[ $line_number - 1 ] =
    #        TypeLessTranslator::translateLine($diff->get_line($line_number));
    #
    #}
    # save the file
    #FileUtilities::writeLinesAsFile($thing->get_full_path(), @new_file);


}

1;


__END__

=head1 NAME

Goo::Thing::pm::Perl6Editor - Not implemented yet.

=head1 SYNOPSIS

use Goo::Thing::pm::Perl6Editor;

=head1 DESCRIPTION



=head1 METHODS

=over

=item run

edit a Perl6 program


=back

=head1 AUTHOR

Nigel Hamilton <nigel@trexy.com>

=head1 SEE ALSO

