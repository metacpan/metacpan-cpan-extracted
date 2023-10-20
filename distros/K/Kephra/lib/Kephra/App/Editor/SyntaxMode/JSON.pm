use v5.12;
use warnings;
use Wx;

package Kephra::App::Editor::SyntaxMode::JSON;


sub set {
    my ($self) = @_;
    $self->StyleClearAll;
    $self->SetLexer( 120 ); # &Wx::wxSTC_LEX_JSON
    $self->SetKeyWords(0, '');
}

1;
