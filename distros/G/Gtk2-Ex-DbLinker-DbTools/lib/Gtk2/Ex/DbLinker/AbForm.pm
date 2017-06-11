package Gtk2::Ex::DbLinker::AbForm;
use Class::InsideOut qw(public private register id);
use Gtk2::Ex::DbLinker::DbTools;
use Scalar::Util qw(weaken);
use Log::Any;
#use Carp 'croak';
our $VERSION = $Gtk2::Ex::DbLinker::DbTools::VERSION;
=head1 NAME

Gtk2::Ex::DbLinker::AbForm - Common methods for Gtk2::Ex::DbLinker::Form and Wx::Perl::DbLinker::Wxform

=head1 SYNOPSIS

See L<Gtk2::Ex::DbLinker::Form> and L<Wx::Perl::DbLinker::Wxform>. The methods in this module are not supposed to be called directly. But they are commented here.

=cut

use strict;
use warnings;
#use Data::Dumper;
use DateTime::Format::Strptime;
use Carp qw(confess croak);

private data_manager => my %dman;
public child_class => my %child_class;
private log => my %log;
private event => my %events;
private states => my %states;
private widgets => my %widgets;

my @arg_names;

sub new {

    my $class = shift;
    my $self = \( my $scalar );
    bless $self, $class;
     register $self;
 weaken $self;
    my $id = id $self;
    my @arg   = @_;
    my $def   = {};
    my $arg_value_ref  = { ( %$def, @arg ) };

    my $arg_holder_ref = { 
        childclass=> \%child_class, 
        data_manager=> \%dman,
        datawidgets => \$widgets{ $id}->{cols},
        datawidgets_ro => \$widgets{ $id}->{datawidgets_ro},
        builder => \$widgets{ $id }->{builder}, 
        on_current => \$events{ $id }->{on_current},
        date_formatters => \$widgets{ $id }->{date_formatters},
        time_zone => \$widgets{ $id }->{time_zone},
        locale => \$widgets{ $id }->{locale},
        rec_spinner_callback => \$events{ $id }->{rec_spinner_callback},
        rec_spinner_insert_callback => \$events{ $id}->{rec_spinner_insert_callback},

    } ;

     @arg_names = keys %{$arg_holder_ref};

    for my $name (@arg_names){
        next unless defined ($arg_value_ref->{$name});

        if (ref $arg_holder_ref->{$name} eq "HASH"){
            $arg_holder_ref->{$name}->{ $id } = $arg_value_ref->{$name};
        } 
        #elsif (ref $arg_holder_ref->{$name} eq "ARRAY") {

        #} 
        else {
           ${$arg_holder_ref->{$name} } =  $arg_value_ref->{$name};
        
        }
    
    }
    #$log{ $id } = Log::Log4perl->get_logger(__PACKAGE__);
    $log{ $id } = Log::Any->get_logger();
        my @dates;

    #$self->{subform} = [];

    #my %formatters_db;
    #my %formatters_f;
    # $self->{dates_formatted} = \(keys %{$self->{date_formatters}});
    if ( !defined $widgets{ $id }->{cols} ) {
        my @col = $dman{ $id }->get_field_names;
        $widgets{ $id }->{cols} = \@col;
    }
    foreach my $v ( keys %{ $widgets{ $id }->{date_formatters} } ) {
        $log{ $id }->debug( "** " . $v . " **" );
        push @dates, $v;
    }
    $widgets{ $id }->{dates_formatted} = \@dates;
    my %hdates = map { $_ => 1 } @dates;
    $widgets{ $id }->{hdates_formatted} = \%hdates;
    $widgets{ $id }->{dates_formatters} = {};
    $states{ $id }->{inserting}        = 0;
    $widgets{ $id }->{pos2del}          = [];

    #bless $self, $class;
   return $self;
}

sub _super_args_needed {
        return @arg_names;
}

=head2 C<set_data_manager( $dman ) >

Replaces the current data manager with the one receives. The columns should not changed, but this method can be use to change the join clause. 

