use v5.12;
use warnings;
use Wx;

package Kephra::App::Editor::SyntaxMode::Ruby;


sub set {
    my ($self) = @_;
    $self->StyleClearAll;
    $self->SetLexer( &Wx::wxSTC_LEX_RUBY );         # Set Lexers to use
    $self->SetKeyWords(0, '');
}

1;
