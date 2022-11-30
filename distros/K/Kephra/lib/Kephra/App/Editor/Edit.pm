use v5.12;
use warnings;

package Kephra::App::Editor::Edit;

package Kephra::App::Editor;

sub copy {
    my $self = shift;
    my ($start_pos, $end_pos) = $self->GetSelection;
    $start_pos == $end_pos ? $self->LineCopy : $self->Copy;
}

sub cut {
    my $self = shift;
    my ($start_pos, $end_pos) = $self->GetSelection;
    $start_pos == $end_pos ? $self->LineCut : $self->Cut;
}
    
sub duplicate {
    my $self = shift;
    my ($start_pos, $end_pos) = $self->GetSelection;
    $start_pos == $end_pos ? $self->LineDuplicate : $self->SelectionDuplicate;
}
    
sub replace {
    my $self = shift;
    my $sel = $self->GetSelectedText();
    return unless $sel;
    my ($old_start, $old_end) = $self->GetSelection;
    $self->BeginUndoAction();
    $self->SetSelectionEnd( $old_start );
    $self->Paste;
    my $new_start = $self->GetSelectionStart( );
    my $new_end = $self->GetSelectionEnd( );
    $self->SetSelection( $new_end, $new_end + $old_end - $old_start);
    $self->Cut;
    $self->SetSelection( $new_start, $new_end);
    $self->EndUndoAction();
}


sub insert_text {
    my ($self, $text, $pos) = @_;
    $pos = $self->GetCurrentPos unless defined $pos;
    $self->InsertText($pos, $text);
    $pos += length $text;
    $self->SetSelection( $pos, $pos );
}

1;
