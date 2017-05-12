#!/usr/bin/perl
#
# $Header: /Users/claude/fuzz/lib/Genezzo/Plan/RCS/TypeCheck.pm,v 7.17 2006/08/26 06:58:03 claude Exp claude $
#
# copyright (c) 2005,2006 Jeffrey I Cohen, all rights reserved, worldwide
#
#
package Genezzo::Plan::TypeCheck;
use Genezzo::Util;

use strict;
use warnings;
use warnings::register;

use Carp;

our $VERSION;

BEGIN {
    $VERSION = do { my @r = (q$Revision: 7.17 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r }; # must be all one line, for MakeMaker

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

    my %valid_aggs = 
        qw(
           MIN      1
           MAX      1
           AVG      1
           SUM      1
           MEAN     1
           STDDEV   1
           COUNT    1
           ECOUNT   1
           );

    $self->{aggregate_functions} = \%valid_aggs;

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

sub TypeCheck
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

    # build a special "statement handle" to hold error and context info
    my $tc_sth = {};
    $tc_sth->{statement} = $args{statement};

    $algebra = $self->TableCheck(algebra => $algebra,
                                 dict    => $args{dict},
                                 tc_sth  => $tc_sth
                                 );

    return ($algebra, 1)
        unless (defined($algebra)); # if error

    greet $tc_sth->{tc1}->{tc_err};

    unless (scalar(@{$tc_sth->{tc1}->{tc_err}->{nosuch_table}}))
    {
        $algebra = $self->ColumnCheck(algebra   => $algebra,
                                      dict      => $args{dict},
                                      statement => $args{statement},
                                      tc_sth    => $tc_sth
                                      );
    }

    unless (exists($tc_sth->{tc1}) &&
            exists($tc_sth->{tc2}) &&
            exists($tc_sth->{tc3}))
    {
        greet "incomplete tc";
        $err_status = 1;
    }


    if (!defined($err_status))
    {
        for my $kk (keys(%{$tc_sth->{tc1}->{tc_err}}))
        {
            if (scalar(@{$tc_sth->{tc1}->{tc_err}->{$kk}}))
            {
                $err_status = 1;
                last;
            }
        }
        if (!defined($err_status))
        {
            for my $kk (keys(%{$tc_sth->{tc3}->{tc_err}}))
            {
                next          # only case of hash vs array
                    if ($kk eq "duplicate_alias");
                if (scalar(@{$tc_sth->{tc3}->{tc_err}->{$kk}}))
                {
                    $err_status = 1;
                    last;
                }
            }
        }
        greet "tc errors"
            if (defined($err_status));
    }
    
    # NOTE: attach the "statement handle" to the algebra -- it contains
    # useful information for code generation
    $algebra->{tc_sth} = $tc_sth;
    return ($algebra, $err_status);
}

sub TableCheck
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

    # XXX XXX: maybe break the type check phases into separate packages

    # first, fetch table info from dictionary

    my $tc1 = {}; # type check tree context for tree walker
    my $tc_sth = $args{tc_sth};
    $tc_sth->{tc1} = $tc1;

    # local tree walk state
    $tc1->{tpos} = 0; # mark each table

    # save bad tables for error reporting...
    $tc1->{tc_err}->{nosuch_table} = [];
    $tc1->{tc_err}->{duplicate_table} = [];
    $algebra = $self->_get_table_info($algebra, $args{dict}, $tc_sth);

    # next, cross reference table info with query blocks

    my $tc2 = {}; # type check tree context for tree walker
    $tc_sth->{tc2} = $tc2;

    # local tree walk state
    $tc2->{qb_list} = []; # build an arr starting with current query block num
    $tc2->{qb_dependency} = []; # save qb parent dependency

    # save table definition/query block info for later type check phases...
    $tc2->{tablist} = []; # arr by qb num of table information
    $algebra = $self->_check_table_info($algebra, $args{dict}, $tc_sth);

    if (0)
    {
        local $Data::Dumper::Indent   = 1;
        local $Data::Dumper::Sortkeys = 1;

        print Data::Dumper->Dump([$tc2],['tc2']);

    }

    return $algebra;
}

# convert an array of quoted strings/barewords into an array
# of normalized strings
sub _process_name_pieces
{
    my @pieces = @_;

    my @full_name;

    # turn array of name "pieces" back into full names
    for my $name_piece (@pieces)
    {
        # may need to distinguish between bareword and
        # quoted strings
        if (exists($name_piece->{quoted_string}))
        {
            my $p1 = $name_piece->{quoted_string};
            # strip leading/trailing quotes
            my @p2 = $p1 =~ m/^\"(.*)\"$/;
            push @full_name, @p2;
        }
        else
        {
            # XXX XXX: may need to uc or lc here...
            if (exists($name_piece->{bareword}))
            {
                my $p1 = $name_piece->{bareword};
                push @full_name, lc($p1);
            }
#            while ( my ($kk,$p1) = (each(%{$name_piece})))
#            {
#                next if ($kk =~ m/^(p1|p2)$/);
#                push @full_name, lc($p1);
#            }
        }
    }

    # NOTE: issue of handling quoted name pieces with 
    # embedded "." (dot) if wish to construct full_name_str 
    # as join('.', @full_name) -- need to avoid ambiguity
    return @full_name;

}

sub _process_name_position
{
    my @pieces = @_;

    my @full_pos;

    for my $name_piece (@pieces)
    {
        my ($p1, $p2);

        $p1 = undef;
        $p2 = undef;

        $p1 = ($name_piece->{p1})
            if (exists($name_piece->{p1}));
        $p2 = ($name_piece->{p2})
            if (exists($name_piece->{p2}));
        # build array of positions of each piece of name...
        push @full_pos, [$p1, $p2];
    }
    return @full_pos;

}

