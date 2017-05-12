package Gtk2::Ex::DbLinker::Datasheet;
use Gtk2::Ex::DbLinker;
our $VERSION = $Gtk2::Ex::DbLinker::VERSION;

use strict;
use warnings;

use Gtk2::Ex::DbLinker::DatasheetHelper;
#use Carp;
use Glib qw/TRUE FALSE/;

#use Data::Dumper;

use constant {
    UNCHANGED     => 0,
    CHANGED       => 1,
    INSERTED      => 2,
    DELETED       => 3,
    LOCKED        => 4,
    STATUS_COLUMN => 0
};

#if number is build with GLib::Int there a default 0 value that is added in a new row and that cannot be reset to undef
#auto incremented primary keys are not correct then.
#Putting Glib::String prevents this

my %render = (
    text          => [ sub { return Gtk2::CellRendererText->new; },     "Glib::String", ],
    hidden        => [ sub { return Gtk2::CellRendererText->new; },     "Glib::String" ],
    number        => [ sub { return Gtk2::CellRendererText->new; },     "Glib::String" ],
    toggle        => [ sub { return Gtk2::CellRendererToggle->new; },   "Glib::Boolean" ],
    combo         => [ sub { return Gtk2::CellRendererCombo->new; },    "Glib::String" ],
    progress      => [ sub { return Gtk2::CellRendererProgress->new; }, "Glib::Int" ],
    status_column => [ sub { return Gtk2::CellRendererPixbuf->new; },   "Glib::Int" ],
    image         => [ sub { return Gtk2::CellRendererPixbuf->new; },   "Glib::Int" ],
    boolean       => [ sub { return Gtk2::CellRendererText->new; },     "Glib::String" ],
    time          => [ sub { return Gtk2::CellRendererText->new; },     "Glib::String" ],
);

#
# sub return a ref to the xx_edited sub since this coderef is called as $self->xxx_edited
# $self is the first arg received and @_ holds the rest: hence shift->xxx_edited(@_)
#
#$codref = $signal{$cell_ref};
#to use the coderef, a second code ref is passed to signal_connect, signal => sub { $self->$codref(@_)}
#all this to have $self as the first arg in the xxx_edited sub ...
#
my %signals = (
    'Gtk2::CellRendererText'   => [ 'edited',  sub { shift->_cell_edited(@_) } ],
    'Gtk2::CellRendererToggle' => [ 'toggled', sub { shift->_toggle_edited(@_) } ],
    'Gtk2::CellRendererCombo'  => [ 'edited',  sub { shift->_combo_edited(@_) } ],

);

sub new {

    #my ($class, $req) = @_;
    my $class = shift;
    my %def = ( null_string => "null" );

    # my $self = $class->SUPER::new();

=for comment
	 my $self ={
		dman => $$req{data_manager},
		treeview => $$req{treeview},
		fields => $$req{fields}, 
		null_string => $$req{null_string} || "null",
		on_changed => $$req{on_changed}, # Code that runs when a record is changed ( any column )
		on_row_select => $$req{on_row_select},
		multi_select => $$req{multi_select},   
	};
=cut

    my %arg = ( ref $_[0] eq "HASH" ? ( %def, %{ $_[0] } ) : ( %def, @_ ) );
    my $self;
    @$self{qw(dman)} = delete @arg{qw(data_manager)};
    @$self{ keys %arg } = values(%arg);
    bless $self, $class;

    $self->{log} = Log::Log4perl->get_logger("Gtk2::Ex::DbLinker::Datasheet");
    my @cols = $self->{dman}->get_field_names;

    # cols holds the field names from the table. Nothing else !
    $self->{cols} = \@cols;
    my %hcols = map { $_ => 1 } @cols;
    $self->{hcols} = \%hcols;
    $self->{log}->debug( "cols: " . join( " ", @cols ) );

    $self->{ds_helper} = Gtk2::Ex::DbLinker::DatasheetHelper->new(
        cols       => $self->{cols},
        dman       => $self->{dman},
	#col_number => sub { $self->colnumber_from_name( $_[0] ) },
    );
    ( $self->{fields}, undef) = 
        $self->{ds_helper}->setup_fields(
	    allfields=> $self->{fields}, 
	    cols=> $self->{cols}, 
	    status_col => {name => "_status_column_", renderer      => "status_column", header_markup => ""}
            );

    $self->_setup_treeview;

    return $self;

}

