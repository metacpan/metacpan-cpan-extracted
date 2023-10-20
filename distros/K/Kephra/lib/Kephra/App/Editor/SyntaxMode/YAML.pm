use v5.12;
use warnings;
use Wx;

package Kephra::App::Editor::SyntaxMode::YAML;


sub set {
    my ($self) = @_;
    $self->StyleClearAll;
    $self->SetLexer( &Wx::wxSTC_LEX_YAML );
    $self->SetKeyWords(0, '');
}

1;