# recursive function to decorate table info
#
# get table information from the dictionary
# number each table uniquely
#
sub _get_table_info # private
{
#    whoami;

    # NOTE: get the current subroutine name so it is easier 
    # to call recursively
    my $subname = (caller(0))[3];

    my $self = shift;
    # generic tree of hashes/arrays
    my ($genTree, $dict, $tc_sth) = @_;

    my $treeCtx = $tc_sth->{tc1};

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
        # recursively convert all elements of hash, but treat
        # table name specially

        if (exists($genTree->{table_name}))
        {

            # uniquely number each table reference
            # Note: use for join order to select STAR expansion

            $genTree->{tc_table_position} = $treeCtx->{tpos};
            $treeCtx->{tpos}++;

            my @full_name = _process_name_pieces(@{$genTree->{table_name}});

            # build a "dot" separated string
            my $full_name_str = join('.', @full_name);

            $genTree->{tc_table_fullname} = $full_name_str;

            # look it up in the dictionary
            if (! ($dict->DictTableExists (
                                           tname => $full_name_str,
                                           silent_exists => 1,
                                           silent_notexists => 0 
                                           )
                   )
                )
            {
                push @{$treeCtx->{tc_err}->{nosuch_table}}, 
                ["table", $full_name_str];
#                       return undef; # XXX XXX XXX XXX
            }
            else
            {
                # XXX XXX: temporary?
                # get hash by column name
                $genTree->{tc_table_colhsh} = 
                    $dict->DictTableGetCols (tname => $full_name_str);
                my @colarr;
                
                (keys(%{$genTree->{tc_table_colhsh}}));
                # build array by column position
                while ( my ($chkk, $chvv) 
                        = each ( %{$genTree->{tc_table_colhsh}})) 
                {
                    my %nh = (colname => $chkk, coltype => $chvv->[1]);
                    $colarr[$chvv->[0]] = \%nh;
                }
                shift @colarr;
                $genTree->{tc_table_colarr} = \@colarr;               
            }
                
        } # end if tablename

        if (exists($genTree->{new_table_name}))
        {
            my @full_name = _process_name_pieces(@{$genTree->{new_table_name}});

            # build a "dot" separated string
            my $full_name_str = join('.', @full_name);

            $genTree->{tc_newtable_fullname} = $full_name_str;

            # look it up in the dictionary
            if ($dict->DictTableExists (
                                        tname => $full_name_str,
                                        silent_exists => 0,
                                        silent_notexists => 1 
                                        )
                )
            {
                push @{$treeCtx->{tc_err}->{duplicate_table}}, 
                ["table", $full_name_str];
#                       return undef; # XXX XXX XXX XXX
            }
                
        } # end if new table name

        if (exists($genTree->{new_index_name}))
        {
            my @full_name = _process_name_pieces(@{$genTree->{new_index_name}});

            # build a "dot" separated string
            my $full_name_str = join('.', @full_name);

            $genTree->{tc_newindex_fullname} = $full_name_str;

            # look it up in the dictionary
            if ($dict->DictTableExists (
                                        tname => $full_name_str,
                                        silent_exists => 0,
                                        silent_notexists => 1 
                                        )
                )
            {
                # XXX XXX: should be "duplicate index"...
                push @{$treeCtx->{tc_err}->{duplicate_table}}, 
                ["index", $full_name_str];
#                       return undef; # XXX XXX XXX XXX
            }
                
        } # end if new index name

        if (exists($genTree->{tablespace_name}))
        {
            my @full_name = _process_name_pieces(@{$genTree->{tablespace_name}});

            # build a "dot" separated string
            my $full_name_str = join('.', @full_name);

            $genTree->{tc_tablespace_fullname} = $full_name_str;

            # look it up in the dictionary
            if (! ($dict->DictObjectExists (
                                            object_type => "tablespace",
                                            object_name => $full_name_str,
                                            silent_exists => 1,
                                            silent_notexists => 0 
                                            )
                   )
                )
            {
                push @{$treeCtx->{tc_err}->{nosuch_table}}, 
                ["tablespace", $full_name_str];
#                       return undef; # XXX XXX XXX XXX
            }
        }

        if (exists($genTree->{new_tablespace_name}))
        {
            my @full_name = _process_name_pieces(@{$genTree->{new_tablespace_name}});

            # build a "dot" separated string
            my $full_name_str = join('.', @full_name);

            $genTree->{tc_newtablespace_fullname} = $full_name_str;

            # look it up in the dictionary
            if ($dict->DictObjectExists (
                                         object_type      => "tablespace",
                                         object_name      => $full_name_str,
                                         silent_exists    => 0,
                                         silent_notexists => 1 
                                         )
                )
            {
                push @{$treeCtx->{tc_err}->{duplicate_table}}, 
                ["tablespace", $full_name_str];

                greet $treeCtx->{tc_err}->{duplicate_table};

#                       return undef; # XXX XXX XXX XXX
            }
            else
            {
                greet "no dup found";
            }
                
        } # end if new tablespace name

        if (exists($genTree->{table_alias}))
        {
            if (scalar(@{$genTree->{table_alias}}))
            {
                # don't build an alias unless we really have one
                my @full_name = 
                    _process_name_pieces(@{$genTree->{table_alias}});

                # build a "dot" separated string
                my $full_name_str = join('.', @full_name);

                $genTree->{tc_table_fullalias} = $full_name_str;
            }
            # XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX 
            # detect FROM clause subquery -- need to build
            # tc_table_colhsh, tc_table_colarr later
            # XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX 
            unless (exists($genTree->{table_name}))
            {
                # uniquely number each table reference
                # Note: use for join order to select STAR expansion
                $genTree->{tc_table_position} = $treeCtx->{tpos};
                
                if (exists($genTree->{tc_table_fullalias}))
                {
                    $genTree->{tc_FROM_SUBQ} = { alias => "USER_ALIAS" };
                }
                else
                {
                    # build a unique alias
                    # XXX XXX: need a better unique function
                    $genTree->{tc_table_fullalias} = 
                        "_SYS_ALIAS_" . $treeCtx->{tpos};
                    $genTree->{tc_FROM_SUBQ} = { alias => "SYSTEM_ALIAS" };
                }
                $genTree->{tc_FROM_SUBQ}->{subq_schema} = "UNKNOWN" ;
                $treeCtx->{tpos}++;
                # setup the "table fullname" for check table...
                $genTree->{tc_table_fullname} = $genTree->{tc_table_fullalias};
            } # end if FROM subq
        } # end if table alias

        while ( my ($kk, $vv) = each ( %{$genTree})) # big while
        {
            if ($kk !~ m/^(table_name|table_alias)$/)
            {
                $genTree->{$kk} = $self->$subname($vv, $dict, $tc_sth);
            }
        } # end big while
    }
    return $genTree;
}

