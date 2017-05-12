package Gapp::Layout::Default;
{
  $Gapp::Layout::Default::VERSION = '0.60';
}
use Gapp::Layout;
use strict;
use warnings;

use Gapp::Util qw( replace_entities );
use Gapp::Actions::Util qw( actioncb parse_action);
use Gapp::Types qw( GappAction GappActionOrArrayRef );
use MooseX::Types::Moose qw( ArrayRef CodeRef Object Str );

use Carp qw( confess );

# Assistant

build 'Gapp::Assistant', sub {
    my ( $l, $w ) = @_;
    $w->gobject->set_icon( $w->gobject->render_icon( $w->icon, 'dnd' ) ) if $w->icon;
    
    if ( $w->forward_page_func ) {
	
	my ( $cb, @args ) = parse_action $w->forward_page_func;
	
	$w->gobject->set_forward_page_func( sub {
	    my ( $pagenum, $w ) = @_;
	    $cb->( $w, \@args, $w->gobject, [$pagenum] );
	}, $w);
    }
};


# Assistnat Page

add 'Gapp::Widget', to 'Gapp::Assistant', sub {
    my ( $l, $w, $c) = @_;
    
    if ( ! $w->does('Gapp::Meta::Widget::Native::Trait::AssistantPage') ) {
	use Carp qw(cluck);
	cluck qq[$w does not have the AssistantPage trait applied. Any widget added to ]. 
	qq[an assistant must have the AssistntPage trait.];
    }

    my $gtk_w = $w->gwrapper;
    
    my $assistant = $c->gobject;
   
    my $page_num = $assistant->append_page( $w->gwrapper );
    $w->set_page_num( $page_num );
    
    $assistant->set_page_title     ($w->gwrapper , $w->page_title );
    $assistant->set_page_side_image($w->gwrapper , $assistant->render_icon( $w->page_icon , 'dnd' ) ) if $w->page_icon;
    $assistant->set_page_type      ($w->gwrapper , $w->page_type );
    $assistant->set_page_complete  ($w->gwrapper , 1);
    $assistant->{pages}{$w->name} = $w if $w->name;
};



# Button

#style 'Gapp::Button', sub {
#    my ( $l, $w ) = @_;
#    
#    my ( $action, @args ) = parse_action ( $w->action );
#    
#    if ( is_GappAction ( $action ) && $action->mnemonic ) {
#	if ( ! $w->label && ! $w->mnemonic ) {
#	    $w->set_mnemonic( $action->mnemonic );
#	    $w->set_constructor( 'new_with_mnemonic' );
#	    $w->set_args( [ $action->mnemonic ] );
#	}
#    }
#};

build 'Gapp::Button', sub {
    my ( $l, $w ) = @_;
    my $gtkw = $w->gobject;
    
    my ( $image );
    if ( $w->image ) {
	$image = $w->image->gobject;
    }
    elsif ( $w->icon ) {
	$image = Gtk2::Image->new_from_stock( $w->icon, $w->icon_size || 'button' );
    }
    

    
    $gtkw->set_label( $w->label ) if defined $w->label && ! defined $w->mnemonic;
    $gtkw->set_image( $image ) if defined $image;
    $gtkw->set_tooltip_text( $w->tooltip ) if defined $w->tooltip;
};


paint 'Gapp::Button', sub {
    my ( $l, $w ) = @_;
    return if ! $w->action;
    
    my ( $action, @args ) = parse_action ( $w->action );
    
   
    if ( is_CodeRef $action ) {
	$w->signal_connect( 'clicked', $action, @args );
    }
    else {
	my $gtkw = $w->gobject;
	$gtkw->set_label( $action->label ) if ! defined $w->mnemonic && ! defined $w->label && defined $action->label;
	$gtkw->set_image( $action->create_gtk_image( 'button' ) ) if ! defined $w->icon && ! defined $w->image && defined $action->icon;
	$gtkw->set_tooltip_text( $action->tooltip ) if ! defined $w->tooltip && defined $action->tooltip;
	$gtkw->signal_connect( clicked => actioncb( $action, $w, \@args ) );
    }
};

# ComboBox

