package IMDB::Local::DB;

use 5.006;
use strict;
use warnings;

=head1 NAME

IMDB::Local::DB - Direct access to IMDB::Local database.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '1.00';

=head1 SYNOPSIS

Package to interact with the IMDB:Local Database. 

    use IMDB::Local::DB;

    my $DB=new IMDB::Local::DB(database=>"/home/user/imdbLocal-data/imdb.db");
    ...

=head1 SUBROUTINES/METHODS

=head2 new

This package extends Class::MethodMaker (making use of the -hash new option)

     db_AutoCommit - scalar - default is 0, if set database
     driver - scalar - default "SQLite" (currently only support dbi driver)
     database - scalar - default "imdb.db" - relative path to IMDB::Local database 

Modifying any options after new() is not supported and unexpected results may occur.

=cut

use base qw(IMDB::Local::DB::Base);


use Class::MethodMaker
    [ 
      scalar => [{-default => 0}, 'db_AutoCommit'],
      scalar => [{-default => 'SQLite'}, 'driver'],
      scalar => [{-default => 'imdb.db'}, 'database'],
      scalar => [{-default => ''}, 'passwd'],
      scalar => [{-default => ''}, 'user'],
      new  => [qw/ -init -hash new /] ,
    ];


sub init($)
{
    my ($self)=@_;
}

=head2 delete

Delete the database. This must be called after new() and prior to connect().

=cut

sub delete($)
{
    my ($self)=@_;
    unlink($self->database());
}

=head2 connect

Connect and auto-create the database.

=cut

sub connect($)
{
    my ($self)=@_;

    my $initIt=0;
    if ( ! -f  $self->database ) {
	$initIt=1;
    }

    my $c=$self->SUPER::connect();
    if ( $c ) {
	#$c->dbh->{AutoCommit}=0;
    }
    if ( $c && $initIt==1 ) {
	if ( $self->driver eq 'SQLite' ) {
	    my $dbh=$self->dbh();
	    $dbh->do("PRAGMA page_size = 8192");
	}
	$self->schema_init();
    }
    return($c);
}

sub schema_init($)
{
    my ($self)=@_;

    for ($self->table_list) {
	print "dropping table: $_\n";
	$self->runSQL("drop table $_");
    }

    local $/ = undef;
    my $sql = <DATA>;
    my @statements = split(/;\s*\n/, $sql);

    foreach my $stmt (@statements) {
        next if ($stmt =~ /^\s*$/o);

	if ( !$self->runSQL($stmt) ) {
            print "Error executing:\n$stmt\n\n";

            print $self->dbh->errstr()."\n";
	    return(0);
        }
    }
    $self->insert_row('Versions', undef, (schema_version=>1));
    $self->commit();
    return(1);
}

sub create_table_indexes($$)
{
    my ($self, $table)=@_;

    if ( !defined($table) || $table eq 'Titles' ) {
	$self->runSQL("CREATE INDEX Titles_Idx1 on Titles (Year)");
	$self->runSQL("CREATE INDEX Titles_Idx2 on Titles (SearchTitle)");
	$self->runSQL("CREATE INDEX Titles_Idx3 on Titles (ParentID)");
    }
    if ( !defined($table) || $table eq 'Directors') {
	$self->runSQL("CREATE INDEX Directors_Idx1 on Directors (SearchName)");
	$self->runSQL("CREATE INDEX Directors_Idx2 on Titles2Directors (TitleID)");
    }
    if ( !defined($table) || $table eq 'Actors') {
	$self->runSQL("CREATE INDEX Actors_Idx1 on Actors (SearchName)");
	$self->runSQL("CREATE INDEX Actors_Idx2 on Actors (Name)");
	$self->runSQL("CREATE INDEX Actors_Idx3 on Titles2Actors (TitleID)");
	$self->runSQL("CREATE INDEX Actors_Idx4 on Titles2Hosts (TitleID)");
	$self->runSQL("CREATE INDEX Actors_Idx5 on Titles2Narrators (TitleID)");
    }
    if ( !defined($table) || $table eq 'Genres') {
	$self->runSQL("CREATE INDEX Genres_Idx1 on Titles2Genres (TitleID)");
    }
    if ( !defined($table) || $table eq 'Ratings') {
	$self->runSQL("CREATE INDEX Ratings_Idx1 on Ratings (TitleID)");
    }
    if ( !defined($table) || $table eq 'Keywords') {
	$self->runSQL("CREATE INDEX Keywords_Idx1 on Titles2Keywords (TitleID)");
    }
    if ( !defined($table) || $table eq 'Plots' ) {
	$self->runSQL("CREATE INDEX Plots_Idx1 on Plots (TitleID)");
    }
    return(1);
}

