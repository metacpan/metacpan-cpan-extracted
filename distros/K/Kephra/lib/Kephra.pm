#!usr/bin/perl
use v5.12;
use warnings;
use Wx;
use Kephra::App::Window;
use Kephra::Config;

package Kephra;

our $VERSION = '0.406';
our $NAME = 'Kephra';
our $STAGE = 'less';

use base qw(Wx::App);

sub OnInit {
    my $app  = shift;
    my $config = $app->{'config'} = Kephra::Config->new();
    my $window = $app->{'window'} = Kephra::App::Window->new( $app );
    $window->Center();
    $window->Show(1);
    $app->SetTopWindow( $window );
    1;
}

sub close  { $_[0]->{'window'}->Close() }

sub OnExit {
    my $app = shift;
    Wx::wxTheClipboard->Flush;
    $app->{'config'}->write;
    # $app->{'window'}->Destroy;
    1;
}

1;

__END__

=pod

=head1 NAME

Kephra - compact, effective and inventive coding editor

=head1 SYNOPSIS

    kephra [file_name]

Small single file editor for perl with max editing comfort.

=head1 DESCRIPTION

Kephra is an editor from and for programmers, currently at start of rewrite.
This page gives you a summary how to use it.

=for HTML <p>
<img src="https://raw.githubusercontent.com/lichtkind/Kephra/master/dev/img/sed.png"  alt="point chart"   width="300" height="225">
</p>

The following is a rundown of the main functions sorted by main menu from left
to right. Not mentioned there is:

Holding Ctrl allows you no navigate with left and right as expected word
wise, up and down block wise and page up and page down subroutine wise.
If the cursor is next to round a brace character you will navigate the its
partner.

Bracing characters (including '' and "") are always created in pairs and
will embrace the selection.

=head2 File

C<New> (Ctrl+N), C<Open> (Ctrl+O), C<Reload> (Ctrl+Shift+O) (reopen same file),
C<Save> (Ctrl+S), C<Save As ..> (Ctrl+Shift+S) (save under different file name),
C<Save Under ..> (Alt+Shift+S) (save current document state under (given in dialog)
file name, but keep association with old file name),
C<Quit> (close Kephra) (Ctrl+Q), C<No Ask Quit> (disregard unsaved files) (Ctrl+Shift+Q)

=head2 Edit

Basic editing as expected: C<undo> (Ctrl+Z), redo (Ctrl+Y), if you add I<Shift>
here, you will go several undo steps at once. I<Alt> instead of I<Ctrl> moves
you to start or end of the undo chain.

Core functions: C<cut> (Ctrl+X) removes the selected text or the current line
(if nothing is selected) and copies it into the clipboard.
Same is true for C<copy> (Ctrl+C), which only copies without removing anything.
C<Paste> (Ctrl+V) inserts the copied text on the position of the caret (cursor).
C<Swap> (Ctrl+Shift+V) streamlines the copy and paste process a bit by replacing
the selection with the old clipboard content, while copying the selection or current line.
C<Delete> (Del) only removes the selection or character on the caret position.
C<Duplicate> (Ctrl+D) copies and paste's the selected text or current line,
without affecting the clipboard.

More advanced is (Ctrl+A), which C<grows selection> from word to expression to line,
block, sub until all is selected and C<shrink selection> is just the opposite (Ctrl+Shift+A).

=head2 Format

Holding Alt moves the selected or current line up or down. Left and right
indent and dedents char wise in this mode. Normal indent/dedent listens
to Tab and Shift+Tab.

Ctrl+K toggles comment status of current or selected lines (commented
becomes uncommented and vice versa). Ctrl+Shift+K does the same, but with
one difference. Ladder are the normal perl comments you might know
(called line comments). The first option adds another letter after the
pound symbol so that such (block) comments stay commented, even after
come actions with Ctrl+Shift+K.

=head2 Search and Replace

Kephra provides all the usual search and replace functions you expect.
We made sure all is accessable via menu, searchbar and keyboard.
The searchbar expands to replacebar via Strg+Shift+F or the I<'='> button.
There you can only search for the replace term and refert the current.
Available options are: case sensitiv, words only, word starts, Regex, Wrap.

F3 skips to next search term (selection by default) findings, F2 to next
marker. Adding shift searhes in reverse order (to previous finding).
Alt+F3 replaces selection with replace term and goes to next finding.
Adding Shift again reverses order. Ctrl+F takes selection as search term
and enters the search bar. Adding Shift takes the selection as replace
term and enters the input field for the replace term where you can easily
navigate the findings of search (up and down) and replace term (Alt+up/down)
and change it in both directions with (Alt+)Enter.

Ctrl+E jumps to position of last edit. If already there, the second last
edit will be destination.

=head2 Document

If C<Soft Tabs> is activated, the Tab key will insert a number of space cahracters.
The C<Indention Size> sets how many character this will be or how much visual space
a tab character will take (also tab character will become visible when "whitespace"
option in the I<View> menu is set on).
If C<Line Ending> defines which character will be inserted by pressing (Enter).
Next submenu helps you to set the encoding (currently only ASCII and UTF-8).
At last position is the language of the syntax highlighter.

=head2 View

Here are items which can be turned on (visible) or off (invisible) lie white
space character, end of line (EOL) marker, indent guides and the right margin,
a vertical line marging the historical 80 character limit. Next are toggle
options for the two types of margin on the left border of the editing widget:
line number and margin for markers (special text position you can jump to).
Further down are options to zoom text or break it on the right border of visibility.
(F11) toggles full screen mode.

=head1 PLAN

Development is done is stages which are focused on different feature sets.
Wer are in stage one called B<sed>, where its all about basic editing
with comfort and effectiveness Next stage will be called B<med> and will
be about having open several docs. Because I<Kephra> is mainly released
now on CPAN we will go on with versioning and choose 0.401 instead of 0.01.

For more please check the TODO file.

=head1 AUTHOR

Herbert Breunung (lichtkind@cpan.org)

=head1 COPYRIGHT

Copyright(c) 2022 by Herbert Breunung

All rights reserved.  This program is free software; you can
redistribute it and/or modify it under the GPL version 3.

=cut