=cut

sub set_data_manager {
    my ( $self, $dman ) = @_;
    $dman{ id $self } = $dman;
}

=head2 C<add_childform( $childform )>

You may add any dependant form or datasheet object with this call if you want that a changed in this subform/datasheet be applied when the apply method of this form is called. 

=cut

sub add_childform {
    my ( $self, $sf ) = @_;
    my $id = id $self;
    $log{ $id }->warn(
        "add_childform : do not set auto_apply to 0 if you call this method")
      unless ( $states{ $id }->{auto_apply} );

#carp("add_childform : do not set auto_apply to 0 if you call this method")  unless ($self->{auto_apply});
    push @{ $widgets{ $id }->{subform} }, $sf;
    weaken @{ $widgets{ $id }->{subform} }[-1];


}

sub _init {
    my $self = shift;
    my $id = id $self;
    if ( defined $widgets{ $id }->{datawidgets_ro} ) {
        my %seen;
        %seen = map { $_ => $seen{$_}++ }
          ( @{ $widgets{ $id }->{cols} }, @{ $widgets{ $id }->{datawidgets_ro} } );
        my @fields_to_save = grep { $seen{$_} < 1 } keys %seen;

        #$log{ $id }->debug("cols: " . join(" ", @{$self->{cols}}));
        $log{ $id }->debug( "cols to saved: " . join( " ", @fields_to_save ) );
        $widgets{ $id }->{col2save} = \@fields_to_save;

    } else {
        $widgets{ $id }->{col2save} = $widgets{ $id }->{cols};

    }

}

sub _painting {
    my $self = shift;
    my $idob = id $self;
    $states{ $idob}->{painting} = $_[0] if (defined $_[0]);
    return  $states{ $idob}->{painting};

}

sub _changed {
    my $self = shift;
    my $idob = id $self;
    $states{ $idob}->{changed} = $_[0] if (defined $_[0]);
    return  $states{ $idob }->{changed};

}

sub _builder {
    my $self = shift;
    my $idob = id $self;
    $widgets{ $idob}->{builder} = $_[0] if (defined $_[0]);
    return  $widgets{ $idob}->{builder};

}
#this datawidgets hash has nothing to do with the argument datawidgets 
#used in new ... it just shows my lake of imagination
sub _datawidgets {
    my $self = shift;
    my $idob = id $self;
    $widgets{ $idob}->{datawidgets}->{ $_[0]} = $_[1] if (defined $_[1]);
    return  $widgets{ $idob}->{datawidgets}->{ $_[0] } if (defined $_[0]); 
    return  $widgets{ $idob}->{datawidgets};

}
sub _datawidgetsName {
    my $self = shift;
    my $idob = id $self;
    $widgets{ $idob}->{datawidgetsName}->{ $_[0] } = $_[1] if (defined $_[1]);
    return  $widgets{ $idob}->{datawidgetsName}->{ $_[0] } if (defined $_[0]); 
    return  $widgets{ $idob}->{datawidgetsName};

}

sub _cols {
    my $self = shift;
    my $id =  id $self; 
    #$log{ $id }->logconfess( __PACKAGE__ . "_cols is readonly") if (defined $_[0]);
    confess($log{ $id }->error( __PACKAGE__ . "_cols is readonly")) if (defined $_[0]);
    return  $widgets{ $id }->{cols};
}

sub _dman {
     my $self = shift;
     my $id =  id $self;
     #$log{ $id }->logconfess( __PACKAGE__ . "_dman is readonly") if (defined $_[0]);
     confess($log{ $id }->error( __PACKAGE__ . "_dman is readonly")) if (defined $_[0]);
    return  $dman{ $id };

}

sub _pos {
     my $self = shift;
    my $id =  id $self;
    # $log{ $id }->logconfess( __PACKAGE__ . "_pos is readonly") if (defined $_[0]);
    confess($log{ $id }->error( __PACKAGE__ . "_pos is readonly")) if (defined $_[0]);
    return  $states{ $id }->{pos};

}

