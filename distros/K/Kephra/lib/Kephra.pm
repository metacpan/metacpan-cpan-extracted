#!usr/bin/perl
use v5.12;
use warnings;
use Wx;
use Kephra::App::Window;

package Kephra;

our $VERSION = '0.403';
our $NAME = 'Kephra';
our $STAGE = 'sed';

use base qw(Wx::App);

sub OnInit {
    my $app  = shift;
    my $window = $app->{'win'} = Kephra::App::Window->new();
    $window->Center();
    $window->Show(1);
    $app->SetTopWindow( $window );
    1;
}
    
sub close  { $_[0]->{'frame'}->Close() }

sub OnExit {
    my $app = shift;
    Wx::wxTheClipboard->Flush;
    # $app->{'win'}->Destroy;
    1;
}

1;

__END__

=pod

=head1 NAME

Kephra - compact, effective and beautiful coding editor

=head1 SYNOPSIS 

    kephra [file_name]

Small single file editor for perl with max editing comfort.

=head1 DESCRIPTION

Kephra is an editor from and for programmers, currently at start of rewrite.
This page gives you a summary how to use it. 

=for HTML <p>
<img src="https://raw.githubusercontent.com/lichtkind/Kephra/master/dev/img/sed.png"  alt="point chart"   width="300" height="225">
</p>

=head2 File IO

Currently just the basics: ASCII and UTF-8 coding. Open, reload, save and
saving under different file name. See the menu for key kombos.

=head2 Editing 

Basic editing as expected: undo redo, cut copy paste delete. 
When nothing is selected Ctrl+C copies current line.

Slightly more advanced is swapping selection and clipboard (Ctrl+Shift+V)
and duplicate current line or selection with Ctrl+D. Ctrl+A grows selection
from word to expression to line, block, sub until all is selected and
shrink selection is just the opposite (Ctrl+Shift+A).

Holding Ctrl allows you no navigate with left and right as expected word
wise, up and down block wise and page up and page down subroutine wise.
If the cursor is next to round a brace character you will navigate the its
partner.

Holding Alt moves the selected or current line up or down. Left and right
indent and dedents char wise in this mode. Normal indent/dedent listens
to Tab and Shift+Tab.

Ctrl+K toggles comment status of current or selected lines (commented 
becomes uncommented and vice versa). Ctrl+Shift+K does the same, but with
one difference. Ladder are the normal perl comments you might know
(called line comments). The first option adds another letter after the
pound symbol so that such (block) comments stay commented, even after
come actions with Ctrl+Shift+K.

Bracing characters (including '' and "") are always created in pairs and
will embrace the selection.

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

Ctrl+E jumps to position of last edit.

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
