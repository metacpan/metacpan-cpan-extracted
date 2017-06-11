package Gtk2::Ex::DbLinker::SqlADataManager;
use Gtk2::Ex::DbLinker::DbTools;
our $VERSION = $Gtk2::Ex::DbLinker::DbTools::VERSION;
use strict;
use warnings;
use interface qw(Gtk2::Ex::DbLinker::AbDataManager);
use Carp qw(carp croak confess cluck);
use Log::Any;
# use Data::Dumper;
use SQL::Abstract::More;
use Try::Tiny;

use parent qw(Gtk2::Ex::DbLinker::Recordset);

#my %fieldtype = (tinyint => "integer", "int" => "integer");

#One must calls the methods with named arguments as defined in SQL::Abstract::More

#DBI avec pass-through tous les energistrements  sont mis d'un coup dans record
#sinon (si from est donne) les enregsitrements sont mis par paquets dans keyset
#c'est pourqoi count retourne les nombre d'element dans l'un ou l'autre
#donc: aperture determine la taille d'un keyset
#keyset_group est le nombre de keyset deja parcouru
#slice_position est la position dans le keyset en cours
#
sub new {
    my $class = shift;
    my %arg;

    #die ref $_[0];
    my %def = ( bla => 1 );

=for comment
	if ( ref $_[0] eq "HASH" ) {
		%arg =(%def, %{$_[0]});
	} elsif (ref $_[0]) {
		confess __PACKAGE__ . "->new : received arguments of the wrong type. Must be a list or a Hash ref\n";
	}
	else {
		%arg = @_;
	}
=cut

    %arg = ( ref $_[0] eq "HASH" ? ( %def, %{ $_[0] } ) : ( %def, @_ ) );

    #my ( $class, $req ) = @_;

#my $self = $class->SUPER::new({aperture => $$req{aperture}, pkvalues_filter=> 1});
    my $self =
      $class->SUPER::new( batch_size => $arg{aperture}, pkvalues_filter => 1 );

    $$self{dbh}          = $arg{dbh};             # A database handle
    $$self{primary_keys} = $arg{primary_keys};    # An array ref of primary keys
      #sql                     => $$req{sql},                                  # A hash of SQL related stuff
    $$self{new_param} = $arg{new_param}
      ;    # hash ref of parameters for the SQL::Abstract::More contructor
    $$self{select_param} = $arg{select_param}
      ; #needed to define the fields and the primary key, can select an empty recordset
     #$$self{aperture	=> $$req{aperture} || 1, #batch size : how many records are read by fetch_new_slice
    $$self{before_query} = $arg{before_query};
    $$self{defaults}     = $arg{defaults};
    $self->{log} = Log::Any->get_logger;
    # $self->{log} = Log::Log4perl->get_logger(__PACKAGE__);
    # $self->{rs} = Gtk2::Ex::DbLinker::Recordset->new( $self->{aperture} );
    confess($self->{log}->error("select_param required"))
      unless ( $self->{select_param} );
    $self->{ai_primary_key} = $arg{ai_primary_key}
      if ( exists( $arg{ai_primary_key} ) )
      ;    # an array of auto incremented primary keys
           #bless $self, $class;
   

    #$self->{auto_incrementing} = ( defined ($self->{ai_primary_key}) ? 1 : 0);

    confess($self->{log}->error(
        "Use ai_primary_key or primary_keys but not both..." ))
      if ( defined $self->{ai_primary_key} && defined $self->{primary_keys} );

    if ( !$self->{dbh} ) {
        confess($self->{log}->error("Constructor missing a dbh!\n" ));
    }

    #$self->{cols} = {};

    #   $self->{cols} = [];
    #     $self->{hcols}= {};
    $self->{server} = $self->{dbh}->get_info(17);

    # $self->{log}->debug( "select_param: ", Dumper( $self->{select_param} ) );
    $self->{log}->debug( "select_param ref: ", ref $self->{select_param} );

    if ( ref $self->{select_param} eq "SCALAR" ) {

        #die ${$self->{select_param}};
        $self->{sql} = undef;
        my $sth;
        try {
            $sth = $self->{dbh}->prepare( ${ $self->{select_param} } );
            $sth->execute;
        }
        catch {
            confess($self->{log}->error(  $self->{dbh}->errstr ) );
        };

        $self->_use_sth_info($sth);
        $self->rs_init( $sth->fetchall_arrayref( {} ), undef );

    } else {
        $self->{sql}   = SQL::Abstract::More->new( %{ $self->{new_param} } );
        $self->{table} = $self->_get_tablename;
        # $self->{log}->debug( "Table found: ", Dumper( $self->{table} ) );
        $self->_init_cols;
        $self->{log}->debug( "cols: ", join( " ", @{ $self->{cols} } ), "\n" );
        $self->{auto_incrementing} =
          ( defined( $self->{ai_primary_key} ) ? 1 : 0 );
        if ( !$self->{primary_keys} ) {

            # peut redefinir auto_incrementing avec mysql
            $self->_init_pks;
        }
        $self->{log}->debug( "primary_keys array : ",
            join( " ", @{ $self->{primary_keys} } ), "\n" );
        $self->{log}
          ->debug( "pks: ", join( " ", $self->get_primarykeys ), "\n" );
        $self->{primary_keys} = $self->{ai_primary_key}
          if ( defined $self->{ai_primary_key} );
        $self->{log}
          ->debug( "auto_incrementing: " . $self->{auto_incrementing} );

        if ( $self->{select_param}->{-where} ) {
            $self->query( { -where => $self->{select_param}->{-where} } );

        }

        if ( $self->{select_param}->{-having} ) {
            #$self->{log}->debug("query called without arg");
            $self->query();
        
        }
    }

    return $self;

}