sub _auto_apply {
     my $self = shift;
     my $id =  id $self;
     # $log{ $id }->logconfess( __PACKAGE__ . "_auto_apply is readonly") if (defined $_[0]);
     confess( $log{ $id }->error( __PACKAGE__ . "_auto_apply is readonly")) if (defined $_[0]);
    return  $states{ $id }->{auto_apply};
}

sub _display_data {
    my ( $self, $pos ) = @_;
     my $idob = id $self;
    $log{ $idob }->debug( "display_data for row at pos " . $pos );

    my $dman = $dman{ $idob };

    $states{ $idob }->{pos} = $pos;

    $dman->set_row_pos($pos) unless ( $pos < 0 );

    $states{ $idob}->{painting} = 1;

    #foreach my $id (keys %{$self->{datawidgets}}){
    foreach my $id ( @{ $widgets{ $idob }->{cols} } ) {

        my $w    = $widgets{ $idob }->{datawidgets}->{$id};
        my $name = $widgets{ $idob }->{datawidgetsName}->{$id};

#die("no name found $id") unless($name);
#if $name is not defined means that $id is in a field array but with no corresponding
#control in the gui
        next unless ($name);
        my $x;

        #my $row = $self->{data}[$pos];

        if ( $pos < 0 ) {
            $x = undef;
        } else {

            #$x = $row->$id() if ($row);
            $x = $dman->get_field($id);
            my $ref = ref $x;
            $log{ $idob }->debug( "ref: " . $ref ) if ($ref);
            if ( $ref && $ref eq "ARRAY" ) {

                # my @set = $row->$id();
                #my @set = $dman->get_field($id);
                my @set = @$x;
                $x = join( ',', @set );
                #confess("dman undef") unless ($dman{ $idob });
                $log{ $idob }->debug( "id: "
                      . $id
                      . " gtkname : "
                      . $name
                      . " ref value: "
                      . ( $x ? ref($x) : "" )
                      . " value: "
                      . ( $x ? $x : "" )
                      . " type : "
                      . $dman{ $idob }->get_field_type($id) );

            }

        }

        # $w->signal_handler_block()

        if ( defined $widgets{ $idob }->{hdates_formatted}->{$id} ) {

            #$x = $self->_dateformatter($self->{date_formatters}->{$id}, $x);
            if ( defined $x ) {

            #my $ff = $self->{dates_formatters_f}->{$id};
            #my $fdb = $self->{dates_formatters_db}->{$id};
            # $log{ $id }->debug("display_data formatted received date: ". $x);
                $x = $self->_format_date( 0, $id, $x );

            }
        }
        $log{ $idob }->debug( $name . " widget undef " ) unless ($w);

        my %setter = $child_class{ $idob }->_get_setter;
        $setter{$name}( $self, $w, $x, $id ) if ( $name && $setter{$name} );

        if ( $name eq "Wx::ListCtrl" ) {
            $widgets{ $idob }->{datawidgetsValue}->{$id} = $x;

        }
    }    #foreach
         #$self->{pos}= $pos;

    $self->_set_record_status_label;

=for comment
    my $first = ($pos < 0 ? 0 : 1);
   $self->_set_rs_range($first,  $dman{ $id }->row_count);
   my $coderef = $self->{rec_spinner_callback};
   &$coderef($self);
=cut

    $events{ $idob }->{on_current}() if ( $events{ $idob }->{on_current} );
    $states{ $idob }->{painting} = 0;
    $states{ $idob }->{changed}  = 0;

}

=head2 Methods applied to a row of data

=over

=item C<insert()>

Create an empty rows at position 0 in the record_count_label.

=cut

