use v5.12;
use warnings;

package Kephra::App::Editor::View;
package Kephra::App::Editor;

sub set_margin {
    my ($self, $style) = @_;

    if (not defined $style or not $style or $style eq 'default') {
        $self->SetMarginType( 0, &Wx::wxSTC_MARGIN_SYMBOL );
        $self->SetMarginType( 1, &Wx::wxSTC_MARGIN_NUMBER );
        $self->SetMarginType( 2, &Wx::wxSTC_MARGIN_SYMBOL );
        $self->SetMarginType( 3, &Wx::wxSTC_MARGIN_SYMBOL );
        $self->SetMarginMask( 0, 0x01FFFFFF );
        $self->SetMarginMask( 1, 0 );
        $self->SetMarginMask( 2, 0x01FFFFFF); #  | &Wx::wxSTC_MASK_FOLDERS
        $self->SetMarginMask( 3, &Wx::wxSTC_MASK_FOLDERS );
        $self->SetMarginSensitive( 0, 1 );
        $self->SetMarginSensitive( 1, 1 );
        $self->SetMarginSensitive( 2, 1 );
        $self->SetMarginSensitive( 3, 0 );
        $self->SetMarginWidth(0,  1);
        $self->SetMarginWidth(1, 47);
        $self->SetMarginWidth(2, 22);
        $self->SetMarginWidth(3,  2);
        # extra text margin
    }
    elsif ($style eq 'no') { $self->SetMarginWidth($_, 0) for 1..3 }

    # extra margin left and right inside the white text area
    $self->SetMargins(2, 2);
    $self;
}

sub view_whitespace_mode { int $_[0]->GetViewWhiteSpace }
sub toggle_view_whitespace {
    my ($self) = @_;
    my $visible = ! $self->view_whitespace_mode;
    $self->SetViewWhiteSpace( $visible );
    $self->GetParent->GetMenuBar->Check(16110, $visible);
}

sub view_eol_mode { int $_[0]->GetViewEOL }
sub toggle_view_eol {
    my ($self) = @_;
    my $visible = ! $self->view_eol_mode;
    $self->SetViewEOL( $visible );
    $self->GetParent->GetMenuBar->Check(16120, $visible);
}

sub indent_guide_mode { int $_[0]->GetIndentationGuides }
sub toggle_view_indent_guide {
    my ($self) = @_;
    my $visible = ! $self->indent_guide_mode;
    $self->SetIndentationGuides( $visible );
    $self->GetParent->GetMenuBar->Check(16130, $visible);
}

sub right_margin_mode { int $_[0]->GetEdgeMode }
sub toggle_view_right_margin {
    my ($self) = @_;
    my $visible = ! $self->right_margin_mode;
    $self->SetEdgeMode( $visible ? &Wx::wxSTC_EDGE_LINE : 0 );
    $self->GetParent->GetMenuBar->Check(16140, $visible ? 1 : 0);
}

sub line_nr_margin_mode { int $_[0]->GetMarginWidth(1) }
sub toggle_view_line_nr_margin {
    my ($self) = @_;
    my $visible = ! $self->line_nr_margin_mode;
    $self->SetMarginWidth(1, ($visible ? 47 : 0) );
    $self->GetParent->GetMenuBar->Check(16210, $visible ? 1 : 0);
}

sub marker_margin_mode { int $_[0]->GetMarginWidth(2) }
sub toggle_view_marker_margin {
    my ($self) = @_;
    my $visible = ! $self->marker_margin_mode;
    $self->SetMarginWidth(2, ($visible ? 22 : 0) );
    $self->GetParent->GetMenuBar->Check(16220, $visible ? 1 : 0);
}

sub line_wrap_mode { int $_[0]->GetWrapMode }
sub toggle_view_line_wrap {
    my ($self) = @_;
    my $on = ! $self->line_wrap_mode;
    $self->SetWrapMode( $on );
    $self->GetParent->GetMenuBar->Check( 16420, $on );
}

sub view_caret_line_mode { int $_[0]->GetCaretLineVisible }
sub toggle_view_caret_line {
    my ($self) = @_;
    my $on = ! $self->view_caret_line_mode;
    $self->SetCaretLineVisible( $on );
    $self->GetParent->GetMenuBar->Check( 16430, $on );
}

sub get_zoom_level { $_[0]->GetZoom }
sub set_zoom_level {
    my ($self, $level) = @_;
    $self->SetZoom( $level );
    $self->GetParent->GetMenuBar->Check( 16340+$level, 1 );
}

sub zoom_in {
    my ($self, $level) = @_;
    my $lvl = $self->get_zoom_level();
    $lvl++;
    $lvl = 20 if $lvl > 20;
    $self->set_zoom_level( $lvl );
}
sub zoom_out {
    my ($self, $level) = @_;
    my $lvl = $self->get_zoom_level( );
    $lvl--;
    $lvl = -10 if $lvl < -10;
    $self->set_zoom_level( $lvl );
}

1;
