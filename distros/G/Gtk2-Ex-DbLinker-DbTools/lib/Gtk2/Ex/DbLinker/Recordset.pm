package Gtk2::Ex::DbLinker::Recordset;
use Gtk2::Ex::DbLinker::DbTools;
our $VERSION = $Gtk2::Ex::DbLinker::DbTools::VERSION;

use strict;
use warnings;
# use Data::Dumper;
# use Carp;
use Try::Tiny;

my %fieldtype = ( tinyint => "integer", "int" => "integer" );

#The position in the recordset is
# $self->{batch_group} * $self->{batch_size}  + $self->{batch_position};
#Rows resulting from a where clause are fetch in two setps:
# - all the values from the primary keys
# - all the rows for subset of batch_size primary keys

#dico from Kasak's code:
#aperture -> batch_size
#keyset_group > batch_group
#slice_position > batch_pos
#keyset   -> pkvalues (all the values of one (or more) primary key(s) resulting from a where clause
# -> batch : store the batch_size values of one  (or more) pks for the current subset
#
sub new {
    my %def   = ( batch_size => 1, pkvalues_filter => 0 );
    my $class = shift;
    my %args  = ( %def, @_ );

    #die Dumper(%args);
    my $self = {
        batch_size      => $args{aperture}        || $def{batch_size},
        pkvalues_filter => $args{pkvalues_filter} || $def{pkvalues_filter},
    };
    $self->{cols}  = [];
    $self->{hcols} = {};
    $self->{rs_log}   = Log::Log4perl->get_logger(__PACKAGE__); #log is used in the derived class
    bless $self, $class;
}

#data: AoA ref of pk values for all the rows fetch from query in DataManager or $data from one row
#pk_names A ref of pk names
#
sub rs_init {
    my ( $self, $data, $pk_names ) = @_;
    if ($pk_names) {
        $self->{pkvalues} = $data
          ; # if(@$data); if $data is  undef: the values from the preceding batch are erased. This is ok
        $self->{pks} = $pk_names;
    } else {
        $self->{records} = $data;    # if (@$data); same here
        $self->{pks}     = undef;
    }

    #die Dumper($self->{records});
    $self->{batch_group} = undef;
    $self->{batch_pos}   = undef;
}

# return 1 if there is row data to be get from a new subset of pk values
sub rs_move {
    my ( $self, $offset, $absolute ) = @_;

#$self->{rs_log}->debug("rs_move : offset ", (defined $offset ? $offset : "undef"), " abs: ", (defined $absolute ? $absolute : "undef") );

    my ( $new_batch_group, $new_position );

    if ( defined $absolute ) {
        $new_position = $absolute;
    } else {
        $new_position = ( $self->get_row_pos || 0 ) + $offset;

        # Make sure we loop around the recordset if we go out of bounds.
        if ( $new_position < 0 ) {
            $new_position = $self->row_count - 1;
        } elsif ( $new_position > $self->row_count - 1 ) {
            $new_position = 0;
        }
    }

    my $isnewbatch = 0;

    #if ( exists $self->{sql}->{from} ) {
    if ( $self->{pks} ) {

        # Check if we need to roll to another slice of our recordset
        $new_batch_group = int( $new_position / $self->{batch_size} );

        #$self->{rs_log}->debug("new_batch_group: ", $new_batch_group);
        if ( defined $self->{batch_pos} ) {
            if ( $self->{batch_group} != $new_batch_group ) {
                $self->{batch_group} = $new_batch_group;
                $isnewbatch = $self->_fetch_new_batch;

                #$isnewbatch = 1;
            }    #else {

#same batch
#	$self->{rs_log}->debug("same batch - keeping the same ", $self->{batch_size}, " values ");
#}

        } else {
            $self->{batch_group} = $new_batch_group;
            $isnewbatch = $self->_fetch_new_batch;

            #$isnewbatch = 1;
        }

        $self->{batch_pos} =
          $new_position - ( $new_batch_group * $self->{batch_size} );

    } else {

        $self->{batch_pos} = $new_position;

    }

    #$self->{rs_log}->debug("batch_pos: ", $self->{batch_pos});
    #return @data;
    return $isnewbatch;

}

