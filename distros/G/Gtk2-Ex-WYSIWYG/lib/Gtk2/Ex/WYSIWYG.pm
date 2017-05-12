package Gtk2::Ex::WYSIWYG;

use strict;
use Gtk2;
use Gtk2::Pango;
use Glib::Object::Subclass
  Gtk2::Table::,
  signals => {},
  properties => [Glib::ParamSpec->uint('undo_stack',
                                       'Undo Stack Size',
                                       ('The maximum size of the undo '.
                                        'stack. Zero implies no limit'),
                                       0, ~0, 0,
                                       [qw/readable writable/]),
                 Glib::ParamSpec->boolean('flat_toolbar',
                                          'Flat Toolbar',
                                          ('Whether the toolbar should be '.
                                           'flat (true) or double-height '.
                                           '(false)'),
                                          0, [qw/readable writable/]),
                 Glib::ParamSpec->boolean('debug',
                                          'Show Debug Button',
                                          ('Show or hide the Debug button'),
                                          0, [qw/readable writable/]),
                 Glib::ParamSpec->boolean('map-fill-to-left',
                                          'Map fill justification to left',
                                          ('Map the fill justification tag '.
                                           'to the left justification tag '.
                                           'for older version of Gtk2 that '.
                                           'don\'t support it'),
                                          0, [qw/readable writable/]),
                 Glib::ParamSpec->boolean('check-spelling',
                                          'Check spelling',
                                          ('Use Gtk2::Spell to allow spell '.
                                           'checking. You must have '.
                                           'Gtk2::Spell installed!'),
                                          0, [qw/readable writable/])];

use constant UNDO_REMOVE_TAG  => 0;
use constant UNDO_APPLY_TAG   => 1;
use constant UNDO_INSERT_TEXT => 2;
use constant UNDO_DELETE_TEXT => 3;

=head1 NAME

Gtk2::Ex::WYSIWYG - A WYSIWYG editor ready to drop into a GUI.

=head1 VERSION

Version 0.02

=cut

our $VERSION = 0.02;

=head1 DESCRIPTION

This module is a subclass of L<Gtk2::Table> containing both a text view
and a 'toolbar' to allow a user to edit and format text. It can serialise
to a plain text block and a tag stack, or to incomplete HTML (the output is
not a complete HTML document, but can be included inside one). It can also
'deserialise' from this same data to easily allow content from one WYSIWYG to
be transfered to another - the more efficient of these is the text/tag stack,
however the HTML form can be more easily stored.

An undo/redo stack is also included, as well as a modification to the text
view's popup menu to allow the user to set the wrap mode with ease.

It should be noted that WYSIWYG emulates paragraphs by using \n\s*\n as a
paragraph separator. The leading newline in the sequence will belong to the
leading paragraph, and the rest to 'interparagraph space'. This has some
implications - interparagraph space honours vertical space (ie, extra newlines
will be rendered when exporting to HTML) but not horizontal space - any spaces
you put inside interparagraph space will be ignored, as will any font
formatting you apply.

It also means that should two paragraphs be joined by a user edit (either by
inserting non-whitespace or by deleteing whitespace) any paragraph-level
formatting applied to the paragraph that used to be before the interparagraph
space will be applied to any affected paragraphs after it.

See the TAGS section below for supported tags.

There are currently three 'sub-packages' contained within Gtk2::Ex::WYSIWYG as
well - Gtk2::Ex::WYSIWYG::HTML (for parsing and generating HTML from the view),
Gtk2::Ex::WYSIWYG::FormatMenu (a Gtk2::ComboBox replacement that shows
formatting in the option menu but not in the main widget) and
Gtk2::Ex::WYSIWYG::SizeMenu (a beefed up Gtk2::ComboBoxEntry with a few extra
features, specifically designed for the font size setting).

=head1 HIERARCHY

  Glib::Object
  +----Glib::InitiallyUnowned
       +----Gtk2::Object
            +----Gtk2::Widget
                 +----Gtk2::Container
                      +----Gtk2::Table
                           +---Gtk2::Ex::WYSIWYG

=head1 METHODS

=cut

#' emacs formatting....

my %TAGS;    # Tag definitions. See end of file for BEGIN filler
my %BUTTONS; # Button definitions. See end of file for BEGIN filler

# 'Public' methods

=head2 Gtk2::Ex::WYSIWYG->new()

Returns a new WYSIWYG instance. There are a few properties you can set, see
the PROPERTIES section below.

=cut

sub INIT_INSTANCE {
  my $self = shift;
  $self->_init_tooltips;
  $self->_init_font_list if not defined $BUTTONS{Font}{Tags};
  $self->{FontSet} = 1;
  $self->{SizeSet} = 1;
  $self->{Active} = {};
  $self->{UndoStack} = [];
  $self->{RedoStack} = [];
  $self->{Record} = undef;
  $self->_build_buttons;
  $self->_build_toolbar;
  $self->_build_text;
  $self->_set_buttons_from_active;
  $self->signal_connect(visibility_notify_event =>
                        sub {$self->_on_visibility_notify});
}

=head2 $wysiwyg->clear_undo()

Empties the undo and redo stacks.

=cut

sub clear_undo {
  my $self = shift;
  $self->{UndoStack} = [];
  $self->{Record} = undef;
  $self->_set_buttons_from_active;
}

=head2 $wysiwyg->undo()

Performs a single undo action. Does nothing if there is nothing to undo.
Undo actions are user-action based, so if a user made a change that actually
made multiple changes to the content, all those changes will be reversed at
once.

=cut

sub undo {
  my $self = shift;
  return if not scalar(@{$self->{UndoStack}});
  ++$self->{Undoing};
  my $undo = pop(@{$self->{UndoStack}});
  my $buf = $self->{Text}->get_buffer;
  for my $step (reverse(@$undo)) {
    my ($type, $from, $to, @args) = @$step;
    if ($type == UNDO_INSERT_TEXT) {
      # Remove text from $from to $to
      $buf->delete($buf->get_iter_at_offset($from),
                   $buf->get_iter_at_offset($to));
    } elsif ($type == UNDO_DELETE_TEXT) {
      # Reinsert text at $from
      $buf->insert($buf->get_iter_at_offset($from), $args[0]);
    } elsif ($type == UNDO_APPLY_TAG) {
      $buf->remove_tag($args[0], $buf->get_iter_at_offset($from),
                       $buf->get_iter_at_offset($to));
    } elsif ($type == UNDO_REMOVE_TAG) {
      $buf->apply_tag($args[0], $buf->get_iter_at_offset($from),
                      $buf->get_iter_at_offset($to));
    }
  }
  push @{$self->{RedoStack}}, $undo;
  --$self->{Undoing};
  $self->_set_active_from_text;
  $self->_set_buttons_from_active;
  return 0;
}

=head2 $wysiwyg->redo()

Performs a single redo action. Does nothing if there is nothing to redo.
Undo actions are user-action based, so if a user made a change that actually
made multiple changes to the content, all those changes will be reapplied at
once.

=cut

sub redo {
  my $self = shift;
  return if not scalar(@{$self->{RedoStack}});
  ++$self->{Undoing};
  my $redo = pop(@{$self->{RedoStack}});
  my $buf = $self->{Text}->get_buffer;
  for my $step (@$redo) {
    my ($type, $from, $to, @args) = @$step;
    if ($type == UNDO_INSERT_TEXT) {
      $buf->insert($buf->get_iter_at_offset($from), $args[0]);
    } elsif ($type == UNDO_DELETE_TEXT) {
      $buf->delete($buf->get_iter_at_offset($from),
                   $buf->get_iter_at_offset($to));
    } elsif ($type == UNDO_APPLY_TAG) {
      $buf->apply_tag($args[0], $buf->get_iter_at_offset($from),
                       $buf->get_iter_at_offset($to));
    } elsif ($type == UNDO_REMOVE_TAG) {
      $buf->remove_tag($args[0], $buf->get_iter_at_offset($from),
                      $buf->get_iter_at_offset($to));
    }
  }
  push @{$self->{UndoStack}}, $redo;
  --$self->{Undoing};
  $self->_set_active_from_text;
  $self->_set_buttons_from_active;
  return 0;
}

=head2 $textview = $wysiwyg->get_text()

Returns the Gtk2::TextView widget that forms the main body of the WYSIWYG
mega-widget. Please be careful with it - making direct modifications may
seriously confuse the serialisation/deserialisation methods.

=cut

sub get_text { $_[0]->{Text} }

=head2 $textbuffer = $wysiwyg->get_buffer()

Returns the Gtk2::TextBuffer widget within the WYSIWYG mega-widget. Toy with
this at your peril.

=cut

sub get_buffer { $_[0]->{Text}->get_buffer }

=head2 ($text, @tags) = $wysiwyg->serialise()

The more efficient of the (currently) two serialisation methods, serialise
will return both the raw text and a sequence of tags that when applied to the
text will render the original look.

Tags are hashrefs with keys of 'Start' (the index to start applying the tag),
'End' (the index to stop applying the tag) and 'Tags' (a hashref of key value
pairs containing the actual tag information). They are ordered by the Start
key, and they do NOT overlap (ie, one tag's range is never inside the range of
another tag).

Tags include more than just the tags applied by the user - three other tags are
also added (and take precedence over user tags) - a 'br' tag (for
intra-paragraph newlines), a 'p' tag (to specify interparagraph space) and
a 'ws' tag (to tag multiple-character whitespace strings). These are mainly
used for conversion to HTML.

=cut

#' emacs formatting

sub serialise {
  my $self = shift;
  my @user = $self->_get_user_tags;
  my $buf = $self->{Text}->get_buffer;
  return ($buf->get_text($buf->get_bounds, 0), @user);
}

=head2 $wysiwyg->deserialise($txt, @tags)

The inverse of serialise. Note that this also clears the undo and redo stacks.

=cut

sub deserialise {
  my $self = shift;
  my ($txt, @tags) = @_;
  # This wipes undo!
  $self->{UndoStack} = [];
  $self->{RedoStack} = [];
  $self->{Record} = undef;
  ++$self->{Undoing};
  my $buf = $self->{Text}->get_buffer;
  {
    my @rem;
    my $tt = $buf->get_tag_table;
    # Remove all of my tags?
    $tt->foreach(sub {
                   push @rem, $_[0] if $self->_is_my_tag($_[0])
                 });
    for my $rem (@rem) {
      $tt->remove($rem);
    }
    $self->{LinkID} = 0;
  }
  $buf->delete($buf->get_bounds);
  $buf->insert($buf->get_start_iter, $txt);
  $txt = undef;
  for my $tag (@tags) {
    # Start, End and Tags (name => val?)
    my $s = $buf->get_iter_at_offset($tag->{Start});
    my $e = $buf->get_iter_at_offset($tag->{End});
    my $size = 10;
    $size = $tag->{Tags}{size} if exists $tag->{Tags}{size};
    my $hscale = 1;
    for my $tname (keys %{$tag->{Tags}}) {
      next if $tname !~ /^h[1-5]\z/;
      $hscale = $TAGS{$tname}{Look}{scale};
      last;
    }
    $hscale = 1 if not $hscale;
    for my $tname (keys %{$tag->{Tags}}) {
      my $val = $tag->{Tags}{$tname};
      my $t;
      if ($tname eq 'link') {
        $t = $self->_create_link($val);
      } elsif ($tname eq 'font') {
        $t = $self->_create_tag($self->_full_tag_name('font', $val->[0]),
                                family => $val->[0]);
      } elsif ($tname eq 'size') {
        $t = $self->_create_tag($self->_full_tag_name('size', $val->[0]),
                                size => $val->[0] * 1024);
      } elsif ($tname eq 'superscript' or $tname eq 'subscript') {
        my ($sz, $sc) = ($size, $hscale);
        if (defined($val)) {
          $sz = $val->[0] if defined($val->[0]);
          $sc = $val->[1] if defined($val->[1]);
        }
        $t = $self->_create_sub_super_tag($tname, $sz, $sc);
      } elsif ($tname eq 'indent') {
        $t = $self->_create_tag($self->_full_tag_name('indent', $val->[0]),
                                'left-margin' => 32 * ($val->[0] + 1));
      } elsif (not defined $val and
               exists $TAGS{$tname} and exists $TAGS{$tname}{Look}) {
        $t = $self->_create_tag($self->_full_tag_name($tname),
                                %{$TAGS{$tname}{Look}});
      }
      $self->_apply_tag($t, $s, $e) if defined $t;
    }
  }
  --$self->{Undoing};
  $self->_set_active_from_text;
  $self->_set_buttons_from_active;
}

=head2 $text = $wysiwyg->get_html()

Outputs the contents of the WYSIWYG as HTML. This can also be used as a less
efficient but more storable serialisation method as the WYSIWYG can re-parse
the output HTML and display it.

Note that the output HTML is incomplete - only the formatting markup is
included, but it would be trivial to wrap the appropriate tags around it.

Font sizes are a little tricky, so WYSIWYG converts sizes to em values
(assuming size 16 is 1 em).

