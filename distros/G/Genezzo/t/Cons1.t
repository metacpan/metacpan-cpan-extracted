# Copyright (c) 2003, 2004, 2005 Jeffrey I Cohen.  All rights reserved.
#
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..21\n"; }
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

    my $fb = Genezzo::GenDBI->new(exe => $0, 
                             gnz_home => $gnz_home, 
                             dbinit => $dbinit);

    unless (defined($fb))
    {
        not_ok ("could not find database");
        exit 1;
    }
    ok();
    $dbinit = 0;

}

# the default "connect" error handler uses "warn" or "die".  Replace
# it with one that prints messages, which makes the test output cleaner.
our $GZERR = sub {
    my %args = (@_);

    return 
        unless (exists($args{msg}));

    my $warn = 0;
    if (exists($args{severity}))
    {
        my $sev = uc($args{severity});
        $sev = 'WARNING'
            if ($sev =~ m/warn/i);

        # don't print 'INFO' prefix
        if ($args{severity} !~ m/info/i)
        {
            printf ("%s: ", $sev);
            $warn = 1;
        }

    }
    print $args{msg};
#    carp $args{msg}
#      if (warnings::enabled() && $warn);
    
};


{
    use Genezzo::Util;

    print "dbi connect:\n";
    my $dbh = Genezzo::GenDBI->connect($gnz_home, 
                                       "NOUSER", "NOPASSWORD",
                                       {GZERR => $GZERR});

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

    if ($dbh->do("create table aaa_cons (col1 char, col2 number, col3 char)"))
    {       
        ok();
    }
    else
    {
        not_ok ("could not create table");
    }

    if ($dbh->do(
        "alter table aaa_cons add constraint AAA_P primary key (col1)"))
    {       
        ok();
    }
    else
    {
        not_ok ("could not add primary key");
    }
    if ($dbh->do(
        'alter table aaa_cons add constraint AAA_CK check (col1 != \'foo\')'))
    {       
        ok();
    }
    else
    {
        not_ok ("could not add check");
    }
    if ($dbh->do("alter table aaa_cons add unique (col2)"))
    {       
        ok();
    }
    else
    {
        not_ok ("could not add unique key");
    }
    if ($dbh->do("create index aaa_ix on aaa_cons (col3)"))
    {       
        ok();
    }
    else
    {
        not_ok ("could not add create index");
    }

    my $sth = $dbh->prepare(
#        "select tid, tname from _tab1 where tname =~ m/aaa_cons/x");
        "select tid, tname from _tab1 where tname = \'aaa_cons\'");

    print $sth->execute(), " rows \n";

    my $f1 = $sth->fetchrow_hashref();

    my $aaa_tid = $f1->{'tid'};
    print "tid: ",$aaa_tid, "\n";

    # 4 constraints on aaa_cons
    $sth = $dbh->prepare("select * from cons1 where tid = $aaa_tid");

    print $sth->execute(), "\n";

    while (1)
    {
        my $ggg = $sth->fetchrow_hashref();
    
        greet $ggg;
        last
            unless (defined($ggg));
    }
    my $cons_cnt = $sth->rows();
    if (4 == $cons_cnt)
    {
        ok();
    }
    else
    {
        not_ok ("$cons_cnt != 4");
    }

    # 3 indexes on aaa_cons
    $sth = $dbh->prepare("select * from ind1 where tid = $aaa_tid");

    print $sth->execute(), "\n";

    while (1)
    {
        my $ggg = $sth->fetchrow_hashref();
    
        greet $ggg;
        last
            unless (defined($ggg));
    }
    $cons_cnt = $sth->rows();
    if (3 == $cons_cnt)
    {
        ok();
    }
    else
    {
        not_ok ("$cons_cnt != 3");
    }

    # 4 tables
    $sth = $dbh->prepare("select * from _tab1 where tid >= $aaa_tid");

    print $sth->execute(), "\n";

    while (1)
    {
        my $ggg = $sth->fetchrow_hashref();
    
        greet $ggg;
        last
            unless (defined($ggg));
    }
    $cons_cnt = $sth->rows();
    if (4 == $cons_cnt)
    {
        ok();
    }
    else
    {
        not_ok ("$cons_cnt != 3");
    }

    if ($dbh->do("commit"))
    {       
        ok();
    }
    else
    {
        not_ok ("could not commit");
    }

    $sth = 
        $dbh->prepare('insert into aaa_cons values (\'a\', 1, \'foo\', \'b\', 2, \'baz\')');

    greet $sth->rows;

    if (2 == $sth->execute())
    {
        ok();
    }
    else
    {
        not_ok ("could insert 2 rows");
    }

    $sth = 
        $dbh->prepare('insert into aaa_cons values (\'a\', 3, \'foo\')');

    greet $sth->rows;

    if (0 == $sth->execute())
    {
        ok();
    }
    else
    {
        not_ok ("violated primary key");
    }

    $sth = 
        $dbh->prepare('insert into aaa_cons values (\'c\', 3, \'foo\')');

    greet $sth->rows;

    if (1 == $sth->execute())
    {
        ok();
    }
    else
    {
        not_ok ("index should allow dup");
    }

    $sth = 
        $dbh->prepare('insert into aaa_cons values (\'c\', 2, \'foo\')');

    greet $sth->rows;

    if (0 == $sth->execute())
    {
        ok();
    }
    else
    {
        not_ok ("violated unique key");
    }

    $sth = 
        $dbh->prepare('update aaa_cons set col1=\'foo\' where col3 = \'foo\'');

    greet $sth->rows;

    if (0 == $sth->execute())
    {
        ok();
    }
    else
    {
        not_ok ("violated check");
    }


    if ($dbh->do("commit"))
    {       
        ok();
    }
    else
    {
        not_ok ("could not commit");
    }


    #### see Cons Zero    


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

