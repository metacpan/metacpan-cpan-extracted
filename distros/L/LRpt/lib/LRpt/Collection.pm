#####################################################################
#
# $Id: Collection.pm,v 1.14 2006/09/17 19:25:31 pkaluski Exp $
# $Name: Stable_0_16 $
#
# This module is a container for results of one select.
#
# $Log: Collection.pm,v $
# Revision 1.14  2006/09/17 19:25:31  pkaluski
# Many, many changes due to performance tuning. There is only key possible, Tie::File is not used any more, other changes
#
# Revision 1.13  2006/09/10 18:29:14  pkaluski
# Added chunking. The class does not connect to database any more. Removed unused code.
#
# Revision 1.12  2006/02/10 22:32:16  pkaluski
# Major redesign in progress. Updated POD. Works.
#
# Revision 1.11  2006/01/14 12:52:33  pkaluski
# New tool design in progress
#
# Revision 1.10  2006/01/07 21:32:24  pkaluski
# Adjusting to new design of LReport tool chain.
#
# Revision 1.9  2005/09/02 19:59:31  pkaluski
# Next refinement of PODs. Ready for distribution. Some work on clarity still to be done
#
# Revision 1.8  2005/09/01 20:00:18  pkaluski
# Refined PODs. Separation between public and private methods still to be done
#
# Revision 1.7  2005/01/24 21:22:51  pkaluski
# Added pod documentation
#
# Revision 1.6  2005/01/21 20:43:15  pkaluski
# Fixed bug 1105088 - Columns sorting does not work for unkeyed rows
#
# Revision 1.5  2004/12/21 21:21:29  pkaluski
# Columns ordering introduced for reporting rows different from expected
#
# Revision 1.4  2004/10/17 18:22:43  pkaluski
# Added test for unkeyed A-E comparison. The test pass.
#
# Revision 1.3  2004/10/17 08:30:32  pkaluski
# Added handling of unkeyed A-E comparison. Old tests still work. New tests to be added
#
# Revision 1.2  2004/10/15 21:51:10  pkaluski
# Added test case for logging when comparing with expecations. Fixed some bugs.
#
# Revision 1.1.1.1  2004/10/02 11:30:57  pkaluski
# Changed the naming convention. All packages start with LRpt
#
#
#
####################################################################
package LRpt::Collection;
use LRpt::CollUnkeyed;
use LRpt::Config;
use Carp;
use strict;
use IO::File;

=head1 NAME

LRpt::Collection - A container for rows returned by select statement.

=head1 DESCRIPTION

This class is a part of L<C<LRpt>|LRpt> (B<LReport>) library.
This module is a container for one I<csv> file.
Rows are stored in a form of hashes returned by DBI's C<fetch_arrayref( {} ) >.
Keys of a hash
are column names, values are column values. References to all rows are
kept in a list, in an order in which they are kept in I<csv> file.
Collection provides a notion of a row key.
You can use row keys for ordering rows and for quick searches of row with
a particular key value (like in databases). Collection may have several
keys defined. Each key has a name, columns, which compose a key and a 
function, which basing on key fields' values, generates a string, which
can be used as a hash key.

=head1 METHODS

=cut

sub new_empty_copy
{
    my $proto         = shift;
    my %params        = @_;
    
    if( ! $params{ 'src_coll' } ){
        die "No source collection specified";
    }
    
    my $class = ref( $proto ) || $proto;
    my $self = {};
    bless( $self, $class ); 

    $self->{ 'name' }     = $params{ 'src_coll' }->{ 'name' };
    $self->{ 'columns' }  = $params{ 'src_coll' }->{ 'columns' }; 
    $self->{ 'col_idxs' } = $params{ 'src_coll' }->{ 'col_idxs' }; 
    $self->{ 'key' }     = $params{ 'src_coll' }->{ 'key' }; 
    $self->{ 'copied' } = 1;
    my $config = LRpt::Config->new();
    my $chunk_size = $config->get_value( 'chunk_size' );
    if( not defined $params{ 'chunk_size' } ){
        $self->{ 'chunk_size' } = $chunk_size;
    }else{
        $self->{ 'chunk_size' } = $params{ 'chunk_size' };
    }
    return $self;
}

