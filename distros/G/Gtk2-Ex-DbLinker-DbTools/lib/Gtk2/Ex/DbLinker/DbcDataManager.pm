package Gtk2::Ex::DbLinker::DbcDataManager;
use Gtk2::Ex::DbLinker::DbTools;
our $VERSION = $Gtk2::Ex::DbLinker::DbTools::VERSION;
use strict;
use warnings;
use interface qw(Gtk2::Ex::DbLinker::AbDataManager);
# use Carp qw(carp croak confess cluck);
# use Data::Dumper;
use Try::Tiny;
use Log::Any;
use Carp qw(croak confess);
my %fieldtype = ( tinyint => 'integer', );

#$self->{rs} holds a RecordSet that is a query def of the data to fetch from the database.
#$self->{data} holds an array ref of array ref of primary key values, in most case this second array will hold one value.
#$self->{current_row} holds a ref to the current row, that comes from  $self->{rs}->find(@{ $self->{data}[$pos] });
#This is called on each set_row_pos( $new_pos ) call.
#
#set_row_pos( $pos) gets the primary key value from the array def stores in $self->{data}[ $pos]
#The row for $pos is searched using search or find for the result objet using the resultset passed by query or by the constructor
#if a row's value is changed so that this row is excluded from the resultset, it will not be found by set_row_pos.
#row_count (which is the resultset->count) will reflect this changes.

sub new {

    # my ( $class, $req ) = @_;
    my $class = shift;
    my %def   = ( page => 1 );
    my %arg   = ( ref $_[0] eq "HASH" ? ( %def, %{ $_[0] } ) : ( %def, @_ ) );
    my $self  = {
        page         => $arg{page}         || 1,
        rec_per_page => $arg{rec_per_page} || 1,
        rs           => $arg{rs},
        primary_keys => $arg{primary_keys},
        ai_primary_keys => $arg{ai_primary_keys},
        cols_types      => $arg{columns},
        '+cols_types'   => $arg{'+columns'},
        defaults        => $arg{defaults},

    };
    #$self->{log} = Log::Log4perl->get_logger(__PACKAGE__);
    $self->{log} = Log::Any->get_logger();

    bless $self, $class;
    $self->{cols}    = [];
    $self->{rocols}  = [];
    $self->{new_row} = undef;
    $self->_init;
    $self->_init_pos;

    return $self;
}

sub query {
    my ( $self, $rs ) = @_;
    $self->{rs} = $rs;
    $self->{log}->debug(
        "query "
          . (
            $self->{cols}
            ? "cols: " . join( " ", @{ $self->{cols} } )
            : " cols undef "
          )
    );

#try to initiate cols as long as it's not done (the array referer by $self->{cols} is empty)
#the line defined cols the first time a row is fetched
# print Dumper($self->{cols});
#$self->{log}->debug(Dumper $rs);
    $self->_init_pos;
    $self->_init if ( @{ $self->{cols} } == 0 );

    #return value of set_row_pos : 0 no data 1 found one or more row
    $self->set_row_pos( $self->{row}->{pos} );

    # $self->{log}->debug("query : " . @$data[0]->noti ) if (scalar @$data > 0);

=for comment
	foreach my $pkr (@{$self->{data}}){
		# print Dumper($pkr);
		foreach my $pkn (@{$self->{primary_keys}}){
			my $i = 0;
			$self->{log}->debug( "pk name: " . $pkn . " pk value : " . $$pkr[$i++] );
		}
	}
=cut

}