# check the validity of results of _get_table_info
#
# determine proper table/alias name
# find duplicates
# associate table info with appropriate query block
# build list of query block dependency information for correlated subqueries
#
sub _check_table_info # private
{
#    whoami;

    # NOTE: get the current subroutine name so it is easier 
    # to call recursively
    my $subname = (caller(0))[3];

    my $self = shift;
    # generic tree of hashes/arrays
    my ($genTree, $dict, $tc_sth) = @_;

    my $treeCtx = $tc_sth->{tc2};

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
        # recursively convert all elements of hash

        my $qb_setup = 0; # TRUE if top hash of query block

        if (exists($genTree->{query_block})) 
        {
            $qb_setup = 1;

            # keep track of current query block number
            my $current_qb = $genTree->{query_block};

            # push on the front
            unshift @{$treeCtx->{qb_list}}, $current_qb;

            unless (defined($treeCtx->{tablist}->[$current_qb]))
            {
                # build a hash to hold the table info associated with
                # the current query block
                $treeCtx->{tablist}->[$current_qb] = { 
                    tables => {}, 

                    # reserve space for select list column aliases
                    select_list_aliases => {},
                    select_col_num => 0
                };
            }

            if (exists($genTree->{query_block_parent}))
            {
                # save the query block dependency information
                my @foo = @{$genTree->{query_block_parent}};
                $treeCtx->{qb_dependency}->[$current_qb] = \@foo;
            }
        }

        # NOTE: build an alias if we don't have one. Do it outside the
        # loop in order to avoid updating the hash as we traverse it.
        if (exists($genTree->{tc_table_fullname}))
        {
            unless (exists($genTree->{tc_table_fullalias}))
            {
                my $tab_alias = $genTree->{tc_table_fullname};
                
                $genTree->{tc_table_fullalias} = $tab_alias;
            }
        }

        while ( my ($kk, $vv) = each ( %{$genTree})) # big while
        {
            if ($kk !~ m/^tc_table_fullname$/)
            {
                $genTree->{$kk} = $self->$subname($vv, $dict, $tc_sth);
            }
            else # table name 
            {
                my $tab_alias;
                
                if (exists($genTree->{tc_table_fullalias}))
                {
                    $tab_alias = $genTree->{tc_table_fullalias};
                }
                else
                {
                    # NOTE: should never get here - should always
                    # define an alias outside this loop...
                    $tab_alias = $vv;
                }

                # store table info in the table list for the current
                # query block
                my $current_qb = $treeCtx->{qb_list}->[0];
                my $tablist    = $treeCtx->{tablist}->[$current_qb]->{tables};

                # use the alias, rather than the tablename -- this is
                # ok since the alias points to the base table info.
                if (exists($tablist->{$tab_alias}))
                {
                    my $msg = "Found duplicate table name: " .
                        "\'$tab_alias\'\n";
                    my %earg = (self => $self, msg => $msg,
                                statement => $tc_sth->{statement},
                                severity => 'warn');
                    
                    &$GZERR(%earg)
                        if (defined($GZERR));
                    # return undef # XXX XXX XXX
                }
                else
                {
                    # save a reference to current hash
                    $tablist->{$tab_alias} = $genTree;
                }

            } # end table name
        } # end big while

        if ($qb_setup)
        {
            # pop from the front
            shift @{$treeCtx->{qb_list}};
        }

    }
    return $genTree;
}

