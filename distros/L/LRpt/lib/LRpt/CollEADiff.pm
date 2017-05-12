##############################################################################
# 
# $Id: CollEADiff.pm,v 1.10 2006/02/10 22:32:16 pkaluski Exp $
# $Name: Stable_0_16 $
# 
# Object of this class is used to compare a set of expected rows with a 
# set of actual rows from the database.
#
# $Log: CollEADiff.pm,v $
# Revision 1.10  2006/02/10 22:32:16  pkaluski
# Major redesign in progress. Updated POD. Works.
#
# Revision 1.9  2006/01/14 21:08:25  pkaluski
# New design of lreport.
#
# Revision 1.8  2006/01/14 12:52:33  pkaluski
# New tool design in progress
#
# Revision 1.7  2005/09/02 19:59:31  pkaluski
# Next refinement of PODs. Ready for distribution. Some work on clarity still to be done
#
# Revision 1.6  2005/09/01 20:00:18  pkaluski
# Refined PODs. Separation between public and private methods still to be done
#
# Revision 1.5  2005/01/23 07:25:43  pkaluski
# Pod documentation added
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
# Revision 1.1.1.1  2004/10/02 11:30:56  pkaluski
# Changed the naming convention. All packages start with LRpt
#
#
#
#############################################################################
package LRpt::CollEADiff;
use strict;
use LRpt::CollUnkeyed;
use XML::Simple;
use LRpt::CollDiff;

@LRpt::CollEADiff::ISA = qw( LRpt::CollDiff );

=head1 NAME

LRpt::CollEADiff - A module for comparing collection of expectations with 
a collection of actual data taken from the database.

=head1 DESCRIPTION

This class is a part of L<C<LRpt>|LRpt> library.
Object of this class is used to compare a set of expected rows with a 
set of actual rows from the database. It subclasses 
L<C<LRpt::CollDiff>|LRpt::CollDiff>. However, there are some important
 differences. During that type of comparison only columns which are present
 in 'expected' collection are compared. If there is a column, which
 is not present in 'expected' but is present in 'actual', the comparison of
 a column is skipped.

Since this class inherits from L<C<LRpt::CollDiff>|LRpt::CollDiff>, 
in its core it uses the notion of 'before' and 'after' collection. 
In its interface with the user it uses notions of:

=over 4

=item expected collection

Collection of expected rows. When using L<C<LRpt::CollDiff>|LRpt::CollDiff> 
functions it is treated as 'before' collection 

=item actual collection

Collection of actual rows. When using L<C<LRpt::CollDiff>|LRpt::CollDiff> 
functions it is treated as 'after' collection 

=back

The class also use a notion of comparing rules. Comparing rules help to
specify what to do, when some expectations are not defined. 
Sometimes a defualt value may be used. Sometimes the comparison should
be terminated (if a value of important column is missing).

=head1 METHODS

=cut

#############################################################################

=head2 C<new>

  my $cdiff = LRpt::CollEADiff->new( expected => $exp_coll,
                                     actual   => $act_coll,
                                     key      => $key,
                                     comparing_rules_file => $rules_fname,
                                     comparing_rules      => $rules,
                                     logger_stream => *STREAM );

Constructor. Initializes internal structures. Meaning of parameters:

=over 4

=item C<expected>

Reference to a L<C<LRpt::Collection>|LRpt::Collection> object, 
which contain expectations for rows.

=item C<actual>

Reference to a L<C<LRpt::Collection>|LRpt::Collection> object, 
which contain actual rows. 

=item C<key>

Name of a L<C<LRpt::Collection>|LRpt::Collection> key used for rows ordering 

=item C<comparing_rules_file>

Name of the file containing comparing rules. Does not have to be specified 
if C<comparing_rules parameter> is given. 

=item C<comparing_rules>

Reference to a structure containing comparing rules. Does not have to 
be specified if C<comparing_rules_file> parameter is given. 

=item C<logger_stream> [optional]

Reference to an output logger stream

=back

=cut

############################################################################
sub new
{
    my $proto  = shift;
    my %params = @_; 

    my $class = ref( $proto ) || $proto;

    my $self = {};
    bless( $self, $class );
    if( !$params{ 'expected' } ){
        die "No expected collection given";
    }else{
        $self->{ 'before' } = $params{ 'expected' };
    }
    if( !$params{ 'actual' } ){
        die "No actual collection given";
    }else{
        $self->{ 'after' } = $params{ 'actual' };
    }

    $self->init_rules( %params );

    if( $params{ 'key' } ){
        $self->{ 'key' } = $params{ 'key' };
    }
    if( $params{ 'logger_stream' } ){
        $self->{ 'logger_stream' } = $params{ 'logger_stream' };
    }
    return $self;
}


