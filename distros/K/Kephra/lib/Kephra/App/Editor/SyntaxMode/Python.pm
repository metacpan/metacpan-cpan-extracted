use v5.12;
use warnings;
use Wx;

package Kephra::App::Editor::SyntaxMode::Python;


sub set {
    my ($self) = @_;
    $self->StyleClearAll;
    $self->SetLexer( &Wx::wxSTC_LEX_PYTHON );         # Set Lexers to use
    $self->SetKeyWords(0, '');
}

1;
