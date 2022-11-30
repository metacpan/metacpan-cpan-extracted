use v5.12;
use warnings;

package Kephra::App::Editor::Move;

package Kephra::App::Editor;

sub move_line {
    my ($ed, $from, $to) = @_;
    return unless defined $to and $from < $ed->GetLineCount and $to < $ed->GetLineCount;
    $from = $ed->GetLineCount + $from if $from < 0;
    $to =   $ed->GetLineCount + $to   if $to < 0;
    return if $from == $to;
    my $last_line_nr = $ed->GetLineCount - 1;
    if ($from  == $last_line_nr) {
        $ed->GotoLine( $from );
        $ed->LineTranspose;
        $from--;
    }
    $ed->SetSelection( $ed->PositionFromLine( $from ),
                         $ed->PositionFromLine( $from + 1 ) );
    my $line = $ed->GetSelectedText( );
    $ed->ReplaceSelection( '' );
    if ($to == $last_line_nr) {
        $ed->InsertText( $ed->PositionFromLine($to - 1), $line );
        $ed->GotoLine( $to );
        $ed->LineTranspose;
    } else { $ed->InsertText( $ed->PositionFromLine($to), $line ) }
}

sub move_block {
    my ($ed, $begin, $size, $newbegin) = @_;
    return unless defined $newbegin and $begin < $ed->GetLineCount
                                    and $size    < $ed->GetLineCount and $size > 0 
                                    and $newbegin  < $ed->GetLineCount and $begin != $newbegin;
    $begin    = $ed->GetLineCount + $begin    if $begin < 0;
    $newbegin = $ed->GetLineCount + $newbegin if $newbegin < 0;
    
    $ed->GotoPos( $ed->GetTextLength );
    $ed->NewLine ();
    $ed->SetSelection( $ed->PositionFromLine( $begin ),
                         $ed->PositionFromLine( $begin + $size ) );
    my $text = $ed->GetSelectedText( );
    $ed->ReplaceSelection( '' );
    $ed->InsertText( $ed->PositionFromLine( $newbegin ), $text );
    $ed->SetSelection( $ed->GetLineEndPosition( $ed->GetLineCount - 2 ),
                       $ed->PositionFromLine( $ed->GetLineCount - 1)    );
    $ed->ReplaceSelection( '' );
}

sub move_up {
    my ($ed) = @_;
    return if $ed->SelectionIsRectangle;
    my ($start_pos, $end_pos) = $ed->GetSelection;
    my $start_line = $ed->LineFromPosition( $start_pos );
    return unless $start_line; # need space above
    my $end_line = $ed->LineFromPosition( $end_pos );
    my $start_col =  $ed->GetColumn( $start_pos );
    $ed->BeginUndoAction();
    if ($start_pos == $end_pos) {
        $ed->LineTranspose;
        $ed->GotoPos ( $ed->PositionFromLine( $start_line - 1 ) + $start_col);
    } elsif ($start_line != $end_line) {
        $ed->move_line( $start_line - 1, $end_line);
        $ed->SetSelection( $ed->PositionFromLine( $start_line - 1 ),
                           $ed->GetLineEndPosition( $end_line - 1 ) );
    } else {
        my $target_pos = $ed->PositionFromLine( $start_line - 1 ) + $start_col;
        $target_pos = $ed->GetLineEndPosition( $start_line - 1 ) if $ed->GetLineEndPosition( $start_line - 1 ) < $target_pos;
        my $text = $ed->GetSelectedText( );
        $ed->ReplaceSelection( '' );
        $ed->InsertText( $target_pos, $text );
        $ed->SetSelection( $target_pos, $target_pos + length $text);
    }
    $ed->EndUndoAction();
}