sub ColumnCheck
{
    my $self = shift;
    
    my %required = (
                    algebra   => "no algebra !",
                    statement => "no sql statement !",
                    dict      => "no dictionary !",
                    tc_sth    => "no statement handle !"
                    );
    
    my %args = ( # %optional,
                 @_);
    
    return undef
        unless (Validate(\%args, \%required));


    my $algebra = $args{algebra};

    my $tc3 = {}; # type check tree context for tree walker
    my $tc_sth = $args{tc_sth};    
    $tc_sth->{tc3} = $tc3;

    # local tree walk state
    $tc3->{qb_list} = []; # build an arr starting with current query block num
    $tc3->{statement} = $args{statement};

    # save bad columns for error reporting
    $tc3->{tc_err}->{duplicate_alias} = {};
    $tc3->{tc_err}->{nosuch_column}   = [];
    # use the table information from table typecheck phase
    $tc3->{tablist} = $tc_sth->{tc2}->{tablist};

    # convert "select * "  to "select <column_list> "
    $algebra = $self->_get_star_cols($algebra, $args{dict}, $tc_sth);

    # setup select list column aliases and column headers
    $algebra = $self->_get_col_alias($algebra, $args{dict}, $tc_sth);

    # map columns to FROM clause tables
    $algebra = $self->_get_col_info($algebra, $args{dict}, $tc_sth);

    # use type information to map sql comparison operations to their
    # perl equivalents

    $algebra = $self->_fixup_comp_op($algebra, $args{dict}, $tc_sth);

    $tc3->{tc_err}->{invalid_args}   = [];
    # mark aggregates and check for invalid args
    $algebra = $self->_find_aggregate_functions($algebra, 
                                                $args{dict}, 
                                                $tc_sth);

    $tc3->{tc_agg_check} = [];
    # check for aggregates in WHERE clause
    $algebra = $self->_check_aggregate_functions($algebra, 
                                                 $args{dict}, 
                                                 $tc_sth);

    # check for GROUPing/aggregates

    # check for final select list columns vs all projected columns in
    # all clauses

    # check args for all functions

    $tc3->{AndPurity} = 1; # false if find OR's

# XXX XXX: moved this to XEVal::Prepare
#    $algebra = $self->_sql_where($algebra, $args{dict}, $tc_sth);

    if (0) # XXX XXX XXX XXX
    {
        my $tc2 = $tc_sth->{tc2};

        local $Data::Dumper::Indent   = 1;
        local $Data::Dumper::Sortkeys = 1;

        print Data::Dumper->Dump([$tc2],['tc2']);

    }

    # NOTE: need to build the select list column aliases *first*,
    # then type check all columns.  
    #
    # Different standards (SQL92, SQL99) and different products have
    # different scoping and precedence rules on the select list column
    # aliases.  In general, the WHERE clause is processed before the
    # select list defines the column aliases, so it can only use table
    # and table alias information.  (Which makes sense -- you can have
    # a column alias on an aggregate operator like COUNT(*), which
    # can't be completely evaluated until the WHERE clause processes
    # the final row.)
    #
    # ORDER BY is the last operation, so it can evaluate expressions
    # using the column aliases.  GROUP BY and HAVING behavior seems to
    # be a bit of a tossup.  We'll try to maintain some flexibility --
    # the tablist has separate entries column alias info and table
    # definitions in each query block.  In case of ambiguity of column
    # alias which matches an existing column name, use rule where
    # column names take precedence over column aliases in GROUP
    # BY/HAVING, *but* reverse precendence in ORDER BY.
    #
    # What is scope of column aliasing in select list itself?  left to
    # right (ie, col2 can utilize the col1 alias) or "simultaneous"?
    #
    #
    # Note that select list column aliases are allowed to mask table
    # columns, but all other table column references should not be
    # ambiguous.

    # XXX XXX XXX: _get_col_alias to only build up alias info in
    # tablist, then _get_col_info to resolve column names against
    # aliases, then tables if necessary

    return $algebra;
}

sub _FROM_subq_star_fixup
{
#    whoami;

    # NOTE: get the current subroutine name so it is easier 
    # to call recursively
    my $subname = (caller(0))[3];

    my $self = shift;
    # generic tree of hashes/arrays
    my ($genTree, $dict, $tc_sth) = @_;

    my $treeCtx = $tc_sth->{tc3};

    return 
        unless (exists($genTree->{tc_FROM_SUBQ})
                && exists($genTree->{tc_FROM_SUBQ}->{subq_schema})
                && ($genTree->{tc_FROM_SUBQ}->{subq_schema} eq 'UNKNOWN'));

    return
        if (exists($genTree->{tc_table_colarr})
            && scalar($genTree->{tc_table_colarr}));

    if (exists($genTree->{sql_query})
        && exists($genTree->{sql_query}->{operands})
        && scalar($genTree->{sql_query}->{operands}))
    {
        # select list of 1st sql query takes precedence for set operations...
        my $first_op = $genTree->{sql_query}->{operands}->[0];

        while (!exists($first_op->{sql_select})
               && exists($first_op->{operands})
               && scalar(@{$first_op->{operands}}))
        {
            # XXX XXX: this needs to be recursive for nested set operations!!
            $first_op = $first_op->{operands}->[0];
        }

        if (exists($first_op->{sql_select})
            && exists($first_op->{sql_select}->{select_list})
            && scalar(@{$first_op->{sql_select}->{select_list}}))
        {
            my $sel_list1 = $first_op->{sql_select}->{select_list};
                        
            $genTree->{tc_table_colarr} = [];
            $genTree->{tc_table_colhsh} = {};

            my $sel_index = 0;
            for my $sel_item (@{$sel_list1})
            {
                $sel_index++;
#                            greet $sel_item;

                # XXX XXX: is there some way to streamline handling of
                # literals here?

                my ($hnam, $htyp);
                if (scalar(@{$sel_item->{col_alias}}))
                {
                    # XXX XXX: eliminate this duplicate code
                    my @full_name = 
                        _process_name_pieces(
                                             @{$sel_item->{col_alias}});
                    $hnam = join('.',@full_name);
#                                greet 1, $hnam;
                }
                else
                {
                    my $col_hd;
                    if (exists($sel_item->{p1}))
                    {
                        $col_hd = substr($treeCtx->{statement},
                                         $sel_item->{p1},
                                         ($sel_item->{p2} - $sel_item->{p1}) + 1
                                         );
                        $col_hd =~ s/^\s*//; # trim leading spaces
#                                    greet 2, $col_hd;
                    }
                    else
                    {
                        # XXX XXX: generated col for STAR - fake it
                            
                        # XXX XXX: assume have a column name
                        my $npa = $sel_item->{value_expression}->{column_name};
                            
                        my @col_name =  _process_name_pieces(@{$npa});

                        $col_hd = join(".", @col_name);
#                                    greet 3, $col_hd;
                    }
                    $hnam = $col_hd;
                                

                } # end no alias
                $htyp = $sel_item->{value_expression}->{tc_expr_type};

                my $h1 = { colname => $hnam,
                           coltype => $htyp };
                push @{$genTree->{tc_table_colarr}}, $h1;

                # XXX XXX: need duplicate col name check
                # or type mismatch here!!
                $genTree->{tc_table_colhsh}->{$hnam} =
                    [$sel_index, $htyp];
            } # end for
        }
    }
    $genTree->{tc_FROM_SUBQ}->{subq_schema} = 'OK';

}
# expand STAR select lists...
#
#
sub _get_star_cols
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

        # fixup star select lists for FROM subqueries
        $self->_FROM_subq_star_fixup($genTree, $dict, $tc_sth);

        if (exists($genTree->{select_list}))
        {
            # if the select list is STAR (not an array)
            unless (ref($genTree->{select_list}) eq 'ARRAY')
            {                
                # start in current query block
                # find our tablist
                my $current_qb   = $treeCtx->{qb_list}->[0];
                my $curr_tablist = $treeCtx->{tablist}->[$current_qb];

                my $table_cnt = keys( %{$curr_tablist->{tables}} ); # reset

                my @tab_cols;

                while ( my ($hkk, $hvv) = 
                        each (%{$curr_tablist->{tables}}))
                {
                    my $tpos = $hvv->{tc_table_position};

                    my $col_list = [];
                    
                    # get all the column names
                    for my $colh (@{$hvv->{tc_table_colarr}})
                    {
                        push @{$col_list}, $colh->{colname};
                    }

                    # convert to array of value expressions 
                    for my $colcnt (0..(scalar(@{$col_list})-1))
                    {
                        my $old_colname = $col_list->[$colcnt];

                        # quote the strings to preserve case
                        my $cv = 
                        {quoted_string => '"' . $col_list->[$colcnt] . '"'};

                        # table name doesn't change, but building a
                        # new one each time gives a nicer Data::Dumper
                        # output...
                        my $table_name = 
                        {quoted_string => '"' . $hkk .'"' };

                        my $foo = [];

                        if ($table_cnt > 1)
                        {
                            # don't use table name if only one table
                            push @{$foo}, $table_name;
                        }
                        push @{$foo}, $cv;

                        # build the value expression
                        my $nx = {
                            col_alias => [],
                            value_expression => {
                                column_name => $foo
                                }
                        };
                        $col_list->[$colcnt] = $nx;

                        # FROM SUBQUERY type fixup...
                        if (exists($hvv->{tc_table_colhsh})
                            && exists($hvv->{tc_table_colhsh}->{$old_colname}))
                        {
                            $nx->{value_expression}->{tc_expr_type} = 
                                $hvv->{tc_table_colhsh}->{$old_colname}->[1];

                        }
                    }
                    # store tables in tpos order
                    $tab_cols[$tpos] = $col_list;


                } # end each tablist table

                
                my $sel_list = [];
                for my $tabi (@tab_cols)
                {
                    if (defined($tabi) && scalar(@{$tabi}))
                    {
                        push @{$sel_list}, @{$tabi};
                    }
                }

                $genTree->{select_list} = $sel_list;
            }
        }

        if ($qb_setup)
        {
            # pop from the front
            shift @{$treeCtx->{qb_list}};
        }

    }
    return $genTree;
}