sub drop_table_indexes($$)
{
    my ($self, $table)=@_;

    if ( !defined($table) || $table eq 'Titles' ) {
	$self->runSQL("DROP INDEX IF EXISTS Titles_Idx1");
	$self->runSQL("DROP INDEX IF EXISTS Titles_Idx2");
	$self->runSQL("DROP INDEX IF EXISTS Titles_Idx3");
    }
    if ( !defined($table) || $table eq 'Directors') {
	$self->runSQL("DROP INDEX IF EXISTS Directors_Idx1");
	$self->runSQL("DROP INDEX IF EXISTS Directors_Idx2");
    }
    if ( !defined($table) || $table eq 'Actors') {
	$self->runSQL("DROP INDEX IF EXISTS Actors_Idx1");
	$self->runSQL("DROP INDEX IF EXISTS Actors_Idx2");
	$self->runSQL("DROP INDEX IF EXISTS Actors_Idx3");
	$self->runSQL("DROP INDEX IF EXISTS Actors_Idx4");
	$self->runSQL("DROP INDEX IF EXISTS Actors_Idx5");
    }
    if ( !defined($table) || $table eq 'Genres') {
	$self->runSQL("DROP INDEX IF EXISTS Genres_Idx1");
    }
    if ( !defined($table) || $table eq 'Ratings') {
	$self->runSQL("DROP INDEX IF EXISTS Ratings_Idx1");
    }
    if ( !defined($table) || $table eq 'Keywords') {
	$self->runSQL("DROP INDEX IF EXISTS Keywords_Idx1");
    }
    if ( !defined($table) || $table eq 'Plots' ) {
	$self->runSQL("DROP INDEX IF EXISTS Plots_Idx1");
    }
    return(1);
}

# Convert a title into a searchtitle by lowercasing,
# making it ASCII and removing punctuation.
#
sub makeSearchableTitle($;$;$) {
  my ($self, $str) = @_;
  return lc $self->RemovePunctuation(lc( CharsetMap( $str ) ));
}


use Text::Unidecode;

#   All characters outside the ASCII range (0x00-0x7F) are replaced by ASCII equivalents,
#    using function Text::Unidecode::unidecode
#
sub CharsetMap($) {
  my ($str) = @_;
  
  # do replacements that unidecode doesn't know about (or does wrong)
  ### IT WOULD BE NICE IF THESE WERE IN A TABLE
  $str =~ s/\x{0133}/ij/og;     # 'ij' -> ij             ("" in unidecode)
  $str =~ s/\x{20ac}/EUR/og;    # euro symbol -> EUR     (EU in unidecode)
  $str =~ s/\x{2122}/TM/og;     # trademark symbol -> TM ("" in unidecode)
  $str =~ s/\x{a3}/GBP/og;      # pound sign -> GBP (PS in unidecode)
  
  # now do the real decode
  $str = unidecode($str);
        
  #print "[$str]\n" if ($debug);
 
  return ($str);
}


my @punctuation;

# Function that removes all punctuation and whitespace from a string.
#  '&' is converted to 'and' along the way
sub RemovePunctuation($;$;$)
{
    my ($self, $str) = @_;

    # Load the array of hashes that contain the punctuation
    # replacements in priority order
    if ( !@punctuation ) {
        my @plist = @{$self->select2Matrix("select priority,pattern,replacement from Punctuation order by priority")};
        my $cnt = 0;
        foreach my $p (@plist) {
            my $pattern = $p->[1];
            my $compiled = qr/$pattern/i;
            $punctuation[$cnt]{origpattern} = $pattern;
            $punctuation[$cnt]{pattern}     = $compiled;
            $punctuation[$cnt]{replacement} = $p->[2];
            $cnt++;
        }
    }

    foreach my $ref (@punctuation) {
        #print "[$str] $ref->{origpattern} " if ($debug);
        $str =~ s/$ref->{pattern}/$ref->{replacement}/g;
        #print "[$str]\n" if ($debug);
    }
    #print "<$str>\n--------\n" if ($debug);
    return ($str);
}

