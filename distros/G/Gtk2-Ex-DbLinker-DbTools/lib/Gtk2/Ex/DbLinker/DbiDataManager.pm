package Gtk2::Ex::DbLinker::DbiDataManager;
use Gtk2::Ex::DbLinker::DbTools;
our $VERSION = $Gtk2::Ex::DbLinker::DbTools::VERSION;
use strict;
use warnings;
use interface qw(Gtk2::Ex::DbLinker::AbDataManager);
# use Carp qw(carp croak confess cluck);
# use Data::Dumper;
use Try::Tiny;
use parent qw(Gtk2::Ex::DbLinker::Recordset);

#my %fieldtype = (tinyint => "integer", "int" => "integer");

sub new {

    #my ( $class, $req ) = @_;
    my $class = shift;
    my %def   = ();
    my %arg   = ( ref $_[0] eq "HASH" ? ( %def, %{ $_[0] } ) : ( %def, @_ ) );

    my $self = $class->SUPER::new( batch_size => $arg{aperture} );
    $self->{dbh}          = $arg{dbh};            # A database handle
    $self->{primary_keys} = $arg{primary_keys};   # An array ref of primary keys
    $self->{sql}          = $arg{sql};            # A hash of SQL related stuff
    $self->{before_query} = $arg{before_query};
    $self->{defaults}     = $arg{defaults};
    $self->{ro_fields} =
      $arg{ro_fields};    #fields from join tables that are not updatable

# an array of auto incremented primary keys
# and I want to test if it has been set to undef to forcibly set auto_imcrementing to 0
    $self->{ai_primary_key} = $arg{ai_primary_key}
      if ( exists( $arg{ai_primary_key} ) );

    # bless $self, $class;

    $self->{log} = Log::Log4perl->get_logger(__PACKAGE__);

    # $self->{log}->debug("args\n", Dumper(%arg));

    $self->{auto_incrementing} = ( defined( $self->{ai_primary_key} ) ? 1 : 0 );
     $self->{log}->logconfess(
        __PACKAGE__ . ": use ai_primary_key or primary_keys but not both..." )
      if ( defined $self->{ai_primary_key} && defined $self->{primary_keys} );

    $self->{primary_keys} = $self->{ai_primary_key}
      if ( defined $self->{ai_primary_key} );

    if ( !$self->{dbh} ) {
         $self->{log}->logconfess( __PACKAGE__ . ": constructor missing a dbh!\n" );
    }

    if ( $self->{sql}->{select_distinct} ) {
        $self->{sql}->{select} = $arg{sql}->{select_distinct};
        $self->{sql}->{head}   = "select distinct ";

    } else {
        $self->{sql}->{head} = "select ";
        $self->{sql}->{select} = "*" unless exists $self->{sql}->{select};
    }

    if ( $self->{sql} ) {
        if ( exists $self->{sql}->{pass_through} ) {
            $self->{read_only} = 1;
        } elsif ( !( exists $self->{sql}->{from} ) ) {
             $self->{log}->logconfess(__PACKAGE__
                  . " constructor missing a complete sql definition!\n"
                  . "You either need to specify a pass_through key ( 'pass_through' )\n"
                  . "or a 'from' key\n" );
        }
    }

    $self->{server} = $self->{dbh}->get_info(17);
    $self->{log}
      ->debug( "server : " . ( $self->{server} ? $self->{server} : "UNDEF" ) );

    # Some PostGreSQL stuff - DLB
    if ( $self->{server} && $self->{server} =~ /postgres/i ) {
        if ( !$self->{search_path} ) {
            if ( $self->{schema} ) {
                $self->{search_path} = $self->{schema} . ",public";
            } else {
                $self->{search_path} = "public";
            }
        }

        try {
            my $sth = $self->{dbh}
              ->prepare( "SET search_path to " . $self->{search_path} );
            $sth->execute;
        }
        catch {
             $self->{log}->logcroak( $self->{dbh}->errstr);
        };
    }

# If we're using a wildcard SQL select or a pass-through, then we use the fieldlist from an empty recordset
# to construct the widgets hash

    my $sth;

    try {
        if ( exists $self->{sql}->{pass_through} ) {
            $sth = $self->{dbh}->prepare( $self->{sql}->{pass_through} );

        } else {
            $sth =
              $self->{dbh}->prepare( $self->{sql}->{head}
                  . $self->{sql}->{select}
                  . " from "
                  . $self->{sql}->{from}
                  . " where 0=1" );

        }
    }
    catch {

         $self->{log}->logconfess($self->{dbh}->errstr);
    };

    try {
        $sth->execute;
    }
    catch {
         $self->{log}->logconfess($self->{dbh}->errstr);

    };

    $self->_use_sth_info($sth);

    $sth->finish;
    my @pks = $self->get_primarykeys;
    my $no_pk = ( scalar @pks == 0 ? 1 : 0 );
    if ( $self->{sql}->{from} && $no_pk ) {
        $self->_init_pks;

    }
    if ( $self->{sql}->{from} ) {
        $self->{log}->debug( "(possibly auto incrementing) primary key: ",
            join( " ", @pks ) );
        $self->{log}
          ->debug( "auto_incrementing: " . $self->{auto_incrementing} );
    }
    if ( $self->{sql}->{where} ) {
        my %w;
        $w{where} = $self->{sql}->{where};
        if ( $self->{sql}->{bind_values} ) {
            $w{bind_values} = $self->{sql}->{bind_values};
        }
        # $self->{log}->debug( Dumper %w );
        $self->query( \%w );
    } elsif ( $self->{sql}->{pass_through} ) {
        $self->query();
    }

    return $self;

}    #new