# get column aliases and column "headers"
#
#
sub _get_col_alias # private
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

        while ( my ($kk, $vv) = each ( %{$genTree})) # big while
        {
            if ($kk =~ m/^(column_list)$/)
            {
                $genTree->{tc_column_list} = [];

                for my $all_cols (@{$genTree->{$kk}})
                {
                    my @full_name = _process_name_pieces(@{$all_cols});
                    # build a "dot" separated string
                    my $full_name_str = join('.', @full_name);
                    push @{$genTree->{tc_column_list}}, $full_name_str;
                }
            }
            elsif ($kk !~ m/^(new_column_name|column_name|col_alias)$/)
            {
                $genTree->{$kk} = $self->$subname($vv, $dict, $tc_sth);
            }
            else # column name or alias
            {
                my $isColumnName = ($kk =~ m/column_name$/);

                my @full_name = _process_name_pieces(@{$vv});
                my @full_pos  = _process_name_position(@{$vv});

                my $stat_pos = [];
                if (scalar(@full_pos))
                {
                    $stat_pos->[0] = $full_pos[0]->[0];
                    $stat_pos->[1] = $full_pos[-1]->[1];
                }

                # last portion should be column name (if not an alias)
                my $column_name;
                $column_name = pop @full_name
                    if ($isColumnName);

                # build a "dot" separated string
                my $full_name_str = join('.', @full_name);

                if ($isColumnName)
                {
                    # just build the names here -- lookup in dictionary later
                    $genTree->{tc_col_tablename} = $full_name_str
                        if (scalar(@full_name));

                    if ($kk =~ m/^new_column_name$/)
                    {
                        $genTree->{tc_newcolumn_name} = $column_name;
                    }
                    else
                    {
                        $genTree->{tc_column_name}          = $column_name;
                        $genTree->{tc_column_name_stat_pos} = $stat_pos;
                    }

                }
                else # column alias
                { 
                    # don't build an alias unless we really have one
                    if (scalar(@full_name))
                    {
                        # alias for later reference
                        $genTree->{tc_col_fullalias} = $full_name_str;
                        
                        # column "header" for formatting output is the
                        # same as the alias
                        $genTree->{tc_col_header}    = $full_name_str;
                        
                        # start in current query block
                        # find our tablist
                        # add our new select list column alias
                        my $current_qb   = $treeCtx->{qb_list}->[0];
                        my $curr_tablist = $treeCtx->{tablist}->[$current_qb];

                        my $qb_aliases     = 
                            $curr_tablist->{select_list_aliases};
                        my $select_col_num = 
                            $curr_tablist->{select_col_num};
                        $curr_tablist->{select_col_num} += 1;
                        
                        if (exists($qb_aliases->{$full_name_str}))
                        {
                            # error: duplicate alias
                            my $dupa = 
                                $treeCtx->{tc_err}->{duplicate_alias};

                            if (exists($dupa->{$full_name_str}))
                            {
                                # count duplicates!
                                $dupa->{$full_name_str} += 1;
                            }
                            else
                            {
                                $dupa->{$full_name_str} = 1;
                            }

                            # XXX XXX: is this illegal?

                            my $msg = "duplicate alias: " .
                                "\'$full_name_str\'";

                            my %earg = (self => $self, msg => $msg,
                                        statement => $tc_sth->{statement},
                                        severity => 'warn');
                            
                            &$GZERR(%earg)
                                if (defined($GZERR));
                            
                            # XXX XXX XXX return undef
                        }
                        else # update the alias with position info
                        {
                            # XXX XXX XXX: what else goes here?

                            my $foo = {};
                            $foo->{p1} = $genTree->{p1};
                            $foo->{p2} = $genTree->{p2};
                            $foo->{select_col_num} = $select_col_num;
                            $qb_aliases->{$full_name_str} = $foo;

                        }
                        
                    }
                    else # no alias
                    {
                        # derive column "header" from input txt -- the
                        # default header is just the text of the
                        # expression.  
                        my $col_hd;

                        if (exists($genTree->{p1}))
                        {
                            $col_hd = 
                                substr($treeCtx->{statement},
                                       $genTree->{p1},
                                       ($genTree->{p2} - $genTree->{p1}) + 1
                                       );
                            $col_hd =~ s/^\s*//; # trim leading spaces
                        }
                        else
                        {
                            # XXX XXX: generated col for STAR - fake it
                            
                            # XXX XXX: assume have a column name
                            my $npa = 
                                $genTree->{value_expression}->{column_name};
                            
                            my @col_name = 
                                _process_name_pieces(@{$npa});

                            $col_hd = join(".", @col_name);
                        }
                        
                        $genTree->{tc_col_header}    = $col_hd;
                    }
                }  # end col alias
            }
        } # end big while

        if ($qb_setup)
        {
            # pop from the front
            shift @{$treeCtx->{qb_list}};
        }

    }
    return $genTree;
}

