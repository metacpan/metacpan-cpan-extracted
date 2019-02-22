package Gtk2::Ex::DbLinker::Form;
use Class::InsideOut qw(public private register id);
use Gtk2::Ex::DbLinker;
our $VERSION = $Gtk2::Ex::DbLinker::VERSION;

use strict;
use warnings;
use parent 'Gtk2::Ex::DbLinker::AbForm';
use Glib qw/TRUE FALSE/;
use Carp qw(croak confess carp);
use Log::Any;
#use DateTime::Format::Strptime;
#use Data::Dumper;
my %fieldtype = (
    varchar   => "Glib::String",
    char      => "Glib::String",
    integer   => "Glib::Int",
    boolean   => "Glib::Boolean",
    date      => "Glib::String",
    serial    => "Glib::Int",
    text      => "Glib::String",
    smallint  => "Glib::Int",
    mediumint => "Glib::Int",
    timestamp => "Glib::String",
    enum      => "Glib::String",

);
my %signals = (
    'GtkCalendar'      => 'day_selected',
    'GtkToggleButton'  => 'toggled',
    'GtkTextView'      => \&_get_textbuffer,
    'Gtk2::TextBuffer' => 'changed',
    'GtkComboBoxEntry' => 'changed',
    'GtkComboBox'      => 'changed',
    'GtkCheckButton'   => 'toggled',
    'GtkEntry'         => 'changed',
    'GtkSpinButton'    => 'value_changed'
);

#
#coderef to place the value of record x in each field, combo, toggle...
#
my %setter = (
    'GtkEntry'         => \&_set_entry,
    'GtkToggleButton'  => \&_set_check,
    'GtkComboBox'      => \&_set_combo,
    'GtkComboBoxEntry' => \&_set_combo,
    'GtkCheckButton'   => \&_set_check,
    'GtkSpinButton'    => \&_set_spinbutton,
    'GtkTextView'      => \&_set_textentry

);

my %getter = (
    'GtkEntry' => sub { my ( $self, $w ) = @_; return $w->get_text; },
    'GtkToggleButton' => sub {
        my ( $self, $w ) = @_;
        my $v = $w->get_active;
        return ( defined $v ? $v : 0 );
    },
    'GtkComboBox' =>,
    \&_get_combobox_firstvalue,
    'GtkComboBoxEntry' => \&_get_combobox_firstvalue,
    'GtkCheckButton'   => sub {
        my ( $self, $w ) = @_;
        my $v = $w->get_active;
        return ( defined $v && length($v) ? $v : 0 );
    },
    'GtkSpinButton' => sub {
        my ( $self, $w ) = @_;
        return $w->get_active;
    },
    'GtkTextView' => sub {
        my ( $self, $textview ) = @_;
        my $buffer = $textview->get_buffer;
        return $buffer->get_text( $buffer->get_bounds, FALSE );
    },

);



private log => my %log;
private event => my %events;
private states => my %states;
private widgets => my %widgets;