#query builds an array ref of complete rows if pass_through is given without any table names
#or it builds an array ref of primary keys values, then set_row_pos() must be called to retrieve 1 or n (= aperture) rows
#query is called by the constructor if a where clause or if pass_through as  have been setted
#query is called as a method on an existing datamanager to change the rows
sub query {

    #my ( $self,  $where_object ) = @_;
    my $self = shift;
    my %h;
    my $where;

    # if ( defined $_[0] ) {
    $where =
      ( ref $_[0] eq "HASH" )
      ? $_[0]
      : ( defined $_[0] ? ( %h = (@_) ) && \%h : {} );

    #} else {
    #	$where = {};
    #}
    # $self->{log}->debug( "query " . Dumper($where) );

# $self->{log}->debug("inserting is " . (defined $self->{inserting} && $self->{inserting} ? " true " : " false or undef"));
    if ( $where->{where} ) {
        $self->{sql}->{where} = $where->{where};
    }

    if ( $where->{bind_values} ) {
        $self->{log}->debug( "bind_values received",
            join( " ", @{ $where->{bind_values} } ) );
        $self->{sql}->{bind_values} = $where->{bind_values};
    } else {

        #added 2016-08 because call like "where 1=1"
        #did not work if the DM stored bin_values
        $self->{sql}->{bind_values} = undef;
    }

    # Execute any before_query code
    if ( $self->{before_query} ) {
        $self->{before_query}();
    }

    if ( !exists $self->{sql}->{from} && exists $self->{sql}->{pass_through} ) {
        my $rec;
        try {
            $rec =
              $self->{dbh}->selectall_arrayref( $self->{sql}->{pass_through},
                { Slice => {} } );
        }
        catch {
             $self->{log}->logconfess( $self->{dbh}->errstr);

        };
        $self->rs_init( $rec, undef );
        $self->{sql_dump} = $self->{sql}->{pass_through};
        return scalar @$rec;

    } else {

        # $self->{keyset_group} = undef;
        #$self->{slice_position} = undef;

        # Get an array of primary keys
        my $sth;

        my $local_sql;
        my @pks = $self->get_primarykeys();
	#$self->{log}->debug( "pks: " . join( ", ", @pks ) );
	#$self->{log}->debug( "select: " . $self->{sql}->{select} );

        #if (  @{$self->{primary_keys}} = 0)
        $local_sql =
            $self->{sql}->{head}
          . join( ", ", @pks )
          . " from "
          . $self->{sql}->{from};

        if ( $self->{sql}->{where} ) {
            $local_sql .= " where " . $self->{sql}->{where};
        }

        # Add order by clause of defined
        if ( $self->{sql}->{order_by} ) {
            $local_sql .= " order by " . $self->{sql}->{order_by};
        }
        $self->{log}->debug( "local_sql " . $local_sql );
        $self->{sql_dump} = $local_sql;
        try {
            $sth = $self->{dbh}->prepare($local_sql);

        }
        catch {
             $self->{log}->logcroak( $self->{dbh}->errstr . " " . $local_sql);
        };

#die $local_sql;
#$self->{log}->debug("bind values received in the sub :\n" . Dumper( $where->{bind_values}));
        # $self->{log}->debug( "bind values stored in the DM :\n" . Dumper( $self->{sql}->{bind_values} ) );

        try {
            if ( $self->{sql}->{bind_values} ) {
                $sth->execute( @{ $self->{sql}->{bind_values} } );
            } else {
                $sth->execute;
            }

        }
        catch {
             $self->{log}->logconfess( $self->{dbh}->errstr . " " . $local_sql);
        };

        # $self->{log}->debug("DBI_dman_query sql: $local_sql");

        my @all_pk_vals;

#each elements of the array is a string with the value(s) of the primary key(s) for record 1 to x
        while ( my @row = $sth->fetchrow_array ) {
            my $key_no = 0;
            my @key_vals;
            foreach my $primary_key (@pks) {

 #$self->{log}->debug("query : " . $primary_key . " value : " . $row[$key_no] );
                push @key_vals, $row[$key_no];
                $key_no++;
            }

            push @all_pk_vals, \@key_vals if (@key_vals);

        }

        #$self->{log}->debug("all_pk_values: ", Dumper (@all_pk_vals));
        $self->rs_init( \@all_pk_vals, \@pks );

      #$self->{keyset_size}
      #for my $v ( @{$self->{keyset}} ) { $self->{log}->debug("value : " . $v);}

        $sth->finish;

        #$self->_move( 0, 0 );
        return scalar @all_pk_vals;
    }    #else

}