sub insert {
    my $self = shift;
    my $id = id $self;
    $log{ $id }->debug("insert");

    # my $row = $self->{data}[0]->new;
    $states{ $id }->{inserting} = 1;

    #$self->{pos} = $self->{count} + 1;
    #afficher des champs vides
    #$self->_display_data(-1);
    my $new_pos = $dman{ $id }->row_count;
    my $first = ( $new_pos > 0 ? 1 : 0 );

#data_manager->new_row is called when apply is cliked / but defaults value are not displayed then
    $dman{ $id }->new_row;
    $log{ $id }->debug(
        "insert : row count is : ",
        $dman{ $id }->row_count,
        " new pos is : ", $new_pos
    );

# SqlADM and DBIDM ->new_row does not change row_count (are the others DM similar ?)
    $self->_display_data($new_pos);
    $log{ $id }->debug( ref $self );
    my $coderef = $events{ $id }->{rec_spinner_insert_callback};
    &$coderef( $self, $new_pos );

=for comment
	   if ($self->{rec_spinner}){
		  #	my $last = $dman{ $id }->row_count;
		  #$self->{rec_spinner}->signal_handler_block( $self->{rs_value_changed_signal} );
	         $self->{rec_spinner}->SetRange( $first, $new_pos+1 );
		 #ne pas appler _rs_on_changed ici
        	$self->{rec_spinner}->SetValue($new_pos+1);
		#$self->{rec_spinner}->signal_handler_unblock( $self->{rs_value_changed_signal} );

    	} 
=cut

}

=item C<undo()>

Revert the row to the original state in displaying the values fetch from the database.

=cut

sub undo {
    my $self = shift;
    my $id = id $self;
    $log{ $id }->debug("undo clicked");
    $states{ $id }->{changed}   = 0;
    $states{ $id }->{inserting} = 0;
    $widgets{ $id }->{pos2del}   = [];
    $self->_display_data( $states{ $id }->{pos} );
    my $coderef = $events{ $id }->{rec_spinner_callback};
    &$coderef($self);

=for comment
	  if ($self->{rec_spinner}){


		$self->{rec_spinner}->signal_handler_block( $self->{rs_value_changed_signal} );
       		$self->{rec_spinner}->set_value($self->{pos} + 1);
		#$self->{rec_spinner}->SetValue($self->{pos} + 1);
	        $self->{rec_spinner}->signal_handler_unblock( $self->{rs_value_changed_signal} );	
	}
=cut

}

=item C<delete()>

Marks the current row to be deleted. The deletion itself will be done on apply.

=cut

sub delete {
    my $self = shift;
    my $id = id $self;
    $log{ $id }->debug( "delete at " . $dman{ $id }->get_row_pos );

    #$self->next;
    $states{ $id }->{changed} = 1;
    push @{ $widgets{ $id }->{pos2del} }, $dman{ $id }->get_row_pos;
    $self->_set_record_status_label;

}

=item C<has_changed()>  

return true if the data exposed in the current row has been modified. If autoaply=>1 has been pass to the constructor,  return true if any child form has been modified.

=cut

sub has_changed {
    my $self   = shift;
    my $id = id $self;
    my $result = $states{ $id }->{changed};
    if ( $states{ $id }->{auto_apply} ) {
        foreach my $sf ( @{ $widgets{ $id }->{subform} } ) {
            if ( $sf->has_changed ) {
                $result = 1;
                last;
            }

        }
    }
    return $result;
}

=item C<apply()>

Save a new row, save changes on an existing row, or delete the row(s) marked for deletion.

=item C<apply( [fieldname1, fieldname2 ...] )>

When inserting a new row, you can pass an array ref of fieldnames that will not be saved to the database. This is usefull to exclude composed primary keys from being saved when this has been done by saving these values directly with the DbiDM or SqlADM with C<dman->save({pk1=> value1, pk2=> value2});>. To populate the datamanager with the new data (and to have the new data correctly diplayed in the form), calls query on the Datamanager and then update on the Form. Without that you may well see the old values diplayed again despite that the database have been updated.


=back

=cut