# 	'GtkSpinButton' => \&set_spinbutton,
# sub {return shift->child->get_text; },
# sub {my $c = shift; print "getter_cbe\n"; my $iter = $c->get_active_iter; return $c->get_model->get( $iter ); }
#
sub new {
    my $class = shift;
   
    #my ($class, $req)=@_;
    my %def = (
        null_string     => "null",
        rec_spinner     => "RecordSpinner",
        status_label    => "lbl_RecordStatus",
        rec_count_label => "lbl_RecordCount",
        locale          => "fr_CH",
        auto_apply      => 1,
        data_lock   => 0,
    );

    my %arg = ( ref $_[0] eq "HASH" ? ( %def, %{ $_[0] } ) : ( %def, @_ ) );

    #   @$self{qw(dman cols)} = delete @arg{qw(data_manager datawidgets)};
    #   @$self{ keys %arg } = values(%arg);
   

my $self = $class->SUPER::new(
        childclass           => __PACKAGE__,
        data_manager => $arg{data_manager},
        builder => $arg{builder},
        datawidgets => $arg{datawidgets},
        on_current => $arg{on_current},
        date_formatters => $arg{date_formatters},
        time_zone => $arg{time_zone},
        locale => $arg{locale},
        rec_spinner_callback => sub {
            my $self = shift;
            my $id = id $self;
            return unless $widgets{ $id}->{rec_spinner};
            $widgets{ $id }->{rec_spinner}
              ->signal_handler_block( $events{ $id }->{rs_value_changed_signal} );
            $widgets{ $id }->{rec_spinner}->set_value( $self->_pos + 1 );
            $widgets{ $id }->{rec_spinner}
              ->signal_handler_unblock( $events{ $id }->{rs_value_changed_signal} );

        },
        rec_spinner_insert_callback => sub {
            my ( $self, $new_pos ) = @_;
            my $id = id $self;
            return unless $widgets{ $id }->{rec_spinner};
            $widgets{ $id }->{rec_spinner}
              ->signal_handler_block( $events{ $id }->{rs_value_changed_signal} );
            my $first = ( $self->_pos < 0 ? 0 : 1 );
            $widgets{ $id }->{rec_spinner}->set_range( $first, $new_pos + 1 );
            $widgets{ $id }->{rec_spinner}->set_value( $new_pos + 1 );
            $widgets{ $id }->{rec_spinner}
              ->signal_handler_unblock( $events{ $id }->{rs_value_changed_signal} );

        },

    );
    register $self;
     my $ido = id $self;
    
    delete @arg{ $self->_super_args_needed };
     my $arg_value_ref = \%arg;

   my $arg_holder_ref = { 
        rec_count_label => \$widgets{ $ido}->{rec_count_label},
        status_label => \$widgets{ $ido}->{status_label},
        rec_spinner => \$widgets{ $ido}->{rec_spinner},
        null_string => \$widgets{ $ido }->{ null_string },
        data_lock => \$events{ $ido }->{data_lock},

    } ;
    for my $name (keys %{$arg_holder_ref}){
        next unless defined ($arg{$name});

        if (ref $arg_holder_ref->{$name} eq "HASH"){
           $arg_holder_ref->{$name}->{ $ido } = $arg_value_ref->{$name};

        } 
        #elsif (ref $arg_holder_ref->{$name} eq "ARRAY") {

        #} 
        else {
            ${ $arg_holder_ref->{$name} } =  $arg{$name};
        
        }
    
    }
   

    #bless $self, $class;

    #$self->{cols} = [];
    $self->_init;
    $self->SUPER::_init;
    #$log{$ido}->debug("\%arg ", Dumper %arg);
    #$log{$ido}->debug("\%widgets ", Dumper %widgets);
=for comment
    my @dates;

    #$self->{subform} = [];

    #my %formatters_db;
    #my %formatters_f;
    # $self->{dates_formatted} = \(keys %{$self->{date_formatters}});
    foreach my $v ( keys %{ $self->{date_formatters} } ) {
        $log{ $id }->debug( "** " . $v . " **" );
        push @dates, $v;
    }
    $self->{dates_formatted} = \@dates;
    my %hdates = map { $_ => 1 } @dates;
    $self->{hdates_formatted} = \%hdates;
    $self->{dates_formatters} = {};
    $self->{inserting}        = 0;
    $self->{pos2del}          = [];
=cut
    return $self;

}    #new

sub _get_setter { my $self = shift; return %setter; }
sub _get_getter { my $self = shift; return %getter; }

sub _init {

    my ($self) = @_;
    my $id = id $self;
    $self->_painting(1);

# get a ref to the Gtk widget used for the record spinner or if the id has been guiven, get the ref via the builder
    $widgets{ $id }->{rec_spinner} = (
        ref $widgets{ $id }->{rec_spinner}
        ? $widgets{ $id }->{rec_spinner}
        : $self->_builder()->get_object( $widgets{ $id }->{rec_spinner} ) );
     if ($widgets{ $id }->{rec_spinner}){
  	$widgets{ $id }->{rec_spinner}->configure(Gtk2::Adjustment->new(1.0, 1.0, 10.0, 1.0, 10.0, 0.0), 0.1, 0);
     }
    $widgets{ $id }->{rec_count_label} = (
        ref $widgets{ $id }->{rec_count_label}
        ? $widgets{ $id }->{rec_count_label}
        : $self->_builder()->get_object( $widgets{ $id }->{rec_count_label} ) );
    $widgets{ $id }->{status_label} = (
        ref $widgets{ $id }->{status_label}
        ? $widgets{ $id }->{status_label}
        : $self->_builder->get_object( $widgets{ $id }->{status_label} ) );

    #$log{ $id } = Log::Log4perl->get_logger(__PACKAGE__);
    $log{ $id } = Log::Any->get_logger;
    $log{ $id }->debug(" ** New Form object ** ");
    $self->_changed(0);
=for comment
    if ( !defined $self->{cols} ) {
        my @col = $self->{dman}->get_field_names;
        $self->{cols} = \@col;
    }
=cut
    $log{ $id }->debug( "_init: cols ", join(" ", @{ $self->_cols  }) );
    $self->_bind_on_changed;
    $self->_set_recordspinner;
    croak($log{ $id }->error("A data manager is required"))
      unless ( defined $self->_dman );
    $self->_dman->set_row_pos(0);
}

