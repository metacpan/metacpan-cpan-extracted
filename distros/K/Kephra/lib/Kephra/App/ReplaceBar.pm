use v5.12;
use warnings;
use Wx;

package Kephra::App::ReplaceBar;
use base qw/Wx::Panel/;

sub new {
    my ( $class, $parent ) = @_;
    my $self = $class->SUPER::new( $parent, -1 );
    $self->{'lbl'}    = Wx::StaticText->new($self, -1, 'Replace:' );
    $self->{'text'}   = Wx::TextCtrl->new(  $self, -1, '',       [-1, -1], [200, 25], &Wx::wxTE_PROCESS_ENTER);
    $self->{'once'}   = Wx::Button->new(    $self, -1, 'Once',   [-1, -1], [50, -1] );
    $self->{'prev'}   = Wx::Button->new(    $self, -1, '<',      [-1, -1], [30, -1] );
    $self->{'next'}   = Wx::Button->new(    $self, -1, '>',      [-1, -1], [30, -1] );
    $self->{'sel'}    = Wx::Button->new(    $self, -1, 'Sel.',   [-1, -1], [40, -1] );
    $self->{'all'}    = Wx::Button->new(    $self, -1, 'All',    [-1, -1], [50, -1] );
    $self->{'flbl'}   = Wx::StaticText->new($self, -1, '< Find:' );
    $self->{'fprev'}  = Wx::Button->new(    $self, -1, '<',      [-1, -1], [30, -1] );
    $self->{'fnext'}  = Wx::Button->new(    $self, -1, '>',      [-1, -1], [30, -1] );
    $self->{'rlbl'}   = Wx::StaticText->new($self, -1, '< Revert:' );
    $self->{'rprev'}  = Wx::Button->new(    $self, -1, '<',      [-1, -1], [30, -1] );
    $self->{'rnext'}  = Wx::Button->new(    $self, -1, '>',      [-1, -1], [30, -1] );
    #$self->{'close'}  = Wx::Button->new( $self, -1, 'X',     [-1, -1], [30, 20] );
    $self->{'text'}->SetToolTip('replace term');
    $self->{'once'}->SetToolTip('replace selection with replacement term in nearby text field');
    $self->{'prev'}->SetToolTip('replace selection and goto previous match of sarch term');
    $self->{'next'}->SetToolTip('replace selection and goto next match of sarch term');
    $self->{'sel'}->SetToolTip('replace all matches inside text selection');
    $self->{'all'}->SetToolTip('replace all matches of search term in document');
    $self->{'fprev'}->SetToolTip('go to previous finding of the replacement term');
    $self->{'fnext'}->SetToolTip('go to nect finding of the replacement term');
    $self->{'rprev'}->SetToolTip('replace selection with search term and go to previous finding of the replacement term');
    $self->{'rnext'}->SetToolTip('replace selection with search term and go to next finding of the replacement term');
    #$self->{'close'}->SetToolTip('close search bar');

    Wx::Event::EVT_BUTTON( $self, $self->{'prev'},   sub { $self->replace_prev });
    Wx::Event::EVT_BUTTON( $self, $self->{'next'},   sub { $self->replace_next });
    Wx::Event::EVT_BUTTON( $self, $self->{'once'},   sub { $self->replace_once });
    Wx::Event::EVT_BUTTON( $self, $self->{'sel'},    sub { $self->replace_in_selection });
    Wx::Event::EVT_BUTTON( $self, $self->{'all'},    sub { $self->replace_all  });
    Wx::Event::EVT_BUTTON( $self, $self->{'fprev'},  sub { $self->find_prev    });
    Wx::Event::EVT_BUTTON( $self, $self->{'fnext'},  sub { $self->find_next    });
    Wx::Event::EVT_BUTTON( $self, $self->{'rprev'},  sub { $self->revert_prev  });
    Wx::Event::EVT_BUTTON( $self, $self->{'rnext'},  sub { $self->revert_next  });
    Wx::Event::EVT_BUTTON( $self, $self->{'close'},  sub { $self->close        });
    # Wx::Event::EVT_TEXT_ENTER( $self, $self->{'text'}, sub {  });

    Wx::Event::EVT_KEY_DOWN( $self->{'text'}, sub {
        my ($ed, $event) = @_;
        my $code = $event->GetKeyCode;  # my $mod = $event->GetModifiers();
        if   (                         $code == &Wx::WXK_ESCAPE)    { $self->search_bar->close  }
        elsif( $event->AltDown     and $code == &Wx::WXK_UP )       { $self->find_prev }
        elsif( $event->AltDown     and $code == &Wx::WXK_DOWN )     { $self->find_next }
        elsif( $event->AltDown and $event->ShiftDown and $code == &Wx::WXK_RETURN)    { $self->revert_prev }
        elsif( $event->AltDown     and $code == &Wx::WXK_RETURN)    { $self->revert_next }
        elsif(                         $code == &Wx::WXK_UP )       { $self->search_bar->_find_prev }
        elsif(                         $code == &Wx::WXK_DOWN )     { $self->search_bar->_find_next }
        elsif( $event->ShiftDown   and $code == &Wx::WXK_RETURN)    { $self->replace_prev  }
        elsif( $event->ControlDown and $code == &Wx::WXK_RETURN)    { $self->replace_all  }
        elsif(                         $code == &Wx::WXK_RETURN )   { $self->replace_next  }
        elsif( $event->ShiftDown   and $event->ControlDown and $code == ord('F')) { $self->editor->SetFocus  }
        elsif( $event->ControlDown and $code == ord('F'))           { $self->search_bar->enter  }
        elsif( $event->ControlDown and $code == ord('R'))           { $self->editor->SetFocus  }
        else { $event->Skip }
    });

    my $attr = &Wx::wxGROW | &Wx::wxTOP|&Wx::wxDOWN;
    my $sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
    $sizer->AddSpacer( 10);
    $sizer->Add( $self->{'lbl'},  0, $attr|&Wx::wxALIGN_CENTER_VERTICAL, 20);
    $sizer->AddSpacer( 15);
    $sizer->Add( $self->{'text'},  0, $attr, 10);
    $sizer->AddSpacer( 15);
    $sizer->Add( $self->{'once'},   0, $attr, 10);
    $sizer->AddSpacer( 10);
    $sizer->Add( $self->{'prev'},  0, $attr, 10);
    $sizer->AddSpacer( 10);
    $sizer->Add( $self->{'next'},  0, $attr, 10);
    $sizer->AddSpacer( 10);
    $sizer->Add( $self->{'sel'},   0, $attr, 10);
    $sizer->AddSpacer( 10);
    $sizer->Add( $self->{'all'},   0, $attr, 10);
    $sizer->AddSpacer( 40);
    $sizer->Add( $self->{'flbl'},  0, $attr, 20);
    $sizer->AddSpacer( 15);
    $sizer->Add( $self->{'fprev'},  0, $attr, 10);
    $sizer->AddSpacer( 10);
    $sizer->Add( $self->{'fnext'},  0, $attr, 10);
    $sizer->AddSpacer( 35);
    $sizer->Add( $self->{'rlbl'},  0, $attr, 20);
    $sizer->AddSpacer( 15);
    $sizer->Add( $self->{'rprev'},  0, $attr, 10);
    $sizer->AddSpacer( 10);
    $sizer->Add( $self->{'rnext'},  0, $attr, 10);
    $sizer->Add( 0, 1, &Wx::wxEXPAND, 0);
    #$sizer->Add( $self->{'close'}, 0, $attr, 15);
    #$sizer->AddSpacer( 10);
    $self->SetSizer($sizer);
    $self;
}

