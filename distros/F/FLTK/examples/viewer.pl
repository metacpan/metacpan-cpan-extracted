#!/usr/bin/perl
# A simple syntax highlighting editor for perl.
# This example demonstrates using Perl FLTK to make a fancy text editor.
# It syntax highlights Perl code (poorly), showing how to use the 
# Fl_Text_Buffer and Fl_Text_Editor widget

# Import FLTK and export the necessary tag group constants.
use FLTK qw( :Keytypes :Colors :Fonts :Utils);

# Make sure we got an argument.
$in = shift;

# Set a style table. A style table is an array of array references, declared 
# here as a series of anonymous array refs (as indicated by brackets). Each 
# array ref contains a color, a font name, and a size. When added to the 
# Fl_Text_Editor widget these entries will be referenced in alphabetical 
# order starting with 'A'. So, the first entry in the style table will be 
# refered to as 'A', the second as 'B', etc, etc.
@styles = ([FL_BLACK, FL_COURIER, 12],
           [FL_RED, FL_COURIER, 12],
           [FL_BLUE, FL_COURIER, 12],
           [fl_rgb(34, 139, 34), FL_COURIER_BOLD, 12],
           [fl_rgb(0, 130, 255), FL_COURIER_ITALIC, 12]);

# Create the text and style buffers.
$sb = new Fl_Text_Buffer();
$tb = new Fl_Text_Buffer();

# The load_file() member function is a pure perl addition to this class. It
# takes a filename, slurps the file's contents into a string and passes that
# to Fl_Text_Buffer::text().
if($in) {
  $tb->load_file($in);
} else {
  $tb->text("#!/usr/bin/perl\n");
}
$tb->tab_distance(2);

# Grab the highlight data, we'll pad the buffer with 'A', our default, to 
# start.
$hdata = $tb->text();
$hdata =~ s/(.)/A/gs;
$sb->text($hdata);

# This is the highlighting routine
do_highlight();

# Set a modify callback on our main text buffer.
$tb->add_modify_callback(\&my_mcb);

# Start the GUI
$window = new Fl_Window(400,480);
$edit = new Fl_Text_Editor(0,5,400,440);
# Add the highlighting data to the Editor widget. Pass it the style 
# Fl_Text_Buffer, the style table (NOTE: It's passed by reference.), a 
# 'unstyled character, and a unstyled callback. The last two arguments are 
# not used, but must be here, they are currently disabled in FLTK 2, but that
# is probably a temporary situation. FLTK hackers will note the absence of 
# the style table size, this is not needed because the size is calculated 
# when translating the style array into the interal structure representation.
$edit->highlight_data($sb, \@styles, 'x', sub { print "no op\n";});
$edit->buffer($tb);

# Add a key binding to the editor. Doesn't really do anything in this example
# except to show how to make key bindings.
$edit->add_key_binding(FL_Enter, 0, \&kb_sub);
$edit->move_down();
$edit->end();
$btn = new Fl_Button(350, 450, 45, 25, "Quit");
$btn->callback(sub { exit;});
$window->resizable($edit);
$window->end();
$window->show();
Fl::run();

# An example Fl_Text_Editor key binding. Key bindings are passed the integer
# position of the cursor in the Text Buffer and an object reference to the 
# editor widget that called the function. Key Bindings work like FLTK's 
# widget handler() routine, returning 1 if the function handles the keypress
# or 0 if not. This example just calls the default key binding.
sub kb_sub {
  my ($i, $e) = @_;
  return $e->kf_enter($i, $e);
}

# A modify callback routine for Fl_Text_Buffer. It recieves the cursor 
# position in the buffer, a flag if the change is an insertion, deletion, or
# a restyled change. The final argument is the text deleted in a delete 
# modification is signalled.
sub my_mcb {
  my ($pos, $nInserted, $nDeleted, $nRestyled, $text) = @_;
  if($nInserted) {
    $sb->insert($pos, 'A');
    do_highlight();
    $edit->redraw();
  } elsif($nDeleted) {
    $sb->remove($pos, ($pos + 1));
    do_highlight();
    $edit->redraw();
  }
}