#add the values contained in the array @$aref in the combo $name
#the combo has to be a Gtk2::ComboBox

sub add_combo_values {
    my ( $self, $w, $aref ) = @_;
        my $id = id $self;
    my $wref       = ref $w;
    my @supp_class = (qw/Gtk2::ComboBox Gtk2::ComboBoxEntry/);
    my %supported  = map { $_ => 1 } @supp_class;
    confess($log{ $id }->error(
        "only " . join( " ", @supp_class ) . " supported by add_combo_values" ))
      unless ( $supported{$wref} );
    if ( $wref eq "Gtk2::ComboBox" ) {
        my $renderer = Gtk2::CellRendererText->new();
        $w->pack_start( $renderer, 'TRUE' );
        $w->add_attribute( $renderer, 'text', 0 );
    }
    my $size = 0;
    my @model;
    if   ( defined $aref->[0] ) { $size = scalar( @{ $aref->[0] } ); }
    else                        { $aref = []; }
    for ( my $col_i = 0 ; $col_i < $size ; $col_i++ ) {
        push @model, "Glib::String";
    }
    my $lst   = Gtk2::ListStore->new(@model);
    my $i_pos = 0;
    @model = ();
    foreach my $row (@$aref) {
        push @model, $lst->append;
        for ( my $col_i = 0 ; $col_i < $size ; $col_i++ ) {
            push @model, $col_i, $row->[$col_i];
        }
        $lst->set(@model);
        @model = ();

    }
    $w->set_model($lst);
    if ( $wref eq "Gtk2::ComboBoxEntry" ) { $w->set_text_column(0) }
}

