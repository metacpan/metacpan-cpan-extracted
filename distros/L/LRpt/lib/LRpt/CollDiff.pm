##########################################################################
#
# $Id: CollDiff.pm,v 1.13 2006/09/17 19:27:01 pkaluski Exp $
# $Name: Stable_0_16 $
# 
# Object of this class compares 2 collections (LRpt::Collection objects).
#
# $Log: CollDiff.pm,v $
# Revision 1.13  2006/09/17 19:27:01  pkaluski
# Performance tuning. Changes around compare_bef_aft_rows (which does nto exist any more).
#
# Revision 1.12  2006/09/10 18:23:01  pkaluski
# Added chunking.
#
# Revision 1.11  2006/02/10 22:32:16  pkaluski
# Major redesign in progress. Updated POD. Works.
#
# Revision 1.10  2006/01/21 20:39:47  pkaluski
# Improved lcsvdiff output format
#
# Revision 1.9  2006/01/14 12:52:33  pkaluski
# New tool design in progress
#
# Revision 1.8  2005/09/02 19:59:31  pkaluski
# Next refinement of PODs. Ready for distribution. Some work on clarity still to be done
#
# Revision 1.7  2005/09/01 20:00:18  pkaluski
# Refined PODs. Separation between public and private methods still to be done
#
# Revision 1.6  2005/01/22 21:24:47  pkaluski
# Added pod documentation
#
# Revision 1.5  2004/12/21 21:21:22  pkaluski
# Columns ordering introduced for reporting rows different from expected
#
# Revision 1.4  2004/11/12 19:27:08  pkaluski
# Bunch of fixes of moderate problems
#
# Revision 1.3  2004/10/17 18:22:43  pkaluski
# Added test for unkeyed A-E comparison. The test pass.
#
# Revision 1.2  2004/10/17 08:30:32  pkaluski
# Added handling of unkeyed A-E comparison. Old tests still work. New tests to be added
#
# Revision 1.1.1.1  2004/10/02 11:30:56  pkaluski
# Changed the naming convention. All packages start with LRpt
#
###############################################################
package LRpt::CollDiff;
use strict;

=head1 NAME

LRpt::CollDiff - A module for comparing 2 collections of rows

=head1 DESCRIPTION

This class is a part of L<C<LRpt>|LRpt> library.
Object of this class compares 2 collections 
(L<C<LRpt::Collection>|LRpt::Collection> objects).
Differences are stored inside the object and can be querried by object's 
methods. They can also be printed on the standard output.

This manual page focus on implementation details. The intended audience
are developers who are willing to modify B<LReport> code or what to use
some of its modules in their code. If you are new to
B<LReport> please have a look at L<C<LRpt>|LRpt> manual page for
introduction. 

=head2 GLOSSARY

The following terms are used in the code:

=over 4

=item before collection

=item after collection

"before" refers to one of compared collections. Second collection is called 
"after". The reason for such a naming instead of col1 and col2 is that the
 code was written for comparing set of rows before the modification with
 rows after the  modification. Although the code will not break if you 
give collections in the opposite order, it would be much easier for 
you to work with this code if you follow this convention

=item missing/additional/not equal

Type of possible differences. If the row is "missing", it means that 
there exists "before" row and there is no "after" row with the same key.
 "additional" means that "after" row exists and respective "before" row
 does not. "not equal" means that after and before rows exist but there 
are some differences between them.

=back

=head1 METHODS

In this sections you will find a more or less complete listing of all
methods provided by the package. Note that the package itself is not
public so none of those methods are guaranteed to be maintained in future 
(including the package itself).

You may consider helpful having a look at the 
L<INTERNAL DATA STRUCTURE|"INTERNAL DATA STRUCTURE"> of the
object. This section may help you to understand meaning of some methods.

=cut

############################################################################

=head2 C<new>

  my $cdiff = LRpt::CollDiff->new( 'before' => $b_coll,
                                   'after'  => $a_coll );

Constructor. Initializes fields used in later processing. The C<before> and
 C<after> parameters should be references to collections to be compared
 (L<C<LRpt::Collection>|LRpt::Collection> objects). 

=cut