#Get the rows from the database using the primary key values
#
sub _get_rows_from_batch {
    my ( $self, @all_pk_vals ) = @_;

#$self->{log}->debug("original select parameters : \n", Dumper($self->{select_param}));
#delete the original where clauses and build new one using the pk
    my $pk_order = 0;
    my @pks      = $self->get_primarykeys();

    my $key_list;

    # Assemble query
    my $local_sql = $self->{sql}->{head} . $self->{sql}->{select};

# Do we have an SQL wildcard ( * or % ) in the select string?
# the 3 lines below blow up when the primary keys are included in the select value
    if ( $self->{sql}->{select} !~ /[\*|%]/ ) {

# No? In that case, check we have the primary keys; append them if we don't - we need them
# $local_sql .= ", " . join( ', ', @{$self->{primary_keys}} );
    }
    $local_sql .=
        " from "
      . $self->{sql}->{from}
      . " where ( "
      . join( ', ', @pks )
      . " ) in ";
    #
    # The where clause we're trying to build should look like:
    #
    # where ( key_1, key_2, key_3 ) in
    # (
    #    ( 1, 5, 8 ),
    #    ( 2, 4, 9 )
    # )
    # ... etc ... assuming we have a primary key spanning 3 columns
    #

#$self->{log}->debug("get_rows_from_batch pk values received: ", Dumper(@all_pk_vals));

    my $pk_vals = $all_pk_vals[$pk_order];
    my $last    = scalar @$pk_vals;
    my %rows;
    for my $pk (@pks) {
        for ( my $i = 0 ; $i < $last ; $i++ ) {
            my $val = $pk_vals->[$i];
            $val =
              $val ^ $val
              ? "'" . $val . "'"
              : $val;    #enclose $val between ' if $val is non numeric
            $rows{$i} .= $val . ", ";

            #$self->{log}->debug("row:", $i, " : ", $rows{$i});
        }
        $pk_order++;
        $pk_vals = $all_pk_vals[$pk_order];

    }    #for
         #die Dumper(%rows);
         #$str = substr( $str, 0, -2);
    my $str;
    for my $row ( keys %rows ) {
        $str .= "(" . substr( $rows{$row}, 0, -2 ) . "), ";
    }
    $local_sql .= "(" . substr( $str, 0, -2 ) . ")";

    if ( $self->{sql}->{order_by} ) {
        $local_sql .= " order by " . $self->{sql}->{order_by};
    }

    #$self->{log}->debug($local_sql);

    my $data;
    try {
        $data = $self->{dbh}->selectall_arrayref( $local_sql, { Slice => {} } );
    }
    catch {
         $self->{log}->logconfess( $self->{dbh}->errstr . " Local SQL was:\n$local_sql");
    };
    return $data;

}