#dman must contains all the rows
sub add_combo {

    #my ($self, $req)=@_;
    my $class = shift;
    #my $id = id $class;
    my %h;
    my $req = ( ref $_[0] eq "HASH" ) ? $_[0] : ( %h = (@_) ) && \%h;
    my $combo = {
        dman   => $$req{data_manager},
        id     => $$req{id},
        fields => $$req{fields},

    };

    my $column_no = 0;
    my @cols;
    if ( defined $combo->{fields} ) {
        @cols = @{ $combo->{fields} };
    } else {
        @cols = $combo->{dman}->get_field_names;

    }
    my @list_def;
    my $self;
    if ( $$req{builder} && ( ref $class eq "" ) ) {    #static init

        $self = {};
        bless $self, $class;
        $self->_builder( $$req{builder} );
        my $id = id $self;
        #$log{ $id } = Log::Log4perl->get_logger("Gtk2::Ex::DbLinker::Form");
        $log{ $id } = Log::Any->get_logger();

        my $w = $self->_builder->get_object( $combo->{id} );
        if ($w) {
            my $name = $w->get_name;
            $self->_datawidgets( $combo->{id} , $w);
            $self->_datawidgetsName( $combo->{id},  $name);
        } else {
            croak( $log{ $id }->error( "no widget found for combo " . $combo->{id}));
        }
    } 
    else {
        $self = $class;
    }
    my $id = id $self;
    $log{ $id } = Log::Any->get_logger();
    $log{ $id }->debug( "cols: " . join( " ", @cols ) );
    # $log{ $id }->debug( sub { Dumper $self->_datawidgets } );
    my $w = $self->_datawidgets( $combo->{id} );

    # $log{ $id }->debug( Dumper $self->{datawidgets});
    # die Dumper $w;
    croak($log{ $id }->error( 'no widget found for combo ' . $combo->{id} )) unless ($w);

    #my @col = @{$self->{cols}};
    croak($log{ $id }->error("no fields found for combo $combo->{id}")) unless (@cols);
    my $lastfield = @cols;

    #the column to show is either the first (pos 0) if it's the only column or
    #the first ( and the next )

    my $displayedcol = ( $lastfield > 1 ? 1 : 0 );
    $log{ $id }->debug("displayed col: " . $displayedcol);
    $w->set_text_column($displayedcol);
    my $model = $w->get_model;
    $log{$id}->debug(" intial model " . ( $model ? " def " : "undef"));
    foreach my $field (@cols) {

        #push @list_def, "Glib::String";
        my $type = $combo->{dman}->get_field_type($field);
        my $gtype = $fieldtype{$type} if ($type);
        if ($gtype) {

            $log{ $id }->debug( "field: " . $field . " type : " . $type );
        } else {
            $log{ $id }->debug(
                "no Glib type found for field $field assuming Glib::String");
            $gtype = "Glib::String";
        }
        push @list_def, $gtype;
        $log{ $id }->debug("add_combo: $field $column_no $gtype");

        #column 0 is not shown unless it's the only column

        #column 1 is display in the entrycompletrion code below
        #column above 1 are displayed here:
        if ( ( !defined $model ) && $column_no > 1 ) {

            $log{ $id }->debug("new renderer for $column_no");
            my $renderer = Gtk2::CellRendererText->new;
            $w->pack_start( $renderer, TRUE );

  # $log{ $id }->debug("add_combo: " . $field . " set text for " . $column_no);
            $w->set_attributes( $renderer, 'text' => $column_no );

            #$combo->{renderers_setup} = 1;

        }

        $column_no++;
    }    #for each
         #$combo->{renderers_setup} = 1;

    if ($model) {
        $log{ $id }->debug("clearing existing model");
        $model->clear;

    } else {
        $model = Gtk2::ListStore->new(@list_def);
        $w->set_model($model);
    }
    $log{ $id }->debug( join( " ", @list_def ) );
    my $i;
    my $last = $combo->{dman}->row_count - 1;

    for ( $i = 0 ; $i <= $last ; $i++ ) {

        #$row = $d->column_accessor_value_pairs;

        $combo->{dman}->set_row_pos($i);
        my @model_row;
        my $column = 0;
        push @model_row, $model->append;

        foreach my $field (@cols) {

            #push @model_row, $column, $row->{$field};
            my $value = $combo->{dman}->get_field($field);

            #$log{ $id }->debug("add_combo: " . $value);
            push @model_row, $column++, $value;

            #$column ++;
        }
	#$log{ $id }->debug( "row : " . join( " ", @model_row ) );
        $model->set(@model_row);
    }
    $log{ $id }->debug( "add_combo: " . $i . " rows added" );

    if ( $self->_datawidgetsName( $combo->{id} ) eq "GtkComboBoxEntry" ) {
        $log{ $id }->debug("setting entryCompletion model is " . ( $model ? " def" : " undef"));
        # if ( ! $self->{combos_set}->{$combo->{id}} ) {
        #    $log{ $id }->debug("setting tex_column");
        # $w->set_text_column( 1 );
        # $self->{combos_set}->{ $combo->{id} } = TRUE;
        # }
        my $entrycompletion = Gtk2::EntryCompletion->new;
        $entrycompletion->set_minimum_key_length(1);

        $entrycompletion->set_model($model);
        $entrycompletion->set_text_column($displayedcol);
        $w->get_child->set_completion($entrycompletion);

    }

}    #sub

#bind an onchanged sub with each modification of the datafields
sub _bind_on_changed {
    my $self = shift;
        my $idob = id $self;
    # my @cols = $self->{dman}->get_field_names;
    foreach my $id ( @{ $self->_cols } ) {
        my $w = $self->_builder->get_object($id);
        $log{ $idob }->debug( "bind_on_changed looking for widget " . $id );
        if ($w) {
            my $name = $w->get_name;
            $self->_datawidgets($id, $w);
            $self->_datawidgetsName($id, $name);
            if ( ref( $signals{$name} ) eq "CODE" ) {
                my $coderef = $signals{$name};
                $w = &$coderef( $self, $w );
                $name = ref $w;

            }
            $log{ $idob }->debug("bind  $name $id with self->changed \n");
            $w->signal_connect_after(
                $signals{$name} => sub { $self->_change_values($id) } );
        } else {
            $log{ $idob }->debug(" ... not found ");
        }
    }

}