##########################################################################
sub new
{
    my $proto  = shift;
    my %params = @_; 

    my $class = ref( $proto ) || $proto;

    my $self = {};
    bless( $self, $class );
    if( !$params{ 'before' } ){
        die "No before collection given";
    }else{
        $self->{ 'before' } = $params{ 'before' };
    }
    if( !$params{ 'after' } ){
        die "No after collection given";
    }else{
        $self->{ 'after' } = $params{ 'after' };
    }
    if( $params{ 'skip_cols' } ){
        $self->{ 'skip_cols' } = $params{ 'skip_cols' };
    }
    return $self;
}

######################################################################

=head2 C<compare_collections>

  $cdiff->compare_collections();

The I<main> function. Compares collections given in a constructor. All 
found differences are stored internally and may be retrieved by calling 
other functions (TODO - list those functions).

=cut

##############################################################
sub compare_collections
{
    my $self           = shift;
    my $print_what     = shift;
    my $report_header  = shift;
    my $before_coll    = $self->{ 'before' };
    my $after_coll     = $self->{ 'after' }; 

    if( $report_header ){
        $self->{ 'report_header' } = $report_header;
    }

    if( $print_what ){
        $self->{ 'print_what' } = $print_what;
    }else{
        $self->{ 'print_what' } = 'diffs';
    }

    $self->compare_columns();
    # Find the sum of all keys

    my @before_key_values = $before_coll->get_key_values();
    my @after_key_values = $after_coll->get_key_values();

    my %all_keys_hash = ();
    @all_keys_hash{ @before_key_values } = 1; 
    @all_keys_hash{ @after_key_values } = 1; 
    
    my @all_keys = sort keys %all_keys_hash;
    my $key = shift( @all_keys );
    while( defined $key ){
        my ( $after_row, @after_key_values )  = $self->get_after_row( $key );
        my ( $before_row, @before_key_values ) = $self->get_before_row( $key );

        #
        # We expected a row and it does not exist/transaction removed
        # the row
        #
        if( !$after_row ){
            $self->add_diff_missing( $key );
            if( $self->{ 'print_what' } ne 'nothing' ){
                $self->report_diff_missing( $key );
            }
        }
        #
        # We did not expect a row and it does exist/a transaction created
        # a row
        #
        elsif( !$before_row ){
            $self->add_diff_additional( $key );
            if( $self->{ 'print_what' } ne 'nothing' ){
                $self->report_diff_additional( $key );
            }
        }
        #
        # Expected row exists. Lets check if it's as expected/
        # what are differences.
        #
        else{
            $self->compare_rows( $key, $before_row, $after_row );
        }

        if( @after_key_values or @before_key_values ){
            %all_keys_hash = ();
            @all_keys_hash{ @before_key_values } = 1; 
            @all_keys_hash{ @after_key_values } = 1; 
            @all_keys_hash{ @all_keys } = 1;
            @all_keys = sort keys %all_keys_hash;
            if( $all_keys[ 0 ] eq $key ){
                shift( @all_keys ); # Skip the key currently used
            }
        }
        $key = shift( @all_keys );
    }
}

#########################################################################

=head2 C<compare_columns>

  $cdiff->compare_columns( $key_value );

Checks if rows from 'before' and 'after' collections, having the same key 
value, have the same columns. If this is not the case, a difference of 
type 'diff_columns' is added.

=cut

