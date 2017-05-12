#!/usr/bin/perl
#
# $Header: /Users/claude/fuzz/lib/Genezzo/RCS/genexp.pl,v 7.5 2006/05/19 07:29:34 claude Exp claude $
#
# copyright (c) 2005, 2006 Jeffrey I Cohen, all rights reserved, worldwide
#
#
#use strict;
use Genezzo::GenDBI;
use Genezzo::Havok::SQLScalar;
use Data::Dumper;
use Getopt::Long;
use Pod::Usage;
use strict;
use warnings;

=head1 NAME

B<genexp.pl> -  Genezzo database exporter

=head1 SYNOPSIS

B<genexp> [options] 

Options:

    -help            brief help message
    -man             full documentation
    -gnz_home        supply a directory for the gnz_home
    -version         print version information
    -define key=val  define a configuration parameter

=head1 OPTIONS

=over 8

=item B<-help>

    Print a brief help message and exits.

=item B<-man>
    
    Prints the manual page and exits.

=item B<-gnz_home>
    
    Supply the location for the gnz_home installation.  If 
    specified, it overrides the GNZ_HOME environment variable.

=item B<-version>
    
    Print version information.  

=item B<-define> key=value
    
    If initializing a new database, define a configuration 
    parameter.

=back

=head1 DESCRIPTION

Genezzo is an extensible, persistent datastore that uses a subset of
SQL.  The genexp tool lets users export their existing schema as a SQL 
script.  Running the script will recreate and repopulate the tables.

=head2 Environment

GNZ_HOME: If the user does not specify a gnz_home directory using 
the B<'-gnz_home'> option, Genezzo stores dictionary and table
information in the location specified by this variable.  If 
GNZ_HOME is undefined, the default location is $HOME/gnz_home.

=head1 TODO

=over 4

=item move most methods to separate .pm file

=item need to distinguish "dictionary" havok routines vs
post-dictionary havok tables

=back 

=head1 AUTHORS

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
        else
        {
            if (exists($args{no_info}))
            {
                # don't print info if no_info set...
                return;
            }
        }

    }
    print $args{msg};
    # add a newline if necessary
    print "\n" unless $args{msg}=~/\n$/;
#    carp $args{msg}
#      if (warnings::enabled() && $warn);
    
};


    my $glob_gnz_home;
    my $glob_id;
    my $glob_defs;

sub setinit
{
    $glob_gnz_home = shift;
    $glob_defs     = shift;
}

BEGIN {
    my $man  = 0;
    my $help = 0;
    my $verzion = 0;
    my $gnz_home = '';
    my %defs = ();      # list of --define key=value

    GetOptions(
               'help|?' => \$help, man => \$man, 
               version => \$verzion,
               'gnz_home=s' => \$gnz_home,
               'define=s'   => \%defs)
        or pod2usage(2);

    $glob_id = "genexp.pl - Genezzo Version $Genezzo::GenDBI::VERSION - $Genezzo::GenDBI::RELSTATUS $Genezzo::GenDBI::RELDATE\n\n"; 


    if ($verzion)
    {
        my $bigmsg = 
            Genezzo::GenDBI::getversionstring(
                                              $Genezzo::GenDBI::VERSION,
                                              $Genezzo::GenDBI::RELSTATUS,
                                              $Genezzo::GenDBI::RELDATE,
                                              1);
        pod2usage(-exitstatus => 0, -verbose => 0, 
                  -msg => $bigmsg
                  );
    }

    pod2usage(-msg => $glob_id, -exitstatus => 1) if $help;
    pod2usage(-msg => $glob_id, -exitstatus => 0, -verbose => 2) if $man;

    setinit($gnz_home,  \%defs);

#    print "loading...\n" ;
}

my $dbh = Genezzo::GenDBI->new(exe => $0, 
                              gnz_home => $glob_gnz_home, 
                              defs   => $glob_defs,
                              GZERR  => $GZERR
                         );

unless (defined($dbh))
{
    my $initmsg = 
        "export failed -- no installation found at $glob_gnz_home\n";

    pod2usage(-exitstatus => 2, -verbose => 0, 
              -msg => $glob_id . $initmsg
              );
    # Note: exit takes zero for success, 1 for failure
    exit (1);
}

my $stat = 0;