=head1 INHERITED FUNCTIONS

The following functions are inherited from IMDB::Local::Base.

=head2 disconnect

Disconnect from the database. Note that for those lazy programmers that fail to call disconnect, the disconnect will be called when the
object is destructed through perl's DESTROY.

=head2 isConnected

Check to see if there has been previous successful 'connect' call.

=head2 quote

Call quote subroutine on DBI handle. Quote must not be called while not connected.

=head2 commit

Commit a DBI transaction (should only be used if db_AutoCommit was zero).

=head2 last_inserted_key

Retrieve the last inserted key for a given table and primaryKey.

=head2 runSQL

Execute a sql statement and return 1 upon success and 0 upon success. Upon failure, carp() is called with the sql statement.

=head2 runSQL_err

Return DBI->err() to retrieve error status of previous call to runSQL.

=head2 runSQL_errstr

Return DBI->errstr() to retrieve error status of previous call to runSQL.

=head2 prepare

Return DBI->prepare() for a given statement.

=head2 execute

Wrapper for calling DBI->prepare() and DBI->exeute() fora given query. Upon success the DBI->prepare() handle is returned.
Upon failure, warn() is called with the query statement string and undef is returned.

=head2 insert_row

Execute a table insertion and return the created primaryKey (if specified).
If primaryKey is not defined, 1 is returned upon success

=head2 query2SQLStatement