sub _setup_treeview {
    my ($self) = @_;

    #setuptreeview
    my $treeview_type = "treeview";
    $self->{status_icon_width} = 0;

    # $self->{treeview} = Gtk2::TreeView->new;
    #
    my @apk = $self->{dman}->get_autoinc_primarykeys;
    $self->{log}->debug( "auto inc pk: " . join( " ", @apk ) );

    my $lastcol = scalar @{ $self->{fields} };

    # additional tree columns to hold the displayed values of the combos
    my @combodata;

    if ( $treeview_type eq "treeview" ) {
        $self->{icons}[UNCHANGED] =
          $self->{treeview}->render_icon( "gtk-yes", "menu" );
        $self->{icons}[CHANGED] =
          $self->{treeview}->render_icon( "gtk-refresh", "menu" );
        $self->{icons}[INSERTED] =
          $self->{treeview}->render_icon( "gtk-add", "menu" );
        $self->{icons}[DELETED] =
          $self->{treeview}->render_icon( "gtk-delete", "menu" );
        $self->{icons}[LOCKED] =
          $self->{treeview}->render_icon( "gtk-dialog-authentication", "menu" );

        foreach my $icon ( @{ $self->{icons} } ) {
            my $icon_width = $icon->get_width;
            if ( $icon_width > $self->{status_icon_width} ) {
                $self->{status_icon_width} = $icon_width;
            }
        }

        # Icons don't seem to take up the entire cell, so we need some more room. This will do ...
        $self->{status_icon_width} += 10;
    }

    # Now set up the model and columns

    for my $field ( @{ $self->{fields} } ) {

        my $renderer = $render{ $field->{renderer} }[0]();

        my $cell_ref = ref $renderer;

        $self->{log}->debug( "Setup tv : field name : " . $field->{name} . " " . $field->{column} . " ref: " . $cell_ref );

        push @{ $self->{ $treeview_type . "_treestore_def" } }, $render{ $field->{renderer} }[1];

        if ( $field->{renderer} eq "status_column" ) {

            $field->{ $treeview_type . "_column" } = Gtk2::TreeViewColumn->new_with_attributes( "", $renderer );
            $self->{$treeview_type}->append_column( $field->{ $treeview_type . "_column" } );

            # Otherwise set fixed width
            $field->{x_absolute} = $self->{status_icon_width};
            $field->{ $treeview_type . "_column" }->set_cell_data_func(
                $renderer,
                sub {
                    my ( $tree_column, $renderer, $model, $iter ) = @_;
                    my $status = $model->get( $iter, STATUS_COLUMN );
                    $renderer->set( pixbuf => $self->{icons}[$status] );
                    return FALSE;
                }
            );

        } else {

           # no de la col
            $renderer->{column} = $field->{column};

            if ( $field->{renderer} eq "toggle" ) {

                $renderer->set( activatable => TRUE );

                # $renderer->set( editable => TRUE );
                $field->{ $treeview_type . "_column" } = Gtk2::TreeViewColumn->new_with_attributes( $field->{name}, $renderer, 'active' => $field->{column} );
            } elsif ( $field->{renderer} eq "combo" ) {
                $renderer->set_fixed_size( $field->{x_percent} * 20, -1 )
                  if ( $field->{x_percent} );
                my $model = $self->_setup_combo( $field->{name} );
                $renderer->set(
                    editable    => TRUE,
                    text_column => 1,
                    has_entry   => FALSE,
                    model       => $model
                );
                $renderer->{col_data} = $lastcol++;

                push @combodata, "Glib::String";

                $self->{log}->debug( "field name with combo renderer: " . $field->{name} );

                #my $fieldtype = $self->{fieldsType}->{$field->{name}};
                my $fieldtype = $self->{ds_helper}->get_gui_type($self->{dman}->get_field_type( $field->{name} ));
		#$fieldtype{ $self->{dman}->get_field_type( $field->{name} ) };

                # $self->{log}->debug("combo field type : " . $fieldtype);
                if ( $fieldtype eq "number" ) {    # serial, intege but not boolean ...
                                                   # $renderer->{data_type} = "numeric";
                    $renderer->{comp} = sub {
                        my ( $a, $b, $c ) = @_;
                        return ( $c ? ( $a == $b ) : ( $a != $b ) );
                    };
                } else {

                    # $renderer->{data_type} = "string";
                    $renderer->{comp} = sub {
                        my ( $a, $b, $c ) = @_;
                        return ( $c ? ( $a eq $b ) : ( $a ne $b ) );
                    };
                }
                $field->{ $treeview_type . "_column" } = Gtk2::TreeViewColumn->new_with_attributes( $field->{name}, $renderer, 'text' => $renderer->{col_data} );

            } else {
                $self->{log}->debug( "field name with txt renderer: " . $field->{name} );

                #if ($field->{name} ~~ @apk) {
                if ( grep /^$field->{name}$/, @apk ) {
                    $self->{log}->debug("not editable because it's a pk");
                    $renderer->set( editable => FALSE );
                } else {
                    $renderer->set( editable => TRUE );
                }
                $field->{ $treeview_type . "_column" } = Gtk2::TreeViewColumn->new_with_attributes( $field->{name}, $renderer, 'text' => $field->{column} );

            }

            # $self->{log}->debug(ref $renderer . " col: " . $field->{column} );

            if ( $field->{renderer} eq "hidden" ) {
                $field->{ $treeview_type . "_column" }->set_visible(FALSE);
            } else {

                #$renderer->signal_connect (edited => sub { $self->cell_edited(@_)});
                if ( exists $signals{$cell_ref} ) {
                    $self->{log}->debug( " signal : " . $signals{$cell_ref}[0] );
                    my $coderef = $signals{$cell_ref}[1];

                    # $renderer->signal_connect ( $signals{$cell_ref}[0] => $coderef, $self );
                    $renderer->signal_connect( $signals{$cell_ref}[0] => sub { $self->$coderef(@_) } );
                }

            }

            $self->{$treeview_type}->append_column( $field->{ $treeview_type . "_column" } );

            $field->{ $treeview_type . "_column" }->{renderer} = $renderer;

            if ( exists $field->{custom_render_functions} ) {

                # $self->{suppress_gtk2_main_iteration_in_query} = TRUE;
                $field->{ $treeview_type . "_column" }->{custom_render_functions} = $field->{custom_render_functions};
            }

        }    #<> status_col

        $renderer->{on_changed} = $field->{on_changed};

        my $label = Gtk2::Label->new;

        if ( exists $field->{header_markup} ) {
            $label->set_markup( $field->{header_markup} );
        } else {
            $label->set_text("$field->{name}");
        }

        $label->visible(1);

        $field->{ $treeview_type . "_column" }->set_widget($label);

        if ( exists $field->{ $treeview_type . "_column" }->{custom_render_functions} ) {
            $field->{ $treeview_type . "_column" }->set_cell_data_func(
                $renderer,
                sub {
                    my ( $tree_column, $renderer, $model, $iter, @all_other_stuff ) = @_;
                    $tree_column->{render_value} =
                      $model->get( $iter, $renderer->{column} );
                    foreach my $render_function ( @{ $tree_column->{custom_render_functions} } ) {
                        &$render_function( $tree_column, $renderer, $model, $iter, @all_other_stuff );
                    }
                    return FALSE;
                }
            );
        }

        if ( $field->{renderer} eq "combo" ) {

            $renderer->signal_connect(
                "editing-started" => sub { $self->_start_editable(@_) },
                $renderer
            );

        }

    }    # for $field ...

    #add fields for the combodata if any
    for my $v (@combodata) {
        push @{ $self->{ $treeview_type . "_treestore_def" } }, $v;
    }

    # Turn on multi-select mode if requested
    if ( $self->{multi_select} ) {
        $self->{$treeview_type}->get_selection->set_mode("multiple");
    }

}    #setup_treeview