#########################################################################

=head2 C<init_rules>

  $ceadiff->init_rules( comparing_rules       => $cmp_rules,
                        comparing_rules_file  => $cmp_rules_file );

Initializes comparing rules structure. If C<comparing_rules> parameter is 
given, C<$cmp_rules> should point to a compring rules structure. If
C<comparing_rules_file> is given, rules are loaded from the file 
C<$cmp_rules_file>

=cut

#########################################################################
sub init_rules
{
    my $self   = shift;
    my %params = @_;

    my $cmp_rules = "";
    if( $params{ "comparing_rules_file" } ){
        $cmp_rules = XMLin( $params{ 'comparing_rules_file' } );
    }
    if( $params{ "comparing_rules" } ){
        if( $cmp_rules ){
            die "Cannot use comparing_rules and comparing_rules_file " .
                "parameters at the same time";
        }else{
            $cmp_rules = $params{ "comparing_rules" };
        } 
    }
    if( !$cmp_rules ){
        die "No comparing rules specified for expected_actual comparing ".
            "mode";
    }
    $self->{ 'comparing_rules' } = $cmp_rules;
}


#########################################################################

=head2 C<compare_rows>

  $ceadiff->compare_rows( $key_name );

Compare expected and actual rows, which have the same key value given in
C<$key_value>. If a difference is found for any column, 'not_equal' type of
difference is reported.

=cut

#########################################################################
sub compare_rows
{
    my $self = shift;
    my $key  = shift;
    my $expected_row = $self->get_expected_row( $key );
    my $actual_row  = $self->get_actual_row( $key );

    foreach my $col ( keys %{ $expected_row } ){
        $expected_row->{ $col } =~ s/\s+$//;
        $actual_row->{ $col } =~ s/\s+$//;
        if( $expected_row->{ $col } ne $actual_row->{ $col } ){
            $self->add_diff_not_equal( $key, 
                                   'column'    => $col,
                                   'before'    => $expected_row->{ $col },
                                   'after'     => $actual_row->{ $col } );
        }
    }
}


#########################################################################

=head2 C<compare_collections>

  $ceadiff->compare_collections();

Main public function. Runs the whole comparing machinery.

=cut

#########################################################################
sub compare_collections
{
    my $self = shift;
    $self->set_expectations();
    $self->SUPER::compare_collections( 'nothing' );
    $self->compare_with_unkeyed_rows();
}


#########################################################################

=head2 C<compare_with_unkeyed_rows>

  $ceadiff->compare_with_unkeyed_rows();

Called when keyed comparison is done and there are still some actual rows
left. Compares those actual rows with expectation rows, for which key is
not defined.

=cut

#############################################################################
sub compare_with_unkeyed_rows
{
    my $self = shift;
    my @additional_rows = $self->get_additional_rows();
    my $unkeyed_coll = $self->get_unkeyed_coll();

    if( $unkeyed_coll->is_empty() ){
        return;
    }

    foreach my $add_row ( @additional_rows ){
        if( $unkeyed_coll->find_matching_row( $add_row ) ){
            $self->remove_diff_additional( $add_row ); 
        }
    } 
    #
    # If any unkeyed row remained, it should be reported as missing 
    # expectation
    #
    my @remaining_rows = $unkeyed_coll->get_remaining_rows();
    $self->{ 'differences_uk' } = [];
    foreach my $r_row ( @remaining_rows ){
        $self->add_diff_missing_unkeyed( $r_row );
    }
}


#########################################################################

=head2 C<get_unkeyed_coll>

  my @unk_colls = $ceadiff->get_unkeyed_coll();

Returns collection of expectation rows, for which not have whole key 
populated

=cut

#########################################################################
sub get_unkeyed_coll
{
    my $self = shift;

    return $self->{ 'before' }->get_unkeyed_coll();
}


#########################################################################

=head2 C<get_diffs_missing_unkeyed>

  my @rows_info = $ceadiff->get_diffs_missing_unkeyed();

Returns information about all expected, 'unkeyed' rows for which there is
no actual rows.

=cut

