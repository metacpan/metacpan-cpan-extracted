#!/usr/bin/perl
#
# $Header: /Users/claude/fuzz/lib/Genezzo/Parse/RCS/SQLGrammar.pl,v 7.13 2006/10/26 07:27:13 claude Exp claude $
#
# copyright (c) 2005, 2006 Jeffrey I Cohen, all rights reserved, worldwide
#
#
use Parse::RecDescent;
use Data::Dumper;
use strict;
use warnings;

$::RD_HINT  = 1;
#$::RD_TRACE = 1;

#    $::RD_AUTOACTION = q
#{ $#item==1 ? $item[1] : new ${"$item[0]_node"} (@item[1..$#item]) 
#  };
$::RD_AUTOACTION = q { 
    if ($item[0] !~ m/_$/) 
    {
        [@item] ;
    }
    else
    {
        @item[1..$#item];
    }
};
#$::RD_AUTOACTION = q { {\%item} };

#  select a from t1
#  select a as b from t1 
#  select a b from t1
#  
#  select a, d from t1
#  select a as b, d from t1 
#  select a b, d from t1
#  
#  select a, d as e from t1
#  select a as b, d as e from t1 
#  select a b, d as e from t1
#  
#  select a, d  e from t1
#  select a as b, d  e from t1 
#  select a b, d  e from t1
#  
#  select a, d, f from t1
#  select all a, d, f from t1
#  select distinct a, d, f from t1
#  
#  

## depth > 2??  forgot (s?) modifier, e.g.: foo: (bar ',')(s?) bar
#
# update ggg set a=b, (c,d) = e, g = h 
# update ggg set a=b,  g = h  
#  
#  update t1 set a=b
#  update t1 set a=b, c=d
#  update t1 set a=b, c=d, e=f
#  update t1 set a=b, c=d, e=f, g=h
#  
#  update t1 set (a,c) = (b,d)
#  update t1 set a=b, c=d, e=f
#  update t1 set a=b, c=d, e=f, g=h
#  
#  
#  
# need to parse a.b.c.colname as well as a::b::c.colname and combos


## XXX XXX: use an ANTLR-like rule - don't generate AST nodes for
## rules which end in underscore

my @res_word_rules = # list of all reserved words
    qw(
       ABSOLUTE_ ACTION_ ADD_ ALL ALLOCATE_ ALTER_ AND ANY_ ARE_ ASC_
       ASSERTION_ AS_ AT_ AUTHORIZATION_ AVG_ sqBEGIN_ BETWEEN_ BIT_
       BIT_LENGTH_ BOTH_ BY_ CASCADED_ CASCADE_ CASE_ CAST_ CATALOG_
       sqCHARACTER CHARACTER_LENGTH_ sqCHAR CHAR_LENGTH_ sqCHECK_ CLOSE_
       COALESCE_ COLLATE_ COLLATION_ COLUMN_ COMMIT_ CONNECTION_
       CONNECT_ CONSTRAINTS_ CONSTRAINT_ CONTINUE_ CONVERT_
       CORRESPONDING_ COUNT_ CREATE_ CROSS CURRENT_ CURRENT_DATE_
       CURRENT_TIMESTAMP_ CURRENT_TIME_ CURRENT_USER_ CURSOR_ DATE_
       DAY_ DEALLOCATE_ DECIMAL DECLARE_ DEC DEFAULT DEFERRABLE_
       DEFERRED_ DELETE_ DESCRIBE_ DESCRIPTOR_ DESC_ DIAGNOSTICS_
       DISCONNECT_ DISTINCT DOMAIN_ DOUBLE DROP_ ELSE_ sqEND_
       END_EXEC_ ESCAPE_ EXCEPTION_ EXCEPT EXECUTE_ EXEC_ EXISTS_
       EXTERNAL_ EXTRACT_ FALSE FETCH_ FIRST_ FLOAT FOREIGN FOR_
       FOUND_ FROM_ FULL GET_ GLOBAL_ GOTO_ GO_ GRANT_ GROUP_ HAVING_
       HOUR_ IDENTITY_ IMMEDIATE_ INDICATOR_ INITIALLY_ INNER INPUT_
       INSENSITIVE_ INSERT_ INTEGER INTERSECT INTERVAL_ INTO_ INT
       IN_ ISOLATION_ IS JOIN KEY LANGUAGE_ LAST_ LEADING_ LEFT
       LEVEL_ LIKE_ LOCAL_ LOWER_ MATCH_ MAX_ sqMINUS MINUTE_ MIN_
       MODULE_ MONTH_ NAMES_ NATIONAL_ NATURAL NCHAR_ NEXT_ NOT NO_
       NULLIF_ NULL sqNUMERIC OCTET_LENGTH_ OF_ ONLY_ ON OPEN_
       OPTION_ ORDER_ OR OUTER OUTPUT_ OVERLAPS_ PAD_ PARTIAL_
       POSITION_ PRECISION PREPARE_ PRESERVE_ PRIMARY PRIOR_
       PRIVILEGES_ PROCEDURE_ PUBLIC_ READ_ REAL REFERENCES_
       RELATIVE_ RESTRICT_ REVOKE_ RIGHT ROLLBACK_ ROWS_ SCHEMA_
       SCROLL_ SECOND_ SECTION_ SELECT_ SESSION_ SESSION_USER_ SET_
       SIZE_ SMALLINT SOME_ SPACE_ SQLCODE_ SQLERROR_ SQLSTATE_ SQL_
       SUBSTRING_ SUM_ SYSTEM_USER_ TABLE_ TEMPORARY_ THEN_ TIMESTAMP_
       TIMEZONE_HOUR_ TIMEZONE_MINUTE_ TIME_ TO_ TRAILING_
       TRANSACTION_ TRANSLATE_ TRANSLATION_ TRIM_ TRUE UNION UNIQUE
       UNKNOWN_ UPDATE_ UPPER_ USAGE_ USER_ USING VALUES_ VALUE_
       VARCHAR VARCHAR2 VARYING VIEW_ WHENEVER_ WHEN_ WHERE_ WITH_ WORK_
       WRITE_ YEAR_ ZONE_
       ECOUNT
       );
# XXX XXX XXX: need to make ECOUNT a reserved word...

# function names and function-like subquery expressions
# Note: special rule to handle COUNT (for COUNT(*)...)
# XXX XXX: plus ECOUNT...
my @standard_funcs = qw(
                        MIN
                        MAX
                        AVG
                        SUM
                        MEAN
                        STDDEV
                        IN
                        INT
                        EXISTS
                        ANY
                        SOME
                        ALL
                        UNIQUE
                        LIKE
                        TRANSLATE
                        TRIM
                        UPPER
                        LOWER
                        );

my %std_funcs;

for my $fname (@standard_funcs)
{
    $std_funcs{$fname} = 1;
}

my $grammar;

my (@all_res_words, @res_minus_fns);

# build rule for each word
for my $ww (@res_word_rules)
{

    # reserved words with trailing underscore are "private" -- they do
    # not show up in the AST.
    my $private1 = ($ww =~ m/\_$/);

    # strip off trailing underscore for match rule
    my $rul = $private1 ?  substr($ww, 0, -1) : $ww;

    # reserved words with a leading lowercase "sq", like "sqBEGIN",
    # need the sq removed for the real token.  Keep the "sq" in the
    # rule name to avoid conflicts with special grammar constructs.
    $rul = substr($rul, 2) if ($rul =~ m/^sq/);

    # build a rule - match case insensitively
    $grammar .= $ww . ' : /' . $rul . '/i';
    $grammar .= "\n" . '  { [] }' . "\n" if $private1; # no action

    $grammar .= "\n\n";

    # XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX
    # build a regexp with negative lookahead in order to allow
    # identifiers with a reserved word prefix, e.g. a column 
    # COUNTY which contains the prefix COUNT.
    # XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX
    my $regex = $rul . '(?!([a-z0-9_]))';
    push @all_res_words, $regex; 

    # don't put valid function names in this list...
    push @res_minus_fns, $regex
        unless (exists($std_funcs{uc($rul)}));
}

@all_res_words = sort @all_res_words;
@res_minus_fns = sort @res_minus_fns;

# build a rule to match all reserved words...
$grammar .= 'reserved_word:  /' . 
    join('|', @all_res_words);
$grammar .=  "/i \n\n";

# build a rule to match all reserved words that aren't valid function names
$grammar .= 'reserved_non_funcs: /' .
    join('|', @res_minus_fns);
$grammar .=  "/i \n\n";

# build the rest of the grammar
($grammar .= << 'END_OF_GRAMMAR') =~ s/^\#.*//gm;

# start all comments in column zero so they get stripped out
# XXX XXX: comment stripping not necessary

        sql_000 : sql_dml end_of_query
                 {  $item[1] }
                | sql_ddl end_of_query
                 {  $item[1] }
                | { 
# trick to reroute error messages
                    foreach (@{$thisparser->{errors}}) {

                        my $msg = "Line $_->[1]:$_->[0]\n";

                        # check for a special error hook
                        if (defined(&gnz_err_hook))
                        {
                            gnz_err_hook($msg);
                        }
                        else
                        {
                            print $msg;
                        }
                    }
                    $thisparser->{errors} = undef;
                }


        sql_dml : sql_insert 
{ $return = {sql_insert => $item{sql_insert}}}
                | sql_update 
{ $return = {sql_update => $item{sql_update}}}
                | sql_delete 
{ $return = {sql_delete => $item{sql_delete}}}
                | top_query
# top query is always a sql query
{ $return = $item{top_query}}
                | <error: unknown or invalid command>

# DDL ALTER, DROP, CREATE
        sql_ddl : sql_alter 
{ $return = {sql_alter => $item{sql_alter}}}
                | sql_drop 
{ $return = {sql_drop => $item{sql_drop}}}
                | sql_create 
{ $return = {sql_create => $item{sql_create}}}
                | <error: unknown or invalid command>

#        sql_alter  : ALTER_ <commit> ddl_object
#{ $return = $item{ddl_object}}
        sql_alter  : ALTER_ <commit> alter_guts
{ $return = $item{alter_guts}}

        sql_create : CREATE_ <commit> create_guts
{ $return = $item{create_guts}}

        sql_drop   : DROP_ <commit> ddl_object
{ $return = $item{ddl_object}}

        ddl_object : TABLE_ table_name 
{ $return = { table_name   => $item{table_name} }}    
                   | VIEW_  table_name
{ $return = { view_name   => $item{table_name} }}    
                   | /INDEX/i  table_name
{ $return = { index_name   => $item{table_name} }}    
                   | /TABLESPACE/i  table_name
{ $return = { tablespace_name   => $item{table_name} }}    

       alter_guts : TABLE_ table_name add_table_cons
{ $return = { table_name     => $item{table_name},
              add_table_cons => $item{add_table_cons}
          }
}    

       create_guts : TABLE_ table_name create_table_def
{ $return = { 
              create_op       => "TABLE",
              new_table_name  => $item{table_name},
              table_def       => $item{create_table_def}
          }
}    
                   | /INDEX/i  big_id ON table_name column_list 
                     storage_clause(?)
{ $return = { 
              create_op      => "INDEX",
              new_index_name => $item{big_id},
              table_name     => $item{table_name},
              column_list    => $item{column_list},
              storage_clause   => $item{'storage_clause(?)'}
          }
}
                   | /TABLESPACE/i  identifier
{ $return = { 
              create_op => "TABLESPACE",    
              new_tablespace_name   => [$item{identifier}] }}
    
       ct_as_select: AS_ sql_query
{ $return = {sql_query      => $item{sql_query}}}

# XXX XXX: optional table_constraint before table_elt_list [elcaro]
# table element list is optional for create table as select
# XXX XXX: need some sort of storage clause before ctas
   create_table_def: table_constraint_def(?) 
                     table_element_list(?) 
                     storage_clause(?)
                     ct_as_select(?)
{ $return = {tab_column_list  => $item{'table_element_list(?)'},
             table_query      => $item{'ct_as_select(?)'},
             table_constraint => $item{'table_constraint_def(?)'},
             storage_clause   => $item{'storage_clause(?)'}
         }
}

storage_clause: /TABLESPACE/i  identifier
{ $return = { 
              store_op        => "TABLESPACE",    
              tablespace_name => [$item{identifier}] }}

table_element_list: '(' <commit> table_elt(s /,/) ')'                    
# skip parens
# lparen is 1, commit is 2, column list is 3
# cannot use item{table_elt} because it repeats...    
{ my @foo = @{$item[3]}; $return = \@foo; }
                       | <error: invalid column list>

# column definition or table_constraint 
# column type is optional for create table as select
        table_elt : column_name column_type(?) 
                    column_default(?) col_cons_list(?)
{$return = {new_column_name => $item{column_name},
            column_type     => $item{'column_type(?)'},
            column_default  => $item{'column_default(?)'},
            col_cons_list   => $item{'col_cons_list(?)'}}}
                  | table_constraint_def
{$return = {table_constraint => $item{table_constraint_def}}}

   column_default : DEFAULT value_expression
{$return = $item{value_expression}}

   col_cons_list  : column_constraint_def(s)
{$return = $item[1]}

# XXX XXX: need constraint attibutes - deferrable, DISABLE etc
column_constraint_def: constraint_name(?) col_cons
{$return = {name => $item{'constraint_name(?)'},
            constraint => $item{col_cons}
        }
}
 table_constraint_def: constraint_name(?) table_cons
{$return = {name => $item{'constraint_name(?)'},
            constraint => $item{table_cons}
        }
}

# use to disambiguate column list for FOREIGN KEY and list for REFERENCES
 fkref_column_list: column_list
{$return = $item[1]}

  constraint_name : CONSTRAINT_ big_id
{$return = $item{big_id}}

# XXX XXX: references on delete cascade - referential action
     col_cons     : NOT(?) NULL
{$return = {operator => $item[2],
            cons_type => 'nullable',
            operands => $item{'NOT(?)'}            
            }}
                  | UNIQUE
{$return = {operator => $item[1],
            cons_type => 'unique'
            }}
                  | PRIMARY KEY
{$return = {operator => $item[1],
            cons_type => 'primary_key'
            }}
                  | REFERENCES_ big_id fkref_column_list
{$return = {operator => $item[1],
            cons_type => 'foreign_key',
            operands => 
            {
                table       => $item{big_id},
                keycols     => $item{fkref_column_list}
            }
        }
}
                  | sqCHECK_ '(' search_cond ')'
{
#
# get start/stop position for search condition
#
    my $p1 = $itempos[3]{offset}{from};
    my $p2 = $itempos[3]{offset}{to};
    $return = {operator => $item[1],
               cons_type => 'check',
               operands => {
                   p1 => $p1,
                   p2 => $p2,
                   sc_tree => $item{search_cond}
               }
           };
}

   table_cons     : UNIQUE column_list 
{$return = {operator => $item[1],
            cons_type => 'unique',
            operands => $item{column_list}, # XXX XXX XXX: cleanup
            column_list => $item{column_list}
        }
}
                  | PRIMARY KEY column_list
{$return = {operator => $item[1],
            cons_type => 'primary_key',
            operands => $item{column_list}, # XXX XXX XXX: cleanup
            column_list => $item{column_list}
        }
}
                  | FOREIGN KEY column_list 
                    REFERENCES_ big_id fkref_column_list
{$return = {operator => $item[1],
            cons_type => 'foreign_key',
            operands => 
            {
                column_list => $item{column_list},
                table       => $item{big_id},
                keycols     => $item{fkref_column_list}
            }
        }
}
                  | sqCHECK_ '(' search_cond ')'
{
#
# get start/stop position for search condition
#
    my $p1 = $itempos[3]{offset}{from};
    my $p2 = $itempos[3]{offset}{to};
    $return = {operator => $item[1],
               cons_type => 'check',
               operands => {
                   p1 => $p1,
                   p2 => $p2,
                   sc_tree => $item{search_cond}
               }
           };
}

   add_table_cons : ADD_ table_constraint_def
{$return = $item{table_constraint_def}}

     col_char_len : '(' numeric_literal ')'
{ $return = $item{numeric_literal} }

     col_num_scale:  ',' numeric_literal
{ $return = $item{numeric_literal} }

     col_num_prec : '(' numeric_literal col_num_scale(?) ')'
{ $return = {
    precision => $item{numeric_literal},
    scale     => $item{'col_num_scale(?)'}
}}

# NOTE WELL: SQL tokens can be substrings of other tokens, which
# messes up matching.  Need to have rules in reverse length order -
# VARCHAR2 before VARCHAR, CHARACTER before CHAR, etc.  "c" and "n"
# rules must be last.
     column_type  : sqCHARACTER VARYING(?) col_char_len(?)
{
    if (scalar(@{$item{'VARYING(?)'}}))
    { 
        $return = 
        { 
            base => 'c',
            spec => 'VARCHAR',
            len  => $item{'col_char_len(?)'}
        };
    }
    else
    { 
        $return = 
        { 
            base => 'c',
            spec => 'CHAR',
            len  => $item{'col_char_len(?)'}
        };
    }
    $return;
}
                  | sqCHAR      VARYING(?) col_char_len(?)
{
    if (scalar(@{$item{'VARYING(?)'}}))
    { 
        $return = 
        { 
            base => 'c',
            spec => 'VARCHAR',
            len  => $item{'col_char_len(?)'}
        };
    }
    else
    { 
        $return = 
        { 
            base => 'c',
            spec => 'CHAR',
            len  => $item{'col_char_len(?)'}
        };
    }
    $return;
}
                  | (/long/i)(?) VARCHAR2 col_char_len(?)
{ 
    $return = 
    { 
        base => 'c',
        spec => 'VARCHAR2',
        len  => $item{'col_char_len(?)'}
    };
}
                  | (/long/i)(?) VARCHAR col_char_len(?)
{ 
    $return = 
    { 
        base => 'c',
        spec => 'VARCHAR',
        len  => $item{'col_char_len(?)'}
    };
}
                  | sqNUMERIC col_num_prec(?)
{ 
    $return = 
    { 
        base => 'n',
        spec => 'NUMERIC',
        precision  => $item{'col_num_prec(?)'}
    };
}
# elcaro number
                  | /number/i col_num_prec(?)
{ 
    $return = 
    { 
        base => 'n',
        spec => 'NUMERIC',
        precision  => $item{'col_num_prec(?)'}
    };
}

                  | DECIMAL col_num_prec(?)
{ 
    $return = 
    { 
        base => 'n',
        spec => 'DECIMAL',
        precision  => $item{'col_num_prec(?)'}
    };
}
                  | DEC col_num_prec(?)
{ 
    $return = 
    { 
        base => 'n',
        spec => 'DECIMAL',
        precision  => $item{'col_num_prec(?)'}
    };
}
                  | INTEGER
{ 
    $return = 
    { 
        base => 'n',
        spec => 'INTEGER'
    };
}
                  | INT
{ 
    $return = 
    { 
        base => 'n',
        spec => 'INTEGER'
    };
}
                  | SMALLINT
{ 
    $return = 
    { 
        base => 'n',
        spec => 'SMALLINT'
    };
}
                  | FLOAT col_num_prec(?)
{ 
    $return = 
    { 
        base => 'n',
        spec => 'FLOAT',
        precision  => $item{'col_num_prec(?)'}
    };
}
                  | REAL
{ 
    $return = 
    { 
        base => 'n',
        spec => 'REAL'
    };
}
                  | DOUBLE PRECISION
{ 
    $return = 
    { 
        base => 'n',
        spec => 'DOUBLE PRECISION'
    };
}
                  | /c/i
{ 
    $return = 
    { 
        base => 'c',
        spec => 'c'
    };
}
                  | /n/i
{ 
    $return = 
    { 
        base => 'n',
        spec => 'n'
    };
}

# DML
# top query can have multiple SELECTs, but only a single ORDER BY clause
        top_query   :  sql_query orderby_clause(?)
{ $return = {sql_query      => $item{sql_query},
             orderby_clause => $item{'orderby_clause(?)'}
         }
}
#                    { [@item[1..$#item] }    
#                    { my $foo = [$item[2]]; push @{$foo}, $item[1]; $foo;}    
        sql_insert  : INSERT_ <commit> INTO_ table_name <commit>
                      column_list(?) insert_values
{

    my $tabinfo = {
        table_name  => $item{table_name}
    };
    if (scalar(@{$item{'column_list(?)'}}))
    {
        # get the optional column list if it exists
        $tabinfo->{column_list} = $item{'column_list(?)'}->[0];
    }
    my $t1 = {insert_tabinfo => $tabinfo};
    my $t2 = {insert_values  => $item{insert_values}};
    $return = [
               # NOTE: split the table info from "values" to create
               # separate, non-nested query blocks.  Needs to be an
               # array to force ordering of qb's, since query block 1
               # must precede query block 2 if not nested, and a hash
               # doesn't guarantee traversal order.
               $t1,
               $t2
               ];
}
        sql_update  : UPDATE_ <commit> table_name SET_
                      update_set_exprlist where_clause(?)
{ $return = { table_name   => $item{table_name},
              update_set_exprlist => $item{'update_set_exprlist'},
              where_clause => $item{'where_clause(?)'}
          }
}
        sql_delete  : DELETE_ <commit> 
                      FROM_ table_name where_clause(?)
{ $return = { table_name   => $item{table_name},
              where_clause => $item{'where_clause(?)'}
          }
}

        update_set_exprlist: update_set_expr(s /,/)
#{ my @foo = @{$item{update_set_expr}}; $return = \@foo; }
{ $return = $item[1] }

# sql92 says only single column UPDATE SET expression, but elcaro 
# allows more...
        update_colthing: column_list 
{$return = {column_list => $item[1]}}
                       | column_name
{$return = {column_name => $item[1]}}
        update_sources : value_expression
{$return = $item{value_expression}}
                       | '(' expr_list ')'
{$return = $item{expr_list}}

# put comp_or_perl first to match "=~" ahead of "="
        update_oplist  : comp_or_perl
{$return = $item{comp_or_perl}}
                       | '=' <commit> update_sources 
{
    $return = {operator => $item[1],
               operands => $item{update_sources}
           }
}

#
# XXX XXX XXX XXX: allow a=b or a =~ s/foo/bar/ perl expression
#
        update_set_expr:  update_colthing update_oplist
{$return = { update_columns => $item{update_colthing},
             update_sources => $item{update_oplist}
             }
}

        subquery    : '(' sql_query ')'                
{ $return = {sql_query => $item{sql_query}}}
        simple_table : sql_select
{ $return = {sql_select => $item{sql_select}}}
                     | /table/i table_name
{ $return = {table => $item{table_name}}}

        sql_query    :  non_join_query 
{ $return = $item{non_join_query}}


# set operations: intersect, union, minus, except, with ALL modifier.
# return {setop=>operation, all=>undef or all=>[ALL]}
        setop_isec   : INTERSECT ALL(?)
{ my @set_op  = @{$item[1]};
  my @set_all = @{$item{'ALL(?)'}};
  $return = {setop => $set_op[0],
             all   => $set_all[0]
             };
}
        setop_union  : UNION     ALL(?)
{ my @set_op  = @{$item[1]};
  my @set_all = @{$item{'ALL(?)'}};
  $return = {setop => $set_op[0],
             all   => $set_all[0]
             };
}
# MINUS equivalent to EXCEPT?
        setop_minus  : sqMINUS   ALL(?)
{ my @set_op  = @{$item[1]};
  my @set_all = @{$item{'ALL(?)'}};
  $return = {setop => 'MINUS', # fix name
             all   => $set_all[0]
             };
}
        setop_except : EXCEPT    ALL(?)
{ my @set_op  = @{$item[1]};
  my @set_all = @{$item{'ALL(?)'}};
  $return = {setop => $set_op[0],
             all   => $set_all[0]
             };
}

        non_join_query : njq_intersect 
{ $return = $item{njq_intersect}}
# this should work since it's not left-recursive
                       | '(' non_join_query ')'
{ $return = $item{non_join_query}}

#
# all njq sql set operations get an array of simpler queries in item[1]
# @set_op has at least one operation
#
        njq_intersect  : <leftop: njq_minus  setop_isec   njq_minus>
{ my @set_op  = @{$item[1]};
  if (exists($item{setop_isec}))
  {
      $return = {sql_setop => $item[0],
                 operands  => \@set_op
                 };
  }
  else
  {
      $return = $set_op[0];
  }
  $return;
}
        njq_minus      : <leftop: njq_union  setop_minus  njq_union>
{ my @set_op  = @{$item[1]};
  if (exists($item{setop_minus}))
  {
      $return = {sql_setop => $item[0],
                 operands  => \@set_op
                 };
  }
  else
  {
      $return = $set_op[0];
  }
  $return;
}
        njq_union      : <leftop: njq_except setop_union  njq_except>
{ my @set_op  = @{$item[1]};
  if (exists($item{setop_union}))
  {
      $return = {sql_setop => $item[0],
                 operands  => \@set_op
                 };
  }
  else
  {
      $return = $set_op[0];
  }
  $return;
}
        njq_except     : <leftop: njq_simple setop_except njq_simple>
{ my @set_op  = @{$item[1]};
  if (exists($item{setop_except}))
  {
      $return = {sql_setop => $item[0],
                 operands  => \@set_op
                 };
  }
  else
  {
      $return = $set_op[0];
  }
  $return;
}

# return a single item array, since other njq rules 
# operate on arrays of simpler queries
        njq_simple     : simple_table
{ $return = {sql_setop => $item[0],
             operands  => [$item{simple_table}]}
}
#{ $return = $item{simple_table}}
#
# this should work since it's not left-recursive
                       | '(' non_join_query ')'
{ $return = $item{non_join_query}}

        all_distinct: ALL 
{ my @ad1 = @{$item[1]};
  $return = $ad1[0]; }
                    | DISTINCT
{ my @ad1 = @{$item[1]};
  $return = $ad1[0]; }

# XXX XXX: need INTO ?
        sql_select  : SELECT_ all_distinct(?) 
                               select_list from_clause
                               where_clause(?)                
                               groupby_clause(?)  
                               having_clause(?)                
#                      { [$item[0], @item[2..$#item]] }
# print Data::Dumper->Dump([%item]), "\n\n"; 
{ $return = {all_distinct   => $item{'all_distinct(?)'},
             select_list    => $item{select_list},
             from_clause    => $item{from_clause},
             where_clause   => $item{'where_clause(?)'},
             groupby_clause => $item{'groupby_clause(?)'},
             having_clause  => $item{'having_clause(?)'}
         }
}

        insert_values  : VALUES_ '(' expr_list ')'
{ $return = $item{expr_list}}
                       | DEFAULT
{ $return = 'DEFAULT'}
                       | sql_query
{ $return = $item{sql_query}}

        column_list    : '(' <commit> column_name(s /,/) ')' 
# skip parens
# lparen is 1, commit is 2, column list is 3
# cannot use item{column_name} because it repeats...    
{ my @foo = @{$item[3]}; $return = \@foo; }
                       | <error: invalid column list>

        where_clause   : WHERE_ search_cond
{
#
# get start/stop position for WHERE clause
#
    my $p1 = $itempos[2]{offset}{from};
    my $p2 = $itempos[2]{offset}{to};
    $return = {
        p1 => $p1,
        p2 => $p2,
        sc_tree => $item{search_cond}
    };
}
        groupby_clause : GROUP_ BY_ expr_list
{ $return = $item{expr_list}}
        having_clause  : HAVING_ search_cond
{ $return = $item{search_cond}}
        orderby_clause : ORDER_ BY_ expr_list
{ $return = $item{expr_list}}

        table_alias : AS_(?) identifier
{ $return =  $item{identifier} }
        table_name  : big_id
{ $return =  $item{big_id}}
                    | <error: invalid tablename>
        select_list : '*' 
{ $return = 'STAR'}
                    | col_expr_list
{ $return =  $item{col_expr_list} }

        from_clause: FROM_ table_list
{ $return = $item{table_list}}
        table_list : table_expr(s /,/)
{ $return = $item[1]}
        table_expr : join_tab
{ $return = $item[1]}
        join_tab   : cross_join
{ $return = $item[1]}
# this should work since it's not left-recursive
                   | '(' join_tab ')'
{ $return = $item[2]}

# XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX 
# START JOIN DEFINITIONS
# XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX 

        cj1            : CROSS JOIN
        cross_join     : <leftop: qualified_join cj1 qualified_join>
{ my @join_op  = @{$item[1]};
  if (exists($item{cj1}))
  {
      $return = {join_op   => $item[0],
                 operands  => \@join_op
                 };
  }
  else
  {
      $return = $join_op[0];
  }
  $return;
}
        qj1            : NATURAL(?) join_type(?) JOIN
        qj_leftop      : <leftop: table_expr_prim qj1 table_expr_prim>
{ my @join_op  = @{$item[1]};
  if (exists($item{qj1}))
  {
      $return = {join_op   => $item[0],
                 operands  => \@join_op
                 };
  }
  else
  {
      $return = $join_op[0];
  }
  $return;
}


# XXX XXX XXX: maybe can collapse qualified join with qj_leftop?

        qualified_join :  qj_leftop join_spec(?)
{

##    print Data::Dumper->Dump([$item[1]]), "\n\n";
# special case because only a single operand
 my @join_op  = [$item[1]];
# is there a non-null join spec array containing ON or USING? 
  if (scalar(@{$item{'join_spec(?)'}}))
  {
      $return = {join_op   => $item[0],
                 operands  => \@join_op,
                 join_spec => $item{'join_spec(?)'}
                 };
  }
  else
  {
      $return = $join_op[0];
  }
  $return;
}

# XXX XXX XXX: optional column list...
        table_expr_prim: table_name         table_alias(?)
{ $return = { table_name   => $item{table_name},
              table_alias  => $item{'table_alias(?)'}
          }
}
                       | '(' sql_query ')'  table_alias(?)
{ $return = { sql_query    => $item{sql_query},
              table_alias  => $item{'table_alias(?)'}
          }
}
# this should work since it's not left-recursive
                       | '(' join_tab ')'
{ $return = $item[2]}



        join_LRF  : LEFT 
{ $return = $item[1] }    
                  | RIGHT 
{ $return = $item[1] }    
                  | FULL
{ $return = $item[1] }    

        join_type : INNER 
{ $return = {$item[0] => $item[1] }}    
                  | join_LRF OUTER(?)
{ $return = {$item[0] => $item[1],
             OUTER    => $item{'OUTER(?)'}
             } 
}   
                  | UNION
{ $return = {$item[0] => $item[1] }}  

        join_spec : ON search_cond
{ $return = {ON => $item{search_cond}}}
                  | USING column_list
{ $return = {USING => $item{column_list}}} 

# XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX 
# END JOIN DEFINITIONS
# XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX 

        column_name   : big_id
{ $return = $item[1] }
                      | <error: invalid column name>
        col_alias  : AS_(?) identifier
{ $return = $item{identifier}}
               
        col_expr   : value_expression col_alias(?)
{
#
# get start/stop position for value expression to make column name
#
    my $p1 = $itempos[1]{offset}{from};
    my $p2 = $itempos[1]{offset}{to};

    $return = { value_expression  => $item{value_expression},
                col_alias         => $item{'col_alias(?)'},
                p1 => $p1, p2 => $p2,
#                col_str           => substr($text, $p1, $p2-$p1)
#                col_str           => substr($text, 0, $p2-$p1+1)
            }
}
        col_expr_list : col_expr(s /,/)
{ my @foo = @{$item[1]}; $return = \@foo; }

        value_expression : num_val
{ $return = $item[1] }    
                         | string_val
{ $return = $item[1] }    
# TRUE FALSE NULL 
                         | bool_TFN
{ $return = $item[1] }
                         | bind_placeholder
{ $return = $item[1] }
# XXX XXX: need user, sysdate, etc
    
        string_val : string_literal
{ $return = {string_literal => $item[1],
             tc_expr_type => 'c'
             }}
#        string_val : concat_expr
#{ $return = $item[1] }
#                   | str_primary
#{ $return = $item[1] }
#

#        num_val   : add_expr
        num_val   : concat_expr
{ $return = $item[1] }

# do DBI-style bind, e.g. "select ?,? from emp"
# get line and column number for bind value to determine order
        bind_placeholder : '?'
{ $return = {bind_placeholder => 
             {offset => $thisoffset
              }}
}

#
# Make concatentation the highest "math" operation
        concat_op   : '||'
{ $return = $item[1] }
        concat_expr : <leftop: add_expr concat_op add_expr>
{ my @math_op  = @{$item[1]};
  if (exists($item{concat_op}))
  {
      $return = {math_op => $item[0],
                 tc_expr_type => 'c',
                 operands  => \@math_op
                 };
  }
  else
  {
      $return = $math_op[0];
  }
  $return;
}

        add_op    : '+' 
{ $return = $item[1] }    
                  | '-'
{ $return = $item[1] }    

        add_expr  : <leftop: mult_expr add_op mult_expr>
{ my @math_op  = @{$item[1]};
  if (exists($item{add_op}))
  {
      $return = {math_op => $item[0],
                 tc_expr_type => 'n',
                 operands  => \@math_op
                 };
  }
  else
  {
      $return = $math_op[0];
  }
  $return;
}

        mult_op   : '*' 
{ $return = $item[1] }    
                  | '/'
{ $return = $item[1] }    

        mult_expr : <leftop: unary_expr mult_op unary_expr>
{ my @math_op  = @{$item[1]};
  if (exists($item{mult_op}))
  {
      $return = {math_op => $item[0],
                 tc_expr_type => 'n',
                 operands  => \@math_op
                 };
  }
  else
  {
      $return = $math_op[0];
  }
  $return;
}
        unary_op  : '+' 
{ $return = $item[1] }    
                  | '-' 
{ $return = $item[1] }    
                  | '!'
{ $return = $item[1] }    

        unary_expr  :  unary_op(?) num_primary1
{  
    if (scalar(@{$item{'unary_op(?)'}}))
    {
        $return = {unary => $item{'unary_op(?)'},
                   tc_expr_type => 'n',
                    val   => $item{num_primary1}
               }
    }
    else
    {
        $return = $item{num_primary1};
    }
    $return;
}                

# e.g. select a=~ s/foo/bar from emp 
# or
# update t1 set a=~ s/foo/bar/ for an update expression
perlish_substitution : '=~'  <perl_quotelike>
{$return = {
    math_op  => 'perlish_substitution',
    operator => $item[1],
    operands => [$item[1], $item[2]]
    }
}

# wrapper for num_primary and num_perlish_substitution
        num_primary1 : num_primary
#        num_primary1 : num_perlish_substitution
{ $return = $item[1] }

# XXX XXX: problem is that substitute operator returns TRUE/FALSE in
# scalar context, not the substituted string.
num_perlish_substitution : num_primary perlish_substitution(?)
{
    if (scalar(@{$item{'perlish_substitution(?)'}}))
    {
        my $op1 = $item{'perlish_substitution(?)'}->[0];
        # add the num_primary to the operand list for perlish substitution
        unshift @{$op1->{operands}}, $item{num_primary};
        $return = $op1;
    }
    else
    {
        $return = $item{num_primary};
    }
    $return;
}
    
        num_primary : value_expr_primary
{ $return = $item{value_expr_primary}}
# function name isn't the the same as an identifier, since
# MIN, MAX, COUNT, etc cannot be identifiers.  Also, note
# that ALL|DISTINCT qualifier is only valid for aggregation/set expressions
                    | function_name ...'(' 
                      '(' <commit> 
                         function_guts(?) ')'
{$return = { function_name => $item{function_name},
             operands      => $item{'function_guts(?)'}
         }
}
# XXX XXX XXX: allow ecount
# treat count special to handle count(*)
                    | /count/i '(' <commit> 
                        countfunc_guts ')'
{$return = { function_name => 'count',
             operands      => $item{'countfunc_guts'}
         }
}
                    | /ecount/i '(' <commit> 
                        countfunc_guts ')'
{$return = { function_name => 'ecount',
             operands      => $item{'countfunc_guts'}
         }
}

 value_expr_primary : '(' value_expression ')'
{ $return = $item{value_expression}}
#
# column name can't be followed by lparen, because then it must be
# a function name.
                    | column_name ...!'('
{ $return = {column_name => $item{column_name}}}
                    | numeric_literal
{ $return = {numeric_literal => $item{numeric_literal},
             tc_expr_type  => 'n'
         }
}
                    | string_literal
{ $return = {string_literal => $item[1],
             tc_expr_type => 'c'
         }
}
                    | bind_placeholder
{ $return = $item[1] }
#                    | value_expression
#                    | (function_name)(?) '(' sql_query ')'
                    | scalar_subquery
{ $return = $item{scalar_subquery}}
                    | <error: invalid expression>

# XXX XXX: need to work on strings - distinguish literals, quotstrings, 
# column names
#        concat_op   : '||'
#        concat_expr : <leftop: str_primary concat_op str_primary>
        str_primary : '(' string_val ')'
{$return = $item[1] }
                    | string_literal
{$return = {string_literal => $item{string_literal},
            tc_expr_type => 'c'
            }}
                    | value_expression
{$return = $item[1] }


        expr_list   :  value_expression(s /,/)
{$return = $item[1] }

        scalar_subquery : subquery
{$return = $item[1] }

	end_of_query: /\Z/

# OBSOLETE
#	expr	:	disj  no_garbage
	
	no_garbage: /^\s*$/
		  | <error: Trailing garbage>


        bool_TFN    : TRUE
{ $return = {tfn_literal   => 1,
             tc_expr_type  => 'n'
         }
}
                    | FALSE
{ $return = {tfn_literal   => 0,
             tc_expr_type  => 'n'
         }
}
                    | NULL
{ $return = {tfn_literal   => undef,
             tc_expr_type  => 'n'
         }
}

        bool_isTFN  : IS NOT(?) bool_TFN
{ $return = { not => $item{'NOT(?)'},
              TFN => $item{bool_TFN}
          }
}
        search_cond : <leftop: bool_term OR  bool_term>
{ my @bool_op  = @{$item[1]};
  if (exists($item{OR}))
  {
      $return = {bool_op   => 'OR',
                 operands  => \@bool_op
                 };
  }
  else
  {
      $return = $bool_op[0];
  }
  $return;
}
        bool_term   : <leftop: bool_fact AND bool_fact>
{ my @bool_op  = @{$item[1]};
  if (exists($item{AND}))
  {
      $return = {bool_op   => 'AND',
                 operands  => \@bool_op
                 };
  }
  else
  {
      $return = $bool_op[0];
  }
  $return;
}
        bool_fact   : NOT(?) bool_test
{
    if (scalar(@{$item{'NOT(?)'}}))
    {
# return an array of operands (even though there is only one)
# to match AND, OR
        $return = {bool_op   => 'NOT',

                   operands  => [$item{bool_test}]
                };
    }
    else
    {
        $return = $item{bool_test};
    }
    $return;
}
        bool_test   : bool_primary bool_isTFN(?)
{
    if (scalar(@{$item{'bool_isTFN(?)'}}))
    {
        $return = {IS       => $item{'bool_isTFN(?)'},
                    operands => $item{bool_primary}
                };
    }
    else
    {
        $return = $item{bool_primary};
    }
    $return;
}
# IN lists or subquery
                   | function_name ...'(' 
                      '(' <commit> 
                         function_guts(?) ')'
{$return = { function_name => $item{function_name},
             operands      => $item{'function_guts(?)'}
         }
}


        bool_primary: predicate
{ $return = $item{predicate} }    
                    | '(' search_cond ')'
{ $return = $item{search_cond} }    

        predicate   : comparison_predicate
{$return = $item[1]}
#  EXISTS, UNIQUE - subquery
                    | function_name ...'(' 
                      '(' <commit> 
                         function_guts(?) ')'
{$return = { function_name => $item{function_name},
             operands      => $item{'function_guts(?)'}
         }
}

# allow "spaceship" compare
        comp_op     : '<=>'
{ $return = $item[1] }    
                    | '=='
{ $return = $item[1] }    
                    | '!='
{ $return = $item[1] }    
                    | '<>'
{ $return = $item[1] }    
                    | '>='
{ $return = $item[1] }    
                    | '<='
{ $return = $item[1] }    
                    | '>'
{ $return = $item[1] }    
                    | '<'
{ $return = $item[1] }    
                    | '='
{ $return = $item[1] }    

# perl regexp match comparison.  
        comp_perlish: '!~' 
{ $return = $item[1] }    
                    | '=~'
{ $return = $item[1] }    
        comp_or_perl: comp_op value_expression 
{
#
# get start/stop position for value_expression
#
    my $p1 = $itempos[2]{offset}{from};
    my $p2 = $itempos[2]{offset}{to};
    
    $return = {operator => $item{comp_op},
               operands => $item{value_expression},
               p1 => $p1, p2 => $p2
           }
}
# e.g. foo !~ m/foo/ for a search predicate, or
# update t1 set a=~ s/foo/bar/ for an update expression
                    | comp_perlish <perl_quotelike>
{$return = {operator => $item{comp_perlish},
            operands => $item[2]
        }
}
#
# XXX XXX: isn't this rule really in bool test, since it must support 
# a leading NOT ??? XXX XXX
#  (need to support In and Like )
                    | function_name ...'(' 
                      '(' <commit> 
                         function_guts(?) ')'
{$return = { function_name => $item{function_name},
             operands      => $item{'function_guts(?)'}
         }
}

# XXX XXX XXX XXX: rewrite comparison predicate to look more like
# bool_op, math_op

        comp_pred1  : value_expression comp_op value_expression 
{$return = {
    comp_op => 'comp_op',
    operator => $item{comp_op},
    operands => [$item[1], $item{comp_op}, $item[3]]
    }
}
# e.g. foo !~ m/foo/ for a search predicate, or
# update t1 set a=~ s/foo/bar/ for an update expression
                    | value_expression comp_perlish <perl_quotelike>
{$return = {
    comp_op  => 'comp_perlish',
    operator => $item{comp_perlish},
    operands => [$item[1], $item{comp_perlish}, $item[3]]
    }
}
#
# XXX XXX: isn't this rule really in bool test, since it must support 
# a leading NOT ??? XXX XXX
#  (need to support In and Like )
                    | value_expression NOT(?) function_name ...'(' 
                      '(' <commit> 
                         function_guts(?) ')'
{
    my $not = scalar(@{$item{'NOT(?)'}});
    my $fn_name = $item{function_name};
    my @opands;
    push @opands, {numeric_literal => $not,     tc_expr_type => 'n'};
    push @opands, {string_literal  => '\'' . $fn_name .'\'', 
                   tc_expr_type => 'c'};
    push @opands, $item{value_expression};
    if (scalar(@{$item{'function_guts(?)'}})
        && exists($item{'function_guts(?)'}->[0]->{operands}))
    {
        push @opands, @{$item{'function_guts(?)'}->[0]->{operands}};
    }
$return = { function_name => 'compare_function',
            operands => [{operands      => \@opands}]
            }
}
                    | value_expression 
{$return = $item[1]}


#        comparison_predicate : value_expression comp_or_perl(?)
        comparison_predicate : comp_pred1
{$return = $item[1] }    


# function operands: query, set function, regular function
       function_guts : sql_query
{ $return = {sql_query      => $item{sql_query}}}
                     | all_distinct(?)  expr_list
{ $return = {all_distinct   => $item{'all_distinct(?)'},
             operands       => $item{expr_list}
         }
}

# count function operands: star or value expression
       count_operand : '*' 
{ $return = 'STAR' }
                     | value_expression
# XXX XXX: return an array like an expr_list in function_guts
{ $return = [{ value_expression  => $item{value_expression}}]}

       countfunc_guts: all_distinct(?) count_operand
{ $return = {all_distinct   => $item{'all_distinct(?)'},
             operands       => $item{count_operand}
         }
}

# [schema.]identifier
# just return an array of name pieces
        big_id      : identifier(s /\./)
{ my @foo = @{$item[1]}; $return = \@foo; }

	identifier  : quoted_string
{ 
    my $p1 = $itempos[1]{offset}{from};
    my $p2 = $itempos[1]{offset}{to};
    $return = {quoted_string => $item{quoted_string},
               p1 => $p1,
               p2 => $p2 }}
                    | bareword 
{  
    my $p1 = $itempos[1]{offset}{from};
    my $p2 = $itempos[1]{offset}{to};
    $return = {bareword => $item{bareword},
               p1 => $p1,
               p2 => $p2 }}
                    | <error: invalid identifier >
	
	quoted_string:
                 { my $string = extract_delimited($text,q{"}); 
# "
# previous comment to close quotes for emacs
		   $return = $string if $string; } 

        string_literal : 
                 { my $string = extract_delimited($text,q{'}); 
# '
# previous comment to close quotes for emacs
		   $return = $string if $string; } 

#
# \w is [0-9a-zA-Z_]
#
# XXX XXX XXX XXX: 
# allow double colon in function names 

#        pkg_sep_chr    : '::'
#{ $return = $item[1] }

#        func_pkg_name  : bareword pkg_sep_chr
#{
#    print Data::Dumper->Dump(\@item,['@item']);
#    print Data::Dumper->Dump([%item],['%item']);
#    print "\n";
#
#    $return = $item[1] . '::';
#}

#        function_name: func_pkg_name(?) function_base_name 
        function_name: function_base_name 
{
#    print Data::Dumper->Dump(\@item,['@item']);
#    print Data::Dumper->Dump([%item],['%item']);
#    print "\n";

    if ((exists($item{'func_pkg_name(?)'}))
        && (defined($item{'func_pkg_name(?)'}))
        && (scalar(@{$item{'func_pkg_name(?)'}})))
    {

        $return =
            $item{'func_pkg_name(?)'}->[0] .
            $item{function_base_name};
    }
    else
    {
        $return = $item{function_base_name};
    }
    $return;
}

        function_base_name: ...!reserved_non_funcs /[a-z]\w*/i
#        function_name: ...!reserved_non_funcs /([a-z]\w*)((::)\w*)?/i
{ $return = $item[-1] }


# XXX XXX: CHEAT - allow genezzo dictionary tables unquoted
 	bareword: ...!reserved_word /([a-z]\w*)|((_tab1|_col1|_pref1|_tspace|_tsfiles)(?!([a-z0-9_])))/i
{ $return = $item[-1] }
        numeric_literal :   /[+-]?(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?/
{ $return = $item[1] }
                                                  

END_OF_GRAMMAR

#;;

#print $grammar, "\n";
sub SQLPrecompile
{

    # add some documentation to the generated file
    Parse::RecDescent->Precompile($grammar, "Genezzo::Parse::SQL");
      my $msg;
      ($msg .= << 'END_OF_MSG') =~ s/^\#//gm;      
#
#
#1;  # don't forget to return a true value from the file
#
#__END__
## Below is stub documentation for your module. You better edit it!
#
#=head1 NAME
#
#Genezzo::Parse::SQL - SQL parser
#
#=head1 SYNOPSIS
#
# use Genezzo::Parse::SQL;
# use Parse::RecDescent;
# use Data::Dumper;
#
# # load the precompiled parser
# my $parser   = Genezzo::Parse::SQL->new();
#
# # sql_000 is parser entry point.
# # The argument is a string which contains a SQL query
# # (without a trailing semicolon).
# # The output is nested hash structure of the abstract 
# # syntax tree.
# my $sql_tree = $parser->sql_000($some_sql_statement);
#
# # dump out the parse tree
# print Data::Dumper->Dumper([$sql_tree],['sql_tree']);
#
#
#=head1 DESCRIPTION
#
#  The SQL parser is a L<Parse::RecDescent> parser generated by 
#  L<Genezzo::Parse::SQLGrammar>.  It shouldn't be looked at with
#  human eyes.  
#
#  Still reading this?  You must be a glutton for punishment.
#
#  This parser handles a fair bit of SQL92, but the error handling
#  is somewhat lacking.
#
#=head1 ARGUMENTS
#
#=head1 FUNCTIONS
#
#
#=head2 EXPORT
#
#=over 4
#
#
#=back
#
#
#=head1 LIMITATIONS
#
# No support for DDL, ANSI Interval, Date, Timestamp, etc.
#
#=head1 TODO
#
#=over 4
#
#=item  alter table (elcaro MODIFY column NOT NULL) vs (sql3 ALTER COLUMN)...
#
#=item  Support for DDL, ANSI Interval, Date, Timestamp, etc.
#
#=item  fix the extra array deref in join rules
#
#=item  error messages everywhere
#
#=item ECOUNT reserved word issues
#
#=item TRIM, UPPER, etc in standard function list?
#
#=item use of negative lookahead in reserved_word regex?
#
#=item table constraint, storage clause
#
#=item constraint attributes - deferrable, disable
#
#=item delete cascade referential action
#
#=item maybe can collapse qualified join with qj_leftop?
#
#=item table expr optional column list
#
#=item "system" literals like USER, SYSDATE
#
#=item better separation of strings and numbers (see concatenate)
#
#=item leading NOT
#
#=item double colon in function names?
#
#
#=back
#
#=head1 AUTHOR
#
#Jeffrey I. Cohen, jcohen@genezzo.com
#
#=head1 SEE ALSO
#
#L<perl(1)>.
#
#Copyright (c) 2005,2006 Jeffrey I Cohen.  All rights reserved.
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
#
#Address bug reports and comments to: jcohen@genezzo.com
#
#For more information, please visit the Genezzo homepage 
#at L<http://www.genezzo.com>
#
#=cut
#
END_OF_MSG

    #
    my $now_string = localtime();
    $msg .= "\n# Generated by SQLGrammar.pl on $now_string\n\n";
    my $fh;
    open($fh, ">> SQL.pm")
        or die "could not open SQL.pm for write : $! \n";
    print $fh $msg;
    close $fh;

}


sub SQLInteractive
{
    local $Data::Dumper::Indent   = 1;
    local $Data::Dumper::Sortkeys = 1;

    my $parser = Parse::RecDescent->new($grammar) or die;

#print Data::Dumper->Dump([$parser], ['parser']);

    print "\nsql> ";

    while (<STDIN>)
    {
        my $ini = $_;
        $ini =~ s/\;$//; # remove trailing semicolon
        my $sql = $parser->sql_000($ini);
        if (defined($sql))
        {
#        print "ok\n";
        }
        else
        {
#        print "bad\n";
        }
        print Data::Dumper->Dump([$sql],['sql']);
        print "\nsql> ";
    }
}

# do everything

if ($ARGV[0] && (lc($ARGV[0]) eq "interactive"))
{
    SQLInteractive();
}
else
{
    SQLPrecompile();
}


1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Genezzo::Parse::SQLGrammar.pl - Generate SQL Parser

=head1 SYNOPSIS

  # Generate SQL.pm standalone parser
  perl -Iblib/lib lib/Genezzo/Parse/SQLGrammar.pl 

  # Primitive line-mode SQL parser - dumps parse tree
  perl -Iblib/lib lib/Genezzo/Parse/SQLGrammar.pl interactive


=head1 OPTIONS



=head1 DESCRIPTION

This program generates a parser which can handle a fair bit of SQL92,
with some non-standard perlish functions thrown in for good measure.

Originally derived from the Parse::RecDescent demo demo_operator.pl,
but it bears as little resemblance to its predecessor as a rocket ship
to a rocking chair.

Special thanks to Damian Conway for Parse::RecDescent, as well as
Terrence Brannon for the Parse::RecDescent::FAQ.  An honorable mention
goes to Terence Parr at ANTLR.org for his help on parsing issues.



=head1 AUTHORS

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