# Associe une fonction sur value_changed du record_spinner qui appelle move avec abs: valeur lue dans l'etiquette du recordspinner
# Place
sub _set_recordspinner {
    my $self = shift;
        my $id = id $self;
    $log{ $id }->debug("set_recordspinner");

    # die unless($widgets{ $id }->{rec_spinner});
    my $coderef;
    if ( $widgets{ $id }->{rec_spinner} ) {

#	    The return type of the signal_connect() function is a tag that identifies your callback function.
#	    You may have as many callbacks per signal and per object as you need, and each will be executed in turn,
#	    in the order they were attached.
        $coderef = $widgets{ $id }->{rec_spinner}->signal_connect_after(
            value_changed => sub {
                my $pos = $widgets{ $id }->{rec_spinner}->get_text - 1;
                $log{ $id }->debug( "rs_value changed will move to " . $pos );
                $widgets{ $id }->{rec_spinner}->signal_handler_block($coderef);

                #$self->move( undef, $pos);
                if ( $self->_auto_apply && $self->has_changed ) {
                    $self->apply;
                }

                #done in _display_data
                #$self->{dman}->set_row_pos($pos);
                $self->_display_data($pos);
                $widgets{ $id }->{rec_spinner}->signal_handler_unblock($coderef);
                return TRUE;
            }
        );
        $events{ $id }->{rs_value_changed_signal} = $coderef;
        $log{ $id }->debug("recordspinner set");
    }

}

sub _set_rs_range {
    my ( $self, $first, $last ) = @_;
    my $id = id $self;
    # Convenience function that sets the min / max value of the record spinner
    $log{ $id }->debug( "set_rs_range  first : " . $first );
    if ( $widgets{ $id }->{rec_spinner} ) {
        my $ad = $widgets{ $id }->{rec_spinner}->get_adjustment;
        $log{ $id }->debug( "adj lower : " . $ad->lower );
        if ( $first < $ad->lower ) {
            $ad->lower($first);
            $widgets{ $id }->{rec_spinner}->set_adjustment($ad);
        }
        $widgets{ $id }->{rec_spinner}
          ->signal_handler_block( $events{ $id }->{rs_value_changed_signal} );
        $widgets{ $id }->{rec_spinner}->set_range( $first, $last );
        $widgets{ $id }->{rec_spinner}
          ->signal_handler_unblock( $events{ $id }->{rs_value_changed_signal} );
    }
    $widgets{ $id }->{rec_count_label}->set_text( " / " . $self->_dman->row_count );
    return TRUE;

}

sub _set_entry {
    my ( $self, $w, $x ) = @_;
        my $id = id $self;
    if ( defined $x ) {
        $log{ $id }->debug( "set_entry: " . $x );
        $w->set_text($x);
    } else {
        $log{ $id }->debug( "set_entry: text entry undef " . $w->get_name );
        $w->set_text("");
    }

}

sub _set_textentry {
    my ( $self, $w, $x ) = @_;
        my $id = id $self;
    $log{ $id }->debug("set_textentry text entry undef") if ( !defined $x );
    $w->get_buffer->set_text( $x || "" );

}

sub _set_combo {
    my ( $self, $w, $x ) = @_;
        my $id = id $self;
    $log{ $id }->debug( "set_combo value "
          . ( defined $x ? $x : " undef" )
          . " widget: "
          . ref $w );
    my $m = $w->get_model;
    my $iter = $m->get_iter_first if ($m);

    if ( ref $w eq "Gtk2::ComboBoxEntry" ) {
        $w->get_child->set_text("");
    }

    my $match_found = 0;

    while ($iter) {
        if ( ( defined $x ) && ( $x eq $m->get( $iter, 0 ) ) ) {
            $match_found = 1;
            $w->set_active_iter($iter);
            last;
        }
        $iter = $m->iter_next($iter);
    }
    if ( !$match_found && $x ) {
        $log{ $id }->debug( "Failed to set " . ref $w . " to $x\n" );
    }

}

sub _set_check {
    my ( $self, $w, $x ) = @_;
        my $id = id $self;
    $w->set_active( ( defined $x ? $x : 0 ) );
}