sub save {

    #	my ($self,  $href) = @_;
    my $self = shift;
    my %h;
    my $href = ( ref $_[0] eq "HASH" ? $_[0] : ( %h = (@_) ) && \%h );
    my @fieldlist   = ();
    my @bind_values = ();

#$href is used to change a field's value when the field is included in a composed primary keys.
#The array @pk holds the field's name of the primary keys since ->get_primarykeys return these fields even if auto_incrementing is 0
#The if test in the foreach loop fails and the values of the primary key fields are not added in the bind_values array therefore.
#The old values are then used to select the row when the field has to be changed.
#
#When $href is undef, save is used to insert or changed a non primary keys field, the primary key value comes from the database.
#@pk holds the auto incremented primary key names (auto_incrementing is) or is undef.
#
    my @pk;
    if ($href) {
        for my $k ( keys %$href ) {
            $self->{log}->debug(
                "push on bind_values " . $href->{$k} . " from field " . $k );
            push @bind_values, $href->{$k};
            push @fieldlist,   $k;
        }
        @pk = $self->get_primarykeys;
    } else {
        @pk = $self->get_autoinc_primarykeys;
    }

# my $placeholders; never used! # We need to append to the placeholders while we're looping through fields, so we know how many fields we actually have
    $self->{log}->debug( "pk: " . join( " ", @pk ) );
    $self->{log}
      ->debug( "primary_keys: " . join( " ", @{ $self->{primary_keys} } ) );

    my $done = 1;

    foreach my $fieldname ( @{ $self->{cols} } ) {

        $self->{log}->debug( "Processing field " . $fieldname );

        if ( grep ( /^$fieldname$/, @pk ) ) {
            $self->{log}->debug("jumping $fieldname because it's a pk");
            next;
        }

        if ( grep ( /^$fieldname$/, @{ $self->{ro_fields} } ) ) {
            $self->{log}->debug("jumping $fieldname because it's readonly");
            next;

        }

#if ( defined $widget && ref $widget ne "Gtk2::Label" ) { # Labels are read-only
        push @fieldlist, $fieldname;
        my $v = $self->get_field($fieldname);
        $self->{log}->debug( "push on bind_values "
              . $fieldname . " : "
              . "'" . ( defined $v ? $v : " undef" ) . "'" );
        push @bind_values, $self->get_field($fieldname);

        #}

    }

    my $update_sql;
    my ($table) = split( /\s+/, $self->{sql}->{from}, 2 );
    if ( $self->{inserting} ) {

#$update_sql = "insert into " . $self->{sql}->{from} . " ( " . join( ",", @fieldlist, ) . " )" . " values ( " . "?," x ( @fieldlist - 1 ) . "? )";
        $update_sql =
            "insert into "
          . $table . " ( "
          . join( ",", @fieldlist, ) . " )"
          . " values ( "
          . "?," x ( @fieldlist - 1 ) . "? )";
        $self->{log}->debug("inserting ");
    } else {
        $self->{log}->debug("updating ");

# $update_sql = "update " . $self->{sql}->{from} . " set " . join( "=?, ", @fieldlist ) . "=? where " . join( "=? and ", @{$self->{primary_keys}} ) . "=?";
# changed 01.2016: take the first word of the from value to get the table name
# with the whole from string, problems arise when field names are identical in tables used in the join syntax
# if problems occurs when more then one tables are updated, a new from_update parameters will have to be specified

        $update_sql =
            "update "
          . $table . " set "
          . join( "=?, ", @fieldlist )
          . "=? where "
          . join( "=? and ", @pk ) . "=?";

        #foreach my $primary_key ( @{$self->{primary_keys}} ) {
        foreach my $primary_key (@pk) {
            $self->{log}->debug( "push on bind_values "
                  . $primary_key . " : "
                  . $self->get_field($primary_key) );
            push @bind_values, $self->get_field($primary_key);
        }

    }

    $self->{log}->debug( "Final SQL:  " . $update_sql );
    my $i = 1;
    $self->{log}->debug(
        "Bind value: "
          . join( " ",
            map { $i++ . ": " . ( defined $_ ? $_ : "" ) } @bind_values )
    );
    my $sth;
    try {
        $sth = $self->{dbh}->prepare($update_sql);

    }
    catch {  $self->{log}->logconfess( $self->{dbh}->errstr) ; };

    try {
        $sth->execute(@bind_values);
    }
    catch {
        $self->{log}->debug( $self->{dbh}->errstr );
        $done = 0;
    };
    $sth->finish;
    if ( $done && $self->{auto_incrementing} && $self->{inserting} ) {
        my $new_key = $self->_last_insert_id;
        $done = ( defined $new_key ? 1 : 0 );
        my $primary_key = $pk[0];
        $self->set_field( $primary_key, $new_key );

        my @keys;

        foreach my $primary_key ( @{ $self->{primary_keys} } ) {
            my $value = $self->get_field($primary_key);
            $self->{log}->debug( "pk : "
                  . $primary_key
                  . " value: "
                  . ( $value ? $value : " undef" ) );
            push @keys, $value;
        }
        $self->add_pkvalues( \@keys );
        $self->{log}->debug( join( ", ", @keys ) . " added to keyset" );
        if ($done) {
            $self->{inserting} = 0;
            $self->{log}->debug("turn off inserting flag");
        }
    }
    return $done;
}    #save