build 'Gapp::ComboBox', sub {
    my ( $l, $w ) = @_;
    my $gtkw = $w->gobject;
    
    
    if ( ! $w->model ) {
	my $model = Gapp::Model::SimpleList->new;
	$w->set_model( $model )
    }
    
    my $model = $w->model->isa('Gapp::Object') ? $w->model->gobject : $w->model;
    
    # populate the module with values
    if ( $w->values ) {
        
        my $model = $w->model->isa('Gapp::Object') ? $w->model->gobject : $w->model;
        
        my @values = is_CodeRef($w->values) ? &{$w->values}($w) : @{$w->values};
        $model->append( $_ ) for ( @values );
        
    }
    
    $gtkw->set_model( $model );
    
    # create the renderer to display the values
    my $gtkr = $w->renderer->gobject;
    $gtkw->{renderer} = $gtkr;
    
    # add the renderer to the column
    $gtkw->pack_start( $gtkr, $w->renderer->expand ? 1 : 0 );
    
    
    # define how to display the renderer
    if ( defined $w->data_column && ! $w->data_func ) {
        $gtkw->set_cell_data_func($gtkr, sub {
            
            my ( $col, $gtkrenderer, $model, $iter, @args ) = @_;
            
            my $value = $model->get( $iter ) if defined $w->data_column;
            
            $gtkrenderer->set_property( 'markup' => defined $value ? replace_entities( $value ) : '' );
        });
    }
    elsif ( $w->data_func ) {
        
        $gtkw->set_cell_data_func($gtkr, sub {
            
            my ( $col, $gtkrenderer, $model, $iter, @args ) = @_;

            my $value = $model->get( $iter ) if defined $w->data_column;
            local $_ = $value;
            
            if ( is_CodeRef( $w->data_func ) ) {
                $value = &{ $w->data_func }( $_ );
            }
            elsif ( is_Str( $w->data_func ) ) {
                my $method = $w->data_func;
                $value = defined $_ ? $_->$method : '';
            }

            $gtkrenderer->set_property( 'markup' => defined $value ? replace_entities( $value ) : '' );
            
        });
    }

};

# Dialog

build 'Gapp::Dialog', sub {
    my ( $l, $w ) = @_;
    my $gtk_w = $w->gobject;
    $w->gobject->set_icon( $w->gobject->render_icon( $w->icon, 'dnd' ) ) if $w->icon;
    $w->gobject->set_transient_for( $w->transient_for->gobject ) if $w->transient_for;
    
    if ( $w->action_widgets ) {
	
	while ( @{$w->action_widgets} ) {
	    my $b = shift @{$w->action_widgets};
	    my $r = shift @{$w->action_widgets};
	    $gtk_w->add_action_widget( $b->gobject, $r );
	}
    }
    if ( $w->buttons ) {
	while ( @{$w->buttons} ) {
	    my $b = shift @{$w->buttons};
	    my $r = shift @{$w->buttons};
	    
	    if ( is_Object( $b ) ) {
		$gtk_w->add_action_widget( $b->gobject, $r );
	    }
	    else {
		$gtk_w->add_button( $b, $r );
	    }
	    
	}
    }

};


style 'Gapp::Entry', sub {
    my ( $l, $w ) = @_;
    $w->properties->{activates_default} ||= 1;
};






# EventBox
style 'Gapp::EventBox', sub {
    my ( $l, $w ) = @_;
};

build 'Gapp::EventBox', sub {
    my ( $l, $w ) = @_;
};





# FileChooserDialog

build 'Gapp::FileChooserDialog', sub {
    my ( $l, $w ) = @_;
    my $gtk_w = $w->gobject;
    $w->gobject->set_icon( $w->gobject->render_icon( $w->icon, 'dnd' ) ) if $w->icon;
    $w->gobject->set_transient_for( $w->transient_for->gobject ) if $w->transient_for;
    
    if ( $w->action_widgets ) {
	
	while ( @{$w->action_widgets} ) {
	    my $b = shift @{$w->action_widgets};
	    my $r = shift @{$w->action_widgets};
	    $gtk_w->add_action_widget( is_Object($b) ? $b->gobject : $b, $r );
	}
    }
    if ( $w->buttons ) {
	while ( @{$w->buttons} ) {
	    my $b = shift @{$w->buttons};
	    my $r = shift @{$w->buttons};
	    $gtk_w->add_button( is_Object($b) ? $b->gobject : $b, $r );
	}
    }

    
    map { $w->gobject->add_filter( $_->gobject ) } $w->filters;
};

# FileFilter

build 'Gapp::FileFilter', sub {
    my ( $l, $w ) = @_;
    
    my $gtkw = $w->gobject;
    $gtkw->set_name( $w->name );
    map { $gtkw->add_pattern( $_ ) } $w->patterns;
    map { $gtkw->add_mime_type( $_ ) } $w->mime_types; 
};


