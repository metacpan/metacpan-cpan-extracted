#!/usr/bin/perl
#
# $Header: /Users/claude/fuzz/lib/Genezzo/RCS/gendba.pl,v 7.12 2007/11/20 07:46:09 claude Exp claude $
#
# copyright (c) 2003-2007 Jeffrey I Cohen, all rights reserved, worldwide
#
#
use Genezzo::GenDBI;
use Getopt::Long;
use Pod::Usage;
use strict;
use warnings;

=head1 NAME

B<gendba.pl> - line mode for Genezzo database system

=head1 SYNOPSIS

B<gendba> [options] 

Options:

    -help            brief help message
    -man             full documentation
    -init            build a gnz_home installation if necessary
    -gnz_home        supply a directory for the gnz_home
    -version         print version information
    -shutdown        do not startup
    -define key=val  define a configuration parameter

    -fileheader_define key=val  define a file-specific configuration 
                                parameter (not useful in general)

=head1 OPTIONS

=over 8

=item B<-help>

    Print a brief help message and exits.

=item B<-man>
    
    Prints the manual page and exits.

=item B<-init>
    
    Build the gnz_home dictionary and default tablespace if 
    it does not exist.

=item B<-gnz_home>
    
    Supply the location for the gnz_home installation.  If 
    specified, it overrides the GNZ_HOME environment variable.

=item B<-version>
    
    Print version information.  

=item B<-shutdown>
    
    If initializing a new database, then shutdown when 
    complete, versus continuing in interactive mode.

=item B<-define> key=value
    
    Define a configuration parameter for database
    creation and/or initialization.  Some important 
    database creation parameters are blocksize and dbsize, 
    which define the size of database blocks and
    the size of the initial database file.  An important
    initialization parameter is use_havok=0, which 
    disables the havok extensibility subsystem on database
    startup. Use "gendba.pl -define help=help" 
    for more information.

=item B<-fileheader_define> key=value
    
    Define a file-specific configuration parameter when the database 
    is created.  For specialized extensions which cannot use the dictionary
    preference table.

=back

=head1 DESCRIPTION

Genezzo is an extensible, persistent datastore that uses a subset of
SQL.  The gendba line-mode tool lets users interactively perform
management tasks, as well as define and modify tables, and manipulate
table data with updates and queries.

=head2 Commands

Genezzo supports some very basic SQL create/drop/alter/describe table,
select, insert, update and delete syntax, and like standard SQL, table
and column names are case-insensitive unless quoted.  More complex SQL
parses, but is ignored.  The only supported functions are count(*) and
ecount(*), a non-blocking count estimation function.  The database
also supports commit to force changes to disk, but no rollback.
NOTE: Data definition (such as create table or ct) must be manually
committed to keep the database in a consistent state.  Uncommitted
inserts and updates will only be block-consistent -- there is no
guarantee that the data will get flushed to disk, and no guarantee
whether the changes will or will not take effect.

    rem  Some simple SELECTs
    select * from _col1;
    select rid, rownum, tname, colname from _col1;
    select count(*) from _col1;
    select ecount(*) from _col1;

    rem  SELECTs with WHERE, perl and SQL style.
    select * from _tab1 where tname =~ m/col/;
    select * from _tab1 where tid < 5;
    select * from _tab1 where numcols > 3 AND numcols < 6;

    rem basic joins
    select * from _tab1, _col1  where _tab1.tid = _col1.tid 
     and _tab1.tname =~ m/col/;

    rem  Column aliases and Expressions
    select tid as Table_ID, tname Name, (tid+1)/2 from _tab1;

    rem  Basic INSERT
    insert into test1 values ('a','b','c','d');
    insert into test1(col2, col1) values ('a','b','c','d');

    rem CREATE TABLE and INSERT...SELECT
    create table test2(col1 char, col2 char);
    insert into test2 (col1) select col1 from test1;

    rem  DELETE with WHERE
    delete from test1 where col1 < 'bravo' and col2 > 5;

    rem  UPDATE with WHERE (no subqueries supported)
    update test2 set col2 = 'foo' where col2 is null;

    rem CREATE an INDEX
    create index test1_ix on test1(col1);

    rem ADD a CHECK CONSTRAINT
    alter table test2 add constraint t2_cn1 check (col2 =~ m/(a|b|c|d)/x );

    commit

Genezzo also supports the following "short" commands: ct, dt, s, i, d, u

=over 8

=item B<ct - create table>

  example: ct EMP NAME=c ID=n
  SQL equivalent: CREATE TABLE EMP (NAME CHAR(10), ID NUMBER) ;

=item B<dt - drop table>

  example: dt EMP
  SQL equivalent: DROP TABLE EMP ;

=item B<s - select>

  example: s EMP *
  SQL equivalent: SELECT * FROM EMP ;

  example: s EMP rid rownum *
  SQL equivalent: SELECT ROWID, ROWNUM, * FROM EMP ;

  example: s EMP NAME
  SQL equivalent: SELECT NAME FROM EMP ;

=item B<i - insert>

  example: i EMP bob 1 orville 2
  SQL equivalent: 
    INSERT INTO EMP VALUES ('bob', '1');
    INSERT INTO EMP VALUES ('orville', '2'); 