sub editor     { $_[0]->GetParent->{'editor'} }
sub search_bar { $_[0]->GetParent->{'searchbar'} }
sub replace_term { $_[0]->{'text'}->GetValue }

sub show {
    my ($self, $visible) = @_;
    $self->Show( $visible );
    $self->GetParent->Layout();
}

sub enter {
    my ($self) = @_;
    $self->search_bar->show(1);
    $self->show(1);
    my $sel = $self->editor->GetSelectedText;
    $self->{'text'}->SetValue( $sel ) if $sel;
    $self->{'text'}->SetFocus();
}

sub close {
    my ($self) = @_;
    $self->show(0);
    $self->editor->SetFocus;
}


sub find_prev {
    my ($self) = @_;
    my $ed = $self->editor;
    my ($start, $end) = $ed->GetSelection;
    my $wrap = $self->search_bar->{'wrap'}->GetValue;
    $ed->SetSelection( $start, $start );
    $ed->SearchAnchor;
    my $pos = $ed->SearchPrev( 0,  $self->replace_term );
    if ($pos == -1){
        $ed->SetSelection( $ed->GetLength , $ed->GetLength  );
        $ed->SearchAnchor();
        $pos = $ed->SearchPrev( 0,  $self->replace_term ) if $wrap;
        $ed->SetSelection( $start, $end ) if $pos == -1;
    }
    $ed->EnsureCaretVisible;
}
sub find_next {
    my ($self) = @_;
    my $ed = $self->editor;
    my ($start, $end) = $ed->GetSelection;
    my $wrap = $self->search_bar->{'wrap'}->GetValue;
    $ed->SetSelection( $end, $end );
    $ed->SearchAnchor;
    my $pos = $ed->SearchNext( 0,  $self->replace_term );
    if ($pos == -1){
        $ed->SetSelection( 0, 0 );
        $ed->SearchAnchor;
        $pos = $ed->SearchNext( 0,  $self->replace_term ) if $wrap;
        $ed->SetSelection( $start, $end ) if $pos == -1;
    }
    $ed->EnsureCaretVisible;
}