#########################################################################
sub compare_columns
{
    my $self       = shift;

    my $before_cols_list = $self->{ 'before' }->get_columns();
    my $after_cols_list = $self->{ 'after' }->get_columns();

    my %before_cols = ();
    my %after_cols = ();
    my %all_cols = ();
    @before_cols{ @$before_cols_list } = 1;
    @after_cols{ @$after_cols_list } = 1;
    @all_cols{ @$before_cols_list } = 1;
    @all_cols{ @$after_cols_list } = 1;
    
    $self->{ 'all_cols' } = [ keys %all_cols ];
    my %only_in_before = ();
    my %only_in_after  = ();
    my %common  = ();
        
    foreach my $col ( keys %all_cols ){
        if( not exists $after_cols{ $col } ){
            $only_in_before{ $col } = 1;
        }elsif( not exists $before_cols{ $col } ){
            $only_in_after{ $col } = 1;
        }else{
            $common{ $col } = 1;
        }
    }

    my @missing = ();
    my @additional = ();
    my @equal = ();
    foreach my $col ( @$before_cols_list ){
        push( @missing, $col ) if exists $only_in_before{ $col };
        push( @equal, $col ) if exists $common{ $col };
    }
    foreach my $col ( @$after_cols_list ){
        push( @additional, $col ) if exists $only_in_after{ $col };
    }
    my @cols_to_compare = ();
    foreach my $col ( @equal ){
        if( not exists $self->{ 'skip_cols' }->{ $col } ){
            push( @cols_to_compare, $col );
        }
    }
    $self->{ 'cols_to_compare' } = \@cols_to_compare; 
    if( @equal != @$before_cols_list or @equal != @$after_cols_list ){
        $self->print_line_of_text( "SCHEMA_DIFF_BEFORE: " .
                                   join( "\t", @$before_cols_list ) ); 
        $self->print_line_of_text( "SCHEMA_DIFF_COMMON: " .
                                   join( "\t", @equal ) ); 
        $self->print_line_of_text( "SCHEMA_DIFF_MISSING: " .
                                   join( "\t", @missing ) ); 
        $self->print_line_of_text( "SCHEMA_DIFF_ADDITIONAL: " .
                                   join( "\t", @additional ) ); 
    }
}


#########################################################################

=head2 C<compare_rows>

  $cdiff->compare_rows( $key_name );

Compares 'before' and 'after' rows having the same key value and report 
differences between them. Finds and stores differences of 'diff_not_equal' 
type.

=cut

#########################################################################
sub compare_rows
{
    my ( $self, $key, $before_row, $after_row ) = @_; 

    my $diff_found = 0;
    foreach my $col ( @{ $self->{ 'cols_to_compare' } } ){
        if( $before_row->{ $col } ne $after_row->{ $col } ){
             $self->add_diff_not_equal( $key,  
                                    'column'    => $col,
                                    'before'    => $before_row->{ $col },
                                    'after'     => $after_row->{ $col } );
             $diff_found = 1;
        }
    }
    if( $self->{ 'print_what' } eq 'nothing' ) {
        return;
    }
    if( $diff_found or $self->{ 'print_what' } eq "all" ){
        $self->report_diffs_not_equal( $key, $before_row, $after_row );
    }
}

#########################################################################

=head2 C<add_diff_missing>

  $cdiff->add_diff_missing( $key_value );

Stores information that a row with the key C<$key_value> is 'missing'.

=cut

#########################################################################
sub add_diff_missing
{
    my $self   = shift;
    my $key    = shift;
    my %params = @_;

    $self->{ 'differences' }->{ $key } = 
                            { 'diff_type' => "missing",
                              'row' => $self->get_before_row( $key ) };
}

#########################################################################

=head2 C<report_diff_missing>

  $cdiff->report_diff_missing( $key_value );

Stores information that a row with the key C<$key_value> is 'missing'.

=cut

#########################################################################
sub report_diff_missing
{
    my $self   = shift;
    my $key    = shift;
    my %params = @_;

    my $line = "";
    if( $self->print_all() ){
        my $row = $self->get_before_row( $key );
        my $cols = $self->{ 'before' }->get_columns();
        $line = "DEL( $key ): " . join( "\t", @$row{ @$cols } ); 
    }else{
        $line = "DEL( $key )";
    }
    $self->print_line_of_text( $line ); 
}

#########################################################################

=head2 C<print_all>

  $cdiff->print_all();

Returns 1 if the full report should be printed (differences and all rows).

=cut

##########################################################################
sub print_all
{
    my $self = shift;
    if( $self->{ 'print_what' } eq "all" ){
        return 1;
    }else{
        return 0;
    }
}

#########################################################################

=head2 C<add_diff_additional>

  $cdiff->add_diff_additional( $key_value );

Stores information that a row with the key C<$key_value> is 'additional'.

=cut

#########################################################################
sub add_diff_additional
{
    my $self   = shift;
    my $key    = shift;
    my %params = @_;

    $self->{ 'differences' }->{ $key } = 
                            { 'diff_type' => "additional",
                              'row' => $self->get_after_row( $key ) };
}

#########################################################################

=head2 C<report_diff_additional>

  $cdiff->report_diff_additional( $key_value );

