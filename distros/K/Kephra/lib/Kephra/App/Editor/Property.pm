use v5.12;
use warnings;

package Kephra::App::Editor::Property;

package Kephra::App::Editor;



sub set_tab_size {
    my ($self, $size) = @_;
    return unless defined $size;
    #$size *= 2 if $^O eq 'darwin';
    $self->SetTabWidth($size);
    $self->SetIndent($size);
    $self->SetHighlightGuide($size);
    $self->{'tab_size'} = $size;
    $self->{'tab_space'} = ' ' x $self->{'tab_size'};
    my $menu = $self->GetParent->GetMenuBar;
    $menu->Check( 15200 + $size, 1 ) if ref $menu;

}

sub set_tab_usage {
    my ($self, $usage) = @_;
    $self->SetUseTabs($usage);
}

sub toggle_tab_usage {
    my ($self) = @_;
    $self->{'tab_usage'} = !$self->GetUseTabs();
    $self->set_tab_usage( $self->{'tab_usage'} );
    $self->GetParent->GetMenuBar->Check(15100, !$self->{'tab_usage'});
}


sub get_EOL {
    my ($self) = @_;
    my $mode = $self->GetEOLMode();
    return 'lf' if $mode == &Wx::wxSTC_EOL_LF;
    return 'cr' if $mode == &Wx::wxSTC_EOL_CR;
    return 'crlf' if $mode == &Wx::wxSTC_EOL_CRLF;
    return '';
}

sub set_EOL {
    my ($self, $mode) = @_;
    return unless defined $mode;
    return $self->set_EOL_lf() if $mode eq 'lf';
    return $self->set_EOL_cr() if $mode eq 'cr';
    return $self->set_EOL_crlf() if $mode eq 'crlf';
}

sub set_EOL_lf   {
    my ($self) = @_;
    $self->SetEOLMode( &Wx::wxSTC_EOL_LF );
    $self->ConvertEOLs( &Wx::wxSTC_EOL_LF );
    $self->GetParent->GetMenuBar->Check(15411, 1);
}

sub set_EOL_cr   {
    my ($self) = @_;
    $self->SetEOLMode( &Wx::wxSTC_EOL_CR );
    $self->ConvertEOLs( &Wx::wxSTC_EOL_CR );
    $self->GetParent->GetMenuBar->Check(15412, 1);
}

sub set_EOL_crlf {
    my ($self) = @_;
    $self->SetEOLMode( &Wx::wxSTC_EOL_CRLF );
    $self->ConvertEOLs( &Wx::wxSTC_EOL_CRLF );
    $self->GetParent->GetMenuBar->Check(15413, 1);
}

sub get_encoding {
    my ($self) = @_;
}

sub set_encoding {
    my ($self, $encoding) = @_;
}


1;