sub apply {
    my $self = shift;
    my $id = id $self;
    my $pkref = ( defined $_[0] ? $_[0] : undef );
    my $row;
    my $done = 1;    # by default, changes are done
                     #we are adding a new record if $pos < 0
    $log{ $id }->debug( "apply: pos : " . $states{ $id }->{pos} );
    if ( $states{ $id }->{pos} < 0 ) {
        $log{ $id }->debug("New row");
    }

    # deleting a (or some) record
    for my $p ( @{ $widgets{ $id }->{pos2del} } ) {
        $dman{ $id }->set_row_pos($p);
        $dman{ $id }->delete;
    }

    #$self->_dman_update_rows($self->{pos2del}) unless ($arg{form_only});

    $log{ $id }->debug( "items in pos2del: " . scalar @{ $widgets{ $id }->{pos2del} } );
    if ( scalar @{ $widgets{$id}->{pos2del} } ) {
        $widgets{ $id }->{pos2del} = [];
        $states{ $id }->{changed} = 0;
        my $last = $dman{ $id }->row_count;

        # $self->set_record_status_label;
        if ( $last > 0 ) {

            #$self->{rec_spinner}->set_value(1) if ($self->{rec_spinner});
            $self->_display_data(0);
        } else {
            $self->_display_data(-1);
        }
        return;
    }

    # return value: number of fields updated - don't save if there are none
    my $count = $self->_update_fields($pkref);
    $log{ $id }->debug( "count updated ", $count );
    if ($count) {
        $log{ $id }->debug("dman->save");
        $done = $dman{ $id }->save;
    }

    #fetch the value of the autoinc pk to pass them on after insert.
    my %pk_val;
    my @pk = $dman{ $id }->get_autoinc_primarykeys;

    for my $pk (@pk) {
        $log{ $id }->debug( "Primary Key: " . $pk );
        my $value = $dman{ $id }->get_field($pk);
        $pk_val{$pk} = $value;
    }

    #push @pk_val, $id

    if ( $done && $events{ $id }->{after_insert} ) {
        my $coderef = $events{ $id }->{after_insert};
        &$coderef( undef, \%pk_val );
    }

    #if ($done && $self->{pos}<0){
    if ( $done && $states{ $id}->{inserting} ) {
        my $last = $dman{ $id }->row_count - 1;
        $last = ( $last < 0 ? 0 : $last );
        $log{ $id }->debug( "last is " . $last );
        $self->_display_data($last);
        $states{ $id }->{inserting} = 0;

        # $self->{rec_spinner_callback}->(); fait dans diplay_data

=for comment
		 if ($self->{rec_spinner}){
		  #	my $last = $dman{ $id }->row_count;
			$self->{rec_spinner}->signal_handler_block( $self->{rs_value_changed_signal} );
        		$self->{rec_spinner}->set_value($last+1);
	        	$self->{rec_spinner}->signal_handler_unblock( $self->{rs_value_changed_signal} );
    		}
=cut

    }
    if ($done) {
        $states{ $id }->{changed} = 0;
        $self->_save_subforms;

        $self->_set_record_status_label;
    }
    return $done;
}