# recursive function to decorate column info
#
#
sub _get_col_info # private
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

      L_bigw:
        while ( my ($kk, $vv) = each ( %{$genTree})) # big while
        {
            if ($kk !~ m/^(tc_column_name)$/)
            {
                $genTree->{$kk} = $self->$subname($vv, $dict, $tc_sth);
            }
            else # column name 
            {
                my $full_name_str = undef;
                if (exists($genTree->{tc_col_tablename}))
                {
                    $full_name_str = $genTree->{tc_col_tablename};
                }
                my $column_name = $genTree->{tc_column_name};
                my $stat_pos    = [];
                $stat_pos = ($genTree->{tc_column_name_stat_pos})
                    if (exists($genTree->{tc_column_name_stat_pos}));

                # XXX XXX XXX: need to deal with table.rid...
                if ($column_name =~ m/^(rid|rownum)$/i)
                {
                    if ($column_name =~ m/^(rid)$/i)
                    {
                        $genTree->{tc_expr_type} = 'c';
                    }
                    else
                    {
                        $genTree->{tc_expr_type} = 'n';
                    }

                    # XXX XXX: need to deal with other pseudo cols like 
                    # sysdate...

                    # rid and rownum are valid
                    next L_bigw;
                }

                my $foundCol = 0;

                # start in current query block
                my $current_qb = $treeCtx->{qb_list}->[0];
                
                # NOTE: search backward from most recent
                # (innermost) query block to earliest (outermost)
              L_qb:
                for (my $qb_num = $current_qb;
                     (defined($qb_num) && ($qb_num > 0));
                     $qb_num--)
                {
                    my $qb2 = $treeCtx->{tablist}->[$qb_num]->{tables};
                    
                    # if have a tablename, look there
                    if (defined($full_name_str))
                    {
                        next L_qb
                            unless (exists($qb2->{$full_name_str}));
                        
                        my $h1 = $qb2->{$full_name_str}->{tc_table_colhsh};
                        next L_qb
                            unless (exists($h1->{$column_name}));

                        $genTree->{tc_column_num} = 
                            $h1->{$column_name}->[0];
                        $genTree->{tc_expr_type} = 
                            $h1->{$column_name}->[1];
                        $genTree->{tc_column_qb} = $qb_num;
                        $foundCol = 1;
                        last L_qb; # done!
                    }
                    else
                    {
                        # need to check all tables in block
                        
                        keys( %{$qb2} ); # XXX XXX: need to reset 

                      L_littlew:
                        while ( my ($hkk, $hvv) = 
                                each ( %{$qb2})) # little while
                        {
                            my $h1 = $hvv->{tc_table_colhsh};
                            next L_littlew
                                unless (exists($h1->{$column_name}));

                            # check all tables in current query block
                            # for duplicate column names
                            if ($foundCol)
                            {
                                my $msg = "column name " .
                                    "\'$column_name\' is ambiguous -- ";

                                $msg .= "tables \'" .
                                    $genTree->{tc_col_tablename} . 
                                    "\', \'" . $hkk . "\'";

                                my %earg = (self => $self, msg => $msg,
                                            statement => $tc_sth->{statement},
                                            stat_pos  => $stat_pos,
                                            severity => 'warn');
                                
                                &$GZERR(%earg)
                                    if (defined($GZERR));
                                
                                last L_qb;
                            }
                                

                            # set the table name
                            $genTree->{tc_col_tablename} = $hkk;
                            
                            $genTree->{tc_column_num} = 
                                $h1->{$column_name}->[0];
                            $genTree->{tc_expr_type} = 
                                $h1->{$column_name}->[1];
                            $genTree->{tc_column_qb} = $qb_num;
                            $foundCol = 1;
#                                last L_qb;
                        } # end little while

                        last L_qb
                            if ($foundCol);
                    }
                } # end for each qb num
                unless ($foundCol)
                {
                    push @{$treeCtx->{tc_err}->{nosuch_column}}, 
                         $full_name_str;
                    
                    my $msg = "column \'$column_name\' not found\n";

                    my %earg = (self => $self, msg => $msg,
                                statement => $tc_sth->{statement},
                                stat_pos  => $stat_pos,
                                severity => 'warn');
                    
                    &$GZERR(%earg)
                        if (defined($GZERR));
                    
#                       return undef; # XXX XXX XXX XXX
                }

            } # end is col name
        } # end big while

        if ($qb_setup)
        {
            # pop from the front
            shift @{$treeCtx->{qb_list}};
        }
        
    }
    return $genTree;
}

    # transform standard sql relational operators to Perl-style,
    # distinguishing numeric and character comparisons
    my $relop_map = 
    {
        '==' => { "n" => "==",  "c" => "eq"},
        '='  => { "n" => "==",  "c" => "eq"},
        '<>' => { "n" => "!=",  "c" => "ne"},
        '!=' => { "n" => "!=",  "c" => "ne"},
        '>'  => { "n" => ">",   "c" => "gt"},
        '<'  => { "n" => "<",   "c" => "lt"},
        '>=' => { "n" => ">=",  "c" => "ge"},
        '<=' => { "n" => "<=",  "c" => "le"},

        '<=>' => { "n" => "<=>",  "c" => "cmp"}
    };