sub revert_prev {
    my ($self) = @_;
    $self->editor->ReplaceSelection( $self->search_bar->search_term );
    $self->find_prev;
}
sub revert_next {
    my ($self) = @_;
    $self->editor->ReplaceSelection( $self->search_bar->search_term );
    $self->find_next;
}

sub replace_prev {
    my ($self) = @_;
    my $ed = $self->editor;
    my ($start, $end) = $ed->GetSelection;
    $self->replace;
    $ed->SetSelection( $start, $start ) unless $self->search_bar->_find_prev;
}
sub replace_next {
    my ($self) = @_;
    my $ed = $self->editor;
    my ($start, $end) = $ed->GetSelection;
    $self->replace;
    $ed->SetSelection( $start, $start ) unless $self->search_bar->_find_next;
}

sub replace { $_[0]->editor->ReplaceSelection( $_[0]->replace_term ) }

sub replace_once {
    my ($self) = @_;
    my $ed = $self->editor;
    my ($start, $end) = $ed->GetSelection;
    $self->replace;
    $ed->SetSelection( $start, $start + length $self->replace_term);
}

sub replace_all {
    my ($self) = @_;
    my $ed = $self->editor;
    my ($start, $end) = $ed->GetSelection;
    $ed->BeginUndoAction();
    $ed->SetSelection( 0, 0 );
    $ed->SearchAnchor;
    $self->replace while $self->search_bar->_find_next;
    $ed->SetSelection( $start, $start );
    $ed->EnsureCaretVisible;
    $ed->EndUndoAction();
}

sub replace_in_selection {
    my ($self) = @_;
    my $ed = $self->editor;
    my ($start, $end) = $ed->GetSelection;
    $ed->BeginUndoAction();
    $ed->SetSelection( $end, $end );
    $ed->SearchAnchor();
    $self->replace while $self->search_bar->_find_prev and $ed->GetSelectionStart >= $start;
    $ed->SetSelection( $start, $start );
    $ed->EnsureCaretVisible;
    $ed->EndUndoAction();
}


1;
