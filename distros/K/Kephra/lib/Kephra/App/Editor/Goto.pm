use v5.12;
use warnings;

package Kephra::App::Editor::Goto;
package Kephra::App::Editor;

sub caret_left {
    my ($self) = @_;
    $self->del_caret_pos_cache();
    $self->GotoPos( $self->GetCurrentPos - 1 );
}
sub caret_right {
    my ($self) = @_;
    $self->del_caret_pos_cache();
    $self->GotoPos( $self->GetCurrentPos + 1 );
}
sub caret_home {
    my ($self) = @_;
    $self->del_caret_pos_cache();
    $self->GotoPos( $self->PositionFromLine( $self->GetCurrentLine  ) );
}
sub caret_end {
    my ($self) = @_;
    $self->del_caret_pos_cache();
    $self->GotoPos( $self->GetLineEndPosition( $self->GetCurrentLine  ) );
}

sub caret_up {
    my ($self) = @_;
    $self->GotoPos( $self->column_in_prev_lines( $self->GetCurrentPos, 1) );
}
sub caret_down {
    my ($self) = @_;
    $self->GotoPos( $self->column_in_next_lines( $self->GetCurrentPos, 1) );
}

my $page_size = 45;
sub caret_page_up {
    my ($self) = @_;
    $self->GotoPos( $self->column_in_prev_lines( $self->GetCurrentPos, $page_size) );
}
sub caret_page_down {
    my ($self) = @_;
    $self->GotoPos( $self->column_in_next_lines( $self->GetCurrentPos, $page_size) );
}

sub select_left {
    my ($self) = @_;
    my ($sel_start, $sel_end) = $self->GetSelection;
    my $pos = $self->GetCurrentPos;
    $self->del_caret_pos_cache();
    $self->GotoPos( $pos - 1 );
    if ($sel_start == $pos){ $self->SetAnchor($sel_end) }
    else                   { $self->SetAnchor($sel_start) }
}
sub select_right {
    my ($self) = @_;
    my ($sel_start, $sel_end) = $self->GetSelection;
    my $pos = $self->GetCurrentPos;
    $self->del_caret_pos_cache();
    $self->GotoPos( $pos + 1 );
    if ($sel_start == $pos){ $self->SetAnchor($sel_end) }
    else                   { $self->SetAnchor($sel_start) }
}

sub select_up {
    my ($self) = @_;
    my ($sel_start, $sel_end) = $self->GetSelection;
    my $pos = $self->GetCurrentPos;
    my $new_pos = $self->column_in_prev_lines( $pos, 1);
    $self->GotoPos( $new_pos );
    if ($sel_start == $pos){ $self->SetAnchor($sel_end) }
    else                   { $self->SetAnchor($sel_start) }
}
sub select_down {
    my ($self) = @_;
    my ($sel_start, $sel_end) = $self->GetSelection;
    my $pos = $self->GetCurrentPos;
    my $new_pos = $self->column_in_next_lines( $pos, 1);
    $self->GotoPos( $new_pos );
    if ($sel_start == $pos){ $self->SetAnchor($sel_end) }
    else                   { $self->SetAnchor($sel_start) }
}

sub select_page_up {
    my ($self) = @_;
    my ($sel_start, $sel_end) = $self->GetSelection;
    my $pos = $self->GetCurrentPos;
    my $new_pos = $self->column_in_prev_lines( $pos, $page_size);
    $self->GotoPos( $new_pos );
    if ($sel_start == $pos){ $self->SetAnchor($sel_end) }
    else                   { $self->SetAnchor($sel_start) }
}
sub select_page_down {
    my ($self) = @_;
    my ($sel_start, $sel_end) = $self->GetSelection;
    my $pos = $self->GetCurrentPos;
    my $new_pos = $self->column_in_next_lines( $pos, $page_size);
    $self->GotoPos( $new_pos );
    if ($sel_start == $pos){ $self->SetAnchor($sel_end) }
    else                   { $self->SetAnchor($sel_start) }
}



sub goto_last_edit {
    my ($self) = @_;
    return $self->GotoPos( $self->{'change_pos'} ) unless $self->GetCurrentPos == $self->{'change_pos'} or $self->{'change_pos'} == -1;
    $self->GotoPos( $self->{'change_prev'} ) unless $self->{'change_prev'} == -1;
}


sub init_marker {
    my $self = shift;
    $self->{'marker'} = {};
    for my $line (@_) {
        $self->{'marker'}{ $line }++;
        $self->MarkerAdd( $line, 1)
    }
}

sub marker_lines {
    my ($self) = @_;
    return sort keys %{$self->{'marker'}};
}


sub toggle_marker {
    my ($self) = @_;
    my $line = 	$self->GetCurrentLine ();
    $self->MarkerGet( $line ) ? delete $self->{'marker'}{$line} : $self->{'marker'}{$line}++;
    $self->MarkerGet( $line ) ? $self->MarkerDelete( $line, 1) : $self->MarkerAdd( $line, 1);
}

sub delete_all_marker { $_[0]->MarkerDeleteAll(1); $_[0]->{'marker'} = {}; }

sub goto_prev_marker {
    my ($self) = @_;
    my $line = 	$self->GetCurrentLine ();
    $line-- if $self->MarkerGet( $line );
    my $target = $self->MarkerPrevious ( $line, 2);
    $target = $self->MarkerPrevious ( $self->GetLineCount, 2 ) if $target == -1;
    $self->GotoLine( $target ) if $target > -1;
}

sub goto_next_marker {
    my ($self) = @_;
    my $line = 	$self->GetCurrentLine ();
    $line++ if $self->MarkerGet( $line );
    my $target = $self->MarkerNext( $line, 2);
    $target = $self->MarkerNext( 0, 2 ) if $target == -1;
    $self->GotoLine( $target ) if $target > -1;
}

sub goto_prev_block {
    my ($self) = @_;
    $self->GotoPos( $self->smart_up_pos );
    $self->EnsureCaretVisible;
}

sub goto_next_block {
    my ($self) = @_;
    $self->GotoPos( $self->smart_down_pos );
    $self->EnsureCaretVisible;
}

sub goto_prev_sub {
    my ($self) = @_;
    my $pos = $self->GetCurrentPos;
    my $new_pos = $self->prev_sub;
    if ($new_pos > -1) { $self->GotoPos( $self->GetCurrentPos ) }
    else               { $self->GotoPos( $pos )  }

}
sub goto_next_sub {
    my ($self) = @_;
    my $pos = $self->GetCurrentPos;
    my $new_pos = $self->next_sub;
    if ($new_pos > -1) { $self->GotoPos( $self->GetCurrentPos ) }
    else               { $self->GotoPos( $pos )  }
}

1;