sub delete {

    my $self = shift;
    my @pks  = $self->get_primarykeys;

    $self->{log}->debug( "delete pk_name is " . join( " ", @pks ) );

    my $delete_sql =
        "delete from "
      . $self->{sql}->{from}
      . " where "
      . join( "=? and ", @pks ) . "=?";
    $self->{log}->debug( "delete : " . $delete_sql );
    my @bind_values = ();
    foreach my $primary_key (@pks) {
        push @bind_values, $self->get_field($primary_key);
    }
    $self->{log}->debug( "delete values: " . join( " ", @bind_values ) );
    my $sth = $self->{dbh}->prepare($delete_sql);
    try {
        $sth->execute(@bind_values);

    }
    catch {
        $self->{log}->debug( $self->{dbh}->errstr );
        return 0;

    };
    $sth->finish;

    $self->delete_keys_values( $self->get_row_pos );
    return 1;
}

1;

__END__

=pod

=head1 NAME

Gtk2::Ex::DbLinker::DbiDataManager - a module that get data from a database using DBI and sql commands

=head1 VERSION

See Version in L<Gtk2::Ex::DbLinker::DbTools>

=head1 SYNOPSIS

	use DBI;
	use Gtk2 -init;
	use Gtk2::GladeXML;
	use Gtk2::Ex:Linker::DbiDataManager; 

	my $dbh = DBI->connect (
                          "dbi:mysql:dbname=sales;host=screamer;port=3306",
                          "some_username",
                          "salespass", {
                                           PrintError => 0,
                                           RaiseError => 0,
                                           AutoCommit => 1,
                                       }
	);
	 my $builder = Gtk2::Builder->new();
	 $builder->add_from_file($path_to_glade_file);