=item B<d, u - delete and update>

  DELETE and UPDATE only work by rid 
  -- you cannot specify a predicate.

  example: d emp 1.2.3
  SQL equivalent: DELETE FROM EMP WHERE RID='1.2.3' ;

  example: u emp 1.2.3 wilbur 4
  SQL equivalent: UPDATE EMP SET NAME='wilbur', 
                                 ID='4' WHERE RID='1.2.3' ;


=back

Genezzo stores information in a couple of subsidiary files: the
default install creates a file called default.dbf which contains the
basic dictionary information.  Other data files can be added as
needed.  While the default configuration uses a single, fixed-size
datafile, Genezzo can be configured to use datafiles that grow to some
maximum size, and it can also be configured to automatically create
new datafiles as necessary.

All tables are currently created in the system tablespace by default.

There are a couple of other useful commands:

=over 4

=item HELP -- give help

=item DUMP -- dump out internal data structures

=item DUMP TABLES - list all tables

=item DUMP TS - dump tablespace information

=item RELOAD - reload all Genezzo perl modules (will lose uncommited changes, though)

=item COMMIT - force write of changes to database.  Note that even CREATE TABLE is
transactional -- you have to commit to update the persistent dictionary.
Forgetting to commit can cause weird behaviors, since the buffer cache may
flush data out to the dbf file.  Then you can have the condition where the
tablespace reuses these "empty" blocks and they already have data in them.

=back

=head2 Environment

GNZ_HOME: If the user does not specify a gnz_home directory using 
the B<'-gnz_home'> option, Genezzo stores dictionary and table
information in the location specified by this variable.  If 
GNZ_HOME is undefined, the default location is $HOME/gnz_home.

=head1 AUTHORS

Copyright (c) 2003-2007 Jeffrey I Cohen.  All rights reserved.  

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
    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  US

Address bug reports and comments to: jcohen@genezzo.com

For more information, please visit the Genezzo homepage 
at L<http://www.genezzo.com>

=cut

our $GZERR = sub {
    my %args = (@_);

    return 
        unless (exists($args{msg}));

    # to process spooling to multiple files
    my $outfile_h = $args{outfile_list} || undef;

    my $warn = 0;
    if (exists($args{severity}))
    {
        my $sev = uc($args{severity});
        $sev = 'WARNING'
            if ($sev =~ m/warn/i);

        return 
            if ($sev =~ m/ignore/i);

        # don't print 'INFO' prefix
        if ($args{severity} !~ m/info/i)
        {
            printf ("%s: ", $sev);

            if (defined($outfile_h))
            {
                while (my ($kk, $vv) = each (%{$outfile_h}))
                {
                    printf $vv ("%s: ", $sev);
                }
            }

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

    if (defined($outfile_h))
    {
        while (my ($kk, $vv) = each (%{$outfile_h}))
        {
            print $vv $args{msg};
            # add a newline if necessary
            print $vv "\n" unless $args{msg}=~/\n$/;
        }
    }


#    carp $args{msg}
#      if (warnings::enabled() && $warn);
    
};


    my $glob_init;
    my $glob_gnz_home;
    my $glob_shutdown; 
    my $glob_id;
    my $glob_defs;
    my $glob_fhdefs;

sub setinit
{
    $glob_init     = shift;
    $glob_gnz_home = shift;
    $glob_shutdown = shift;
    $glob_defs     = shift;
    $glob_fhdefs     = shift;
}

BEGIN {
    my $man  = 0;
    my $help = 0;
    my $init = 0;
    my $verzion = 0;
    my $shutdown = 0;
    my $gnz_home = '';
    my %defs     = ();    # list of --define key=value
    my %fhdefs   = ();    # list of --fileheader_define key=value

    GetOptions(
               'help|?' => \$help, man => \$man, init => \$init,
               version => \$verzion,
               shutdown => \$shutdown,
               'gnz_home=s' => \$gnz_home,
               'define=s'   => \%defs,
               'fileheader_define=s'   => \%fhdefs)
        or pod2usage(2);

    $glob_id = "Genezzo Version $Genezzo::GenDBI::VERSION - $Genezzo::GenDBI::RELSTATUS $Genezzo::GenDBI::RELDATE\n\n"; 

    
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

    setinit($init, $gnz_home, $shutdown, \%defs, \%fhdefs);

    print "loading...\n" ;
}

my $fb = Genezzo::GenDBI->new(exe => $0, 
                              gnz_home => $glob_gnz_home, 
                              dbinit => $glob_init,
                              defs   => $glob_defs,
                              fhdefs => $glob_fhdefs,
                              GZERR  => $GZERR
                         );

unless (defined($fb))
{
    my $initmsg = 
        "use \n\t$0 -init \n\nto create a default installation.\n";

    if ($glob_init)
    {
        $initmsg = 
        "use \n\t$0 -define force_init_db=1 \n\n" .
        "to overwrite (and destroy) an existing installation.\n"
    }

    pod2usage(-exitstatus => 2, -verbose => 0, 
              -msg => $glob_id . $initmsg
              );
    # Note: exit takes zero for success, 1 for failure
    exit (1);
}

exit(0) # no interactive
    if ($glob_shutdown);

exit(!$fb->Interactive()); # invert status code for exit
