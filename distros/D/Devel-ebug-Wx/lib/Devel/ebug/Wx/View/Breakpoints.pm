package Devel::ebug::Wx::View::Breakpoints;

use strict;
use base qw(Wx::ScrolledWindow Devel::ebug::Wx::View::Base);
use Devel::ebug::Wx::Plugin qw(:plugin);

__PACKAGE__->mk_accessors( qw(panes sizer) );

use Wx qw(:sizer);

sub tag         { 'breakpoints' }
sub description { 'Breakpoints' }

sub new : View {
    my( $class, $parent, $wxebug, $layout_state ) = @_;
    my $self = $class->SUPER::new( $parent, -1 );

    $self->wxebug( $wxebug );
    $self->panes( [] );

    $self->subscribe_ebug( 'break_point', sub { $self->_add_bp( @_ ) } );
    $self->subscribe_ebug( 'break_point_delete', sub { $self->_del_bp( @_ ) } );
    $self->subscribe_ebug( 'load_program_state', sub { $self->load_all_breakpoints } );
    $self->set_layout_state( $layout_state ) if $layout_state;
    $self->register_view;

    my $sizer = Wx::BoxSizer->new( wxVERTICAL );
    $self->SetSizer( $sizer );

    $self->sizer( $sizer );

    $self->load_all_breakpoints if $wxebug->ebug->is_running;

    $self->SetSize( $self->default_size );

    return $self;
}

sub load_all_breakpoints {
    my( $self ) = @_;
    my $wxebug = $self->wxebug;

    foreach my $pane ( @{$self->panes} ) {
        $self->sizer->Detach( $pane );
        $pane->Destroy;
    }
    $self->{panes} = [];

    $self->_add_bp( $wxebug->ebug, undef,
                    file      => $_->{filename},
                    line      => $_->{line},
                    condition => $_->{condition},
                    ) foreach $wxebug->ebug->all_break_points_with_condition;
}

sub _compare {
    my( $x, $y ) = @_;
    my $fc = $x->{file} cmp $y->{file};
    return $fc if $fc != 0;
    return $x->{line} <=> $y->{line};
}

sub _add_bp {
    my( $self, $ebug, $event, %params ) = @_;

    my( $index, $order );
    for( $index = 0; $index < @{$self->panes}; ++$index ) {
        $order = _compare( \%params, $self->panes->[$index] );
        return if $order == 0;
        last if $order < 0;
    }
    my $pane = Devel::ebug::Wx::Breakpoints::Pane->new( $self, \%params );
    splice @{$self->panes}, $index, 0, $pane;
    $self->sizer->Insert( $index, $pane, 0, wxGROW );
    $self->SetScrollRate( 0, $pane->GetSize->y );
    # force relayout and reset virtual size
    $self->Layout;
    $self->SetSize( $self->GetSize );
}

sub _del_bp {
    my( $self, $ebug, $event, %params ) = @_;

    my $index;
    for( $index = 0; $index < @{$self->panes}; ++$index ) {
        last if _compare( \%params, $self->panes->[$index] ) == 0;
    }
    my $pane = $self->panes->[$index];

    splice @{$self->panes}, $index, 1;
    $self->sizer->Detach( $pane );
    $pane->Destroy;
    # force relayout and reset virtual size
    $self->Layout;
    $self->SetSize( $self->GetSize );
}

sub delete {
    my( $self, $pane ) = @_;

    $self->ebug->break_point_delete( $pane->file, $pane->line );
}

sub go_to {
    my( $self, $pane ) = @_;

    $self->wxebug->code_display_service
         ->highlight_line( $pane->file, $pane->line );
}

sub set_condition {
    my( $self, $pane, $condition ) = @_;

    $self->ebug->ebug->break_point( $pane->file, $pane->line, $condition );
}

package Devel::ebug::Wx::Breakpoints::Pane;

use strict;
use base qw(Wx::Panel Class::Accessor::Fast);

__PACKAGE__->mk_ro_accessors( qw(controls file line) );

use File::Basename qw(basename);

use Wx qw(:sizer);
use Wx::Event qw(EVT_BUTTON EVT_TEXT);

sub new {
    my( $class, $parent, $args ) = @_;
    my $self = $class->SUPER::new( $parent );

    my $bp_label = Wx::StaticText->new( $self, -1, '' );
    my $goto = Wx::Button->new( $self, -1, 'Go to' );
    my $delete = Wx::Button->new( $self, -1, 'Delete' );
    my $cnd_label = Wx::StaticText->new( $self, -1, 'Cond:' );
    my $condition = Wx::TextCtrl->new( $self, -1, '' );

    $self->{controls} = { label     => $bp_label,
                          condition => $condition,
                          };
    $self->{file} = $args->{file};
    $self->{line} = $args->{line};

    $self->display_bp( $args );

    my $topsz = Wx::BoxSizer->new( wxVERTICAL );
    my $fsz = Wx::BoxSizer->new( wxHORIZONTAL );
    my $ssz = Wx::BoxSizer->new( wxHORIZONTAL );

    $fsz->Add( $bp_label, 0, wxLEFT|wxALIGN_CENTER_VERTICAL, 2 );
    $fsz->Add( $delete, 0, 0 );
    $fsz->Add( $goto, 0, wxRIGHT, 2 );

    $ssz->Add( $cnd_label, 0, wxLEFT|wxALIGN_CENTER_VERTICAL, 2 );
    $ssz->Add( $condition, 1, wxRIGHT, 2 );

    $topsz->Add( $fsz, 0, wxGROW );
    $topsz->Add( $ssz, 0, wxGROW );

    $self->SetSizerAndFit( $topsz );

    EVT_BUTTON( $self, $goto, sub { $self->GetParent->go_to( $self ) } );
    EVT_BUTTON( $self, $delete, sub { $self->GetParent->delete( $self ) } );
    EVT_TEXT( $self, $condition, sub { $self->GetParent->set_condition( $self, $condition->GetValue ) } );

    return $self;
}

sub display_bp {
    my( $self, $args ) = @_;

    my $text = basename( $args->{file} ) . ': ' . $args->{line};
    my $cond = $args->{condition} || '';
    $self->controls->{label}->SetLabel( $text );
    $self->controls->{condition}->SetValue( $cond eq '1' ? '' : $cond );
}

1;