sub _get_combobox_firstvalue {
    my ( $self, $c ) = @_;
    my $id = id $self;
    
    #print "getter_cb\n";
    my $iter = $c->get_active_iter;
    unless ($iter) {
        $log{ $id }->debug( "iter undef row: " . $c->get_active );
    }
    return ( $iter ? $c->get_model->get( $iter, 0 ) : undef );
}

sub _set_spinbutton {
    my ( $self, $w, $x ) = @_;
        my $id = id $self;
    if ( $self->getID($w) eq $self->getID( $widgets{ $id }->{rec_spinner} ) ) {
        $log{ $id }->debug("Found record_spinner... leaving");
        return;
    }
    $w->set_value( $x || 0 );

}

sub _get_textbuffer {
    my ( $self, $w ) = @_;
        my $id = id $self;
    return $w->get_buffer;

}

sub _change_values {
    my ( $self, $fieldname ) = @_;
    my $id = id $self;
    # $log{ $id }->debug("self->changed for $fieldname");
    if ( !$self->_painting ) {
        $self->_changed(1);
        if ( $events{ $id }->{on_change} ) {
            $events{ $id }->{on_change}();
        }
        $self->_set_record_status_label;
    }
    return FALSE;

}

sub _set_record_status_label {

    my $self = shift;
    my $id = id $self;
  $log{ $id }->debug("set_record_satus_label changed is " . $self->_changed);

    if ( $widgets{ $id }->{status_label} ) {
        if ( $events{ $id }->{data_lock} ) {
            $widgets{ $id }->{status_label}
              ->set_markup("<b><i><span color='red'>Locked</span></i></b>");
        } elsif ( $self->_changed ) {

            $widgets{ $id }->{status_label}
              ->set_markup("<b><span color='red'>Changed</span></b>");

        } else {
            $widgets{ $id }->{status_label}
              ->set_markup("<b><span color='blue'>Synchronized</span></b>");
        }
    }
}

=for comment

#parameter $in_db is 0 or 1 :
# 0 we are reading from the db, and the format to use are at the pos 0 and 1 in the array of format for the field
# 1 we are writing to the db and the format are to use in a revers order
# $id is the field id
# $v the date string from the form (if in_db is 1) or from the db (if in_db is 0)
sub _format_date {
    my ( $self, $in_db, $id, $v ) = @_;
        my $id = id $self;
    $log{ $id }->debug( "format_date received date: " . $v );
    my ( $pos1, $pos2 ) = ( $in_db ? ( 1, 0 ) : ( 0, 1 ) );
    my $format = $self->{date_formatters}->{$id}->[$pos1];
    my $f      = $self->_get_dateformatter($format);
    my $dt     = $f->parse_datetime($v) or croak( $f->errmsg );
    $log{ $id }->debug( "format_date:  date time object ymd: " . $dt->ymd );
    $format = $self->{date_formatters}->{$id}->[$pos2];
    $f      = $self->_get_dateformatter($format);
    my $r = $f->format_datetime($dt) or croak( $f->errmsg );
    $log{ $id }->debug( "format_date formatted date: " . $r );

    return $r;

}
=cut
1;

__END__

=head1 NAME

Gtk2::Ex::DbLinker::Form - a module that display data from a database in glade generated Gtk2 interface

=head1 VERSION

See Version in L<Gtk2::Ex::DbLinker>

=head1 SYNOPSIS

	use Rdb::Coll::Manager;
	use Rdb::Biblio::Manager;

	use Gtk2::Ex::DbLinker::RdbDataManager;
	use Gtk2::Ex::DbLinker::Form;

	use Gtk2 -init;
	use Gtk2::GladeXML;

	 my $builder = Gtk2::Builder->new();
	 $builder->add_from_file($path_to_glade_file);
	 $builder->connect_signals($self);