sub move_down {
    my ($ed) = @_;
    return if $ed->SelectionIsRectangle;
    my ($start_pos, $end_pos) = $ed->GetSelection;
    my $start_line = $ed->LineFromPosition( $start_pos );
    my $end_line  = $ed->LineFromPosition( $end_pos );
    my $start_col = $ed->GetColumn( $start_pos );
    my $end_col   = $ed->GetColumn( $end_pos );
    $ed->BeginUndoAction();
    if ( $end_line + 1 == $ed->GetLineCount ) {
        $ed->GotoLine( $start_line );
        $ed->NewLine;
        if     ($start_pos == $end_pos)  { $ed->GotoPos ( $ed->PositionFromLine( $start_line + 1 ) + $start_col) }
        elsif ($start_line != $end_line) { $ed->SetSelection( $ed->PositionFromLine( $start_line + 1 ) ,
                                                              $ed->GetLineEndPosition( $end_line + 1 )  ) }
        else                             { my $next_line_pos = $ed->PositionFromLine( $start_line + 1 );
                                           $ed->SetSelection( $next_line_pos + $start_col, $next_line_pos + $end_col) }
    } elsif ($start_pos == $end_pos) {
        $ed->GotoLine( $start_line + 1 );
        $ed->LineTranspose;
        $ed->GotoPos ( $ed->PositionFromLine( $start_line + 1 ) + $start_col);
    } elsif ($start_line != $end_line) {
        $ed->move_line( $end_line + 1, $start_line);
        $ed->SetSelection( $ed->PositionFromLine( $start_line + 1 ) ,
                           $ed->GetLineEndPosition( $end_line + 1 )  );
    } else {
        my $text = $ed->GetSelectedText( );
        $ed->ReplaceSelection( '' );
        my $target_pos = $ed->PositionFromLine( $start_line + 1 ) + $start_col;
        $target_pos = $ed->GetLineEndPosition( $start_line + 1 ) if $ed->GetLineEndPosition( $start_line + 1 ) < $target_pos;
        $ed->InsertText( $target_pos, $text );
        $ed->SetSelection( $target_pos, $target_pos + length $text);
    }
    $ed->EndUndoAction();
}

sub move_page_up {
    my ($ed) = @_;
    return if $ed->SelectionIsRectangle;
    my ($start_pos, $end_pos) = $ed->GetSelection;
    my $start_line = $ed->LineFromPosition( $start_pos );
    return unless $start_line; # need space above
    my $end_line = $ed->LineFromPosition( $end_pos );
    my $start_col =  $ed->GetColumn( $start_pos );
    my $target_line = $start_line - 50;
    $target_line = 0 if $target_line < 0;
    $ed->BeginUndoAction();
    if ($start_pos == $end_pos) {
        $ed->move_line( $start_line, $target_line);
        $ed->SetSelection( $ed->PositionFromLine( $target_line ) + $start_col,
                           $ed->PositionFromLine( $target_line ) + $start_col );

    } elsif ($start_line != $end_line) {
        my $end_col = $ed->GetColumn( $end_pos );
        $ed->move_block( $start_line, $end_line - $start_line + 1, $target_line);
        $ed->SetSelection( $ed->PositionFromLine( $target_line ),
                           $ed->GetLineEndPosition( $target_line - $start_line + $end_line ) );
    } else {
        my $text = $ed->GetSelectedText( );
        $ed->ReplaceSelection( '' );
        my $target_pos = $ed->PositionFromLine( $target_line ) + $start_col;
        $target_pos = $ed->GetLineEndPosition( $target_line ) if $ed->GetLineEndPosition( $target_line ) < $target_pos;
        $ed->InsertText( $target_pos, $text );
        $ed->SetSelection( $target_pos, $target_pos + length $text);
    }
    $ed->EndUndoAction();
    $ed->ScrollToLine( $target_line - $start_line + $end_line + 5 );
    $ed->ScrollToLine( $target_line - 5 );
}