#the first field links the data from the table with a value in the list
#the remaining fields are displayed in the combo
# the type of the first field is in ->{fieldsType} the other(s) are supposed to be strings

sub _setup_combo {
    my ( $self, $fieldname ) = @_;

    my $fields = $self->{fields}[ $self->colnumber_from_name($fieldname) ];

  my $col_ref =  $self->{ds_helper}->init_combo_setup(name => $fieldname, fields => $fields);

   my @liste_def = $self->{ds_helper}->get_liste_def(
	   fields =>$fields , 
	   renderer=> \%render, 
	   default_renderer=>"Glib::String",
	   col_ref => $col_ref,
   );
    $self->{ds_helper}->setup_combo(
        fields  => $fields,
        name    => $fieldname,
        col_ref => $col_ref,
        model   => Gtk2::ListStore->new(@liste_def)

    );

}

sub update {
    my ($self) = @_;

    #my ($self, $data) = @_;

    #keep the value of the hash ref by ->{data} unchanged if
    # $data is undef
    #$self->{data} = $data if ($data);
    my $treeview_type = "treeview";
    my $last          = $self->{dman}->row_count;
    $self->{log}->debug( "datasheet query: " . $last . " rows" );

    #my $row_pos = 0;
    my $liststore =
      Gtk2::ListStore->new( @{ $self->{ $treeview_type . "_treestore_def" } } );

    # foreach my $row (@{$self->{data}}){
    for ( my $i = 0 ; $i < $last ; $i++ ) {

        # $self->{log}->debug("Datasheet query set row pos " . $i);
        $self->{dman}->set_row_pos($i);
        my @combo_values;
        my @model_row;
        my $column = 0;

        for my $field ( @{ $self->{fields} } ) {
            if ( $column == 0 ) {

                my $record_status = UNCHANGED;

                # $self->{log}->debug("Col " . $column . " added");
                push @model_row, $liststore->append, STATUS_COLUMN, $record_status;

            } else {
                my $x = "";

                # if ( $field->{name} ~~ @{$self->{cols}}) {
                if ( defined $self->{hcols}->{ $field->{name} } ) {
                    # $self->{log}->debug("query: " .  $field->{name} . " row: " . $i );
                    $x = $self->{dman}->get_field( $field->{name} );
                    # $self->{log}->debug( $field->{name} . " " . (defined $x ? "x: " . $x : "x undefined"));
                    if ( defined $x ) {
                        # $self->{log}->debug( $field->{name} . " " . ( $x ne "" ? "x: " . $x : "x zls"));
                        $x = ( $x eq $self->{null_string} ? "" : $x );
                    }

                } else {
                    $self->{log}->debug( "update: " . $field->{name} . " not found in " . join( " ", @{ $self->{cols} } ) );
                }
                # $self->{log}->debug("field: ". $field->{name} . " col.: " . $column . " value: " . (defined $x?$x:" undef "));
                push @model_row, $column, $x;
                #die unless defined($x);
                if ( $field->{renderer} eq "combo" && defined $x && $x ne "" ) {
                    my @renderers  = $field->{ $treeview_type . "_column" }->get_cell_renderers;
                    my $combomodel = $renderers[0]->get("model");
                    # $self->{log}->debug("data-t: " . $field->{ $treeview_type . "_column" }->{renderer}->{data_type});
                    my $value = $self->_combo_value( $combomodel, $x, $field->{ $treeview_type . "_column" }->{renderer}->{comp} );
                    # push @combo_values, $value;
                    push @model_row, $renderers[0]->{col_data}, $value;
                }
            }    #else
            $column++;
        }    #for each column

        {
            no warnings 'numeric';
            $liststore->set(@model_row);

            # use warnings;
        }
    }    # foreach row

    if ( $self->{row_select_signal} ) {
        $self->{treeview}->get_selection->signal_handler_disconnect( $self->{row_select_signal} );
    }

    $self->{log}->debug("update done");
    $self->{changed} = FALSE;

    #  if ( $self->{on_changed} ) {
    $self->{log}->debug("binding on_changed callback");
    $self->{changed_signal} = $liststore->signal_connect( "row-changed" => sub { $self->_changed(@_); } );

    # }

    if ( $self->{on_row_select} ) {
        $self->{log}->debug("binding row_select callback");
        $self->{row_select_signal} = $self->{treeview}->get_selection->signal_connect( changed => sub { $self->{on_row_select}(@_); } );
    }

    $self->{treeview}->set_model($liststore);

    return FALSE;
}    #sub

