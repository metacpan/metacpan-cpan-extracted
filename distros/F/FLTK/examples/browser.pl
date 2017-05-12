#!/usr/bin/perl
use FLTK qw( :Boxtypes :Imagetypes :Flags :Colors );

$folderSmall = new Fl_Shared_Image(FL_IMAGE_XPM, "folder_small.xpm");
$fileSmall = new Fl_Shared_Image(FL_IMAGE_XPM, "file_small.xpm");

$win = new Fl_Window(240, 304, "Browser Example");
$tree = new Fl_Browser(10, 10, 220, 180);
$tree->indented(1);
$tree->end();
$win->resizable($tree);
$remove_button = new Fl_Button(10, 200, 100, 22, "Remove");
$add_paper_button = new Fl_Button(10, 224, 100, 22, "Add Paper");
$add_folder_button = new Fl_Button(10, 248, 100, 22, "Add Folder");
$sort_button = new Fl_Check_Button(10, 272, 100, 22, "Sort");
$multi_button = new Fl_Button(130, 200, 100, 22, "MultiBrowser");
$sort_button_rev = new Fl_Button(130, 224, 100, 22, "Reverse Sort");
$sort_button_rnd = new Fl_Button(130, 248, 100, 22, "Randomize");
$colors_button = new Fl_Check_Button(130, 272, 100, 22, "Colors");

$win->end();

$remove_button->callback(\&cb_remove, $tree);
$add_paper_button->callback(\&cb_add_paper, $tree);
$add_folder_button->callback(\&cb_add_folder, $tree);
$sort_button->callback(\&cb_sort, $tree);
$multi_button->callback(\&cb_multi, $tree);
$sort_button_rev->callback(\&cb_sort_reverse, $tree);
$sort_button_rnd->callback(\&cb_sort_random, $tree);
$colors_button->callback(\&cb_colors, $tree);
$tree->callback(\&cb_test);

@papers;
@folders;