#$self->{batch} : AoA, there are as many rows as primary keys for a table (so most of the time only one row).
#This row is an array ref that contains the values for the pk. There is batch_size values unless
#$self->pkvalues_filter is 1: the pk values are added only once in the array.
#$self->pkvalues_filter is 0: all the values are added.
#return 1 if there is row data to be get
sub _fetch_new_batch {

    # Fetches a new set  of pk values ( based on the aperture size )
    my $self = shift;
    my @data;

    # Get max value for the loop
    my $lower      = $self->{batch_group} * $self->{batch_size};
    my $upper      = ( ( $self->{batch_group} + 1 ) * $self->{batch_size} ) - 1;
    my $isnewbatch = 1;

    my $batch_count = $self->row_count;

 #$self->{rs_log}->debug("_fetch_new_batch batch_group : ". $self->{batch_group} );

#$self->{rs_log}->debug("_fetch_new_batch lower: " . $lower . "  count : " . $batch_count . " upper ". $upper);

    if ( ( $batch_count == 0 ) || ( $batch_count == $lower ) ) {

        # If $batch_count == 0 , then we don't have any records.

# If $batch_count == $lower, then the 1st position ( lower ) is actually out of bounds
# because our keyset STARTS AT ZERO.
# Either way, there are no records, we issue a warning ...

        # First, we have to delete anything in $self->{records}
        $self->{records} = ();
        $self->{rs_log}->debug("_fetch_new_batch called on an empty recordset");
        $isnewbatch = 0;
    } else {

        if ( $upper > $batch_count - 1 ) {
            $upper = $batch_count - 1;
        }

        my @all_pk_vals = @{ $self->{pkvalues} };
        my @pks         = @{ $self->{pks} };
        my $pk_order    = 0;
        foreach my $pk (@pks) {

            #counter donne le nombre de lignes
            my @vals_for_pk;
            my %seen;
            for ( my $counter = $lower ; $counter < $upper + 1 ; $counter++ ) {

         # $local_sql .= " ( " . join( ",", $self->{keyset}[$counter] ) . " ),";
                my @pk_vals = @{ $all_pk_vals[$counter] };

#$self->{rs_log}->debug("array for row ", $counter, " is ", Dumper(@pk_vals), " value for ", $pk, " is ", $pk_vals[$pk_order]);
#push @vals_for_pk, $pk_vals[$pk_order] unless ($seen{ $pk_vals[$pk_order] }++);
                if ( $self->{pkvalues_filter} ) {

# if a primary key value is repeated
#(that means that the table rows are defined by several colums to form the primary key),
#it is stored once
                    push @vals_for_pk, $pk_vals[$pk_order]
                      unless ( $seen{ $pk_vals[$pk_order] }++ );
                } else {

                    #all the values are stored, repeated or not
                    push @vals_for_pk, $pk_vals[$pk_order];
                }
            }
            $pk_order++;

           #Each row in @data holds an array ref and correspond to a primary key
           #(most of the time the is one pk, so one array ref).
           #This array holds the batch_size values for this pk
            push @data, \@vals_for_pk;
        }

    }
    $self->{batch} = \@data;
    return $isnewbatch;
}

sub get_pkvalues_from_batch {
    return @{ shift->{batch} };

}

sub delete_keys_values {
    my ( $self, $pos ) = @_;

    # First remove the record from the batch
    splice( @{ $self->{pkvalues} }, $pos, 1 );
    if ( $self->row_count > 0 ) {

        #$self->{batch_group} = -1;
        $self->rs_move(-1);
    } else {
        $self->{records} = undef;

    }
}

#param: Aref of all the rows that correspond to the current batch of primary key(s) values
sub rs_set_rows {
    my ( $self, $data ) = @_;

    #die ( ref $data);
    $self->{records} = $data;

    #$self->{rs_log}->debug("rs_set_rows : ", Dumper($self->{records}));
}

