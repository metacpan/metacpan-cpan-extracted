package Gtk2::Ex::DbLinker::RdbDataManager;
use Gtk2::Ex::DbLinker::DbTools;
our $VERSION = $Gtk2::Ex::DbLinker::DbTools::VERSION;
use strict;
use warnings;
use interface qw(Gtk2::Ex::DbLinker::AbDataManager);
use Carp qw(confess croak carp);
use Log::Any;
# use Data::Dumper;

#$self->{data} holds an array of objects returned by the Rose::DB::Manager's descendant
#This array is access at set_row_pos( $pos ) when get_field( $id ) is called.
#It is walked by changing $pos, and any changes in the rows, even if the changes affect the selection criteria
#are not reflected in number of rows in the array.
#
sub new {
    my $class = shift;
    my %def   = ( page => 1, rec_per_page => 1 );
    my %arg   = ( ref $_[0] eq "HASH" ? ( %def, %{ $_[0] } ) : ( %def, @_ ) );
    my $self  = {
        page            => $arg{page},
        rec_per_page    => $arg{rec_per_page},
        data            => $arg{data},
        meta            => $arg{meta},
        alias           => $arg{alias},
        columns         => $arg{columns},
        '+columns'      => $arg{'+columns'},
        primary_keys    => $arg{primary_keys},
        ai_primary_keys => $arg{ai_primary_keys},
        defaults        => $arg{defaults},

    };
    #$self->{log} = Log::Log4perl->get_logger("Gtk2::Ex::DbLinker::RdbDataManager");
    $self->{log} = Log::Any->get_logger;

    $self->{rocols} = [];
    bless $self, $class;
    $self->_init_pos;
    $self->_init;
    return $self;
}

sub query {
    my ( $self, $data ) = @_;
    $self->{data} = $data;
    $self->{log}->debug(
        "query " . ( $self->{cols} ? @{ $self->{cols} } : " cols undef " ) );

#try to initiate cols as long as it's not done (the array referer by $self->{cols} is empty)
#the line defined cols the first time a row is fetched
# print Dumper($self->{cols});
    $self->_init_pos;
    $self->_init if ( @{ $self->{cols} } == 0 );
    $self->set_row_pos( $self->{row}->{pos} );

  # $self->{log}->debug("query : " . @$data[0]->noti ) if (scalar @$data > 0);
    foreach my $r ( @{ $self->{data} } ) {
        foreach my $f ( @{ $self->{cols} } ) {
            $self->{log}->debug( $f . " : " . ( $r->{$f} ? $r->{$f} : "" ) );
        }
    }
    return ( defined $self->{row}->{last_row} ? 1 : 0 );

}

sub set_row_pos {
    my ( $self, $pos ) = @_;
    my $found = 1;

# $self->{log}->debug("new_row is " . ($self->{new_row} ? " defined" : " undefined"));
    if ( !defined( $self->{row}->{pos} ) ) {
        $self->{log}->debug("RdbDataManager : not data");
        $found = 0;
    }
    elsif ( $pos <= $self->{row}->{last_row} + 1 && $pos >= 0 ) {
        $self->{row}->{pos} =
            $pos;    #if pos is last_row + 1 we are inserting a new row
                     #this row is created with new_row
                     #this row will be pushed on the row array on save
                     #and saved to the database with row->save
                     #} elsif ($pos == $self->{row}->{last_row} + 1) {
                     #	$self->{row}->{pos} =  $pos;

    }
    else {
        $found = 0;
         croak($self->{log}->error(" position outside rows limits "));
    }

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
    if ( $self->{isalias}->{$id} ) {
        $id = $self->{isalias}->{$id};
    }
    my $rel = $self->{fieldsRel}->{$id};
    $rel = ( $rel ? $rel : "" );
    my $key = $rel . $id;

    #if ($key ~~ @{$self->{rocols}}){
    if ( grep( /^$key$/, @{ $self->{rocols} } ) ) {
        $self->{log}->debug( "set_field: "
                . $id
                . " key: "
                . $key
                . " pos: "
                . $pos
                . " skipped since this is a readonly field." );
    }
    elsif ( grep( /^$key$/, @{ $self->{ai_primary_keys} } ) ) {
        $self->{log}->debug( "set_field: "
                . $id
                . " key: "
                . $key
                . " pos: "
                . $pos
                . " skipped since this is an ai primary key." );
    }
    else {
        $self->{log}->debug( "set_field: "
                . $id
                . " key: "
                . $key
                . " pos: "
                . $pos
                . " value : "
                . ( $value ? $value : "" ) );
        if ( $pos >= $self->row_count ) {
            $row = $self->{new_row};
        }
        else {
            $row = $self->{data}[$pos];
        }
        my $rel = $self->{fieldsRel}->{$key};
        my $m   = $self->{fieldSetter}->{$key};
        if ($rel) {
            $row->{$rel}->$m($value);
        }
        else {
            $row->$m($value);
        }
    }
}