# Label

build 'Gapp::Label', sub {
    my ( $l, $w ) = @_;

    my $gtkw = $w->gobject;
    $gtkw->set_text( $w->text ) if defined $w->text;
    $gtkw->set_markup( $w->markup ) if defined $w->markup;
};

# List

build 'Gapp::Model::List', sub {
    my ( $l, $w ) = @_;
    map { $w->gobject->append_record( @$_ ) } @{ $w->content };
};



# Image

build 'Gapp::Image', sub {
    my ( $l, $w ) = @_;
    
    my $gtkw = $w->gobject;
    if ( $w->file ) {
	$gtkw->set_from_file( $w->file );
    }
    elsif ( $w->stock ) {
        $gtkw->set_from_stock( $w->stock->[0], $w->stock->[1] );
    }
};

# ImageMenuItem

#style 'Gapp::ImageMenuItem', sub {
#    my ( $l, $w ) = @_;
#    
#    my ( $action, @args ) = parse_action ( $w->action );
#    
#    
#    
#    if ( is_GappAction ( $action ) && $action->mnemonic ) {
#	
#	if ( ! $w->label && ! $w->mnemonic ) {
#	    
#	    $w->set_mnemonic( $action->mnemonic );
#	    $w->set_constructor( 'new_with_mnemonic' );
#	    $w->set_args( [ $action->mnemonic ] );
#	    
#	    $w->_construct_gobject;
#	}
#    }
#};



build 'Gapp::ImageMenuItem', sub {
    my ( $l, $w ) = @_;
    my $gtkw = $w->gobject;
    
    my ( $image );
    
    if ( $w->icon ) {
	$image = Gtk2::Image->new_from_stock( $w->icon, 'menu' );
    }
    if ( $w->image ) {
	$image = $w->image->gobject;
    }
    
    $gtkw->set_label( $w->label ) if defined $w->label && ! defined $w->mnemonic;
    $gtkw->set_image( $image ) if defined $image;
    $gtkw->set_tooltip_text( $w->tooltip ) if defined $w->tooltip;
    
    if ( $w->menu ) {
	$gtkw->set_submenu( $w->menu->gobject );
    }
};

paint 'Gapp::ImageMenuItem', sub {
    my ( $l, $w ) = @_;
    return if ! $w->action;
    
    #print $w, $w->mnemonic, "\n";
    
    my ( $action, @args ) = parse_action ( $w->action );
    
    if ( is_CodeRef $action ) {
	$w->signal_connect( 'activate', $action, \@args );
    }
    else {
	my $gtkw = $w->gobject;
	
	$gtkw->set_label( $action->label ) if ! defined $w->label  && ! defined $w->mnemonic && defined $action->label;
	$gtkw->set_image( $action->create_gtk_image( 'menu' ) ) if ! $w->icon && ! defined $w->image && defined $action->icon;
	$gtkw->set_tooltip_text( $action->tooltip ) if ! defined $w->tooltip && defined $action->tooltip;
	$gtkw->signal_connect( activate => actioncb( $action, $w, \@args ) );
    }
};




# MenuItem
#style 'Gapp::MenuItem', sub {
#    my ( $l, $w ) = @_;
#    
#    my ( $action, @args ) = parse_action ( $w->action );
#    
#    if ( is_GappAction ( $action ) && $action->mnemonic ) {
#	if ( ! $w->label && ! $w->mnemonic ) {
#	    $w->set_constructor( 'new_with_mnemonic' );
#	    $w->set_args( [ $action->mnemonic ] );
#	}
#    }
#};


build 'Gapp::MenuItem', sub {
    my ( $l, $w ) = @_;
    my $gtkw = $w->gobject;
        
    $gtkw->set_label( $w->label ) if defined $w->label && ! defined $w->mnemonic;
    $gtkw->set_tooltip_text( $w->tooltip ) if defined $w->tooltip;
    
    if ( $w->menu ) {
	$gtkw->set_submenu( $w->menu->gobject );
    }
};

paint 'Gapp::MenuItem', sub {
    my ( $l, $w ) = @_;
    return if ! $w->action;
    
    my ( $action, @args ) = parse_action ( $w->action );
    
    if ( is_CodeRef $action ) {
	$w->signal_connect( 'activate', $action, \@args );
    }
    else {
	my $gtkw = $w->gobject;
	$gtkw->set_label( $action->label ) if ! defined $w->label && ! defined $w->mnemonic && defined $action->label;
	$gtkw->set_tooltip_text( $action->tooltip ) if ! defined $w->tooltip && defined $action->tooltip;
	$gtkw->signal_connect( activate => actioncb( $action, $w, \@args ) );
    }
};