#########################################################################
sub get_diffs_missing_unkeyed
{
    my $self = shift;
    my @rows_info = ();
    if( not exists $self->{ 'differences_uk' } ){
        return ();
    }
    else{
        foreach my $diff ( @{ $self->{ 'differences_uk' } } ){
            if( $diff->{ 'diff_type' } eq "missing_unkeyed" ){
                push( @rows_info, $diff->{ 'rows' } );
            }
        }
    }
    return @rows_info;    
}


#########################################################################

=head2 C<add_diff_missing_unkeyed>

  $ceadiff->add_diff_missing_unkeyed( $row_info );

Stores information that there is no match for an 'unkeyed' expected row.

=cut

##########################################################################
sub add_diff_missing_unkeyed
{
    my $self        = shift;
    my $row_info    = shift;

    push( @{ $self->{ 'differences_uk' } },
               { 'diff_type' => "missing_unkeyed",
                 'rows' => $row_info } );
}


#########################################################################

=head2 C<set_expectations>

  $ceadiff->set_expecations();

Using comparing rules and a set of expectations, creates a set of row, which
will be used in further processing as a expected collection

=cut

#########################################################################
sub set_expectations
{
    my $self     = shift;
    my $exp_coll = $self->{ 'before' };
    my $all_rows = $exp_coll->get_keyed_rows();

    foreach my $key ( keys %{ $all_rows } ){
        my $row = $all_rows->{ $key };
        my $pop_row = $self->create_exp_row( $row );
        $all_rows->{ $key } = $pop_row;
    }
}


#########################################################################

=head2 C<create_exp_row>

  my $exp_row = $ceadiff->create_exp_row( $existing_values );

Basing on comparison rules and given expected values,
creates a row of expected values. 

=cut

#########################################################################
sub create_exp_row 
{
    my $self            = shift;
    my $existing_values = shift;
    my $col = "";
    my $exp_row = {};

    my %warnings = ();
    
    my $cmp_rls = $self->{ 'comparing_rules' };
    #
    # You should iterate through the sum of columns present in the row and
    # in the comparing rules file.
    #
    my @all_cols = ( keys %$cmp_rls , keys %$existing_values );
    foreach my $col ( @all_cols ){
        if( !$existing_values->{ $col } ){
            # If there is no rule for a column...
            if( !( keys %{ $cmp_rls->{ $col } } ) ){
                next;
            }
            elsif( $cmp_rls->{ $col }->{ 'if_no_value' } eq "skip_and_warn" )
            { 
                $warnings{ $col } = { warning => "skip_and_warn" };
                $self->log_msg( 
                    "No expected value specified for field '$col' ".
                    $self->descr_row_location( $existing_values ) );
            }
            elsif( $cmp_rls->{ $col }->{ 'if_no_value' } eq "die" )
            { 
                $self->log_msg( 
                         "No expected value specified for field '$col' " .
                         $self->descr_row_location( $existing_values ) . 
                         ". The field is too important. Terminating" );
                die "No expected value for $col";
            }
            elsif( $cmp_rls->{ $col }->{ 'if_no_value' } eq "use_default" )
            { 
                $exp_row->{ $col } = $cmp_rls->{ $col }->{ 'default' };
            }
            elsif( $cmp_rls->{ $col }->{ 'if_no_value' } 
                                               eq "use_default_and_warn" )
            { 
                $exp_row->{ $col } = $cmp_rls->{ $col }->{ 'default' };
                $warnings{ $col } = 
                               { warning => "use_default_and_warn",
                                 value => $cmp_rls->{ $col }->{ default } };

                $self->log_msg( 
                           "No expected value specified for field '$col' " .
                           $self->descr_row_location( $existing_values ) . 
                           ". Using default value : '" . 
                           $cmp_rls->{ $col }->{ 'default' } . "'" );
            }
            elsif( $cmp_rls->{ $col }->{ 'if_no_value' } eq "skip" )
            { 
                next;
            }else{
                die "Unknown type of if_no_value action : ".
                    $cmp_rls->{ $col }->{ 'if_no_value' };
                $self->log_msg( "Unknown type of if_no_value action : ".
                                $cmp_rls->{ $col }->{ 'if_no_value' } );
            }
        }else{
            $exp_row->{ $col } = $existing_values->{ $col };
        }
    }
    return $exp_row;
}


#########################################################################

=head2 C<descr_row_location>

  my $loc_str = $ceadiff->descr_row_location( $row );

Creates a string describing a row - collection name and row's key value.

