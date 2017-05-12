package Devel::ebug::Wx::View::Notebook;

use Wx::AUI;

use strict;
use base qw(Wx::AuiNotebook Devel::ebug::Wx::View::Multi);
use Devel::ebug::Wx::Plugin qw(:plugin);

__PACKAGE__->mk_accessors( qw(has_views) );

use Wx qw(:aui);
use Wx::Event qw(EVT_RIGHT_UP EVT_MENU);

sub tag_base         { 'notebook' }
sub description_base { 'Notebook' }

sub new : View {
    my( $class, $parent, $wxebug, $layout_state ) = @_;
    my $self = $class->SUPER::new( $parent, -1, [-1, -1], [-1, -1],
                                   wxAUI_NB_TAB_MOVE|wxAUI_NB_CLOSE_BUTTON|
                                   wxAUI_NB_WINDOWLIST_BUTTON );

    $self->wxebug( $wxebug );
    $self->SetSize( $self->default_size );

    $self->AddPage( Wx::StaticText->new( $self, -1,
                                         "Use 'View -> Edit Notebooks'" ),
                    'Add pages' );
    $self->set_layout_state( $layout_state ) if $layout_state;
    $self->register_view;

    return $self;
}

sub add_view {
    my( $self, $view ) = @_;
    my $instance = $self->wxebug->view_manager_service->get_view( $view->tag );

    if( !$self->has_views ) {
        $self->DeletePage( 0 );
    }
    # always destroy if present
    if( $instance ) {
        $instance->Destroy;
    }
    $instance = $view->new( $self, $self->wxebug );
    $self->AddPage( $instance, $instance->description );
    $self->has_views( 1 );
}

sub get_layout_state {
    my( $self ) = @_;
    my $state = $self->SUPER::get_layout_state;
    return $state unless $self->has_views;

    $state->{notebook} = [ map $_->get_layout_state,
                           map $self->GetPage( $_ ),
                               ( 0 .. $self->GetPageCount - 1 )
                           ];

    return $state;
}

sub set_layout_state {
    my( $self, $state ) = @_;
    $self->SUPER::set_layout_state( $state );

    return unless $state->{notebook};
    $self->DeletePage( 0 ); # FIXME use non ad-hoc handling...

    foreach my $subview ( @{$state->{notebook} || []} ) {
        my $instance = $subview->{class}->new( $self, $self->wxebug,
                                               $subview );
        $self->AddPage( $instance, $instance->description );
        $self->has_views( 1 );
    }
}


1;
