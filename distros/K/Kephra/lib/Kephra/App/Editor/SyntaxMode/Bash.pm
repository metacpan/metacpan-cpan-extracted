use v5.12;
use warnings;
use Wx;

package Kephra::App::Editor::SyntaxMode::Bash;


sub set {
    my ($self) = @_;
    $self->StyleClearAll;
    $self->SetLexer( &Wx::wxSTC_LEX_BASH );
    $self->SetKeyWords(0, '');
}

1;