sub get_column_value {

    # returns the value in the requested column in the currently selected row
    # If multi_select is turned on and more than 1 row is selected, it looks in the 1st row

    my ( $self, $sql_fieldname ) = @_;

    my @selected_paths = $self->{treeview}->get_selection->get_selected_rows;

    if ( !scalar(@selected_paths) ) {
        return 0;
    }

    my $model = $self->{treeview}->get_model;
    my @selected_values;

    foreach my $selected_path (@selected_paths) {

        my $column_no = $self->colnumber_from_name($sql_fieldname);
        my $value = $model->get( $model->get_iter($selected_path), $column_no );

        push @selected_values, $value;

    }

    if ( $self->{multi_select} ) {
        return @selected_values;
    } else {
        return $selected_values[0];
    }

}

sub set_column_value {

    # sets the value in the requested column in the currently selected row

    my ( $self, $sql_fieldname, $value ) = @_;

    if ( $self->{multi_select} ) {
        $self->{log}->debug( "set_column_value called with multi_select enabled -> setting value in 1st selected row" );
    }

    my @selected_paths = $self->{treeview}->get_selection->get_selected_rows;

    if ( !scalar(@selected_paths) ) {
        return 0;
    }

    my $model = $self->{treeview}->get_model;
    my $iter  = $model->get_iter( $selected_paths[0] );

    $model->set( $iter, $self->colnumber_from_name($sql_fieldname), $value );

    return TRUE;

}