Stores information that a row with the key C<$key_value> is 'additional'.

=cut

#########################################################################
sub report_diff_additional
{
    my $self   = shift;
    my $key    = shift;
    my %params = @_;

    my $line = "";
    if( $self->print_all() ){
        my $row = $self->get_after_row( $key );
        my $cols = $self->{ 'after' }->get_columns();
        $line = "INS( $key ): " . join( "\t", @$row{ @$cols } ); 
    }else{
        $line = "INS( $key )";
    }
    $self->print_line_of_text( $line );
}

#########################################################################

=head2 C<add_diff_not_equal>

  $cdiff->add_diff_not_equal( $key_value,
                              'column' => $column_name,
                              'before' => $before_value,
                              'after'  => $after_value );

Stores information that a row with the key C<$key_value> is 'not_equal'.

=cut

#########################################################################
sub add_diff_not_equal
{
    my $self   = shift;
    my $key    = shift;
    my %params = @_;

    $self->{ 'differences' }->{ $key }->{ 'diff_type' } = "not_equal";
    $self->set_before_col_val( $key, 
                               $params{ 'column' }, 
                               $params{ 'before' } );
    $self->set_after_col_val( $key, 
                              $params{ 'column' }, 
                              $params{ 'after' } );
}

#########################################################################

=head2 C<report_diff_not_equal>

  $cdiff->report_diff_not_equal( $key_value,
                              'column' => $column_name,
                              'before' => $before_value,
                              'after'  => $after_value );

Stores information that a row with the key C<$key_value> is 'not_equal'.

=cut

#########################################################################
sub report_diffs_not_equal
{
    my ( $self, $key, $before_row, $after_row ) = @_;

    my $cols = $self->{ 'after' }->get_columns();
    my %diff_cols = ();
    @diff_cols{ $self->get_diff_columns( $key ) } = 1;
    my $line = "";
    if( $self->print_all() ){
        $line = "ROW( $key ): " . join( "\t", @$after_row{ @$cols } ); 
        $self->print_line_of_text( $line );
    }
    foreach my $col ( @$cols ){
        if( exists $diff_cols{ $col } ){
            $line = "UPD( $key ): " . $col . ": " .
                  $before_row->{ $col } . " ==#> " . 
                  $after_row->{ $col };
            $self->print_line_of_text( $line );
        }
    }
}

#########################################################################

=head2 C<add_diff_columns>

  $cdiff->add_diff_columns( $key_value,
                              'column' => $column_name,
                              'before' => $before_value,
                              'after'  => $after_value );

Stores information that compared rows do not have the same sets of columns.

=cut

#########################################################################
sub add_diff_columns
{
    my $self   = shift;
    my $key    = shift;
    my %params = @_;

    $self->{ 'differences' }->{ $key } = 
                            { 'diff_type' => "different_columns", 
                              'only_in_after' => $params{ 'only_in_after' },
                              'only_in_before'=> $params{ 'only_in_before' } };
}


#########################################################################

=head2 C<set_before_col_val>

  $cdiff->set_before_col_val( $key_value,
                              $column_name,
                              $value );

Stores information about value in 'before' row, which is different from value
 in 'after' row.

=cut

#########################################################################
sub set_before_col_val
{
    my $self = shift;
    my ( $key, $col, $value ) = @_; 
    $self->{ 'differences' }->{ $key }->{ 'diffs' }->{ $col }->{ 'before' } =
                                                            $value;
    $self->{ 'differences' }->{ $key }->{ 'before_row' } = 
                                                  $self->get_before_row( $key );
}


#########################################################################

=head2 C<set_after_col_val>

  $cdiff->set_after_col_val( $key_value,
                             $column_name,
                             $value );

Stores information about value in 'after' row, which is different from value 
in 'before' row.

=cut

#########################################################################
sub set_after_col_val
{
    my $self = shift;
    my ( $key, $col, $value ) = @_; 
    $self->{ 'differences' }->{ $key }->{ 'diffs' }->{ $col }->{ 'after' } =
                                                            $value;
    $self->{ 'differences' }->{ $key }->{ 'after_row' } = 
                                                  $self->get_after_row( $key );
}


#########################################################################

=head2 C<get_before_row>

  $cdiff->get_before_row( $key_value );

Gets before row with the given key value.