Construct an sql query using a hash containing:

  fields - required array of fields to select
  tables - required array of tables to select from
  wheres - optional array of where clauses to include (all and'd together)
  groupbys - optional array of group by clauses to include
  sortByField - optional field to sort by (if prefixed with -, then sort is reversed)
  orderbys - optional array of order by clauses to include
  offset - offset of returned rows
  limit - optional integer value to limit # of returned rows

=head2 findRecords

Call query2SQLStatement with the given hash arguments and return a IMDB::Local::DB::RecordIterator handle.

In addition to the query2SQLStatement arguments the following are optional:
  cacheBy - set cacheBy value in returned IMDB::Local::DB::RecordIterator handle. If not specified, limit is used.

=head2 rowExists

Check to see at least one row exists with value in 'column' in the specified 'table'

=head2 select2Scalar

Execute the given sql statement and return the value in a single scalar value

=head2 select2Int

Execute the given sql statement and return the value cast as an integer (ie int(returnvalue))

=head2 select2Array

Execute the given sql statement and return an array with all the results.

=head2 select2Matrix

Execute the given sql statement and return an array of arrays, each containing a row of values

=head2 select2HashRef

Execute the given sql statement and return a reference to a hash with the result

=head2 select2Hash

Execute the given sql statement and return a reference ot a hash containing the given row.

=head2 table_list

Retrieve a list of tables available. Created Tables or Views created after connect() may not be included.

=head2 table_exists

Check to see if a given table exists. Uses table_list.

=head2 column_info

Retrieve information about a given column in a table. Changes to columns made after connect() may not be included.

Returns a list of columns in a database/driver specific order containing:
 COLUMN_NAME - name of the column
 TYPE_NAME - data type (if available)
 COLUMN_SIZE - size of column data (if available)
 IS_NULL - true/false if column is nullable
 IS_PRIMARY_KEY - 1 or 0 if column is a primary key

=head2 column_list

Retrieve a list of column names in column_list order.

=head2 writeQuery2CSV

Run an sql query and output the result to the specified file in Text::CSV format

=head2 appendCSV2Table

Parse the given CVS file (which must have column names that match a the given table) and insert each row
as a new row into the specified table.

Upon success, returns > 0, number of rows successfully inserted.
Returns 0 if open() on the given file fails.

=head2 table_row_count

Retrieve the # of rows in a given table.

=head2 table_report

Retrieve a reference to an array of arrays, each sub-array containing [table, #ofRows, data-size-in-KBs, index-size-in-KBs]

=head1 AUTHOR

jerryv, C<< <jerry.veldhuis at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-imdb-local at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=IMDB-Local>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc IMDB::Local::DB


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=IMDB-Local>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/IMDB-Local>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/IMDB-Local>

=item * Search CPAN

L<http://search.cpan.org/dist/IMDB-Local/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2015 jerryv.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of IMDB::Local::DB

__DATA__
-- schema version is incremented with every backwards non-compatible change to the db schema
-- version 1 - initial alpha version
CREATE TABLE Versions (
    schema_version INTEGER DEFAULT 1
);

CREATE TABLE Punctuation (
    priority INTEGER,
    pattern VARCHAR NOT NULL,
    replacement VARCHAR NOT NULL
);

INSERT INTO Punctuation VALUES (10, '\\bA-', 'ahyphen');
INSERT INTO Punctuation VALUES (11, ',\\s*A$', '');
INSERT INTO Punctuation VALUES (12, '\\bA$', '123zzazz456');
INSERT INTO Punctuation VALUES (13, '\\bA\\.$', '123zzazz456.');
INSERT INTO Punctuation VALUES (15, '\\b(The|A|An)\\b', '');
INSERT INTO Punctuation VALUES (16, '123zzazz456$', 'a');
INSERT INTO Punctuation VALUES (17, '123zzazz456\\.$', 'a.');
INSERT INTO Punctuation VALUES (20, '&#8482;', '');
INSERT INTO Punctuation VALUES (21, '&', 'and');
INSERT INTO Punctuation VALUES (22, '\\+', 'and');
INSERT INTO Punctuation VALUES (23, '\@', 'at');
INSERT INTO Punctuation VALUES (25, '\\Wn\\W', 'and');
INSERT INTO Punctuation VALUES (40, '\\((?=\\s*\\d\\d?\\s*\\))', '(Part ');
INSERT INTO Punctuation VALUES (50, '\\bPt\\b', 'part');
INSERT INTO Punctuation VALUES (51, '\\bPt(?=\\s*\\d)', 'part ');
INSERT INTO Punctuation VALUES (52, '\\bVol\\b', 'volume');
INSERT INTO Punctuation VALUES (53, '\\bXmas\\b', 'christmas');
INSERT INTO Punctuation VALUES (54, '\\bit has\\b', 'its');
INSERT INTO Punctuation VALUES (55, '\\bit is\\b', 'its');
INSERT INTO Punctuation VALUES (56, '\\bversus\\b', 'vs');
INSERT INTO Punctuation VALUES (57, '\\bvs\\b', 'v');
INSERT INTO Punctuation VALUES (58, '\\bThru\\b', 'through');
INSERT INTO Punctuation VALUES (59, '\\bEp\\b', 'episode');
INSERT INTO Punctuation VALUES (60, '\\bWive$\\b', 'Wives');
INSERT INTO Punctuation VALUES (61, '\\bc''ship', 'championship');
INSERT INTO Punctuation VALUES (62, '\\bto\\b', '2');
INSERT INTO Punctuation VALUES (63, '\\bgp\\b', 'grand prix');
INSERT INTO Punctuation VALUES (64, '\\bch''ship', 'championship');
INSERT INTO Punctuation VALUES (65, '\\bb''ball\\b', 'basketball');
INSERT INTO Punctuation VALUES (66, '\\bconf\\b', 'conference');
INSERT INTO Punctuation VALUES (67, '\\ba''villa\\b', 'aston villa');
INSERT INTO Punctuation VALUES (68, '\\bb''burn\\b', 'blackburn');
INSERT INTO Punctuation VALUES (69, '\\butd\\b', 'united');
INSERT INTO Punctuation VALUES (70, '\\bl''pool\\b', 'liverpool');
INSERT INTO Punctuation VALUES (71, '\\bm''brough\\b', 'middlesbrough');
INSERT INTO Punctuation VALUES (72, '\\bceleb\\b', 'celebrity');
INSERT INTO Punctuation VALUES (73, '\\bwld\\b', 'world');
INSERT INTO Punctuation VALUES (74, '\\bchampionships\\b', 'championship');
INSERT INTO Punctuation VALUES (75, '\\btenpin\\b', 'ten pin');
INSERT INTO Punctuation VALUES (76, '\\bdr\\.?\\b', 'doctor');
INSERT INTO Punctuation VALUES (77, '\\btelevision\\b', 'TV');
INSERT INTO Punctuation VALUES (78, '\\bchamp\\b', 'championship');
INSERT INTO Punctuation VALUES (79, '\\bchamps\\b', 'championship');
INSERT INTO Punctuation VALUES (80, '\\brnd\\b', 'round');
INSERT INTO Punctuation VALUES (101, '\\b(?<=\\w)\\.', '');
INSERT INTO Punctuation VALUES (102, '\\bII\\b', '2');
INSERT INTO Punctuation VALUES (103, '\\bIII\\b', '3');
INSERT INTO Punctuation VALUES (104, '\\bIV\\b', '4');
INSERT INTO Punctuation VALUES (105, '\\bV\\b', '5');
INSERT INTO Punctuation VALUES (106, '\\bVI\\b', '6');
INSERT INTO Punctuation VALUES (107, '\\bVII\\b', '7');
INSERT INTO Punctuation VALUES (108, '\\bVIII\\b', '8');
INSERT INTO Punctuation VALUES (109, '\\bIX\\b', '9');
INSERT INTO Punctuation VALUES (110, '\\bX\\b', '10');
INSERT INTO Punctuation VALUES (111, '\\bXI\\b', '11');
INSERT INTO Punctuation VALUES (112, '\\bXII\\b', '12');
INSERT INTO Punctuation VALUES (113, '\\bXIII\\b', '13');
INSERT INTO Punctuation VALUES (114, '\\bXIV\\b', '14');
INSERT INTO Punctuation VALUES (115, '\\bXV\\b', '15');
INSERT INTO Punctuation VALUES (116, '\\bXVI\\b', '16');
INSERT INTO Punctuation VALUES (117, '\\bXVII\\b', '17');
INSERT INTO Punctuation VALUES (118, '\\bXVIII\\b', '18');
INSERT INTO Punctuation VALUES (119, '\\bXIX\\b', '19');
INSERT INTO Punctuation VALUES (120, '\\bXX\\b', '20');
INSERT INTO Punctuation VALUES (201, '\\bOne\\b', '1');
INSERT INTO Punctuation VALUES (202, '\\bTwo\\b', '2');
INSERT INTO Punctuation VALUES (203, '\\bThree\\b', '3');
INSERT INTO Punctuation VALUES (204, '\\bFour\\b', '4');
INSERT INTO Punctuation VALUES (205, '\\bFive\\b', '5');
INSERT INTO Punctuation VALUES (206, '\\bSix\\b', '6');
INSERT INTO Punctuation VALUES (207, '\\bSeven\\b', '7');
INSERT INTO Punctuation VALUES (208, '\\bEight\\b', '8');
INSERT INTO Punctuation VALUES (209, '\\bNine\\b', '9');
INSERT INTO Punctuation VALUES (210, '\\bTen\\b', '10');
INSERT INTO Punctuation VALUES (211, '\\bEleven\\b', '11');
INSERT INTO Punctuation VALUES (212, '\\bTwelve\\b', '12');
INSERT INTO Punctuation VALUES (213, '\\bThirteen\\b', '13');
INSERT INTO Punctuation VALUES (214, '\\bFourteen\\b', '14');
INSERT INTO Punctuation VALUES (215, '\\bFifteen\\b', '15');
INSERT INTO Punctuation VALUES (216, '\\bSixteen\\b', '16');
INSERT INTO Punctuation VALUES (217, '\\bSeventeen\\b', '17');
INSERT INTO Punctuation VALUES (218, '\\bEighteen\\b', '18');
INSERT INTO Punctuation VALUES (219, '\\bNineteen\\b', '19');
INSERT INTO Punctuation VALUES (220, '\\bTwenty\\b', '20');
INSERT INTO Punctuation VALUES (260, '\\bSixty\\b', '60');
INSERT INTO Punctuation VALUES (301, 'First', '1st');
INSERT INTO Punctuation VALUES (302, 'Second', '2nd');
INSERT INTO Punctuation VALUES (303, 'Third', '3rd');
INSERT INTO Punctuation VALUES (304, 'Fourth', '4th');
INSERT INTO Punctuation VALUES (305, 'Fifth', '5th');
INSERT INTO Punctuation VALUES (306, 'Sixth', '6th');
INSERT INTO Punctuation VALUES (307, 'Seventh', '7th');
INSERT INTO Punctuation VALUES (308, 'Eighth', '8th');
INSERT INTO Punctuation VALUES (309, 'Nineth', '9th');
INSERT INTO Punctuation VALUES (310, 'Tenth', '10th');
INSERT INTO Punctuation VALUES (999, '[^a-zA-Z0-9]', '');

CREATE TABLE QualifierTypes (
    QualifierTypeID INTEGER,
    Name CHAR(10)
);

INSERT INTO QualifierTypes(QualifierTypeID, Name) VALUES(1, 'tv_movie');
INSERT INTO QualifierTypes(QualifierTypeID, Name) VALUES(2, 'tv_mini_series');
INSERT INTO QualifierTypes(QualifierTypeID, Name) VALUES(3, 'tv_series');
INSERT INTO QualifierTypes(QualifierTypeID, Name) VALUES(4, 'video_movie');
INSERT INTO QualifierTypes(QualifierTypeID, Name) VALUES(5, 'video_game');
INSERT INTO QualifierTypes(QualifierTypeID, Name) VALUES(6, 'movie');

INSERT INTO QualifierTypes(QualifierTypeID, Name) VALUES(12, 'episode_of_tv_mini_series');
INSERT INTO QualifierTypes(QualifierTypeID, Name) VALUES(13, 'episode_of_tv_series');

CREATE TABLE Titles (
    TitleID INTEGER 			PRIMARY KEY, -- AUTOINCREMENT,
    SearchTitle VARCHAR,
    Title VARCHAR,
    QualifierTypeID CHAR(1) 		NOT NULL REFERENCES QualifierTypes(QualifierTypeID),
    Year INTEGER,
    ParentID INTEGER,			-- only set for episodes
    Series INTEGER,			-- only set for episodes (and still may be 0)
    Episode INTEGER,			-- only set for episodes (and still may be 0)
    AirDate INTEGER			-- some tv series have air-dates instead of series/episode information
);

-- table to give imdb list file's title string to a Title entry
-- CREATE TABLE IMDBTitleKeys (
--     String VARCHAR
--     TitleID INTEGER, -- from Titles
-- );

---
-- IMDB list files don't give us an any order to directors by title
---
CREATE TABLE Directors (
    DirectorID INTEGER PRIMARY KEY AUTOINCREMENT,
    SearchName VARCHAR,
    Name VARCHAR
);

CREATE TABLE Titles2Directors (
    TitleID INTEGER,
    DirectorID INTEGER
);

--
-- Actors are used for Roles, Hosts and Narrators
-- 
CREATE TABLE Actors (
    ActorID INTEGER PRIMARY KEY AUTOINCREMENT,
    SearchName VARCHAR,
    Name VARCHAR
);

CREATE TABLE Titles2Actors (
    TitleID INTEGER,
    ActorID INTEGER,
    Billing INTEGER
);

CREATE TABLE Titles2Hosts (
    TitleID INTEGER,
    ActorID INTEGER
);

CREATE TABLE Titles2Narrators (
    TitleID INTEGER,
    ActorID INTEGER
);

CREATE TABLE Genres (
    GenreID INTEGER PRIMARY KEY AUTOINCREMENT,
    Name VARCHAR
);

CREATE TABLE Titles2Genres (
    TitleID INTEGER,
    GenreID INTEGER
);

CREATE TABLE Ratings (
    TitleID INTEGER,
    Distribution VARCHAR,
    Votes INTEGER,
    Rank REAL
);

CREATE TABLE Keywords (
    KeywordID INTEGER PRIMARY KEY AUTOINCREMENT,
    Name VARCHAR
);

CREATE TABLE Titles2Keywords (
    TitleID INTEGER,
    KeywordID INTEGER
);

CREATE TABLE Plots (
    PlotID INTEGER PRIMARY KEY AUTOINCREMENT,
    TitleID INTEGER,
    Sequence INTEGER,
    Description VARCHAR,
    Author VARCHAR
);

