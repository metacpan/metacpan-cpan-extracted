use v5.12;
use warnings;
use Wx;

package Kephra::App::Window::Menu;

my $edit;

sub mount {
    my ($win) = @_;
    my $ed = $win->{'ed'};
    Wx::Event::EVT_MENU( $win, 11100, sub { $win->new_file                     });
    Wx::Event::EVT_MENU( $win, 11200, sub { $win->open_file                    });
    Wx::Event::EVT_MENU( $win, 11300, sub { $win->reopen_file                  });
    Wx::Event::EVT_MENU( $win, 11400, sub { $win->save_file                    });
    Wx::Event::EVT_MENU( $win, 11500, sub { $win->save_as_file                 });
    Wx::Event::EVT_MENU( $win, 11900, sub { $win->Close                        });
    Wx::Event::EVT_MENU( $win, 11910, sub { $win->{'dontask'} = 1; $win->Close });
    Wx::Event::EVT_MENU( $win, 12100, sub { $win->{'ed'}->Undo                 });
    Wx::Event::EVT_MENU( $win, 12110, sub { $win->{'ed'}->Redo                 });
    Wx::Event::EVT_MENU( $win, 12200, sub { $win->{'ed'}->cut                  });
    Wx::Event::EVT_MENU( $win, 12210, sub { $win->{'ed'}->copy                 });
    Wx::Event::EVT_MENU( $win, 12220, sub { $win->{'ed'}->Paste                });
    Wx::Event::EVT_MENU( $win, 12230, sub { $win->{'ed'}->replace              });
    Wx::Event::EVT_MENU( $win, 12240, sub { $win->{'ed'}->Clear                });
    Wx::Event::EVT_MENU( $win, 12300, sub { $win->{'ed'}->expand_selecton      });
    Wx::Event::EVT_MENU( $win, 12310, sub { $win->{'ed'}->shrink_selecton      });
    Wx::Event::EVT_MENU( $win, 12400, sub { $win->{'ed'}->duplicate            });
    Wx::Event::EVT_MENU( $win, 13100, sub { $win->{'ed'}->move_left            });
    Wx::Event::EVT_MENU( $win, 13110, sub { $win->{'ed'}->move_right           });
    Wx::Event::EVT_MENU( $win, 13120, sub { $win->{'ed'}->move_up              });
    Wx::Event::EVT_MENU( $win, 13130, sub { $win->{'ed'}->move_down            });
    Wx::Event::EVT_MENU( $win, 13300, sub { $win->{'ed'}->toggle_block_comment });
    Wx::Event::EVT_MENU( $win, 13310, sub { $win->{'ed'}->toggle_comment       });
    Wx::Event::EVT_MENU( $win, 14110, sub { $win->{'sb'}->enter                });
    Wx::Event::EVT_MENU( $win, 14120, sub { $win->{'sb'}->find_prev            });
    Wx::Event::EVT_MENU( $win, 14130, sub { $win->{'sb'}->find_next            });
    Wx::Event::EVT_MENU( $win, 14210, sub { $win->{'rb'}->enter                });
    Wx::Event::EVT_MENU( $win, 14220, sub { $win->{'rb'}->replace_prev         });
    Wx::Event::EVT_MENU( $win, 14230, sub { $win->{'rb'}->replace_next         });
    Wx::Event::EVT_MENU( $win, 14240, sub { $win->{'rb'}->replace_in_selection });
    Wx::Event::EVT_MENU( $win, 14310, sub { $win->{'ed'}->marker_toggle        });
    Wx::Event::EVT_MENU( $win, 14320, sub { $win->{'ed'}->marker_prev          });
    Wx::Event::EVT_MENU( $win, 14330, sub { $win->{'ed'}->marker_next          });
    Wx::Event::EVT_MENU( $win, 14250, sub { $win->{'rb'}->replace_all          });
    Wx::Event::EVT_MENU( $win, 14310, sub { $win->{'ed'}->toggle_marker        });
    Wx::Event::EVT_MENU( $win, 14340, sub { $win->{'ed'}->delete_all_marker    });
    Wx::Event::EVT_MENU( $win, 14320, sub { $win->{'ed'}->goto_prev_marker     });
    Wx::Event::EVT_MENU( $win, 14330, sub { $win->{'ed'}->goto_next_marker     });
    Wx::Event::EVT_MENU( $win, 14400, sub { $win->{'ed'}->goto_last_edit       });
    Wx::Event::EVT_MENU( $win, 15100, sub { Kephra::App::Dialog::documentation( $win ) });
    Wx::Event::EVT_MENU( $win, 15200, sub { Kephra::App::Dialog::keymap($win)  });
    Wx::Event::EVT_MENU( $win, 15300, sub { Kephra::App::Dialog::about( $win)  });
    Wx::Event::EVT_MENU( $win, 15900, sub { $win->ShowFullScreen( not $win->IsFullScreen ) });
    

    my $file_menu = Wx::Menu->new();
    $file_menu->Append( 11100, "&New\tCtrl+N", "complete a sketch drawing" );
    $file_menu->AppendSeparator();
    $file_menu->Append( 11200, "&Open\tCtrl+O", "save currently displayed image" );
    $file_menu->Append( 11300, "&Reload\tCtrl+Shift+O", "save currently displayed image" );
    $file_menu->AppendSeparator();
    $file_menu->Append( 11400, "&Save\tCtrl+S", "save currently displayed image" );
    $file_menu->Append( 11500, "Save &As\tCtrl+Shift+S", "save currently displayed image" );
    $file_menu->AppendSeparator();
    $file_menu->Append( 11900, "&Quit\tCtrl+Q", "close program" );
    $file_menu->Append( 11910, "No Ask Qui&t\tCtrl+Shift+Q", "close program without file dialog" );
    
    my $edit_menu = Wx::Menu->new();
    $edit_menu->Append( 12100, "&Undo\tCtrl+Z",       "undo last text change" );
    $edit_menu->Append( 12110, "&Redo\tCtrl+Y",       "undo last undo" );
    $edit_menu->AppendSeparator();                    
    $edit_menu->Append( 12200, "&Cut\tCtrl+X",        "delete selected text and move it into clipboard" );
    $edit_menu->Append( 12210, "C&opy\tCtrl+C",       "move selected text into clipboard" );
    $edit_menu->Append( 12220, "&Paste\tCtrl+V",      "insert clipboard content at cursor position" );
    $edit_menu->Append( 12230, "S&wap\tCtrl+Shift+V", "replace selected text with clipboard content" );
    $edit_menu->Append( 12240, "&Delete\tDel",        "delete selected text" );
    $edit_menu->AppendSeparator();
    $edit_menu->Append( 12300, "&Grow Selection\tCtrl+A", "select entire text" );
    $edit_menu->Append( 12310, "&Shrink Selection\tCtrl+Shift+A", "select entire text" );
    $edit_menu->AppendSeparator();
    $edit_menu->Append( 12400, "Du&plicate\tCtrl+D",     "copy and paste selected text or current line" );

    my $format_menu = Wx::Menu->new();
    $format_menu->Append( 13100, "Move &Left\tAlt+Left",  "move current line or selected lines one character to the left" );
    $format_menu->Append( 13110, "Move &Right\tAlt+Right","move current line or selected lines one character to right" );
    $format_menu->Append( 13120, "Move &Up\tAlt+Up",      "move current line or selected lines one row up" );
    $format_menu->Append( 13130, "Move &Down\tAlt+Down",  "move current line or selected lines one row down" );
    $format_menu->AppendSeparator();
    $format_menu->Append( 13200, "&Indent\tTab",       "move current line or selected block one tab to right" );
    $format_menu->Append( 13210, "D&edent\tShift+Tab", "move current line or selected block one tab to left" );
    $format_menu->AppendSeparator();
    $format_menu->Append( 13300, "&Block Comment\tCtrl+K", "insert or remove (toggle) script comment with #~" );
    $format_menu->Append( 13310, "&Comment\tCtrl+Shift+K", "insert or remove (toggle) script comment with #" );
    
    my $search_menu = Wx::Menu->new();
    $search_menu->Append( 14110, "&Find\tCtrl+F",        "enter search phrase into search bar" );
    $search_menu->Append( 14120, "Find &Prev\tShift+F3", "jump to previous match of search term" );
    $search_menu->Append( 14130, "Find &Next\tF3",       "jump to next match of search text" );
    $search_menu->AppendSeparator();
    $search_menu->Append( 14210, "&Replace\tCtrl+Shift+F",      "enter replace term into replace bar" );
    $search_menu->Append( 14220, "Replace Pre&v\tAlt+Shift+F3", "replace selection and go to previous match" );
    $search_menu->Append( 14230, "Replace Ne&xt\tAlt+F3",       "replace selection and go to next match" );
    $search_menu->Append( 14240, "Replace In &Selection\tAlt+Shift+F", "replace all search term matches inside selected text" );
    $search_menu->Append( 14250, "Replace &All\tAlt+F",         "replace all search term matches in the document" );
    $search_menu->AppendSeparator();
    $search_menu->Append( 14310, "&Toggle Marker\tCtrl+M", "set or remove marker on current line" );
    $search_menu->Append( 14340, "&Delete All Marker\tCtrl+Shift+M", "remove all marker" );
    $search_menu->Append( 14320, "Prev Mar&ker\tShift+F2", "jump to previous marked line above current caret position " );
    $search_menu->Append( 14330, "Next &Marker\tF2",       "jump to next marked line below current caret position" );
    $search_menu->AppendSeparator();
    $search_menu->Append( 14400, "&Goto Edit\tCtrl+E", "move cursor position of last change" );
    
    my $help_menu = Wx::Menu->new();
    #$help_menu->Append( 15100, "&Usage",  "Explaining the user interface" );
    #$help_menu->Append( 15200, "&Keymap\tAlt+K",  "listings with all key kombination from all widgets" );
    $help_menu->Append( 15900, "&Fullscreen\tF11",  "switches to or from fullscreen mode" );
    $help_menu->Append( 15300, "&About",  "Dialog with some general information" );

    my $menu_bar = Wx::MenuBar->new();
    $menu_bar->Append( $file_menu,   '&File' );
    $menu_bar->Append( $edit_menu,   '&Edit' );
    $menu_bar->Append( $format_menu, 'F&ormat' );
    $menu_bar->Append( $search_menu, '&Search' );
    $menu_bar->Append( $help_menu,   '&Help' );
    
    $win->SetMenuBar($menu_bar);
}




sub edit_context { $edit }


1;