#Replace for the function duration the -where parameter setted in the constructor by the arg received in the call
#Get the pk values for the rows corresponding to this -where parameter
#Build a new recordset object using these values and restore the original -where and -col parameter.
#
#keyset is an array ref, of arrays, each reccord fetch by query is remembered by an array of the primary key(s) value(s). Most of the time, the array will have one element.
#If query return 10 records, keyset will refer to an array of 10 arrays
sub query {

    #my ( $self,  $where ) = @_;
    my $self = shift;
    my %h;
   
    my $select = $self->{select_param};
    my $col    = $select->{-columns};     #could be undef, default to '*'
         #my $worig = $self->{select_param}->{-where};
     my $where;
     if ( defined $_[0]) {
         $where = ( ref $_[0] eq "HASH" ) ? $_[0] : ( %h = (@_) ) && \%h;
        $select->{-where} = $where->{-where} if ( exists $where->{-where} );
    }

    #$self->{select_param} = $select;

    #  $self->{log}->debug("query: ", Dumper($select));

    if ( $self->{before_query} ) {
        $self->{before_query}();
    }

# build a sql statement and bind parameters for fetching the primary key values only
# substitute the originial -columns value with the pk names
    my @pks = $self->get_primarykeys();
    $select->{-columns} = \@pks;
    my @select = ();
    while ( my ( $k, $v ) = each %$select ) {
        push @select, $k;
        push @select, $v;
    }
    my ( $sql, @bind ) = $self->{sql}->select(@select);

    # die $sql;
    my $sth = $self->_execute( $sql, @bind );

    # restaurer le param -columns s'il etait indique
    if ( !defined $col ) {
        delete $select->{-columns};
    } else {
        $select->{-columns} = $col;
    }

    #reset the original parameters including the -where param
    $self->{select_param} = $select;

    #$self->{keyset} = ();
    #$self->{records} = ();

    my @all_pk_vals;

#build a array ref at $self->{keyset}
#each elements of the array is an array ref. The sub array holds the value(s) of the primary key(s) for a row.
    while ( my @row = $sth->fetchrow_array ) {
        my $key_no = 0;
        my @key_vals;

        # $self->{log}->debug(Dumper @row);
        foreach my $pk (@pks) {

# $self->{log}->debug("query : " . $primary_key . " value : " . $row[$key_no] );
# if $row[$key_no] is 0 the test failed but a pk could have this value...
            croak( $self->{log}->error("No value found for primary key $pk .. check the sql command"
                )) unless ( defined $row[$key_no] );

            #push @keys, $row[$key_no];
            push @key_vals, $row[$key_no];

#$self->{log}->debug("add ", $row[$key_no], " to array of pkvalues for pk ", $pk);
            $key_no++;
        }

#was :
# push @{$self->{keyset}}, @keys; # but the loop in fetch_new_slice missed a pk value...
# $self->{log}->debug("push " . join(" ", @key_vals) . " on all_pk_vals array");
#push @{$self->{keyset}}, join(", ",  @{$key_vals{$pk}});
        push @all_pk_vals, \@key_vals
          if (@key_vals);    #peut rester undef si sth ne retourne aucune ligne

    }
    $self->rs_init( \@all_pk_vals, \@pks );

# $self->{keysetvalues} = \%key_vals; #->{keyset} hashref, key: pks, and value: array ref of the value for n rows for that key
#$self->{keyset_size}
#for my $v ( @{$self->{keyset}} ) { $self->{log}->debug("value : " . $v);}

    $sth->finish;
    return scalar @all_pk_vals;

}

