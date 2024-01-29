use v5.12;
use warnings;

package Kephra::App::Editor::Events;

sub mount {
    my ($self, @which) = @_;
    $self->DragAcceptFiles(1) if $^O eq 'MSWin32'; # enable drop files on win
    #$self->SetDropTarget( Kephra::App::Editor::TextDropTarget->new($self) );

    # Wx::Event::EVT_KEY_UP( $self, sub { my ($ed, $event) = @_; my $code = $event->GetKeyCode;  my $mod = $event->GetModifiers; });
    Wx::Event::EVT_KEY_DOWN( $self, sub {
        my ($ed, $event) = @_;
        my $code = $event->GetKeyCode; # my $raw = $event->GetRawKeyCode;
        my $mod = $event->GetModifiers; #  say $code;
        #   alt ",$event->AltDown, " ; ctrl ",$event->ControlDown; say "mod $mod code $code";

        if ( $event->ControlDown and $mod != 3) { # $mod == 2 and
            if ($event->AltDown) {
                $event->Skip
            } else {
                if ($event->ShiftDown){
                    #if    ($code == 65)                { $ed->shrink_selecton   } # A
                    if    ($code == &Wx::WXK_UP)       { $ed->select_prev_block }
                    elsif ($code == &Wx::WXK_DOWN)     { $ed->select_next_block }
                    elsif ($code == &Wx::WXK_PAGEUP )  { $ed->select_prev_sub   }
                    elsif ($code == &Wx::WXK_PAGEDOWN ){ $ed->select_next_sub   }
                    else                               { $event->Skip           }
                } else {
                    if    ($code == 43 or $code == 388){ $ed->zoom_in           } # +
                    elsif ($code == 45 or $code == 390){ $ed->zoom_out          } # -
                    elsif ($code == 65)                { $ed->expand_selecton   } # A
                    elsif ($code == 67)                { $ed->copy              } # C
                    elsif ($code == 76)                { $ed->sel               } # L
                    elsif ($code == 88)                { $ed->cut               } # X
                    elsif ($code == &Wx::WXK_UP)       { $ed->goto_prev_block   }
                    elsif ($code == &Wx::WXK_DOWN)     { $ed->goto_next_block   }
                    elsif ($code == &Wx::WXK_PAGEUP )  { $ed->goto_prev_sub     }
                    elsif ($code == &Wx::WXK_PAGEDOWN ){ $ed->goto_next_sub     }
                    else                               { $event->Skip }
                }
            }
        } else {
            if ($mod == 3) { # Alt Gr
                if ($event->ShiftDown) {
                    $event->Skip
                } else {
                    if    ($code == 81)                { $ed->insert_text('@') } # Q
                    elsif ($code == 55 )               { $ed->insert_brace('{', '}') }
                    elsif ($code == 56 )               { $ed->insert_brace('[', ']') }
                    else                               { $event->Skip                }
                }
            } elsif ( $event->AltDown ) { # $mod == 1
                if ($event->ShiftDown){
                    if    ($code == &Wx::WXK_UP)       { $ed->select_rect_up    }
                    elsif ($code == &Wx::WXK_DOWN)     { $ed->select_rect_down  }
                    elsif ($code == &Wx::WXK_LEFT)     { $ed->select_rect_left  }
                    elsif ($code == &Wx::WXK_RIGHT)    { $ed->select_rect_right }
                    else                               { $event->Skip }
                } else {
                    if    ($code == &Wx::WXK_UP)       { $ed->move_up           }
                    elsif ($code == &Wx::WXK_DOWN)     { $ed->move_down         }
                    elsif ($code == &Wx::WXK_LEFT)     { $ed->move_left         }
                    elsif ($code == &Wx::WXK_RIGHT)    { $ed->move_right        }
                    elsif ($code == &Wx::WXK_PAGEUP)   { $ed->move_page_up      }
                    elsif ($code == &Wx::WXK_PAGEDOWN) { $ed->move_page_down    }
                    elsif ($code == &Wx::WXK_HOME)     { $ed->move_to_start     }
                    elsif ($code == &Wx::WXK_END )     { $ed->move_to_end       }
                    elsif ($code == &Wx::WXK_DELETE)   { $ed->delete_line       }
                    elsif ($code == 55 )               { $ed->insert_brace('{', '}') }
                    elsif ($code == 56 )               { $ed->insert_brace('[', ']') }
                    else                               { $event->Skip }
                }
            } else {
                if ($event->ShiftDown){
                    if    ($code == 35 )                   { $ed->insert_brace("'", "'") }
                    elsif ($code == 40 )                   { $ed->insert_brace('(', ')') }
                    elsif ($code == 50 )                   { $ed->insert_brace('"', '"') }
                    elsif ($code == &Wx::WXK_LEFT)         { $ed->select_left             }
                    elsif ($code == &Wx::WXK_RIGHT)        { $ed->select_right            }
                    elsif ($code == &Wx::WXK_UP)           { $ed->select_up              }
                    elsif ($code == &Wx::WXK_DOWN)         { $ed->select_down            }
                    elsif ($code == &Wx::WXK_HOME)         { $ed->select_home            }
                    elsif ($code == &Wx::WXK_END)          { $ed->select_end             }
                    elsif ($code == &Wx::WXK_PAGEUP )      { $ed->select_page_up         }
                    elsif ($code == &Wx::WXK_PAGEDOWN )    { $ed->select_page_down       }
                    else                                   { $event->Skip                }
                } else {
                    if    ($code == &Wx::WXK_ESCAPE )      { $ed->escape                 }
                    elsif ($code == &Wx::WXK_LEFT)         { $ed->caret_left             }
                    elsif ($code == &Wx::WXK_RIGHT)        { $ed->caret_right            }
                    elsif ($code == &Wx::WXK_HOME)         { $ed->caret_home             }
                    elsif ($code == &Wx::WXK_END)          { $ed->caret_end              }
                    elsif ($code == &Wx::WXK_UP)           { $ed->caret_up               }
                    elsif ($code == &Wx::WXK_DOWN)         { $ed->caret_down             }
                    elsif ($code == &Wx::WXK_PAGEUP )      { $ed->caret_page_up          }
                    elsif ($code == &Wx::WXK_PAGEDOWN )    { $ed->caret_page_down        }
                    elsif ($code == &Wx::WXK_RETURN)       { $self->new_line             }
                    else                                   { $event->Skip                }
                }
            }
        }
    });

    Wx::Event::EVT_LEFT_DOWN( $self, sub {
        my ($ed, $ev) = @_;
        #my $XY = $ev->GetLogicalPosition( Wx::MemoryDC->new( ) );
        #my $pos = $ed->XYToPosition( $XY->x, $XY->y);
        # $ed->expand_selecton( $pos ) or
        $ed->del_caret_pos_cache();
        $ev->Skip;
    });
    # Wx::Event::EVT_RIGHT_DOWN( $self, sub {});
    Wx::Event::EVT_MIDDLE_UP( $self, sub {  $_[1]->Skip;  });

    # Wx::Event::EVT_STC_CHARADDED( $self, $self, sub {  });
    Wx::Event::EVT_STC_CHANGE ( $self, -1, sub {  # edit event
        my ($ed, $event) = @_;
        my $pos = $ed->GetCurrentPos;
        unless ($ed->{'change_pos'} == $pos) {
            $ed->{'change_prev'} = $ed->{'change_pos'};
            $ed->{'change_pos'} = $pos;
        }
        # if ($self->SelectionIsRectangle) { } else { }
        $event->Skip;
    });

    Wx::Event::EVT_STC_UPDATEUI(         $self, -1, sub { # cursor move event
        my ($ed, $event) = @_;
        my $p = $self->GetCurrentPos;
        my ($start_pos, $end_pos) = $self->GetSelection;
        $ed->{'set_pos'} = $p if $start_pos == $end_pos; # say "move ",$ed->{'set_pos'};
        $self->bracelight( $p );
        my $psrt = ($self->GetCurrentLine+1).':'.$self->GetColumn( $p );
        $psrt .= ' ('.($end_pos - $start_pos).')' if $start_pos != $end_pos;
        $self->GetParent->SetStatusText( $psrt , 0);
    });
    Wx::Event::EVT_STC_SAVEPOINTREACHED( $self, -1, sub { $self->GetParent->set_title(0) });
    Wx::Event::EVT_STC_SAVEPOINTLEFT(    $self, -1, sub { $self->GetParent->set_title(1) });
    Wx::Event::EVT_SET_FOCUS(            $self,     sub { my ($ed, $event ) = @_;        $event->Skip;   });
    Wx::Event::EVT_DROP_FILES          ( $self,     sub {
        say $_[0], $_[1];
        #$self->GetParent->open_file()
    });
#    Wx::Event::EVT_STC_DO_DROP  ($self, -1, sub {
#        my ($ed, $event ) = @_; # StyledTextEvent=SCALAR
#        my $str = $event->GetDragText;
#        chomp $str;
#        if (substr( $str, 0, 7) eq 'file://'){
#            $self->GetParent->open_file( substr $str, 7 );
#        }
#        return; # $event->Skip;
#    });

}