sub set_row_pos {
    my ( $self, $pos ) = @_;
    my $found = 1;

# $self->{log}->debug("new_row is " . ($self->{new_row} ? " defined" : " undefined"));
    if ( !defined( $self->{row}->{pos} ) ) {
        $self->{log}->debug("no data");
        $found = 0;
    } elsif ( defined $self->{row}->{last_row} && ($pos < $self->{row}->{last_row} + 1 && $pos >= 0 )) {
	    # $self->{log}->debug( "setting current row to an existing row at pos ", $pos );
        $self->{row}->{pos} = $pos;

# $self->{log}->debug("set_row at pos : " . $pos . " pk: " . join(" ", @{ $self->{data}[$pos] }) . " class: " . $self->{rs}->result_class);
#die Dumper( $self->{data}[$pos] );
        my $r;
        if ( $self->{usefind} ) {
		#$self->{log}->debug( "usefind is true rs count: " . $self->{rs}->count );

      # my $sql =  $self->{rs}->as_query;
      # $self->{log}->debug("sql  and bound values : " .  join(" * ", @$$sql) );
      #$self->{log}->debug( "searching " . join( " ", @{ $self->{data}[$pos] } ) );
            if ( $self->{rs}->count > 0 ) {
                $r = $self->{rs}->find( @{ $self->{data}[$pos] } );
            } else {
                $found = 0;
            }

            #$self->{log}->debug("cols: " . join(" ", $r->columns));
        } else {

            my %h;
            my @vals = @{ $self->{data}[$pos] };
            my $i    = 0;
            for my $key ( @{ $self->{primary_keys} } ) {
                $h{ "me." . $key } = $vals[ $i++ ];
            }
            $self->{log}->debug( "keys: " . join( " ", keys %h ) );
            $self->{log}->debug( "values: " . join( " ", values %h ) );
            my $rs = $self->{rs}->search( \%h );
            $r = $rs->single();
            $self->{log}->debug( "count (should be 1) : ", $rs->count );

        }
        if ($found) {

#croak ("Can't set current row for value(s) " . join(" " , @{ $self->{data}[$pos] }) . " at pos " . $pos ) unless (defined $r);
            $self->{current_row} = $r;
        }    # else current_row remains the same

    } elsif ( defined $self->{row}->{last_row} && $pos == $self->{row}->{last_row} + 1 ) {

        #$self->{log}->debug("setting current row to undef");
        #$self->{current_row} = undef;
        $self->{log}->debug("setting current row to new row");
        $self->{current_row} = $self->{new_row};

    }    #else { $found = 0; croak(" position outside rows limits "); }
     # $self->{log}->debug("set_row_pos current pos: " . $self->{row}->{pos} . " new pos : " . $pos . " last: " . $self->{row}->{last_row} . " count : " . scalar @{ $self->{data}} );

    return $found;

}

sub get_row_pos {
    my ($self) = @_;
    return $self->{row}->{pos};
}

sub set_field {
    my ( $self, $id, $value ) = @_;
    my $pos = $self->{row}->{pos};
    my $row;

    #if ($id ~~ @{$self->{rocols}}){
    $self->{log}
      ->debug( "set_field: rocols: " . join( " ", @{ $self->{rocols} } ) );
    if ( grep /^$id$/, @{ $self->{rocols} } ) {
        $self->{log}->debug( "set_field: "
              . $id
              . " pos: "
              . $pos
              . " skipped since this is a readonly field." );
    } else {
        $self->{log}->debug( "set_field: "
              . $id
              . " pos: "
              . $pos
              . " value : "
              . ( $value ? $value : "" ) );
        if ( $pos >= $self->row_count ) {
            $row = $self->{new_row};
        } else {

            $row = $self->{current_row};
        }
        try {
         $row->set_column( $id, $value )
     } catch {
         $self->{log}->error( "No column named " . $id . " in row" );
        
     }
          ; #or die(__PACKAGE__ . " no method found to set value " . $value . " in the column " . $id . " entries are ".  join(" ", keys %{ $self->{fieldSetter} }));
    }
}

sub get_field {
    my ( $self, $id ) = @_;

    #my $pos =  $self->{row}->{pos};
    #my $row = $self->{rs}->find(@{$self->{data}[$pos]});
    my $row = $self->{current_row};
    my $value;
    if ( !defined $row ) {
        $self->{log}->debug("current row undef because there's no row");
    } else {
        try {
            $value = $row->get_column($id);
        }
        catch {
            $self->{log}->error( "No column named " . $id . " in row" );
        }
    }
    # $self->{log}->debug( "get_field ". $id. " value: " . ( defined $value ? $value : "undef" ) );
    return $value;

}