add 'Gapp::MenuItem', to 'Gapp::MenuShell', sub {
    my ( $l, $w, $c ) = @_;
    $c->gobject->append( $w->gwrapper );
    $c->gobject->show;
};


# ToolButton

style 'Gapp::MenuToolButton', sub {
    my ( $l, $w ) = @_;
    
    my $image = $w->image ?
    $w->image->gobject :
    Gtk2::Image->new_from_stock( $w->icon || 'gtk-dialog-error' , $w->icon_size || 'large-toolbar' );
    
    $w->set_args( [ $image, defined $w->label ? $w->label : ''  ] );
};


build 'Gapp::MenuToolButton', sub {
    my ( $l, $w ) = @_;
    my $gtkw = $w->gobject;
    
    $w->gobject->set_menu( $w->menu->gobject ) if $w->menu;
    
    $gtkw->set_stock_id( $w->stock_id ) if $w->stock_id;
    $gtkw->set_label( $w->label ) if defined $w->label;
    $gtkw->set_tooltip_text( $w->tooltip ) if defined $w->tooltip;
    $gtkw->set_homogeneous( 1 ) if $w->homogeneous;
    $w->menu->gwrapper->show_all if $w->menu;
};

paint 'Gapp::MenuToolButton', sub {
    my ( $l, $w ) = @_;
    return if ! $w->action;
    
    my ( $action, @args ) = parse_action ( $w->action );
    
    if ( is_CodeRef $action ) {
	$w->signal_connect( 'clicked', $action, \@args );
    }
    else {
	my $gtkw = $w->gobject;
	$gtkw->set_label( $action->label ) if ! defined $w->label && defined $action->label;
	$gtkw->set_icon_widget( $action->create_gtk_image( $w->icon_size || 'large-toolbar' ) ) if ! $w->icon  && ! $w->image && defined $action->icon;
	$gtkw->set_tooltip_text( $action->tooltip ) if ! defined $w->tooltip && defined $action->tooltip;
	$gtkw->signal_connect( clicked => actioncb( $action, $w, \@args ) );
    }
};


# Notice
build 'Gapp::Notebook', sub {
    my ( $l, $w ) = @_;

    my $gtkw = $w->gobject;
    
    # handle action widget
    if ( $w->action_widget ) {
	$w->action_widget->show_all if $w->action_widget;
	$gtkw->set_action_widget( $w->action_widget->gobject, 'end' );
    }

};


add 'Gapp::Widget', to 'Gapp::Notebook', sub {
    my ( $l, $w, $c) = @_;
   
    my $gtkw = $w->gwrapper;
    
    # check that widget is a NotebookPage
    if ( ! $w->does('Gapp::Meta::Widget::Native::Trait::NotebookPage') ) {
	die qq[ Could not add $w to $c, $w must have the NotebookPage trait applied.];
    }
    
    
    
    # append the page
    $c->gobject->append_page( $gtkw, $w->page_name );
    
    # create the label
    $w->tab_label ?
    $c->gobject->set_tab_label( $gtkw, $w->tab_label->gobject ) :
    $c->gobject->set_tab_label_text( $gtkw, $w->page_name );
    
    $w->tab_label->show_all if $w->tab_label;

    # call show all on the widget
    $w->show_all;
    
    $c->{pages}{$w->page_name} = $w;
};






# SimpleList
build 'Gapp::Model::SimpleList', sub {
    my ( $l, $w ) = @_;
    map { $w->gobject->append( $_ ) } @{ $w->content };
};


# SpinButton

style 'Gapp::SpinButton', sub {
    my ( $l, $w ) = @_;
    $w->properties->{activates_default} ||= 1;
};


build 'Gapp::SpinButton', sub {
    my ( $l, $w ) = @_;
    $w->gobject->set_increments( $w->step, $w->page ) if $w->page;
};




# ScrolledWindow
build 'Gapp::ScrolledWindow', sub {
    my ( $l, $w ) = @_;
    $w->gobject->set_policy( @{ $w->policy }) if $w->policy;
};