sub colnumber_from_name {

    my ( $self, $fieldname ) = @_;
    # confess("fieldname undef") unless ( defined $fieldname );
    # return $self->{colname_to_number}->{$fieldname}
    return $self->{ds_helper}->colnumber_from_name($fieldname);

}

sub undo {

    #shift->query;
    shift->update;
}

#called by on-change event for each row of the treeview
#added by query

sub _changed {

    my ( $self, $liststore, $treepath, $iter ) = @_;

    $self->{log}->debug("changed\n");

    my $model = $self->{treeview}->get_model;

    # Only change the record status if it's currently unchanged
    if ( !$model->get( $iter, STATUS_COLUMN ) ) {
        $model->signal_handler_block( $self->{changed_signal} );
        $model->set( $iter, STATUS_COLUMN, CHANGED );
        $model->signal_handler_unblock( $self->{changed_signal} );
    }

    if ( $self->{on_changed} ) {
        $self->{on_changed}(
            {
                treepath => $treepath,
                iter     => $iter
            }
        );
    }

    $self->{changed} = TRUE;

    return FALSE;

}

sub apply {
    my $self  = shift;
    my $pkref = ( defined $_[0] ? $_[0] : undef );
    my $model = $self->{treeview}->get_model;
    my $iter  = $model->get_iter_first;

    #$self->{ds_helper}->init_iter( $model, $self->{changed_signal});
    $self->{ds_helper}->init_apply(
        sig       => $self->{changed_signal},
        sig_block => sub { $self->{log}->debug("sig_block"); $model->signal_handler_block( $_[0] ) },
        sig_unblock => sub { $model->signal_handler_unblock( $_[0] ) },
        next        => sub { $model->iter_next( $_[0] ) },
        get_val     => sub { $self->{log}->debug( "get_val col: ", $_[1] ); my $x = $model->get( $_[0], $_[1] ); $self->{log}->debug( "get_val found ", $x ); return $x },
        set_val => sub { $self->{log}->debug( "set_val", $_[2] ); $model->set( $_[0], $_[1], $_[2] ) },
        del_row => sub { $model->remove( $_[0] ) },
        has_more_row => sub { return ( defined $iter ? 1 : 0 ) },
        iter => $iter,
	status_col => STATUS_COLUMN,

    );

    $self->{ds_helper}->apply($pkref);
    
    return FALSE;

}

