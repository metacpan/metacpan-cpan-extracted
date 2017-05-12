# Copyright (c) 2003-2006 Jeffrey I Cohen.  All rights reserved.
#
#!/usr/bin/perl
use strict;
use warnings;

use File::Path;
use File::Spec;

use Genezzo::GenDBI;
use Data::Dumper;

#    my $gnz_home = $ENV{GNZ_HOME} || ($ENV{HOME} . '/gnz_home');
    my $gnz_home = File::Spec->catdir("t", "gnz_home");

if (1)
{
    # build a database if necessary

    # works interactively, but not via system??
#    system ("perl -Iblib/lib lib/Genezzo/gendba.pl -init -gnz_home $gnz_home -shutdown");


    # can have additional database definition parameters if necessary
    my %defs = (
                dbsize    => "10M", # set default dbf file to 10 meg
                blocksize => "4k",  # database uses 4k blocks
#               force_init_db => 0  # set to 1 to overwrite (and destroy)
                                    # an existing database
                );

    # create a database (not command-line)
    # Note: do not overwrite an existing database (even with dbinit => 1)
    #       unless defs => {force_init_db => 1} is set.
    my $fb = Genezzo::GenDBI->new(exe => $0, 
                             gnz_home => $gnz_home, 
                             dbinit => 1,       # init 
#                            defs => \%defs     # define additional parameters
                             );
    print "\n\n";
    print "created a new database"
        if (defined($fb));
    print "\n\n";
}

{ 
    
    # connect to the database
    my $dbh = Genezzo::GenDBI->connect($gnz_home, "NOUSER", "NOPASSWORD");
    
    $dbh->do("startup"); # start the database
    
    # create table test2 (col1 char, col2 char, col3 char, col4 char);
#    $dbh->do("dt test2"); 
    $dbh->do("drop table test2");

#    $dbh->do("ct test2 col1=c col2=c col3=c col4=c");
    $dbh->do("create table test2 (col1 char,col2 char,col3 char,col4 char)");

    my $sth = 
        $dbh->prepare("insert into test2 values (\'alpha\', \'bravo\', \'charlie\', \'delta\', \'echo\', \'foxtrot\', \'golf\', \'hotel\')");

    for my $ii (1..10)
    {
        $sth->execute();
    }

    $dbh->do("commit"); 

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
    print Dumper( @ftchary);
    print $sth->execute(), " rows \n";

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
    print Dumper($lastfetch);

    $sth = 
        $dbh->prepare("select rid ROWid, rownum as NuMbEr, col1 BAKER, col2 as CHUCK from test2");

    print $sth->execute(), " rows \n";

    print $sth->{NUM_OF_FIELDS}, " columns in select list\n";
    print Dumper($sth->{NAME});

    print Dumper ($dbh->selectall_arrayref("select rid, rownum, col1 from test2 where col1 < \'bravo\'"));

    $dbh->do("shutdown"); # shutdown the database

}