#Param: $data hash ref for one row
sub rs_add_row {
    my ( $self, $data ) = @_;

    #push @{$self->{records}}, $data;
    $self->{records}[ $self->{batch_pos} ] = $data;

    #$self->{rs_log}->debug("rs_add_row : ", Dumper($self->{records}));

}

#return an array ref of rows
sub rs_get_rows {
    shift->{records};

}

sub set_field {
    my ( $self, $fieldname, $value ) = @_;
    $self->{records}[ $self->{batch_pos} ]->{$fieldname} = $value;

    #$self->{rs_log}->debug("set_field : ", Dumper ($self->{records}));

}

sub get_field {
    my ( $self, $fieldname ) = @_;

# $self->{rs_log}->debug("get_field - name : " . $fieldname . "\nRecords: " . (Dumper $self->{records}));
     $self->{rs_log}->logcarp("get_field($fieldname) called on an empty recordset ! Did you forget to call set_row_pos(0) after query ?"
    ) unless ( $self->{records} );
    my $data = $self->{records}[ $self->{batch_pos} ]->{$fieldname};
    return $data;
}

sub get_field_names {
    my $self = shift;

    # my @names =  keys %{$self->{widgets}};
    my @names = @{ $self->{cols} };
    return @names;
}

sub row_count {
    my $self = shift;
    my $count_this;

  #if ( ! exists $self->{sql}->{from} && exists $self->{sql}->{pass_through} ) {
    if ( $self->{pks} ) {
        $count_this = "pkvalues";
    } else {
        $count_this = "records";
    }

    my $count;
    if ( ref( $self->{$count_this} ) eq "ARRAY" ) {

        #$arraydef = 1;
        $count = scalar @{ $self->{$count_this} };
    } else {
        $count = 0;
    }

   # $self->{rs_log}->debug("row_count :  counting ", $count_this , " : ", $count);
    return $count;
}

sub get_row_pos {
    my $self = shift;
    return ( $self->{batch_group} * $self->{batch_size} ) + $self->{batch_pos};

}

sub next {
    shift->set_row_pos( 1, 1 );
}

sub previous {
    shift->set_row_pos( -1, 1 );
}

sub last {
    my $self = shift;
    $self->set_row_pos( $self->row_count - 1 );
}

sub first {
    shift->set_row_pos(0);
}

#Param: array ref of pk value(s) for a row
sub add_pkvalues {
    my ( $self, $value ) = @_;
    push @{ $self->{pkvalues} }, $value;

}

sub get_autoinc_primarykeys {
    my $self = shift;
    if ( $self->{auto_incrementing} ) {
        my $arref =
          (   $self->{ai_primary_key}
            ? $self->{ai_primary_key}
            : $self->{primary_keys} );
        return @{$arref};
    } else {

#http://stackoverflow.com/questions/1006904/why-does-my-array-undef-have-an-element
        return ();
    }

}

sub get_primarykeys {
    my $self = shift;
    if ( $self->{auto_incrementing} ) {

        #return @{$self->{ai_primary_keys}};
        return $self->get_autoinc_primarykeys;
    } else {
        if ( $self->{primary_keys} ) {
            return @{ $self->{primary_keys} };
        } else {
            return ();

        }
    }
}

sub set_row_pos {
    my ( $self, $pos, $isrelative ) = @_;

    #$self->{rs_log}->debug("set_row_pos: " . $pos  );
    #$self->_move(undef, $pos);
    my @batch_pk_vals;
    my $newbatch;
    if ($isrelative) {
        $newbatch = $self->rs_move($pos);
    } else {
        $newbatch = $self->rs_move( undef, $pos );
    }

    #Dumper(@batch_pk_vals);
    if ($newbatch) {

        #die $pos;
        #$self->{rs_log}->debug("set inserting to 0");
        $self->{inserting} = 0;
        my $data =
          $self->_get_rows_from_batch( $self->get_pkvalues_from_batch );

        #die (ref $data);
        $self->rs_set_rows($data);
    } # else there is nothing to do since the rows values are already in the recordset

}