sub insert {

    my ( $self, @columns_and_values ) = @_;
    my $model = $self->{treeview}->get_model;
    my $iter  = $model->append;
    $self->{log}->debug("inserting...");

    # print Dumper(@columns_and_values);
    my @new_record;

    push @new_record, $iter, STATUS_COLUMN, INSERTED;

    if (@columns_and_values) {
        push @new_record, @columns_and_values;
    }
    $self->{log}->debug( "new rec default values: " . join( " ", @new_record ) );
    $model->set(@new_record);

    $self->{treeview}->set_cursor( $model->get_path($iter), $self->{fields}[0]->{treeview_column}, 0 );

    # Now scroll the scrolled window to the end
    # Using an idle timer is required because gtk needs time to add the new row ...
    #  ... if we don't use an idle timer, we end up scrolling to the 2nd-last row

    Glib::Idle->add(
        sub {
            my $adjustment = $self->{treeview}->get_vadjustment;
            my $upper      = $adjustment->upper;
            $adjustment->set_value( $upper - $adjustment->page_increment - $adjustment->step_increment );
        }
    );

    return TRUE;

}

sub delete {

    my $self = shift;

    # We only mark the selected record for deletion at this point
    my @selected_paths = $self->{treeview}->get_selection->get_selected_rows;
    my $model          = $self->{treeview}->get_model;

    for my $path (@selected_paths) {
        my $iter = $model->get_iter($path);

        $model->set( $iter, STATUS_COLUMN, DELETED );
    }

    return FALSE;

}

sub has_changed {
    my $self = shift;

    #there is no child datasheet or child form in a datasheet (or ?)
    return ( $self->{changed} ? 1 : 0 );
}

sub get_current_row {
    my $self = shift;
    return $self->{curr_row};

}

sub _cell_edited {
    my ( $self, $cell, $path_string, $new_text ) = @_;
    $self->{log}->debug( "_cell_edited path_String : " . $path_string );
    my $path  = Gtk2::TreePath->new_from_string($path_string);
    my $model = $self->{treeview}->get_model;
    my $col   = $cell->{column};
    $self->{curr_row} = $path_string;
    my $iter = $model->get_iter($path);

    $model->set_value( $iter, $col, $new_text );
    return FALSE;
}

sub _toggle_edited {
    my ( $self, $renderer, $text_path, $something ) = @_;
    my $column_no = $renderer->{column};
    $self->{log}->debug( "_toggle_edited path" . $text_path );
    $self->{curr_row} = $text_path;
    my $path      = Gtk2::TreePath->new($text_path);
    my $model     = $self->{treeview}->get_model;
    my $iter      = $model->get_iter($path);
    my $old_value = $model->get( $iter, $renderer->{column} );
    my $new_text  = !$old_value;

    $model->set( $iter, $renderer->{column}, $new_text );
    return FALSE;
}