To fetch the data from the a whole table

	  my $rdbm = Gtk2::Ex::DbLinker::DbiDataManager->new(
		 	dbh => $dbh,
			sql =>{from => "mytable",
			select => "pk_id, field1, field2, field3",
			where => "1=1",
		},
	 );

To link the data with a Gtk windows, have the Gtk entries ID, or combo ID in the xml glade file set to the name of the database fields: pk_id, field1, field2...

	  $self->{form} = Gtk2::Ex::DbLinker::Form->new( 
		    data_manager => $rdbm,
		    builder =>  $builder,
		   ...
	    );

To add a combo box in the form:

	  my $dman = Gtk2::Ex::DbLinker::DbiDataManager->new(
			dbh => $dbh,
			sql => {
				select => "id, name",
				from => "table",
				order_by => "name ASC",
				where => "1=1",
				},
		);

The first field given in the select value will be used as the return value of the combo.
C<noed> is the Gtk2combo id in the glade file and the field's name in the table displayed in the form.

    $self->{form}->add_combo(
    	data_manager => $dman,
    	id => 'noed',
      );

And when all combos or datasheets are added:

      $self->{form}->update;

To change a set of rows in a subform, listen to the on_changed event of the primary key in the main form:

		$self->{subform_a}->on_pk_changed($new_primary_key_value);

In the subform_a module:

	sub on_pk_changed {
		 my ($self,$value) = @_;
		$self->{jrn_coll}->get_data_manager->query( where =>"pk_value_of_the_bound_table = ?", 
								bind_values => [ $value ],
							   );
		...
		}

=head1 DESCRIPTION

This module fetches data from a dabase using DBI and sql commands. A new instance is created using a database handle and sql string and this instance is passed to a Gtk2::Ex::DbLinker::Form object or to Gtk2::Ex::DbLinker::Datasheet objet constructors.

=head1 METHODS

=head2 constructor

The parameters to C<new> are passed as a list of parameters name => values, or as a hash reference with the parameters name as keys.

Paramters are  C<dbh>, C<sql>, C<primary_keys>, C<ai_primary_key>.

The value for C<primary_keys> and C<ai_primary_key> are arrayrefs holding the field names of the primary key and auto incremented primary keys. 
If the table use a autogenerated key, use ai_primary_key instead of primary_keys to set these.
C<dbh>, C<sql> are mandatory.
The value for C<sql> is a hash reference with the following keys : C<select> or C<select_distinct>, C<from>, C<where>, C<order_by>, C<bind_values>, C<pass_through>.

The constructor parameters are described below:

=over

=item * 

C<dbh>: a DBI database handle. Mandatory.

=item *

C<aperture>: default to 1. All the primary keys for a given where clause are retrieved but only C<aperture> rows are fetch. Using a aperture of 50 speed up the code if the rows contain data that does not change.

=item *

C<before_query> : a code ref to be run at the start of the query method.

=item *

C<primary_keys> : an array ref of the primary key(s) name. With Mysql these are correctly detected.

=item *

C<ro_fields> : an array fef of read only fields from joined tables that are not to be included in update and insert sql statement

=item *

C<ai_primary_key> : an array ref of the auto incremeted primary key name. With Mysql this is corretly detected. You may pass ai_primary_key as undef to indicate that the primary key is not auto incrementing

=item *

C<defaults> : a hash ref of fieldname => default value;

=item*

C<sql> a hash ref with the following keys:

=over

=item *

C<select> or C<select_distinct> : a comma delimited string of the field names, default to * if left unspecified. Field aliasing is supported.

=item *

C<from> : a string of the join clause. Mandatory unless you use C<pass_through>