add_folder(\@folders, \$tree, "aaa\t123", 1, $folderSmall);
add_folder(\@folders, \$folders[$#folders], "bbb TWO\t456", 1, $folderSmall);

add_folder(\@folders, \$tree, "bbb", 0, $folderSmall);

add_paper(\@papers, \$folders[$#folders], "ccc\t789", 1, $folderSmall);
add_paper(\@papers, \$folders[$#folders], "ddd\t012", 0, $fileSmall);

add_folder(\@folders, \$tree, "eee", 1, $folderSmall);
add_paper(\@papers, \$folders[$#folders], "fff", 0, $fileSmall);

add_folder(\@folders, \$folders[$#folders], "ggg", 1, $folderSmall);
add_paper(\@papers, \$folders[$#folders], "hhh", 1, $fileSmall);
add_paper(\@papers, \$folders[$#folders], "iii", 1, $fileSmall);

add_folder(\@folders, \$tree, "jjj", 1, $folderSmall);
add_paper(\@papers, \$folders[$#folders], "kkk", 0, $fileSmall);

add_paper(\@papers, \$tree, "lll", 0, $fileSmall);
add_folder(\@folders, \$tree, "mmm", 0, $folderSmall);
add_paper(\@papers, \$folders[$#folders], "nnn", 1, $folderSmall);
add_paper(\@papers, \$folders[$#folders], "ooo", 0, $fileSmall);

add_folder(\@folders, \$folders[$#folders], "ppp", 1, $folderSmall);
add_paper(\@papers, \$folders[$#folders], "qqq", 0, $fileSmall);

add_folder(\@folders, \$folders[$#folders], "rrr", 1, $folderSmall);
add_folder(\@folders, \$folders[$#folders], "sss", 1, $folderSmall);
add_folder(\@folders, \$folders[$#folders], "ttt", 1, $folderSmall);

add_folder(\@folders, \$tree, "uuu", 1, $folderSmall);
add_paper(\@papers, \$folders[$#folders], "vvv", 0, $fileSmall);

add_paper(\@papers, \$tree, "www", 0, $fileSmall);
add_paper(\@papers, \$tree, "xxx", 0, $fileSmall);
add_paper(\@papers, \$tree, "yyy", 0, $fileSmall);
add_paper(\@papers, \$tree, "zzz", 0, $fileSmall);

$win->show();
Fl::run();

sub cb_test {
  my ($w) = @_;
  my $child = $w->goto_visible_focus();
  my $label = $child->label() ? $child->label() : "null";
  print "callback for $label\n";
  print $tree->value(),"\n";
}

sub add_folder {
  my ($list, $parent, $name, $open, $image) = @_;
  my $new = new Fl_Item_Group($name);
  $new->image($image);
  if($open) {$new->set_flag(FL_OPEN);}
  push @$list, $new;
  $$parent->add($new);
  $$parent->relayout();
}

sub add_paper {
  my ($list, $parent, $name, $open, $image) = @_;
  my $new = new Fl_Item($name);
  $new->image($image);
  push @$list, $new;
  $$parent->add($new);
  $$parent->relayout();
}

sub cb_add_folder {
  my ($w, $ptr) = @_;
  my $g = current_group($ptr);
  add_folder(\@folders, \$g, "Added folder", 1, $folderSmall);
}

sub cb_add_paper {
  my ($w, $ptr) = @_;
  my $g = current_group($ptr);
  add_paper(\@papers, \$g, "New paper", 0, $fileSmall);
}

sub current_group {
  my ($browser) = @_;
  my $w = $browser->goto_mark(Fl_Browser::FOCUS);
  if(!$w) {
    print "Returning browser.\n";
    return $browser;
  }
  if($w->is_group() && ($w->flags()& FL_OPEN)) {
    print "Returning group with label ".$w->label()."\n";
    return (bless $w, "Fl_Group");
  }
  return $browser;
}

sub cb_colors {
  my ($w, $ptr) = @_;
  $ptr->color($w->value() ? FL_LIGHT2 : $ptr->text_background());
  $ptr->redraw();
}

sub cb_multi {
  my ($w, $ptr) = @_;
  $ptr->type($w->value() ? Fl_Browser::FL_MULTI_BROWSER : Fl_Browser::FL_NORMAL_BROWSER);
  $ptr->relayout();
}

sub cb_remove {
  my ($widget, $tree) = @_;
  my ($w, $g);
  if($tree->multi()) {
    $w = $tree->goto_top();
    while($w) {
      if($w->value()) {
        $g = $w->parent();
        $g->remove($w);
        print "Wanting to remove widget labelled '".$w->label()."\n";
        undef $w;
        $g->relayout();
        $w = $tree->goto_top();
      } else {
        $w = $tree->forward();
        print "Moving on to widget ".$w->label()."\n";
      }
    }
  } else {
    
    if(!($w = $tree->goto_visible_focus())) {
      print "No child selected.\n";
    }
    if($w) {
      $g = $w->parent();
      $g->remove($w);
      undef $w;
      $g->relayout();
    }
  }
}

sub cb_sort { print "I don't do anything.\n"; }
sub cb_sort_reverse { print "I don't do anything.\n"; }
sub cb_sort_random { print "I don't do anything.\n"; } 
    
sub widget_kill {
  my ($w) = @_;
  my @newarr;
  my $item;
  my $killed = 1;
  foreach $item (@papers) {
    if($item->label() ne $w->label()) {
      push @newarr, $item;
    } else {
      $killed = 1;
    }
  } 
  undef @papers;
  foreach $item (@newarr) {
    push @papers, $item;
  }
  undef @newarr;
  if(!$killed) {
    foreach $item (@folders) {
      if($item->label() ne $w->label()) {
        push @newarr, $item;
      }
    }
    undef @folders;
    foreach $item (@newarr) {
      push @folders, $item;
    }
  }
}