sub get_field_type {
    my ( $self, $fieldname ) = @_;
    my $type;
    if ( exists $self->{column_info}->{$fieldname} ) {
        $type = lc( $self->{column_info}->{$fieldname}->{TYPE_NAME} );
        $type = ( $fieldtype{$type} ? $fieldtype{$type} : $type );
    } else {

        #$self->{rs_log}->debug (Dumper $self->{column_info});
        $type = "varchar";
    }

    #$self->{rs_log}->debug("get_field_type for ".   $fieldname . " : " . $type);
    return $type;
}

sub new_row {

    my $self = shift;

    #$self->{rs_log}->debug("new row called : set inserting flag");
    my $newposition =
      $self->row_count;    # No need to add one, as the array starts at zero.

    $self->rs_move( undef, $newposition );

    $self->{inserting} = 1;

    # Assemble new record and put it in place
    #$self->{records}[$self->{slice_position}] = $self->_assemble_new_record;
    $self->rs_add_row( $self->_assemble_new_record );

    # $self->{rs_log}->debug("new row rows are : ", Dumper($self->rs_get_rows));
}

sub _assemble_new_record {

    # This sub assembles a new hash record and sets default values

    my $self = shift;

    #$self->{rs_log}->debug("_assemble_new_record");
    my $new_record;

    # First, we create fields with default values from the database ...
    foreach my $fieldname ( keys %{ $self->{column_info} } ) {

        # COLUMN_DEF is DBI speak for 'column default'
        my $default = $self->{column_info}->{$fieldname}->{COLUMN_DEF};
        if ( $default && $self->{server} =~ /microsoft/i ) {
            $default = $self->parse_sql_server_default($default);
        }
        $self->{rs_log}->debug(
            "set database's default value ",
            $self->{defaults}->{$fieldname},
            " for field ", $fieldname
        );
        $new_record->{$fieldname} = $default;
    }

    # ... and then we set user-defined defaults
    foreach my $fieldname ( keys %{ $self->{defaults} } ) {
        $self->{rs_log}->debug(
            "set user's default value ",
            $self->{defaults}->{$fieldname},
            " for field ", $fieldname
        );
        $new_record->{$fieldname} = $self->{defaults}->{$fieldname};
    }
    return $new_record;

}

sub _last_insert_id {

    my $self = shift;

    my $primary_key;

    if ( $self->{server} =~ /postgres/i ) {

        # Postgres drivers support DBI's last_insert_id()

        $primary_key =
          $self->{dbh}
          ->last_insert_id( undef, $self->{schema}, $self->{sql}->{from},
            undef );

    } elsif ( lc( $self->{server} ) eq "sqlite" ) {

        $primary_key = $self->{dbh}
          ->last_insert_id( undef, undef, $self->{sql}->{from}, undef );

    } else {

        my $sth = $self->{dbh}->prepare('select @@IDENTITY');
        $sth->execute;

        if ( my $row = $sth->fetchrow_array ) {
            $primary_key = $row;
        } else {
            $primary_key = undef;
        }

    }
    $self->{rs_log}->debug( "_last_instert_id : ",
        ( defined $primary_key ? $primary_key : " undef" ) );
    return $primary_key;

}

sub _init_pks {
    my $self = shift;
    my $sth;
    my $sth2;

    # DBIDataManager and SqlADataManger : table name is not in the same field
    my $table = $self->{sql}->{from};
    $table = ( defined $table ? $table : $self->{table} );
    $self->{rs_log}->debug( "_init_pks: ", $table );

    try {
        $sth = $self->{dbh}->primary_key_info( undef, undef, $table );

    }
    catch {
        $self->{rs_log}->debug( $self->{dbh}->errstr );
        return;
    };

    #push @$self->{select_param}, (-want_details => 1);
    #my %det = $self->{sql}->select(@$self->{select_param});
    #$hrtable = $det{aliased_tables};
    #my @tables = values %hrtable;

    while ( my $row = $sth->fetchrow_hashref ) {

        $self->{rs_log}->debug( "Detected primary key : " . $row->{COLUMN_NAME} );
        try {
            $sth2 = $self->{dbh}
              ->column_info( undef, undef, $table, $row->{COLUMN_NAME} );
        }
        catch {
            $self->{rs_log}->debug( $self->{dbh}->errstr );
        };

        while ( my $ir = $sth2->fetchrow_hashref ) {
            if ( $ir->{mysql_is_auto_increment} ) {

                # Dumper($ir);
                # $self->{rs_log}->debug("ai pk type: ", $ir->{TYPE});
                $self->{auto_incrementing} = 1;
            }

        }

        push @{ $self->{primary_keys} }, $row->{COLUMN_NAME};
        $self->_add_to_cols( $row->{COLUMN_NAME} );

    }    #while

}