=cut

#########################################################################
sub get_before_row
{
    my $self = shift;
    my $key  = shift;
    return $self->{ 'before' }->get_row( $key );
}


#########################################################################

=head2 C<get_after_row>

  $cdiff->get_after_row( $key_value );

Gets after row with the given key value.

=cut

#########################################################################
sub get_after_row
{
    my $self = shift;
    my $key  = shift;
    return $self->{ 'after' }->get_row( $key );
} 


#########################################################################

=head2 C<get_diff_type>

  $cdiff->get_diff_type( $key_value );

Gets type of the difference between 'before' and 'after' rows of a 
given key value.

=cut

#########################################################################
sub get_diff_type
{
    my $self = shift;
    my $key  = shift;
    return $self->{ 'differences' }->{ $key }->{ 'diff_type' };
}


#########################################################################

=head2 C<get_diff_columns>

  $cdiff->get_diff_columns( $key_value );

Gets all columns, which values are different for 'after' and 'before' rows
 of a given key value. Columns are ordered by their order in the database.

=cut

#########################################################################
sub get_diff_columns
{
    my $self = shift;
    my $key  = shift;
    if( not exists $self->{ 'differences' }->{ $key } ){
        return ();
    }else{
        my @diff_cols = 
               keys %{ $self->{ 'differences' }->{ $key }->{ 'diffs' } };
        return @{ $self->{ 'after' }->order_columns( \@diff_cols ) };
    }
}


#########################################################################

=head2 C<get_key_columns>

  $cdiff->get_key_columns();

Get names of columns, which are a part of a key.

=cut

#########################################################################
sub get_key_columns
{
    my $self = shift;
    return $self->{ 'after' }->get_key_columns();
}


#########################################################################

=head2 C<has_any_diff>

  my $result = $cdiff->has_any_diff();

Returns 1 if there are any differences between compared collections 
(L<C<LRpt::Collection>|LRpt::Collection>). 
0 otherwise.

=cut

#########################################################################
sub has_any_diff
{
    my $self    = shift;
    
    if( !exists $self->{ 'differences' } ){
        return 0;
    }
    if( keys %{ $self->{ 'differences' } } ){
        return 1;
    }else{
        return 0;
    }
}


#########################################################################

=head2 C<has_diff>

  my $result = $cdiff->has_diff( $diff_type, $key_value, $col_name );

Returns 1 if there is a difference on a given column of a given type for
 rows with a given key. 0 otherwise.

=cut

#########################################################################
sub has_diff
{
    my $self      = shift;
    my $diff_type = shift;
    my $key       = shift;
    my $col_name  = shift;

    if( !$self->has_any_diff() ){
        return 0;
    }
    
    if( !exists $self->{ 'differences' }->{ $key } ){
        return 0;
    }
    if( $self->get_diff_type( $key ) eq $diff_type ){
        if( exists $self->{ 'differences' }->{ $key }->
                                  { 'diffs' }->{ $col_name } ){
            return 1;
        }
    }
    return 0;
} 


#########################################################################

=head2 C<get_not_equal_keys>

  my @key_values = $cdiff->get_not_equal_keys();

Get keys of all rows which have 'not_equal' type of difference.

=cut

#########################################################################
sub get_not_equal_keys
{
    my $self = shift;
    my @not_equal = ();
    foreach my $key ( keys %{ $self->{ 'differences' } } ){
        if( $self->get_diff_type( $key ) eq "not_equal" ){
            push( @not_equal, $key );
        }
    }
    return @not_equal;
}


#########################################################################

=head2 C<get_missing_keys>

  my @key_values = $cdiff->get_missing_keys();

Get keys of all rows which have 'missing' type of difference.

=cut

#########################################################################
sub get_missing_keys
{
    my $self = shift;
    my @missing = ();
    foreach my $key ( keys %{ $self->{ 'differences' } } ){
        if( $self->get_diff_type( $key ) eq "missing" ){
            push( @missing, $key );
        }
    }
    return @missing;
}


#########################################################################

=head2 C<get_additional_keys>

  my @key_values = $cdiff->get_additional_keys();

Get keys of all rows which have 'additional' type of difference.

=cut