#Get the rows from the database using the primary key values
#
sub _get_rows_from_batch {
    my ( $self, @all_pk_vals ) = @_;
    my @where_orig = (
        ref $self->{select_param}->{-where}
        ? %{ $self->{select_param}->{-where} }
        : $self->{select_param}->{-where} );

#$self->{log}->debug("original select parameters : \n", Dumper($self->{select_param}));
#$self->{log}->debug("where_orig ", join(" ", @where_orig));
#my @in;

    #my @all_pk_vals = @{$self->{keyset}};
    #die Dumper(@all_pk_vals);
    #delete the original where clauses and build new one using the pk
    my @where_new = ();
    my $pk_order  = 0;
    my @pks       = $self->get_primarykeys();
    foreach my $pk (@pks) {

        #counter donne le nombre de lignes
        my @vals_for_pk;
        my %seen;

        # my $counter = 0;
        #for ( my $counter = $lower; $counter < $upper+1; $counter++ ) {
        my $pk_vals = $all_pk_vals[$pk_order];

        #die Dumper(@$pk_vals);
        for my $pk_val (@$pk_vals) {

  # $local_sql .= " ( " . join( ",", $self->{keyset}[$counter] ) . " ),";
  #my @pk_vals = @{$all_pk_vals[$counter]};
  #my $value = $pk_val->[]
  #$self->{log}->debug("pk :", $pk, " value: ", $pk_val);
 
            push @vals_for_pk, $pk_val unless ( $seen{$pk_val}++ );

            #push @where_new, %where;

        }
        $pk_order++;
        my %where = ( $pk => { -in => \@vals_for_pk } );
        push @where_new, %where;
    }

    #$self->{log}->debug(Dumper(@where));
    my %w = @where_new;
    $self->{select_param}->{-where} = \%w;

#$self->{log}->debug("modified select parameters : \n", Dumper($self->{select_param}));

    my ( $stm, @bind ) = $self->{sql}->select( ( %{ $self->{select_param} } ) );

    my $sth = $self->_execute( $stm, @bind );
    return unless ($sth);
    #$self->{records} = $sth->fetchall_arrayref({});
    #$self->rs_set_rows( $sth->fetchall_arrayref({}) );
   if ( @where_orig > 1){
        %w = @where_orig;
        $self->{select_param}->{-where} = \%w;
    } 
    else {
         $self->{select_param}->{-where} = $where_orig[0];
    }

    # return an array ref of hash ref: each hash is {field_name => field_Value}
    my $data = $sth->fetchall_arrayref( {} );
    return $data;
}