# comp_op fixup
#
#
sub _fixup_comp_op
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

        # grab the WHERE clause text
        if (exists($genTree->{sc_tree}))
        {
            if (exists($genTree->{p1})
                && exists($genTree->{p2}))
            {
                my $pos1 = $genTree->{p1};
                my $pos2 = $genTree->{p2};

                my $sc_txt =
                    substr($treeCtx->{statement},
                           $pos1,
                           ($pos2 - $pos1) + 1
                           );
                
                $genTree->{sc_txt} = $sc_txt;
            }
        }

        # XXX XXX XXX: Get text for update col = expression...
        if (exists($genTree->{operator}))
        {
            if (($genTree->{operator} eq "=") &&
                (exists($genTree->{p1})
                 && exists($genTree->{p2})))
            {
                my $pos1 = $genTree->{p1};
                my $pos2 = $genTree->{p2};

                my $vx_txt =
                    substr($treeCtx->{statement},
                           $pos1,
                           ($pos2 - $pos1) + 1
                           );
                
                $genTree->{vx_txt} = $vx_txt;
            }
        }


        if (exists($genTree->{comp_op}))
        {
#            print $genTree->{operator}, "\n";

            # fixup the perl operators
            if (($genTree->{comp_op} eq 'comp_perlish')
                && (3 == scalar(@{$genTree->{operands}})))
            {
                my $op1 = 
                    $genTree->{operands}->[1];
                $genTree->{operands}->[1] = {
                    tc_comp_op   => $op1,
                    orig_comp_op => $op1
                    };

                my $op2 =
                    $genTree->{operands}->[2];

                # XXX XXX: op2 should be an array of 
                # perl regex pieces -- reassemble it.  
                # may need to do some work for non-standard
                # quoting
                my $perl_lit = join("", @{$op2});

                $genTree->{operands}->[2] = {
                    string_literal => $perl_lit,
                    orig_reg_exp => $op2
                    };
            }

          L_for_ops:
            for my $op_idx (0..(@{$genTree->{operands}}-1))
            {
                my $op1 = $genTree->{operands}->[$op_idx]; 

#                print $op1, "\n", ref($op1), "\n";

                next L_for_ops
                    if (ref($op1)); # ref is false for scalar non-ref

#                print $op1, "\n";

                my $tok_expr = '(<=>|cmp|eq|==|<>|lt|gt|le|ge|!=|<=|>=|<|>|=)';

                next L_for_ops
                    unless ($op1 =~ m/^$tok_expr$/);

                next L_for_ops
                    unless (exists($relop_map->{$op1}));

                my $h1 = $relop_map->{$op1};

                my $left_op  = $genTree->{operands}->[$op_idx - 1]; 
                my $right_op = $genTree->{operands}->[$op_idx + 1]; 

                my $op_type = '?';

                if ((ref($left_op) eq 'HASH') && 
                    (exists($left_op->{tc_expr_type})))
                {
                    $op_type = $left_op->{tc_expr_type};
                } # else type is char by default

                # char takes precedence over number, so only test
                # right side if left side was numeric
                if (($op_type ne 'c') &&
                    (ref($right_op) eq 'HASH') && 
                    (exists($right_op->{tc_expr_type})))
                {
                    $op_type = $right_op->{tc_expr_type};
                }
                
                $op_type = 'c' # only allow c or n
                    unless ($op_type =~ m/^(n|c)$/);

                # update the operator 
                $genTree->{operands}->[$op_idx] = {
                    tc_comp_op   => $h1->{$op_type},
                    orig_comp_op => $op1
                    };

            } # end for
        }

        if ($qb_setup)
        {
            # pop from the front
            shift @{$treeCtx->{qb_list}};
        }

    }
    return $genTree;
}


sub _find_aggregate_functions
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

        if (exists($genTree->{function_name}))
        {
            my $fname = uc($genTree->{function_name});
            if (exists($self->{aggregate_functions}->{$fname}))
            {
                # perform final aggregation

                # need to generate stages to perform aggregate
                # initialization and intermediate aggregation

                $genTree->{aggregate_stage} =
                    "finalize";
            }
            else
            {
                if (exists($genTree->{operands}))
                {
                    my $ops = $genTree->{operands};
                    if (scalar(@{$ops})
                        && (exists($ops->[0]->{all_distinct})))
                    {
                        if (scalar(@{$ops->[0]->{all_distinct}}))
                        {
                            # invalid all/distinct qualifier 
                            # for non-aggregate function

                            my $adq = $ops->[0]->{all_distinct}->[0];

                            my $msg = "invalid argument ". 
                                "\'$adq\' for non-aggregate function \'$fname\'";

                            my %earg = (self => $self, msg => $msg,
                                        statement => $tc_sth->{statement},
                                        severity => 'warn');

                            push @{$treeCtx->{tc_err}->{invalid_args}},  $msg;
                            
                            &$GZERR(%earg)
                                if (defined($GZERR));
                            
                        }
                    }
                }
            }
        }
    
        if ($qb_setup)
        {
            # pop from the front
            shift @{$treeCtx->{qb_list}};
        }

    }
    return $genTree;
} # end _find_aggregate_functions