sub _use_sth_info {
    my ( $self, $sth ) = @_;

    $self->{cols} = $sth->{'NAME'};

    #for my $name (@{ $sth->{'NAME_lc'}}){
    #	$self->{cols}->{ $name };
    #}

    my %hcols = map { $_ => 1 } @{ $self->{cols} };
    $self->{hcols} = \%hcols;
    my @type = @{ $sth->{'TYPE'} };
    $self->{rs_log}->debug( "TYPE: ", join( " ", @type ) );
    my $pos     = 0;    #http://docstore.mik.ua/orelly/linux/dbi/ch06_01.htm
    my %sqltype = (
        1  => 'char',
        2  => 'integer',
        3  => 'integer',
        4  => 'integer',
        5  => 'integer',
        6  => 'integer',
        7  => 'integer',
        8  => 'integer',
        9  => 'date',
        10 => 'date',
        11 => 'date',
        12 => 'varchar',
        -1 => 'varchar',
        -2 => 'boolean',
        -3 => 'boolean',
        -4 => 'text',
        -5 => 'integer',
        -6 => 'integer',
        -7 => 'integer'
    );
    for my $name ( @{ $self->{cols} } ) {
        my $type = lc $type[ $pos++ ];

        #$self->{rs_log}->debug("searching " . $type);
        #if ($self->{server}){
        if ( $type =~ /-?\d{1,2}/ )
        { #mysql gives type as given in sqltype above, DBI::CSV (where $self->{server} is undef) gives the type as an array of string
            $type = $sqltype{$type};
        }

        $self->{rs_log}->debug( $name . " type: " . $type );
        $self->{column_info}->{$name}->{TYPE_NAME} = $type;
    }
}

sub _add_to_cols {
    my ( $self, $fieldname ) = @_;
    my %hcols = %{ $self->{hcols} };
    $self->{rs_log}->debug( "_add_to_cols ", $fieldname )
      unless ( defined $hcols{$fieldname} );
    push @{ $self->{cols} }, $fieldname unless ( defined $hcols{$fieldname} );
    $hcols{$fieldname}++;

    #$self->{hcols}->{$fieldname}++;
    $self->{hcols} = \%hcols;

}

1;
__END__

=pod

=head1 NAME

Gtk2::Ex::DbLinker::Recordset - A base class the SqlADataManager and DBIDataManager inherit from.

=head1 VERSION

See Version in L<Gtk2::Ex::DbLinker::DbTools>

=head1 SYNOPSIS

The end user is not supposed to use this class directly.

=head1 DESCRIPTION

Methods starting with 

=over

=item *

C<_> are not supposed to be used outside this module.

=item *

C<rs_> are used by the inheriting class but not the end user.

=item *

The others methods are use by the end user and are described in the inheriting classes.

=back

=head1 AUTHOR

FranE<ccedil>ois Rappaz <rappazf@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2016-2017 by F. Rappaz.  All rights reserved.  This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Gtk2::Ex::DbLinker::SqlADataManager>

L<Gtk2::Ex::DbLinker::DbiDataManager>

L<Gtk2::Ex::DBI>

=head1 CREDIT

Daniel Kasak's implementation of storing only the pk values for the rows from a select query and getting the actual data for subset of rows.
L<Gtk2::Ex::DBI>

=cut