add 'Gapp::Widget', to 'Gapp::ScrolledWindow', sub {
    my ($l, $w, $c) = @_;
    
    if ( $c->use_viewport ) {
	$c->gobject->add_with_viewport( $w->gwrapper );
    }
    else {
	$c->gobject->add( $w->gwrapper );
    }
    
};


# TextBuffer
build 'Gapp::TextView', sub {
    my ( $l, $w ) = @_;
    $w->gobject->set_buffer( $w->buffer->gobject ) if $w->buffer;
};



# TextView
build 'Gapp::TextView', sub {
    my ( $l, $w ) = @_;
    $w->gobject->set_buffer( $w->buffer->gobject ) if $w->buffer;
};

# ToggleButton
build 'Gapp::ToggleButton', sub {
    my ( $l, $w ) = @_;
    my $gtkw = $w->gobject;
    
    my ( $image );
    if ( $w->image ) {
	$image = $w->image->gobject;
    }
    elsif ( $w->icon ) {
	$image = Gtk2::Image->new_from_stock( $w->icon, $w->icon_size || 'button' );
    }
    

    
    $gtkw->set_label( $w->label ) if defined $w->label && ! defined $w->mnemonic;
    $gtkw->set_image( $image ) if defined $image;
    $gtkw->set_tooltip_text( $w->tooltip ) if defined $w->tooltip;
};


# Toolbar
build 'Gapp::Toolbar', sub {
    my ( $l, $w ) = @_;
    $w->gobject->set_icon_size( $w->icon_size ) if $w->icon_size;
};

# ToolItem

add 'Gapp::ToolItem', to 'Gapp::Toolbar', sub {
    my ($l,  $w, $c) = @_;
    $c->gobject->insert( $w->gwrapper, -1 );
    $c->gobject->child_set_property( $w->gwrapper, 'homogeneous',  1 );
};


# ToolButton

style 'Gapp::ToolButton', sub {
    my ( $l, $w ) = @_;
    
    my $image = $w->image ?
    $w->image->gobject :
    Gtk2::Image->new_from_stock( $w->icon || 'gtk-dialog-error' , $w->icon_size || 'large-toolbar' );
    
    $w->set_args( [ $image, defined $w->label ? $w->label : ''  ] );
};


build 'Gapp::ToolButton', sub {
    my ( $l, $w ) = @_;
    my $gtkw = $w->gobject;
   
    $gtkw->set_stock_id( $w->stock_id ) if $w->stock_id;
    $gtkw->set_label( $w->label ) if defined $w->label;
    $gtkw->set_tooltip_text( $w->tooltip ) if defined $w->tooltip;
    $gtkw->set_homogeneous( 1 ) if $w->homogeneous;
};

paint 'Gapp::ToolButton', sub {
    my ( $l, $w ) = @_;
    return if ! $w->action;
    
    my ( $action, @args ) = parse_action ( $w->action );
    
    if ( is_CodeRef $action ) {
	$w->signal_connect( 'clicked', $action, \@args );
    }
    else {
	my $gtkw = $w->gobject;
	$gtkw->set_label( $action->label ) if ! defined $w->label && defined $action->label;
	$gtkw->set_icon_widget( $action->create_gtk_image( $w->icon_size || 'large-toolbar' ) ) if ! $w->icon  && ! $w->image && defined $action->icon;
	$gtkw->set_tooltip_text( $action->tooltip ) if ! defined $w->tooltip && defined $action->tooltip;
	$gtkw->signal_connect( clicked => actioncb( $action, $w, \@args ) );
    }
};

style 'Gapp::ToggleToolButton', sub {
    my ( $l, $w ) = @_;
};



# TreeView

build 'Gapp::TreeView', sub {
    my ( $l, $w ) = @_;
    my $gtkw = $w->gobject;
    
    my $model = $w->model;
    
    $gtkw->set_model( $model->isa('Gapp::Object') ? $model->gobject : $model ) if $model;
};

# TreeViewColumn