sub move_page_down {
    my ($ed) = @_;
    return if $ed->SelectionIsRectangle;
    my ($start_pos, $end_pos) = $ed->GetSelection;
    my $start_line = $ed->LineFromPosition( $start_pos );
    my $end_line = $ed->LineFromPosition( $end_pos );
    my $start_col =  $ed->GetColumn( $start_pos );
    my $target_line = $start_line + 50;
    my $last_possible_line = $ed->GetLineCount - 1 - $end_line + $start_line;
    $target_line = $last_possible_line if $target_line > $last_possible_line;
    $ed->BeginUndoAction();
    if ($start_pos == $end_pos) {
        $ed->move_line( $start_line, $target_line);
        $ed->SetSelection( $ed->PositionFromLine( $target_line ) + $start_col,
                           $ed->PositionFromLine( $target_line ) + $start_col );
    } elsif ($start_line != $end_line) {
        my $end_col = $ed->GetColumn( $end_pos );
        $ed->move_block( $start_line, $end_line - $start_line + 1, $target_line);
        $ed->SetSelection( $ed->PositionFromLine( $target_line ),
                           $ed->GetLineEndPosition( $target_line - $start_line + $end_line ) );
    } else {  
        my $text = $ed->GetSelectedText( );
        $ed->ReplaceSelection( '' );
        my $target_pos = $ed->PositionFromLine( $target_line ) + $start_col;
        $target_pos = $ed->GetLineEndPosition( $target_line ) if $ed->GetLineEndPosition( $target_line ) < $target_pos;
        $ed->InsertText( $target_pos, $text );
        $ed->SetSelection( $target_pos, $target_pos + length $text);
    }
    $ed->EndUndoAction();
    $ed->ScrollToLine( $target_line - $start_line + $end_line + 5 );
    $ed->ScrollToLine( $target_line - 5 );
}

sub move_to_start {
    my ($ed) = @_;
    return if $ed->SelectionIsRectangle;
    my ($start_pos, $end_pos) = $ed->GetSelection;
    my $start_line = $ed->LineFromPosition( $start_pos );
    my $end_line = $ed->LineFromPosition( $end_pos );
    my $start_col =  $ed->GetColumn( $start_pos );
    my $end_col = $ed->GetColumn( $end_pos );
    return unless $start_line; # need space above    GetFirstVisibleLine
    my $target_line = 0;
    $ed->BeginUndoAction();
    if ($start_pos == $end_pos) {
        $ed->move_line( $start_line, $target_line);
        $ed->SetSelection( $ed->PositionFromLine( $target_line ) + $start_col,
                           $ed->PositionFromLine( $target_line ) + $start_col );
    } elsif ($start_line != $end_line) {
        $ed->move_block( $start_line, $end_line - $start_line + 1, $target_line);
        $ed->SetSelection( $ed->PositionFromLine( $target_line ),
                           $ed->GetLineEndPosition( $target_line - $start_line + $end_line )  );
    } else {
        my $text = $ed->GetSelectedText( );
        $ed->ReplaceSelection( '' );
        my $target_pos = $ed->PositionFromLine( 0 ) + $start_col;
        $target_pos = $ed->GetLineEndPosition( 0 ) if $ed->GetLineEndPosition( 0 ) < $target_pos;
        $ed->InsertText( $target_pos, $text );
        $ed->SetSelection( $target_pos, $target_pos + length $text);
    }
    $ed->EndUndoAction();
    $ed->ScrollToLine( 0 );
}

sub move_to_end {
    my ($ed) = @_;
    return if $ed->SelectionIsRectangle;
    my ($start_pos, $end_pos) = $ed->GetSelection;
    my $start_line = $ed->LineFromPosition( $start_pos );
    my $end_line = $ed->LineFromPosition( $end_pos );
    my $start_col =  $ed->GetColumn( $start_pos );
    my $end_col = $ed->GetColumn( $end_pos );
    my $last_line = $ed->GetLineCount - 1;
    my $target_line = $last_line - $end_line + $start_line;
    $ed->BeginUndoAction();
    if ($start_pos == $end_pos) {
        $ed->move_line( $start_line, $last_line);
        $ed->SetSelection( $ed->PositionFromLine( $target_line ) + $start_col,
                           $ed->PositionFromLine( $target_line ) + $start_col );
    } elsif ($start_line != $end_line) {
        $ed->move_block( $start_line, $end_line - $start_line + 1, $target_line);
        $ed->SetSelection( $ed->PositionFromLine( $target_line ),
                           $ed->GetLineEndPosition( $target_line - $start_line + $end_line ) );
    } else { 
        my $text = $ed->GetSelectedText( );
        $ed->ReplaceSelection( '' );
        my $target_pos = $ed->PositionFromLine( $target_line ) + $start_col;
        $target_pos = $ed->GetLineEndPosition( $target_line ) if $ed->GetLineEndPosition( $target_line ) < $target_pos;
        $ed->InsertText( $target_pos, $text );
        $ed->SetSelection( $target_pos, $target_pos + length $text);
    }
    $ed->EndUndoAction();
    $ed->ScrollToLine( $last_line );
}