#########################################################################
sub get_additional_keys
{
    my $self = shift;
    my @additional = ();
    foreach my $key ( keys %{ $self->{ 'differences' } } ){
        if( $self->get_diff_type( $key ) eq "additional" ){
            push( @additional, $key );
        }
    }
    return @additional;
}


#########################################################################

=head2 C<is_missing>

  my $result = $cdiff->is_missing( $key_value );

Returns 1 if a row of a given key is 'missing'.

=cut

#########################################################################
sub is_missing
{
    my $self = shift;
    my $key  = shift;
    if( !exists $self->{ 'differences' }->{ $key } ){
        return 0;
    }
    if( $self->get_diff_type( $key ) eq "missing" ){
        return 1;
    }
    return 0;
}


#########################################################################

=head2 C<is_additional>

  my $result = $cdiff->is_additional( $key_value );

Returns 1 if a row of a given key is 'additional'.

=cut

#########################################################################
sub is_additional
{
    my $self = shift;
    my $key  = shift;
    if( !exists $self->{ 'differences' }->{ $key } ){
        return 0;
    }
    if( $self->get_diff_type( $key ) eq "additional" ){
        return 1;
    }
    return 0;
}


#########################################################################

=head2 C<get_missing_row>

  my $row = $cdiff->get_missing_row( $key_value );

Returns a 'missing' row for a given key value. If there is no such 
'missing' row, method dies.

=cut

#########################################################################
sub get_missing_row
{
    my $self = shift;
    my $key  = shift;

    if( !$self->is_missing( $key ) ){
        die "No missing row for key $key";
    } 
    return $self->{ 'differences' }->{ $key }->{ 'row' }
}


#########################################################################

=head2 C<get_additional_row>

  my $row = $cdiff->get_additional_row( $key_value );

Returns an 'additional' row for a given key value. If there is no such
 'additional' row, the method dies.

=cut

#########################################################################
sub get_additional_row
{
    my $self = shift;
    my $key  = shift;

    if( !$self->is_additional( $key ) ){
        die "No missing row for key $key";
    } 
    return $self->{ 'differences' }->{ $key }->{ 'row' }
}


#########################################################################

=head2 C<get_additional_rows>

  my @rows = $cdiff->get_additional_rows();

Returns all 'additional' rows.

=cut

#########################################################################
sub get_additional_rows
{
    my $self = shift;
    my @a_keys = $self->get_additional_keys();
    my @a_rows = ();

    foreach my $key ( @a_keys ){
        push( @a_rows, $self->get_additional_row( $key ) );
    }
    return @a_rows;
}


#########################################################################

=head2 C<remove_diff_additional>

  $cdiff->remove_diff_additional( $row );

Removes from internal structures an information that a row reffered to 
by C<$row> is an 'additional' row.

=cut

#########################################################################
sub remove_diff_additional
{
    my $self = shift;
    my $row  = shift;
    my $key = $self->{ 'before' }->get_key_value( $row );
    if( not exists $self->{ 'differences' }->{ $key } ){
        die "Removing not existing difference of type additional for key $key";
    }else{
        if( $self->{ 'differences' }->{ $key }->{ 'diff_type' } 
                                                      eq "additional" )
        {
            delete $self->{ 'differences' }->{ $key };
        }else{
            die "Diff type for $key is not 'additional'";
        }
    }
}


#########################################################################

=head2 C<has_missing_diffs>

  my $result = $cdiff->has_missing_diffs();

Returns 1 if there is any difference of type 'missing'. 0 otherwise.

=cut

#########################################################################
sub has_missing_diffs
{
    my $self = shift;
    my @keys = $self->get_missing_keys();
    if( ! @keys ){
        return 0;
    }
    return 1;
}


#########################################################################

=head2 C<has_additional_diffs>

  my $result = $cdiff->has_additional_diffs();

Returns 1 if there is any difference of type 'additional'. 0 otherwise.

=cut

#########################################################################
sub has_additional_diffs
{
    my $self = shift;
    my @keys = $self->get_additional_keys();
    if( ! @keys ){
        return 0;
    }
    return 1;
}


#########################################################################

=head2 C<has_not_equal_diffs>

  my $result = $cdiff->has_not_equal_diffs();

Returns 1 if there is any difference of type 'not_equal'. 0 otherwise.

=cut