sub save {
    my $self = shift;
    my $row;
    my $result;
    my $done;
    if ( $self->{new_row} ) {
        $self->{log}->debug(" save new row ");
        $row = $self->{new_row};

        #$row->update;
        my $new_row =  $row->insert;
        $done = ( defined $new_row ? 1 : 0 );
        #$self->{rs}->create($row->insert);
        $self->{log}->debug( " insert return " . $done );
        $self->{log}->debug("rs->count : ", $self->{rs}->count); #return 0 even insert has been called
        #with the abo-jrnabt example the where clause is noabt < 0 -> the form is empy
        #but this filter is still added with insert so the count is still 0
        #
        # $self->{row}->{last_row} +=  1; not needed if count is taken from the nuber of rows in $self->{data}
        $self->{current_row} = $new_row;
        my @pk_val;
        for my $pk ( $new_row->primary_columns ) {
            my $pkval = $new_row->get_column($pk);
            $self->{log}->debug( "pk after insert: " . $pkval );
            push @pk_val, $pkval;
        }
        if ($done) {
            $self->{new_row} = undef;
            $self->{log}->debug("saving and unsetting new row");
        }
        push @{ $self->{data} }, \@pk_val;

        #calling new_row  in Form->apply sets the cursor on the newly added row 
        #and increment the last_row by 1
        #
        
        #my $last = scalar (@{$self->{data}}) -1;
        $self->{log}->debug("row_count after saved new row: ", $self->row_count);
        #$self->{row} = {pos => $last, last_row => $last};
        # $self->set_row_pos($last);

    } else {
        $self->{log}->debug( " save at " . $self->{row}->{pos} );
        my $pos = $self->{row}->{pos};

        #$row =  $self->{rs}->find(@{$self->{data}[$pos]});
        $row = $self->{current_row};

        # $self->{log}->debug(Dumper($row));
        try {
            #$result = $row->update;
            if ( $row->update ) {

    #$self->{new_row} = undef; #si on arrive ici, c'est que new_row est undef ?!
    #$self->{log}->debug("saving and unsetting new row");
                $done = 1;
            }
        }
        catch {
            # $self->{log}->logcarp("Can't save record : $_");
            carp( $self->{log}->warn("Can't save record : $_"));
            $done = 0;
        }

    }

    #$row->save;
    #don't delete new_row is inserting in the db gets wrong
    #if ($result) {
    #	$self->{new_row} = undef;
    #}
    return $done;
}

sub new_row {
    my ($self) = @_;

    #return if ($self->{new_row});
    my $rs = $self->{rs};
    my %hash = map { $_, undef } @{ $self->{primary_keys} };

    #my %hash   = map { $_, undef } @{$self->{cols}};
    if ( $self->{defaults} ) {
        my %hd = %{ $self->{defaults} };
        foreach my $k ( keys %hd ) {
            $hash{$k} = $hd{$k};
        }

    }
    $self->{log}->debug("new_row  last_row : ", (defined $self->{row}->{last_row} ? $self->{row}->{last_row} : " undef"));

    #row->insert is done in save
    my $row = $rs->new_result( \%hash );
    $self->{new_row} = $row;
    $self->{log}->debug("new_row sets to rs->new_result rs->count is ", $self->{rs}->count);
    #rs->count is not changed until rs->insert is called
    #so row->count is wrong at this time
    #
    #
    #to insure that the new row is at last + 1:
    if ( defined $self->{row}->{last_row} ) {
        $self->{row}->{pos} = $self->{row}->{last_row} + 1;
    } else {
        $self->{row}->{pos}      = 0;
        $self->{row}->{last_row} = -1;
    }

    $self->{log}->debug(
        "new_row pos:", $self->{row}->{pos},
        " last: ",      $self->{row}->{last_row}
    );

    #$self->{log}->debug( Dumper($row));

}

sub delete {
    my $self = shift;
    $self->{log}->debug( " delete at " . $self->{row}->{pos} );
    my $pos = $self->{row}->{pos};
    if ( defined $pos ) {

        # my $row = $self->{rs}->find( @{$self->{data}[$pos]} );
        my $row = $self->{current_row};
        if ( !$row->delete ) {  
            #$self->{log}->logcroak( " can't delete row at pos " . $pos ) 
            croak($self->{log}->error( " can't delete row at pos " . $pos ));
            }

        splice @{ $self->{data} }, $pos, 1;
        if ( $self->row_count == 0 ) {
            $self->{row} = { pos => undef, last_row => undef };
        } else {
            $self->next;
            $self->{row} = { pos => $pos, last_row => $self->row_count - 1 };
        }
    }

}

