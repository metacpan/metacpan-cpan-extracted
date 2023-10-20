use v5.12;
use warnings;
use Wx;

package Kephra::App::Editor::SyntaxMode::Rust;


sub set {
    my ($self) = @_;
    $self->StyleClearAll;
    $self->SetLexer( 111 ); #&Wx::wxSTC_LEX_RUST
    $self->SetKeyWords(0, '');
}

1;
