#!/usr/bin/perl
#
# $Header: /Users/claude/fuzz/lib/Genezzo/Plan/RCS/QueryRewrite.pm,v 1.7 2006/03/01 08:41:16 claude Exp claude $
#
# copyright (c) 2005,2006 Jeffrey I Cohen, all rights reserved, worldwide
#
#
package Genezzo::Plan::QueryRewrite;
use Genezzo::Util;

use strict;
use warnings;
use warnings::register;

use Carp;

our $VERSION;

BEGIN {
    $VERSION = do { my @r = (q$Revision: 1.7 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r }; # must be all one line, for MakeMaker

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

sub _init
{
    my $self = shift;
    my %args = @_;

    return 0
        unless (exists($args{plan_ctx})
                && defined($args{plan_ctx}));

    $self->{plan_ctx} = $args{plan_ctx};

    return 1;

}


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

    return undef
        unless (_init($self, %args));

    return bless $self, $class;

} # end new

sub QueryRewrite
{
    my $self = shift;
    
    my %required = (
                    algebra   => "no algebra !",
                    statement => "no sql statement !",
                    dict      => "no dictionary !"
                    );
    
    my %args = ( # %optional,
                 @_);
    
    return undef
        unless (Validate(\%args, \%required));

    my $algebra = $args{algebra};

    my $err_status;

    my $qrw1 = {}; # type check tree context for tree walker
    # NOTE: we stashed the statement handle in the top of the 
    # algebra when we did typechecking earlier
    my $tc_sth = $algebra->{tc_sth};
    $tc_sth->{qrw1} = $qrw1;

    # get all FROM, SELECT list, WHERE info
    $tc_sth->{qrw1}->{all_from} = {};
    $tc_sth->{qrw1}->{all_select_list} = {};
    $tc_sth->{qrw1}->{all_where} = {};

    # NOTE: clear out the "statement handle" since it's not part of
    # the algebra and we don't want to walk it
    $algebra->{tc_sth} = undef;

    # local tree walk state
    $qrw1->{qb_list}    = [];
    $qrw1->{top_qb_num} = 1;     # top query block number is 1

    $algebra = $self->SubqueryNestG(algebra => $algebra,
                                    dict    => $args{dict},
                                    tc_sth  => $tc_sth
                                    );

    # NOTE: replace the "statement handle" 
    $algebra->{tc_sth} = $tc_sth;

    return ($algebra, 1)
        unless (defined($algebra)); # if error

    return ($algebra, $err_status);
}

sub SubqueryNestG
{
    my $self = shift;
    
    my %required = (
                    algebra => "no algebra !",
                    dict    => "no dictionary !",
                    tc_sth  => "no statement handle !"
                    );
    
    my %args = ( # %optional,
                 @_);
    
    return undef
        unless (Validate(\%args, \%required));
    
    my $algebra = $args{algebra};
    my $tc_sth  = $args{tc_sth};

    $algebra = $self->_subq_nest_nj($algebra, $args{dict}, $tc_sth, 0);

    return $algebra;

}

# detect "column IN (subquery)" comparison
sub _is_IN_subq
{
    my $self = shift;
    # generic tree of hashes/arrays
    my ($genTree, $dict, $tc_sth) = @_;

    if ( (exists($genTree->{comp_op}))
         && (exists($genTree->{operator}))
         && (exists($genTree->{operands})))
    {
        if (($genTree->{comp_op} =~ m/^function$/)
            && ($genTree->{operator} =~ m/^in$/))
        {
            if (scalar($genTree->{operands}) >  1)
            {
                my $op1 = $genTree->{operands}->[1];
                if (exists($op1->{function_name})
                    && exists($op1->{operands}))
                {
                    if (($op1->{function_name} =~ m/^in$/)
                        && (scalar($op1->{operands} > 0)))
                    {
                        if (exists($op1->{operands}->[0]->{sql_query}))
                        {
#                            return $genTree;
                            return (\$genTree, \$genTree->{operands}->[0],
                                    \$op1->{operands}->[0]->{sql_query});

                        }
                    }
                }
            }
        }
    }

    return undef;
}

# rewrite for subquery is join
#
# select null from emp 
#   where emp.deptno in (select dept.deptno from dept where deptno > 5);
#
# [assume select list cols are fully qualified by this time]
# select null from emp, dept 
#   where emp.deptno = dept.deptno  and dept.deptno > 5;
#
# select null from emp, 
#                  (select dept.deptno from dept 
#                     where deptno > 5) as _sys_t2
#   where emp.deptno = _sys_t2.deptno; 
#   could add "AND _sys_t2.deptno > 5" to outer query as well...

sub _IN_rewrite
{
    my $self = shift;
    # generic tree of hashes/arrays
    my ($genTree, $dict, $tc_sth, $parent_qb, $treeCtx) = @_;

    my @outi;

    my @fff = $self->_is_IN_subq($genTree, $dict, $tc_sth);

#    print Data::Dumper->Dump(\@fff);

    return @outi
        unless (scalar(@fff) > 1);

    my ($compare_clause, $where_clause, $from_clause);

    my $comp_op = $fff[0];

    my $op1     = $fff[1];

    my $subq    = $fff[2];

    # XXX XXX: do GetFromWhere to get select list, from, where for
    # subq.  Need to pass qbnum.

    my $new_comp_eq = {
        comp_op => 'comp_op',
        operator => '=',
        operands => []
        };

    my $comp_typ = {
        orig_comp_op => '=',
        tc_comp_op   => '='
        };

    my $tt = $$op1; # fix the deref

    if ($tt->{tc_expr_type} eq 'c')
    {
        $comp_typ->{tc_comp_op} = 'eq';
    }

    push @{$new_comp_eq->{operands}}, $$op1;
    push @{$new_comp_eq->{operands}}, $comp_typ;
##    push @{$comp_eq->{operands}}, $;

    push @outi, $new_comp_eq, $comp_op, $op1, $subq;

# XXX XXX:    print Data::Dumper->Dump(\@outi);

    return @outi;
}

sub _subq_nest_nj
{
    whoami;

    # NOTE: get the current subroutine name so it is easier 
    # to call recursively
    my $subname = (caller(0))[3];

    my $self = shift;
    # generic tree of hashes/arrays
    my ($genTree, $dict, $tc_sth, $in_where) = @_;

    my $treeCtx = $tc_sth->{qrw1};

    # recursively convert all elements of array
    if (ref($genTree) eq 'ARRAY')
    {
        my $maxi = scalar(@{$genTree});
        $maxi--;
        for my $i (0..$maxi)
        {
            $genTree->[$i] = $self->$subname($genTree->[$i], $dict, $tc_sth, $in_where);
        }

    }

    if (ref($genTree) eq 'HASH')
    {
        keys( %{$genTree} ); # XXX XXX: need to reset expression!!

        # recursively convert all elements of hash

        my $qb_setup = 0; # TRUE if top hash of query block
        my $current_where;

        if (exists($genTree->{query_block})) 
        {
            $qb_setup = 1;

            # keep track of current query block number
            my $current_qb = $genTree->{query_block};

            # push on the front
            unshift @{$treeCtx->{qb_list}}, $current_qb;
        }

        if (scalar(@{$treeCtx->{qb_list}}))
        {
            my $current_qb = $treeCtx->{qb_list}->[0];
            
            if ($current_qb == $treeCtx->{top_qb_num})
            {

            }

            if (exists($genTree->{from_clause}))
            {
                $treeCtx->{all_from}->{$current_qb} = 
                    $genTree->{from_clause};
            }
            if (exists($genTree->{select_list}))
            {
                $treeCtx->{all_select_list}->{$current_qb} = 
                    $genTree->{select_list};
            }
            if (exists($genTree->{search_cond}))
            {
                $current_where = $genTree->{search_cond};
                $treeCtx->{all_where}->{$current_qb} = 
                    $genTree->{search_cond};
            }
        }

        while ( my ($kk, $vv) = each ( %{$genTree})) # big while
        {
            my $loc_where;
            $loc_where = ($kk =~ m/search_cond/) ? 1 : $in_where;
            # convert subtree first...
            $genTree->{$kk} = $self->$subname($vv, $dict, $tc_sth, $loc_where);

        }

#        if ($in_where && (exists($genTree->{comp_op}))
        if (exists($genTree->{comp_op}))
        {
            my $current_qb = $treeCtx->{qb_list}->[0];

            my @foo = $self->_is_IN_subq($genTree, $dict, $tc_sth);

            if (scalar(@foo) > 1)
            {
### XXX XXX:               print "\nbingo!\n\n";
                    
                @foo = $self->_IN_rewrite($genTree, $dict, $tc_sth, 
                                          $current_qb, $treeCtx);
            }
            if (scalar(@foo) > 3)
            {
                my ($new_comp_eq, $comp_op, $op1, $subq) = @foo;
                my $subq_qb = $$subq->{operands}->[0]->{query_block};

                my $new_col = $treeCtx->{all_select_list}->{$subq_qb}->[0];

                push @{$new_comp_eq->{operands}}, $new_col;

                push @{$treeCtx->{all_from}->{$current_qb}},
                     [$$subq];
            
                # replace this node with the new equality comparison
                $genTree->{comp_op}  = $new_comp_eq->{comp_op};
                $genTree->{operator} = $new_comp_eq->{operator};
                $genTree->{operands} = $new_comp_eq->{operands};
            }
            
        }
        if ($qb_setup)
        {
            # pop from the front
            my $current_qb = shift @{$treeCtx->{qb_list}};

            if (1) ###defined($current_where))
            {
#                print "qb num: ",$current_qb, "\n";
            }

        }

    }
    return $genTree;
}


END { }       # module clean-up code here (global destructor)

## YOUR CODE GOES HERE

1;  # don't forget to return a true value from the file

__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Genezzo::Plan::QueryRewrite - Perform checks on relational algebra representation

=head1 SYNOPSIS

use Genezzo::Plan::QueryRewrite;


=head1 DESCRIPTION

Rewrite relational algebra.

=head1 ARGUMENTS

=head1 FUNCTIONS

=over 4

=item QueryRewrite

Perform typechecking on a relational algebra, and add type information
to the tree

=item TableCheck

Check table references in the relational algebra, and provide type information.

=item ColumnCheck

Resolve each column reference in the relational algebra back to some
base table.

=back

=head2 EXPORT

=over 4


=back


=head1 LIMITATIONS


=head1 TODO

=over 4

=item check for function existance in GenDBI and main namespaces

=item update pod

=item need to handle FROM clause subqueries -- some tricky column type issues.

=item check bool_op - AND purity if no OR's.

=item check relational operator (comp_op, relop)

=item handle ddl/dml (create, insert, delete etc with embedded queries) by
      checking for query_block info -- look for hash with 'query_block'
      before attempting table/col resolution.  Need special type checking
      for these functions.

=item refactor to common TreeWalker 

=item _process_name_pieces: quoted string/case-insensitivity 

=item handle all pseudo cols

=item most value expression stuff needs to migrate to XEval

=back

=head1 AUTHOR

Jeffrey I. Cohen, jcohen@genezzo.com

=head1 SEE ALSO

L<perl(1)>.

Copyright (c) 2005,2006 Jeffrey I Cohen.  All rights reserved.

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