# Cheap, inefficient Perl syntax highlighter. Viewing anything but perl code
# with this editor will look pretty crappy.
sub do_highlight {
  # Some perl keywords
  my @keywds = qw( if shift while do for return new print my sub open foreach use package elsif else );
  my $pos = 0;
  my $newpos = 0;
  my $wend;
  my $newbuf;
  my $nextchar;

  # Search for all instances of each keyword in the list and highlight them 
  # with the 4th item in our style table.
  foreach my $wrd (@keywds) {
    $pos = 0;
    while($tb->search_forward($pos, $wrd, $newpos, 1)) {
      $wend = $tb->word_end($newpos);
      $newbuf = $tb->text_range($newpos, $wend);
      # The next bit of code makes sure this is the actual word and isn't
      # a larger word with the keyword in it (e.g. sub, not subtract).
      while($newbuf ne $wrd) {
        $wend--;
        $newbuf = $tb->text_range($newpos, $wend);
      }
      $nextchar = $tb->character(($wend));
      if($nextchar eq " " || $nextchar eq "(" || $nextchar eq "{" || $nextchar eq ";") {
        $newbuf =~ s/(.)/D/g;
        $sb->replace($newpos, $wend, $newbuf);
      }
      $pos = $newpos + 1;
    }
  }
  $pos = 0;
  # Highlight all quoted strings with item 2 of the style table
  while($tb->search_forward($pos, '"', $newpos)) {
    if($tb->search_forward(($newpos+1), '"', $wend)) {
      $newbuf = $tb->text_range($newpos, $wend);
      $newbuf =~ s/(.)/B/g;
      $sb->replace($newpos, $wend, $newbuf);
      $pos = $wend + 1;
    } else {
      $pos++;;
    }
  }
  $pos = 0;
  # Highlight all qw(...) lists like strings.
  while($tb->search_forward($pos, 'qw(', $newpos)) {
    if($tb->search_forward(($newpos+1), ')', $wend)) {
      $newbuf = $tb->text_range($newpos, ($wend + 1));
      $newbuf =~ s/(.)/B/g;
      $sb->replace($newpos, ($wend + 1), $newbuf);
      $pos = $wend + 1;
    } else {
      $pos++;
    }
  }

  # Highlight the variables, arrays, hashes, and function references with the
  # third style item.
  $pos = 0;
  while($tb->search_forward($pos, '$', $newpos)) {
    $wend = $tb->word_end(($newpos+1));
    if($tb->character(($wend)) =~ m/([\!\@\/\_])/) {
      $wend++;
    }
    $newbuf = $tb->text_range($newpos, $wend);
    $newbuf =~ s/(.)/C/g;
    $sb->replace($newpos, $wend, $newbuf);
    $pos = $wend + 1;
  }
  $pos = 0;
  while($tb->search_forward($pos, '@', $newpos)) {
    $wend = $tb->word_end(($newpos+1));
    if($tb->character(($wend)) =~ m/([\!\@\/\_])/) {
      $wend++;
    }
    $newbuf = $tb->text_range($newpos, $wend);
    $newbuf =~ s/(.)/C/g;
    $sb->replace($newpos, $wend, $newbuf);
    $pos = $wend + 1;
  }
  $pos = 0;
  while($tb->search_forward($pos, '%', $newpos)) {
    $wend = $tb->word_end(($newpos+1));
    if($tb->character(($wend)) =~ m/([\!\@\/\_])/) {
      $wend++;
    }
    $newbuf = $tb->text_range($newpos, $wend);
    $newbuf =~ s/(.)/C/g;
    $sb->replace($newpos, $wend, $newbuf);
    $pos = $wend + 1;
  }
  $pos = 0;
  while($tb->search_forward($pos, '&', $newpos)) {
    $wend = $tb->word_end(($newpos+1));
    if($tb->character(($wend)) =~ m/([\!\@\/\_])/) {
      $wend++; 
    }
    $newbuf = $tb->text_range($newpos, $wend);
    $newbuf =~ s/(.)/C/g;
    $sb->replace($newpos, $wend, $newbuf);
    $pos = $wend + 1;
  } 

  # Highlight comments
  $pos = 0;
  while($tb->search_forward($pos, '#', $newpos)) {
    if($tb->character(($newpos - 1)) ne '$') {
      $wend = $tb->line_end($newpos);
      $newbuf = $tb->text_range($newpos, $wend);
      $newbuf =~ s/(.)/E/g;
      $sb->replace($newpos, $wend, $newbuf);
      $pos = $wend;
    } else {
      $pos = $newpos + 1;
    }
  }
}