sub save {
    my $self = shift;
    my %h;
    my $href = ( ref $_[0] eq "HASH" ? $_[0] : ( %h = (@_) ) && \%h );

    my %new_values;

    #my @fieldlist = ();
    #my @bind_values = ();
    $self->{log}->debug( " save: inserting is " . $self->{inserting} );

#$href is used to change a field's value when the field is included in a composed primary keys.
#The array @pk holds the field's name of the primary keys since ->get_primarykeys return these fields even if auto_incrementing is 0
#The if test in the foreach loop fails and the values of the primary key fields are not added in the bind_values array therefore.
#The old values are then used to select the row when the field has to be changed.
#
#When $href is undef, save is used to insert or changed a non primary keys field, the primary key value comes from the database.
#@pk holds the auto incremented primary key names (auto_incrementing is 1) or is undef.
#
    my @pk;
    if ($href) {
        for my $k ( keys %$href ) {
            $self->{log}->debug( "received with calling save "
                  . $href->{$k}
                  . " from field "
                  . $k );

            #push @bind_values, $href->{$k};
            #push @fieldlist, $k;
            $new_values{$k} = $href->{$k};
            if ( $self->{inserting} )
            { #when updating existing pk value, the old value in dman are to be used
                    # to select the row. -> no change
                $self->set_field( $k, $href->{$k} );
            }
        }

        # @pk = $self->get_primarykeys;
    }    #else {
         # @pk  = $self->get_autoinc_primarykeys;
     #avec la table abo et la jointure sur jrnabt, la mise a jour ne marche pas car get_autoinc_primarykey retroune un vecteur vide
     #noabt est alors traite comme un champ normal
     #prendre toujours le resultat de get_primarykeys corrige ce probleme
     #}
    @pk = $self->get_primarykeys;
    $self->{log}->debug( "pk: " . join( " ", @pk ) );
    $self->{log}
      ->debug( "primary_keys: " . join( " ", @{ $self->{primary_keys} } ) );

    my %pk_values;
    my $table = $self->_get_tablename;
    my ( $value, $stm, @bind );

    foreach my $fieldname ( @{ $self->{cols} } ) {

        $self->{log}->debug( "Processing field " . $fieldname );

        #if ( $sql_fieldname ~~ @pk) {
        if ( grep ( /\b$fieldname\b/, @pk ) ) {
            my @keys = keys %new_values;
            $self->{log}
              ->debug("Not fetching value from $fieldname because it's a pk. ");

            next;
        }

        $value = $self->get_field($fieldname);

#if ( defined $widget && ref $widget ne "Gtk2::Label" ) { # Labels are read-only
# push @fieldlist, $fieldname;
#push @bind_values, $self->get_widget_value( $fieldname );
#$self->{log}->debug("push on bind_values " . $fieldname . " : " . $value);
#   push @bind_values, $self->get_field( $fieldname );
#}
        $self->{log}->debug( "field : ", $fieldname, " value : ",
            ( defined $value ? $value : "" ) );
        $new_values{$fieldname} = $value;
    }    #foreach

    # my $update_sql;
    $self->{log}->debug( "new values: ", join(" ", %new_values) );
    if ( $self->{inserting} ) {

#$update_sql = "insert into " . $self->{sql}->{from} . " ( " . join( ",", @fieldlist, ) . " )" . " values ( " . "?," x ( @fieldlist - 1 ) . "? )";

        $self->{log}->debug( "inserting into ", $table );

        ( $stm, @bind ) =
          $self->{sql}->insert( -into => $table, -values => \%new_values );

    } else {

        #update: fetch the pk(s) value(s) for the row to update

        foreach my $primary_key (@pk) {
            $primary_key =~ s/^$table\.//;
            $value = $self->get_field($primary_key);
            $self->{log}->debug( "Get pk "
                  . $primary_key
                  . " value : "
                  . ( $value ? $value : " !!! undefined !!!" ) );

            #push @bind_values,  $self->get_field($primary_key) };
            $pk_values{$primary_key} = $value;
        }

        $self->{log}->debug(
            "updating ", $table,
            " at rows with pks : ",
            join(" ", %pk_values)
        );

        # run the update
        ( $stm, @bind ) = $self->{sql}->update(
            -table => $table,
            -set   => \%new_values,
            -where => \%pk_values
        );

    }

    my $done = ( $self->_execute( $stm, @bind ) ? 1 : 0 );

    if ( $done && $self->{inserting} ) {

     # update the datamanager with the value of autoinc pk given by the database
        if ( $self->{auto_incrementing} ) {
            my $new_key = $self->_last_insert_id;

            # my $primary_key = $self->{primary_keys}[0];
            my $primary_key = $pk[0];

#$self->{records}[$self->{slice_position}]->{ $self->{sql_to_widget_map}->{$primary_key} } = $new_key;
            $self->set_field( $primary_key, $new_key );

        }

        #insert in a row defined by pk(s) that are autoinc or not autoinc
        #add the pks names + values to the recordset object
        my @keys;
        foreach my $primary_key ( @{ $self->{primary_keys} } ) {

       #my $value = $self->{records}[$self->{slice_position}]->{ $primary_key };
            my $value = $self->get_field($primary_key);

#$self->{log}->debug("pk : " . $primary_key . " value: " . ($value ? $value : " undef"));
            push @keys, $value;
        }

#in Recordset, pkvalues is an array ref of array, each array contains usualy one value for the a given row, but can contains 2 values if it's a composed primary key
        $self->add_pkvalues( \@keys );

#$self->{log}->debug( join(", ", @keys) . " added to pkvalues");
#turn the flag only if $done is true... otherwise all subsequent atempts to save a new insert
#that has failed will be treated as updates (not inserts) and will failed also since no pk has been given.
        $self->{inserting} = 0;
        $self->{log}->debug("turn off inserting flag");
    }

    #$self->{inserting} = 0;
    #$self->{log}->debug("turn off inserting flag");
    return $done;
}

