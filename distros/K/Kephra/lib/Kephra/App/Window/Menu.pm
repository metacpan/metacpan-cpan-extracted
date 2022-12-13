use v5.12;
use warnings;
use Wx;

package Kephra::App::Window::Menu;

my $edit;

sub mount {
    my ($win) = @_;
    my $ed = $win->{'ed'};

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
    #$edit_menu->Append( 12310, "&Shrink Selection\tCtrl+Shift+A", "select entire text" );
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

    #~ my $doc_menu  = Wx::Menu->new();
    #~ $doc_menu->AppendCheckItem( 15100, "Soft Tabs",    "if active, several space character simulate a tab character" );
    #~ my $doc_tab_menu  = Wx::Menu->new();
    #~ $doc_tab_menu->AppendRadioItem( 15200+$_, $_ ,  ) for 1..10;
    #~ $doc_tab_menu->Check(15204, 1);
    #~ $doc_menu->Append( 15200, '&Tab Size', $doc_tab_menu, '' );
    #~ my $doc_encoding_menu  = Wx::Menu->new();
    #~ $doc_encoding_menu->AppendRadioItem( 15401, 'UTF-8' );
    #~ $doc_encoding_menu->AppendRadioItem( 15402, 'ASCII' );
    #~ $doc_menu->Append( 15400, '&Encoding', $doc_encoding_menu, '' );
    #~ my $doc_mode_menu  = Wx::Menu->new();
    #~ $doc_mode_menu->AppendRadioItem( 15501, 'no' );
    #~ $doc_mode_menu->AppendRadioItem( 15502, 'Perl' );
    #~ $doc_mode_menu->AppendRadioItem( 15503, 'Python' );
    #~ $doc_mode_menu->AppendRadioItem( 15504, 'Ruby' );
    #~ $doc_mode_menu->AppendRadioItem( 15505, 'C' );
    #~ $doc_mode_menu->AppendRadioItem( 15506, 'Rust' );
    #~ $doc_mode_menu->AppendRadioItem( 15507, 'Markdown' );
    #~ $doc_mode_menu->AppendRadioItem( 15508, 'YAML' );
    #~ $doc_menu->Append( 15500, '&Syntax Mode', $doc_mode_menu, '' );
        
    my $view_menu = Wx::Menu->new();
    $view_menu->AppendCheckItem( 16110, "&Whitespace",    "make white space and tabs visible by dots and arrows" );
    $view_menu->AppendCheckItem( 16120, "&EOL Marker",    "show symbols marking the invisible end of line characters" );
    $view_menu->AppendCheckItem( 16130, "&Indent Guide",  "vertical lines on top of space at tab size distance" );
    $view_menu->AppendCheckItem( 16140, "&Right Margin",  "vertical line at the 80 (changeable) character mark" );
    $view_menu->AppendSeparator();
    $view_menu->AppendCheckItem( 16210, "&Line Number Margin",  "make line numbers visible or not" );
    $view_menu->AppendCheckItem( 16220, "&Marker Margin",       "make marker margin (right beside line number) visible or not" );
    $view_menu->AppendSeparator();
    $view_menu->Check(16110, 1);
    $view_menu->Check(16130, 1);
    $view_menu->Check(16140, 1);
    $view_menu->Check(16210, 1);
    $view_menu->Check(16220, 1);
    my @zoom_range = -10 .. 20;
    my $zoom_menu  = Wx::Menu->new();
    $zoom_menu->Append( 16310, "Zoom &In\tCtrl+-", 'increase zoom level' );
    $zoom_menu->Append( 16320, "Zoom &Out\tCtrl++", 'decrease zoom level ' );
    $zoom_menu->AppendSeparator();
    $zoom_menu->AppendRadioItem( 16340+$_, "Zoom Level  ".$_, 'set zoom level to '.$_ ) for @zoom_range;
    $view_menu->AppendCheckItem( 16420, "Line Wra&p",  "break up lines so they fit the window" );
    $view_menu->Append( 16300, '&Zoom', $zoom_menu, '' );
    $view_menu->AppendCheckItem( 16410, "&Fullscreen\tF11",  "switches to or from fullscreen mode" );
    $zoom_menu->Check(16340, 1);
    
    my $help_menu = Wx::Menu->new();
    #$help_menu->Append( 15100, "&Usage",  "Explaining the user interface" );
    #$help_menu->Append( 15200, "&Keymap\tAlt+K",  "listings with all key kombination from all widgets" );
    $help_menu->Append( 17500, "&About",  "Dialog with some general information" );

    my $menu_bar = Wx::MenuBar->new();
    $menu_bar->Append( $file_menu,   '&File' );
    $menu_bar->Append( $edit_menu,   '&Edit' );
    $menu_bar->Append( $format_menu, 'F&ormat' );
    $menu_bar->Append( $search_menu, '&Search' );
    #$menu_bar->Append( $doc_menu,    '&Document' );
    $menu_bar->Append( $view_menu,   '&View' );
    $menu_bar->Append( $help_menu,   '&Help' );
    $win->SetMenuBar($menu_bar);
    
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
    Wx::Event::EVT_MENU( $win, 16110, sub { $win->{'ed'}->toggle_view_whitespace });
    Wx::Event::EVT_MENU( $win, 16120, sub { $win->{'ed'}->toggle_view_eol         });
    Wx::Event::EVT_MENU( $win, 16130, sub { $win->{'ed'}->toggle_view_inden_guide  });
    Wx::Event::EVT_MENU( $win, 16140, sub { $win->{'ed'}->toggle_view_right_margin  });
    Wx::Event::EVT_MENU( $win, 16210, sub { $win->{'ed'}->toggle_view_line_nr_margin });
    Wx::Event::EVT_MENU( $win, 16220, sub { $win->{'ed'}->toggle_view_marker_margin  });
    Wx::Event::EVT_MENU( $win, 16310, sub { $win->{'ed'}->zoom_in                    });
    Wx::Event::EVT_MENU( $win, 16320, sub { $win->{'ed'}->zoom_out                   });
    Wx::Event::EVT_MENU( $win, 16340 + $_, sub { $win->{'ed'}->set_zoom_level(  $_) }) for @zoom_range;
    Wx::Event::EVT_MENU( $win, 16420, sub { $win->{'ed'}->toggle_view_line_wrap      });
    Wx::Event::EVT_MENU( $win, 16410, sub { $win->toggle_full_screen           });
#    Wx::Event::EVT_MENU( $win, 15100, sub { Kephra::App::Dialog::documentation( $win ) });
#    Wx::Event::EVT_MENU( $win, 15200, sub { Kephra::App::Dialog::keymap($win)  });
    Wx::Event::EVT_MENU( $win, 17500, sub { Kephra::App::Dialog::about( $win)  });

}




sub edit_context { $edit }


1;