sub _update_fields {
    my $self = shift;
    my $id = id $self;
    my @pk =
      ( defined $_[0] ? @{ $_[0] } : $dman{ $id }->get_autoinc_primarykeys );

#updating a new or an existing record
#foreach widget in the form, get the value from the widget and place it in the field unless it's a primary key
#with an autogenerated value
    $log{$id}->debug("_update_fields \@pk : ", join(" ", @pk), " col2save: ",  join(" ", @{ $widgets{ $id }->{col2save} }));
    my $count_updated = 0;
    foreach my $idcol ( @{ $widgets{ $id }->{col2save} } ) {

# {datawidgets}: href to $widget object - different from the datawidgets param in the constructor
        $log{ $id }->debug( "updating field ", $idcol );
        if ( exists $widgets{ $id }->{datawidgets}->{$idcol} ) {

            #@pk = $dman{ $id }->get_autoinc_primarykeys;

            #if ($id ~~ @pk)  {
            if ( grep /^$idcol$/, @pk ) {
                $log{ $id }->debug( $idcol, " not done because it's a pk" );
            } else {
                my $w = $widgets{ $id }->{datawidgets}->{$idcol};
                $log{ $id }->debug( $widgets{ $id }->{datawidgetsName}->{$idcol} );
                my %getter  = $child_class{ $id }->_get_getter;
                my $coderef = $getter{ $widgets{ $id }->{datawidgetsName}->{$idcol} };
                #$log{ $id }->debug(Dumper $coderef);
                #$idcol only used by Wxform
                my $v = &$coderef( $self, $w, $idcol );
                $log{ $id }->debug(
                    "_update_fields id: $idcol value: " . ( $v ? $v : "" ) );
                $v = ( $v eq "" ? undef : $v );
                $log{ $id }->debug( $idcol . ": value undef" )
                  unless ( defined $v );

                # if ( defined $v && ( $id ~~ @{$self->{dates_formatted}})){
                if ( defined $v && defined $widgets{ $id }->{hdates_formatted}->{$idcol} ) {

                    #my $ff = $self->{dates_formatters_f}->{$id};

                    #my $date = $ff->parse_datetime($v);
                    $v = $self->_format_date( 1, $idcol, $v );

             # $v = $self->{dates_formatters_db}->{$id}->format_datetime($date);
             #$v = $self->dateformatter('%Y-%m-%d', $date);
                }

                if ( $states{$id }->{pos} < -1 ) {
                    $log{ $id }->debug(
                        "current row pos: " . $dman{ $id }->get_row_pos );
                }
                $count_updated++;
                $dman{ $id }->set_field( $idcol, $v );
                $log{ $id }->debug("done");
            }    # not in @pk
        }    # if exists
        else {
            $log{ $id }->debug( $idcol . " not in data" );
        }
    }    #foreach

    return $count_updated;
}

=head2 Moving between rows

=over

=item C<next>

=item C<previous>

=item C<first>

=item C<last>

=back

=cut

sub next {
    my $self = shift;
    my $id = id $self;
    if ( $states{ $id }->{auto_apply} && $self->has_changed ) { $self->apply; }
    $self->_display_data( $dman{ $id }->next );
}

sub previous {
    my $self = shift;
    my $id = id $self;
    if ( $states{ $id }->{auto_apply} && $self->has_changed ) { $self->apply; }
    $self->_display_data( $dman{ $id }->previous );
}

sub first {
    my $self = shift;
    my $id = id $self;
    if ( $states{ $id}->{auto_apply} && $self->has_changed ) { $self->apply; }
    $self->_display_data( $dman{ $id }->first );
}

sub last {
    my $self = shift;
    my $id = id $self;
    if ( $states{ $id }->{auto_apply} && $self->has_changed ) { $self->apply; }
    $self->_display_data( $dman{ $id }->last );
}

sub _save_subforms {
    my ($self) = @_;
    my $id = id $self;
    return unless ( $states{$id }->{auto_apply} );
    foreach my $sf ( @{ $widgets{ $id }->{subform} } ) {
        $sf->apply if ( $sf->has_changed );
    }

}

sub set_widget_value {
    my ( $self, $wid, $x ) = @_;
    my $id = id $self;
    $log{ $id }->debug(
        "set_widget_value: " . $wid . " to " . ( defined $x ? $x : "null" ) );
    my $w = $widgets{ $id }->{builder}->get_object($wid);
    if ($w) {

        my %setter  = $child_class{ $id }->_get_setter;
        my $coderef = $setter{ $widgets{ $id }->{datawidgetsName}->{$wid} };

        #$wid used only by wxform
        &$coderef( $self, $w, $x, $wid );
    }

}