sub next {
    my $self = shift;
    $self->_move(1);
}

sub previous {
    my $self = shift;
    $self->_move(-1);
}

sub last {
    my $self = shift;
    $self->_move( undef, $self->row_count() - 1 );
}

sub first {
    my $self = shift;
    $self->_move( undef, 0 );
}

sub row_count {
    my $self = shift;
    my $hr   = $self->{row};

    my $count = scalar @{$self->{data}};
    #data is updated only after a call to query
    #the resultset->count takes into account a change in the row's selection
    #but new rows added to an empty resultset (pk < 0) are not counted when rs->insert is called
    #rs->count is still 0
    #since the filter pk < 0 is still applied
    #my $count = $self->{rs}->count;
    $hr->{last_row}= $count -1;
    $self->{log}->debug( "row_count last pos : ",
           ( defined $hr->{last_row} ? $hr->{last_row} : "undefined" ),
           " count: ", $count );
    return $count;

}

sub get_field_names {
    my $self = shift;
    return @{ $self->{cols} };

}

#field type : fieldtype return by the database
#param : the field name
sub get_field_type {
    my ( $self, $id ) = @_;

    #return $fieldtype{$self->{fieldsDBType}->{$id}};
    return $self->{fieldsDBType}->{$id};

}

sub get_autoinc_primarykeys {
    my $self = shift;
    return @{ $self->{ai_primary_keys} } if ( $self->{ai_primary_keys} );
}

sub get_primarykeys {
    my $self = shift;
    return @{ $self->{primary_keys} } if ( $self->{primary_keys} );
}

sub _init_pos {
    my $self = shift;
    my $rs   = $self->{rs};
    my @data;

    my @pks = $rs->search( undef, { columns => $self->{primary_keys} } );

    for my $pk (@pks) {
        my @pkv;

        #$self->{log}->debug(join(" ", @{$self->{primary_keys}}));

        for my $pkname ( @{ $self->{primary_keys} } ) {

#$self->{log}->debug("pk name : " . $pkname . " value : " . $pk->get_column($pkname));
            push @pkv, $pk->get_column($pkname);

        }

        push @data, \@pkv;
    }
    $self->{data} = \@data;

    #$self->{data}= \@pks;
    #
    my $count = scalar @{ $self->{data} };

    if ( $count > 0 ) {

        $self->{row} = { pos => 0, last_row => $count - 1 };
    } else {
        $self->{log}->debug("_init_pos setting pos and last_row to undef");
        $self->{row} = { pos => undef, last_row => undef };
    }
}



sub _init {
    my $self  = shift;
    my $rs    = $self->{rs};
    my $table = $rs->result_source;
    $self->{class} = $rs->result_class;
    my @pk;
    if ( !defined $self->{primary_keys} ) {
        $self->{usefind}      = 1;
        @pk                   = $table->primary_columns;
        $self->{primary_keys} = \@pk;
    } else {
        $self->{usefind} = 0;
        $self->{log}->debug(
            "primary_keys defined by caller as ",
            join( " ", @{ $self->{primary_keys} } )
        );
    }
    # $self->{log}->logcroak("can't work without a pk") if ( scalar @{ $self->{primary_keys} } == 0 );
     croak( $self->{log}->error("can't work without a pk")) if ( scalar @{ $self->{primary_keys} } == 0 );
    my @apk;
    if ( !defined $self->{ai_primary_keys} ) {
        foreach my $c (@pk) {
            my $href = $table->column_info($c);
            if ( $href->{is_auto_increment} ) {
                push @apk, $c;
            }
        }
        $self->{ai_primary_keys} = \@apk;
    }
    my @cols;
    if ( !defined $self->{cols_types} ) {

        @cols = $table->columns;

        #$self->{cols} = \@cols;
        foreach my $id (@cols) {
            my $type = $table->column_info($id)->{data_type};
            $type = ( exists $fieldtype{$type} ? $fieldtype{$type} : $type );
            $self->{log}
              ->debug( "Dbc_dman_init: field " . $id . " type: " . $type );
            $self->{fieldsDBType}->{$id} = $type;
        }
        if ( defined $self->{'+cols_types'} ) {
            my %h = %{ $self->{'+cols_types'} };
            for my $col ( keys %h ) {
                push @cols, $col;
                push @{ $self->{rocols} }, $col;
                $self->{fieldsDBType}->{$col} = $h{$col};
            }
        }
    } else {
        my %h = %{ $self->{cols_types} };
        for my $col ( keys %h ) {
            push @cols, $col;
            push @{ $self->{rocols} }, $col;
            $self->{fieldsDBType}->{$col} = $h{$col};
        }

        #$self->{cols} = \@cols;
    }

    $self->{cols} = \@cols;

}