Remember that as-is tags are not 'html-cleaned' (that's the point - so you can
insert HTML tags that WYSIWYG itself doesn't support), so be careful!

=cut

sub get_html {
  my $self = shift;
  my @user = $self->_get_user_tags;
  my @auto = $self->_get_auto_tags;
  my @tags = $self->_merge_tags(\@user, \@auto);
  my $buf = $self->{Text}->get_buffer;
  return Gtk2::Ex::WYSIWYG::HTML->generate($buf, @tags);
}

=head2 $wysiwyg->set_html($text)

The inverse of get_html, this takes HTML text and attempts to parse it back
into the WYSIWYG.

While this is primarily designed to take text created with get_html, it can
handle being given arbitrary HTML. Any HTML tags it doesn't understand it
will insert tagged as 'as-is', so that a later call to get_html should
return something very similar to what was given to set_html.

=cut

#'emacs formatting

sub set_html {
  my $self = shift;
  my ($html) = @_;
  # This wipes undo!
  $self->{UndoStack} = [];
  $self->{RedoStack} = [];
  $self->{Record} = undef;
  ++$self->{Undoing};
  my ($txt, @tags) = Gtk2::Ex::WYSIWYG::HTML->parse($html);
  --$self->{Undoing};
  $self->deserialise($txt, @tags);
}

=head2 $wysiwyg->debug()

This function is what is called by the special 'debug' button (which appears
if you set the debug property to true). By default it simply prints
"DEBUG\n" to the screen, but you can override it to do whatever you like.

Two examples are included in the function - the first tests the serialisation
by serialising the current text and then deserialising that data back into the
WYSIWYG, and the second does the same but for the HTML serialisation.

=cut

#'emacs formatting

sub debug {
  my $self = shift;
  print "DEBUG!\n";
  # Check serialisation
  #  $self->deserialise($self->serialise);

  # Check serialisation via html
  #  $self->set_html($self->get_html);
  return 0;
}

# That's it for 'public' methods.

=head1 PROPERTIES

=head2 'undo-stack' (Glib::UInt : readable / writable)

The number of items allowed on the undo and redo stacks. A value of zero
indicates no limit, which is the default.

=head2 'check-spelling' (Glib::Boolean : readable/writable)

If this is turned on (and you have Gtk2::Spell installed), WYSIWYG will attach
a Gtk2::Spell instance to its text view.

=head2 'flat-toolbar' (Glib::Boolean : readable/writable)

The tool bar can be rendered either as 'fat' (two lines of buttons with named
groups) or 'flat' (one line of buttons). If flat-toolbar is set to true the
latter will be used, otherwise the former will be. The change will be mirrored
in the widget immediately. The default toolbar is the 'fat' version.

=head2 'map-fill-to-left' (Glib::Boolean : readable/writable)

Old versions of Gtk2 don't support the fill justification method, and will
complain loudly if you try to use it. If you're using such a version, set
this property to true to make WYSIWYG use the left justification tag instead.

This won't affect how the WYSIWYG outputs justification data - just how it
displays it.

=head2 'debug' (Glib::Boolean : readable/writable)

When set to true, this activates the 'debug' button on the toolbar. This button
will trigger the WYSIWYG's debug method - you'll probably want to override that
to do something useful.

=cut

# Move properties into their own parent key
sub GET_PROPERTY {
  my $self = shift;
  my ($pspec) = @_;
  return ($self->{Properties}{$pspec->get_name} || $pspec->get_default_value);
}

sub SET_PROPERTY {
  my $self = shift;
  my ($pspec, $newval) = @_;
  my $name = $pspec->get_name;
  my $old = $self->get_property($name);
  if ($name eq 'flat_toolbar' and
      $newval != $self->get_property('flat_toolbar')) {
    $self->{Properties}{flat_toolbar} = $newval;
    $self->_build_buttons; # Shouldn't be a problem if done again
    $self->_build_toolbar;
  } elsif ($name eq 'debug' and
           $newval != $self->get_property('debug')) {
    $self->{Properties}{debug} = $newval;
    if ($newval) {
      if (not defined $self->{Buttons}{DUMP}) {
        $self->{Buttons}{DUMP} = Gtk2::Button->new;
        $self->{Buttons}{DUMP}->
          set_image(Gtk2::Image->new_from_stock('gtk-dialog-warning',
                                                'button'));
        $self->{Buttons}{DUMP}->signal_connect('clicked', sub{$self->debug});
      }
      $self->_build_buttons;
      $self->_build_toolbar;
    }
  } elsif ($name eq 'map_fill_to_left' and
           $newval != $self->get_property('map-fill-to-left')) {
    $self->{Properties}{map_fill_to_left} = $newval;
    if (defined $self->{Text}) {
      my $tag = $self->{Text}->get_buffer->get_tag_table->lookup('fill');
      die("Gtk2::Ex::WYSIWYG tag naming conflict for fill - " .
          "tag name already in use!") if not $self->_is_my_tag($tag);
      $tag->set_property(justification => ($newval ? 'left' : 'fill'))
        if defined $tag and $self->_is_my_tag($tag);
    }
  } elsif ($name eq 'check_spelling' and
           $newval != $self->get_property('check-spelling')) {
    $self->{Properties}{check_spelling} = $newval;
    if ($newval) {
      eval {require Gtk2::Spell};
      if ($@) {
        warn("Gtk2::Spell does not appear to be installed!");
        return;
      }
      if (not defined $self->{GtkSpell} and defined($self->{Text})) {
        $self->{GtkSpell} = Gtk2::Spell->new_attach($self->{Text});
        $self->{GtkSpell}->recheck_all;
      }
    } elsif (defined($self->{GtkSpell})) {
      $self->{GtkSpell}->detach;
      $self->{GtkSpell} = undef;
    }
  } else {
    $self->{Properties}{$name} = $newval;
  }
}

=head1 TAGS

There are two classes of tags available in the WYSIWYG - font tags and
paragraph tags.

=head2 Font Tags

Font tags are applied to arbitrary lengths of text, and only affect those
lengths of text.

The following font tags are pre-defined:

=head3 font

=head3 size

=head3 bold

=head3 italic

=head3 underline

=head3 strikethrough

=head3 superscript

Cannot be applied to text at the same time as subscript.

=head3 subscript

Cannot be applied to text at the same time as superscript.

=head3 link

=head3 pre

Preformatted text, like the HTML tag.

=head3 asis

A special tag that allows you to enter 'code' that the WYSIWYG would otherwise
not be able to understand as formatting. All other font tags are removed from
text marked as 'as-is'.

=head2 Paragraph Tags

Paragraph tags apply to a whole paragraph, and cannot be applied to only part
of a paragraph.

The following paragraph tags are predefined:

=head3 h1

Heading 1 - cannot be used in the same paragraph as other Heading tags.

=head3 h2

Heading 2 - cannot be used in the same paragraph as other Heading tags.

=head3 h3

Heading 3 - cannot be used in the same paragraph as other Heading tags.

=head3 h4

Heading 4 - cannot be used in the same paragraph as other Heading tags.

=head3 h5

Heading 5 - cannot be used in the same paragraph as other Heading tags.

=head3 left

Left justification - cannot be used in the same paragraph as other
Justification tags.

=head3 center

Center justification - cannot be used in the same paragraph as other
Justification tags.

=head3 right

Right justification - cannot be used in the same paragraph as other
Justification tags.

=head3 fill

Fill justification - cannot be used in the same paragraph as other
Justification tags. See the 'map-fill-to-left' property for older versions of
Gtk2 that do not support fill justification properly.

=head3 indent

The size of the left margin (or the right for right justified paragraphs).

=head1 AUTHOR

Matthew Braid, C<< <perl-pkg at mdb.id.au> >>

=head1 TODO

=over 4

=item * Separate the toolbar from the text view

=item * Find some way to support bulleted/numbered lists

=back

=head1 BUGS

Please report any bugs or feature requests to C<bug-gtk2-ex-wysiwyg at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Gtk2-Ex-WYSIWYG>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Gtk2::Ex::WYSIWYG


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Gtk2-Ex-WYSIWYG>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Gtk2-Ex-WYSIWYG>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Gtk2-Ex-WYSIWYG>

=item * Search CPAN

L<http://search.cpan.org/dist/Gtk2-Ex-WYSIWYG/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Matthew Braid.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

############################################################################
# Builder functions - used to create class and instance widgets as necessary
############################################################################

#########
# Create the tooltips - both the 'standard' tooltips widget for hovering
# over buttons and a 'fake' one for hovering over links
#########
BEGIN {
  my ($TT, $TT_L); # Fake tooltips and label for same
  my $TOOLTIPS;    # 'Real' tooltips widget for buttons

  sub _init_tooltips {
    my $self = shift;
    return if defined $TOOLTIPS;
    $TOOLTIPS = Gtk2::Tooltips->new; # Class wide. Would be nice if there was a
                                     # way of determining if a tooltip widget
                                     # was already created and use that
    $TT = Gtk2::Window->new('popup'); # The 'fake' link tooltip window
    $TT_L = Gtk2::Label->new;
    $TT_L->set_padding(4, 4);
    $TT->set_resizable(0);
    $TT->set_decorated(0);
    $TT->set_position('mouse'); # We modify this on popup
    # Would be good to get the current theme colour - on ubuntu this works, but
    # using blackbox on freebsd results in a colour that is 'too yellow'
    $TT->modify_bg('normal',
                   Gtk2::Gdk::Color->new(245 << 8, 245 << 8, 181 << 8));
    my $frame = Gtk2::Frame->new;
    $frame->set_shadow_type('etched-in');
    $frame->add($TT_L);
    $TT->add($frame);
  }

  sub _tooltip_text {
    my $self = shift;
    my ($txt) = @_;
    $TT_L->set_text($txt);
  }

  sub _tooltip_show {
    my $self = shift;
    my ($x, $y) = @_;
    $TT->show_all;
    my ($thisx, $thisy) = $TT->window->get_origin;
    $TT->move($thisx + 20, $thisy + 20);
  }

  sub _tooltip_hide { $TT->hide }

  ##########
  # _build_buttons - on an instance creation, build the buttons for the toolbar
  #                  at the top. Uses the %BUTTONS and %TAGS hashes (see below)
  #                  In this begin block to access $TOOLTIPS
  ##########
  sub _build_buttons {
    my $self = shift;
    for my $bname (keys %BUTTONS) {
      return if defined($self->{Buttons}{$bname});
      if ($BUTTONS{$bname}{Type} eq 'toggle') {
        $self->{Buttons}{$bname} = Gtk2::ToggleButton->new;
        $self->{Buttons}{$bname}->set_active(1)
          if $BUTTONS{$bname}{On};
        $TOOLTIPS->set_tip($self->{Buttons}{$bname},
                           $BUTTONS{$bname}{TipText});
        if ($TAGS{$BUTTONS{$bname}{Tag}}{Multi}) {
          $self->{Buttons}{$bname}->
            signal_connect('toggled',
                           sub {$self->_on_multi_toggle_change($bname)});
        } else {
          $self->{Buttons}{$bname}->
            signal_connect('toggled', sub {$self->_on_toggle_change($bname)});
        }
      } elsif ($BUTTONS{$bname}{Type} eq 'button') {
        $self->{Buttons}{$bname} = Gtk2::Button->new;
        $TOOLTIPS->set_tip($self->{Buttons}{$bname},
                           $BUTTONS{$bname}{TipText});
        $self->{Buttons}{$bname}->
          signal_connect('clicked', sub {$self->_on_button_click($bname)});
      } elsif ($BUTTONS{$bname}{Type} eq 'menu') {
        $self->{Buttons}{$bname} = Gtk2::Ex::WYSIWYG::FormatMenu->new;
        $self->{Buttons}{$bname}->set_tool_tip($TOOLTIPS);
        $self->{Buttons}{$bname}->
          signal_connect(format_selected =>
                         sub {$self->_on_menu_change($bname, @_)});
        $self->{Buttons}{$bname}->
          set_options(map({[$_->[1], $_->[0],
                            ((exists($TAGS{$_->[0]}) and
                              exists($TAGS{$_->[0]}{Look}))
                             ? $TAGS{$_->[0]}{Look}
                             : undef)]}
                          @{$BUTTONS{$bname}{Tags}}));
        $self->{Buttons}{$bname}->set_ellipsize('end');
        $self->{Buttons}{$bname}->set_default($BUTTONS{$bname}{Default});
        $self->{Buttons}{$bname}->set_text($BUTTONS{$bname}{Default});
      } elsif ($BUTTONS{$bname}{Type} eq 'font') {
        $self->{Buttons}{$bname} = Gtk2::Ex::WYSIWYG::FormatMenu->new;
        $self->{Buttons}{$bname}->set_tool_tip($TOOLTIPS);
        $self->{Buttons}{$bname}->
          signal_connect(format_selected =>
                         sub {$self->_on_font_change($bname, @_)});
        $self->{Buttons}{$bname}->
          set_options(map({[$_, $_, {family => $_}]}
                          @{$BUTTONS{$bname}{Tags}}));
        $self->{Buttons}{$bname}->set_ellipsize('end');
        $self->{Buttons}{$bname}->set_default($BUTTONS{$bname}{Default});
        $self->{Buttons}{$bname}->set_text($BUTTONS{$bname}{Default});
      } elsif ($BUTTONS{$bname}{Type} eq 'size') {
        $self->{Buttons}{$bname} = Gtk2::Ex::WYSIWYG::SizeMenu->new;
        $self->{Buttons}{$bname}->set_value($BUTTONS{$bname}{Default});
        $self->{Buttons}{$bname}->
          signal_connect(size_selected => sub {$self->_on_size_change($bname,
                                                                      @_)});
      } else {
        next;
      }
      # Eeek! This won't work if the button has both an image and text!
      $self->{Buttons}{$bname}->
        set_image(Gtk2::Image->new_from_stock($BUTTONS{$bname}{Image},
                                              'button'))
          if exists $BUTTONS{$bname}{Image};
      $self->{Buttons}{$bname}->set_label($BUTTONS{$bname}{Label})
        if exists $BUTTONS{$bname}{Label};
      $self->{Buttons}{$bname}->set_focus_on_click(0);
    }
  }
}

sub _clear_toolbar {
  my $self = shift;
  return if not defined $self->{Toolbar};
  for my $child ($self->{Toolbar}->get_children) {
    $self->_clear_toolbar_part($child)
      if $child->isa('Gtk2::Box') or $child->isa('Gtk2::Frame');
    $self->{Toolbar}->remove($child);
  }
  $self->remove($self->{Toolbar});
}

sub _clear_toolbar_part {
  my $self = shift;
  my ($part) = @_;
  for my $child ($part->get_children) {
    if ($child->isa('Gtk2::Box') or $child->isa('Gtk2::Frame')) {
      $self->_clear_toolbar_part($child);
    }
    $part->remove($child);
  }
}

##########
# _build_toolbar - once the buttons are built, pack them into a nice format as
#                  the toolbar
##########
sub _build_toolbar {
  my $self = shift;
  $self->_clear_toolbar;
  if ($self->{Properties}{flat_toolbar}) {
    $self->_build_flat_toolbar;
  } else {
    $self->_build_fat_toolbar;
  }
}

sub _build_flat_toolbar {
  my $self = shift;
  # +--------------------------------------------------------------...
  # |+----------------------------FONT----------------------------+...
  # || FONTV SIZEV | SZ+ SZ- | B I U S sub SUP CASE | BG FG | CLR |...
  # |+------------------------------------------------------------+...
  # +--------------------------------------------------------------...

  # ...-------------------------------------+
  # ...-------------PARAGRAPH---------++---+|
  # ...I- I+ | L C R F | HEADING TYPE ||U R||
  # ...-------------------------------++---+|
  # ...-------------------------------------+
  $self->{Toolbar} = Gtk2::HBox->new(0, 0)
    if not defined $self->{Toolbar};

  # FONT BLOCK
  my $frame = Gtk2::Frame->new();
  $frame->set_shadow_type('etched-in');
  $frame->set_border_width(2);
  $self->{Toolbar}->pack_start($frame, 0, 0, 2);
  my $hb2 = Gtk2::HBox->new(0, 0);
  $frame->add($hb2);
  $self->{Buttons}{Font}->set_width_chars(16);
  $hb2->pack_start($self->{Buttons}{Font}, 1, 1, 0);
  $hb2->pack_start($self->{Buttons}{Size}, 0, 0, 0);
  $hb2->pack_start(Gtk2::VSeparator->new, 0, 0, 2);
  $hb2->pack_start($self->{Buttons}{SizeUp}, 0, 0, 0);
  $hb2->pack_start($self->{Buttons}{SizeDown}, 0, 0, 0);
  $hb2->pack_start(Gtk2::VSeparator->new, 0, 0, 2);
  $hb2->pack_start($self->{Buttons}{Bold}, 0, 0, 0);
  $hb2->pack_start($self->{Buttons}{Italic}, 0, 0, 0);
  $hb2->pack_start($self->{Buttons}{Underline}, 0, 0, 0);
  $hb2->pack_start($self->{Buttons}{Strike}, 0, 0, 0);
  $hb2->pack_start($self->{Buttons}{Sub}, 0, 0, 0);
  $hb2->pack_start($self->{Buttons}{Super}, 0, 0, 0);
#  $hb2->pack_start($self->{Buttons}{Case}, 0, 0, 0);
  $hb2->pack_start($self->{Buttons}{Link}, 0, 0, 0);
  $hb2->pack_start(Gtk2::VSeparator->new, 0, 0, 2);
#  $hb2->pack_start($self->{Buttons}{Colour}, 0, 0, 0);
#  $hb2->pack_start(Gtk2::VSeparator->new, 0, 0, 2);
  $hb2->pack_start($self->{Buttons}{Pre}, 0, 0, 0);
  $hb2->pack_start($self->{Buttons}{AsIs}, 0, 0, 0);
  $hb2->pack_start(Gtk2::VSeparator->new, 0, 0, 2);
  $hb2->pack_start($self->{Buttons}{Clear}, 0, 0, 0);

  # PARAGRAPH BLOCK
  $frame = Gtk2::Frame->new();
  $frame->set_shadow_type('etched-in');
  $frame->set_border_width(2);
  $self->{Toolbar}->pack_start($frame, 0, 0, 0);
  $hb2 = Gtk2::HBox->new(0, 2);
  $frame->add($hb2);
  $hb2->pack_start($self->{Buttons}{IndentDown}, 0, 0, 0);
  $hb2->pack_start($self->{Buttons}{IndentUp}, 0, 0, 0);
  $hb2->pack_start(Gtk2::VSeparator->new, 0, 0, 2);
  $hb2->pack_start($self->{Buttons}{Left}, 0, 0, 0);
  $hb2->pack_start($self->{Buttons}{Center}, 0, 0, 0);
  $hb2->pack_start($self->{Buttons}{Right}, 0, 0, 0);
  $hb2->pack_start($self->{Buttons}{Fill}, 0, 0, 0);
  $hb2->pack_start(Gtk2::VSeparator->new, 0, 0, 2);
  $self->{Buttons}{Heading}->set_width_chars(10);
  $hb2->pack_start($self->{Buttons}{Heading}, 1, 1, 0);

  # UNDO/REDO GROUP
  $frame = Gtk2::Frame->new;
  $frame->set_shadow_type('etched-in');
  $frame->set_border_width(2);
  $self->{Toolbar}->pack_start($frame, 0, 0, 0);
  $hb2 = Gtk2::HBox->new(0, 2);
  $frame->add($hb2);
  $hb2->pack_start($self->{Buttons}{Undo}, 0, 0, 0);
  $hb2->pack_start($self->{Buttons}{Redo}, 0, 0, 0);

  $self->{Toolbar}->pack_start($self->{Buttons}{DUMP}, 0, 0, 0)
    if $self->get_property('debug') and defined $self->{Buttons}{DUMP};
  $self->{Toolbar}->show_all;
  $self->attach($self->{Toolbar}, 0, 1, 0, 1,
                [qw(fill expand)], [qw(fill)], 0, 0);
}

sub _build_fat_toolbar {
  my $self = shift;
  #  +---------------------------------------------------+
  #  |+-------------FONT-------------++---PARAGRAPH--++-+|
  #  || FONTV  SIZEV | SZ+ SZ- | CLR ||I- I+|L C R F ||U||
  #  || B I U S sub SUP CASE | BG FG ||HEADING TYPE  ||R||
  #  |+------------------------------++--------------++-+|
  #  +---------------------------------------------------+
  $self->{Toolbar} = Gtk2::HBox->new(0, 0);

  # FONT GROUP
  my $frame = Gtk2::Frame->new('Font');
  $frame->set_label_align(0.5, 0.5);
  $frame->set_shadow_type('etched-in');
  my $lab = $frame->get_label_widget;
  $lab->set_markup('<small>Font</small>');
  $self->{Toolbar}->pack_start($frame, 0, 0, 2);
  my $vbox = Gtk2::VBox->new(0, 0);
  my $hb2 = Gtk2::HBox->new(0, 0);
  $frame->add($hb2);
  $hb2->pack_start($vbox, 0, 0, 2);
  $hb2 = Gtk2::HBox->new(0, 0);
  $self->{Buttons}{Font}->set_width_chars(0);
  $hb2->pack_start($self->{Buttons}{Font}, 1, 1, 0);
  $hb2->pack_start($self->{Buttons}{Size}, 0, 0, 0);
  $hb2->pack_start(Gtk2::VSeparator->new, 0, 0, 2);
  $hb2->pack_start($self->{Buttons}{SizeUp}, 0, 0, 0);
  $hb2->pack_start($self->{Buttons}{SizeDown}, 0, 0, 0);
  $vbox->pack_start($hb2, 0, 0, 2);
  $hb2 = Gtk2::HBox->new(0, 0);
  $hb2->pack_start($self->{Buttons}{Bold}, 0, 0, 0);
  $hb2->pack_start($self->{Buttons}{Italic}, 0, 0, 0);
  $hb2->pack_start($self->{Buttons}{Underline}, 0, 0, 0);
  $hb2->pack_start($self->{Buttons}{Strike}, 0, 0, 0);
  $hb2->pack_start($self->{Buttons}{Sub}, 0, 0, 0);
  $hb2->pack_start($self->{Buttons}{Super}, 0, 0, 0);
#  $hb2->pack_start($self->{Buttons}{Case}, 0, 0, 0);
  $hb2->pack_start($self->{Buttons}{Link}, 0, 0, 0);
  $hb2->pack_start(Gtk2::VSeparator->new, 0, 0, 2);
#  $hb2->pack_start($self->{Buttons}{Colour}, 0, 0, 0);
#  $hb2->pack_start(Gtk2::VSeparator->new, 0, 0, 2);
  $hb2->pack_start($self->{Buttons}{Pre}, 0, 0, 0);
  $hb2->pack_start($self->{Buttons}{AsIs}, 0, 0, 0);
  $hb2->pack_start(Gtk2::VSeparator->new, 0, 0, 2);
  $hb2->pack_start($self->{Buttons}{Clear}, 0, 0, 0);
  $vbox->pack_start($hb2, 0, 0, 2);

  # PARA GROUP
  $frame = Gtk2::Frame->new('Paragraph');
  $frame->set_label_align(0.5, 0.5);
  $frame->set_shadow_type('etched-in');
  $lab = $frame->get_label_widget;
  $lab->set_markup('<small>Paragraph</small>');
  $self->{Toolbar}->pack_start($frame, 0, 0, 2);
  $vbox = Gtk2::VBox->new(0, 0);
  $hb2 = Gtk2::HBox->new(0, 0);
  $frame->add($hb2);
  $hb2->pack_start($vbox, 0, 0, 2);
  $hb2 = Gtk2::HBox->new(0, 0);
  $hb2->pack_start($self->{Buttons}{IndentDown}, 0, 0, 0);
  $hb2->pack_start($self->{Buttons}{IndentUp}, 0, 0, 0);
  $hb2->pack_start(Gtk2::VSeparator->new, 0, 0, 2);
  $hb2->pack_start($self->{Buttons}{Left}, 0, 0, 0);
  $hb2->pack_start($self->{Buttons}{Center}, 0, 0, 0);
  $hb2->pack_start($self->{Buttons}{Right}, 0, 0, 0);
  $hb2->pack_start($self->{Buttons}{Fill}, 0, 0, 0);
  $vbox->pack_start($hb2, 0, 0, 2);
  $hb2 = Gtk2::HBox->new(0, 0);
  $self->{Buttons}{Heading}->set_width_chars(0);
  $hb2->pack_start($self->{Buttons}{Heading}, 1, 1, 0);
  $vbox->pack_start($hb2, 1, 1, 2);

  # UNDO/REDO GROUP
  $frame = Gtk2::Frame->new('Undo');
  $frame->set_label_align(0.5, 0.5);
  $frame->set_shadow_type('etched-in');
  $lab = $frame->get_label_widget;
  $lab->set_markup('<small>Undo</small>');
  $self->{Toolbar}->pack_start($frame, 0, 0, 2);
  $vbox = Gtk2::VBox->new(0, 0);
  $hb2 = Gtk2::HBox->new(0, 0);
  $frame->add($hb2);
  $hb2->pack_start($vbox, 1, 1, 2);
  $hb2 = Gtk2::HBox->new(0, 0);
  $hb2->pack_start($self->{Buttons}{Undo}, 0, 0, 0);
  $vbox->pack_start($hb2, 1, 1, 2);
  $hb2 = Gtk2::HBox->new(0, 0);
  $hb2->pack_start($self->{Buttons}{Redo}, 0, 0, 0);
  $vbox->pack_start($hb2, 1, 1, 2);

  $self->{Toolbar}->pack_start($self->{Buttons}{DUMP}, 0, 0, 0)
    if $self->get_property('debug') and defined($self->{Buttons}{DUMP});
  $self->{Toolbar}->show_all;
  $self->attach($self->{Toolbar}, 0, 1, 0, 1,
                [qw(fill expand)], [qw(fill)], 0, 0);
}

#########
# _build_text - create the text view and initialise it. Also creates cursors
#               and connects signals as required
#########
sub _build_text {
  my $self = shift;
  my $txt = Gtk2::TextView->new;
  my $scr = Gtk2::ScrolledWindow->new;
  $scr->set_shadow_type('in');
  $scr->set_policy('automatic', 'automatic');
  $scr->add($txt);
  $scr->show_all;
  $self->attach($scr, 0, 1, 1, 2, [qw(fill expand)], [qw(fill expand)], 0, 0);
  $self->{Text} = $txt;
  if ($self->get_property('check-spelling')) {
    eval {require Gtk2::Spell};
    if ($@) {
      warn("Gtk2::Spell does not appear to be installed!");
    } else {
      $self->{GtkSpell} = Gtk2::Spell->new_attach($self->{Text});
      $self->{GtkSpell}->recheck_all;
    }
  }
  my $buf = $txt->get_buffer;
  $buf->signal_connect('mark-set' => sub {$self->_on_cursor_move(@_)});
  $buf->signal_connect_after('insert-text' => sub {$self->_on_insert(@_)});
  $buf->signal_connect('delete-range' => sub {$self->_on_delete(@_)});
  $buf->signal_connect_after('delete-range' => sub {$self->_after_delete(@_)});
  $buf->signal_connect('apply-tag' => sub {$self->_on_apply_tag(@_)});
  $buf->signal_connect('remove-tag' => sub {$self->_on_remove_tag(@_)});
  $self->{Cursor}{Current} = 'Text';
  $self->{Cursor}{Text} = Gtk2::Gdk::Cursor->new('xterm');
  $self->{Cursor}{Link} = Gtk2::Gdk::Cursor->new('hand2');
  $self->{Text}->signal_connect(motion_notify_event =>
                                sub {$self->_on_motion_notify(@_)});
  $self->{Text}->signal_connect('focus-out-event' =>
                                sub {$self->_on_unfocus_text});
  $self->{Text}->signal_connect('populate-popup',
                                sub {$self->_on_popup(@_)});
}

##########
# _init_font_list - examines the pango context and sets available fonts,
#                   the default font and the default size
##########
sub _init_font_list {
  my $self = shift;
  my $c = $self->get_pango_context;
  $BUTTONS{Font}{Default} = $c->get_font_description->get_family;
  $BUTTONS{Font}{Tags} = [];
  for my $name (sort {$a cmp $b} map {$_->get_name} $c->list_families) {
    push @{$BUTTONS{Font}{Tags}}, $name;
  }
  $BUTTONS{Size}{Default} = int($c->get_font_description->get_size / 1024);
  Gtk2::Ex::WYSIWYG::HTML->set_fonts(@{$BUTTONS{Font}{Tags}});
  Gtk2::Ex::WYSIWYG::HTML->set_default_size($BUTTONS{Size}{Default});
}

############################################################################
# Signal Handlers
############################################################################

##########
# _on_apply_tag - to facilitate undo and redo, record tag applications.
##########
sub _on_apply_tag {
  my $self = shift;
  my ($buf, $tag, $s, $e) = @_;
  $self->_record_undo(UNDO_APPLY_TAG, $s->get_offset, $e->get_offset, $tag)
    if $self->_is_my_tag($tag);
  return 0;
}

##########
# _on_remove_tag - to facilitate undo and redo, record tags removals.
# NOTE: the signal handler recieves a start and end range exactly matching
#       what was used in the $buf->remove_tag(...) call, which may be wrong
#       if the range includes bits where the tag wasn't applied in the first
#       place. All tag removals in code should therefore be done with the
#       _remove_tag or _remove_tag_cascade functions within this package
##########
sub _on_remove_tag {
  my $self = shift;
  my ($buf, $tag, $s, $e) = @_;
  $self->_record_undo(UNDO_REMOVE_TAG, $s->get_offset, $e->get_offset, $tag)
    if $self->_is_my_tag($tag);
  return 0;
}

##########
# _on_popup - modify the default popup window to include a Wrap menu
##########
sub _on_popup {
  my $self = shift;
  my ($txt, $menu) = @_;
  my $currmode = $txt->get_wrap_mode;
  my $mt = Gtk2::MenuItem->new('Wrap');
  my $sub = Gtk2::Menu->new;
  $mt->set_submenu($sub);
  my $grp = undef;
  for my $it (['None', 'none'], ['Character', 'char'],
              ['Word', 'word'], ['Word, then character', 'word-char']) {
    my $mi = Gtk2::RadioMenuItem->new($grp, $it->[0]);
    $grp = $mi if not defined $grp;
    $mi->set_active($currmode eq $it->[1]);
    $mi->signal_connect(activate => sub {$txt->set_wrap_mode($it->[1])
                                           if $_[0]->get_active; 0});
    $sub->append($mi);
  }
  $mt->show_all;
  $menu->append($mt);
  $menu->reorder_child($mt, 7);
  return 0;
}

#########
# _on_cursor_move - if the cursor has moved, update the buttons to reflect the
#                   new edit mode
#########
sub _on_cursor_move {
  my $self = shift;
  my ($buf, $iter, $mark) = @_;
  return 0 if $mark->get_name ne 'insert';
  my ($s, $e) = $buf->get_bounds;
  return 0 if $s->equal($e);
  $self->_set_active_from_text;
  $self->_set_buttons_from_active;
  return 0;
}

#########
# _on_insert - make sure that inserted text has the correct tags applied.
#              Do nothing if we're in the middle of an undo action
#              Remember to record this action if we need to for an undo
#########
sub _on_insert {
  my $self = shift;
  my ($buf, $iter, $str) = @_;
  return 0 if $self->{Undoing}; # Don't interfere!
  my $commit = $self->_start_record_undo;
  my $start = $iter->copy;
  $start->backward_chars(length $str);
  $self->_record_undo(UNDO_INSERT_TEXT, $start->get_offset, $iter->get_offset,
                      $str);
  # Ensure correct tags applied to text inserted
  $buf->get_tag_table->
    foreach(sub {
              my ($tag) = @_;
              return if not $self->_is_my_tag($tag);
              if (exists $self->{Active}{$tag->get_property('name')}) {
                $self->_apply_tag_cascade($tag, $start, $iter);
              } else {
                $self->_remove_tag_cascade($tag, $start, $iter);
              }
            });
  # What if this insert just bridged two paragraphs?!
  $self->_normalise_paragraph($start, $iter);
  $self->_set_active_from_text;
  $self->_commit_record_undo if $commit;
  $self->_set_buttons_from_active;
  return 0;
}

###########
# _on_delete - unless we're in the middle of an undo action, record the
#              pending change. Don't just record the delete - pre-remove
#              any tags applied over the range so an undo doesn't plonk plain
#              text back
###########
sub _on_delete {
  my $self = shift;
  return 0 if $self->{Undoing};
  my ($buf, $s, $e) = @_;
  ++$self->{DeleteCommit} if $self->_start_record_undo;
  my $p = $s->copy;
  while (1) {
    last if $p->compare($e) != -1;
    for my $tag ($p->get_tags) {
      next if not $self->_is_my_tag($tag);
      my $t = $p->copy;
      $t = $e->copy if (not $t->forward_to_tag_toggle($tag) or
                        $t->compare($e) == 1);
      $self->_remove_tag($tag, $p, $t);
    }
    last if not $p->forward_to_tag_toggle(undef);
  }
  $self->_record_undo(UNDO_DELETE_TEXT, $s->get_offset, $e->get_offset,
                      $buf->get_text($s, $e, 0));
  0;
}

#########
# _after_delete - unless we're in the middle of an undo action, ensure
#                 paragraph tags are consistent, and make sure the buttons
#                 reflect the current active state. Also commit the undo
#                 recording if we have one.
#########
sub _after_delete {
  my $self = shift;
  return 0 if $self->{Undoing};
  my ($buf, $s, $e) = @_;
  $self->_normalise_paragraph($s, $e);
  $self->_set_active_from_text;
  $self->_set_buttons_from_active;
  if ($self->{DeleteCommit}) {
    $self->_commit_record_undo;
    --$self->{DeleteCommit};
  }
  return 0;
}

sub _on_visibility_notify {
  my $self = shift;
  $self->_set_cursor;
  return 0;
}

sub _on_motion_notify {
  my $self = shift;
  my ($view, $ev) = @_;
  my ($x, $y) = $view->window_to_buffer_coords('widget', $ev->get_coords);
  $self->_set_cursor($x, $y);
  $view->window->get_pointer;
  return 0;
}

sub _on_unfocus_text {
  my $self = shift;
  $self->{Cursor}{Current} = 'Text';
  $self->{Text}->get_window('text')->set_cursor($self->{Cursor}{Text});
  $self->_tooltip_hide();
  $self->{CurrentLink} = undef;
  0;
}

###########
# _on_toggle_change - a toggle button has been toggled - reflect the change
###########
sub _on_toggle_change {
  my $self = shift;
  return 0 if $self->{Lock}{Buttons}; # Programmatic button change in progress
  my ($name) = @_;
  my $commit = $self->_start_record_undo;
  my $tname = $BUTTONS{$name}{Tag};
  my ($s, $e) = $self->_get_current_bounds_for_tag($tname);
  if ($self->{Buttons}{$name}->get_active) {
    # Switching on
    my $tag = $self->_create_tag($self->_full_tag_name($tname),
                                 %{$TAGS{$tname}{Look}});
    $self->_apply_tag_cascade($tag, $s, $e);
    $self->_normalise_paragraph($s, $e)
      if ($tname eq 'asis' or $tname eq 'pre') and not $s->equal($e);
    $self->_set_active_from_text if not $s->equal($e);
    $self->{Active}{$tag->get_property('name')} = undef;
    $self->_set_buttons_from_active;
  } else {
    # Switching off
    my $tag = $self->_full_tag_name($tname);
    $self->_remove_tag_cascade($tag, $s, $e);
    $self->_set_active_from_text if not $s->equal($e);
    delete($self->{Active}{$tag});
    $self->_set_buttons_from_active;
  }
  $self->_commit_record_undo if $commit;
  return 0;
}

###########
# _on_multi_toggle_change - a toggle button has been toggled, and it is a
#                           'multi' tag (ie, makes tagname_X tags rather than
#                           just one tagname tag). Uses the ToggleOn and
#                           ToggleOff tag definitions.
###########
sub _on_multi_toggle_change {
  my $self = shift;
  return 0 if $self->{Lock}{Buttons};
  my ($bname) = @_;
  my $commit = $self->_start_record_undo;
  my $tname = $BUTTONS{$bname}{Tag};
  my ($s, $e) = $self->_get_current_bounds_for_tag($tname);
  if ($self->{Buttons}{$bname}->get_active) {
    die "Multi tag without toggle on code '$tname'!"
      if not exists $TAGS{$tname}{ToggleOn};
    $TAGS{$tname}{ToggleOn}->($self, $bname, $s, $e);
  } else {
    die "Multi tag without toggle off code '$tname'!"
      if not exists $TAGS{$tname}{ToggleOff};
    $TAGS{$tname}{ToggleOff}->($self, $bname, $s, $e);
  }
  $self->_commit_record_undo if $commit;
  return 0;
}

sub _on_button_click {
  my $self = shift;
  return 0 if $self->{Lock}{Buttons};
  my ($bname) = @_;
  my $tname = $BUTTONS{$bname}{Tag};
  die "No code for tag '$tname'!" if not exists $TAGS{$tname}{Activate};
  my $commit = $self->_start_record_undo;
  $TAGS{$tname}{Activate}->($self, $bname,
                            $self->_get_current_bounds_for_tag($tname));
  $self->_commit_record_undo if $commit;
  return 0;
}

sub _on_menu_change {
  my $self = shift;
  my ($bname, $wid, $display, $tname) = @_;
  return 0 if $self->{Lock}{Buttons};
  return 0 if $self->{Buttons}{$bname}->get_inconsistant; # make no changes!
  my $commit = $self->_start_record_undo;
  my ($s, $e);
  my $buf = $self->{Text}->get_buffer;
  for my $tag (@{$BUTTONS{$bname}{Tags}}) {
    next if not exists $TAGS{$tag->[0]};
    ($s, $e) = $self->_get_current_bounds_for_tag($tag->[0])
      if not defined $s;
    last if $s->equal($e);
    $self->_remove_tag_cascade($self->_full_tag_name($tag->[0]), $s, $e);
  }
  my $ftname = $self->_full_tag_name($tname);
  my $tag = $self->_create_tag($ftname, %{$TAGS{$tname}{Look}})
    if $display ne $BUTTONS{$bname}{Default};
  if ($s->equal($e)) {
    for my $tag (@{$BUTTONS{$bname}{Tags}}) {
      delete($self->{Active}{$self->_full_tag_name($tag->[0])});
    }
    $self->{Active}{$ftname} = undef;
    $self->_set_buttons_from_active;
  } else {
    $self->_apply_tag_cascade($tag, $s, $e)
      if $display ne $BUTTONS{$bname}{Default};
    # Update subscript and superscript over this range!
    # Maybe meld this into apply_tag_cascade?
    if ($tname =~ /^h[1-5]\z/) {
      $self->_update_superscript($s, $e, undef, $TAGS{$tname}{Look}{scale});
      $self->_update_subscript($s, $e, undef, $TAGS{$tname}{Look}{scale});
    } elsif ($tname eq 'h0') {
      $self->_update_superscript($s, $e, undef, 1);
      $self->_update_subscript($s, $e, undef, 1);
    }
    $self->{Active}{$ftname} = undef;
    $self->_set_buttons_from_active;
  }
  $self->_commit_record_undo if $commit;
  return 0;
}

sub _on_font_change {
  my $self = shift;
  my ($bname, $wid, $display, $tname) = @_;
  return 0 if $self->{Lock}{Buttons};
  return 0 if $self->{Buttons}{$bname}->get_inconsistant; # make no changes!
  my $commit = $self->_start_record_undo;
  my $buf = $self->{Text}->get_buffer;
  my ($s, $e) = $self->_get_current_bounds_for_tag('font');
  # Remove any current font from that range
  {
    my @rem;
    my $tt = $buf->get_tag_table;
    $tt->foreach(sub {
                   push @rem, $_[0] if
                     $self->_short_tag_name($_[0]) eq 'font';
                 });
    for my $rem (@rem) {
      $self->_remove_tag($rem, $s, $e);
    }
  }
  my $ftname = $self->_full_tag_name('font', $tname);
  my $tag = $self->_create_tag($ftname, family => $tname)
    if $display ne $BUTTONS{$bname}{Default};
  if ($s->equal($e)) {
    for my $tag (@{$BUTTONS{$bname}{Tags}}) {
      delete($self->{Active}{$self->_full_tag_name('font', $tag)});
    }
  } elsif ($display ne $BUTTONS{$bname}{Default}) {
    $self->_apply_tag_cascade($tag, $s, $e);
  }
  $self->{Active}{$ftname} = undef;
  $self->_set_buttons_from_active;
  $self->_commit_record_undo if $commit;
  return 0;
}
    
sub _on_size_change {
  my $self = shift;
  return 0 if $self->{Lock}{Buttons};
  my ($name, $wid, $size) = @_;
  return 0 if $size !~ /\d/ or not $size;
  my $commit = $self->_start_record_undo;
  my $buf = $self->{Text}->get_buffer;
  my $tname = $BUTTONS{$name}{Tag};
  my ($s, $e) = $self->_get_current_bounds_for_tag($tname);
  my $nosel = $s->equal($e);
  if (not $nosel) {
    $buf->get_tag_table->
      foreach(sub {
                my ($tag) = @_;
                return if not $self->_is_my_tag($tag);
                $self->_remove_tag_cascade($tag, $s, $e)
                  if $self->_short_tag_name($tag) eq $tname;
              });
    # Update super/subscript tags for this range!
    $self->_update_subscript($s, $e, $size);
    $self->_update_superscript($s, $e, $size);
  }
  my $tag = $self->_create_tag($self->_full_tag_name($tname, $size),
                               size => $size * 1024);
  if ($nosel) {
    for my $k (keys %{$self->{Active}}) {
      delete($self->{Active}{$k})
        if $self->_short_tag_name($k) eq $BUTTONS{$name}{Tag};
    }
    $self->{Active}{$tag->get_property('name')} = undef;
  } else {
    $self->_apply_tag_cascade($tag, $s, $e);
    $self->_set_active_from_text;
  }
  $self->_set_buttons_from_active;
  $self->_commit_record_undo if $commit;
  return 0;
}

# Callbacks for specific buttons

sub _sup_sub_scan {
  my $self = shift;
  my ($s, $e, $type, $force) = @_;
  my ($sz, $sc);
  for my $tag ($s->get_tags) {
    next if not $self->_is_my_tag($tag);
    my $name = $self->_short_tag_name($tag);
    if ($name eq 'superscript' or $name eq 'subscript') {
      $self->_remove_tag_cascade($tag, $s, $e);
      next;
    }
    if (not defined $sz and $name eq 'size') {
      ($sz) = $self->_tag_args($tag, 1);
    } elsif (not defined $sc and $name =~ /^h[1-5]\z/) {
      $sc = $TAGS{$name}{Look}{scale};
    }
  }
  $sz = $BUTTONS{Size}{Default} if not defined $sz;
  $sc = 1 if not $sc;
  my $n = $s->copy;
  $n->forward_to_tag_toggle(undef);
  $n = $e->copy if $n->compare($e) == 1;
  $self->_apply_tag_cascade($self->_create_sub_super_tag($type, $sz, $sc),
                            $s, $n);
  return $n;
}

sub _create_sub_super_tag {
  my $self = shift;
  my ($type, $size, $scale) = @_;
  my $rise = ($type eq 'superscript' ? 0.75 : -0.25);
  $rise = int($size * $scale * $rise * 1024);
  $self->_create_tag($self->_full_tag_name($type, $size, $scale),
                     scale => 0.5, rise => $rise);
}

sub _superscript_on {
  my $self = shift;
  my ($s, $e) = @_;
  my $buf = $self->{Text}->get_buffer;
  my $p = $s->copy;
  while (1) {
    $p = $self->_sup_sub_scan($p, $e, 'superscript');
    last if $p->compare($e) != -1;
  }
  $self->_set_active_from_text;
  $self->_set_buttons_from_active;
}

sub _superscript_off {
  my $self = shift;
  my ($s, $e) = @_;
  my $buf = $self->{Text}->get_buffer;
  $buf->get_tag_table->
    foreach(sub {
              my ($tag) = @_;
              return if (not $self->_is_my_tag($tag) or
                         $self->_short_tag_name($tag) ne 'superscript');
              $self->_remove_tag_cascade($tag, $s, $e);
            });
  $self->_set_active_from_text;
  $self->_set_buttons_from_active;
}

sub _update_superscript {
  my $self = shift;
  my ($s, $e, $force_size, $force_scale) = @_;
  $s = $s->copy;
  my $buf = $self->{Text}->get_buffer;
  while (1) {
    last if $s->compare($e) != -1;
    my ($size, $scale, $curr, $csize, $cscale) =
      ($BUTTONS{Size}{Default}, 1, undef, undef, undef);
    for my $tag ($s->get_tags) {
      next if not $self->_is_my_tag($tag);
      my $name = $self->_short_tag_name($tag);
      if ($name eq 'size') {
        ($size) = $self->_tag_args($tag, 1);
      } elsif ($name =~ /^h[1-5]\z/) {
        $scale = $TAGS{$name}{Look}{scale};
      } elsif ($name eq 'superscript') {
        $curr = $tag;
        ($csize, $cscale) = $self->_tag_args($tag, 2);
      }
    }
    $scale = 1 if not $scale;
    $size = $force_size if defined $force_size;
    $scale = $force_scale if defined $force_scale;
    my $t = $s->copy;
    $t = $e->copy if not $t->forward_to_tag_toggle(undef);
    if (defined($curr) and ($csize != $size or $cscale != $scale)) {
      $self->_remove_tag($curr, $s, $t);
      $self->_apply_tag($self->_create_sub_super_tag('superscript',
                                                     $size, $scale), $s, $t);
    }
    $s = $t;
  }
}

sub _subscript_on {
  my $self = shift;
  my ($s, $e) = @_;
  my $buf = $self->{Text}->get_buffer;
  my $p = $s->copy;
  while (1) {
    $p = $self->_sup_sub_scan($p, $e, 'subscript');
    last if $p->compare($e) != -1;
  }
  $self->_set_active_from_text;
  $self->_set_buttons_from_active;
}

sub _subscript_off {
  my $self = shift;
  my ($s, $e) = @_;
  my $buf = $self->{Text}->get_buffer;
  $buf->get_tag_table->
    foreach(sub {
              my ($tag) = @_;
              return if (not $self->_is_my_tag($tag) or
                         $self->_short_tag_name($tag) ne 'subscript');
              $self->_remove_tag_cascade($tag, $s, $e);
            });
  $self->_set_active_from_text;
  $self->_set_buttons_from_active;
}

sub _update_subscript {
  my $self = shift;
  my ($s, $e, $force_size, $force_scale) = @_;
  $s = $s->copy;
  my $buf = $self->{Text}->get_buffer;
  while (1) {
    last if $s->compare($e) != -1;
    my ($size, $scale, $curr, $csize, $cscale) =
      ($BUTTONS{Size}{Default}, 1, undef, undef, undef);
    for my $tag ($s->get_tags) {
      next if not $self->_is_my_tag($tag);
      my $name = $self->_short_tag_name($tag);
      if ($name eq 'size') {
        ($size) = $self->_tag_args($tag, 1);
      } elsif ($name =~ /^h[1-5]\z/) {
        $scale = $TAGS{$name}{Look}{scale};
      } elsif ($name eq 'subscript') {
        $curr = $tag;
        ($csize, $cscale) = $self->_tag_args($tag, 2);
      }
    }
    $scale = 1 if not $scale;
    $size = $force_size if defined $force_size;
    $scale = $force_scale if defined $force_scale;
    my $t = $s->copy;
    $t = $e->copy if not $t->forward_to_tag_toggle(undef);
    if (defined($curr) and ($csize != $size or $cscale != $scale)) {
      $self->_remove_tag($curr, $s, $t);
      $self->_apply_tag($self->_create_sub_super_tag('subscript',
                                                     $size, $scale), $s, $t);
    }
    $s = $t;
  }
}

sub _indent_up {
  my $self = shift;
  my ($s, $e) = @_;
  my ($ps, $pe) = $self->_get_current_bounds_for_tag('indent');
  my $buf = $self->{Text}->get_buffer;
  while (1) {
    last if $ps->compare($pe) != -1;
    my $curr;
    for my $tag ($ps->get_tags) {
      next if not $self->_is_my_tag($tag);
      my ($name, $val) = $self->_tag_name_args($tag, 1);
      next if $name ne 'indent';
      $curr = $val;
      last;
    }
    my $t = $ps->copy;
    $ps = $pe if not $ps->forward_to_tag_toggle(undef);
    if (defined($curr)) {
      $self->_remove_tag($self->_full_tag_name('indent', $curr), $t, $ps);
      ++$curr;
    } else {
      $curr = 0;
    }
    $self->_apply_tag($self->_create_tag($self->_full_tag_name('indent',
                                                               $curr),
                                         'left-margin' => 32 * ($curr + 1)),
                      $t, $ps);
  }
  return 0;
}

sub _indent_down {
  my $self = shift;
  my ($s, $e) = @_;
  my ($ps, $pe) = $self->_get_current_bounds_for_tag('indent');
  my $buf = $self->{Text}->get_buffer;
  while (1) {
    last if $ps->compare($pe) != -1;
    my $curr;
    for my $tag ($ps->get_tags) {
      next if not $self->_is_my_tag($tag);
      my ($name, $val) = $self->_tag_name_args($tag, 1);
      next if $name ne 'indent';
      $curr = $val;
      last;
    }
    my $t = $ps->copy;
    $ps = $pe if not $ps->forward_to_tag_toggle(undef);
    next if not defined $curr;
    $self->_remove_tag($self->_full_tag_name('indent', $curr), $t, $ps);
    next if not $curr;
    --$curr;
    $self->_apply_tag($self->_create_tag($self->_full_tag_name('indent',
                                                               $curr),
                                         'left-margin' => 32 * ($curr + 1)),
                      $t, $ps);
  }
  return 0;
}

sub _link_on {
  my $self = shift;
  my ($s, $e) = @_;
  my $buf = $self->{Text}->get_buffer;
  my $txt = $buf->get_text($s, $e, 0);
  my $target = $txt;
  ($txt, $target) = $self->_get_link_target($txt, $target);
  return 0 if not defined $txt; # What about length?!
  my $tag = $self->_create_link($target);
  if ($s->equal($e)) { # No selection
    my $here = $buf->get_iter_at_mark($buf->get_insert);
    my $s = $here->get_offset;
    $buf->insert($here, $txt);
    $s = $buf->get_iter_at_offset($s);
    $e = $s->copy;
    $e->forward_chars(length($txt));
    $self->_apply_tag_cascade($tag, $s, $e);
  } else {
    my $off = $s->get_offset;
    $buf->delete($s, $e); ## GET TAGS OVER THIS RANGE
    $s = $buf->get_iter_at_offset($off);
    $buf->insert($s, $txt); ## APPLY TAGS OVER THIS RANGE
    $s = $buf->get_iter_at_offset($off);
    $e = $s->copy;
    $e->forward_chars(length($txt));
    $self->_apply_tag_cascade($tag, $s, $e);
    $buf->select_range($s, $e);
  }
}

sub _create_link {
  my $self = shift;
  my ($target) = @_;
  $self->{LinkID} = 0 if not exists $self->{LinkID};
  my $tag = $self->_create_tag($self->_full_tag_name('link',
                                                     $self->{LinkID}++),
                               %{$TAGS{link}{Look}});
  $tag->{Target} = $target;
  return $tag;
}

sub _link_off {
  my $self = shift;
  my ($s, $e) = @_;
  my $buf = $self->{Text}->get_buffer;
  $buf->get_tag_table->foreach(sub {
                                 my ($tag) = @_;
                                 $self->_remove_tag_cascade($tag, $s, $e)
                                   if ($self->_is_my_tag($tag) and
                                       $self->_short_tag_name($tag) eq 'link');
                               }) if not $s->equal($e);
}

sub _get_link_target {
  my $self = shift;
  my ($txt, $target) = @_;
  my $win = $self;
  while (1) {
    last if $win->isa('Gtk2::Window');
    $win = $win->get_parent;
    last if not defined $win;
  }
  my $dlg = Gtk2::Dialog->new("Insert link...", $win,
                              [qw(modal destroy-with-parent)]);
  my $cancel = $dlg->add_button('gtk-cancel' => 'cancel');
  my $ok = $dlg->add_button('gtk-ok' => 'ok');
  my $tbl = Gtk2::Table->new(3, 2, 0);
  my $label = Gtk2::Label->new("Define your link text and destination");
  $tbl->attach($label, 0, 2, 0, 1, [qw(fill expand)], [], 4, 4);
  my ($etxt, $elnk);
  for my $dat ([\$etxt, 'Text:', $txt,    1],
               [\$elnk, 'Link:', $target, 2]) {
    my ($er, $lb, $tx, $i) = @$dat;
    my $lab = Gtk2::Label->new($lb);
    $tbl->attach($lab, 0, 1, $i, $i + 1, [], [qw(fill)], 4, 4);
    $$er = Gtk2::Entry->new;
    $$er->set_text($tx);
    $$er->signal_connect(activate =>
                         sub {$ok->clicked if $ok->sensitive; 0});
    $$er->signal_connect(changed =>
                         sub {
                           $ok->set_sensitive(length($etxt->get_text) and
                                              length($elnk->get_text));
                           0;
                         });
    $tbl->attach($$er, 1, 2, $i, $i + 1, [], [qw(fill expand)], 4, 4);
  }
  $ok->set_sensitive(0) if not length($txt) or not length($target);
  (length($txt) ? $elnk : $etxt)->grab_focus;
  $tbl->show_all;
  eval {$dlg->get_content_area->add($tbl)};
  $dlg->vbox->add($tbl) if $@;
  $dlg->set_default_response('ok');
  my $res = $dlg->run;
  if ($res ne 'ok') {
    $dlg->destroy;
    return;
  }
  $txt = $etxt->get_text;
  $target = $elnk->get_text;
  $dlg->destroy;
  return ($txt, $target);
}

sub _increase_size {
  my $self = shift;
  if (not $self->{Buttons}{Size}->get_inconsistant) {
    $self->{Buttons}{Size}->up_value;
    return 0;
  }
  my ($s, $e) = $self->_get_current_bounds_for_tag('size');
  my $buf = $self->{Text}->get_buffer;
  while (1) {
    last if $s->compare($e) != -1;
    my $size = $BUTTONS{Size}{Default};
    for my $tag ($s->get_tags) {
      next if not $self->_is_my_tag($tag);
      my ($name, $val) = $self->_tag_name_args($tag, 1);
      next if $name ne 'size';
      $size = $val;
      last;
    }
    my $t = $s->copy;
    $s = $e if not $s->forward_to_tag_toggle(undef);
    $self->_remove_tag($self->_full_tag_name('size', $size), $t, $s);
    $size = $self->{Buttons}{Size}->next_value_up($size);
    $self->_apply_tag($self->_create_tag($self->_full_tag_name('size', $size),
                                         size => $size * 1024), $t, $s);
  }
  $self->_set_active_from_text;
  $self->_set_buttons_from_active;
  return 0;
}

sub _decrease_size {
  my $self = shift;
  if (not $self->{Buttons}{Size}->get_inconsistant) {
    $self->{Buttons}{Size}->down_value;
    return 0;
  }
  # Selection, and with differing sizes
  my ($s, $e) = $self->_get_current_bounds_for_tag('size');
  my $buf = $self->{Text}->get_buffer;
  while (1) {
    last if $s->compare($e) != -1;
    my $size = $BUTTONS{Size}{Default};
    for my $tag ($s->get_tags) {
      next if not $self->_is_my_tag($tag);
      my ($name, $val) = $self->_tag_name_args($tag, 1);
      next if $name ne 'size';
      $size = $val;
      last;
    }
    my $t = $s->copy;
    $s = $e if not $s->forward_to_tag_toggle(undef);
    $self->_remove_tag($self->_full_tag_name('size', $size), $t, $s);
    $size = $self->{Buttons}{Size}->next_value_down($size);
    $self->_apply_tag($self->_create_tag($self->_full_tag_name('size', $size),
                                         size => $size * 1024), $t, $s);
  }
  $self->_set_active_from_text;
  $self->_set_buttons_from_active;
  return 0;
}

sub _clear_font_formatting {
  my $self = shift;
  my ($s, $e) = @_;
  my $buf = $self->{Text}->get_buffer;
  if ($s->equal($e)) {
    # remove all non-paragraph tags
    for my $tname (keys %{$self->{Active}}) {
      my $rname = $self->_short_tag_name($tname);
      next if not exists $TAGS{$rname} or $TAGS{$rname}{Class} eq 'paragraph';
      delete($self->{Active}{$tname});
    }
    $self->_set_active_from_text if not $s->equal($buf->get_end_iter);
  } else {
    $buf->get_tag_table->foreach(sub {
                                   my ($tag) = @_;
                                   return if not $self->_is_my_tag($tag);
                                   my $name = $self->_short_tag_name($tag);
                                   return
                                     if (not exists $TAGS{$name} or
                                         $TAGS{$name}{Class} eq 'paragraph');
                                   $self->_remove_tag_cascade($tag, $s, $e);
                                 });
     $self->_set_active_from_text;
  }
  $self->_set_buttons_from_active;
}

# Undo and Redo

sub _start_record_undo {
  my $self = shift;
  return 0 if $self->{Undoing} or defined $self->{Record};
  $self->{Record} = [];
  return 1;
}

sub _record_undo {
  my $self = shift;
  return if $self->{Undoing} or not defined $self->{Record};
  my ($act, $start, $end, @dat) = @_;
  push @{$self->{Record}}, [$act, $start, $end, @dat];
}

sub _commit_record_undo {
  my $self = shift;
  return 0 if $self->{Undoing};
  if (defined($self->{Record}) and scalar(@{$self->{Record}})) {
    push @{$self->{UndoStack}}, $self->{Record};
    my $max = $self->{Properties}{undo_stack};
    shift @{$self->{UndoStack}} if ($max and
                                    scalar(@{$self->{UndoStack}}) > $max);
    $self->{RedoStack} = []; ###
  }
  $self->{Record} = undef;
}

sub _rollback_record_undo {
  my $self = shift;
  $self->{Record} = undef;
}

# Tag handling

sub _create_tag {
  my $self = shift;
  my ($name, %opts) = @_;
  $opts{justification} = 'left'
    if (exists $opts{justification} and $opts{justification} eq 'fill' and 
        $self->get_property('map-fill-to-left'));
  my $tag = $self->{Text}->get_buffer->get_tag_table->lookup($name);
  $tag = $self->{Text}->get_buffer->create_tag($name, %opts)
    if not defined $tag;
  $tag->{WYSIWYG} = undef; # Use this later to store data?
  return $tag;
}

sub _apply_tag_cascade {
  my $self = shift;
  my ($tag, $start, $end) = @_;
  my $buf = $self->{Text}->get_buffer;
  $tag = $self->{Text}->get_buffer->get_tag_table->lookup($tag)
    if not ref($tag);
  return if not defined $tag;
  my $regname = $self->_short_tag_name($tag);
  my $tdef = $TAGS{$regname};
  if ($regname eq 'asis') {
    # Remove all non-paragraph tags
    $buf->get_tag_table->
      foreach(sub {
                my ($tag) = @_;
                return if not $self->_is_my_tag($tag);
                my $name = $self->_short_tag_name($tag);
                return if (not exists $TAGS{$name} or
                           $TAGS{$name}{Class} eq 'paragraph');
                $self->_remove_tag($tag, $start, $end);
              });
    $self->_apply_tag($tag, $start, $end);
    return 1;
  }
  if ($tdef->{Multi} or defined($tdef->{Group})) {
    $buf->get_tag_table->
      foreach(sub {
                my ($tag) = @_;
                return if not $self->_is_my_tag($tag);
                my $name = $self->_short_tag_name($tag);
                $self->_remove_tag($tag, $start, $end)
                  if (($tdef->{Multi} and $name eq $regname) or
                      grep {$_ eq $name} @{$tdef->{Group}});
              });
  }
  if ($tdef->{Class} eq 'paragraph') {
    $self->_apply_tag($tag, $start, $end);
    return 1;
  }
  # Only apply this tag to places where the asis tag is not
  my $s = $start->copy;
  my $aname = $self->_full_tag_name('asis');
#  my $asis = $buf->get_tag_table->lookup($aname);
  my $asis = $self->_create_tag($aname, %{$TAGS{asis}{Look}});
  die("Gtk2::Ex::WYSIWYG tag naming conflict for $aname - " .
      "tag name already in use!") if not $self->_is_my_tag($asis);
  while (1) {
    my $asishere = 0;
    for my $tag ($s->get_tags) {
      next if $tag ne $asis;
      $asishere = 1;
      last;
    }
    $s->forward_to_tag_toggle($asis) if $asishere;
    return 1 if $s->compare($end) != -1;
    my $e = $s->copy;
    $e->forward_to_tag_toggle($asis);
    $e = $end->copy if $e->compare($end) == 1;
    # s to e is asis free
    $self->_apply_tag($tag, $start, $end);
    last if $e->equal($end);
    $s = $e;
  }
  return 1;
}

sub _apply_tag {
  my $self = shift;
  my ($tag, $start, $end) = @_;
  $tag = $self->{Text}->get_buffer->get_tag_table->lookup($tag)
    if not ref $tag;
  $self->{Text}->get_buffer->apply_tag($tag, $start, $end) if defined $tag;
}

sub _remove_tag_cascade {
  my $self = shift;
  my ($tag, $start, $end) = @_;
  # ONLY REMOVE THE TAG FROM THE AREAS IT IS APPLIED!
  my $buf = $self->{Text}->get_buffer;
  $self->_remove_tag($tag, $start, $end);
  $tag = $tag->get_property('name') if ref($tag);
  delete($self->{Active}{$tag});
  return 1;
}

sub _remove_tag {
  my $self = shift;
  my ($tag, $s, $e) = @_;
  my $buf = $self->{Text}->get_buffer;
  $tag = $buf->get_tag_table->lookup($tag) if not ref($tag);
  return if not defined $tag;
  my $t = $s->copy;
  SEARCH: while (1) {
    last if $t->compare($e) != -1;
    for my $ctag ($t->get_tags) {
      next if $ctag ne $tag;
      my $u = $t->copy;
      $t = $e->copy if (not $t->forward_to_tag_toggle($tag) or
                        $t->compare($e) == 1);
      $buf->remove_tag($tag, $u, $t);
      next SEARCH;
    }
    last if not $t->forward_to_tag_toggle($tag);
  }
}

# Given a tag name, ensure it is a tag controlled by this package.
# Of course, if someone tries hard enough, this can be fooled
sub _is_my_tag {
  my $self = shift;
  my ($tag) = @_;
  return 0 if not defined $tag or not exists $tag->{WYSIWYG};
  return 1;
}

sub _full_tag_name {
  my $self = shift;
  my ($name, @args) = @_;
  return $name->get_property('name') if ref($name);
  my $full = "gtkwysiwyg:$name";
  $full .= ":" . join(":", @args) if scalar(@args);
  return $full;
}

sub _short_tag_name {
  my $self = shift;
  my ($tag) = @_;
  $tag = $tag->get_property('name') if ref $tag;
  return undef if index($tag, 'gtkwysiwyg:') != 0;
  my $end = index($tag, ':', 11);
  return substr($tag, 11) if $end == -1;
  return substr($tag, 11, $end - 11);
}

sub _tag_args {
  my $self = shift;
  my ($tag, $acnt) = @_;
  $tag = $tag->get_property('name') if ref($tag);
  return () if index($tag, 'gtkwysiwyg:') != 0;
  my $end = index($tag, ':', 11);
  return () if $end == -1;
  return (split(':', substr($tag, $end + 1), $acnt));
}

sub _tag_name_args {
  my $self = shift;
  my ($tag, $acnt) = @_;
  $tag = $tag->get_property('name') if ref($tag);
  return undef if index($tag, 'gtkwysiwyg:') != 0;
  my $end = index($tag, ':', 11);
  return substr($tag, 11) if $end == -1;
  return (substr($tag, 11, $end - 11),
          split(':', substr($tag, $end + 1), $acnt));
}

# Button/active manipulation

sub _set_active_from_text {
  # Set the active hash from the current position
  # Also keep track of whether the font and size should be set/'inconsistant'
  my $self = shift;
  $self->{Active} = {};
  my $buf = $self->{Text}->get_buffer;
  my ($s, $e) = $buf->get_selection_bounds;
  if (not defined($s)) {
    ($s, $e) = $buf->get_bounds;
    return 0 if $s->equal($e);
    $s = $buf->get_iter_at_mark($buf->get_insert);
    $e = undef;
  }
  if (not defined($e)) {
    # No selection - also means only one possible font/size
    $s->backward_char if $s->compare($buf->get_start_iter) != 0;
    for my $tag ($s->get_tags) {
      next if not $self->_is_my_tag($tag);
      $self->{Active}{$tag->get_property('name')} = undef;
    }
    $self->{FontSet} = 1;
    $self->{SizeSet} = 1;
  } else {
    # Selection
    my $p = $s->copy;
    my $common = {};
    my $fonts = {};
    my $sizes = {};
    while (1) {
      last if $p->compare($e) != -1;
      my $this = {};
      my ($nofont, $nosize) = (1, 1);
      for my $tag ($p->get_tags) {
        next if not $self->_is_my_tag($tag);
        my $name = $self->_short_tag_name($tag);
        if ($name eq 'font') {
          $nofont = 0;
          my ($font) = $self->_tag_args($tag, 1);
          $fonts->{$font} = undef;
        } elsif ($name eq 'size') {
          $nosize = 0;
          my ($size) = $self->_tag_args($tag, 1);
          $sizes->{$size} = undef;
        }
        $name = $self->_full_tag_name($tag);
        $common->{$name} = undef if $p->equal($s);
        $this->{$name} = undef;
      }
      $fonts->{DEFAULT} = undef if $nofont;
      $sizes->{DEFAULT} = undef if $nosize;
      if (not $p->equal($s)) {
        for my $k (keys %$common) {
          delete($common->{$k}) if not exists $this->{$k};
        }
      }
      last if not $p->forward_to_tag_toggle(undef);
    }
    $self->{Active} = $common;
    $self->{FontSet} = scalar(keys %$fonts) <= 1;
    $self->{SizeSet} = scalar(keys %$sizes) <= 1;
  }
  return 0;
}
  
sub _set_buttons_from_active {
  my $self = shift;
  ++$self->{Lock}{Buttons};
  # Font disabled if asis, enabled otherwise
  # size disabled if asis, enabled otherwise
  # size+/- disabled if asis, enabled otherwise
  # bold/italic/underline/strike/sup/sub/pre disabled if asis, enabled other
  for my $bname (keys %BUTTONS) {
    if ($bname eq 'Undo') {
      $self->{Buttons}{Undo}->set_sensitive(scalar(@{$self->{UndoStack}}));
      next;
    } elsif ($bname eq 'Redo') {
      $self->{Buttons}{Redo}->set_sensitive(scalar(@{$self->{RedoStack}}));
      next;
    } elsif (exists $self->{Active}{$self->_full_tag_name('asis')} and
             exists $BUTTONS{$bname}{Tag} and
             $BUTTONS{$bname}{Tag} ne 'asis' and
             $BUTTONS{$bname}{Tag} ne 'clear' and
             $TAGS{$BUTTONS{$bname}{Tag}}{Class} eq 'font') {
      $self->{Buttons}{$bname}->set_sensitive(0);
    } else {
      $self->{Buttons}{$bname}->set_sensitive(1);
    }
    next if $BUTTONS{$bname}{Type} eq 'button';
    if ($BUTTONS{$bname}{Type} eq 'menu') {
      $self->{Buttons}{$bname}->
        set_text($self->_get_current_menu_state($bname));
    } elsif ($BUTTONS{$bname}{Type} eq 'font') {
      if ($self->{FontSet}) {
        $self->{Buttons}{$bname}->
          set_text($self->_get_current_font_state($bname));
      } else {
        $self->{Buttons}{$bname}->set_inconsistant;
      }
    } elsif ($BUTTONS{$bname}{Type} eq 'size') {
      if ($self->{SizeSet}) {
        $self->{Buttons}{$bname}->set_value($self->_get_current_size($bname));
      } else {
        $self->{Buttons}{$bname}->set_inconsistant;
      }
    } elsif ($BUTTONS{$bname}{Type} eq 'toggle') {
      $self->{Buttons}{$bname}->
        set_active($self->_get_current_toggle_state($bname));
    }
  }
  --$self->{Lock}{Buttons};
  return 0;
}

sub _get_current_toggle_state {
  my $self = shift;
  my ($bname) = @_;
  my $tag = $BUTTONS{$bname}{Tag};
  if ($TAGS{$tag}{Multi}) {
    for my $k (keys %{$self->{Active}}) {
      next if $self->_short_tag_name($k) ne $tag;
      return 1;
    }
  } elsif (exists($self->{Active}{$self->_full_tag_name($tag)})) {
    return 1;
  }
  return 0 if not exists $TAGS{$tag}{Default};
  if ($TAGS{$tag}{Default} eq $tag) {
    for my $other (@{$TAGS{$tag}{Group}}) {
      return 0 if exists($self->{Active}{$self->_full_tag_name($other)});
    }
    return 1;
  }
  return 0;
}

sub _get_current_menu_state {
  my $self = shift;
  my ($bname) = @_;
  for my $tdef (@{$BUTTONS{$bname}{Tags}}) {
    my ($tagname, $display) = @$tdef;
    next if not exists $self->{Active}{$self->_full_tag_name($tagname)};
    return $display;
  }
  return $BUTTONS{$bname}{Default};
}

sub _get_current_font_state {
  my $self = shift;
  my ($bname) = @_;
  for my $fname (@{$BUTTONS{$bname}{Tags}}) {
    next if not exists $self->{Active}{$self->_full_tag_name('font',
                                                             $fname)};
    return $fname;
  }
  return $BUTTONS{$bname}{Default};
}

sub _get_current_size {
  my $self = shift;
  my ($bname) = @_;
  my $tname = $BUTTONS{$bname}{Tag};
  for my $k (keys %{$self->{Active}}) {
    my ($name, $size) = $self->_tag_name_args($k);
    next if $name ne $tname;
    return $size;
  }
  return $BUTTONS{$bname}{Default};
}

# Paragraph normalisation

sub _normalise_paragraph {
  my $self = shift;
  my ($s, $e) = @_;
  my ($ps, $pe) = $self->_get_paragraph_bounds($s, $e);
  my $buf = $self->{Text}->get_buffer;
  my @apply;
  for my $tag ($ps->get_tags) {
    next if not $self->_is_my_tag($tag);
    my $name = $self->_short_tag_name($tag);
    push @apply, $tag if (exists($TAGS{$name}) and
                          $TAGS{$name}{Class} eq 'paragraph');
  }
  $buf->get_tag_table->foreach(sub {
                                 my ($tag) = @_;
                                 return if not $self->_is_my_tag($tag);
                                 my $name = $self->_short_tag_name($tag);
                                 $self->_remove_tag($tag, $ps, $pe)
                                   if (exists $TAGS{$name} and
                                       $TAGS{$name}{Class} eq 'paragraph');
                               });
  for my $tag (@apply) {
    $self->_apply_tag_cascade($tag, $ps, $pe);
  }
}

# Bounds fetching

sub _get_current_bounds_for_tag {
  my $self = shift;
  my ($tname) = @_;
  if ($TAGS{$tname}{Class} eq 'paragraph') {
    return $self->_get_current_paragraph_bounds;
  } else {
    my $buf = $self->{Text}->get_buffer;
    my ($s, $e) = $buf->get_selection_bounds;
    if (not defined($s)) {
      $s = $buf->get_iter_at_mark($buf->get_insert);
      $e = $s->copy;
    }
    return ($s, $e);
  }
}

sub _get_current_paragraph_bounds {
  my $self = shift;
  my $buf = $self->{Text}->get_buffer;
  my ($s, $e) = $buf->get_selection_bounds;
  if (not defined($s)) {
    $s = $buf->get_iter_at_mark($buf->get_insert);
    $e = $s->copy;
  }
  return $self->_get_paragraph_bounds($s, $e);
}

sub _get_paragraph_bounds {
  my $self = shift;
  my ($s, $e) = @_;
  my ($ps, $pe);
  if ($self->_iter_in_real_paragraph($s)) {
    ($ps, $pe) = $self->_get_real_paragraph_bounds_for_iter($s);
  } else {
    ($ps, $pe) = $self->_get_inter_paragraph_bounds_for_iter($s);
  }
  return ($ps, $pe) if ($s->equal($e) or $e->compare($pe) == -1);
  if ($self->_iter_in_real_paragraph($e)) {
    (my $t, $pe) = $self->_get_real_paragraph_bounds_for_iter($e);
  } else {
    (my $t, $pe) = $self->_get_real_paragraph_bounds_for_iter($e);
  }
  return ($ps, $pe);
}

sub _iter_in_real_paragraph {
  ## ASIS AND PRE TAGS!
  ## newlines inside pre/asis tags do not count as 'paragraph breakers'
  ## In fact, _ANYTHING_ inside pre/asis tags count as a single 'non-space'
  ## item
  ## A\n\nB -> paragraphs are A and B
  ## A<p>\n\n</p>B -> all one paragraph
  ## A\n\n<p>\n\n\n\n</p>\n\nB => paragraphs are A, <p>\n\n\n\n</p> and B
  my $self = shift;
  my ($i) = @_;
  return 1 if not $self->_get_newline_state_at_iter($i);
  my $j = $i->copy;
  $j->forward_char;
  my $curr = $i->get_slice($j);
  return 1 if $curr =~ /\S/;
  my $prenl = 0;
  my $postnl = 0;
  ++$postnl if $curr eq "\n";
  my $FOUNDNL = 0;
  my $lookfor = sub {
    $FOUNDNL = ($_[0] eq "\n");
    return (($_[0] eq "\n") or ($_[0] =~ /\S/));
  };
  my $s = $i->copy;
  while ($s->backward_find_char($lookfor)) {
    last if not $FOUNDNL or not $self->_get_newline_state_at_iter($s);
    last if ++$prenl == 2;
  }
  return 1 if $prenl == 0;
  my $e = $i->copy;
  while ($e->forward_find_char($lookfor)) {
    last if not $FOUNDNL or not $self->_get_newline_state_at_iter($e);
    last if ++$postnl == 2;
  }
  return $postnl == 0;
}

sub _get_real_paragraph_bounds_for_iter {
  my $self = shift;
  my ($i) = @_;
  my $s = $i->copy;
  my $e = $i->copy;
  $e->forward_char;
  my $curr = $s->get_slice($e);
  my $lastnl = undef;
  my $FOUNDNL = 0;
  my $lookfor = sub {
    $FOUNDNL = ($_[0] eq "\n");
    return (($_[0] eq "\n") or ($_[0] =~ /\S/));
  };
  while (1) {
    if (not $s->backward_find_char($lookfor)) {
      $s = $self->{Text}->get_buffer->get_start_iter;
      last;
    } elsif ($FOUNDNL) {
      # If this NL is in pre or asis, it counts as a \S
      if (not $self->_get_newline_state_at_iter($s)) {
        $lastnl = undef; # lastnl is invalidated when we find \S
        next;
      } elsif (defined($lastnl)) {
        $s = $lastnl;
        $s->forward_char;
        last;
      }
      $lastnl = $s->copy;
    } else {
      # Found a \S -> lastnl is invalidated
      $lastnl = undef;
    }
  }
  # Found new start, now find new end
  $e = $i->copy;
  $lastnl = undef;
  $lastnl = $i->copy if ($curr eq "\n" and
                         $self->_get_newline_state_at_iter($e));
  while (1) {
    if (not $e->forward_find_char($lookfor)) {
      $e = $self->{Text}->get_buffer->get_end_iter;
      last;
    } elsif ($FOUNDNL) {
      if (not $self->_get_newline_state_at_iter($s)) {
        $lastnl = undef;
        next;
      } elsif (defined($lastnl)) {
        $e = $lastnl;
        last;
      }
      $lastnl = $e->copy;
      next;
    }
    $lastnl = undef;
  }
  return ($s, $e);
}

# _get_newline_state_at_iter - true -> raw newline, can be used for paragraph
# searching, false -> 'asis' newline, cannot be used for paragraph searching
sub _get_newline_state_at_iter {
  my $self = shift;
  my ($i) = @_;
  for my $tag ($i->get_tags) {
    next if not $self->_is_my_tag($tag);
    my $name = $self->_short_tag_name($tag);
    return 0 if $name eq 'asis' or $name eq 'pre';
  }
  return 1;
}

sub _get_inter_paragraph_bounds_for_iter {
  my $self = shift;
  my ($i) = @_;
  my $s = $i->copy;
  my $e = $i->copy;
  $e->forward_char;
  my $curr = $s->get_slice($e);
  my $lastnl = ($curr eq "\n" ? $s->copy : undef);
  my $FOUNDNL = 0;
  my $lookfor = sub {
    $FOUNDNL = ($_[0] eq "\n");
    return (($_[0] eq "\n") or ($_[0] =~ /\S/));
  };
  while (1) {
    if (not $s->backward_find_char($lookfor)) {
      if (not defined($lastnl)) {
        $s = $self->{Text}->get_buffer->get_start_iter;
      } else {
        $s = $lastnl;
        $s->forward_char;
      }
    } elsif ($FOUNDNL) {
      if (not $self->_get_newline_state_at_iter($s)) {
        # counts as \S!
        die "Invalid use of _get_inter_paragraph_bounds_for_iter"
          if not defined $lastnl;
        $s = $lastnl;
        $s->forward_char;
      } else {
        $lastnl = $s->copy;
        next;
      }
    } else { # Found a \S!
      die "Invalid use of _get_inter_paragraph_bounds_for_iter"
        if not defined $lastnl;
      $s = $lastnl;
      $s->forward_char;
    }
    last;
  }
  $lastnl = ($curr eq "\n" ? $i->copy : undef);
  $e = $i->copy;
  while (1) {
    if (not $e->forward_find_char($lookfor)) {
      if (not defined($lastnl)) {
        $e = $self->{Text}->get_buffer->get_end_iter;
      } else {
        $e = $lastnl;
        $e->forward_char;
      }
    } elsif ($FOUNDNL) {
      if (not $self->_get_newline_state_at_iter($e)) {
        # Counts as \S!
        die "Invalid use of _get_inter_paragraph_bounds_for_iter"
          if not defined $lastnl;
        $e = $lastnl;
        $e->forward_char;
      } else {
        $lastnl = $e->copy;
        next;
      }
    } else { # Found a \S!
      die "Invalid use of _get_inter_paragraph_bounds_for_iter"
        if not defined $lastnl;
      $e = $lastnl;
      $e->forward_char;
    }
    last;
  }
  return ($s, $e);
}

sub _merge_tags {
  my $self = shift;
  my ($user, $auto) = @_;
  # AUTO overrides USER tags
  my @stack;
  my $ui = 0;
  my $ustart = undef;
  for my $ai (0..(scalar(@$auto) - 1)) {
    if ($ui >= scalar(@$user)) {
      push @stack, $auto->[$ai];
      next;
    }
    my $start = (defined($ustart) ? $ustart : $user->[$ui]{Start});
    while ($ui < scalar(@$user) and $user->[$ui]{End} <= $auto->[$ai]{Start}) {
      push @stack, {Start => $start,
                    End => $user->[$ui]{End},
                    Tags => {%{$user->[$ui]{Tags}}}};
      $ustart = undef;
      ++$ui;
      $start = ($ui < scalar(@$user) ? $user->[$ui]{Start} : undef);
    }
    if ($ui >= scalar(@$user)) {
      push @stack, $auto->[$ai];
      next;
    }
    if ($start >= $auto->[$ai]{End}) {
      push @stack, $auto->[$ai];
      next;
    }
    if ($start < $auto->[$ai]{Start}) {
      push @stack, {Start => $start,
                    End => $auto->[$ai]{Start},
                    Tags => {%{$user->[$ui]{Tags}}}};
    }
    $ustart = $auto->[$ai]{End};
    if ($ustart >= $user->[$ui]{End}) {
      $ustart = undef;
      ++$ui;
    }
    push @stack, $auto->[$ai];
  }
  for my $i ($ui..(scalar(@$user) - 1)) {
    if (defined($ustart)) {
      push @stack, {Start => $ustart,
                    End   => $user->[$i]{End},
                    Tags  => {%{$user->[$i]{Tags}}}};
      $ustart = undef;
    } else {
      push @stack, $user->[$i];
    }
  }
  return @stack;
}

sub _get_auto_tags {
  my $self = shift;
  my ($s, $e) = $self->{Text}->get_buffer->get_bounds;
  my @stack = ();
  my ($FOUNDNL, $FOUNDWS, $SAWS) = (0, 0, 0);
  my $find = sub {
    $FOUNDNL = $_[0] eq "\n";
    $FOUNDWS = $_[0] =~ /\s/;
    $SAWS = 1 if not $SAWS and $_[0] =~ /\S/;
    return ($FOUNDNL or $FOUNDWS);
  };
  my $lastnl = undef;
  my $pstart = undef;
  my $wsstart = undef;
  my $lastws = undef;
  while (1) {
    ($FOUNDNL, $FOUNDWS, $SAWS) = (0, 0, 0);
    last if $s->equal($e) or not $s->forward_find_char($find);
    if (not $self->_get_newline_state_at_iter($s)) {
      # This isn't really whitespace or a newline, so process open tags
      if (defined($pstart)) {
        push @stack, {Start => $pstart,
                      End => $SAWS ? $lastnl : $s->get_offset,
                      Tags => {p => undef}};
      } elsif (defined($lastnl)) {
        push @stack, {Start => $lastnl,
                      End => $lastnl + 1,
                      Tags => {br => undef}};
      }
      if (defined($wsstart) and $lastws - $wsstart > 0) {
        push @stack, {Start => $wsstart,
                      End => $lastws + 1,
                      Tags => {ws => undef}};
      }
      ($pstart, $lastnl, $wsstart, $lastws) = (undef, undef, undef, undef);
      next;
    }
    # a nl or space here!
    if ($SAWS) {
      # We passed a \S, so handle any existing newlines/paras/ws
      if (defined($pstart)) {
        push @stack, {Start => $pstart,
                      End => $lastnl + 1,
                      Tags => {p => undef}};
      } elsif (defined($lastnl)) {
        push @stack, {Start => $lastnl,
                      End => $lastnl + 1,
                      Tags => {br => undef}};
      }
      if (defined($wsstart) and $lastws - $wsstart > 0) {
        push @stack, {Start => $wsstart,
                      End => $lastws + 1,
                      Tags => {ws => undef}};
      }
      ($pstart, $lastnl, $wsstart, $lastws) = (undef, undef, undef, undef);
    }
    if ($FOUNDNL) {
      if (defined($pstart)) {
        # Continuing a paragraph
        $lastnl = $s->get_offset;
        next;
      } elsif (defined($lastnl)) {
        # New paragraph break!
        $pstart = $lastnl;
        $lastnl = $s->get_offset;
      } else {
        # Found a newline!
        $lastnl = $s->get_offset;
      }
      if (defined($wsstart) and $lastws - $wsstart > 0) {
        push @stack, {Start => $wsstart,
                      End => $lastws + 1,
                      Tags => {ws => undef}};
      }
      ($wsstart, $lastws) = (undef, undef);
      # WS to process?
    } elsif ($FOUNDWS) {
      if (defined($wsstart)) {
        $lastws = $s->get_offset;
      } else {
        $wsstart = $lastws = $s->get_offset;
      }
    }
  }
  # anything left open?
  if (defined($pstart)) {
    push @stack, {Start => $pstart,
                  End => $lastnl + 1,
                  Tags => {p => undef}};
  } elsif (defined($lastnl)) {
    push @stack, {Start => $lastnl,
                  End => $lastnl + 1,
                  Tags => {br => undef}};
  }
  if (defined($wsstart) and $lastws - $wsstart > 0) {
    push @stack, {Start => $wsstart,
                  End => $lastws + 1,
                  Tags => {ws => undef}};
  }
  return @stack;
}

sub _get_user_tags {
  my $self = shift;
  my ($s, $e) = $self->{Text}->get_buffer->get_bounds;
  my @stack = ({Start => undef,
                End   => undef,
                Tags  => {}});
  while (1) {
    last if $s->equal($e);
    # This is the end of the previous tag group too
    if (defined($stack[-1]{Start})) {
      $stack[-1]{End} = $s->get_offset;
      push @stack, {Start => undef,
                    End   => undef,
                    Tags  => {}};
    }
    for my $tag ($s->get_tags) {
      next if not $self->_is_my_tag($tag);
      my $name = $self->_short_tag_name($tag);
      next if not exists $TAGS{$name};
      $stack[-1]{Start} = $s->get_offset if not defined $stack[-1]{Start};
      my $val;
      if (exists $tag->{Target}) {
        $val = $tag->{Target};
      } elsif ($TAGS{$name}{ArgumentCount} > 0) {
        $val = [$self->_tag_args($tag, $TAGS{$name}{ArgumentCount})];
      }
      $stack[-1]{Tags}{$name} = $val;
    }
    last if not $s->forward_to_tag_toggle(undef);
  }
  if (defined($stack[-1]{Start})) {
    $stack[-1]{End} = $s->get_offset;
  } else {
    pop(@stack);
  }
  return @stack;
}

sub _set_cursor {
  my $self = shift;
  my ($x, $y) = @_;
  ($x, $y) = $self->{Text}->window_to_buffer_coords('widget',
                                                    $self->{Text}->get_pointer)
    if not defined $x;
  my $iter = $self->{Text}->get_iter_at_location($x, $y);
  return unless defined $iter;
  my ($target);
  for my $tag ($iter->get_tags) {
    next if not $self->_is_my_tag($tag) or not exists $tag->{Target};
    $target = $tag->{Target};
    last;
  }
  my $cursor = defined($target) ? 'Link': 'Text' ;
  if ($cursor ne $self->{Cursor}{Current}) {
    $self->{Cursor}{Current} = $cursor;
    $self->{Text}->get_window('text')->set_cursor($self->{Cursor}{$cursor});
    if ($cursor eq 'Text') {
      $self->_tooltip_hide;
    } else {
      $self->_tooltip_text($target);
      $self->_tooltip_show($x, $y);
    }
  } elsif ($cursor eq 'Link' and $self->{CurrentLink} ne $target) {
    $self->_tooltip_hide;
    $self->_tooltip_text($target);
    $self->_tooltip_show($x, $y);
  }
  $self->{CurrentLink} = $target;
}

# Tags.
# Tags all have a simple name (just alphanumerics, no punctiation at all) which
# is used as a key to the %TAGS hash. Each value is a hashref with the 
# following keys/values:
#   Class: either 'font' or 'paragraph'. Paragraph class tags affect an entire
#          paragraph, while font class tags only affect their immediate area
#          (be that the current selection or the currect active modes)
#   Look: the properties of the text tag for this tag. Not all tags will
#         equate to an actual text tag (the clear tag for instance just holds
#         code on what to do when the Clear button is hit), but any tag that
#         should apply a style to the text should have a Look key.
#   Multi: true or false, this indicates whether the tag is a definition that
#          is to be used to create text tags that are named with at least one
#          argument. This is for tags that can be applied incrementally, or
#          whose look depends on an argument (for example, indent and font
#          respectively).
#   ArgumentCount: Some tags have arguments (for instance, the size tag takes
#                  the numeric size as an argument). For parsing and output
#                  purposes, the number of those arguments must be kept in the
#                  ArgumentCount key. If a tag has no arguments, this key
#                  should not be present.
#   Group: For tags that belong to a group (of which only one should be applied
#          at a time), this key has an arrayref as a value, each element of
#          which is the name of the other tags in the group.
#   Default: For group tags, this specifies which tag should be turned on if
#            all the other tags are turned off.
#   Activate: For tags that are connected to non-toggle buttons, this key holds
#             a coderef to be run when the button is clicked. Arguments are
#             the WYSIWYG widget, the button name, and the start and end iters
#             of the affected area of text.
#   ToggleOn: For tags that are connected to toggle buttons and that are marked
#             as Multi, this key holds a coderef to be run when the button is
#             toggled to the ON position. Like Activate, the arguments are the
#             WYSIWYG widget, the button name and the start and end iters of
#             the affected area of text.
#   ToggleOff: As for ToggleOn, but called when the button is toggled to the
#              OFF position.
BEGIN {
  %TAGS = (clear         =>
             # Fake tag to hold action for the 'Clear' buttons
             {Class   => 'font',
              Activate => sub {
                my $self = shift;
                my ($bname, $s, $e) = @_;
                $self->_clear_font_formatting($s, $e);
              }},
              
           # 'bold' - makes the text bold.
           # Used by the 'Bold' button (a toggle)
           bold          => {Class   => 'font',
                             Look    => {weight => PANGO_WEIGHT_BOLD}},
                             
           # 'italic' - makes the text italic.
           # Used by the 'Italic' button (a toggle)
           italic        => {Class   => 'font',
                             Look    => {style => 'italic'}},
                             
           # 'underline' - makes the text underlined.
           # off asis. Used by the 'Underline' button (a toggle)
           underline     => {Class   => 'font',
                             Look    => {underline => 'single'}},

           # 'strikethrough' - makes the text struck.
           # off asis. Used by the 'Strike' button (a toggle)
           strikethrough => {Class   => 'font',
                             Look    => {strikethrough => 1}},

           superscript   => {Class   => 'font',
                             Multi   => 1,
                             ArgumentCount => 2,
                             ToggleOn => sub {
                               my $self = shift;
                               my ($bname, $s, $e) = @_;
                               $self->_superscript_on($s, $e);
                             },
                             ToggleOff => sub {
                               my $self = shift;
                               my ($bname, $s, $e) = @_;
                               $self->_superscript_off($s, $e);
                             }},

           subscript     => {Class   => 'font',
                             Multi   => 1,
                             ArgumentCount => 2,
                             ToggleOn => sub {
                               my $self = shift;
                               my ($bname, $s, $e) = @_;
                               $self->_subscript_on($s, $e);
                             },
                             ToggleOff => sub {
                               my $self = shift;
                               my ($bname, $s, $e) = @_;
                               $self->_subscript_off($s, $e);
                             }},

           link          =>
             {Class     => 'font',
              Multi     => 1, # ie, create link_0, link_1 etc instead of link
              Look      => {underline  => 'single',
                            foreground => 'blue'},
              ToggleOn  => sub {
                my $self = shift;
                my ($bname, $s, $e) = @_;
                $self->_link_on($s, $e);
              },
              ToggleOff => sub {
                my $self = shift;
                my ($bname, $s, $e) = @_;
                $self->_link_off($s, $e);
              }},

           # 'left' - A paragraph tag, sets left justification. This is on
           #          by default, and belongs to a group including 'right' and
           #          'center' - turning left on turns right and center off.
           #          Turning it off turns it back on if right and center are
           #          off. Used by the Left button (a toggle)
           left          => {Class   => 'paragraph',
                             Look    => {justification => 'left'},
                             Group   => [qw(right center fill)],
                             Default => 'left'},

           # 'right' - A paragraph tag, sets right justification. This 
           #           belongs to a group including 'left' and
           #           'center' - turning right on turns left and center off.
           #           Turning it off turns left on. Used by the Right button
           #           (a toggle)
           right         => {Class   => 'paragraph',
                             Look    => {justification => 'right'},
                             Group   => [qw(left center fill)],
                             Default => 'left'},

           # 'center' - A paragraph tag, sets centre justification. This 
           #           belongs to a group including 'left' and 'right' -
           #           turning center on turns left and right off.
           #           Turning it off turns left on. Used by the Center button
           #           (a toggle)
           center        => {Class   => 'paragraph',
                             Look    => {justification => 'center'},
                             Group   => [qw(left right fill)],
                             Default => 'left'},

           fill          => {Class   => 'paragraph',
                             Look    => {justification => 'fill'},
                             Group   => [qw(left right center)],
                             Default => 'left'},

           indent        => {Class => 'paragraph',
                             ArgumentCount => 1},
           
           indentup      =>
             {Class    => 'paragraph',
              Multi    => 1,
              Activate => sub {
                my $self = shift;
                my ($bname, $s, $e) = @_;
                $self->_indent_up($s, $e);
              }},

           indentdown    =>
             {Class    => 'paragraph',
              Multi    => 1,
              Activate => sub {
                my $self = shift;
                my ($bname, $s, $e) = @_;
                $self->_indent_down($s, $e);
              }},

           # 'h1' to 'h5' - headings. Each is a member of the heading drop
           #                down menu.
           h1            => {Class   => 'paragraph',
                             Look    => {weight => PANGO_WEIGHT_BOLD,
                                         scale  => 1.15 * 4}},
           h2            => {Class   => 'paragraph',
                             Look    => {weight => PANGO_WEIGHT_BOLD,
                                         scale  => 1.15 * 3}},
           h3            => {Class   => 'paragraph',
                             Look    => {weight => PANGO_WEIGHT_BOLD,
                                         scale  => 1.15 * 2}},
           h4            => {Class   => 'paragraph',
                             Look    => {weight => PANGO_WEIGHT_BOLD,
                                         scale  => 1.15}},
           h5            => {Class   => 'paragraph',
                             Look    => {weight => PANGO_WEIGHT_BOLD,
                                         scale  => 1.15,
                                         style  => 'italic'}},

           size          => {Class   => 'font',
                             Multi   => 1,
                             ArgumentCount => 1},
           sizeup        => {Class   => 'font',
                             Activate => sub {
                               my $self = shift;
                               $self->_increase_size;
                             }},
           sizedown      => {Class   => 'font',
                             Activate => sub {
                               my $self = shift;
                               $self->_decrease_size;
                             }},

           font          => {Class   => 'font',
                             Multi   => 1,
                             ArgumentCount => 1},

           undo          => {Class   => 'undo',
                             Activate => sub {
                               my $self = shift;
                               $self->undo;
                             }},

           redo          => {Class   => 'undo',
                             Activate => sub {
                               my $self = shift;
                               $self->redo;
                             }},
           # 'pre' - 'codifies' the included text, but other tags are honoured
           pre           => {Class   => 'font',
                             Look    => {family => 'Courier'}},

           # 'asis' - leaves the text exactly as is when exported
           asis          => {Class   => 'font',
                             Look    => {'background-full-height' => 1,
                                         background => 'blue',
                                         foreground => 'yellow'}});
}

# Buttons
# Defines buttons that appear in the toolbar. The keys are button names (they
# will be stored under the Buttons->NAME key of the WYSIWYG), values are
# hashrefs with the following key/value pairs:
#   Type: what type of button to create. Valid options are 'button' (standard
#         clickable button), 'toggle' (toggle button), 'menu' (formatted menu
#         item), 'size' (numeric menu item) and 'font' (specialised menu)
#   Tag: a tag in the %TAGS hash that this button applies in some way. Note
#        that this might not be a direct mapping - it can just point to a tag
#        that has the right type of information, but isn't used directly.
#   TipText: a string, used to set tooltip text for the button.
#   Image: a stock image name to display on the button (for button and toggle
#          types only)
#   Label: a string to display on the buttons. CURRENTLY WILL REPLACE ANY
#          IMAGE GIVEN!
#   On: boolean, whether the toggle should be active once created
#   Tags: for menu types, this defines the menu items. Each element should be
#         an arrayref, the first element of which should be a tag name (used
#         to describe what to do when the menu item is chosen, and what the
#         menu item should look like), and the second element should be the
#         display text. If the tag name doesn't exist, it will be assumed that
#         that menu item is for the 'default' look, and no style will be
#         applied
#   Default: For menu types, this defines which item in the menu is the default
#   Width: for font types, this defines how wide (in characters) the menu
#          button should be. The menu button will show '...' at the end of
#          too-long items (the menu itself will still show them full width).
BEGIN {
  %BUTTONS = (Clear      => {Type   => 'button',
                             Tag    => 'clear',
                             Image  => 'gtk-clear',
                             TipText => 'Clear Formatting'},
              Bold       => {Tag    => 'bold',
                             Image  => 'gtk-bold',
                             Type   => 'toggle',
                             TipText => 'Bold'},
              Italic     => {Tag    => 'italic',
                             Image  => 'gtk-italic',
                             Type   => 'toggle',
                             TipText => 'Italic'},
              Underline  => {Tag    => 'underline',
                             Image  => 'gtk-underline',
                             Type   => 'toggle',
                             TipText => 'Underline'},
              Strike     => {Tag    => 'strikethrough',
                             Image  => 'gtk-strikethrough',
                             Type   => 'toggle',
                             TipText => 'Strikethrough'},
              Link       => {Tag    => 'link',
                             Image  => 'gtk-network',
                             Type   => 'toggle',
                             TipText => 'Add/Remove Link'},
              Left       => {Tag    => 'left',
                             Image  => 'gtk-justify-left',
                             Type   => 'toggle',
                             On     => 1,
                             TipText => 'Left Justify'},
              Center     => {Tag    => 'center',
                             Image  => 'gtk-justify-center',
                             Type   => 'toggle',
                             TipText => 'Center Justify'},
              Right      => {Tag    => 'right',
                             Image  => 'gtk-justify-right',
                             Type   => 'toggle',
                             TipText => 'Right Justify'},
              Fill       => {Tag    => 'fill',
                             Image  => 'gtk-justify-fill',
                             Type   => 'toggle',
                             TipText => 'Fill Justify'},
              IndentUp   => {Tag    => 'indentup',
                             Image  => 'gtk-indent',
                             Type   => 'button',
                             TipText => 'Increase Indent'},
              IndentDown => {Tag    => 'indentdown',
                             Image  => 'gtk-unindent',
                             Type   => 'button',
                             TipText => 'Decrease Indent'},
              Pre        => {Tag    => 'pre',
                             Label  => ' P ',
                             Type   => 'toggle',
                             TipText => 'Keep Whitespace As Is'},
              AsIs       => {Tag    => 'asis',
                             Image  => 'gtk-execute',
                             Type   => 'toggle',
                             TipText => 'Code Mode'},
              Heading    => {Type    => 'menu',
                             Default => 'Normal',
                             Tag     => 'h1', # Typical tag
                             Tags    => [[h1 => 'Heading 1'],
                                         [h2 => 'Heading 2'],
                                         [h3 => 'Heading 3'],
                                         [h4 => 'Heading 4'],
                                         [h5 => 'Heading 5'],
                                         [h0 => 'Normal']]},
              Size       => {Type     => 'size',
                             Default  => undef,
                             Tag      => 'size'},
              SizeUp     => {Type     => 'button',
                             Image    => 'gtk-zoom-in',
                             Tag      => 'sizeup',
                             TipText => 'Increase Font Size'},
              SizeDown   => {Type     => 'button',
                             Image    => 'gtk-zoom-out',
                             Tag      => 'sizedown',
                             TipText => 'Decrease Font Size'},
              Font       => {Type     => 'font',
                             Width    => 20,
                             Tag      => 'font', ## FOR DISABLING!
                             Default  => undef,
                             Tags     => undef},
              Sub        => {Type     => 'toggle',
                             Image    => 'gtk-go-down',
                             Tag      => 'subscript',
                             TipText => 'Subscript'},
              Super      => {Type     => 'toggle',
                             Image    => 'gtk-go-up',
                             Tag      => 'superscript',
                             TipText => 'Superscript'},
#              Case       => {Type     => 'button',
#                             Image    => 'gtk-cancel'},
#              Colour     => {Type     => 'button',
#                             Image    => 'gtk-select-color'},
              Undo       => {Type     => 'button',
                             Tag      => 'undo',
                             Image    => 'gtk-undo',
                             TipText  => 'Undo'},
              Redo       => {Type     => 'button',
                             Tag      => 'redo',
                             Image    => 'gtk-redo',
                             TipText  => 'Redo'});

}
  
BEGIN {
  package Gtk2::Ex::WYSIWYG::FormatMenu;

  use strict;
  use Gtk2;
  use Gtk2::Pango;
  use Glib::Object::Subclass
    Gtk2::Button::,
        signals => {format_selected => {param_types => ['Glib::String',
                                                        'Glib::Scalar']}};

  sub INIT_INSTANCE {
    my $self = shift;
    my $hbox = Gtk2::HBox->new(0, 0);
    $self->{Label} = Gtk2::Label->new();
    $self->{Options} = [];
    $self->{Default} = undef;
    $self->{Label}->set_alignment(0, 0.5);
    my $bar = Gtk2::VSeparator->new;
    my $arrow = Gtk2::Arrow->new('down', 'none');
    $hbox->pack_start($self->{Label}, 1, 1, 0);
    $hbox->pack_start($bar, 0, 0, 2);
    $hbox->pack_start($arrow, 0, 0, 0);
    $hbox->show_all;
    $self->add($hbox);
    $self->signal_connect(clicked => sub {$self->_show_menu(@_)});
  }

  sub set_inconsistant {
    my $self = shift;
    $self->{Label}->set_text('');
  }

  sub get_inconsistant {
    my $self = shift;
    return $self->{Label}->get_text =~ /^\s*\z/;
  }

  sub set_text {
    my $self = shift;
    my ($txt) = @_;
    $self->{Label}->set_text($txt);
    $self->{TT}->set_tip($self, $txt) if defined $self->{TT};
    return 1;
  }

  sub get_text {
    my $self = shift;
    $self->{Label}->get_text;
  }

  sub set_default {
    my $self = shift;
    my ($default) = @_;
    if (not defined($default)) {
      $self->{Default} = undef;
      return 1;
    }
    for my $opt (@{$self->{Options}}) {
      next if $opt->[0] ne $default;
      $self->{Default} = $default;
      return 1;
    }
    die "Default string '$default' does not match any available options";
  }

  sub get_default {
    my $self = shift;
    return $self->{Default};
  }

  sub set_options {
    my $self = shift;
    my @opts = @_;
    for my $opt (@opts) {
      # Need DISPLAY, DAT, and STYLE - STR, ANY, HASHREF
      die "Option style must be a hashref or undef"
        if defined($opt->[2]) and ref($opt->[2]) ne 'HASH';
    }
    $self->{Options} = [];
    for my $opt (@opts) {
      push @{$self->{Options}}, ["$opt->[0]", $opt->[1], $opt->[2]];
    }
    return 1;
  }

  sub get_options {
    my $self = shift;
    return map({[$_->[0], $_->[1], ref($_->[2]) ? {%{$_->[2]}} : undef]}
               @{$self->{Options}});
  }

  sub get_tool_tip {
    my $self = shift;
    return $self->{TT};
  }

  sub set_tool_tip {
    my $self = shift;
    my ($TT) = @_;
    $self->{TT} = $TT;
    $self->{TT}->set_tip($self, $self->{Label}->get_text)
      if defined $self->{TT};
  }

  sub set_width_chars {
    my $self = shift;
    $self->{Label}->set_width_chars(@_);
  }

  sub get_width_chars {
    my $self = shift;
    $self->{Label}->get_width_chars(@_);
  }

  sub set_ellipsize {
    my $self = shift;
    $self->{Label}->set_ellipsize(@_);
  }

  sub get_ellipsize {
    my $self = shift;
    $self->{Label}->get_ellipsize(@_);
  }

  sub _show_menu {
    my $self = shift;
    return 0 if not scalar(@{$self->{Options}});
    my $menu = Gtk2::Menu->new;
    my $match = $self->{Label}->get_text;
    my $sel = undef;
    my $i = 0;
    for my $opt (@{$self->{Options}}) {
      my ($label, $dat, $style) = @$opt;
      if ($label eq $match) {
        $sel = $i;
      } elsif (not defined $sel and defined $self->{Default} and
               $label eq $self->{Default}) {
        $sel = $i;
      }
      ++$i;
      my $item = Gtk2::MenuItem->new_with_label('');
      if (defined($style)) {
        my @slist;
        for my $attr (keys %$style) {
          if ($attr eq 'scale') {
            my $s = $self->get_pango_context->get_font_description->
              get_size;
            $s = int($s * $style->{$attr});
            push @slist, "size=\"$s\"";
          } elsif ($attr eq 'family') {
            push @slist, "font_family=\"$style->{$attr}\"";
          } else {
            push @slist, "$attr=\"$style->{$attr}\"";
          }
        }
        my $lab = $item->get_child;
        if (scalar(@slist)) {
          my $vis = $label;
          $vis =~ s/</&lt;/g;
          $lab->set_markup("<span " . join(" ", @slist) . ">$vis</span>");
        } else {
          $lab->set_text($label);
        }
      } else {
        $item->get_child->set_text($label);
      }
      $item->signal_connect(activate => sub {
                              $self->_item_selected($label, $dat);
                            });
      $item->show;
      $menu->append($item);
    }
    $sel = 0 if not defined $sel;
    $menu->set_active($sel);
    # Popup the menu
    $menu->popup(undef, undef, undef, undef, $self, undef);
    $menu->popup(undef, undef, '_menu_pos', $self, $self, undef);
    my ($mx, $my) = $menu->get_size_request;
    my ($bx, $by) = $self->get_size_request;
    $menu->set_size_request($bx, -1) if $mx < $bx;
    my $active = $menu->get_active;
    ($active) = $menu->get_children if not defined $active;
    $menu->select_item($active);
    return 0;
  }

  # !!! _menu_pos assumes that the menu _HAS ALREADY BEEN POPPED UP!_
  # This is so allocation details are set already.
  sub _menu_pos {
    my ($menu, $evx, $evy, $self) = @_;
    my ($px, $py) = $self->get_pointer;
    my ($x, $y, $w, $h) = $self->allocation->values;
    my ($rx, $ry) = $self->window->get_origin;
    my $active = $menu->get_active;
    ($active) = $menu->get_children if not defined $active;
    my ($ix, $iy, $iw, $ih) = $active->allocation->values;
    return ($rx + $x, $evy - $iy - ($ih / 2));
  }

  sub _item_selected {
    my $self = shift;
    my ($disp, $dat) = @_;
    $self->{Label}->set_text($disp);
    $self->{TT}->set_tip($self, $disp) if defined $self->{TT};
    $self->signal_emit(format_selected => $disp, $dat);
    return 0;
  }
}

BEGIN {
  package Gtk2::Ex::WYSIWYG::SizeMenu;

  use strict;
  use Gtk2;
  use Gtk2::Pango;
  use Glib::Object::Subclass
    Gtk2::ComboBoxEntry::,
        signals => {size_selected => {param_types => ['Glib::UInt']}};

  my @DEFAULT_SIZES = qw(8 9 10 11 12 14 16 18 20 22 24 26 28 36 48 72);
  sub INIT_INSTANCE {
    my $self = shift;
    my $model = Gtk2::ListStore->new('Glib::String');
    for my $val (@DEFAULT_SIZES) {
      $model->set($model->append, 0, $val);
    }
    $self->set_model($model);
    $self->set_text_column(0);
    my $ent = $self->get_child; # -> validation!
    $ent->set_max_length(4); # 1 to 1024pt
    $ent->set_width_chars(4);
    $self->signal_connect(changed => sub {$self->_changed(@_)});
  }

  sub set_inconsistant {
    my $self = shift;
    $self->get_child->set_text('');
  }

  sub get_inconsistant {
    my $self = shift;
    return $self->get_child->get_text =~ /^\s*\z/;
  }

  sub set_value {
    my $self = shift;
    my ($val) = @_;
    die "Cannot set value to non-numeric" if $val =~ /\D/ or not length($val);
    die "Cannot set value to zero" if not $val;
    die "Maximum value is 1024" if $val > 1024;
    $self->get_child->set_text($val);
    $self->{OldValue} = $val;
    return 1;
  }

  sub get_value {
    my $self = shift;
    my $res = $self->get_child->get_text;
    $res = 1 if not $res;
    return $res;
  }

  sub up_value {
    my $self = shift;
    my $curr = $self->get_value;
    my $new = $self->next_value_up($curr);
    return if $new == $curr;
    $self->set_value($new);
  }

  sub down_value {
    my $self = shift;
    my $curr = $self->get_value;
    my $new = $self->next_value_down($curr);
    return if $new == $curr;
    $self->set_value($new);
  }

  sub next_value_up {
    my $self = shift;
    my ($from) = @_;
    return 1024 if $from >= 1024;
    return $from + 1
      if $from < $DEFAULT_SIZES[0] or $from >= $DEFAULT_SIZES[-1];
    for my $i (0..(scalar(@DEFAULT_SIZES) - 2)) {
      next if $DEFAULT_SIZES[$i] < $from;
      return $DEFAULT_SIZES[$i + 1] if $from == $DEFAULT_SIZES[$i];
      last;
    }
    return $from + 1;
  }

  sub next_value_down {
    my $self = shift;
    my ($from) = @_;
    return 1 if $from <= 1;
    return $from - 1
      if $from <= $DEFAULT_SIZES[0] or $from > $DEFAULT_SIZES[-1];
    for my $i (1..(scalar(@DEFAULT_SIZES) - 1)) {
      next if $DEFAULT_SIZES[$i] < $from;
      return $DEFAULT_SIZES[$i - 1] if $from == $DEFAULT_SIZES[$i];
      last;
    }
    return $from - 1;
  }

  sub _changed {
    my $self = shift;
    return 0 if $self->{STOP};
    my $curr = $self->get_child->get_text;
    if ($curr =~ /\D/) {
      ++$self->{STOP};
      $self->get_child->set_text($self->{OldValue});
      --$self->{STOP};
      return 0
    }
    $self->{OldValue} = $curr;
    $self->signal_emit(size_selected => $self->get_child->get_text);
    return 1;
  }
}

BEGIN {
  package Gtk2::Ex::WYSIWYG::HTML;

  use strict;
  use XML::Quote;
  use constant CLEV_PARAGRAPH => 5;
  use constant CLEV_PRE       => 4;
  use constant CLEV_SPAN      => 3;
  use constant CLEV_SUPSUB    => 2;
  use constant CLEV_LINK      => 1;
  use constant CLEV_NONE      => 0;

  my (@TAGS, @FONTS);
  my ($TPOS, $HPOS, $TXT, $DEFAULT_SIZE) = (0, 0, '', 10);

  sub init {
    @TAGS = ();
    $TPOS = 0;
    $HPOS = 0;
    $TXT  = '';
  }

  sub set_fonts {
    my $class = shift;
    @FONTS = @_;
  }

  sub set_default_size {
    my $class = shift;
    $DEFAULT_SIZE = $_[0];
  }

  sub _check_start {
    my $class = shift;
    my ($pok, $preok, $spanok, $subok, $aok) = @_;
    for my $i (reverse(0..(scalar(@TAGS) - 1))) {
      for my $chk ([$pok,    [qw(P H1 H2 H3 H4 H5)]],
                   [$preok,  ['PRE']],
                   [$spanok, ['SPAN']],
                   [$subok,  [qw(SUB SUP)]],
                   [$aok,    ['A']]) {
        my ($ok, $types) = @$chk;
        next if $ok;
        for my $type (@$types) {
          return 0 if $TAGS[$i]{Type} eq $type and not defined $TAGS[$i]{End};
        }
      }
    }
    return 1;
  }

  sub _check_end {
    my $class = shift;
    my ($type, $seena, $seensub, $seenspan, $seenpre) = @_;
    my $open;
    # Paragraph tags could enclose arbitrary numbers of CLOSED font tags
    my $para = grep({$_ eq $type} qw(P H1 H2 H3 H4 H5));
    for my $ti (reverse(0..(scalar(@TAGS) - 1))) {
      my $ct = $TAGS[$ti];
      if ($ct->{Type} eq $type) {
        $open = $ct if not defined $ct->{End};
        last;
      } elsif ($ct->{Type} =~ /^H\d\z/ or $ct->{Type} eq 'P') {
        last;
      } elsif ($ct->{Type} eq 'PRE') {
        last if (not $para and $seenpre) or not defined($ct->{End});
        $seenpre = 1;
      } elsif ($ct->{Type} eq 'SPAN') {
        last if ((not $para and ($seenpre or $seenspan)) or
                 not defined($ct->{End}));
        $seenspan = 1;
      } elsif ($ct->{Type} eq 'SUB' or $ct->{Type} eq 'SUP') {
        last if ((not $para and ($seenpre or $seenspan or $seensub)) or
                 not defined($ct->{End}));
        $seensub = 1;
      } elsif ($ct->{Type} eq 'A') {
        last if ((not $para and ($seenpre or $seenspan or
                                 $seensub or $seena)) or
                 not defined($ct->{End}));
        $seena = 1;
      } else {
        last;
      }
    }
    return $open;
  }

  sub _tag_asis {
    my $class = shift;
    my ($tag) = @_;
    $TXT .= $tag;
    push @TAGS, {Type  => 'ASIS',
                 Start => $TPOS,
                 End   => $TPOS + length($tag),
                 Tags  => {asis => undef}};
    $TPOS += length($tag);
    $HPOS += length($tag);
  }

  sub _handle_open_tag {
    my $class = shift;
    my ($tag, $type, $style, $flags, $look) = @_;
    if (not $class->_check_start(@$flags)) {
      $class->_tag_asis($tag);
      return;
    }
    my $stags = (defined($style) ? $class->_parse_style($style) : {});###
    if (not defined($stags)) {
      $class->_tag_asis($tag);
      return;
    }
    for my $k (keys %$look) {
      $stags->{$k} = $look->{$k};
    }
    push @TAGS, {Type  => $type,
                 Start => $TPOS,
                 Tags  => $stags};
    $HPOS += length($tag);
  }

  sub _handle_close_tag {
    my $class = shift;
    my ($tag, $type, $flags, $nl) = @_;
    my $open = $class->_check_end($type, @$flags);
    if (defined($open)) {
      $open->{End} = $TPOS;
      $HPOS += length($tag);
      if ($nl) {
        $TXT .= "\n";
        ++$TPOS;
      }
      return;
    }
    $class->_tag_asis($tag);
  }

  sub _parse_style {
    my $class = shift;
    my ($style) = @_;
    my %tags;
    for my $part (grep {$_ !~ /^\s*\z/} split(/\s*;\s*/, $style)) {
      $part =~ s/(?:^\s+)|(\s+\z)//;
      my ($key, $val) = split(/\s*:\s*/, $part, 2);
      $key = lc($key);
      if ($key eq 'font-weight') {
        return undef if lc($val) ne 'bold';
        $tags{bold} = undef;
      } elsif ($key eq 'font-style') {
        return undef if lc($val) ne 'italic';
        $tags{italic} = undef;
      } elsif ($key eq 'font-size') {
        return undef if $val !~ /^(\d+(?:\.\d+)?)[Ee][Mm]\z/;
        $tags{size} = [int($1 * 16)];
      } elsif ($key eq 'font-family') {
        return undef if not grep {$_ eq $val} @FONTS;
        $tags{font} = [$val];
      } elsif ($key eq 'text-decoration') {
        for my $sval (grep {$_ !~ /^\s*\z/} split(/\s+/, lc($val))) {
          if ($sval eq 'underline') {
            $tags{underline} = undef;
          } elsif ($sval eq 'line-through') {
            $tags{strikethrough} = undef;
          } else {
            return undef;
          }
        }
      } elsif ($key eq 'text-align') {
        $val = lc($val);
        return undef if not grep {$_ eq $val} qw(left center right justify);
        $val = 'fill' if $val eq 'justify';
        $tags{$val} = undef;
      } elsif ($key eq 'margin-left' or $key eq 'margin-right') {
        return undef if lc($val) !~ /^(\d+)px\z/;
        my $cnt = $1;
        $cnt /= 32;
        return undef if int($cnt) != $cnt;
        $tags{indent} = [$cnt];
      } else {
        return undef;
      }
    }
    return \%tags;
  }

  sub _html_style {
    my $class = shift;
    my ($style) = @_;
    my @sstyle;
    push @sstyle, 'font-weight:bold' if exists $style->{bold};
    push @sstyle, 'font-style:italic' if exists $style->{italic};
    push @sstyle, sprintf('font-size:%.3fem',
                          ($style->{size}[0] / 16))#$DEFAULT_SIZE))
      if exists $style->{size};
    push @sstyle, "font-family:$style->{font}[0]"
      if exists $style->{font};
    my @deco;
    push @deco, 'underline' if exists $style->{underline};
    push @deco, 'line-through' if exists $style->{strikethrough};
    push @sstyle, 'text-decoration:' . join(' ', @deco) if scalar(@deco);
    return @sstyle;
  }

  sub _get_html_tag_changelevel {
    my $self = shift;
    my ($new, $old) = @_;
    return CLEV_PARAGRAPH
      if (not defined($old->{paragraph_type}) or
          $old->{paragraph_type} ne $new->{paragraph_type} or
          $old->{align} ne $new->{align} or
          $old->{indent} ne $new->{indent});
    return CLEV_PRE if exists($old->{pre}) != exists($new->{pre});
    for my $stag (qw(bold italic underline strikethrough)) {
      return CLEV_SPAN if exists($old->{$stag}) != exists($new->{$stag});
    }
    for my $stag (qw(font size)) {
      return CLEV_SPAN
        if (exists($old->{$stag}) != exists($new->{$stag}) or
            (exists $old->{$stag} and $old->{$stag} ne $new->{$stag}));
    }
    return CLEV_SUPSUB
      if (exists($old->{superscript}) != exists($new->{superscript}) or
          exists($old->{subscript}) != exists($new->{subscript}));
    return CLEV_LINK
      if (exists($old->{link}) != exists($new->{link}) or
          (exists $old->{link} and $new->{link} ne $old->{link}));
    return CLEV_NONE;
  }

  sub _get_html_tag_state {
    my $class = shift;
    my ($tag) = @_;
    my $def = {paragraph_type => 'p',
               align          => undef,
               indent         => undef};
    for my $tname (keys %{$tag->{Tags}}) {
      if ($tname =~ /^h[1-5]\z/) {
        $def->{paragraph_type} = $tname;
      } elsif ($tname eq 'indent') {
        $def->{indent} = [$tag->{Tags}{$tname}];
      } elsif (grep {$_ eq $tname} qw(right center)) {
        $def->{align} = $tname;
      } elsif ($tname eq 'fill') {
        $def->{align} = 'justify';
      } else {
        $def->{$tname} = $tag->{Tags}{$tname};
      }
    }
    return $def;
  }

  sub parse {
    my $class = shift;
    my ($html) = @_;
    $class->init;
    while ($HPOS < length($html)) {
      my $char = substr($html, $HPOS, 1);
      if ($char ne '<') {
        # Slurp up to next tag
        my $txt = $char;
        ++$HPOS;
        $char = undef;
        while (1) {
          last if $HPOS >= length($html);
          $char = substr($html, $HPOS, 1);
          last if $char eq '<';
          $txt .= $char;
          ++$HPOS;
        }
        $txt = xml_dequote($txt);
        $TXT .= $txt;
        $TPOS += length($txt);
        next;
      }
      # New tag?
      my $tag = '<';
      my $j = $HPOS + 1;
      while ($j < length($html)) {
        $char = substr($html, $j++, 1);
        $tag .= $char;
        last if $char eq '>';
      }
      if (index($tag, '>') == -1) {
        $class->_tag_asis($tag);
        next;
      }
      my ($close, $type, $style, $nl, $look, $flags) =
        (0, undef, undef, 0, {}, []);
      if ($tag =~ /^<br( ?\/)?>\z/) {
        $TXT .= "\n";
        $TPOS += 1;
        $HPOS += length($tag);
        next;
      } elsif ($tag =~ /^<span\s+style=\"white-space:pre\">\z/) {
        # Self contained - other tags don't matter
        # WS Tag
        my $jump = $HPOS + length($tag);
        my $ws = '';
        # get as much whitespace as possible, then grab a </span>
        my $close = undef;
        my $ok = 0;
        while ($jump < length($html)) {
          my $char = substr($html, $jump++, 1);
          if (defined($close)) {
            $close .= $char;
            if ($close eq '</span>') {
              $ok = 1;
              last;
            }
            last if '</span>' !~ /^\Q$close/;
          } elsif ($char eq '<') {
            $close = $char;
          } elsif ($char eq "\n" or $char !~ /^\s\z/) {
            last;
          } else {
            $ws .= $char;
          }
        }
        if (not $ok) {
          $class->_tag_asis($tag);
        } else {
          $TXT .= $ws;
          $TPOS += $ws;
          $HPOS += $jump;
        }
        next;
      } elsif ($tag =~ /^<(p|h1|h2|h3|h4|h5)(?:\s+style=\"([^\"]+)\")?>\z/i) {
        ($type, $style) = (uc($1), $2);
        $flags = [0, 0, 0, 0, 0];
        $look->{$type} = undef if $type ne 'P';
      } elsif ($tag =~ /^<\/(p|h1|h2|h3|h4|h5)>\z/) {
        ($close, $type, $flags, $nl) = (1, uc($1), [0, 0, 0, 0], 1);
      } elsif ($tag eq '<pre>') {
        ($type, $flags) = ('PRE', [1, 0, 0, 0, 0]);
        $look->{pre} = undef;
      } elsif ($tag eq '</pre>') {
        ($close, $type, $flags) = (1, 'PRE', [0, 0, 0, 1]);
      } elsif ($tag =~ /^<span\s+style=\"([^\"]+)\">\z/) {
        ($type, $style, $flags) = ('SPAN', $1, [1, 1, 0, 0, 0]);
      } elsif ($tag eq '</span>') {
        ($close, $type, $flags) = (1, 'SPAN', [0, 0, 1, 1]);
      } elsif ($tag eq '<sup>' or $tag eq '<sub>') {
        $type = uc($tag);
        $type =~ s/[<>]//g;
        $look->{$type eq 'SUP' ? 'superscript' : 'subscript'} = undef;
        $flags = [1, 1, 1, 0, 0];
      } elsif ($tag eq '</sup>' or $tag eq '</sub>') {
        $close = 1;
        $type = uc($tag);
        $type =~ s/[<>]//g;
        $flags = [0, 1, 1, 1];
      } elsif ($tag =~ /^<a href=\"([^\"]+)\">\z/) {
        # There should be no open a tags
        $look->{link} = $1;
        ($type, $flags) = ('A', [1, 1, 1, 1, 0]);
      } elsif ($tag eq '</a>') {
        ($close, $type, $flags) = (1, 'A', [1, 1, 1, 1]);
      } else {
        $class->_tag_asis($tag);
        next;
      }
      if ($close) {
        $class->_handle_close_tag($tag, $type, $flags, $nl);
      } else {
        $class->_handle_open_tag($tag, $type, $style, $flags, $look);
      }
    }
    for my $i (0..(scalar(@TAGS) - 2)) {
      next if defined($TAGS[$i]{End});
      $TAGS[$i]{End} = $TAGS[$i + 1]{Start};
    }
    if (scalar(@TAGS)) {
      $TAGS[-1]{End} = $TPOS if not defined($TAGS[-1]{End});
      @TAGS = grep {scalar(keys %{$_->{Tags}})} @TAGS;
      for my $tag (@TAGS) {
        delete($tag->{Type});
      }
    }
    my ($txt, @tags) = ($TXT, @TAGS);
    $class->init;
    return ($txt, @tags);
  }
  
  sub generate {
    my $class = shift;
    my ($buf, @tags) = @_;
    my $res = '';
    if (not scalar(@tags)) {
      $res .= "<p>";
      $res .= xml_quote($buf->get_text($buf->get_bounds, 0));
      $res .= "</p>\n";
      return $res;
    }
    my @openstack;
    my $currstyle = {paragraph_type => undef,
                     indent         => undef,
                     align          => undef};
    if ($tags[0]{Start} != 0) {
      $res .= "<p>";
      push @openstack, {name => 'p',
                        type => 'paragraph'};
      $currstyle->{paragraph_type} = 'p';
    }
    my $lastpos = 0;
    for my $tag (@tags) {
      # Previous text...
      if ($lastpos != $tag->{Start}) {
        # Turn off all non-paragraph tags!
        while (scalar(@openstack)) {
          last if $openstack[-1]{type} eq 'paragraph';
          my $this = pop(@openstack);
          $res .= "</$this->{name}>";
        }
        $currstyle = {paragraph_type => $currstyle->{paragraph_type},
                      align          => $currstyle->{align},
                      indent         => $currstyle->{indent}};
        # And if there's no paragraph tag here yet?! The only way that could
        # happen is if there were no paragraph tags, and the only way that
        # could happen if it's going to be an empty, plain <p>
        if (not scalar(@openstack)) {
          push @openstack, {type => 'paragraph',
                            name => 'p'};
          $currstyle->{paragraph_type} = 'p';
          $currstyle->{align}          = undef;
          $currstyle->{indent}         = undef;
          $res .= "<p>";
        }
        $res .=
          xml_quote($buf->get_text($buf->get_iter_at_offset($lastpos),
                                   $buf->get_iter_at_offset($tag->{Start}),
                                   0));
      }
      $lastpos = $tag->{End};
      # Auto/singular tags
      if (exists $tag->{Tags}{p}) {
        # p acts as a paragraph and font terminator - nothing 'matches' it
        # ensure any open tags are closed
        while (scalar(@openstack)) {
          my $this = pop(@openstack);
          $res .= "</$this->{name}>";
          $res .= "\n" if $this->{type} eq 'paragraph';
        }
        my $txt = $buf->get_text($buf->get_iter_at_offset($tag->{Start}),
                                 $buf->get_iter_at_offset($tag->{End}), 0);
        $txt =~ s/^\n[^\n]*\n//;
        while ($txt =~ s/^[^\n]*\n[^\n]*\n//) { # Spacing paragraphs
          $res .= "<p></p>\n";
        }
        $res .= "<br />\n" if $txt =~ /\n/;
        $currstyle = {paragraph_type => undef,
                      indent         => undef,
                      align          => undef};
        next;
      } elsif (exists $tag->{Tags}{br}) {
        $res .= "<br />\n";
        next;
      } elsif (exists $tag->{Tags}{ws}) {
        $res .= "<span style=\"white-space:pre\">";
        $res .=
          xml_quote($buf->get_text($buf->get_iter_at_offset($tag->{Start}),
                                   $buf->get_iter_at_offset($tag->{End}), 0));
        $res .= "</span>";
        next;
      } elsif (exists $tag->{Tags}{asis}) {
        # Do as it says!
        $res .= $buf->get_text($buf->get_iter_at_offset($tag->{Start}),
                               $buf->get_iter_at_offset($tag->{End}), 0);
        next;
      }
      # Has our paragraphing changed? If so, close everything.
      # For paragraphing changes, we need to know: the para type, the para
      # indent and the para alignment.
      # Types are p, h1, h2, h3, h4, h5 or undef (undef == no paragraph)
      # indent is a number or nothing
      # alignment is right, center, fill or nothing
      my $newstyle = $class->_get_html_tag_state($tag);
      my $changelevel = $class->_get_html_tag_changelevel($newstyle,
                                                          $currstyle);
      if ($changelevel == CLEV_NONE) {
        $res .=
          xml_quote($buf->get_text($buf->get_iter_at_offset($tag->{Start}),
                                   $buf->get_iter_at_offset($tag->{End}), 0));
        next;
      }
      # ROLLBACK!
      {
        my @stopat;
        push @stopat, 'paragraph' if $changelevel < CLEV_PARAGRAPH;
        push @stopat, 'pre' if $changelevel < CLEV_PRE;
        push @stopat, 'span' if $changelevel < CLEV_SPAN;
        push @stopat, ('sub', 'sup') if $changelevel < CLEV_SUPSUB;
        while (scalar(@openstack)) {
          last if grep {$_ eq $openstack[-1]{type}} @stopat;
          my $this = pop(@openstack);
          $res .= "</$this->{name}>";
          $res .= "\n" if $this->{type} eq 'paragraph';
        }
      }
      # REAPPLY!
      if ($changelevel == CLEV_PARAGRAPH) {
        # <(p|h1|h2|h3|h4|h5) style="margin-left:(32 * (X + 1))px;
        #                            text-align:center|right|fill">
        $res .= "<$newstyle->{paragraph_type}";
        my @style;
        if (defined($newstyle->{indent})) {
          my $dir = 'left';
          $dir = 'right' if $newstyle->{align} eq 'right';
          push @style, ("margin-$dir:" . 32 * ($newstyle->{indent}[0] + 1) .
                        "px")
        }
        push @style, "text-align:$newstyle->{align}"
          if defined $newstyle->{align};
        $res .= " style=\"" . join(";", @style) . "\"" if scalar(@style);
        $res .= ">";
        push @openstack, {type => 'paragraph',
                          name => $newstyle->{paragraph_type}};
      }
      if ($changelevel >= CLEV_PRE and exists $newstyle->{pre}) {
        $res .= "<pre>";
        push @openstack, {type => 'pre',
                          name => 'pre'};
      }
      if ($changelevel >= CLEV_SPAN) {
        my @sstyle = $class->_html_style($newstyle);
        if (scalar(@sstyle)) {
          $res .= "<span style=\"" . join(";", @sstyle) . "\">";
          push @openstack, {type => 'span',
                            name => 'span'};
        }
      }
      if ($changelevel >= CLEV_SUPSUB) {
        if (exists $newstyle->{superscript}) {
          $res .= "<sup>";
          push @openstack, {type => 'sup',
                            name => 'sup'};
        } elsif (exists $newstyle->{subscript}) {
          $res .= "<sub>";
          push @openstack, {type => 'sub',
                            name => 'sub'};
        }
      }
      if ($changelevel >= CLEV_LINK and exists $newstyle->{link}) {
        $res .= "<a href=\"" . xml_quote($newstyle->{link}) . "\">";
        push @openstack, {type => 'link',
                          name => 'a'};
      }
      $currstyle = $newstyle;
      $res .=
        xml_quote($buf->get_text($buf->get_iter_at_offset($tag->{Start}),
                                 $buf->get_iter_at_offset($tag->{End}), 0));
    }
    my ($s, $e) = ($buf->get_iter_at_offset($tags[-1]{End}),
                   $buf->get_end_iter);
    while (scalar(@openstack)) {
      last if not $s->equal($e) and $openstack[-1]{type} eq 'paragraph';
      my $this = pop(@openstack);
      $res .= "</$this->{name}>";
      $res .= "\n" if $this->{type} eq 'paragraph';
    }
    return $res if $s->equal($e);
    if (not scalar(@openstack)) {
      $res .= "<p>";
      push @openstack, {type => 'paragraph',
                        name => 'p'};
    }
    $res .= xml_quote($buf->get_text($s, $e, 0));
    while (scalar(@openstack)) {
      my $this = pop(@openstack);
      $res .= "</$this->{name}>";
      $res .= "\n" if $this->{type} eq 'paragraph';
    }
    return $res;
  }
}

1;
__END__
