use v5.12;
use warnings;

package Kephra::App::Editor::SyntaxMode;
use Wx qw/ :everything /;
use Wx::STC;
#use Wx::Scintilla;

sub apply {
    my ($self) = @_;
    set( $self, 'perl' );
    set_colors( $self ); # after highlight
}

sub set_colors {
    my $self = shift;
    $self->SetCaretPeriod( 600 );
    $self->SetCaretForeground( create_color( 0, 0, 100) ); #140, 160, 255
    $self->SetCaretLineBack( create_color(230, 230, 250) );
    $self->SetCaretWidth( 2 );
    $self->SetCaretLineVisible(1);

    $self->SetSelForeground( 1, create_color(243,243,243) );
    $self->SetSelBackground( 1, create_color(0, 17, 119) );
    $self->SetWhitespaceForeground( 1, create_color(160, 160, 143) );
    $self->SetViewWhiteSpace(1);

    $self->StyleSetForeground(&Wx::wxSTC_STYLE_INDENTGUIDE, create_color(206,206,202)); # 37
    $self->StyleSetForeground(&Wx::wxSTC_STYLE_LINENUMBER, create_color(93,93,97));    # 33
    $self->StyleSetBackground(&Wx::wxSTC_STYLE_LINENUMBER, create_color(206,206,202));

    $self->SetEdgeColour( create_color(200,200,255) );
    $self->SetEdgeColumn( 80 );
    $self->SetEdgeMode( &Wx::wxSTC_EDGE_LINE );
}
sub create_color { Wx::Colour->new(@_) }

sub set {
    my ($self, $mode) = @_;
    if ($mode eq 'perl'){
        require Kephra::App::Editor::SyntaxMode::Perl;
        Kephra::App::Editor::SyntaxMode::Perl::set($self);
    } elsif ($mode eq 'python'){
        require Kephra::App::Editor::SyntaxMode::Python;
        Kephra::App::Editor::SyntaxMode::Python::set($self);
    } elsif ($mode eq 'ruby'){
        require Kephra::App::Editor::SyntaxMode::Ruby;
        Kephra::App::Editor::SyntaxMode::Ruby::set($self);
    } elsif ($mode eq 'rust'){
        require Kephra::App::Editor::SyntaxMode::Rust;
        Kephra::App::Editor::SyntaxMode::Rust::set($self);
    } elsif ($mode eq 'cpp'){
        require Kephra::App::Editor::SyntaxMode::CPP;
        Kephra::App::Editor::SyntaxMode::CPP::set($self);
    } elsif ($mode eq 'bash'){
        require Kephra::App::Editor::SyntaxMode::Bash;
        Kephra::App::Editor::SyntaxMode::Bash::set($self);
    } elsif ($mode eq 'json'){
        require Kephra::App::Editor::SyntaxMode::JSON;
        Kephra::App::Editor::SyntaxMode::JSON::set($self);
    } elsif ($mode eq 'markdown'){
        require Kephra::App::Editor::SyntaxMode::Markdown;
        Kephra::App::Editor::SyntaxMode::Markdown::set($self);
    } elsif ($mode eq 'yaml'){
        require Kephra::App::Editor::SyntaxMode::YAML;
        Kephra::App::Editor::SyntaxMode::YAML::set($self);
    } else {
        require Kephra::App::Editor::SyntaxMode::No;
        Kephra::App::Editor::SyntaxMode::No::set($self);
    }
}

1;