sub new_from_csv
{
    my $proto         = shift;
    my %params        = @_;

    die "Name of the statement not given" if not $params{ 'name' };
    die "Name of the data file not given" if not $params{ 'data_file' };
    
    my $class = ref( $proto ) || $proto;
    my $self = {};
    bless( $self, $class ); 
    my $config = LRpt::Config->new();
    my $chunk_size = $config->get_value( 'chunk_size' );
    if( not defined $params{ 'chunk_size' } ){
        $self->{ 'chunk_size' } = $chunk_size;
    }else{
        $self->{ 'chunk_size' } = $params{ 'chunk_size' };
    }

    $self->{ 'name' } = $params{ 'name' };
    $self->{ 'data_file' } = $params{ 'data_file' };
    $self->upload_from_csv( $params{ 'data_file' } );

    if( $params{ 'key' } ){
        $self->init_keys_data( $params{ 'key' } );
    }
    if( $self->{ 'key' } ){
        $self->build_keys();
    }
    return $self;

} 



#########################################################################

=head2 C<init_keys_data>

  $coll->init_keys_data( $keys_info );

Initializes internal structure, storing information about keys.
The meaning of fields is as follows:

=over 4

=item C<$self->{ keys }>

Hash. Key in a hash is a key name. Value is a reference
to a hash with the following key-value pairs:

C<columns> => reference to array of names of columns which are part of the key

C<function> => reference to a function, which creates a key value from the 
columns' values. If not defined C<generate_key> is used.

After initialization, current key is set to the first specified key.

=back

=cut

########################################################################### 
sub init_keys_data
{
    my $self        = shift;
    my $inp_structs = shift;

    $self->{ 'key' } = {};

    #
    # We are generous, so we allow user to specify either column
    # names, or their indexes (0 based)
    #

    my @col_names = ();
    foreach my $col ( @{ $inp_structs->{ 'columns' } } ){
        if( $col =~ /^\d+$/ ){
            if( $col >= @{ $self->{ 'columns' } } ){
                warn "No column of index $col for " . 
                     $self->{ 'data_file' };
            }
            push( @col_names, $self->{ 'columns' }->[ $col ] );
        }else{
            if( not exists $self->{ 'col_idxs' }->{ $col } ){
                warn "No column $col " . $self->{ 'data_file' };
            }
            push( @col_names, $col );
        }
    }
    $self->{ 'key' } = 
            {
                'columns'  => [ @col_names ],
                'function' => $inp_structs->{ 'function' }
            };
}


####################
# Loads next chunk of data
#
#################### 
sub load_next_chunk
{
    my $self = shift;
    my $key  = shift;

    if( $self->{ 'chunk_size' } == 0 ){
        die "load_next_chunk should not be called when chunk_size is zero. " .
            "If you got this message, there is a serious bug in the code.";
    }
    if( $self->{ 'file_handle' } ){
        my $fh = $self->{ 'file_handle' };
        my @rows = ();
        my $i = 0;
        my $cols = $self->{ 'columns' };
        my $last_row = $self->get_keyed_rows()->{ $key };
        while( <$fh> ){
            chomp;
            my @values = split( /\t/, $_ );
            my %row    = ();
            @row{ @$cols } = @values;
            push( @rows, \%row );
            if( $i == $self->{ 'chunk_size' } - 1 )
            { 
                last;
            }
            $i++;
        }
        if( $i == 0 ){
            $fh->close() or 
                      die "Cannot close " . $self->{ 'data_file' } . ": $!";
            $self->{ 'file_handle' } = undef;
            my $rows = $self->{ 'rows' };
            $self->{ 'rows' } = [];
            $self->{ 'rows' }->[ 0 ] = $last_row; 
            $self->build_keys();
            return 1; # Nothing new loaded
        }
        unshift( @rows, $last_row );
        $self->{ 'rows' } = \@rows;
        $self->build_keys();
        return 2; #New chunk loaded
    }
    else{
        return 1;
    }
    
}


