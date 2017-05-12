package GappX::Notice;
{
  $GappX::Notice::VERSION = '0.200';
}

use Moose;
use MooseX::SemiAffordanceAccessor;
use MooseX::StrictConstructor;

extends 'Gapp::Widget';
with 'Gapp::Meta::Widget::Native::Role::HasIcon';
with 'Gapp::Meta::Widget::Native::Role::HasIconSize';
with 'Gapp::Meta::Widget::Native::Role::HasImage';
with 'Gapp::Meta::Widget::Native::Role::HasAction';


has '+gclass' => (
    default => 'Gtk2::EventBox',
);

has 'text' => (
    is => 'rw',
    isa => 'Str',
    default => '',
);

has 'label' => (
    is => 'ro',
    isa => 'Gapp::Label',
    default => sub {
        Gapp::Label->new( text => $_[0]->text || '' ),
    },
    lazy => 1,
);

has 'hbox' => (
    is => 'ro',
    isa => 'Gapp::HBox',
    init_arg => undef,
    default => sub {
        Gapp::HBox->new(
            
        )
    },
    lazy => 1,
);



package Gapp::Layout::Default;
{
  $Gapp::Layout::Default::VERSION = '0.200';
}
use Gapp::Layout;

build 'GappX::Notice', sub {
    my ( $l, $w ) = @_;
    
    my $gtkw = $w->gobject;
    $gtkw->add( $w->hbox->gwrapper );

    if ( ! $w->image && $w->icon ) {
        my $img = Gapp::Image->new( stock => [ $w->icon, $w->icon_size || 'dialog' ] );
        $w->set_image( $img );
    }
    
    # put the label into the wrapper
    $w->hbox->gobject->pack_start( $w->image->gwrapper, 1, 1, 0 ) if $w->image;
    $w->hbox->gobject->pack_start( $w->label->gwrapper, 1, 1, 0 );
    $gtkw->show_all;
};

paint 'GappX::Notice', sub {
    my ( $l, $w ) = @_;
    return if ! $w->action;
   
    my ( $action, @args ) = parse_action ( $w->action );
    
    if ( is_CodeRef $action ) {
	$w->signal_connect( 'button-release-event', $action, \@args );
    }
    else {
	my $gtkw = $w->gobject;
	$gtkw->set_image( $action->create_gtk_image( $w->icon_size || 'button' ) ) if ! defined $w->icon && ! defined $w->image && defined $action->icon;
	$gtkw->set_tooltip_text( $action->tooltip ) if ! defined $w->tooltip && defined $action->tooltip;
	$gtkw->signal_connect( 'button-release-event' => actioncb( $action, $w, \@args ) );
    }
    
};

1;