#called after a change in the combo
# $combo -> $tree
sub _combo_edited {
    my ( $self, $renderer, $path_string, $new_text ) = @_;

    # return unless ($tree);
    #  treeViewModel[path][columnNumber] = newText
    my $model = $self->{treeview}->get_model;

    #print( "combo_edited " . $new_text . "\n" );
    $self->{log}->debug( "_combo_edited path_string: " . $path_string );

    #	$cell->get("model");
    #	$model->set ($iter, $cell->{column}, $new_text);
    my $path   = Gtk2::TreePath->new_from_string($path_string);
    my $citer  = $renderer->{combo}->get_active_iter;
    my $cmodel = $renderer->{combo}->get_model;
    $self->{curr_row} = $path_string;
    my $value = $cmodel->get( $citer, 0 );
    print( "combo_edited value :" . $value . "\n" );
    my $iter = $model->get_iter($path);
    $model->set( $iter, $renderer->{column},   $value );
    $model->set( $iter, $renderer->{col_data}, $new_text );
}

sub _start_editable {
    my ( $self, $cell, $editable, $path, $renderer ) = @_;
    $self->{log}->debug("start_editable");

    # print Dumper($editable);
    # $maincombo = $editable;
    $renderer->{combo} = $editable;

}

sub _combo_value {
    my ( $self, $combo_model, $id, $comp_ref ) = @_;
    my $iter = $combo_model->get_iter_first();
    my $key  = -1;
    my $value;

    # while ($iter && $key != $id){
    while ( $iter && &$comp_ref( $key, $id, 0 ) ) {
        $key = $combo_model->get_value( $iter, 0 );

        #  if ($key == $id) {
        if ( &$comp_ref( $key, $id, 1 ) ) {

            $value = $combo_model->get_value( $iter, 1 );

            #$self->{log}->debug( "found : " . $value . " for ". $id);
            last;
        }
        $iter = $combo_model->iter_next($iter);
    }

    return $value;

}

sub get_data_manager {
    return shift->{dman};
}

1;
__END__

=pod

=head1 NAME

Gtk2::Ex::DbLinker::Datasheet -  a module that display data from a database in a tabular format using a treeview

=head1 VERSION

See Version in 
L<Gtk2::Ex::DbLinker>

=head1 SYNOPSIS

This display a table having to 6 columns: 3 text entries, 2 combo, 1 toogle, we have to create a dataManager object for each combo, and a dataManager for the table itself. The example here use Rose::DB::Object to access the tables.

This gets the Rose::DB::Object::Manager (we could have use plain sql command, or DBIx::Class object) 

    	my $datasheet_rows = Rdb::Mytable::Manager->get_mytable(sort_by => 'field1');

This object is used to instanciante a RdbDataManager, that will be used in the datasheet constructor.

      	my $dman = Gtk2::Ex::DbLinker::RdbDataManager->new(data => $datasheet_rows, meta => Rdb::Mytable->meta );

We create the RdbDataManager for the combo rows

    my $combo_data = Rdb::Combotable::Manager->get_combotable( select => [qw/t1.id t1.name/], sort_by => 'name');
	my $dman_combo_1 = Gtk2::Ex::DbLinker::RdbDataManager->new(data => $combo_data, meta => Rdb::Combotable->meta);


	my $combo2_data =  Rdb::Combotable2::Manager->get_combotable2( sort_by => 'country');
	my $dman_combo_2 = Gtk2::Ex::DbLinker::RdbDataManager->new( 
					     		data =>$combo2_data,
						        meta => Rdb::Combotable2->meta,
							);