sub _move {
    my ( $self, $offset, $absolute ) = @_;
    $self->{log}->debug( "move offset: "
          . ( $offset ? $offset : "" )
          . " abs: "
          . ( defined $absolute ? $absolute : "" ) );
    if ( defined $absolute ) {
        $self->{row}->{pos} = $absolute;
    } else {
        $self->{row}->{pos} += $offset;
    }

    # Make sure we loop around the recordset if we go out of bounds.
    if ( $self->{row}->{pos} < 0 ) {
        $self->{row}->{pos} = 0;
    } elsif ( $self->{row}->{pos} > $self->row_count() - 1 ) {
        $self->{row}->{pos} = $self->row_count() - 1;
    }

    #set $self->{current_row} with the call below
    $self->set_row_pos( $self->{row}->{pos} );
    return $self->{row}->{pos};

}

1;

__END__

=pod

=head1 NAME

Gtk2::Ex::DbLinker::DbcDataManager - a module used by Form and Datasheet that get data from a database using DBIx::Class objects

=head1 VERSION

See Version in L<Gtk2::Ex::DbLinker::DbTools>

=head1 SYNOPSIS

	use Gtk2 -init;
	use Gtk2::GladeXML;
	use Gtk2::Ex:Linker::DbcDataManager; 

	my $builder = Gtk2::Builder->new();
	$builder->add_from_file($path_to_glade_file);

	use My::Schema;
	use Gtk2::Ex::DbLinker::DbcDataManager;

Instanciation of a DbcManager object is a two step process:

=over

=item *

use a ResultSet object from the table(s) you want to display

     my $rs = $self->{schema}->resultset('Jrn'); 

=item * 

Pass this object to the DbcDataManager constructor 

	 my $dbcm = Linker::DbcDataManager->new( rs => $rs );

=back

To link the data with a Gtk window, the Gtk entries id in the glade file have to be set to the names of the database fields

	  $self->{linker} = Linker::Form->new( 
		    data_manager => $dbcm,
		    builder =>  $builder,
		    rec_spinner => $self->{dnav}->get_object('RecordSpinner'),
  	    	    status_label=>  $self->{dnav}->get_object('lbl_RecordStatus'),
		    rec_count_label => $self->{dnav}->get_object("lbl_recordCount"),
	    );

To add a combo box in the form, the first field given in fields array will be used as the return value of the combo. 
noed is the Gtk2combo id in the glade file and the field's name in the table that received the combo values.

	my $dman = Gtk2::Ex::DbLinker::DbcDataManager->new(rs => $self->{schema}->resultset('Ed')->search_rs( undef, {order_by => ['nom']} )  );


	$self->{linker}->add_combo(
    	data_manager => $dman,
    	id => 'noed',
	fields => ["id", "nom"],
      );


And when all combos or datasheets are added:

      $self->{linker}->update;

To change a set of rows in a subform, use and on_changed event of the primary key in the main form and call

		$self->{subform_a}->on_pk_changed($new_primary_key_value);

In the subform a module:

	sub on_pk_changed {
		 my ($self,$value) = @_;
		# get a new ResultSet object and pass it to query
		my $rs = $self->{schema}->resultset('Table')->search_rs({FieldA=> $fieldA_value},  {order_by => 'FieldB'});
		$self->{subform_a}->get_data_manager->query($rs);
		$self->{subform_a}->update;
	}

=head1 DESCRIPTION

This module fetch data from a dabase using DBIx::Class. 



=head1 METHODS

=head2 constructor

The parameter is passed as a list of parameter name => value or as a hash reference with the parameter name as key.

The unique parameter is C<rs>.

The value for C<rs> is a DBIx::Class::ResultSet object.

		my $rs = $self->{schema}->resultset("Table")->search_rs(undef, {order_by => 'title'});

		my $dman = Gtk2::Ex::DbLinker::DbcDataManager->new({ rs => $rs});

