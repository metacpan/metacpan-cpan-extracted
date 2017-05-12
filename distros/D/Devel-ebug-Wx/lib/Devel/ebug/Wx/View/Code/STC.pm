package Devel::ebug::Wx::View::Code::STC;

use Wx::STC;

# FIXME split in a fully-fledged view linked to the code display service
#       and a simple code-edit/display control
use strict;
use base qw(Wx::StyledTextCtrl Devel::ebug::Wx::View::Base
            Devel::ebug::Wx::Plugin::Configurable::Base);
use Devel::ebug::Wx::Plugin qw(:plugin);

__PACKAGE__->mk_accessors( qw(filename line highlighted_line) );

use Wx qw(:stc :font);
use Wx::Event qw(EVT_CHAR EVT_STC_MARGINCLICK EVT_RIGHT_UP);

use constant { CURRENT_LINE => 2,
               BREAKPOINT   => 1,
               BACKGROUND   => 3,
               };

sub tag { 'code_stc' }

sub new {
    my( $class, $parent, $wxebug ) = @_;
    my $self = $class->SUPER::new( $parent, -1 );

    $self->filename( '' );
    $self->line( -1 );
    $self->highlighted_line( 0 );
    $self->wxebug( $wxebug );

    $self->subscribe_ebug( 'file_changed', sub { $self->_show_code( @_ ) } );
    $self->subscribe_ebug( 'line_changed', sub { $self->_show_line( @_ ) } );
    $self->subscribe_ebug( 'break_point', sub { $self->_break_point( @_ ) } );
    $self->subscribe_ebug( 'break_point_delete', sub { $self->_break_point( @_ ) } );
    $self->subscribe_ebug( 'load_program_state', sub { $self->_change_state( @_ ) } );

    $self->register_configurable;
    $self->_setup_stc( $self->get_configuration
                           ( $self->wxebug->service_manager ) );

    return $self;
}

sub _change_state {
    my( $self ) = @_;

    $self->show_break_point( $_ )
        foreach $self->ebug->break_points( $self->filename );
}

sub _break_point {
    my( $self, $ebug, $event, %params ) = @_;

    return unless $params{file} eq $self->filename;
    if( $event eq 'break_point' ) {
        $self->show_break_point( $params{line} );
    } elsif( $event eq 'break_point_delete' ) {
        $self->hide_break_point( $params{line} );
    }
}

sub show_break_point {
    my( $self, $line ) = @_;

    $self->MarkerAdd( $line - 1, BREAKPOINT );
}

sub hide_break_point {
    my( $self, $line ) = @_;

    $self->MarkerDelete( $line - 1, BREAKPOINT );
}

sub _show_code {
    my( $self, $ebug, $event, %params ) = @_;

    $self->show_code_for_file( $ebug->filename );
}

sub show_code_for_file {
    my( $self, $filename ) = @_;

    $self->SetReadOnly( 0 );
    $self->SetText( join "\n", $self->ebug->codelines( $filename ) );
    $self->SetReadOnly( 1 );
    $self->filename( $filename );
    $self->show_break_point( $_ )
        foreach $self->ebug->break_points( $filename );
    $self->highlighted_line( 0 );
}

sub _show_line {
    my( $self, $ebug, $event, %params ) = @_;

    $self->show_current_line;
}

sub show_current_line {
    my( $self ) = @_;
    my $line = $self->ebug->line;

    if( $self->filename ne $self->ebug->filename ) {
        $self->show_code_for_file( $self->ebug->filename );
    }
    if( $self->line >= 0 ) {
        $self->MarkerDelete( $self->line - 1, CURRENT_LINE );
    }
    $self->line( $line );
    $self->MarkerAdd( $line - 1, CURRENT_LINE );
    $self->EnsureVisibleEnforcePolicy( $line - 1 );
}