sub delete {

    my $self  = shift;
    my @pks   = $self->get_primarykeys;
    my $table = $self->_get_tablename;

    #$self->{log}->debug("delete pk_name is " . join( " ", @pks));

    my %keys_values;
    my $value;

    foreach my $pk (@pks) {

#push @bind_values, $self->{records}[$self->{slice_position}]->{ $self->{sql_to_widget_map}->{$primary_key} };
        $value = $self->get_field($pk);

        #$self->{log}->debug("pk name: ", $pk , " value: ", $value);
        $keys_values{$pk} = $value;
    }

    my ( $stm, @bind ) =
      $self->{sql}->delete( -from => $table, -where => \%keys_values );

# my $sth = $self->{dbh}->prepare( "delete from " . $self->{sql}->{from} . " where " . $self->{primary_key} . " = ?" );
    $self->{log}
      ->debug( "delete values: " . join( " ", values(%keys_values) ) );

    $self->_execute( $stm, @bind );

    $self->delete_keys_values( $self->get_row_pos );
}

sub _execute {
    my ( $self, $sql, @bind ) = @_;
    # $self->{log}->debug( "_execute:", $sql );
    my $sth = $self->{dbh}->prepare($sql);

    #my $done=0;
    try {
        $sth->execute(@bind);

        #$done =1;
    }
    catch {
        $sth = undef;
        $self->{log}->error( $self->{dbh}->errstr );
    };

    #return $done;
    return $sth;
}

sub _init_cols {
    my $self = shift;
    my $args = $self->{select_param};
    my %aliased_columns;
    my %seen;
    my @cols =
      ref $args->{-columns} ? @{ $args->{-columns} } : $args->{-columns};
    $self->{log}->debug( "_init_cols ",  defined $cols[0] ? join(" ", @cols) : " undef");
    if ( $cols[0] ) {
        my @post_select;
        push @post_select, shift @cols while @cols && $cols[0] =~ s/^-//;
        foreach my $col (@cols) {

            # extract alias, if any
            if (
                $col =~ /^\s*         # ignore insignificant leading spaces
                 (.*[^|\s])   # any non-empty string, not ending with ' ' or '|'
                 \|           # followed by a literal '|'
                 (\w+)        # followed by a word (the alias))
                 \s*          # ignore insignificant trailing spaces
                 $/x
              )
            {
                #$aliased_columns{$2} = $1;
                #$col = $1;
                $self->{log}->debug( "found col ", $col );

#$col = $self->column_alias($1, $2); dans le cas select lang, lang as lang1 seul lang doit etre ajoute dans @cols
#dans le cas select table1.field as fieldrenamed, table2.other as otherrenamded
# fieldrenamed + otherrenamed doivent etre ajoute

                my $a = $aliased_columns{$2};
                $self->{log}
                  ->debug( $1, " alias : ", ( $a ? " yes " : " no " ) );
                if ( !$seen{$1} ) {
                    $col = ( $2 ? $2 : $1 );
                } else {
                    $self->{log}->debug( $1, " already added to cols" );
                    $col = undef;
                }
                $aliased_columns{$2} = $1 if ($2);
            }
            if ( defined $col ) {
                $self->_add_to_cols($col);
                $seen{$col}++;
            }
        }
        $self->{isalias} = \%aliased_columns;
    } else {
        my $w = $$args{-where};
        $$args{-where} = { 0 => { '=' => \"1" } };
        my @args = %$args;

        #ie Dumper(@args);

        my ( $s, @bind ) = $self->{sql}->select(@args);

        #die $s;
        my $sth;
        try {
            $sth = $self->{dbh}->prepare($s);
            $sth->execute;
        }
        catch {
            $self->{log}->error( $sth->errstr );
        };
        $self->_use_sth_info($sth);
        $self->{select_param}->{-where} = $w;
    }

    #$args{-columns} = \@cols;

}