sub get_widget_value {
    my ( $self, $wid ) = @_;
    my $id = id $self;
    my $x;
    $log{ $id }->debug( "get_widget_value: " . $wid );
    my $w = $widgets{ $id }->{builder}->get_object($wid);
    $log{ $id }->debug("no widget found") unless ($w);
    if ( $w && $widgets{ $id }->{datawidgetsName} ) {
        my %getter  = $child_class{ $id }->_get_getter;
        my $coderef = $getter{ $widgets{ $id }->{datawidgetsName}->{$wid} };
        $x = &$coderef( $self, $w, $wid );
    }
    $log{ $id }->debug( "found: " . ( $x ? $x : " undef" ) );
    return ( $x ? $x : "" );
}

=head2 C<update()>

Reflect in the user interface the changes made after the data manager has been queried, or on the form creation

=cut

sub update {
    my ($self) = @_;
    my $id = id $self;
    my @col = $dman{ $id }->get_field_names;
    $log{ $id }->debug(
        "update cols are " . ( @col ? join( " ", @col ) : " cols undef " ) );
    my $pos;
    if ( $dman{ $id }->row_count > 0 ) {

        #$self->{rec_spinner}->set_value(1) if ($self->{rec_spinner});
        $pos = 0;

    } else {
        $pos = -1;
    }
    $self->_display_data($pos);
    my $first = ( $pos < 0 ? 0 : 1 );
    $self->_set_rs_range( $first, $dman{ $id }->row_count );
    my $coderef = $events{ $id }->{rec_spinner_callback};
    &$coderef($self);
}

#parameter $in_db is 0 or 1 :
# 0 we are reading from the db, and the format to use are at the pos 0 and 1 in the array of format for the field
# 1 we are writing to the db and the format are to use in a revers order
# $id is the field id
# $v the date string from the form (if in_db is 1) or from the db (if in_db is 0)
sub _format_date {
    my ( $self, $in_db, $idcol, $v ) = @_;
    my $id = id $self;
    $log{ $id }->debug( "format_date received date: " . $v );
    my ( $pos1, $pos2 ) = ( $in_db ? ( 1, 0 ) : ( 0, 1 ) );
    my $format = $widgets{ $id }->{date_formatters}->{$idcol}->[$pos1];
    my $f      = $self->_get_dateformatter($format);
    #my $dt     = $f->parse_datetime($v) or $log{ $id }->logcroak( $f->errmsg );
    my $dt     = $f->parse_datetime($v) or croak($log{ $id }->error( $f->errmsg ));
    $log{ $id }->debug( "format_date:  date time object ymd: " . $dt->ymd );
    $format = $widgets{ $id }->{date_formatters}->{$idcol}->[$pos2];
    $f      = $self->_get_dateformatter($format);
    # my $r = $f->format_datetime($dt) or $log{ $id }->logcroak( $f->errmsg );
     my $r = $f->format_datetime($dt) or croak($log{ $id }->error( $f->errmsg ));
    $log{ $id }->debug( "format_date formatted date: " . $r );

    return $r;

}

# create a formatter if none is found in the hash for the corresponding formatting string and store it for later use, and return it or
# return an existing formatter
sub _get_dateformatter {
    my ( $self, $format ) = @_;
    my $id = id $self;
    my %hf = %{ $widgets{ $id }->{dates_formatters} };
    my $f;
    if ( exists $hf{$format} ) {
        $log{ $id }->debug(
            "get_dateformatter : return an existing formatter for " . $format );
        $f = $hf{$format};
    } else {
        $log{ $id }
          ->debug( "get_dateformatter: new formatter for " . $format );
        $f = new DateTime::Format::Strptime(
            pattern   => $format,
            locale    => $widgets{ $id }->{locale},
            time_zone => $widgets{$id }->{time_zone},
            on_error  => 'undef',
        );
        $hf{$format} = $f;

    }
    $widgets{ $id }->{dates_formatters} = \%hf;
    return $f;
}

=head2 C<get_data_manager>

Returns the data manager to be queried

=cut

sub get_data_manager {
    return $dman{ id shift};
}

1;
__END__

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

L<Gtk2::Ex::DbLinker> L<Wx::Perl::DbLinker>.

=cut