# FIXME split in two methods
sub highlight_line {
    my( $self, $file, $line ) = @_;

    if( $self->filename ne $file ) {
        $self->show_code_for_file( $file );
    }
    $self->MarkerDelete( $self->highlighted_line - 1, BACKGROUND )
      if $self->highlighted_line;
    $self->MarkerAdd( $line - 1, BACKGROUND );
    $self->EnsureVisibleEnforcePolicy( $line - 1 );
    $self->highlighted_line( $line );
}

# FIXME finish moving to configuration
sub _setup_stc {
    my( $self, $configuration ) = @_;
    my $font = Wx::Font->new( 10, wxTELETYPE, wxNORMAL, wxNORMAL );

    $self->SetFont( $font );
    $self->StyleSetFont( wxSTC_STYLE_DEFAULT, $font );
    $self->StyleClearAll();

    $self->apply_configuration( $configuration );

    $self->SetLexer( wxSTC_LEX_PERL );

    $self->MarkerDefine( CURRENT_LINE, 2,  Wx::wxGREEN, Wx::wxNullColour );
    $self->MarkerDefine( BREAKPOINT  , 0,  Wx::wxBLUE, Wx::wxNullColour );
    $self->MarkerDefine( BACKGROUND  , 22, Wx::wxNullColour, Wx::Colour->new( 0x90, 0x90, 0x90 ) );

    $self->SetReadOnly( 1 );
    $self->SetMarginSensitive( 1, 1 );

    # FIXME: move to code display service
    EVT_STC_MARGINCLICK( $self, $self, sub { $self->_set_bp( $_[1] ) } );
    EVT_CHAR( $self, sub {
                  $self->wxebug->command_manager_service->handle_key( $_[1]->GetKeyCode );
              } );
    # FIXME add context menu
    EVT_RIGHT_UP( $self, sub {
                      warn $_[1]->GetX, ' ', $_[1]->GetY;
                      warn $self->GetMarginWidth( 1 );
                      warn $self->PositionFromPointClose($_[1]->GetX, $_[1]->GetY);
                  } );
}

sub _has_marker {
    my( $self, $line, $marker ) = @_;

    return $self->MarkerGet( $line ) & ( 1 << $marker );
}

sub _set_bp {
    my( $self, $e ) = @_;
    my $stc_line = $self->LineFromPosition( $e->GetPosition );
    my $has_bp = $self->_has_marker( $stc_line, BREAKPOINT );

    if( $has_bp ) {
        $self->ebug->break_point_delete( $self->filename, $stc_line + 1 );
    } else {
        $self->ebug->break_point( $self->filename, $stc_line + 1 );
    }
}

sub _constant {
    my( $k ) = @_;

    no strict 'refs';
    return &{"Wx::wxSTC_PL_" . uc( $k )}();
}

no warnings qw(qw);
my @style_keys =
  ( qw(default error commentline pod number word string character
       punctuation preprocessor operator identifier scalar array regex
       regsubst)
    );
my @defaults =
  ( qw(fore:#00007f fore:#ff0000 fore:#007f00 fore:#7f7f7f fore:#007f7f
       fore:#00007f fore:#ff7f00 fore:#7f007f fore:#000000 fore:#7f7f7f
       fore:#00007f fore:#00007f fore:#7f007f,bold fore:#4080ff,bold
       fore:#ff007f fore:#7f7f00)
    );

sub get_configuration_keys {
    my( $class ) = @_;

    my @keys = map { key     => $style_keys[$_],
                     type    => 'string',
                     label   => ucfirst( $style_keys[$_] ),
                     default => $defaults[$_],
                     },
                   ( 0 .. $#style_keys );
    return { label   => 'Code display',
             section => 'code_stc_view',
             keys    => \@keys,
             };
}

sub configuration : Configurable {
    my( $class ) = @_;

    return { configurable => __PACKAGE__,
             configurator => 'configuration_simple',
             };
}

sub apply_configuration {
    my( $self, $data ) = @_;

    foreach my $key ( @{$data->{keys}} ) {
        $self->StyleSetSpec( _constant( $key->{key} ), $key->{value} );
    }
}

1;
