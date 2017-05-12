#!/usr/bin/perl
#
# $Header: /Users/claude/fuzz/lib/Genezzo/Plan/RCS/MakeAlgebra.pm,v 7.2 2006/02/23 07:53:06 claude Exp claude $
#
# copyright (c) 2005 Jeffrey I Cohen, all rights reserved, worldwide
#
#
package Genezzo::Plan::MakeAlgebra;
use Genezzo::Util;

use strict;
use warnings;
use warnings::register;

use Carp;

our $VERSION;

BEGIN {
    $VERSION = do { my @r = (q$Revision: 7.2 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r }; # must be all one line, for MakeMaker

}

our $GZERR = sub {
    my %args = (@_);

    return 
        unless (exists($args{msg}));

    if (exists($args{self}))
    {
        my $self = $args{self};
        if (defined($self) && exists($self->{GZERR}))
        {
            my $err_cb = $self->{GZERR};
            return &$err_cb(%args);
        }
    }

    carp $args{msg}
        if warnings::enabled();
    
};


sub new 
{
#    whoami;
    my $invocant = shift;
    my $class = ref($invocant) || $invocant ; 
    my $self = { };
    
    my %args = (@_);

    if ((exists($args{GZERR}))
        && (defined($args{GZERR}))
        && (length($args{GZERR})))
    {
        # NOTE: don't supply our GZERR here - will get
        # recursive failure...
        $self->{GZERR} = $args{GZERR};
        my $err_cb     = $self->{GZERR};
        # capture all standard error messages
        $Genezzo::Util::UTIL_EPRINT = 
            sub {
                &$err_cb(self     => $self,
                         severity => 'error',
                         msg      => @_); };
        
        $Genezzo::Util::WHISPER_PRINT = 
            sub {
                &$err_cb(self     => $self,
#                         severity => 'error',
                         msg      => @_); };
    }

#    return undef
#        unless (_init($self, %args));

    return bless $self, $class;

} # end new

sub Convert # public
{
#    whoami;
    my $self = shift;
    my %required = (
                    parse_tree => "no parse tree!"
                    );

    my %args = ( # %optional,
                @_);

    return 0
        unless (Validate(\%args, \%required));

    my $parse_tree = $args{parse_tree};

    my $current_qb = {qb => 0};

    # Note: handle "query blocks" for non-query statements,
    # e.g.  UPDATE, DELETE (but not INSERT)

    unless (exists($parse_tree->{sql_query}))
    {
        $current_qb->{qb} = 1;

        if (exists($parse_tree->{sql_insert}))
        {

#                && exists($parse_tree->{sql_insert}->{insert_values})
#                && (ref($parse_tree->{sql_insert}->{insert_values}) ne 'ARRAY')
#                )

            # NOTE: create first query block in insert_tabinfo subtree
            # (which is a sibling, not a parent of subtree
            # "insert_values") in order to have separate, non-nested
            # query blocks
            my $op1 = $parse_tree->{sql_insert}->[0];
            $op1->{insert_tabinfo}->{query_block} = 1;
        }
        else
        {
            $parse_tree->{query_block} = 1;
        }
    }
    my $alg = convert_algebra($parse_tree, $current_qb);

    # label parent query blocks
    $current_qb = {qb => 0, qb_parent => []};

    $alg = $self->_label_qb($alg, $current_qb);
    return $alg;
}

# recursive function to convert parse tree to relational algebra
sub convert_algebra # private
{
#    whoami;
    my ($sql, $current_qb) = @_;

    # recursively convert all elements of array
    if (ref($sql) eq 'ARRAY')
    {
        my $maxi = scalar(@{$sql});
        $maxi--;
        for my $i (0..$maxi)
        {
            $sql->[$i] = convert_algebra($sql->[$i], $current_qb);
        }

    }
    if (ref($sql) eq 'HASH')
    {
        keys( %{$sql} ); # XXX XXX: need to reset expression!!
        # recursively convert all elements of hash, but treat
        # sql_select specially

        while ( my ($kk, $vv) = each ( %{$sql})) # big while
        {
            if ($kk !~ m/^sql_select$/)
            {
                $sql->{$kk} = convert_algebra($vv, $current_qb);
            }
            else
            {
                # add a unique id for each query block
                my $qb_num = $current_qb->{qb};
                $qb_num++;
                $current_qb->{qb}   = $qb_num;
                $sql->{query_block} = $qb_num; 
                
                # convert SQL SELECT to a basic relational algebra,
                # (PROJECT ( FILTER (THETA-JOIN)))
                #
                # First, perform a theta-join of the FROM clause
                # tables.
                #
                # Next, filter out the rows that don't satisfy the
                # WHERE clause.
                #
                # Project the required SELECT list entries as
                # output.
                #
                # Finally, perform grouping and filter the results of
                # the HAVING clause.  
                #

                my @op_list = qw(
                                 theta_join    from_clause
                                 filter        where_clause
                                 project       select_list
                                 alg_group     groupby_clause
                                 hav           having_clause
                                 );

                # build a list of each relational algebra operation and
                # the associated SQL statement clause.
                my %alg_oper_map = @op_list;
                my %alg_oper;

                while (my ($operkey, $operval) = each (%alg_oper_map))
                {
                    # associate each operation with its operands.
                    # Note that some operands might contain SQL
                    # SELECTs, so process them recursively with
                    # convert_algebra.

                    $alg_oper{$operkey} = convert_algebra($vv->{$operval}, 
                                                          $current_qb
                                                          );
                }

                # build a nested hash of relational algebra
                # operations, starting with theta-join as the
                # innermost operator.
                #
                # The simplest output is just a degenerate
                # theta-join of a single table.
                # The most complex output is a 
                #  (filter(groupby(project(filter(theta-join)))))
                # 
                # More complicated combinations arise from compound
                # statements using set operations (UNION, INTERSECT)
                # or subqueries.

                my $hashi;
                my $prev;
                my $toggle = -1; # get every other entry, 
                                 # ie get the hash keys in order
              L_all_opers:
                for my $oper (@op_list)
                {
                    $toggle *= -1;
                    next L_all_opers if ($toggle) < 1;

                    my $filter_type;
                    $filter_type = undef;
                    
                    if ($oper eq "theta_join")
                    {
                        # build first (innermost) hash entry
                        # 
                        # theta_join => 
                        #   from_clause => converted(from_clause)
                        # 
                        
                        $hashi = 
                        {
                            alg_op_name => $oper,
                            $alg_oper_map{$oper} => $alg_oper{$oper}
                        };
                        $prev = $oper;
                    }
                    else
                    {
                        # cleanup the tree: use more consistent names
                        # for operators and operands.
                        my $oper_alias   = $oper;
                        my $operands_key = $alg_oper_map{$oper};

                        if ($oper eq "filter")
                        {
                            # use generic search_cond, vs where_clause
                            $operands_key = "search_cond";
                            $filter_type  = "WHERE";

                            # ignore empty list
                            my $a1 = $alg_oper{$oper};
                            if ((ref($a1) eq 'ARRAY')
                                && (0 == scalar(@{$a1})))
                            {
                                next L_all_opers;
                            }
                        }
                        elsif ($oper eq "alg_group")
                        {
                            # ignore empty list
                            my $a1 = $alg_oper{$oper};
                            if ((ref($a1) eq 'ARRAY')
                                && (0 == scalar(@{$a1})))
                            {
                                next L_all_opers;
                            }
                        }
                        elsif ($oper eq "hav")
                        {
                            # having is just a filter, and having clause
                            # is just a search condition
                            $oper_alias   = "filter";
                            $operands_key = "search_cond";
                            $filter_type  = "HAVING";

                            # ignore empty list
                            my $a1 = $alg_oper{$oper};
                            if ((ref($a1) eq 'ARRAY')
                                && (0 == scalar(@{$a1})))
                            {
                                next L_all_opers;
                            }

                        }
                        elsif ($oper eq "project")
                        {
                            # if performing a "SELECT * FROM..." then
                            # project is superfluous

                            if (
                                   (exists($vv->{all_distinct}))
                                && (ref($vv->{all_distinct}) eq 'ARRAY')
                                && (0 == scalar(@{$vv->{all_distinct}})))
                            {
                                # XXX XXX XXX XXX XXX XXX XXX XXX 
                                # XXX XXX XXX XXX XXX XXX XXX XXX 
                                # Keep the project for "select *"
                                # because the optimizer might rewrite
                                # the query and add extra tables to
                                # the FROM list.  Expand the "*" to
                                # only include the columns from the
                                # original FROM list.
                                # XXX XXX XXX XXX XXX XXX XXX XXX 
                                # XXX XXX XXX XXX XXX XXX XXX XXX 
                                if (0 &&
                                    exists($vv->{select_list})
                                    && (!ref($vv->{select_list}))
                                    && ($vv->{select_list} eq 'STAR'))
                                {
                                    next L_all_opers;
                                }
                            }
                        }

                        # build new hash, wrapping previous.
                        # e.g., if had theta-join, and outer oper
                        # is a filter, we get:
                        # filter => (search_cond => ...
                        #            theta_join => (...)
                        #           )

                        $hashi = 
                        {
                            alg_op_name   => $oper_alias,
                            $operands_key => $alg_oper{$oper},
                            alg_oper_child  => $hashi
                        };

                        if ($oper eq "project")
                        {
                            # project has additional all/distinct attribute

                            $hashi->{all_distinct} =
                                $vv->{all_distinct};
                        }
                        if ($oper_alias eq "filter")
                        {
                            # mark filter if from WHERE or HAVING
                            # clauses - useful for checking aggregate
                            # functions (which cannot be in WHERE
                            # clause)
                            $hashi->{alg_filter_type} = $filter_type
                                if (defined($filter_type));
                        }

                        $prev = $oper_alias;
                        
                    }
                } # end for oper list

                $sql->{$kk} = $hashi;

            } # end else
        } # end big while
    }

    return $sql;
} # end convert_algebra

sub _label_qb # private
{
#    whoami;

    # NOTE: get the current subroutine name so it is easier 
    # to call recursively
    my $subname = (caller(0))[3];

    my $self = shift;
    # generic tree of hashes/arrays
    my ($genTree, $current_qb) = @_;

    # recursively convert all elements of array
    if (ref($genTree) eq 'ARRAY')
    {
        my $maxi = scalar(@{$genTree});
        $maxi--;
        for my $i (0..$maxi)
        {
            $genTree->[$i] = $self->$subname($genTree->[$i], $current_qb);
        }
    }
    if (ref($genTree) eq 'HASH')
    {
        keys( %{$genTree} ); # XXX XXX: need to reset expression!!
        # recursively convert all elements of hash, but treat
        # table name specially

        my $qb_setup = 0; # TRUE if top hash of query block

        if (exists($genTree->{sql_select})
            && exists($genTree->{query_block}))
        {
            $qb_setup = 1;

            $current_qb->{qb} = $genTree->{query_block};

            if (scalar(@{$current_qb->{qb_parent}}))
            {
                # setup list of parent query blocks to current block
                my @foo = @{$current_qb->{qb_parent}};
                $genTree->{query_block_parent} = \@foo;
            }
            # push on the front
            unshift @{$current_qb->{qb_parent}}, $genTree->{query_block};
        }

        while ( my ($kk, $vv) = each ( %{$genTree})) # big while
        {
            if ($kk !~ m/^search_cond$/)
            {
                $genTree->{$kk} = $self->$subname($vv, $current_qb);
            }
            else # search_cond
            {
                $genTree->{$kk} = $self->$subname($vv, $current_qb);
            } # end search_cond
        } # end big while

        if ($qb_setup)
        {
            # pop from the front
            shift @{$current_qb->{qb_parent}};
        }
    } # end HASH
    return $genTree;
}


END { }       # module clean-up code here (global destructor)

## YOUR CODE GOES HERE

1;  # don't forget to return a true value from the file

__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Genezzo::Plan::MakeAlgebra - Convert a SQL parse tree to relational algebra

=head1 SYNOPSIS

use Genezzo::Plan::MakeAlgebra;


=head1 DESCRIPTION

This module converts a SQL parse tree into a set of relational algebra
operations.

=head1 ARGUMENTS

=head1 FUNCTIONS

=over 4

=item Convert

=back

=head2 EXPORT

=over 4


=back


=head1 LIMITATIONS


=head1 TODO

=over 4

=item need additional work for non-query operations/special cases

=back

=head1 AUTHOR

Jeffrey I. Cohen, jcohen@genezzo.com

=head1 SEE ALSO

L<perl(1)>.

Copyright (c) 2005 Jeffrey I Cohen.  All rights reserved.

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

Address bug reports and comments to: jcohen@genezzo.com

For more information, please visit the Genezzo homepage 
at L<http://www.genezzo.com>

=cut