=cut

#########################################################################
sub descr_row_location
{
    my $self = shift;
    my $row  = shift;
    return "in a row with a key value '".
           $self->{ 'after' }->get_key_value( $row ) . "' " . 
           "from collection '" . 
           $self->{ 'after' }->get_name() . "'";
}


#########################################################################

=head2 C<get_expected_row>

  my $row = $ceadiff->get_expected_row( $key_value );

Returns expected row with a given key value.

=cut

#########################################################################
sub get_expected_row
{
    my $self = shift;
    my $key  = shift;
    return $self->get_before_row( $key );

}


#########################################################################

=head2 C<get_actual_row>

  my $row = $ceadiff->get_actual_row( $key_value );

Returns actual row with a given key value.

=cut

#########################################################################
sub get_actual_row
{
    my $self = shift;
    my $key  = shift;
    return $self->get_after_row( $key );
} 


#########################################################################

=head2 C<set_log_stream>

  $ceadiff->set_log_stream( $fh );

Sets a logging stream.

=cut

#########################################################################
sub set_log_stream
{
    my $self = shift;
    my $fh   = shift;
    $self->{ 'logger_stream' } = $fh;
}


#########################################################################

=head2 C<log_msg>

  $ceadiff->log_msg( $message );

Puts a message in the log file.

=cut

#########################################################################
sub log_msg
{
    my $self    = shift;
    my $message = shift;
    if( ! $self->{ 'logger_stream' } ){
        return;
    }
    my $fh = $self->{ 'logger_stream' };
    print $fh "" . localtime() . "--> $message\n";
} 

#########################################################################

=head2 C<create_xml_report>

  $ceadiff->create_xml_report( $indent );

Creates a report of comparison in XML format. I<$indent> is a number
of indentation spaces.

=cut

#########################################################################
sub create_xml_report
{
    my $self = shift;
    my $indent = shift;
    print " " x $indent . "<" . $self->{ 'after' }->get_name() . ">\n";
    $self->missing_to_xml( $indent + 4 );
    $self->additional_to_xml( $indent + 4 );
    $self->not_equal_to_xml( $indent + 4 );
    $self->unmatched_to_xml( $indent + 4 );
    print " " x $indent . "</" . $self->{ 'after' }->get_name() . ">\n";
}

#########################################################################

=head2 C<missing_to_xml>

  $ceadiff->missing_to_xml( $indent );

converts to XML format report on missing rows. I<$indent> is a number
of indentation spaces.

=cut

#########################################################################
sub missing_to_xml
{
    my $self   = shift;
    my $indent = shift;
    my %miss_keys = (); 
    @miss_keys{ $self->get_missing_keys() } = 1;
    my @keys = sort keys %miss_keys;
    if( @keys ){
        print " " x $indent . "<missing>\n";
        my $cols = $self->{ 'before' }->get_columns();
        foreach my $key( @keys ){
            print " " x ( $indent + 4 ) .  "<row>\n";
            $self->xmlize_row( $self->get_before_row( $key ), 
                               $cols, 
                               $indent + 8 );
            print " " x ( $indent + 4 ) .  "</row>\n";
        }
        print " " x $indent . "</missing>\n";
    }
}

#########################################################################

=head2 C<additional_to_xml>

  $ceadiff->additional_to_xml( $indent );

converts to XML format report on additional rows. I<$indent> is a number
of indentation spaces.

=cut

#########################################################################
sub additional_to_xml
{
    my $self = shift;
    my $indent = shift;
    my %add_keys = (); 
    @add_keys{ $self->get_additional_keys() } = 1;
    my @keys = sort keys %add_keys;
    if( @keys ){
        print " " x $indent . "<additional>\n";
        my $cols = $self->{ 'after' }->get_columns();
        foreach my $key( @keys ){
            print " " x ( $indent + 4 ) .  "<row>\n";
            $self->xmlize_row( $self->get_after_row( $key ), 
                               $cols,
                               $indent + 8 );
            print " " x ( $indent + 4 ) .  "</row>\n";
        }
        print " " x $indent . "</additional>\n";
    }
}

#########################################################################

=head2 C<not_equal_to_xml>

  $ceadiff->not_equal_to_xml( $indent );

converts to XML format report on not equal rows. I<$indent> is a number
of indentation spaces.

=cut