#########################################################################

=head2 C<build_keys>

  $coll->build_keys();

Builds all data structures needed for efficient use of keys for rows
retrieval.
It generates a key value for each row. Then creates the following
structure:

  $self->{ 'keyed_rows' } => Reference to a hash. Key of a hash is a name 
                             of a key. Value is a reference to a hash in 
                             which key is a value of row key, and hash 
                             value is reference to a row.

Accesing a row with key = xxx would require to use the following reference:

  $self->{ 'keyed_rows' }->{ 'rows' }->{ 'xxx' }

=cut

#################################################################### 
sub build_keys
{
    my $self = shift;

    my $sel_key = $self->{ 'key' };
    $self->{ 'unkeyed_coll' } = LRpt::CollUnkeyed->new();
    $self->build_one_key( $sel_key );
}


#####################################################################

=head2 C<build_one_key>

  $coll->build_one_key();

Builds a structure described in C<build_keys> for one row key.
All rows, which do not have values for all columns from the key, are
moved to a list of 'unkeyed' rows.

=cut

#################################################################### 
sub build_one_key
{
    my $self = shift;

    #print STDERR "Chunk size is " . $self->{ 'chunk_size' } . "\n";
    my $key = $self->{ 'key' };

    my $key_function = \&LRpt::Collection::generate_key;
    if( $key->{ 'function' } ){
        if( !ref $key->{ 'function' } ){
            $key_function = \&LRpt::Collection::generate_fmt_key; 
        }else{
            $key_function = $key->{ 'function' };
        }
    }
    my $unkeyed = 0;
    $self->{ 'keyed_rows' }->{ 'rows' } = {};
    foreach my $row ( @{ $self->{ 'rows' } } ){
        if( $self->has_all_key_columns( $row ) ){
            my $key_value = &$key_function( $row, $key );
            $self->{ 'keyed_rows' }->{ 'rows' }->{ $key_value } = $row;
        }else{
            $self->{ 'unkeyed_coll' }->add_row( $row );
            $unkeyed++;
        }
    }
    my @chunk_keys = 
        sort keys %{ $self->{ 'keyed_rows' }->{ 'rows' } };
    if( @chunk_keys ){
        $self->set_first_chunk_key( $chunk_keys[ 0 ] ); 
        $self->set_last_chunk_key( $chunk_keys[ $#chunk_keys ] ); 
    }
    if( ( scalar( @{ $self->{ 'rows' } } ) - $unkeyed ) != 
        ( keys %{ $self->{ 'keyed_rows' }->{ 'rows' } } ) )
    {
        if( exists $self->{ 'data_file' } ){
            warn "Key is not unique. Some rows from file " .
                 $self->{ 'data_file' } . " will be lost!!!";
        }else{
            die "Should not reach this place";
        }
    }
}

sub set_first_chunk_key
{
    my $self      = shift;
    my $first_key = shift;
    if( not exists $self->{ 'first_chunk_key' } )
    {
        $self->{ 'first_chunk_key' } = $first_key; 
    }else{
        #
        # If a key of the first row in a new chunk is lower then or equal
        # to the current one...
        #
        if( $first_key lt 
            $self->{ 'last_chunk_key' } )
        {
            die "Unsorted input for collection " . $self->{ 'data_file' } . 
                ". When input is chunked it must be sorted";
        }else{  
            $self->{ 'first_chunk_key' } = $first_key; 
        }
    }
}
    
sub set_last_chunk_key
{
    my $self      = shift;
    my $last_key  = shift;
    if( not exists $self->{ 'last_chunk_key' } )
    {
        $self->{ 'last_chunk_key' } = $last_key; 
    }else{
        #
        # If a key of the first row in a new chunk is lower then or equal
        # to the current one...
        #
        if( $last_key lt 
            $self->{ 'last_chunk_key' } )
        {
            die "Unsorted input for collection " . $self->{ 'data_file' } . 
                ". When input is chunked it must be sorted";
        }else{
            $self->{ 'last_chunk_key' } = $last_key; 
        }
    }
}


#####################################################################

=head2 C<get_unkeyed_coll>

  $unk_rows = $coll->get_unkeyed_coll();

Returns a reference to a collection of 'unkeyed' rows 
(L<C<LRpt::CollUnkeyed>|LRpt::CollUnkeyed>).

=cut

#################################################################### 
sub get_unkeyed_coll
{
    my $self = shift;
    return $self->{ 'unkeyed_coll' };
}


#########################################################################

=head2 C<has_all_key_columns>

  $coll->has_all_key_columns($row );

Checks if a rows has values in columns, which are part of a key

=cut

####################################################################
sub has_all_key_columns
{
    my $self = shift;
    my $row = shift;
    
    my $key_cols = $self->{ 'key' }->{ 'columns' };
    foreach my $col ( @$key_cols ){
        if( not exists $row->{ $col } ){
            return 0;
        }
    }
    return 1;
}

#########################################################################

=head2 C<dump_rows>

  $coll->dump_rows( $path );

Dumps rows from the collections to the text file (tab separated)

=cut

####################################################################
sub dump_rows 
{
    my $self     = shift;
    my $path     = shift;
    my $config   = LRpt::Config->new();

    if( !$path ){
        $path = $config->get_value( 'path' );
    }
    my $ext = $config->get_value( 'ext' );
    my $sep = $config->get_value( 'sep' );

    my $rows     = $self->{ 'rows' };
    my $name     = $self->{ 'name' };

    my $row = "";

    open( OUTFILE, ">$path/$name.$ext" ) or
        die "Cannot open $path/$name.$ext : $!";  
    #
    # Print header (all column names)
    #
    print OUTFILE join( $sep, @{ $self->{ columns } } ) . "\n";
        
    foreach $row ( @{ $rows } ){ 
        #
        # @ord_cols should contain all columns, in the same order in which
        # they are in querried tables
        #
        
        my @ord_cols = @$row{ @{ $self->{ 'columns' } } };
        print OUTFILE "" . join( $sep, @ord_cols ) . "\n";
    }
    close( OUTFILE ) or die "Cannot close $path/$name.txt : $!"; 
} 


#########################################################################

=head2 C<upload_from_csv>

  $coll->upload_from_csv( $path );

Uploads rows from the text file (tab separated)

=cut

####################################################################
sub upload_from_csv
{
    my $self = shift;
    my $path = shift;

    my $fh = new IO::File;
    $fh->open( "< $path" ) or die "Cannot open $path : $!";

    $self->{ 'file_handle' } = $fh;
    my $header = <$fh>;
    die "No header given in $path" if not $header;
    chomp( $header );
    
    my @cols = split( /\t/, $header );
    $self->{ 'columns' } = \@cols;
    my %col_idxs = ();
    for( my $i = 0; $i < @cols; $i++ ){
        $col_idxs{ $cols[ $i ] } = $i;
    }
    $self->{ 'col_idxs' } = \%col_idxs; 

    my @rows = (); 
    my $i = 1;
    while( <$fh> ) 
    {
        chomp;
        my @values = split( /\t/, $_ );
        my %row    = ();
        @row{ @cols } = @values;
        push( @rows, \%row );
        if( $i == $self->{ 'chunk_size' } and $self->{ 'chunk_size' } )
        { 
            last;
        }
        $i++;
    }

    $self->{ 'rows' } = \@rows;

}

#########################################################################

=head2 C<get_name>

  $coll->get_name();

Gets the name of the collection.

=cut

#########################################################################
sub get_name
{
    my $self = shift;
    return $self->{ 'name' };
}


#########################################################################

=head2 C<get_columns>

  $coll->get_columns();

Returns all columns names returned by the select

=cut

#########################################################################
sub get_columns
{
    my $self = shift;
    return $self->{ 'columns' };
}


#########################################################################

=head2 C<generate_key>

  my $key_value = LRpt::Collection::generate_keys( $row, $key );

Default function for generating row key values. 
It simply joins all key columns using '#' as a separator

=cut

########################################################################
sub generate_key
{
    my $row  = shift;
    my $key  = shift;

    my $cols     = $key->{ 'columns' };
    foreach my $col ( @$cols ){
        if( not exists $row->{ $col } ){
            die "Invalid rkey definition. There is no such column '$col'";
        }
    }
    my @key_cols = @$row{ @$cols };
    return join( '#', @key_cols ); 
}


#########################################################################

=head2 C<get_key_value>

  my $key_value = $coll->get_key_value( $row );

Returns value of the current key for a given row.

=cut

#########################################################################
sub get_key_value
{
    my $self = shift;
    my $row  = shift;
    
    return LRpt::Collection::generate_key( $row, $self->{ 'key' } );
}


#########################################################################

=head2 C<get_key_columns>

  my @cols = $coll->get_key_columns();

For a given key (or the current key, of no key name given) returns
all columns, which are part of the a key. 

=cut

########################################################################
sub get_key_columns
{
    my $self     = shift;
    return @{ $self->order_columns( $self->{ 'key' }->{ 'columns' } ) };
}


#########################################################################

=head2 C<order_columns>

  my $cols = $coll->order_columns( $unord_cols );

Orders and returns columns by their appearance in the table

=cut

#########################################################################
sub order_columns
{
    my $self = shift;
    my $cols = shift;

    my $idx_hash = $self->{ 'col_idxs' };
    my $columns = $self->{ 'columns' };

    my @col_idxs = @$idx_hash{ @$cols }; # Indexes of all columns given in
                                         # $cols
    @col_idxs = sort { $a <=> $b } @col_idxs;
    my @ord_cols = @$columns[ @col_idxs ]; 
                                         # Columns from cols sorted by the
                                         # order of appearance in a table

    return \@ord_cols;
}


#########################################################################

=head2 C<generate_fmt_key>

  my $key_str = LRpt::Collection::generate_fmt_key( $row, $key );

Generates a key string, which can be used as a key in a hash.

=cut

########################################################################
sub generate_fmt_key
{
    my $row  = shift;
    my $key  = shift;

    my $cols     = $key->{ 'columns' };
    foreach my $col ( @$cols ){
        if( not exists $row->{ $col } ){
            die "Invalid rkey definition. There is no such column '$col'";
        }
    }
    my @key_cols = @$row{ @$cols };
    return sprintf( $key->{ 'function' }, @key_cols ); 
}


#########################################################################

=head2 C<get_keyed_rows>

  my $rows = $coll->get_keyed_rows();

Returns a reference to a hash were keys are values of key and
values are reference to rows with those keys.

=cut

########################################################################
sub get_keyed_rows
{
    my $self     = shift;
    return $self->{ 'keyed_rows' }->{ 'rows' };
}

#########################################################################

=head2 C<get_key_values>

  my @values = $coll->get_key_values();

Returns all values of a given key.

=cut

########################################################################
sub get_key_values
{
    my $self     = shift;

    if( $self->no_rows() ){
        return ();
    }
    return keys %{ $self->get_keyed_rows() };
}


#########################################################################

=head2 C<get_row>

  my $row = $coll->get_row( $key_value )

Using a key value C<$key_value> for key retrieves a row.

=cut

########################################################################
sub get_row
{
    my $self     = shift;
    my $key      = shift;

    if( $self->no_rows() ){
        return undef;
    }

    if( $self->{ 'chunk_size' } != 0 ){
        if( $key eq $self->{ 'last_chunk_key' } ){
            my $load = $self->load_next_chunk( $key );
            if( $load == 1 ){
                return $self->get_keyed_rows()->{ $key };
            }elsif( $load == 2 ){
                return ( $self->get_keyed_rows()->{ $key },
                        $self->get_key_values() ); 
            }
        } 
    }
    return $self->get_keyed_rows()->{ $key };
} 


#########################################################################

=head2 C<no_rows>

  my $res = $coll->no_rows();

Returns 1 if collection is empty

=cut

########################################################################
sub no_rows
{
    my $self = shift;
    if( @{ $self->{ 'rows' } } ){
        return 0;
    }else{
        return 1;
    }
}

#########################################################################

=head2 C<adopt_rows>

  $coll->adopt_rows( $rows );

Appends a set of rows to the collection ( C<$rows> should be a reference to
and array of references to hashes, each representing one row ).

=cut

############################################################################
sub adopt_rows
{
    my $self = shift;
    my $rows = shift;

    foreach my $row ( @$rows ){
        foreach my $col ( keys %$row ){
            if( not exists $self->{ 'col_idxs' }->{ $col } ){
                die "Adopted row has unknown column $col";
            }
        }
    }

    if( !$self->{ 'rows' } ){
        $self->{ 'rows' } = [ @$rows ];
    }else{
        my $all_rows = [ @{ $self->{ 'rows' } }, @$rows ];
        $self->{ 'rows' } = $all_rows;
    }
    if( $self->{ 'key' } ){
        $self->build_keys();
    }
}

#########################################################################

=head2 C<get_all_rows>

  $coll->get_all_rows();

Returns a reference to a list containing all rows in the order returned
by select.

=cut

############################################################################
sub get_all_rows
{
    my $self = shift;
    return $self->{ 'rows' };
}


=head1 INTERNAL DATA STRUCTURE

Below you can find something, which is my pathetic attempt to create 
a readable diagram. It is supposed to show a hierarchy of internal data
structure. I am open to suggestions how to make it look more readable

  $self->
      |
      |->{ name }
      |->{ data_file }
      |->{ key }
      |   |->{ columns }  = [ $col1, $col2, ... ]
      |   |->{ function } = $fmt_string   
      |->{ columns } = $sth->{ 'NAME' }
      |->{ col_idxs } = $sth->{ 'NAME_hash' }
      |->{ rows }      = [ $row1, $row2, ... , $rown ]
      |->{ unkeyed_coll } = LRpt::CollUnkeyed object
      |->{ keyed_rows }
      |   |->{ $key_value1 } = $self->{ rows }->[ ... ]
      |   |->{ $key_value2 } = $self->{ rows }->[ ... ]
      |   |->{ ........... } = $self->{ rows }->[ ... ]
      |   |->{ $key_valueN } = $self->{ rows }->[ ... ]
      |->{ select_stmt }
      |   |->{ statement } --> obsolete

=over 4

=item name

Name of a collection. Does not have a particular meaning for 
Collection object itself, but is helpful for managing a group of
collections and is used by other LRpt modules

=item data_file

Name of a csv file used as a data source

=item key

A structure keeping an information about row key used by a 
collection. 
Key entry contains 'columns' which is a reference to list of 
columns which are parts of a key (order matters), and a function, 
which specifies some additional formatting, which should be 
applied to key columns in order to get 
a key value. Currently it's a formatting string used by sprintf to build
one string from all key columns. If function is not given, it is a simple
concatenation.

=item columns

equivalent of DBI's $sth->{ 'NAME' } - A list of columns in the order 
from the row

=item col_idxs

equivalent of DBI's $sth->{ 'NAME_hash' } - A hash in which a 
key is column name and value is an index of a column in a row.

=item rows

A reference to a list of all rows returned by 
the select/uploaded from csv file

=item unkeyed_coll

collection of rows, for which not all columns being 
part of a row key are defined. 

=item keyed_rows

Additional structure used for performance when accessing single rows 
using row keys. For each row key name it defines a hash. 
Each key in this hash is a key value, hash value is a 
reference to a row having this key value.

=back

=head1 SEE ALSO

The project is maintained on Source Forge L<http://lreport.sourceforge.net>. 
You can find there links to some helpful documentation like tutorial.

=head1 AUTHORS

Piotr Kaluski E<lt>pkaluski@piotrkaluski.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2004-2006 Piotr Kaluski. Poland. All rights reserved.

You may distribute under the terms of either the GNU General Public License 
or the Artistic License, as specified in the Perl README file. 

=cut


1;