This gets the Rose::DB::Object::Manager (we could have use plain sql command, or DBIx::Class object instead), and the DataManager object we pass to the form constructor.

	my $data = Rdb::Mytable::Manager->get_mytable(query => [pk_field => {eq => $value]);

	my $dman = Gtk2::Ex::DbLinker::RdbDataManager->new(data=> $data, meta => Rdb::Mytable->meta );

This create the form.

		$self->{form_coll} = Gtk2::Ex::DbLinker::Form->new(
			data_manager => $dman,
			meta => Rdb::Mytable->meta,
			builder => 	$builder,
		  	rec_spinner => $self->{dnav}->get_object('RecordSpinner'),
	    		status_label=>  $self->{dnav}->get_object('lbl_RecordStatus'),
			rec_count_label => $self->{dnav}->get_object("lbl_recordCount"),
			on_current =>  sub {on_current($self)},
			date_formatters => {
				field_id1 => ["%Y-%m-%d", "%d-%m-%Y"], 
				field_id2 => ["%Y-%m-%d", "%d-%m-%Y"], },
			time_zone => 'Europe/Zurich',
			locale => 'fr_CH',
	    );


C<rec_spinner>, C<status_label>, C<rec_count_label> are Gtk2 widget used to display the position of the current record. See one of the example 2 files in the examples folder for more details. 
C<date_formatters> receives a hash of id for the Gtk2::Entries in the Glade file (keys) and an arrays (values) of formating strings.

In this array

=over

=item *

pos 0 is the date format of the database.

=item * 

pos 1 is the format to display the date in the form. 

=back

C<time_zone> and C<locale> are needed by Date::Time::Strptime.



To display new rows on a bound subform, connect the on_change event to the field of the primary key in the main form.
In this sub, call a sub to synchonize the form:

In the main form:

    sub on_nofm_changed {
        my $widget = shift;
	my $self = shift;
	my $pk_value = $widget->get_text();
	$self->{subform_a}->synchronize_with($pk_value);
	...
	}

In the subform_a module

    sub synchronize_with {
	my ($self,$value) = @_;
	my $data = Rdb::Product::Manager->get_product(with_objects => ['seller_product'], query => ['seller_product.no_seller' => {eq => $value}]);
	$self->{subform_a}->get_data_manager->query($data);	
	$self->{subform_a}->update;
     }

=head2 Dealing with many to many relationship 

It's the sellers and products situation where a seller sells many products and a product is selled by many sellers.
One way is to have a insert statement that insert a new row in the linking table (named transaction for example) each time a new row is added in the product table.

An other way is to create a data manager for the transaction table

With DBI

	$dman = Gtk2::Ex::DbLinker::DbiDataManager->new( dbh => $self->{dbh}, sql =>{select =>"no_seller, no_product", from => "transaction", where => ""});

With Rose::DB::Object

	$data = Rdb::Transaction::Manager->get_transaction(query=> [no_seller => {eq => $current_seller }]);

	$dman = Gtk2::Ex::DbLinker::RdbDataManager->new(data => $data, meta=> Rdb::Transaction->meta);

And keep a reference of this for latter

      $self->{linking_data} = $dman;

If you want to link a new row in the table product with the current seller, create a method that is passed and array of primary key values for the current seller and the new product.

	sub update_linking_table {
	   	my ( $self, $keysref) = @_;
   		my @keys = keys %{$keysref};
		my $f =  $self->{main_form};
		my $dman = $self->{main_abo}->{linking_data};
		$dman->new_row;
		foreach my $k (@keys){
			my $value = ${$keysref}{$k};
			$dman->set_field($k, $value );
		}
		$dman->save;
	}

This method is to be called when a new row has been added to the product table:

	sub on_newproduct_applied_clicked {
		my $button = shift;
	 	my $self = shift;
    		my $main = $f->{main_form};
    		$self->{product}->apply;
		my %h;
		$h{no_seller}= $main->{no_seller};
		$h{no_product}= $self->{abo}->get_widget_value("no_product");
    		$self->update_linking_table(\%h);
	}

You may use the same method to delete a row from the linking table

	my $data = Rdb::Transaction::Manager->get_transaction(query=> [no_seller => {eq => $seller }, no_product=>{eq => $product } ] );
	$f->{linking_data}->query($data);
	$f->{linking_data}->delete;

=head1 DESCRIPTION

This module automates the process of tying data from a database to widgets on a Glade-generated form.
All that is required is that you name your widgets the same as the fields in your data source.

Steps for use:

=over

=item * 

Create a xxxDataManager object that contains the rows to display

=item * 

Create a Gtk2::GladeXML object (the form widget)

=item * 

Create a Gtk2::Ex::DbLinker::Form object that links the data and your form

=item *

You would then typically connect the buttons to the methods below to handle common actions
such as inserting, moving, deleting, etc.

=back

=head1 METHODS

=head2 constructor

The C<new();> method expects a list or a hash reference of parameters name => value pairs

=over

=item * 

C<data_manager> a instance of a xxxDataManager object

=item *

C<builder> a Gtk2::GladeXML builder


=back

The following parameters are optional:

=over

=item *

C<datawidgets> a reference to an array of id in the glade file that will display the fields

=item * 

C<rec_spinner> the name of a GtkSpinButton to use as the record spinner or a reference to this widget. The default is to use a
widget called RecordSpinner.

=item *

C<rec_count_label>  name (default to "lbl_RecordCount") or a reference to a label that indicate the position of the current row in the rowset

=item *  

C<status_label> name (default to "lbl_RecordStatus") or a reference to a label that indicate the changed or syncronized flag of the current row

=item *

C<on_current> a reference to sub that will be called when moving to a new record

=item * 

C<date_formatters> a reference to an hash of Gtk2Entries id (keys), and format strings  that follow Rose::DateTime::Util (value) to display formatted Date

=item * 

C<auto_apply> defaults to 1, meaning that apply will be called if a changed has been made in a widget before moving to another record. Set this to 0 if you don't want this feature

=back

=head2 C<add_combo_values( $widget, $array_ref); >

Populates a Gtk2::ComboBox or Gtk2::ComboBoxEntry widget with a static list of values. 
The array whose reference is stored in $array_ref is a list of array that described the rows: [[return value1, displayed value1], [...], ...]

=head2 C<add_combo( {data_manager =E<gt> $dman, 	id =E<gt> 'noed',  fields =E<gt> ["id", "nom"], ); >

Once the constructor has been called, combo designed in the glade file received their rows with this method. 
The parameter is a list of parameters name => value, or a hash reference of the same.

The paramaters are:

=over

=item * 

C<data_manager> a dataManager instance that holds  the rows of the combo

=item *

C<id> the id of the widget in the glade file

=item *

C<fields> an array reference holdings the names of fields in the combo (this parameter is needed with RdbDataManager only)

=back

=head2 C< Gtk2::Ex::DbLinker::Form->add_combo({	data_manager =E<gt> $combodata, id =E<gt> 'countryid',	builder =E<gt> $builder,   }); >

This method can also be called as a class method, when the underlying form is not bound to any table. You need to pass the Gtk2::Builder object as a supplemental parameter.


=head2 C<get_widget_value ( $widget_id );>

Returns the value of a data widget from its id

=head2 C<set_widget_value ( $widget_id, $value )>;

Sets the value of a data widget from its id

=head2 Methods applied to a row of data

=over

=item C<insert()> See L<Gtk2::Ex::DbLinker::AbForm/insert()>

=item C<delete()> See L<Gtk2::Ex::DbLinker::AbForm/delete()>

=item C<apply()> See L<Gtk2::Ex::DbLinker::AbForm/apply()>

=item C<undo()> See L<Gtk2::Ex::DbLinker::AbForm/undo()>

=item C<next()>  See L<Gtk2::Ex::DbLinker::AbForm/Moving between rows>

=item C<previous()>  See L<Gtk2::Ex::DbLinker::AbForm/Moving between rows>

=item C<first()>  See L<Gtk2::Ex::DbLinker::AbForm/Moving between rows>

=item C<last()>  See L<Gtk2::Ex::DbLinker::AbForm/Moving between rows>

=item C<add_childform( $childform )> See L<Gtk2::Ex::DbLinker::AbForm/add_childform( $childform )>

=item C<has_changed()>  See L<Gtk2::Ex::DbLinker::AbForm/has_changed()>

=back

=head1 SUPPORT

Any Gk2::Ex::DbLinker questions or problems can be posted to me (rappazf) on my gmail account.  

The current state of the source can be extract using Mercurial from
L<http://sourceforge.net/projects/gtk2-ex-dblinker/>.

=head1 AUTHOR

FranE<ccedil>ois Rappaz <rappazf@gmail.com>

=head1 COPYRIGHT

Copyright (c) 2014-2017 by F. Rappaz.  All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Gtk2::Ex::DBI>

=head1 CREDIT

Daniel Kasak, whose modules initiate this work.

=cut

1;