sub get_field {
    my ( $self, $id ) = @_;
    my $pos = $self->{row}->{pos};
    return
        unless defined $pos
        ; #prevents cascade of errors when get_field is called on inexisting row
    my $last = $self->row_count;

    #$self->{log}->debug( "get_field: pos ", $pos, " last : ", $last );
    my $row;
    if ( $pos < $last ) {
        $row = $self->{data}[$pos];
    }
    elsif ( $pos == $last ) {
        $row = $self->{new_row};
    }
    else {
        $self->{log}->debug("current pos outside row limits");
    }
    if ( $self->{isalias}->{$id} ) {
        $id = $self->{isalias}->{$id};
    }
    my $rel = $self->{fieldsRel}->{$id};
    $rel = ( $rel ? $rel : "" );
    my $key = $rel . $id;
    my $m   = $self->{fieldGetter}->{$key};
    my $v;
    if ( defined $m ) {
        if ( length($rel) ) {
            $v = $row->{$rel}->$m();
        }
        else {
            $v = $row->$m();
        }
    }
    else {
        $self->{log}->debug( "field ", $id, " undefined" );
    }
    return $v;

}

sub save {
    my $self = shift;
    my $row;
    if ( $self->{new_row} ) {
        $self->{log}->debug( __PACKAGE__, " save new row " );
        $row = $self->{new_row};
        push @{ $self->{data} }, $row;
        my $last = $self->row_count - 1;
        $self->{row} = { pos => $last, last_row => $last };

    }
    else {
        $self->{log}->debug( __PACKAGE__, " save at " . $self->{row}->{pos} );
        my $pos = $self->{row}->{pos};
        $row = $self->{data}[$pos];
    }
    $self->{log}->debug("saving and unsetting new row");

=for comment
     my $m = $row->meta();
     my @col = $m->columns;
     $self->{log}->debug("acc ", join ( " " , $m->column_accessor_method_names));
     for my $c (@col){
 	$self->{log}->debug("name: ", $c->name, " type ", $c->type);
      }
=cut

    my $done;
    $done = $row->save or  carp($self->{log}->warn("can't save ...\n"));
    $self->{new_row} = undef;
    return $done;
}

sub new_row {
    my ($self) = @_;
    $self->{log}->debug("new_row");
    my $class = $self->{class};
    my @def   = ( %{ $self->{defaults} } ) if ( $self->{defaults} );
    my $row   = $class->new(@def);
    $self->{new_row} = $row;

    #push @{$self->{data}}, $row;
    $self->{row}->{pos} = $self->{row}->{last_row} + 1;
    $self->{log}->debug( "new_row: pos ", $self->{row}->{pos} );

}

