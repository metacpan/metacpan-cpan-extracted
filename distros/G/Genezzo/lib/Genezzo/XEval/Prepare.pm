#!/usr/bin/perl
#
# $Header: /Users/claude/fuzz/lib/Genezzo/XEval/RCS/Prepare.pm,v 7.10 2006/10/26 07:33:18 claude Exp claude $
#
# copyright (c) 2005, 2006 Jeffrey I Cohen, all rights reserved, worldwide
#
#
package Genezzo::XEval::Prepare;
use Genezzo::Util;

use strict;
use warnings;
use warnings::register;

use Carp;

our $VERSION;

BEGIN {
    $VERSION = do { my @r = (q$Revision: 7.10 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r }; # must be all one line, for MakeMaker

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

sub Prepare
{
    whoami;

    my $self = shift;

    my %required = (
                    plan => "no plan!",
                    dict => "no dict!"
                    );

    my %args = ( # %optional,
                @_);

    my ($msg, %earg);

    return undef
        unless (Validate(\%args, \%required));

    my $algebra = $args{plan};

    # NOTE: we stashed the statement handle in the top of the 
    # algebra when we did typechecking earlier
    my $tc_sth = $algebra->{tc_sth};

    # NOTE: clear out the "statement handle" since it's not part of
    # the algebra and we don't want to walk it
    $algebra->{tc_sth} = undef;

   $algebra = $self->_sql_where($algebra, $args{dict}, $tc_sth);

    # NOTE: replace the "statement handle" 
    $algebra->{tc_sth} = $tc_sth;

    my $err_status;

    return ($algebra, $err_status);

}

# sqlwhere
#
sub _sql_where
{
#    whoami;

    # NOTE: get the current subroutine name so it is easier 
    # to call recursively
    my $subname = (caller(0))[3];

    my $self = shift;
    # generic tree of hashes/arrays
    my ($genTree, $dict, $tc_sth) = @_;

    my $treeCtx = $tc_sth->{tc3};

    # recursively convert all elements of array
    if (ref($genTree) eq 'ARRAY')
    {
        my $maxi = scalar(@{$genTree});
        $maxi--;
        for my $i (0..$maxi)
        {
            $genTree->[$i] = $self->$subname($genTree->[$i], $dict, $tc_sth);
        }

    }
    if (ref($genTree) eq 'HASH')
    {
        keys( %{$genTree} ); # XXX XXX: need to reset expression!!

        # convert subtree first, then process local select list
        {
            my $qb_setup = 0; # TRUE if top hash of query block
            
            if (exists($genTree->{query_block})) 
            {
                $qb_setup = 1;
                
                # keep track of current query block number
                my $current_qb = $genTree->{query_block};

                # push on the front
                unshift @{$treeCtx->{qb_list}}, $current_qb;
            }
            
            while ( my ($kk, $vv) = each ( %{$genTree})) # big while
            {
                # convert subtree first...
                $genTree->{$kk} = $self->$subname($vv, $dict, $tc_sth);
            }

            if ($qb_setup)
            {
                # pop from the front
                shift @{$treeCtx->{qb_list}};
            }

        }

        # recursively convert all elements of hash

        my $qb_setup = 0; # TRUE if top hash of query block

        if (exists($genTree->{query_block})) 
        {
            $qb_setup = 1;

            # keep track of current query block number
            my $current_qb = $genTree->{query_block};

            # push on the front
            unshift @{$treeCtx->{qb_list}}, $current_qb;
        }

        if (exists($genTree->{tc_column_name}))
        {
            if (exists($genTree->{tc_column_num}))
            {
#                $genTree->{vx} = 
#                    '$outarr->[' . ($genTree->{tc_column_num} - 1) .
#                    ']';
                # for joins, switch to get_alias_col hash
                $genTree->{vx} = 
                    '$get_alias_col->{"' 
                    . $genTree->{tc_col_tablename} . 
                    '"}->[' . ($genTree->{tc_column_num} - 1) .
                    ']';
                # XXX XXX: handle joins...
                $genTree->{vx_etc} = 
                    'get_table_col(\'' 
                    . $genTree->{tc_col_tablename} . '\', ' 
                    . ($genTree->{tc_column_num} - 1) .
                    ')';
            }
            else
            {
                if ($genTree->{tc_column_name} =~ m/^rid$/i)
                {
#                    $genTree->{vx} = '$tc_rid';
                    $genTree->{vx} = '$rid';
                }
                if ($genTree->{tc_column_name} =~ m/^rownum$/i)
                {
                    $genTree->{vx} = '$tc_rownum';
                }
            }
        }

        if (exists($genTree->{numeric_literal}))
        {
            $genTree->{vx} = $genTree->{numeric_literal};
        }

        if (exists($genTree->{tfn_literal}))
        {
            $genTree->{vx} = $genTree->{tfn_literal};
        }

        if (exists($genTree->{string_literal}))
        {
            $genTree->{vx} = $genTree->{string_literal};
        }

        if (exists($genTree->{comp_op}))
        {
            my $bigstr = '( ';

            for my $op1 (@{$genTree->{operands}})
            {
                if (ref($op1) eq 'HASH')
                {
                    if (exists($op1->{vx}))
                    {
                        if (defined($op1->{vx}))
                        {
                            $bigstr .= $op1->{vx} . ' ' ;
                        }
                        else
                        {
                            # handle NULL/UNDEF
                            $bigstr .= ' undef ';
                        }
                    }
                    if (exists($op1->{tc_comp_op}))
                    {
                        $bigstr .= $op1->{tc_comp_op} . ' ';
                    }
                }
            }
            $bigstr .= ')';
            $genTree->{vx} = $bigstr;

            # build an index key if have an expression like:
            # column_name comp_op literal
            #
            if (3 == scalar(@{$genTree->{operands}}))
            {
                my $oplist = $genTree->{operands};
                my ($colnum, $comp_op, $literal);
                
                if (ref($oplist->[0]) eq 'HASH')
                {
                    $colnum = ($oplist->[0]->{tc_column_num}) - 1
                        if (exists($oplist->[0]->{tc_column_num}));
                }
                if (ref($oplist->[1]) eq 'HASH')
                {
                    my $tok_expr = '(eq|==|<|>|lt|gt|le|ge|<=|>=)';

                    $comp_op = $oplist->[1]->{tc_comp_op}
                        if (exists($oplist->[1]->{tc_comp_op})
                            && ($oplist->[1]->{tc_comp_op} =~
                                m/^$tok_expr$/
                                )
                            );
                }
                if (ref($oplist->[2]) eq 'HASH')
                {
                    if (exists($oplist->[2]->{string_literal}))
                    {
                        $literal = $oplist->[2]->{string_literal};
                    }
                    elsif (exists($oplist->[2]->{numeric_literal}))
                    {
                        $literal = $oplist->[2]->{numeric_literal};
                    }
                }

                if (defined($colnum)  && 
                    defined($comp_op) && 
                    defined($literal))
                {
                    # XXX XXX: change to better format
                    $genTree->{tc_index_key} =
                        [
                         { col     => $colnum  },
                         { op      => $comp_op },
                         { literal => $literal }
                         ];
                }
                
            } # end build index key
        }

        if (exists($genTree->{IS}))
        {
            my $bigstr = '';

            # XXX XXX XXX: not an array!
            my $op1 = $genTree->{operands};
            {
                # XXX XXX: undef issue?
                if (exists($op1->{vx}))
                {
                    $bigstr .= $op1->{vx} . ' ';
                }
            }

            my $tfn1 = $genTree->{IS}->[0]->{TFN}->{tfn_literal};
            my $not1 = scalar(@{$genTree->{IS}->[0]->{not}});

            my $s2;
            if (!(defined($tfn1)))
            {
                # not null = is defined
                $s2 = '(';
                $s2 .= '!' if (!$not1);
                $s2 .= 'defined(' . $bigstr . '))';

                # NOTE: Reset AndPurity if have "IS NULL" predicate
                # because can't do index search on null values.
                $treeCtx->{AndPurity} = 0
                    unless ($not1);

            }
            else
            {
                # not true = is false
                $s2 = '(('.$bigstr .') == ';
                my $tf_val = ($not1) ? 1 : 0;
                if ($tfn1) # true
                {
                    $tf_val = ($not1) ? 0 : 1;
                }
                $s2 .= $tf_val . ')';
            }
            $genTree->{vx} = $s2;
            
        }

        if (exists($genTree->{math_op}))
        {

            # fixup the perl operators like 'comp_perlish'
            if (($genTree->{math_op} eq 'perlish_substitution')
                && (3 == scalar(@{$genTree->{operands}})))
            {

                my $op2 =
                    $genTree->{operands}->[2];

                # XXX XXX: op2 should be an array of 
                # perl regex pieces -- reassemble it.  
                # may need to do some work for non-standard
                # quoting
                
#                my $perl_lit = join("", @{$op2});
                my $perl_lit = "";
                for my $toknum (0..(scalar(@{$op2})-1))
                {

                    # need to skip duplicate quote, e.g.
                    # s/foo/bar/g becomes
                    # ['s', '/', 'foo', '/', '/', 'bar', '/', 'g']
                    # Note the duplicate quotes in position 3,4

                    next if ($toknum == 3);
                    $perl_lit .= $op2->[$toknum];
                }

                $genTree->{operands}->[2] = {
                    string_literal => $perl_lit,
                    # Note: fill in all the string literal info
                    vx             => $perl_lit,
                    tc_expr_type   => 'c',
                    orig_reg_exp => $op2
                    };

                if ($op2->[0] !~ /^s$/)
                {
                    my $msg = "illegal expression ($perl_lit)\n" .
                        "only substitution (s//) regexps are " .
                        "allowed in SELECT list"; 
                    
                    my %earg = (self => $self, msg => $msg,
                                severity => 'warn');
                
                    &$GZERR(%earg)
                        if (defined($GZERR));
                    
                    return undef; 
                }

            }

            my $bigstr = '( ';
            for my $op1 (@{$genTree->{operands}})
            {
                if (ref($op1))
                {
                    # XXX XXX: undef issue?
                    if (exists($op1->{vx}))
                    {
                        $bigstr .= $op1->{vx} . ' ';
                    }
                }
                else
                {
                    # XXX XXX: concatenation
                    if ($op1 eq '||')
                    { $op1 = '.'; }

                    $bigstr .= $op1 . ' ';
                }
            }
            $bigstr .= ')';
            $genTree->{vx} = $bigstr;
        }

        if (exists($genTree->{bool_op}))
        {
            my $bigstr = '( ';

            if ($genTree->{bool_op} =~ m/NOT/i)
            {
                # treat NOT a little special, since it's a prefix
                # operator, not an infix op like AND/OR.  Should only
                # have one operand.
                $bigstr .= '!( ';
            }

            my $op_cnt = 0;
            for my $op1 (@{$genTree->{operands}})
            {
                if (ref($op1) eq 'HASH')
                {
                    if (exists($op1->{vx}))
                    {
                        if (defined($op1->{vx}))
                        {
                            $bigstr .= ' ' . $op1->{vx} ;
                        }
                        else
                        {
                            # handle NULL/UNDEF
                            $bigstr .= ' undef';
                        }
                    }
                }
                elsif (ref($op1) eq 'ARRAY')
                {
                    if ($op1->[0] =~ m/^or$/i)
                    {
                        # found an OR
                        $treeCtx->{AndPurity} = 0;

                        $bigstr .= '|| ';
                    }
                    elsif ($op1->[0] =~ m/^and$/i)
                    {
                        $bigstr .= '&& ';
                    }
                    else
                    {
                        $bigstr .= $op1->[0] . ' ';
                    }

                }
                else
                {
                    $bigstr .= $op1 . ' ';
                }

                $op_cnt++;
            }
            if ($genTree->{bool_op} =~ m/NOT/i)
            {
                # terminate the NOT expression
                $bigstr .= ')';
            }

            $bigstr .= ')';
            $genTree->{vx} = $bigstr;
        }

        if (exists($genTree->{unary}))
        {
            my $bigstr = '( ';

            my $unop = $genTree->{unary}->[0];

            if ($unop eq "+")
            {
                $bigstr .= ' ( ';
            }
            elsif ($unop eq "-")
            {
                $bigstr .= ' -1 * ( ';
            }
            elsif ($unop eq "!") # XXX XXX: is this NOT or minus ? 
            {
                $bigstr .= ' !( ';
            }

            if (exists($genTree->{val}))
            {
                my $op1 = $genTree->{val};
                
                if (ref($op1) eq 'HASH')
                {
                    if (exists($op1->{vx}))
                    {
                        if (defined($op1->{vx}))
                        {
                            $bigstr .= ' ' . $op1->{vx} ;
                        }
                        else
                        {
                            # handle NULL/UNDEF
                            $bigstr .= ' undef';
                        }
                    }
                }
            }

            $bigstr .= '))';
            $genTree->{vx} = $bigstr;
        }

        if (exists($genTree->{function_name}))
        {
            my $hash_args = 0;

            my $foundIt = 0;
            my $fn_name;

            if ($genTree->{function_name} =~ m/^HavokUse$/i)
            {
                $fn_name = 'Genezzo::GenDBI::sql_func_HavokUse';
            }
            else
            {
                if ($genTree->{function_name} =~ m/^sql_func/)
                {
                    $fn_name = 'Genezzo::GenDBI::'
                        . ($genTree->{function_name});
                }
                else
                {
                    $fn_name = 'Genezzo::GenDBI::sql_func_'
                        . lc($genTree->{function_name});
                }

                my $dbh = $dict->{dbh};
                my $sth;
                my $ffname = lc($genTree->{function_name});
                $sth = $dbh->prepare("select argstyle, args, typecheck from user_functions where sqlname = \'$ffname\'");

                if ($sth) 
                {
                    $sth->execute();

                    my @lastfetch = $sth->fetchrow_array();

                    if (scalar(@lastfetch))
                    {
                        if ($lastfetch[0] =~ m/HASH/)
                        {
                            $hash_args = 1;
                        }
                    }
                }

            }

            if (($genTree->{function_name} =~ m/^sql_func_HavokUse$/)
                || ($genTree->{function_name} =~ m/^HavokUse$/i))
            {
                # pass a hash vs an array of args
                $hash_args = 1;
            }

            # look in GenDBI namespace 
            for my $numtries (1..2)
            {
                # check if function exists
                if (defined(&$fn_name))
                {
                    $foundIt = 1;
                    last;
                } 
                if ($genTree->{function_name} !~ m/^sql_func/)
                {
                    $fn_name = 'Genezzo::GenDBI::'
                        . ($genTree->{function_name});
                }
                
            }

            if (!$foundIt)
            {
                # XXX XXX: fix for COUNT/ECOUNT
                if ($genTree->{function_name} =~ m/^(ecount|count)$/i)
                {
                    $foundIt = 1;
                }
            }

            unless ($foundIt)
            {
                my $msg = "function \'$fn_name\' not found\n";
                
                my %earg = (self => $self, msg => $msg,
                            severity => 'warn');
                
                &$GZERR(%earg)
                    if (defined($GZERR));
                
#                       return undef; # XXX XXX XXX XXX
            }


            my $bigstr  = ' ' . $fn_name . '( ';
            
            # 
            if ($hash_args)
            {
                $bigstr .= 'function_args => [ ';
            }


            if (exists($genTree->{operands})
                && (ref($genTree->{operands}) eq 'ARRAY')
                && scalar(@{$genTree->{operands}}))
            {
                # XXX XXX: deal with ALL/DISTINCT/SUBQUERIES

                my $fn_ops = $genTree->{operands}->[0];

                # XXX XXX: what about COUNT(*), ECOUNT?
                if (exists($fn_ops->{operands})
                    && (ref($fn_ops->{operands}) eq 'ARRAY'))
                {
                    my $cnt_ff = 0;
                    for my $op1 (@{$fn_ops->{operands}})
                    {
                        if (exists($op1->{vx}))
                        {
                            $bigstr .= ',' if ($cnt_ff);
                            if (defined($op1->{vx}))
                            {
                                $bigstr .= ' ' . $op1->{vx} ;
                            }
                            else
                            {
                                # handle NULL/UNDEF
                                $bigstr .= ' undef';
                            }
                        }
                        $cnt_ff++;
                    }
                }
            }

            if ($hash_args)
            {
                $bigstr .= ' ], dict => $tc_dict,  dbh => $tc_dbh ';
            }

            $bigstr .= ')';
            $genTree->{vx} = $bigstr;
        } # end function name


        if ($qb_setup)
        {
            # pop from the front
            shift @{$treeCtx->{qb_list}};
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

Genezzo::Plan::TypeCheck - Perform checks on relational algebra representation

=head1 SYNOPSIS

use Genezzo::Plan::TypeCheck;


=head1 DESCRIPTION


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

=item sql_where: function name processing -- drive from user_function, use type-checking functions.

=item update pod

=item need to handle FROM clause subqueries -- some tricky column type issues.

=item explode STARs with column names - need consistent join table position

=item check bool_op - AND purity if no OR's.

=item check relational operator (comp_op, relop)

=item handle ddl/dml (create, insert, delete etc with embedded queries) by
      checking for query_block info -- look for hash with 'query_block'
      before attempting table/col resolution.  Need special type checking
      for these functions.

=item refactor to common TreeWalker 


=back

=head1 AUTHOR

Jeffrey I. Cohen, jcohen@genezzo.com

=head1 SEE ALSO

L<perl(1)>.

Copyright (c) 2005, 2006 Jeffrey I Cohen.  All rights reserved.

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