sub _get_tablename {

    my $self = shift;
    my %args = %{ $self->{select_param} };
    my $tableinfo;
    if ( ref $args{-from} eq 'ARRAY' && $args{-from}[0] eq '-join' ) {
        my @join_args = @{ $args{-from} };
        shift @join_args;    # drop initial '-join'
        my $href = $self->{sql}->join(@join_args);
        # $self->{log}->debug( Dumper($href) );
        my $alias_or_name = $href->{name};
        $tableinfo = $href->{aliased_tables}->{$alias_or_name};
        $tableinfo = ( defined $tableinfo ? $tableinfo : $alias_or_name );
    } else {
        $tableinfo = $args{-from}

    }

    return $tableinfo;

}

1;

__END__

=pod

=head1 NAME

Gtk2::Ex::DbLinker::SqlADataManager - a module that get data from a database using SQL::Abstract::More

=head1 VERSION

See Version in L<Gtk2::Ex::DbLinker::DbTools>

=head1 SYNOPSIS

	use DBI;
	use Gtk2 -init;
	use Gtk2::GladeXML;
	use Gtk2::Ex:Linker::SQLADataManager; 

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

To fetch the data from the database

	  my $rdbm = Gtk2::Ex::DbLinker::SqlADataManager->new(
		 	dbh => $dbh,
		 	 primary_keys => ["pk_id"],
			select_param =>{-from=>'table', -where=>{id =>{'<'=> 4}}},
	 );

To link the data with a Gtk windows, have the Gtk entries ID, or combo ID in the xml glade file set to the name of the database fields: pk_id, field1, field2...

	  $self->{linker} = Gtk2::Ex::DbLinker::Form->new({ 
		    data_manager => $rdbm,
		    builder =>  $builder,
		    rec_spinner => $self->{dnav}->get_object('RecordSpinner'),
  	    	    status_label=>  $self->{dnav}->get_object('lbl_RecordStatus'),
		    rec_count_label => $self->{dnav}->get_object("lbl_recordCount"),
	    });

To add a combo box in the form:

	  my $dman = Gtk2::Ex::DbLinker::SqlADataManager->new(
			dbh => $dbh,
			select_param => {
				-columns => "id, name",
				-from => "table",
				-order_by => [+name]
				-where => {-bool => "1=1"}
				},
		);

The first field given in the -columns value will be used as the return value of the combo.
C<noed> is the Gtk2combo id in the glade file and the field's name in the table displayed in the form.

    $self->{linker}->add_combo(
    	data_manager => $dman,
    	id => 'noed',
      );

And when all combos or datasheets are added:

      $self->{linker}->update;

To change a set of rows in a subform, listen to the on_changed event of the primary key in the main form:

		$self->{subform_a}->on_pk_changed($new_primary_key_value);

In the subform_a module:

	sub on_pk_changed {
		 my ($self,$value) = @_;
		$self->{jrn_coll}->get_data_manager->query(-where =>{pk_value_of_the_bound_table => $value },
							   );
		...
		}

=head1 DESCRIPTION

This module fetches data from a dabase using SQL::Abstract::More to build sql statements and parameters. A new instance of SqlADataManager is created with passing a hash ref of a database handle and -select parameters. This instance is used by a Gtk2::Ex::DbLinker::Form object or to Gtk2::Ex::DbLinker::Datasheet objet constructors.

=head1 METHODS

=head2 constructor

The parameters to C<new> are passed in as a list of parameters name => value or as a hash reference with the parameters name as keys 

Parameters are

=over

=item *

C<dbh>, 

=item *

C<new_param>

Hash ref of parameters for the L<SQL::Abstract::More/"new"> constructor.

=item *

C<select_param>, 

The value for C<select_param> can be

=over

=item *

a hash reference with the keys used by select in SQL::Abstract::More using the named parameters : C<-columns> or C<-from>, C<-where>, C<-order_by>, C<-group_by>, C<-having>, C<-union>, C<-for>, C<-wants_details>, C<-limit>, C<-offset> or C<-page_size>, C<-page-index>. Use a -where value if you want fetch an initial set of rows. To get a complete table use C<-where => {-bool => "1=1"}> or C<-where => {primarykey =>{'>'=>0}}>.