{
    unless($dbh->do("startup"))
    {
        $stat = 1;
        last;
    }


    my $sth;
    $sth = 
        $dbh->prepare("select pref_value from  _pref1  where pref_key=\'export_start_tid\'");

    $sth->execute();
    
    my @lastfetch = $sth->fetchrow_array();
    
    my $last_dict_tid;

    if (scalar(@lastfetch))
    {
        $last_dict_tid = ($lastfetch[0]);
    }


    $sth =
        $dbh->prepare("select tid, tname from _tab1 where tid > $last_dict_tid and object_type='TABLE'");

#    print $sth->execute(), " rows \n";
    $sth->execute();

    my @tabs;
    while (1)
    {
        my @ggg = $sth->fetchrow_array();
        
#    print Dumper (@ggg), "\n";
        
        last
            unless (scalar(@ggg));
        
        push @tabs, [@ggg];

    }

#    print Dumper(@tabs), "\n";
# get all tables with tid > cons1_cols

    for my $tabi (@tabs)
    {
        my $tid = $tabi->[0];

        my $sql = 
            "select colidx, colname, coltype, tid, tname from _col1 where tid = $tid";
        $sth = 
            $dbh->prepare($sql);

#    print $sth->execute(), " rows \n";
        $sth->execute();

        my @cols = ();

        while (1)
        {
            my @ggg = $sth->fetchrow_array();
        
#            print Dumper (@ggg), "\n";
        
            last
                unless (scalar(@ggg));
            
            my $colidx = shift @ggg;

            $cols[$colidx] = [@ggg];
        }

        print "ct $tabi->[1] ";

        for my $coli (@cols)
        {
            print $coli->[0],"=",$coli->[1]," "
                if (defined($coli));
        }
        print "\n";

    }

    for my $tabi (@tabs)
    {
        my $tname = $tabi->[1];
        my $tid = $tabi->[0];

        my $sql = 
            "select colidx, colname, coltype, tid, tname from _col1 where tid = $tid";
        $sth = 
            $dbh->prepare($sql);

#    print $sth->execute(), " rows \n";
        $sth->execute();

        my @cols = ();

        while (1)
        {
            my @ggg = $sth->fetchrow_array();
        
#            print Dumper (@ggg), "\n";
        
            last
                unless (scalar(@ggg));
            
            my $colidx = shift @ggg;

            $cols[$colidx] = [@ggg];
        }


        $sql = 
            "select * from $tname ";
        $sth = 
            $dbh->prepare($sql);

#    print $sth->execute(), " rows \n";
        $sth->execute();

        while (1)
        {
            my $firsttime;
            my @fff = $sth->fetchrow_array();
            my @ggg = @fff;

#            print Dumper (@ggg), "\n";
        
            last
                unless (scalar(@ggg));
            
            print "insert into $tname values(";

            $firsttime = 1;
            for my $colcnt (1..scalar(@fff))
            {
                print ", "
                    unless $firsttime;
                if (defined($fff[$colcnt-1]))
                {
                    my $outi = $ggg[$colcnt-1];

#                    print  "'",$outi,"'";

                    if ($outi =~ m/([^A-Za-z0-9])+/)
                    {
                        print "unquurl(\'", sql_func_quurl2($outi),"\')";
                    }
                    else
                    {
                        print "\'",$outi,"\'";
                    }

                }
                else
                {
                    print "NULL";
                }

                $firsttime = 0
            }
            print ");\n";

        }

    }

    $sth =
        $dbh->prepare("select cons_name, cons_type, tid, check_text,check2 from cons1");

#    print $sth->execute(), " rows \n";
    $sth->execute();

    while (1)
    {
        my @ggg = $sth->fetchrow_array();

        last
            unless (scalar(@ggg));

#            print Dumper (@ggg), "\n";

        my ($c_name, $c_type, $tid, $c_text, $check2) = @ggg;

        $c_name = undef
            if ($c_name =~ m/^SYS_/);


        if ($c_type =~ m/(IK|PK|UQ)/)
        {
            my ($i_name, $iid) = split(":", $c_text, 2);
         
            next
                unless ($iid > $last_dict_tid);

            my @iinfo = get_index_info($dbh, $tid, $iid);
            my $tname = get_tname_by_tid($dbh, $tid);

            if ($c_type =~ m/IK/)
            {
                my $iname = shift(@iinfo);

                print "CREATE INDEX $iname on ";
                print "$tname (";
            }
            if ($c_type =~ m/PK|UQ/)
            {
                my $iname = shift(@iinfo);

                print "ALTER TABLE $tname ADD ";

                print "CONSTRAINT $c_name "
                    if (defined($c_name));

                my $tt1 = ($c_type =~ m/UQ/) ? "UNIQUE (" : "PRIMARY KEY (";
                print $tt1;

            }

            print join(", ", @iinfo);
            print ");\n";
            
            
        }
        else
        {
            if ($c_type =~ m/(CK)/)
            {
                my $tname = get_tname_by_tid($dbh, $tid);

                print "ALTER TABLE $tname ADD " ;

                print "CONSTRAINT $c_name "
                    if (defined($c_name));

                print "CHECK ($check2);\n";

            }
        }

    } # end while 1

}

sub get_tname_by_tid
{
    my ($dbh, $tid) = @_;
    my $sth;
    $sth = 
        $dbh->prepare("select tname from _tab1 where tid = $tid");

    $sth->execute();
    
    my @lastfetch = $sth->fetchrow_array();

    return undef 
        unless scalar(@lastfetch);

    my $tname = $lastfetch[0];

    return $tname;
}

sub get_cname_by_idx
{
    my ($dbh, $tid, $col_idx) = @_;

#    print "d2 ",Dumper ([$tid, $col_idx]), "\n";

    my $sth;
    $sth = 
        $dbh->prepare(
"select colname from _col1  where tid = $tid and colidx = $col_idx");

    $sth->execute();
    
    my @lastfetch = $sth->fetchrow_array();

    return undef 
        unless scalar(@lastfetch);

    my $cname = $lastfetch[0];

    return $cname;
}

sub get_index_info
{
    my ($dbh, $tid, $iid) = @_;
    my $sth;
    $sth = 
        $dbh->prepare("select iname from ind1 where iid = $iid");

    $sth->execute();
    
    my @lastfetch = $sth->fetchrow_array();

    return undef 
        unless scalar(@lastfetch);

    my $iname = $lastfetch[0];

    $sth = 
        $dbh->prepare("select colidx, posn from ind1_cols where iid = $iid and tid = $tid");

    $sth->execute();
    
    my @cols;

    @lastfetch = $sth->fetchrow_array();

    while (scalar(@lastfetch))
    {
        my ($cidx, $iposn) = @lastfetch;

#            print "d1 ", Dumper (@lastfetch), "\n";

        my $cname = get_cname_by_idx($dbh, $tid, $cidx);

        return undef
            unless (defined($cname));

        $cols[$iposn] = $cname;

        @lastfetch = $sth->fetchrow_array();
    }

    return undef 
        unless scalar(@cols);

    $cols[0] = $iname;

    return @cols;
}

exit($stat) 

