use v5.12;
use warnings;
use Wx;

package Kephra::App::Editor::SyntaxMode::No;


sub set {
    my ($self) = @_;
    $self->StyleClearAll;
    $self->SetLexer( &Wx::wxSTC_LEX_NULL );         # Set Lexers to use
    $self->SetKeyWords(0, '');
}

1;