sub delete {
    my $self = shift;
    $self->{log}
        ->debug(" delete at " . $self->{row}->{pos} );
    my $pos = $self->{row}->{pos};
    if ( defined $pos ) {    # if ($pos) is false when $pos is 0
        my $row = $self->{data}[$pos];
        if ( !$row->delete ) { croak ($self->{log}->error( " can't delete row at pos " . $pos )) }

        splice @{ $self->{data} }, $pos, 1;
        if ( $self->row_count == 0 ) {
            $self->{row} = { pos => undef, last_row => undef };
        }
        else {
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
    my $self  = shift;
    my $hr    = $self->{row};
    my $count = scalar @{ $self->{data} };

# $self->{log}->debug( "row_count last pos : ". ( $hr->{last_row} ? $hr->{last_row} : -1 ). " count: ". $count );
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
    if ( $self->{isalias}->{$id} ) {
        $id = $self->{isalias}->{$id};
    }
    my $rel = $self->{fieldsRel}->{$id};
    $rel = ( $rel ? $rel : "" );
    my $key = $rel . $id;
    return $self->{fieldsDBType}->{$key};

}

sub get_primarykeys {
    my $self = shift;
    my @pk;
    @pk = @{ $self->{primary_keys} } if ( $self->{primary_keys} );
    return @pk;

}

sub get_autoinc_primarykeys {
    my $self = shift;
    my @pk;
    @pk = @{ $self->{ai_primary_keys} } if ( $self->{ai_primary_keys} );
    return @pk;
}

sub _init_fields_access {
    my ( $self, $meta, $fldref, $relname ) = @_;
    my $aref = ( $fldref ? $fldref : $meta->column_names );
    $relname = ( $relname ? $relname : "" );
    $self->{log}
        ->debug( "init_fields_access: fields are " . join( " ", @$aref ) );
    foreach my $id (@$aref) {
        my $c = $meta->column($id);
         croak($self->{log}->error("Field $id not found in $meta->class metadata")) unless ($c);
        my $method = $c->method_name('get') || $c->method_name('get_set')
            or  croak($self->{log}->error("no get/get_set method found for $id"));
        $self->{fieldGetter}->{ $relname . $id } = $method;
        $self->{log}->debug( "get method for field "
                . $relname . " "
                . $id . " : "
                . $method );
        $method = $c->method_name('set') || $c->method_name('get_set')
            or  croak($self->{log}->error("no set/get_set method found for $id"));
        $self->{fieldSetter}->{ $relname . $id }  = $method;
        $self->{fieldsDBType}->{ $relname . $id } = $c->type;

        if ( length($relname) ) {
            $self->{fieldsRel}->{$id} = $relname;
        }
    }

}

sub _init_joined_fields {
    my ( $self, $href ) = @_;
    my %h = %{$href};
    for my $relname ( keys %h ) {
        my $aref = $h{$relname};
        my @a = map { $relname . $_ } @$aref;
        push @{ $self->{cols} }, @$aref
            ; #widget's name are given without a table's or relationship's name in the glade file
        $self->{log}->debug(
            "init_joined_fields: fields are " . join( " ", @$aref ) );
        push @{ $self->{rocols} }, @a;
        $self->{log}
            ->debug( "init_joined_fields: ro_fields are " . join( " ", @a ) );
        my $class = $self->{meta}->relationship($relname)->{class};
        $self->{log}->debug( "class: ", $class );
        my $meta = Rose::DB::Object::Metadata->for_class($class);
        $self->_init_fields_access( $meta, $aref, $relname );

    }

}

sub _init_pos {
    my $self  = shift;
    my $first = $self->{data}[0];
    if ($first) {
        my $count = scalar @{ $self->{data} };
        $self->{row} = { pos => 0, last_row => $count - 1 };
    }
    else {
        $self->{row} = { pos => undef, last_row => undef };
    }

}

sub _init {
    my $self = shift;
    my $meta = $self->{meta};
    $self->{class} = $meta->class;
    $self->{log}->debug( "Class: " . $self->{class} );
    $self->{primary_keys} = [];
    $self->{cols}         = [];
    foreach my $id ( $meta->column_names ) {
        my ( @pk, @apk );

        #push @{$self->{cols}}, $id;
        my $c = $meta->column($id);
        if ( $c->is_primary_key_member ) {
            $self->{log}->debug( "found pk " . $id );
            push @pk, $id;
            if ( $c->type eq "serial" ) {
                $self->{log}->debug( "found auto inc pk " . $id );
                push @apk, $id;
            }
        }

        # don't override user defined values
        $self->{primary_keys}    = \@pk  unless ( $self->{primary_keys} );
        $self->{ai_primary_keys} = \@apk unless ( $self->{ai_primary_keys} );
        $self->{log}
            ->debug( "Rdb_dman_init: field " . $id . " type: " . $c->type );
    }
    if ( defined $self->{alias} ) {
        my %usedfor;
        for my $field ( keys %{ $self->{alias} } ) {
            my $aliaslist = $self->{alias}->{$field};
            for my $alias ( @{$aliaslist} ) {
                $usedfor{$alias} = $field;
                push @{ $self->{cols} }, $alias;
            }
        }
        $self->{isalias} = \%usedfor;
    }
    if ( defined $self->{'+columns'} )
    { #use meta object from main table and from relationship (foreign key not treated with) for the moment

        #$self->_get_fields_access($meta, $aref);

        $self->_init_joined_fields( $self->{'+columns'} );

    }

    if ( !defined $self->{columns} ) {    #use meta object from main table

        push @{ $self->{cols} }, $meta->column_names;
        $self->_init_fields_access( $meta, undef, undef );

    }
    else
    {  #use meta object from the relationship objects, not from the main table
         #the pk field has been defined above from the meta data from the main table
        $self->_init_joined_fields( $self->{columns} );
    }
}

sub _move {
    my ( $self, $offset, $absolute ) = @_;
    $self->{log}->debug( "move offset: "
            . ( $offset ? $offset : "" )
            . " abs: "
            . ( defined $absolute ? $absolute : "" ) );
    if ( defined $absolute ) {
        $self->{row}->{pos} = $absolute;
    }
    else {
        $self->{row}->{pos} += $offset;
    }

    # Make sure we loop around the recordset if we go out of bounds.
    if ( $self->{row}->{pos} < 0 ) {
        $self->{row}->{pos} = 0;
    }
    elsif ( $self->{row}->{pos} > $self->row_count() - 1 ) {
        $self->{row}->{pos} = $self->row_count() - 1;
    }
    return $self->{row}->{pos};

}

sub get_class {
    shift->{class};
}

1;

__END__

=pod

=head1 NAME

Gtk2::Ex::DbLinker::RdbDataManager - a module that get data from a database using Rose::DB::Objects

=head1 VERSION

See Version in L<Gtk2::Ex::DbLinker::DbTools>

=head1 SYNOPSIS

	use Gtk2 -init;
	use Gtk2::GladeXML;
	use Gtk2::Ex:Linker::RdbDataManager; 
	my $builder = Gtk2::Builder->new();
	$builder->add_from_file($path_to_glade_file);

Instanciation of a RdbManager object is a two step process:

=over

=item *

use a Rose::DB::Object::Manager derived object to get a array of Rose::DB::Object derived rows. 

	 my $data = Rdb::Mytable::Manager->get_mytable(query => [ pk_field => {ge => 0}], sort_by => 'field2' );

=item * 

Pass this object to the RdbDataManager constructor with a Rose::DB::Object::Metatdata derived object

 	my $rdbm = Gtk2::Ex::DbLinker::RdbDataManager->new(data => $data,
 		meta => Rdb::Mytable->meta,
	);

=back

To link the data with a Gtk window, the Gtk entries id in the glade file have to be set to the names of the database fields

	  $self->{linker} = Gtk2::Ex::DbLinker::Form->new( 
		    data_manager => $rdbm,
		    builder =>  $builder,
		    rec_spinner => $self->{dnav}->get_object('RecordSpinner'),
  	    	    status_label=>  $self->{dnav}->get_object('lbl_RecordStatus'),
		    rec_count_label => $self->{dnav}->get_object("lbl_recordCount"),
	    );

To add a combo box in the form, the first field given in fields array will be used as the return value of the combo. 
noed is the Gtk2combo id in the glade file and the field's name in the table that received the combo values.

	my $dman = Gtk2::Ex::DbLinker::RdbDataManager->new(data => Rdb::Combodata::Manager->get_combodata(sort_by => 'name' ), meta => Rdb::Combodata->meta );

	$self->{linker}->add_combo(
    	data_manager => $dman,
    	id => 'comboid',
	fields => ["id", "name"],
      );

And when all combos or datasheets are added:

      $self->{linker}->update;

To change a set of rows in a subform, use and on_changed event of the primary key in the main form and call

		$self->{subform_a}->on_pk_changed($new_primary_key_value);

In the subform a module:

	sub on_pk_changed {
		 my ($self,$value) = @_;
		my $data =  Rdb::Mytable::Manager->get_mytable(query => [pk_field => {eq => $value}]);
		$self->{subform_a}->get_data_manager->query($data);
		$self->{subform_a}->update;


=head1 DESCRIPTION

This module fetch data from a dabase using Rose::DB::Object derived objects. 

A new instance is created using an array of objects issue by a Rose::DB::Object::Manager child and this instance is passed to a Gtk2::Ex::DbLinker::Form object or by Gtk2::Ex::DbLinker::Datasheet objet constructor.

=head1 METHODS

=head2 constructor

The parameters are passed as a list of parameters name => value, or as a hash reference with the parameters name as keys. 

Parameters are C<data>, C<meta>, C<columns> or  C<'+columns'>, C<alias>.

The value for C<data> is a reference to an array of Rose::SB::Object::Manager derived objects. The value for C<meta> is the corresponding metadata object.

		my $data = Rdb::Mytable::Manager->get_mytable(query => [pk_field => {eq => $value }]);
		my $dman = Gtk2::Ex::DbLinker::RdbDataManager->new(data=> $data, meta => Rdb::Mytable->meta );

Array references of primary key names and auto incremented primary keys may also be passed using  C<primary_keys>, C<ai_primary_keys> as hash keys. If not given the RdbDataManager uses the metadata to have these.

You may pass a C<columns> or  C<'+columns'> parameters. The value is as a hash ref where the keys are the names of the relationship and the values are an array ref holding the fields names accessed by this relationship.
Use C<+columns> if you are using fields from the main table and from joined table(s). Use C<columns> if you are interested only in fields from tables bounded by join clauses.
Use neither of them if you want to access fields from the main table only, the relationship being used to restrict the rows.
The fields selected with C<'+columns'> or with C<'columns'> are readonly: a call to set_field($field_id, $field_value) will not change any value.

C<alias> is a hash ref of field (key) and array ref (alias list). For example if my Speak.pm module define
 	__PACKAGE__->meta->setup(
	    table   => 'speaks',

	    columns => [
        	speaksid  => { type => 'serial'.not_null => 1 },
	        countryid => { type => 'integer', not_null => 1 },
        	langid    => { type => 'integer', not_null => 1 },
    	],

    		primary_key_columns => [ 'speaksid' ],
	);

Giving C<alias => {langid => [qw(langid1 langid2)]},> in the constructor will enable the RdbDataManager to return the langid value when called with C< $dman->get_field('langid1')>. It is possible to add alias directly with using C<Rose::DB::Object::Metadata> but I confess I have not found out how...

=head2 C<query( $data );>

To display an other set of rows in a form, call the query method on the datamanager instance for this form with a new array of Rose::DB::Object derived objects.
Return 0 if there is no row or 1 if there are any.

	my $data =  Rdb::Mytable::Manager->get_mytable(query => [pk_field => {eq => $value}]);
	$self->{form_a}->get_data_manager->query($data);
	$self->{form_a}->update;

=head2 C<new_row();> C<save();> C<delete();>

These methods are used by the Form module and you should not have to use them directly.

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

Return an array of autoincremented primary key(s) defined by the the 'serial' column's type or undef.

=head1 SUPPORT

Any Gk2::Ex::DbLinker questions or problems can be posted to me (rappazf) on my gmail account. 

The current state of the source can be extract using Mercurial from
L<http://sourceforge.net/projects/gtk2-ex-dblinker-dbtools/>.

=head1 AUTHOR

FranE<ccedil>ois Rappaz <rappazf@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2017 by F. Rappaz.  All rights reserved.  This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Gtk2::Ex::DbLinker::Forms>

L<Gtk2::Ex::DbLinker::Datasheet>

L<Rose::DB::Object>

=head1 CREDIT

John Siracusa and the powerfull Rose::DB::Object ORB.

=cut