sub move_line_left {
    my ($ed, $line_nr) = @_;
    return 0 unless defined $line_nr;
    $ed->SetSelection( $ed->PositionFromLine( $line_nr ),
                       $ed->PositionFromLine( $line_nr ) + 1  );
    my $s = $ed->GetSelectedText;
    $s = $ed->{tab_space} if $s eq "\t";
    if (substr( $s, 0, 1 ) eq ' '){ chop $s }
    else                          { return 0 }
    $ed->ReplaceSelection( $s );
    return 1;
}

sub move_line_right {
    my ($ed, $line_nr) = @_;
    return unless defined $line_nr;
    $ed->SetSelection( $ed->PositionFromLine( $line_nr ),
                         $ed->GetLineEndPosition( $line_nr )  );
    my $line = $ed->GetSelectedText( );
    $line =~ s/\t/$ed->{tab_space}/g if $line =~ /\t/;
    $ed->ReplaceSelection( ' '.$line );
}

sub move_left {
    my ($ed) = @_;
    return if $ed->SelectionIsRectangle;
    my ($start_pos, $end_pos) = $ed->GetSelection;
    my $start_line = $ed->LineFromPosition( $start_pos );
    my $end_line = $ed->LineFromPosition( $end_pos );
    my $start_col =  $ed->GetColumn( $start_pos );
    $ed->BeginUndoAction();
    if ($start_pos == $end_pos) {
        $start_pos-- if $ed->move_line_left( $start_line ) and $start_col;
        $ed->GotoPos ( $start_pos );
    } elsif ($start_line != $end_line) {
        my $end_col = $ed->GetColumn( $end_pos );
        $start_pos-- if $ed->move_line_left( $start_line ) and $end_col;
        $end_col-- if $ed->move_line_left( $end_line );
        $ed->move_line_left( $_ ) for $start_line + 1 .. $end_line - 1;
        $ed->SetSelection( $ed->PositionFromLine( $start_line ), $ed->GetLineEndPosition( $end_line ) );
    } else {
        return unless $start_col;      
        my $text = $ed->GetSelectedText( );
        $ed->ReplaceSelection( '' );
        $ed->InsertText( $start_pos - 1, $text );
        $ed->SetSelection( $start_pos - 1, $end_pos - 1);
    }
    $ed->EndUndoAction();
}

sub move_right {
    my ($ed) = @_;
    return if $ed->SelectionIsRectangle;
    my ($start_pos, $end_pos) = $ed->GetSelection;
    my $start_line = $ed->LineFromPosition( $start_pos );
    my $end_line = $ed->LineFromPosition( $end_pos );
    $ed->BeginUndoAction();
    if ($start_pos == $end_pos) {
        $ed->move_line_right( $start_line );
        $ed->GotoPos ( $start_pos + 1);
    } elsif ($start_line != $end_line) {
        $ed->move_line_right( $_ ) for $start_line .. $end_line;
        $ed->SetSelection( $ed->PositionFromLine( $start_line ), $ed->GetLineEndPosition( $end_line ) );
    }  else {
        my $end_col = $ed->GetColumn( $end_pos );
        return if $end_pos == $ed->GetLineEndPosition( $end_line );
        my $text = $ed->GetSelectedText( );
        $ed->ReplaceSelection( '' );
        $ed->InsertText( $start_pos + 1, $text );
        $ed->SetSelection( $start_pos + 1, $end_pos + 1);
    }
    $ed->EndUndoAction();
}

1;