Array references of primary key names and auto incremented primary keys may also be passed using  C<primary_keys>, C<ai_primary_keys> as hash keys. If not given the DbcDataManager uses the primary key from the Ressource object.
You have to give the primary key when you use join. For example to have a list of customer's names that have passed orders, you will define a join between the table orders and customers with

	my $href =  { join => ['ComUser'] ,
		distinct => 1 ,
		order_by => ['ComUser.name', 'ComUser.givename'],
		columns => [{id_user => 'ComUser.id_user'},{name => 'ComUser.name'},{givename => 'ComUser.givenname'}],
	};
	my $table =  $self->{schema}->resultset('Order');
	my $rs = $table->search_rs({}, $href);

ComUser and ComCred are the relationships described in the ::Result::Order package.
You will build a datamanager from the User and Order tables with

	my $dman = Gtk2::Ex::DbLinker::DbcDataManager->new({ 
		rs => $rs, 
		primary_keys => ['id_user'], 
		columns => {id_user => 'integer', name => 'varchar', givename => 'varchar'}, 
	});

The fields are taken from a call to C<$resultset->result_source> and when you join two tables this is not always the fields you are intersted in.
You may pass a C<columns> as a hash ref where the keys are the names of the fields and the values are the type (varchar, char, integer,boolean, date, serial, text, smallint, mediumint, timestamp, enum).
Likewise, C<'+columns'> with a similar hash ref will add the fields (from the join table) to those that are derived from  C<$resultset->result_source>. Use this if you are using fields from the result_source object and fields from join clause. Use C<columns> if you are interested only in fields from a join clause.
The fields selected with C<'+columns'> or with C<'columns'> are readonly: a call to set_field($field_id, $field_value) will not change any value.

=head2 C<query( $rs );>

To display an other set of rows in a form, call the query method on the datamanager instance for this form with a new DBIx::Class::ResultSet object.
Return 0 if there is no row or 1 if there are any rows found by the query.

	my $rs = $self->{schema}->resultset('Books')->search_rs({no_title => $value});
	$self->{form_a}->get_data_manager->query($rs);
	$self->{form_a}->update;

The methods belows are used by the Form module and you should not have to use them directly.


=head2 C<new_row();>

Calls new_result on the underlying recordset and insert defaults values.

=head2 C<save();>

return 1 on success or 0. Check this if you implement a locking mecanism within a Result module with DBIx::Class::OptimisticLocking:

        __PACKAGE__->load_components(qw/OptimisticLocking Core/);
        __PACKAGE__->optimistic_locking_strategy('dirty'); 

This will prevent a row from being changed by two users in the same time.

=head2 C<delete();>

Delete the current row.

=head2 C<set_row_pos( $new_pos ); >

change the current row for the row at position C<$new_pos>.

=head2 C<get_row_pos();>

Return the position of the current row, first one is 0.

=head2 C<set_field ( $field_id, $value);>

Sets $value in $field_id. undef as a value will set the field to null.

=head2 C<get_field ( $field_id );>

Return the value of a field or undef if null.

=head2 C<get_field_type ( $field_id );>

Return one of varchar, char, integer, date, serial, boolean.

=head2 C<row_count();>

Return the number of rows.

=head2 C<get_field_names();>

Return an array of the field names.

=head2 C<get_primarykeys()>;

Return an array of primary key(s) (auto incremented or not).

=head2 C<get_autoinc_primarykeys()>;

Return an array of auto incremented primary key(s) from the underlying result_source or undef.

=head1 SUPPORT

Any Gk2::Ex::DbLinker questions or problems can be posted to me (rappazf) on my gmail account. 

The current state of the source can be extract using Mercurial from
L<http://sourceforge.net/projects/gtk2-ex-dblinker-dbtools/>.

=head1 AUTHOR

FranE<ccedil>ois Rappaz <rappazf@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2017 by FranE<ccedil>ois Rappaz.  All rights reserved.  This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Gtk2::Ex::DbLinker::Forms>

L<Gtk2::Ex::DbLinker::Datasheet>

L<DBIx::Class>

=head1 CREDIT

The authors of L<DBIx::Class> !

=cut


