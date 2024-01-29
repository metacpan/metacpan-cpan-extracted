use v5.12;
use warnings;

package Kephra::App::Editor;
our @ISA = 'Wx::StyledTextCtrl';
use Wx qw/ :everything /;
use Wx::STC;
use Wx::DND;
#use Wx::Scintilla;
use Kephra::App::Editor::Edit;
use Kephra::App::Editor::Events;
use Kephra::App::Editor::Goto;
use Kephra::App::Editor::Move;
use Kephra::App::Editor::Position;
use Kephra::App::Editor::Property;
use Kephra::App::Editor::Select;
use Kephra::App::Editor::SyntaxMode;
use Kephra::App::Editor::Tool;
use Kephra::App::Editor::View;

sub new {
    my( $class, $parent, $style) = @_;
    my $self = $class->SUPER::new( $parent, -1,[-1,-1],[-1,-1] );
    Kephra::App::Editor::Events::mount( $self );
    $self->SetWordChars('abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789._$@%&*\\');
    $self->SetAdditionalCaretsBlink( 1 );
    $self->SetAdditionalCaretsVisible( 1 );
    $self->SetAdditionalSelectionTyping( 1 );
    $self->SetIndentationGuides( &Wx::wxSTC_WS_VISIBLEAFTERINDENT );  # wxSTC_WS_VISIBLEAFTERINDENT   2   wxSTC_WS_VISIBLEALWAYS 1
    # $self->SetAdditionalSelAlpha( 1 );
    $self->SetScrollWidth(300);
    $self->SetYCaretPolicy( &Wx::wxSTC_CARET_SLOP, 5);
    $self->SetVisiblePolicy( &Wx::wxSTC_VISIBLE_SLOP, 5);
    $self->set_margin;
    $self->load_font;  # before setting highlighting
    Kephra::App::Editor::SyntaxMode::apply( $self, 'perl' );
    $self->{'change_pos'} = $self->{'change_prev'} = -1;
    $self->del_caret_pos_cache;
    return $self;
}

sub window { $_[0]->GetParent }

sub apply_config {
    my ($self, $config) = @_;
    my $config_value = $config->get_value('document');
    $self->set_tab_size( $config_value->{'tab_size'} );
    $self->set_tab_usage( !$config_value->{'soft_tabs'} );
    $self->set_EOL( $config_value->{'line_ending'} );

    $config_value = $config->get_value('view');
    $self->set_zoom_level( $config_value->{'zoom_level'} );
    $self->toggle_view_whitespace     unless $config_value->{'whitespace'}    == $self->view_whitespace_mode;
    $self->toggle_view_eol            unless $config_value->{'line_ending'}   == $self->view_eol_mode;
    $self->toggle_view_indent_guide   unless $config_value->{'indent_guide'}  == $self->indent_guide_mode;
    $self->toggle_view_right_margin   unless $config_value->{'right_margin'}  == $self->right_margin_mode;
    $self->toggle_view_line_nr_margin unless $config_value->{'line_nr_margin'}== $self->line_nr_margin_mode;
    $self->toggle_view_marker_margin  unless $config_value->{'marker_margin'} == $self->marker_margin_mode;
    $self->toggle_view_caret_line     unless $config_value->{'caret_line'}    == $self->view_caret_line_mode;
    $self->toggle_view_line_wrap      unless $config_value->{'line_wrap'}     == $self->line_wrap_mode;
    $self->window->toggle_full_screen unless $config_value->{'full_screen'}   == $self->window->IsFullScreen;

    $config_value = $config->get_value('editor');
    $self->{ $_ } = $config_value->{ $_ } for qw/change_pos change_prev/;
    $self->init_marker( @{$config_value->{'marker'}} );
    $self->SetSelection( $config_value->{'caret_pos'}, $config_value->{'caret_pos'});
    $self->EnsureCaretVisible;
}

sub save_config {
    my ($self, $config) = @_;
    $config->set_value( { soft_tabs => !$self->{'tab_usage'},
                          indention_size => $self->{'tab_size'},
                          line_ending   => $self->get_EOL,
                        # encoding   => 'utf-8',
                        } , 'document');
    $config->set_value( { change_pos => $self->{'change_pos'},
                          change_prev => $self->{'change_prev'},
                          caret_pos => $self->GetCurrentPos,
                          marker => [ $self->marker_lines ],
                        } , 'editor');
    $config->set_value( { whitespace     => $self->view_whitespace_mode,
                          line_ending    => $self->view_eol_mode,
                          indent_guide   => $self->indent_guide_mode,
                          right_margin   => $self->right_margin_mode,
                          line_nr_margin => $self->line_nr_margin_mode,
                          marker_margin  => $self->marker_margin_mode,
                          caret_line     => $self->view_caret_line_mode,
                          line_wrap      => $self->line_wrap_mode,
                          zoom_level     => $self->get_zoom_level,
                          full_screen    => int $self->window->IsFullScreen,
                        } , 'view');
}