We create the Datasheet object with the columns description

	my $treeview = Gtk2::TreeView->new();

	$self->{datasheet} = Gtk2::Ex::DbLinker::Datasheet->new(
		treeview => $treeview,
		fields => [{name=>"field1", renderer=>"text"},
			{name=>"field2"}, 
			{name=>"url", renderer=>"text", custom_render_functions => [sub {display_url (@_, $self);},]},
			{name => 'nameid', renderer => 'combo', data_manager => $dman_combo_1, fieldnames=>["id", "name"]},
			{name => 'countryid', renderer => 'combo', 
				     data_manager=> $dman_combo_2,
					fieldnames=>["id", "country"]}, 
			{name => 'idle', renderer => 'toggle'},
				],
		data_manager => $dman,		
	);

To change a set of rows in the table when we navigate between records for example, we fetch the rows using a object derived from Rose::DB::Object::Manager and pass it to the Gt2::Ex::DbLinker::RdbDatamanager object using the query method:

	  my $data =  Rdb::Mytable::Manager->get_mytable(query =>[pk_field =>{eq=> $primarykey_value}], sort_by => 'field1');
	  $self->{dataseet}->get_data_manager->query($data);

	  $self->{datasheet}->update();



=head1 DESCRIPTION

This module automates the process of setting up a model and treeview based on field definitions you pass it. An additional column named _status_column_ is added in front of a the other fields. It holds icons that shows if a row is beeing edited, mark for deletion or is added.

Steps for use:

=over

=item * 

Instanciate a xxxDataManager that will fetch a set of rows.

=item * 

Create a 'bare' Gtk2::TreeView.

=item *

Create a xxxDataManager holding the rows to display, if the datasheet has combo box, create the corresponding DataManager that hold the combo box content.

=item * 

Create a Gtk2::Ex::DbLinker::Datasheet object and pass it your TreeView and DataManagers objects. 

You would then typically connect some buttons to methods such as inserting, deleting, etc.

=back

=head1 METHODS

=head2 constructor

The C<new()> method expects a list of parameters name => value or a hash reference of parameters name (keys) / value pairs.

The parameters are:

=over

=item * 

C<data_manager> a instance of a xxxDataManager object.

=item *

C<tree> a Gtk2::TreeView

=item *

C<fields> a reference to an array of hash refs. Each hash has the following key / value pairs.

=over

=item *

C<name> / name of the field to display.

=item *

C<renderer> / one of "text combo toggle hidden image".

=back

if the renderer is a combo the following key / values are needed in the same hash reference:

=over

=item *

C<data_manager> / an instance holding the rows of the combo.

=item *

C<fieldnames> / a reference to an array of the fields that populate the combo. The first one is the return value that correspond to the field given in C<name>.

=back

=back

=head2 C<update();>

Reflect in the user interface the changes made after the data manager has been queried, or on the datasheet creation.

=head2 C<get_data_manager();>

Returns the data manager to be queried.


=head2 Methods applied to a row of data:

=over 

=item *

C<insert();>

Displays an empty rows.

=item *

C<delete();>

Marks the current row to be deleted. The delele itself will be done on apply.

=item *

C<apply();>

Create a new row in the DataManager and fetchs the values from the grid, and add this row to the database. Save changes on an existing row, or delete the row(s) marked for deletion. An array ref of fields name can be given to prevent these from being saved. This is usefull to change the row flag from modified to unmodif when the change are saved directly with the DataManager.

=item *

C<undo();>

Revert the row to the original state in displaying the values fetch from the database.

=back

=head1 SUPPORT

Any Gk2::Ex::DbLinker questions or problems can be posted to me (rappazf) on my gmail account. 

The current state of the source can be extract using Mercurial from
L<http://sourceforge.net/projects/gtk2-ex-dblinker/>.

=head1 AUTHOR

FranE<ccedil>ois Rappaz <rappazf@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2017 by FranE<ccedil>ois Rappaz.  All rights reserved.  This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Gtk2::Ex::Datasheet::DBI>

=head1 CREDIT

Daniel Kasak, whose modules initiate this work.

=cut

