# Copyright (c) 2006 Jeffrey I Cohen.  All rights reserved.
#
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..29\n"; }
END {print "not ok 1\n" unless $loaded;}
use Genezzo::GenDBI;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):
use strict;
use warnings;
use File::Path;
use File::Spec;

my $TEST_COUNT;

$TEST_COUNT = 2;

my $dbinit   = 1;
my $gnz_home = File::Spec->catdir("t", "gnz_home");
my $gnz_restore = File::Spec->catdir("t", "restore");
#rmtree($gnz_home, 1, 1);
#mkpath($gnz_home, 1, 0755);

{
    use Genezzo::TestSetup;

    my $fb = 
        Genezzo::TestSetup::CreateOrRestoreDB( 
                                               gnz_home => $gnz_home,
                                               restore_dir => $gnz_restore);

    unless (defined($fb))
    {
        not_ok ("could not create database");
        exit 1;
    }
    ok();
    $dbinit = 0;

}

{
    use Genezzo::Util;

    my $dbh = Genezzo::GenDBI->connect($gnz_home, "NOUSER", "NOPASSWORD");

    unless (defined($dbh))
    {
        not_ok ("could not find database");
        exit 1;
    }
    ok();

    if ($dbh->do("startup"))
    {       
        ok();
    }
    else
    {
        not_ok ("could not startup");
    }


    if ($dbh->do("ct test2 col1=c col2=c col3=c col4=c"))
    {
        ok();
    }
    else
    {
        not_ok ("could not create table");
    }

    my $sth = $dbh->prepare('insert into test2 values ( \'alpha\', \'bravo\', \'charlie\', \'delta\', \'echo\', \'foxtrot\', \'golf\', \'hotel\')');

    greet $sth->rows;

    for my $ii (1..10)
    {
        if (2 == $sth->execute())
        {
            ok();
        }
        else
        {
            not_ok ("could insert 2 rows");
        }
        if (2 == $sth->rows())
        {
            ok();
        }
        else
        {
            not_ok ("could not get row count");
        }
    }

    $sth = $dbh->prepare("select * from test2");
    
    print $sth->execute(), " rows \n";

    my @ftchary;
    while (1)
    {
        my @ggg = $sth->fetchrow_array();

        last
            unless (scalar(@ggg));
        @ftchary = @ggg;
    }
    greet @ftchary;

    $sth = $dbh->prepare("select count(*) from test2");

    print $sth->execute(), " rows \n";

    my $lastfetch;
    while (1)
    {
        my $ggg = $sth->fetchrow_hashref();
    
        last
            unless (defined($ggg));
        $lastfetch = $ggg;
    }
    if (exists($lastfetch->{'COUNT(*)'})
        && $lastfetch->{'COUNT(*)'} == 20)
    {
        ok();
    }
    else
    {
        not_ok ("could not fetch count(*)");
    }

my $parse_tree = {
  'orderby_clause' => [],
  'sql_query' => {
    'operands' => [
      {
        'sql_select' => {
          'all_distinct' => [],
          'from_clause' => [
            [
              {
                'table_alias' => [],
                'table_name' => [
                  {
                    'bareword' => 'test2'
                  }
                ]
              }
            ]
          ],
          'groupby_clause' => [],
          'having_clause' => [],
          'select_list' => [
            {
                # NOTE: col_alias required 
              'col_alias' => [
                  {
                    'bareword' => 'COLUMN1'
                  }
                              ],
              'p1' => '7', # not valid unless have a sql statement
              'p2' => '11',
              'value_expression' => {
                'column_name' => [
                  {
                    'bareword' => 'col1'
                  }
                ]
              }
            }
          ],
          'where_clause' => []
        }
      }
    ],
    'sql_setop' => 'njq_simple'
  }
};


    $sth = $dbh->parse_tree_prepare(parse_tree => $parse_tree,
                                    statement_type => "select");

    print $sth->execute(), " rows \n";

    my %ptcount;
    while (1)
    {
        my @ggg = $sth->fetchrow_array();

#        print join(" ", @ggg), "\n";

        last
            unless (scalar(@ggg));

        if (exists($ptcount{$ggg[0]}))
        {
            $ptcount{$ggg[0]} += 1;
        }
        else
        {
            $ptcount{$ggg[0]} = 1;
        }
        @ftchary = @ggg;
    }
    greet @ftchary;

    # should be 10 alphas and 10 echos
    if ((exists($ptcount{alpha})
        && ($ptcount{alpha} == 10)) &&
        (exists($ptcount{echo})
        && ($ptcount{echo} == 10)))
    {
        ok();
    }
    else
    {
        not_ok("invalid counts for column 1 values");
    }

    if ($dbh->do("commit"))
    {       
        ok();
    }
    else
    {
        not_ok ("could not commit");
    }
    if ($dbh->do("shutdown"))
    {
        ok();
    }
    else
    {
        not_ok ("could not shutdown");
    }

}


sub ok
{
    print "ok $TEST_COUNT\n";
    
    $TEST_COUNT++;
}


sub not_ok
{
    my ( $message ) = @_;
    
    print "not ok $TEST_COUNT #  $message\n";
        
        $TEST_COUNT++;
}


sub skip
{
    my ( $message ) = @_;
    
    print "ok $TEST_COUNT # skipped: $message\n";
        
        $TEST_COUNT++;
}