#########################################################################
sub has_not_equal_diffs
{
    my $self = shift;
    my @keys = $self->get_not_equal_keys();
    if( ! @keys ){
        return 0;
    }
    return 1;
}


#########################################################################

=head2 C<get_before_fname>

  my $result = $cdiff->get_before_fname();

Returns file name which was a source of data for before collection.

=cut

#########################################################################
sub get_before_fname
{
    my $self = shift;
    return $self->{ 'before' }->{ 'data_file' };
}


#########################################################################

=head2 C<get_after_fname>

  my $result = $cdiff->get_after_fname();

Returns file name which was a source of data for after collection.

=cut

#########################################################################
sub get_after_fname
{
    my $self = shift;
    return $self->{ 'after' }->{ 'data_file' };
}

sub print_line_of_text
{
    my $self = shift;
    my $text = shift;

    if( not exists $self->{ 'header_printed' } ){
        if( $self->{ 'report_header' } ){
            print "". $self->{ 'report_header' } . 
                  " " . $self->get_before_fname() .
                  " " . $self->get_after_fname() . "\n";
         }
         my $cols = $self->{ 'after' }->get_columns();
         print "SCHEMA: " . join( "\t", @$cols ) . "\n";
         $self->{ 'header_printed' } = 1;     
    }
    print "$text\n";
}
            
        

1;
__END__

=head1 INTERNAL DATA STRUCTURE

Below you can find something, which is my pathetic attempt to create 
a readable diagram. It is supposed to show a hierarchy of internal data
structure. I am open to suggestions how to make it look more readable

  $self->
      |
      |->{ before } = LRpt::Collection object
      |->{ after }  = LRpt::Collection object
      |->{ report_header } = $header
      |->{ print_what }   = $type_of_output
      |->{ differences }
      |   |->{ $key_value1 }
      |   |   |->{ diff_type } = "missing"
      |   |   |->{ row } = $row1
      |   |......................
      |   |->{ $key_valueX }
      |   |   |->{ diff_type } = "additional"
      |   |   |->{ row } = $rowX
      |   |......................
      |   |->{ $key_valueY }
      |   |   |->{ diff_type } = "not_equal"
      |   |   |->{ diffs }
      |   |   |   |->{ $col1 }
      |   |   |   |   |->{ before } = $value_before1
      |   |   |   |   |->{ after } = $value_after1
      |   |   |   |.................................
      |   |   |   |->{ $colK }
      |   |   |   |   |->{ before } = $value_beforeK
      |   |   |   |   |->{ after } = $value_afterK
      |   |   |->{ before_row } = $before_row
      |   |   |->{ after_row } = $after_row

Meaning of data members:

=over 4

=item before

Reference to a I<before> L<C<LRpt::Collection>|LRpt::Collection> object

=item after

Reference to a I<after> L<C<LRpt::Collection>|LRpt::Collection> object

=item key

Name of a row key used in both L<C<LRpt::Collection>|LRpt::Collection> 
objects for row retrieval.
It is expected that the key is defined in both collections and it has the same
definition in both. If it doesn't then, to be honest, I don't know what is 
going to happen.

=item report_header

Text to be printed on standard output when comparison of collections starts

=item print_what

Mode of printing

=item differences

Reference to a data structure containing information about all found 
differences. If I<after> and I<before> rows are identical, no information
is stored here. If they both exist, but there are some differences in
values in columns, or one of them does not exist, 
then a new element is created. 

If both rows exists but they are different, then a hash key is added. The
value of the key is row key of compared rows. The hash value, pointed by a key
is references to a new hash. The hash contains four elements:

* B<diff_type> - Type of the difference. In that case it is I<not_equal>

* B<diffs> - A reference to a new hash. Keys of this new hash are names of
columns, which are different in I<before> and I<after> rows. Values are
references to hashes keeping I<before> and I<after> value of a column.

* B<before_row> - Reference to a I<before> row.

* B<after_row> - Reference to an I<after> row.

If I<after> row does not exists, then a key value is a row key of the 
I<before> row.
The I<diff_type> is I<missing>. I<row> element points to I<before> row.

If I<before> row does not exists, then a key value is a row key of the 
I<after> row.
The I<diff_type> is I<additional>. I<row> element points to I<after> row.

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