=item *

C<where> : a string of the where clause. Use place holders if the C<bind_values> keys is set. If left unspecified, no rows will be retrieved, but query with a hash ref describing a where clause can still be called on an data manager object.

=item *

C<order_by> : a string of the order by clause.

=item *

C<bind_values> : a array ref of the values corresponding to the place holders in the C<where> clause.


=item *

C<pass_through> :  an sql string that will be executed in the DB. Rows are read only, and can't be deleted or added. The query method can't be used to fetch a new set of rows.

=back

=back

	Gtk2::Ex::DbLinker::DbiManager->new( dbh => $dbh,
					    sql => {
							select_distinct => "abo.ref as ref, ...",
							from   => "abo INNER JOIN jrnabt ON abo.noabt = jrnabt.noabt",
							where  => "nofm=?",
							order_by =>"abo.type ASC, abo.ref ASC",
							bind_values=> [ $nofm_value ],
						}
				);

=head2 C<query( where => "pk=?" , bind_values=>[ $value ] );

To display an other set of rows in a form, call the query method on the datamanager instance for this form.
Return the number of rows retrieved.

	my $dman = $self->{form_a}->get_data_manager();

	$dman->query(where=>"nofm=?", bind_values=>[ $f->{nofm} ]);

	$self->{form_a}->update;

C<query> will not place the recordset cursor, but in the above example C<update> on the Form (or a Datasheet) instance will. Be sure to call C<set_row_pos(0)> on the datamanager object after C<query( ... )> in others situations.

The parameter of the query method is a list of parmaters name => values, or a hash reference with the keys as parameters name.

Parameters are:

=over

=item *

C<where> : a string of the where clause, with placeholder if the bind_values array is set.

=item *

C<bind_values> : a array reference holding the value(s) corresponding to the placeholders of the where clause.

=back

=head2 C<save();> 

Build the sql commands tu insert a new record or update an existing record. Fetch the value from auto_incremented primary key.

=head2 C<save( $field_name => $value );>

Pass a list or a hash reference as a parameter when a value has to be saved in the database without using C< $dman->set_field($ field, $value ) >. Use this when you want to change a field that is part of a multiple fields primary key.

=head2 C<new_row();>

You may pass defaults in the constructor to pass default values as a hash ref {field name => value} that will be set in a new row. You have to use C<save> on the datamanager to store the row in the database.

=head2 C<delete();>

Delete the row at the current position.

=head2 C<set_row_pos( $new_pos); >

Change the current row for the row at position C<$new_pos>.

=head2 C<get_row_pos( );>

Return the position (zero based) of the current row.

=head2 C<set_field ( $field_id, $value);>

Sets $value in $field_id. undef as a value will set the field to null.

=head2 C<get_field ( $field_id );>

return the value of the field C<$field_id> or undef if null.

=head2 C<get_field_type ( $field_id);>

Return one of varchar, char, integer, date, serial, boolean, text.

=head2 C<row_count();>

Return the number of rows.

=head2 C<get_field_names();>

Return an array of the field names.

=head2 C<get_primarykeys()>;

Return an array of primary key(s) (auto incremented or not). 

=head2 C<get_autoinc_primarykeys();>

Return an array of auto incremented primary key(s). If the names are not supplied to the constructor, the array of primary keys is returned.

=head1 SUPPORT

Any Gk2::Ex::DbLinker::DbiDataManager questions or problems can be posted to me (rappazf) on my gmail account. 

The current state of the source can be extract using Mercurial from
L<http://sourceforge.net/projects/gtk2-ex-dblinker/>.

=head1 AUTHOR

FranE<ccedil>ois Rappaz <rappazf@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2017 by F. Rappaz. This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Gtk2::Ex::DbLinker::Forms>

L<Gtk2::Ex::DbLinker::Datasheet>

=head1 CREDIT

Daniel Kasak, whose code have inspired this module.

See L<Gtk2::Ex::DBI>

=cut