1;

__END__

$self->SetIndicatorCurrent( $c);
$self->IndicatorFillRange( $start, $len );
$self->IndicatorClearRange( 0, $len )
#Wx::Event::EVT_STC_STYLENEEDED($self, sub{})
#Wx::Event::EVT_STC_CHARADDED($self, sub {});
#Wx::Event::EVT_STC_ROMODIFYATTEMPT($self, sub{})
#Wx::Event::EVT_STC_KEY($self, sub{})
#Wx::Event::EVT_STC_DOUBLECLICK($self, sub{})
Wx::Event::EVT_STC_UPDATEUI($self, -1, sub {
#my ($ed, $event) = @_; $event->Skip; print "change \n";
});
#Wx::Event::EVT_STC_MODIFIED($self, sub {});
#Wx::Event::EVT_STC_MACRORECORD($self, sub{})
#Wx::Event::EVT_STC_MARGINCLICK($self, sub{})
#Wx::Event::EVT_STC_NEEDSHOWN($self, sub {});
#Wx::Event::EVT_STC_PAINTED($self, sub{})
#Wx::Event::EVT_STC_USERLISTSELECTION($self, sub{})
#Wx::Event::EVT_STC_UR$selfROPPED($self, sub {});
#Wx::Event::EVT_STC_DWELLSTART($self, sub{})
#Wx::Event::EVT_STC_DWELLEND($self, sub{})
#Wx::Event::EVT_STC_START_DRAG($self, sub{})
#Wx::Event::EVT_STC_DRAG_OVER($self, sub{})
#Wx::Event::EVT_STC_DO_DROP($self, sub {});
#Wx::Event::EVT_STC_ZOOM($self, sub{})
#Wx::Event::EVT_STC_HOTSPOT_CLICK($self, sub{})
#Wx::Event::EVT_STC_HOTSPOT_DCLICK($self, sub{})
#Wx::Event::EVT_STC_CALLTIP_CLICK($self, sub{})
#Wx::Event::EVT_STC_AUTOCOMP_SELECTION($self, sub{})
#$self->SetAcceleratorTable( Wx::AcceleratorTable->new() );
#Wx::Event::EVT_STC_SAVEPOINTREACHED($self, -1, \&Kephra::File::savepoint_reached);
#Wx::Event::EVT_STC_SAVEPOINTLEFT($self, -1, \&Kephra::File::savepoint_left);
$self->SetAcceleratorTable(
Wx::AcceleratorTable->new(
[&Wx::wxACCEL_CTRL, ord 'n', 1000],