build 'Gapp::TreeViewColumn', sub {
    my ( $l, $w ) = @_;
    
    my $gtkw = $w->gobject;
    
    if ( $w->renderer ) {
	
	my $gtkr = $w->renderer->gobject;
	$gtkw->{renderer} = $gtkr;
	
	# add the renderer to the column
	$gtkw->pack_start( $gtkr, $w->renderer->expand ? 1 : 0 );
	
	# set the data function
	$gtkw->set_cell_data_func($gtkr, sub {
	    my ( $col, $gtkrenderer, $model, $iter, @args ) = @_;
	    my $value = $w->get_cell_value( $model->get( $iter, $w->data_column ) );
	    $gtkrenderer->set_property( $w->renderer->property => $value );
	});
    }
    
    # if sorting enabled
    if ( $w->sort_enabled ) {
	$w->gobject->set_clickable( 1 );
	$w->gobject->signal_connect( 'clicked', sub {
	    $w->gobject->get_tree_view->get_model->set_default_sort_func( sub {
		my ( $model, $itera, $iterb, $w ) = @_;
		my $a = $model->get( $itera, $w->data_column );
		my $b = $model->get( $iterb, $w->data_column );
		$w->sort_func->( $w, $a, $b );
	    }, $w)
	} );
    }
};

# Widget

add 'Gapp::Widget', to 'Gapp::AssistantPage', sub {
    my ($l,  $w, $c ) = @_;
    $c->gobject->pack_start( $w->gwrapper, $w->expand, $w->fill, $w->padding );
};

add 'Gapp::Widget', to 'Gapp::Bin', sub {
    my ($l,  $w, $c ) = @_;
    $c->gobject->add( $w->gwrapper );
};

add 'Gapp::Widget', to 'Gapp::Container', sub {
    my ($l,  $w, $c) = @_;
    $c->gobject->pack_start( $w->gwrapper, $w->expand, $w->fill, $w->padding );
};

add 'Gapp::Widget', to 'Gapp::Expander', sub {
    my ($l,  $w, $c ) = @_;
    $c->gobject->add( $w->gwrapper );
};


add 'Gapp::Widget', to 'Gapp::HBox', sub {
    my ($l,  $w, $c ) = @_;
    $c->gobject->pack_start( $w->gwrapper, $w->expand, $w->fill, $w->padding );
};

add 'Gapp::Widget', to 'Gapp::VBox', sub {
    my ($l,  $w, $c ) = @_;
    $c->gobject->pack_start( $w->gwrapper, $w->expand, $w->fill, $w->padding );
};

add 'Gapp::Widget', to 'Gapp::Paned', sub {
    my ($l,  $w, $c ) = @_;
    
    if ( ! $c->gobject->get_child1 ) {
	$c->gobject->pack1( $w->gwrapper, $c->resize1, $c->shrink1 );
    }
    else {
	$c->gobject->pack2( $w->gwrapper, $c->resize2, $c->shrink2 );
    }
};

add 'Gapp::Widget', to 'Gapp::Dialog', sub {
    my ($l,  $w, $c ) = @_;
    $c->gobject->vbox->pack_start( $w->gwrapper, $w->expand, $w->fill, $w->padding );
    $w->gobject->show;
};

add 'Gapp::Widget', to 'Gapp::Table', sub {
    my ( $l, $w, $c ) = @_;
    
    my $cell = $c->next_cell;
    
    my $gtkw;
    if ( defined $cell->xalign || defined $cell->yalign ) {
        my ( $xa, $ya ) = ( $cell->xalign, $cell->yalign );
        my $xs = $xa == -1 ? 1 : 0; # x-scale
	my $ys = $ya == -1 ? 1 : 0; # y-scale
        $xa = 0 if $xa == -1; # x-align
        $ya = 0 if $ya == -1; # y-align
        
        my $gtk_align = Gtk2::Alignment->new( $xa, $ya, $xs, $ys );
        $gtk_align->add( $w->gwrapper );
        $gtkw = $gtk_align;
    }
    else {
        $gtkw = $w->gwrapper;
    }
    
    
    $c->gobject->attach(
        $gtkw, $cell->table_attach, 
        0, 0
    );
    
    
    1;
};

add 'Gapp::Widget', to 'Gapp::ToolItemGroup', sub {
    my ($l,  $w, $c ) = @_;
    $c->gobject->add( $w->gwrapper );
};

add 'Gapp::Widget', to 'Gapp::ToolPalette', sub {
    my ($l,  $w, $c ) = @_;
    $c->gobject->add( $w->gwrapper );
};

add 'Gapp::Widget', to 'Gapp::Window', sub {
    my ($l,  $w, $c ) = @_;
    $c->gobject->add( $w->gwrapper );
};

# Window

build 'Gapp::Window', sub {
    my ( $l, $w ) = @_;
    $w->gobject->set_icon( $w->gobject->render_icon( $w->icon, 'dnd' ) ) if $w->icon;
    $w->gobject->set_transient_for( $w->transient_for->gobject ) if $w->transient_for;
};




1;