#########################################################################
sub not_equal_to_xml
{
    my $self = shift;
    my $indent = shift;
    my %ne_keys = (); 
    @ne_keys{ $self->get_not_equal_keys() } = 1;
    my @keys = sort keys %ne_keys;
    if( @keys ){
        print " " x $indent . "<not_equal>\n";
        my $cols = $self->{ 'after' }->get_columns();
        my @key_cols = $self->{ 'after' }->get_key_columns();
        print " " x ( $indent + 4 ) .  "<key>\n";
        foreach my $key ( @key_cols ){
            print " " x ( $indent + 8 ) .  "<$key/>\n";
        }
        print " " x ( $indent + 4 ) .  "</key>\n";
        foreach my $key( @keys ){
            print " " x ( $indent + 4 ) .  "<row>\n";
            my @diff_cols = $self->get_diff_columns( $key );
            $self->xmlize_row_pair( $self->get_expected_row( $key ),
                                    $self->get_actual_row( $key ),
                                    $cols,
                                    \@diff_cols,
                                    $indent + 8 );
            print " " x ( $indent + 4 ) .  "</row>\n";
        }
        print " " x $indent . "</not_equal>\n";
    }
}

#########################################################################

=head2 C<xmlize_row>

  $ceadiff->xmlize_row( $row, $cols, $indent );

Converts to XML format contents of a given row. I<$indent> is a number
of indentation spaces.

=cut

#########################################################################
sub xmlize_row
{
    my $self = shift;
    my $row = shift;
    my $cols = shift;
    my $indent = shift;

    foreach my $col ( @$cols ){
        if( exists $row->{ $col } ){
            print " " x $indent . "<$col>" . $row->{ $col } . "</$col>\n";
        }
    }
}

#########################################################################

=head2 C<xmlize_row_pair>

  $ceadiff->xmlize_row_pair( $exp_row, $act_row, $cols, $diff_cols, $indent );

Converts to XML format contents of expected-actual rows. I<$indent> is a number
of indentation spaces.

=cut

#########################################################################
sub xmlize_row_pair
{
    my $self = shift;
    my $exp_row = shift;
    my $act_row = shift;
    my $cols = shift;
    my $diff_cols = shift;
    my $indent = shift;

    my %diffs = ();
    @diffs{ @$diff_cols } = 1;

    foreach my $col ( @$cols ){
        if( exists $exp_row->{ $col } ){
            print " " x $indent . "<$col>";
            if( exists $diffs{ $col } ){
                print "\n" . " " x ( $indent + 4 ) . 
                      "<expected>" . $exp_row->{ $col } .
                                 "</expected>\n"; 
                print " " x ( $indent + 4 ) . 
                      "<actual>" . $act_row->{ $col } .
                                 "</actual>\n"; 
                print " " x $indent . "<$col>\n";
            }else{
                print "" . $exp_row->{ $col } . "</$col>\n";
            }
        }
    }
}

#########################################################################

=head2 C<unmatched_to_xml>

  $ceadiff->unmatched_to_xml( $indent );

Converts to XML format contents of unmatched rows. I<$indent> is a number
of indentation spaces.

=cut

#########################################################################
sub unmatched_to_xml
{
    my $self = shift;
    my $indent = shift;
    my @rows_info = $self->get_diffs_missing_unkeyed();    
    if( @rows_info ){
        print " " x $indent . "<unmatched>\n";
        foreach my $row_info ( @rows_info ){
            if( $row_info->{ 'quantity' } == 0 ){
                next;
            }
            my %unm_cols = ();
            @unm_cols{ @{ $row_info->{ 'unm_cols' } } } = 1;
            print " " x ( $indent + 4 ) . "<row count=\"" . 
                             $row_info->{ 'quantity' } . "\">\n";
            my $row = $row_info->{ 'row' };
            my @unord_cols = keys %$row;
            my @cols = @{ $self->{ 'after' }->order_columns( \@unord_cols ) };
            foreach my $col ( @cols ){
                print " " x ( $indent + 8 ) . "<$col>";
                if( exists $unm_cols{ $col } ){
                    print "\n" . " " x ( $indent + 12 ) . "<unmatched>" . 
                          $row->{ $col } . "</unmatched>\n";
                    print " " x ( $indent + 8 ) . "</$col>\n";
                }else{                     
                    print "" . $row->{ $col } . "</$col>\n";
                }
            }
            print " " x ( $indent + 4 ) . "</row>\n";
        }
        print " " x $indent . "</unmatched>\n";
    }
}


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