sub _check_aggregate_functions
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

        my $got_one = 0;
        if (exists($genTree->{alg_op_name}))
        {
            $got_one = 1;
            push @{$treeCtx->{tc_agg_check}}, $genTree;
        }

        if (exists($genTree->{aggregate_stage}))
        {
            my $op_node = $treeCtx->{tc_agg_check}->[-1];
            my $fname   = ($genTree->{function_name});
            
            if (exists($op_node->{alg_op_name}))
            {
                if ($op_node->{alg_op_name} eq 'project')
                {
                    # will need to check project to determine if all
                    # projected columns are aggregates or GROUPed
                    $op_node->{tc_has_agg} = 1;
                }


                # aggregates are legal in HAVING, ORDER BY,
                # and illegal in WHERE clause

                # XXX XXX : also illegal in JOIN conditions...

                if (($op_node->{alg_op_name} eq 'filter')
                    && ($op_node->{alg_filter_type} eq 'WHERE'))
                {
                    my $msg = "illegal use of" .
                        " aggregate function \'$fname\' in WHERE clause";

                    my %earg = (self => $self, msg => $msg,
                                statement => $tc_sth->{statement},
                                severity => 'warn');

                    push @{$treeCtx->{tc_err}->{invalid_args}},  $msg;
                    
                    &$GZERR(%earg)
                        if (defined($GZERR));
                }
            }

        }


        while ( my ($kk, $vv) = each ( %{$genTree})) # big while
        {
            $genTree->{$kk} = $self->$subname($vv, $dict, $tc_sth);
        }

        if ($got_one) 
        {
            pop @{$treeCtx->{tc_agg_check}};
        }

    }
    return $genTree;
} # end _check_aggregate_functions



sub GetFromWhereEtc
{
    my $self = shift;
    
    my %required = (
                    algebra   => "no algebra !",
                    dict      => "no dictionary !",
                    );

    my %optional = (top_cmd => "SELECT");

    my %args = (%optional,
                @_);
    
    return undef
        unless (Validate(\%args, \%required));


    my $algebra = $args{algebra};

    my $tc4 = {}; # type check tree context for tree walker
    # NOTE: we stashed the statement handle in the top of the 
    # algebra when we did typechecking earlier
    my $tc_sth = $algebra->{tc_sth};
    $tc_sth->{tc4} = $tc4;

    # NOTE: clear out the "statement handle" since it's not part of
    # the algebra and we don't want to walk it
    $algebra->{tc_sth} = undef;

    # local tree walk state
    $tc4->{top_qb_num} = 1;     # top query block number is 1
    if ($args{top_cmd} =~ m/INSERT/i)
    {
        # NOTE: "top" query block number 2 for INSERT...SELECT 
        # (use qb 1 to resolve insert table/column info)
        $tc4->{top_qb_num} = 2; 
    }

    $tc4->{qb_list} = []; # build an arr starting with current query block num

    greet $tc4;

    $tc4->{index_keys} = []             # only build index keys 
        if ($tc_sth->{tc3}->{AndPurity}); # if pure AND search condition


    $algebra = $self->_get_from_where($algebra, $args{dict}, $tc_sth);

    my $from       = $tc4->{from};
    my $sel_list   = $tc4->{select_list};
    my $where      = $tc4->{where};

    # XXX XXX XXX: need to localize AndPurity per WHERE clause/search cond
    my $and_purity = $tc_sth->{tc3}->{AndPurity};

    $tc4->{where}->[0]->{sc_and_purity} = $and_purity;
    if ($and_purity)
    {
        $tc4->{where}->[0]->{sc_index_keys} = $tc4->{index_keys};
    }
    # XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX 

    # NOTE: replace the "statement handle" 
    $algebra->{tc_sth} = $tc_sth;

    return ($algebra, $from, $sel_list, $where);
}

# transition from old parser to new...
#
sub _get_from_where
{
#    whoami;

    # NOTE: get the current subroutine name so it is easier 
    # to call recursively
    my $subname = (caller(0))[3];

    my $self = shift;
    # generic tree of hashes/arrays
    my ($genTree, $dict, $tc_sth) = @_;

    my $treeCtx = $tc_sth->{tc4};

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

        if (scalar(@{$treeCtx->{qb_list}}))
        {
            my $current_qb = $treeCtx->{qb_list}->[0];
            
            if ($current_qb == $treeCtx->{top_qb_num})
            {

                if (exists($genTree->{from_clause}))
                {
                    $treeCtx->{from} = $genTree->{from_clause};
                }
                if (exists($genTree->{select_list}))
                {
                    $treeCtx->{select_list} = $genTree->{select_list};
                }
                # distinguish WHERE and HAVING clauses...
                if (exists($genTree->{search_cond}) &&
                    (exists($genTree->{alg_op_name}) &&
                     ($genTree->{alg_op_name} eq 'filter')) &&
                    (exists($genTree->{alg_filter_type}) &&
                     ($genTree->{alg_filter_type} eq 'WHERE')))
                {
                    $treeCtx->{where} = $genTree->{search_cond};
                }
            }
        }

        while ( my ($kk, $vv) = each ( %{$genTree})) # big while
        {
            if (($kk =~ m/tc_index_key/) &&
                exists($treeCtx->{index_keys}))
            {
                # build big list of index keys
                push @{$treeCtx->{index_keys}}, @{$vv};
            }
            # convert subtree first...
            $genTree->{$kk} = $self->$subname($vv, $dict, $tc_sth);
        }

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

Perform type-checking/analysis on relational algebra.

=head1 ARGUMENTS

=head1 FUNCTIONS

=over 4

=item TypeCheck

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

=item  need to generate stages to perform aggregate initialization and intermediate aggregation

=item  check for aggregates in WHERE clause

=item  check for GROUPing/aggregates

=item  check for final select list columns vs all projected columns in all clauses

=item  check args for all functions

=item check for function existance in GenDBI and main namespaces

=item update pod

=item need to handle FROM clause subqueries -- some tricky column type issues.  check for duplicate aliases/type mismatch in _FROM_subq_star_fixup ?

=item check bool_op - AND purity if no OR's.

=item check relational operator (comp_op, relop)

=item handle ddl/dml (create, insert, delete etc with embedded queries) by
      checking for query_block info -- look for hash with 'query_block'
      before attempting table/col resolution.  Need special type checking
      for these functions.

=item refactor to common TreeWalker 

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