sub load_font {
    my ($self, $font) = @_;
    my ( $fontweight, $fontstyle ) = ( &Wx::wxNORMAL, &Wx::wxNORMAL );
    $font = {
        family => $^O eq 'darwin' ? 'Andale Mono' : 'Courier New', # old default
        # family => 'DejaVu Sans Mono', # new    # Courier New
        size => $^O eq 'darwin' ? 13 : 11,
        style => 'normal',
        weight => 'normal',
    } unless defined $font;
    #my $font = _config()->{font};
    $fontweight = &Wx::wxLIGHT  if $font->{weight} eq 'light';
    $fontweight = &Wx::wxBOLD   if $font->{weight} eq 'bold';
    $fontstyle  = &Wx::wxSLANT  if $font->{style}  eq 'slant';
    $fontstyle  = &Wx::wxITALIC if $font->{style}  eq 'italic';
    my $wx_font = Wx::Font->new(
        $font->{size}, &Wx::wxDEFAULT, $fontstyle, $fontweight, 0, $font->{family}, &Wx::wxFONTENCODING_DEFAULT
    );
    $self->StyleSetFont( &Wx::wxSTC_STYLE_DEFAULT, $wx_font ) if $wx_font->Ok > 0;
    # wxFONTENCODING_ISO8859_1
    # wxFONTENCODING_UTF8
    # wxFONTENCODING_UTF16(L|BE)
}

sub is_empty { not $_[0]->GetTextLength }

sub new_text {
    my ($self, $content, $soft) = @_;
    return unless defined $content;
    $self->SetText( $content );
    $self->EmptyUndoBuffer unless defined $soft;
    $self->SetSavePoint;
}

sub bracelight{
    my ($self, $pos) = @_;
    my $char_before = $self->GetTextRange( $pos-1, $pos );
    my $char_after = $self->GetTextRange( $pos, $pos + 1);
    if (    $char_before eq '(' or $char_before eq ')'
         or $char_before eq '{' or $char_before eq '}'
         or $char_before eq '[' or $char_before eq ']' ) {
        my $mpos = $self->BraceMatch( $pos - 1 );
        $mpos != &Wx::wxSTC_INVALID_POSITION
            ? $self->BraceHighlight($pos - 1, $mpos)
            : $self->BraceBadLight($pos - 1);
    } elsif ($char_after eq '(' or $char_after eq ')'
          or $char_after eq '{' or $char_after eq '}'
          or $char_after eq '[' or $char_after eq ']'){
        my $mpos = $self->BraceMatch( $pos );
        $mpos != &Wx::wxSTC_INVALID_POSITION
            ? $self->BraceHighlight($pos, $mpos)
            : $self->BraceBadLight($pos);
    } else  { $self->BraceHighlight(-1, -1); $self->BraceBadLight( -1 ) }
}

sub new_line {
    my ($self) = @_;
    my $pos = $self->GetCurrentPos;
    my $char_before = $self->GetTextRange( $pos-1, $pos );
    my $char_after = $self->GetTextRange( $pos, $pos + 1);
    $self->NewLine;
    my $l = $self->GetCurrentLine;
    my $i = $self->GetLineIndentation( $l - 1 );

    if ($char_before eq '{' and $char_after eq '}'){ # postion braces when around caret
        $self->NewLine;
        $self->SetLineIndentation( $self->GetCurrentLine, $i );
        $i+= $self->{'tab_size'}
    } else {
        # ignore white space left of caret
        while ($char_before eq ' ' and $self->LineFromPosition( $pos ) == $l-1){
            $pos--;
            $char_before = $self->GetTextRange( $pos-1, $pos );
        }
        if ($char_before eq '{')    { $i+= $self->{'tab_size'} }
        elsif ($char_before eq '}') {
            my $mpos = $self->BraceMatch( $pos - 1 );
            if ($mpos != &Wx::wxSTC_INVALID_POSITION){
                $i = $self->GetLineIndentation( $self->LineFromPosition( $mpos ) );
            } else {
                $i-= $self->{'tab_size'};
                $i = 0 if $i < 0;
            }
        }
    }
    $self->SetLineIndentation( $l, $i );
    $self->GotoPos( $self->GetLineIndentPosition( $l ) );
}

sub escape {
    my ($self) = @_;
    #my ($start_pos, $end_pos) = $self->GetSelection;
    my $win = $self->GetParent;
    #if ($start_pos != $end_pos) { return $self->GotoPos ( $self->GetCurrentPos ) }
    if ($win->IsFullScreen) { return $win->toggle_full_screen};
    # 3. focus  to edit field
}

sub GetLastPosition { $_[0]->GetTextLength }

sub set_caret_pos_cache {
    my ($self, $name, $pos) = @_;
    return unless defined $name;
    $self->{'caret_cache'} = {name => $name, pos => [$self->GetSelection]};
    $self->{'caret_cache'}{'pos'} = [$pos] if defined $pos;
}
sub get_caret_pos_cache {
    my ($self, $name) = @_;
    return unless defined $name and $self->{'caret_cache'}{'name'} eq $name;
    return @{$self->{'caret_cache'}{'pos'}} if int @{$self->{'caret_cache'}{'pos'}};
}
sub del_caret_pos_cache { $_[0]->{'caret_cache'} = {name => '', pos => []} }

#~ sub sel {
    #~ my ($self) = @_;
    #~ my $pos = $self->GetCurrentPos;
    #~ say $self->GetStyleAt( $pos);
#~ }

1;