See L<SQL::Abstract::More> for the values. 

=item *

a scalar reference where the scalar holds an sql string that will be executed in the DB. Rows are read only, and can't be deleted or added. The query method can't be used to fetch a new set of rows.

=back

=item *

C<primary_keys>, 


=item *

C<ai_primary_key>.

The value for C<primary_keys> and C<ai_primary_key> are arrayrefs holding the field names of the primary key and auto incremented primary keys. 

If the table use a autogenerated key, use ai_primary_key instead of primary_keys to set these. If your DB is mysql ai_primary_key should be detected.

=item *

C<defaults> : a hash ref of fieldname => default value;

=item *

C<before_query> : a code ref to be run at the start of the query method.

=back

C<dbh>, C<select_param> are mandatory but you may omit a -where clause to retrieve an empty set of records.




	Gtk2::Ex::DbLinker::SqlADataManager->new({ dbh => $dbh,
					    select_param => {
							-columns => [qw (abo.ref|ref abo.type|type abo.note|note abo.debut|debut abo.fin|fin abo.nofrn)],
							-from   =>[qw/ abo|t1 noabt=nobat jrnabt|t2/]
							-where  => {nofm => $self->{nofm} }
							-order_by => [qw/ +abo.type +abo.ref/],

							},
						});

=head2 C<query( -where => { field => $value} );

To display an other set of rows, call the query method on the datamanager instance. The parameter is a list of param => value or a hash ref of the same. 
The only key is -where and the value follow the same rules of -where parameter in L<SQL::Abstract::More/"select">.
Return the number of rows. To use the Mysql full text index, use C<{-where => { -bool =>"match(ti, ex, ad) against('+$bla' in boolean mode)" }}>

	my $dman = $self->{form_a}->get_data_manager();

	$dman->query({ -where=> {nofm=> $f->{nofm} }});
	$self->{form_a}->update;

C<query> will not place the recordset position, but in the above example C<update> on the Form (or a Datasheet) instance will. Be sure to call C<set_row_pos(0)> on the datamanager object after C<query( ... )> in others situations.

=head2 C<save();> 

Insert a new record or update an existing record. Fetch the value from auto_incremented primary key.

=head2 C<save($field_name => $value );>

Pass a list or a hash reference to save when a value has to be saved in the database without using C< $dman->set_field($ field, $value ) >. Use this when you want to change a field that is part of a multiple fields primary key.

=head2 C<new_row();>

Insert a new row and set the default values.

=head2 C<delete();>

Delete the row $pos once C<set_row_pos( $pos )> has been called.

=head2 C<set_row_pos( $new_pos); >

Change the current row for the row at position C<$new_pos>.

=head2 C<get_row_pos( );>

Return the position of the current row, first one is 0.

=head2 C<set_field ( $field_id, $value);>

Sets $value in $field_id. undef as a value will set the field to null.

=head2 C<get_field ( $field_id );>

return the value of the field C<$field_id> or undef if null.

=head2 C<get_field_type ( $field_id);>

Return one of varchar, char, integer, date, serial, boolean.

=head2 C<row_count();>

Return the number of rows.

=head2 C<get_field_names();>

Return an array of the field names.

=head2 C<get_primarykeys()>;

Return an array of primary key(s) (auto incremented or not). Can be supplied to the constructor, or is searched by the code.

=head2 C<get_autoinc_primarykeys();>

Return an array of auto incremented primary key(s). If the names are not supplied to the constructor, the array of primary keys is returned.

=head1 SUPPORT

Any Gk2::Ex::DbLinker::SqlADataManaeger questions or problems can be posted to me (rappazf) on my gmail account. 

The current state of the source can be extract using Mercurial from
L<http://sourceforge.net/projects/gtk2-ex-dblinker-dbtools/>.

=head1 AUTHOR

FranE<ccedil>ois Rappaz <rappazf@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2016-2017 by F. Rappaz.  All rights reserved.  This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Gtk2::Ex::DbLinker::Forms>

L<Gtk2::Ex::DbLinker::Datasheet>

=head1 CREDIT

Laurent Dami for its robust SQL::Abstract::More module !

=cut

