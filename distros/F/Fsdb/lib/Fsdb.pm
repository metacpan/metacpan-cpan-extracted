#!/usr/bin/perl -w

#
# Fsdb.pm
#
# Copyright (C) 1991-2016 by John Heidemann <johnh@isi.edu>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License,
# version 2, as published by the Free Software Foundation.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#

package Fsdb;

use warnings;
use strict;
use utf8;

=encoding utf8

=head1 NAME

Fsdb - a flat-text database for shell scripting


=cut
our $VERSION = '2.67';

=head1 SYNOPSIS

Fsdb, the flatfile streaming database is package of commands
for manipulating flat-ASCII databases from
shell scripts.  Fsdb is useful to process medium amounts of data (with
very little data you'd do it by hand, with megabytes you might want a
real database).
Fsdb was known as as Jdb from 1991 to Oct. 2008.

Fsdb is very good at doing things like:

=over 4

=item *

extracting measurements from experimental output

=item *

examining data to address different hypotheses

=item *

joining data from different experiments

=item *

eliminating/detecting outliers

=item *

computing statistics on data
(mean, confidence intervals, correlations, histograms)

=item *

reformatting data for graphing programs

=back

Fsdb is built around the idea of a flat text file as a database.
Fsdb files (by convention, with the extension F<.fsdb>),
have a header documenting the schema (what the columns mean),
and then each line represents a database record (or row).

For example:

	#fsdb experiment duration
	ufs_mab_sys 37.2
	ufs_mab_sys 37.3
	ufs_rcp_real 264.5
	ufs_rcp_real 277.9

Is a simple file with four experiments (the rows), 
each with a description, size parameter, and run time
in the first, second, and third columns.

Rather than hand-code scripts to do each special case, Fsdb provides
higher-level functions.  Although it's often easy throw together a
custom script to do any single task, I believe that there are several
advantages to using Fsdb:

=over 4

=item *

these programs provide a higher level interface than plain Perl, so

=over 4

=item **

Fewer lines of simpler code:

    dbrow '_experiment eq "ufs_mab_sys"' | dbcolstats duration

Picks out just one type of experiment and computes statistics on it,
rather than:

    while (<>) { split; $sum+=$F[1]; $ss+=$F[1]**2; $n++; }
    $mean = $sum / $n; $std_dev = ...

in dozens of places.

=back

=item *

the library uses names for columns, so

=over 4

=item **

No more C<$F[1]>, use C<_duration>.

=item **

New or different order columns?  No changes to your scripts!

=back

Thus if your experiment gets more complicated with a size parameter,
so your log changes to:

	#fsdb experiment size duration
	ufs_mab_sys 1024 37.2
	ufs_mab_sys 1024 37.3
	ufs_rcp_real 1024 264.5
	ufs_rcp_real 1024 277.9
	ufs_mab_sys 2048 45.3
	ufs_mab_sys 2048 44.2

Then the previous scripts still work, even though duration is
now the third column, not the second.

=item *

A series of actions are self-documenting (each program records what it does).

=over 4

=item **

No more wondering what hacks were used to compute the
final data, just look at the comments at the end
of the output.

=back

For example, the commands

    dbrow '_experiment eq "ufs_mab_sys"' | dbcolstats duration

add to the end of the output the lines
    #    | dbrow _experiment eq "ufs_mab_sys"
    #    | dbcolstats duration


=item *

The library is mature, supporting large datasets (more than 100GB), 
corner cases, error handling, backed by an automated test suite.

=over 4

=item **

No more puzzling about bad output because your custom script
skimped on error checking.

=item **

No more memory thrashing when you try to sort ten million records.

=back

=item *

Fsdb-2.x supports Perl scripting (in addition to shell scripting),
with libraries to do Fsdb input and output, and easy support for pipelines.
The shell script

    dbcol name test1 | dbroweval '_test1 += 5;'

can be written in perl as:

    dbpipeline(dbcol(qw(name test1)), dbroweval('_test1 += 5;'));

=back

(The disadvantage is that you need to learn what functions Fsdb provides.)

Fsdb is built on flat-ASCII databases.  By storing data in simple text
files and processing it with pipelines it is easy to experiment (in
the shell) and look at the output.  
To the best of my knowledge, the original implementation of
this idea was C</rdb>, a commercial product described in the book
I<UNIX relational database management: application development in the UNIX environment>
by Rod Manis, Evan Schaffer, and Robert Jorgensen (and
also at the web page L<http://www.rdb.com/>).  Fsdb is an incompatible
re-implementation of their idea without any accelerated indexing or
forms support.  (But it's free, and probably has better statistics!).

Fsdb-2.x will exploit multiple processors or cores,
and provides Perl-level support for input, output, and threaded-pipelines.
(As of Fsdb-2.44 it no longer uses Perl threading, just processes,
since they are faster.)

Installation instructions follow at the end of this document. 
Fsdb-2.x requires Perl 5.8 to run.  
All commands have manual pages and provide usage with the C<--help> option.
All commands are backed by an automated test suite.

The most recent version of Fsdb is available on the web at
L<http://www.isi.edu/~johnh/SOFTWARE/FSDB/index.html>.


=head1 WHAT'S NEW

=head2 2.67, 2019-07-10
summary tdb

=over 4

=item IMPROVEMENT

L<dbformmail> now has an "mh" mechanism that writes messages to 
individual files (an mh-style mailbox).

=item BUG FIX

L<dbrow> failed to include the Carp library, leading to fails on croak.

=item BUG FIX

Fixed L<dbjoin> error message for an unsorted right stream was incorrect
(it said left).

=item IMPROVEMENT

All Fsdb programs can now read from and write to HDFS,
when files that start with "hdfs:" are given to -i and -o options.

=back



=head1 README CONTENTS

=over 4

=item executive summary

=item what's new

=item README CONTENTS

=item installation

=item basic data format

=item basic data manipulation

=item list of commands

=item another example

=item a gradebook example

=item a password example

=item history

=item related work

=item release notes

=item copyright

=item comments

=back


=head1 INSTALLATION

Fsdb now uses the standard Perl build and installation from
ExtUtil::MakeMaker(3), so the quick answer to installation is to type:
    
    perl Makefile.PL
    make
    make test
    make install

Or, if you want to install it somewhere else, change the first line to

    perl Makefile.PL PREFIX=$HOME

and it will go in your home directory's F<bin>, etc.
(See L<ExtUtil::MakeMaker(3)> for more details.)

Fsdb requires perl 5.8 or later.

A test-suite is available, run it with

    make test

A FreeBSD port to Fsdb is available, see
L<http://www.freshports.org/databases/fsdb/>.

A Fink (MacOS X) port is available, see
L<http://pdb.finkproject.org/pdb/package.php/fsdb>.
(Thanks to Lars Eggert for maintaining this port.)


=head1 BASIC DATA FORMAT

These programs are based on the idea storing data in simple ASCII
files.  A database is a file with one header line and then data or
comment lines.  For example:

	#fsdb account passwd uid gid fullname homedir shell
	johnh * 2274 134 John_Heidemann /home/johnh /bin/bash
	greg * 2275 134 Greg_Johnson /home/greg /bin/bash
	root * 0 0 Root /root /bin/bash
	# this is a simple database

The header line must be first and begins with C<#h>.
There are rows (records) and columns (fields),
just like in a normal database.
Comment lines begin with C<#>.
Column names are any string not containing spaces or single quote
(although it is prudent to keep them alphanumeric with underscore).

By default, columns are delimited by whitespace.  
With this default configuration, the contents of a field
cannot contain whitespace.
However, this limitation can be relaxed by changing the field separator
as described below.

The big advantage of simple flat-text databases is that 
it is usually easy to massage data into this format,
and it's reasonably easy to take data out of this
format into other (text-based) programs, like gnuplot, jgraph, and
LaTeX.  Think Unix.  Think pipes.
(Or even output to Excel and HTML if you prefer.)

Since no-whitespace in columns was a problem for some applications,
there's an option which relaxes this rule.  You can specify the field
separator in the table header with C<-F x> where C<x> is 
a code for the new field separator.
A full list of codes is at L<dbfilealter(1)>,
but two common special values are C<-F t>
which is a separator of a single tab character,
and C<-F S>, a separator of two spaces.
Both allowing (single) spaces in fields.  An example:

	#fsdb -F S account passwd uid gid fullname homedir shell
	johnh  *  2274  134  John Heidemann  /home/johnh  /bin/bash
	greg  *  2275  134  Greg Johnson  /home/greg  /bin/bash
	root  *  0  0  Root  /root  /bin/bash
	# this is a simple database

See L<dbfilealter(1)> for more details.  Regardless of what the column
separator is for the body of the data, it's always whitespace in the
header.

There's also a third format: a "list".  Because it's often hard to see
what's columns past the first two, in list format each "column" is on
a separate line.  The programs dblistize and dbcolize convert to and
from this format, and all programs work with either formats.
The command

    dbfilealter -R C  < DATA/passwd.fsdb

outputs:

	#fsdb -R C account passwd uid gid fullname homedir shell
	account:  johnh
	passwd:   *
	uid:      2274
	gid:      134
	fullname: John_Heidemann
	homedir:  /home/johnh
	shell:    /bin/bash
	
	account:  greg
	passwd:   *
	uid:      2275
	gid:      134
	fullname: Greg_Johnson
	homedir:  /home/greg
	shell:    /bin/bash
	
	account:  root
	passwd:   *
	uid:      0
	gid:      0
	fullname: Root
	homedir:  /root
	shell:    /bin/bash
	
	# this is a simple database
	#  | dblistize 

See L<dbfilealter(1)> for more details.


=head1 BASIC DATA MANIPULATION

A number of programs exist to manipulate databases.
Complex functions can be made by stringing together commands
with shell pipelines.  For example, to print the home
directories of everyone with ``john'' in their names,
you would do:

	cat DATA/passwd | dbrow '_fullname =~ /John/' | dbcol homedir

The output might be:

	#fsdb homedir
	/home/johnh
	/home/greg
	# this is a simple database
	#  | dbrow _fullname =~ /John/
	#  | dbcol homedir

(Notice that comments are appended to the output listing each command,
providing an automatic audit log.)

In addition to typical database functions (select, join, etc.) there
are also a number of statistical functions.

The real power of Fsdb is that one can apply arbitrary code to rows
to do powerful things.

	cat DATA/passwd | dbroweval '_fullname =~ s/(\w+)_(\w+)/$2,_$1/'

converts "John_Heidemann" into "Heidemann,_John".
Not too much more work could split fullname into firstname and lastname
fields.

(Or:

	cat DATA/passwd | dbcolcreate sort | dbroweval -b 'use Fsdb::Support'
		'_sort = _fullname; _sort =~ s/_/ /g; _sort = fullname_to_sort(_sort);'


=head1 TALKING ABOUT COLUMNS

An advantage of Fsdb is that you can talk about columns by name
(symbolically) rather than simply by their positions.  So in the above
example, C<dbcol homedir> pulled out the home directory column, and
C<dbrow '_fullname =~ /John/'> matched against column fullname.

In general, you can use the name of the column listed on the C<#fsdb> line
to identify it in most programs, and _name to identify it in code.

Some alternatives for flexibility:

=over 4

=item *

Numeric values identify columns positionally, numbering from 0.
So 0 or _0 is the first column, 1 is the second, etc.

=item *

In code, _last_columnname gets the value from columname's previous row.

=back

See L<dbroweval(1)> for more details about writing code.



=head1 LIST OF COMMANDS

Enough said.  I'll summarize the commands, and then you can
experiment.  For a detailed description of each command, see a summary
by running it with the argument C<--help> (or C<-?> if you prefer.)
Full manual pages can be found by running the command
with the argument C<--man>, or running the Unix command C<man dbcol>
or whatever program you want.

=head2 TABLE CREATION

=over 4

=item dbcolcreate

add columns to a database

=item dbcoldefine

set the column headings for a non-Fsdb file

=back

=head2 TABLE MANIPULATION

=over 4

=item dbcol

select columns from a table

=item dbrow

select rows from a table

=item dbsort

sort rows based on a set of columns

=item dbjoin

compute the natural join of two tables

=item dbcolrename

rename a column

=item dbcolmerge

merge two columns into one

=item dbcolsplittocols

split one column into two or more columns

=item dbcolsplittorows

split one column into multiple rows

=item dbfilepivot

"pivots" a file, converting multiple rows
corresponding to the same entity into a single row with multiple columns.

=item dbfilevalidate

check that db file doesn't have some common errors

=back

=head2 COMPUTATION AND STATISTICS

=over 4

=item dbcolstats

compute statistics over a column (mean,etc.,optionally median)

=item dbmultistats

group rows by some key value, then compute stats (mean, etc.) over each group
(equivalent to dbmapreduce with dbcolstats as the reducer)

=item dbmapreduce

group rows (map) and then apply an arbitrary function to each group (reduce)

=item dbrvstatdiff

compare two samples distributions (mean/conf interval/T-test)

=item dbcolmovingstats

computing moving statistics over a column of data

=item dbcolstatscores

compute Z-scores and T-scores over one column of data

=item dbcolpercentile

compute the rank or percentile of a column

=item dbcolhisto

compute histograms over a column of data

=item dbcolscorrelate

compute the coefficient of correlation over several columns

=item dbcolsregression

compute linear regression and correlation for two columns

=item dbrowaccumulate

compute a running sum over a column of data

=item dbrowcount

count the number of rows (a subset of dbstats)

=item dbrowdiff

compute differences between a columns in each row of a table

=item dbrowenumerate

number each row

=item dbroweval

run arbitrary Perl code on each row

=item dbrowuniq

count/eliminate identical rows (like Unix uniq(1))

=item dbfilediff

compare fields on rows of a file (something like Unix diff(1))

=back

=head2 OUTPUT CONTROL

=over 4

=item dbcolneaten

pretty-print columns

=item dbfilealter

convert between column or list format, or change the column separator

=item dbfilestripcomments

remove comments from a table

=item dbformmail

generate a script that sends form mail based on each row

=back

=head2 CONVERSIONS

(These programs convert data into fsdb.  See their web pages for details.)

=over 4

=item cgi_to_db

L<http://stein.cshl.org/boulder/>

=item combined_log_format_to_db

L<http://httpd.apache.org/docs/2.0/logs.html>

=item html_table_to_db

HTML tables to fsdb (assuming they're reasonably formatted).

=item kitrace_to_db    

L<http://ficus-www.cs.ucla.edu/ficus-members/geoff/kitrace.html>

=item ns_to_db 

L<http://mash-www.cs.berkeley.edu/ns/>

=item sqlselect_to_db   

the output of SQL SELECT tables to db

=item tabdelim_to_db   

spreadsheet tab-delimited files to db

=item tcpdump_to_db  

(see man tcpdump(8) on any reasonable system)

=item xml_to_db  

XML input to fsdb, assuming they're very regular


=back

(And out of fsdb:)

=over 4

=item db_to_csv

Comma-separated-value format from fsdb.

=item db_to_html_table

simple conversion of Fsdb to html tables

=back

=head2 STANDARD OPTIONS

Many programs have common options:

=over 4

=item B<-?> or B<--help>

Show basic usage.

=item B<-N> on B<--new-name>

When a command creates a new column like L<dbrowaccumulate>'s C<accum>,
this option lets one override the default name of that new column.

=item B<-T TmpDir>

where to put tmp files.
Also uses environment variable TMPDIR, if -T is 
not specified.
Default is /tmp.

Show basic usage.

=item B<-c FRACTION> or B<--confidence FRACTION>

Specify confidence interval FRACTION (L<dbcolstats>, L<dbmultistats>, etc.)

=item B<-C S> or C<--element-separator S>

Specify column separator S (L<dbcolsplittocols>, L<dbcolmerge>).

=item B<-d> or B<--debug>

Enable debugging (may be repeated for greater effect in some cases).

=item B<-a> or B<--include-non-numeric>

Compute stats over all data (treating non-numbers as zeros).
(By default, things that can't be treated as numbers
are ignored for stats purposes)

=item B<-S> or B<--pre-sorted>

Assume the data is pre-sorted.
May be repeated to disable verification (saving a small amount of work).

=item B<-e E> or B<--empty E>

give value E as the value for empty (null) records

=item B<-i I> or B<--input I>

Input data from file I.

=item B<-o O> or B<--output O>

Write data out to file O.

=item B<--header> H

Use H as the full Fsdb header, rather than reading a header from
then input.  This option is particularly useful when using Fsdb
under Hadoop, where split files don't have heades.

=item B<--nolog>.

Skip logging the program in a trailing comment.

=back

When giving Perl code (in L<dbrow> and L<dbroweval>)
column names can be embedded if preceded by underscores.
Look at L<dbrow(1)> or L<dbroweval(1)> for examples.)

Most programs run in constant memory and use temporary files if necessary.
Exceptions are L<dbcolneaten>, L<dbcolpercentile>, L<dbmapreduce>,
L<dbmultistats>, L<dbrowsplituniq>.


=head1 ANOTHER EXAMPLE

Take the raw data in C<DATA/http_bandwidth>,
put a header on it (C<dbcoldefine size bw>),
took statistics of each category (C<dbmultistats -k size bw>),
pick out the relevant fields (C<dbcol size mean stddev pct_rsd>), and you get:

	#fsdb size mean stddev pct_rsd
	1024    1.4962e+06      2.8497e+05      19.047
	10240   5.0286e+06      6.0103e+05      11.952
	102400  4.9216e+06      3.0939e+05      6.2863
	#  | dbcoldefine size bw
	#  | /home/johnh/BIN/DB/dbmultistats -k size bw
	#  | /home/johnh/BIN/DB/dbcol size mean stddev pct_rsd

(The whole command was:

	cat DATA/http_bandwidth |
	dbcoldefine size |
	dbmultistats -k size bw |
	dbcol size mean stddev pct_rsd

all on one line.)

Then post-process them to get rid of the exponential notation
by adding this to the end of the pipeline:

    dbroweval '_mean = sprintf("%8.0f", _mean); _stddev = sprintf("%8.0f", _stddev);'

(Actually, this step is no longer required since L<dbcolstats>
now uses a different default format.)

giving:

	#fsdb      size    mean    stddev  pct_rsd
	1024     1496200          284970        19.047
	10240    5028600          601030        11.952
	102400   4921600          309390        6.2863
	#  | dbcoldefine size bw
	#  | dbmultistats -k size bw
	#  | dbcol size mean stddev pct_rsd
	#  | dbroweval   { _mean = sprintf("%8.0f", _mean); _stddev = sprintf("%8.0f", _stddev); }

In a few lines, raw data is transformed to processed output.


Suppose you expect there is an odd distribution of results of one
datapoint.  Fsdb can easily produce a CDF (cumulative distribution
function) of the data, suitable for graphing:

    cat DB/DATA/http_bandwidth | \
        dbcoldefine size bw | \
	dbrow '_size == 102400' | \
	dbcol bw | \
	dbsort -n bw | \
	dbrowenumerate | \
	dbcolpercentile count | \
	dbcol bw percentile | \
	xgraph

The steps, roughly:
1. get the raw input data and turn it into fsdb format,
2. pick out just the relevant column (for efficiency) and sort it,
3. for each data point, assign a CDF percentage to it,
4. pick out the two columns to graph and show them


=head1 A GRADEBOOK EXAMPLE

The first commercial program I wrote was a gradebook,
so here's how to do it with Fsdb.

Format your data like DATA/grades.

	#fsdb name email id test1
	a a@ucla.example.edu 1 80
	b b@usc.example.edu 2 70
	c c@isi.example.edu 3 65
	d d@lmu.example.edu 4 90
	e e@caltech.example.edu 5 70
	f f@oxy.example.edu 6 90

Or if your students have spaces in their names, use C<-F S> and two spaces
to separate each column:

	#fsdb -F S name email id test1
	alfred aho  a@ucla.example.edu  1  80
	butler lampson  b@usc.example.edu  2  70
	david clark  c@isi.example.edu  3  65
	constantine drovolis  d@lmu.example.edu  4  90
	debrorah estrin  e@caltech.example.edu  5  70
	sally floyd  f@oxy.example.edu  6  90

To compute statistics on an exam, do

	cat DATA/grades | dbstats test1 |dblistize

giving

	#fsdb -R C  ...
	mean:        77.5
	stddev:      10.84
	pct_rsd:     13.987
	conf_range:  11.377
	conf_low:    66.123
	conf_high:   88.877
	conf_pct:    0.95
	sum:         465
	sum_squared: 36625
	min:         65
	max:         90
	n:           6
	...

To do a histogram:

	cat DATA/grades | dbcolhisto -n 5 -g test1

giving

	#fsdb low histogram
	65      *
	70      **
	75
	80      *
	85
	90      **
	#  | /home/johnh/BIN/DB/dbhistogram -n 5 -g test1

Now you want to send out grades to the students by e-mail.
Create a form-letter (in the file F<test1.txt>):

	To: _email (_name)
	From: J. Random Professor <jrp@usc.example.edu>
	Subject: test1 scores

	_name, your score on test1 was _test1.
	86+   A
	75-85 B
	70-74 C
	0-69  F

Generate the shell script that will send the mail out:

	cat DATA/grades | dbformmail test1.txt > test1.sh

And run it:

	sh <test1.sh

The last two steps can be combined:

	cat DATA/grades | dbformmail test1.txt | sh

but I like to keep a copy of exactly what I send.


At the end of the semester you'll want to compute grade totals and
assign letter grades.  Both fall out of dbroweval.
For example, to compute weighted total grades with a 40% midterm/60%
final where the midterm is 84 possible points and the final 100:

	dbcol -rv total |
	dbcolcreate total - |
	dbroweval '
		_total = .40 * _midterm/84.0 + .60 * _final/100.0;
		_total = sprintf("%4.2f", _total);
		if (_final eq "-" || ( _name =~ /^_/)) { _total = "-"; };' | 
	dbcolneaten  


If you got the data originally from a spreadsheet, save it in
"tab-delimited" format and convert it with tabdelim_to_db
(run tabdelim_to_db -? for examples).


=head1 A PASSWORD EXAMPLE

To convert the Unix password file to db:

	cat /etc/passwd | sed 's/:/  /g'| \
		dbcoldefine -F S login password uid gid gecos home shell \
		>passwd.fsdb

To convert the group file

	cat /etc/group | sed 's/:/  /g' | \
		dbcoldefine -F S group password gid members \
		>group.fsdb

To show the names of the groups that div7-members are in
(assuming DIV7 is in the gecos field):

	cat passwd.fsdb | dbrow '_gecos =~ /DIV7/' | dbcol login gid | \
		dbjoin -i - -i group.fsdb gid | dbcol login group


=head1 SHORT EXAMPLES

Which Fsdb programs are the most complicated (based on number of test cases)?

        ls TEST/*.cmd | \
                dbcoldefine test | \
                dbroweval '_test =~ s@^TEST/([^_]+).*$@$1@' | \
                dbrowuniq -c | \
                dbsort -nr count | \
                dbcolneaten

(Answer: L<dbmapreduce>, then L<dbcolstats>, L<dbfilealter> and L<dbjoin>.)


Stats on an exam (in C<$FILE>, where C<$COLUMN> is the name of the exam)?

	cat $FILE | dbcolstats -q 4 $COLUMN <$FILE | dblistize | dbstripcomments

	cat $FILE | dbcolhisto -g -n 20 $COLUMN | dbcolneaten | dbstripcomments


Merging a the hw1 column from file hw1.fsdb into grades.fsdb assuming
there's a common student id in column "id":

	dbcol id hw1 <hw1.fsdb >t.fsdb

	dbjoin -a -e - grades.fsdb t.fsdb id | \
	    dbsort  name | \
	    dbcolneaten >new_grades.fsdb


Merging two fsdb files with the same rows:

	cat file1.fsdb file2.fsdb >output.fsdb

or if you want to clean things up a bit

	cat file1.fsdb file2.fsdb | dbstripextraheaders >output.fsdb

or if you want to know where the data came from

	for i in 1 2
	do
		dbcolcreate source $i < file$i.fsdb
	done >output.fsdb

(assumes you're using a Bourne-shell compatible shell, not csh).
	

=head1 WARNINGS

As with any tool, one should (which means I<must>) understand
the limits of the tool.

All Fsdb tools should run in I<constant memory>.
In some cases (such as F<dbcolstats> with quartiles, where the whole input
must be re-read), programs will spool data to disk if necessary.

Most tools buffer one or a few lines of data, so memory
will scale with the size of each line.
(So lines with many columns, or when columns have lots data,
may cause large memory consumption.)

All Fsdb tools should run in constant or at worst C<n log n> time.

All Fsdb tools use normal Perl math routines for computation.
Although I make every attempt to choose numerically stable algorithms
(although I also welcome feedback and suggestions for improvement),
normal rounding due to computer floating point approximations
can result in inaccuracies when data spans a large range of precision.
(See for example the F<dbcolstats_extrema> test cases.)

Any requirements and limitations of each Fsdb tool
is documented on its manual page.

If any Fsdb program violates these assumptions,
that is a bug that should be documented
on the tool's manual page or ideally fixed.

Fsdb does depend on Perl's correctness, and Perl (and Fsdb) have
some bugs.  Fsdb should work on perl from version 5.10 onward.


=head1 HISTORY

There have been three versions of Fsdb;
fsdb 1.0 is a complete re-write of the pre-1995 versions,
and was 
distributed from 1995 to 2007.
Fsdb 2.0 is a significant re-write of the 1.x versions
for reasons described below.

Fsdb (in its various forms) has been used extensively by its author
since 1991.  Since 1995 it's been used by two other researchers at
UCLA and several at ISI.  In February 1998 it was announced to the
Internet.  Since then it has found a few users, some outside where I
work.

Major changes: 

=over 4

=item 1.0 1997-07-22: first public release.

=item 2.0 2008-01-25: rewrite to use a common library, and starting to use threads.

=item 2.12 2008-10-16: completion of the rewrite, and first RPM package.

=item 2.44 2013-10-02: abandoning threads for improved performance

=back

=head2 Fsdb 2.0 Rationale

I've thought about fsdb-2.0 for many years, but it was started
in earnest in 2007.  Fsdb-2.0 has the following goals:

=over 4

=item in-one-process processing

While fsdb is great on the Unix command line as a pipeline between
programs, it should I<also> be possible to set it up to run in a single
process.  And if it does so, it should be able to avoid serializing
and deserializing (converting to and from text) data between each module.
(Accomplished in fsdb-2.0: see L<dbpipeline>, although still needs tuning.)

=item clean IO API

Fsdb's roots go back to perl4 and 1991, so the fsdb-1.x library is
very, very crufty.  More than just being ugly (but it was that too),
this made things reading from one format file and writing to another
the application's job, when it should be the library's.
(Accomplished in fsdb-1.15 and improved in 2.0: see L<Fsdb::IO>.)

=item normalized module APIs

Because fsdb modules were added as needed over 10 years,
sometimes the module APIs became inconsistent.
(For example, the 1.x C<dbcolcreate> required an empty
value following the name of the new column,
but other programs specify empty values with the C<-e> argument.)
We should smooth over these inconsistencies.
(Accomplished as each module was ported in 2.0 through 2.7.)

=item everyone handles all input formats

Given a clean IO API, the distinction between "colized"
and "listized" fsdb files should go away.  Any program
should be able to read and write files in any format.
(Accomplished in fsdb-2.1.)

=back

Fsdb-2.0 preserves backwards compatibility where possible,
but breaks it where necessary to accomplish the above goals.
In August 2008, Fsdb-2.7 was declared preferred over the 1.x versions.
Benchmarking in 2013 showed that threading performed much worse than
just using pipes, so Fsdb-2.44 uses threading "style",
but implemented with processes (via my "Freds" library).

=head2 Contributors

Fsdb includes code ported from Geoff Kuenning (C<Fsdb::Support::TDistribution>).

Fsdb contributors:  
Ashvin Goel F<goel@cse.oge.edu>,
Geoff Kuenning F<geoff@fmg.cs.ucla.edu>,
Vikram Visweswariah F<visweswa@isi.edu>,
Kannan Varadahan F<kannan@isi.edu>,
Lars Eggert F<larse@isi.edu>,
Arkadi Gelfond F<arkadig@dyna.com>,
David Graff F<graff@ldc.upenn.edu>,
Haobo Yu F<haoboy@packetdesign.com>,
Pavlin Radoslavov F<pavlin@catarina.usc.edu>,
Graham Phillips,
Yuri Pradkin,
Alefiya Hussain,
Ya Xu,
Michael Schwendt,
Fabio Silva F<fabio@isi.edu>,
Jerry Zhao F<zhaoy@isi.edu>,
Ning Xu F<nxu@aludra.usc.edu>,
Martin Lukac F<mlukac@lecs.cs.ucla.edu>,
Xue Cai,
Michael McQuaid,
Christopher Meng,
Calvin Ardi,
H. Merijn Brand,
Lan Wei,
Hang Guo.

Fsdb includes datasets contributed from NIST (F<DATA/nist_zarr13.fsdb>),
from
L<http://www.itl.nist.gov/div898/handbook/eda/section4/eda4281.htm>,
the NIST/SEMATECH e-Handbook of Statistical Methods, section
1.4.2.8.1. Background and Data.  The source is public domain, and
reproduced with permission.




=head1 RELATED WORK

As stated in the introduction, Fsdb is an incompatible reimplementation
of the ideas found in C</rdb>.  By storing data in simple text files and
processing it with pipelines it is easy to experiment (in the shell)
and look at the output.  The original implementation of this idea was
/rdb, a commercial product described in the book I<UNIX relational
database management: application development in the UNIX environment>
by Rod Manis, Evan Schaffer, and Robert Jorgensen (and also at the web
page L<http://www.rdb.com/>).

While Fsdb is inspired by Rdb, it includes no code from it,
and Fsdb makes several different design choices.
In particular: rdb attempts to be closer to a "real" database,
with provision for locking, file indexing.
Fsdb focuses on single user use and so eschews these choices.
Rdb also has some support for interactive editing.
Fsdb leaves editing to text editors like emacs or vi.

In August, 2002 I found out Carlo Strozzi extended RDB with his
package NoSQL L<http://www.linux.it/~carlos/nosql/>.  According to
Mr. Strozzi, he implemented NoSQL in awk to avoid the Perl start-up of
RDB.  Although I haven't found Perl startup overhead to be a big
problem on my platforms (from old Sparcstation IPCs to 2GHz
Pentium-4s), you may want to evaluate his system.
The Linux Journal has a description of NoSQL
at L<http://www.linuxjournal.com/article/3294>.
It seems quite similar to Fsdb.
Like /rdb, NoSQL supports indexing (not present in Fsdb).
Fsdb appears to have richer support for statistics,
and, as of Fsdb-2.x, its support for Perl threading may support
faster performance (one-process, less serialization and deserialization).


=head1 RELEASE NOTES

Versions prior to 1.0 were released informally on my web page
but were not announced.

=head2 0.0 1991

started for my own research use

=head2 0.1 26-May-94

first check-in to RCS

=head2 0.2 15-Mar-95

parts now require perl5

=head2 1.0, 22-Jul-97

adds autoconf support and a test script.

=head2 1.1, 20-Jan-98

support for double space field separators, better tests

=head2 1.2, 11-Feb-98

minor changes and release on comp.lang.perl.announce

=head2 1.3, 17-Mar-98

=over 4

=item *
adds median and quartile options to dbstats


=item *

adds dmalloc_to_db converter


=item *

fixes some warnings


=item *

dbjoin now can run on unsorted input


=item *

fixes a dbjoin bug


=item *

some more tests in the test suite

=back

=head2 1.4, 27-Mar-98

=over 4

=item *

improves error messages (all should now report the program that makes the error)

=item *

fixed a bug in dbstats output when the mean is zero

=back

=head2 1.5, 25-Jun-98

=over 4

=item BUG FIX
dbcolhisto, dbcolpercentile now handles non-numeric values like dbstats

=item NEW
dbcolstats computes zscores and tscores over a column

=item NEW
dbcolscorrelate computes correlation coefficients between two columns

=item INTERNAL
ficus_getopt.pl has been replaced by DbGetopt.pm

=item BUG FIX
all tests are now ``portable'' (previously some tests ran only on my system)

=item BUG FIX
you no longer need to have the db programs in your path (fix arose from a discussion with Arkadi Gelfond)

=item BUG FIX
installation no longer uses cp -f (to work on SunOS 4)

=back

=head2 1.6, 24-May-99

=over 4

=item NEW
dbsort, dbstats, dbmultistats now run in constant memory (using tmp files if necessary)

=item NEW
dbcolmovingstats does moving means over a series of data

=item NEW
dbcol has a -v option to get all columns except those listed

=item NEW
dbmultistats does quartiles and medians

=item NEW
dbstripextraheaders now also cleans up bogus comments before the fist header

=item BUG FIX
dbcolneaten works better with double-space-separated data

=back

=head2 1.7,  5-Jan-00

=over 4

=item NEW
dbcolize now detects and rejects lines that contain embedded copies of the field separator

=item NEW
configure tries harder to prevent people from improperly configuring/installing fsdb

=item NEW
tcpdump_to_db converter (incomplete)

=item NEW
tabdelim_to_db converter:  from spreadsheet tab-delimited files to db

=item NEW
mailing lists for fsdb are	C<fsdb-announce@heidemann.la.ca.us> and	C<fsdb-talk@heidemann.la.ca.us>

To subscribe to either, send mail to	C<fsdb-announce-request@heidemann.la.ca.us>	or C<fsdb-talk-request@heidemann.la.ca.us>     with "subscribe" in the BODY of the message.

=item BUG FIX
dbjoin used to produce incorrect output if there were extra, unmatched values in the 2nd table. Thanks to Graham Phillips for providing a test case.

=item BUG FIX
the sample commands in the usage strings now all should explicitly include the source of data (typically from "cat foo.fsdb |").  Thanks to Ya Xu for pointing out this documentation deficiency.

=item BUG FIX (DOCUMENTATION)
dbcolmovingstats had incorrect sample output.

=back

=head2 1.8, 28-Jun-00

=over 4

=item BUG FIX
header options are now preserved when writing with dblistize

=item NEW
dbrowuniq now optionally checks for uniqueness only on certain fields

=item NEW
dbrowsplituniq makes one pass through a file and splits it into separate files based on the given fields

=item NEW
converter for "crl" format network traces

=item NEW
anywhere you use arbitrary code (like dbroweval), _last_foo now maps to the last row's value for field _foo.

=item OPTIMIZATION
comment processing slightly changed so that dbmultistats now is much faster on files with lots of comments (for example, ~100k lines of comments and 700 lines of data!) (Thanks to Graham Phillips for pointing out this performance problem.)

=item BUG FIX
dbstats with median/quartiles now correctly handles singleton data points.

=back

=head2 1.9,  6-Nov-00

=over 4

=item NEW
dbfilesplit, split a single input file into multiple output files (based on code contributed by Pavlin Radoslavov).

=item BUG FIX
dbsort now works with perl-5.6

=back

=head2 1.10, 10-Apr-01

=over 4

=item BUG FIX
dbstats now handles the case where there are more n-tiles than data

=item NEW
dbstats now includes a -S option to optimize work on pre-sorted data (inspired by code contributed by Haobo Yu)

=item BUG FIX
dbsort now has a better estimate of memory usage when run on data with very short records (problem detected by Haobo Yu)

=item BUG FIX
cleanup of temporary files is slightly better

=back

=head2 1.11,  2-Nov-01

=over 4

=item BUG FIX
dbcolneaten now runs in constant memory

=item NEW
dbcolneaten now supports "field specifiers" that allow some control over how wide columns should be

=item OPTIMIZATION
dbsort now tries hard to be filesystem cache-friendly (inspired by "Information and Control in Gray-box Systems" by the Arpaci-Dusseau's at SOSP 2001)

=item INTERNAL
t_distr now ported to perl5 module DbTDistr

=back

=head2 1.12,  30-Oct-02

=over 4

=item BUG FIX
dbmultistats documentation typo fixed

=item NEW
dbcolmultiscale

=item NEW
dbcol has -r option for "relaxed error checking"

=item NEW
dbcolneaten has new -e option to strip end-of-line spaces

=item NEW
dbrow finally has a -v option to negate the test

=item BUG FIX
math bug in dbcoldiff fixed by Ashvin Goel (need to check Scheaffer test cases)

=item BUG FIX
some patches to run with Perl 5.8. Note: some programs (dbcolmultiscale, dbmultistats, dbrowsplituniq) generate warnings like: "Use of uninitialized value in concatenation (.)" or "string at /usr/lib/perl5/5.8.0/FileCache.pm line 98, <STDIN> line 2". Please ignore this until I figure out how to suppress it. (Thanks to Jerry Zhao for noticing perl-5.8 problems.)

=item BUG FIX
fixed an autoconf problem where configure would fail to find a reasonable prefix (thanks to Fabio Silva for reporting the problem)

=item NEW
db_to_html_table: simple conversion to html tables (NO fancy stuff)

=item NEW
dblib now has a function dblib_text2html() that will do simple conversion of iso-8859-1 to HTML

=back


=head2 1.13,  4-Feb-04


=over 4

=item NEW
fsdb added to the freebsd ports tree L<http://www.freshports.org/databases/fsdb/>.  Maintainer: C<larse@isi.edu>

=item BUG FIX
properly handle trailing spaces when data must be numeric (ex. dbstats with -FS, see test dbstats_trailing_spaces). Fix from Ning Xu C<nxu@aludra.usc.edu>.

=item NEW
dbcolize error message improved (bug report from Terrence Brannon), and list format documented in the README.

=item NEW
cgi_to_db converts CGI.pm-format storage to fsdb list format

=item BUG FIX
handle numeric synonyms for column names in dbcol properly

=item ENHANCEMENT
"talking about columns" section added to README. Lack of documentation pointed out by Lars Eggert.

=item CHANGE
dbformmail now defaults to using Mail ("Berkeley Mail") to send mail, rather than sendmail (sendmail is still an option, but mail doesn't require running as root)

=item NEW
on platforms that support it (i.e., with perl 5.8), fsdb works fine with unicode

=item NEW
dbfilevalidate: check a db file for some common errors

=back


=head2 1.14,  24-Aug-06

=over 4


=item ENHANCEMENT
README cleanup

=item INCOMPATIBLE CHANGE
dbcolsplit renamed dbcolsplittocols

=item NEW
dbcolsplittorows  split one column into multiple rows

=item NEW
dbcolsregression compute linear regression and correlation for two columns

=item ENHANCEMENT
cvs_to_db: better error handling, normalize field names, skip blank lines

=item ENHANCEMENT
dbjoin now detects (and fails) if non-joined files have duplicate names

=item BUG FIX
minor bug fixed in calculation of Student t-distributions (doesn't change any test output, but may have caused small errors)

=back

=head2 1.15, 12-Nov-07

=over 4

=item NEW
fsdb-1.14 added to the MacOS Fink system L<http://pdb.finkproject.org/pdb/package.php/fsdb>. (Thanks to Lars Eggert for maintaining this port.)

=item NEW
Fsdb::IO::Reader and Fsdb::IO::Writer now provide reasonably clean OO I/O interfaces to Fsdb files.  Highly recommended if you use fsdb directly from perl.  In the fullness of time I expect to reimplement the entire thing using these APIs to replace the current dblib.pl which is still hobbled by its roots in perl4.

=item NEW
dbmapreduce now implements a Google-style map/reduce abstraction, generalizing dbmultistats.

=item ENHANCEMENT
fsdb now uses the Perl build system (Makefile.PL, etc.), instead of autoconf.  This change paves the way to better perl-5-style modularization, proper manual pages, input of both listize and colize format for every program, and world peace.

=item ENHANCEMENT
dblib.pl is now moved to Fsdb::Old.pm.

=item BUG FIX
dbmultistats now propagates its format argument (-f). Bug and fix from Martin Lukac (thanks!).

=item ENHANCEMENT
dbformmail documentation now is clearer that it doesn't send the mail, you have to run the shell script it writes.  (Problem observed by Unkyu Park.)

=item ENHANCEMENT
adapted to autoconf-2.61 (and then these changes were discarded in favor of The Perl Way.

=item BUG FIX
dbmultistats memory usage corrected (O(# tags), not O(1))

=item ENHANCEMENT
dbmultistats can now optionally run with pre-grouped input in O(1) memory

=item ENHANCEMENT
dbroweval -N was finally implemented (eat comments)

=back

=head2 2.0, 25-Jan-08

2.0, 25-Jan-08 --- a quiet 2.0 release (gearing up towards complete)

=over 4

=item ENHANCEMENT:
shifting old programs to Perl modules, with
the front-end program as just a wrapper.
In the short-term, this change just means programs have real man pages.
In the long-run, it will mean that one can run a pipeline in a single
Perl program.
So far: 
L<dbcol>,
L<dbroweval>,
the new L<dbrowcount>.
L<dbsort>
the new L<dbmerge>,
the old C<dbstats> (renamed L<dbcolstats>),
L<dbcolrename>,
L<dbcolcreate>,

=item NEW:
L<Fsdb::Filter::dbpipeline> is an internal-only module that lets one
use fsdb commands from within perl (via threads).

It also provides perl function aliases for the internal modules,
so a string of fsdb commands in perl are nearly as terse as in the
shell:

    use Fsdb::Filter::dbpipeline qw(:all);
    dbpipeline(
        dbrow(qw(name test1)),
        dbroweval('_test1 += 5;')
    );

=item INCOMPATIBLE CHANGE:
The old L<dbcolstats> has been renamed L<dbcolstatscores>.
The new L<dbcolstats> does the same thing as the old L<dbstats>.
This incompatibility is unfortunate but normalizes program names.

=item CHANGE:
The new L<dbcolstats> program
always outputs C<-> (the default empty value) for
statistics it cannot compute (for example, standard deviation
if there is only one row),
instead of the old mix of C<-> and "na".

=item INCOMPATIBLE CHANGE:
The old L<dbcolstats> program, now called L<dbcolstatscores>,
also has different arguments.  The C<-t mean,stddev> option is now
C<--tmean mean --tstddev stddev>.  See L<dbcolstatscores> for details.

=item INCOMPATIBLE CHANGE:
L<dbcolcreate> now assumes all new columns get the default 
value rather than requiring each column to have an initial constant value.
To change the initial value, sue the new C<-e> option.

=item NEW:
L<dbrowcount> counts rows, an almost-subset of L<dbcolstats>'s C<n> output
(except without differentiating numeric/non-numeric input),
or the equivalent of C<dbstripcomments | wc -l>.

=item NEW:
L<dbmerge> merges two sorted files.
This functionality was previously embedded in L<dbsort>.

=item INCOMPATIBLE CHANGE:
L<dbjoin>'s C<-i> option to include non-matches
is now renamed C<-a>, so as to not conflict with the new
standard option C<-i> for input file.

=back

=head2 2.1,  6-Apr-08

2.1,  6-Apr-08 --- another alpha 2.0, but now all converted programs understand both listize and colize format

=over 4

=item ENHANCEMENT:
shifting more old programs to Perl modules.
New in 2.1:
L<dbcolneaten>,
L<dbcoldefine>,
L<dbcolhisto>,
L<dblistize>,
L<dbcolize>,
L<dbrecolize>

=item ENHANCEMENT
L<dbmerge> now handles an arbitrary number of input files,
not just exactly two.

=item NEW
L<dbmerge2> is an internal routine that handles merging exactly two files.

=item INCOMPATIBLE CHANGE
L<dbjoin> now specifies inputs like L<dbmerge2>,
rather than assuming the first two arguments were tables (as in fsdb-1).

The old L<dbjoin> argument C<-i> is now C<-a> or <--type=outer>.

A minor change: comments in the source files for
L<dbjoin> are now intermixed with output
rather than being delayed until the end.

=item ENHANCEMENT
L<dbsort> now no longer produces warnings when null values are 
passed to numeric comparisons.

=item BUG FIX
L<dbroweval> now once again works with code that lacks a trailing semicolon.
(This bug fixes a regression from 1.15.)

=item INCOMPATIBLE CHANGE
L<dbcolneaten>'s old C<-e> option (to avoid end-of-line spaces) is now C<-E>
to avoid conflicts with the standard empty field argument.

=item INCOMPATIBLE CHANGE
L<dbcolhisto>'s old C<-e> option is now C<-E> to avoid conflicts.
And its C<-n>, C<-s>, and C<-w> are now
C<-N>, C<-S>, and C<-W> to correspond.

=item NEW
L<dbfilealter> replaces L<dbrecolize>, L<dblistize>, and L<dbcolize>,
but with different options.

=item ENHANCEMENT
The library routines C<Fsdb::IO> now understand both list-format
and column-format data, so all converted programs can now
I<automatically> read either format.  This capability was one
of the milestone goals for 2.0, so yea!

=back

=head2 2.2, 23-May-08

Release 2.2 is another 2.x alpha release.  Now I<most> of the
commands are ported, but a few remain, and I plan one last
incompatible change (to the file header) before 2.x final.

=over 4

=item ENHANCEMENT

shifting more old programs to Perl modules.
New in 2.2:
L<dbrowaccumulate>,
L<dbformmail>.
L<dbcolmovingstats>.
L<dbrowuniq>.
L<dbrowdiff>.
L<dbcolmerge>.
L<dbcolsplittocols>.
L<dbcolsplittorows>.
L<dbmapreduce>.
L<dbmultistats>.
L<dbrvstatdiff>.
Also
L<dbrowenumerate> 
exists only as a front-end (command-line) program.

=item INCOMPATIBLE CHANGE

The following programs have been dropped from fsdb-2.x:
L<dbcoltighten>,
L<dbfilesplit>,
L<dbstripextraheaders>,
L<dbstripleadingspace>.

=item NEW

L<combined_log_format_to_db> to convert Apache logfiles

=item INCOMPATIBLE CHANGE

Options to L<dbrowdiff> are now B<-B> and B<-I>,
not B<-a> and B<-i>.

=item INCOMPATIBLE CHANGE

L<dbstripcomments> is now L<dbfilestripcomments>.

=item BUG FIXES

L<dbcolneaten> better handles empty columns;
L<dbcolhisto> warning suppressed (actually a bug in high-bucket handling).

=item INCOMPATIBLE CHANGE

L<dbmultistats> now requires a C<-k> option in front of the 
key (tag) field, or if none is given, it will group by the first field
(both like L<dbmapreduce>).

=item KNOWN BUG

L<dbmultistats> with quantile option doesn't work currently.

=item INCOMPATIBLE CHANGE

L<dbcoldiff> is renamed L<dbrvstatdiff>.

=item BUG FIXES

L<dbformmail> was leaving its log message as a  command, not a comment.
Oops.  No longer.

=back

=head2 2.3, 27-May-08 (alpha)

Another alpha release, this one just to fix the critical dbjoin bug
listed below (that happens to have blocked my MP3 jukebox :-).

=over 4

=item BUG FIX

Dbsort no longer hangs if given an input file with no rows.

=item BUG FIX

Dbjoin now works with unsorted input coming from a pipeline (like stdin).
Perl-5.8.8 has a bug (?) that was making this case fail---opening
stdin in one thread, reading some, then reading more in a different
thread caused an lseek which works on files, but fails on pipes like stdin.
Go figure.

=item BUG FIX / KNOWN BUG

The dbjoin fix also fixed dbmultistats -q
(it now gives the right answer).
Although a new bug appeared, messages like:
    Attempt to free unreferenced scalar: SV 0xa9dd0c4, Perl interpreter: 0xa8350b8 during global destruction.
So the dbmultistats_quartile test is still disabled.

=back

=head2 2.4, 18-Jun-08

Another alpha release, mostly to fix minor usability
problems in dbmapreduce and client functions.

=over 4

=item ENHANCEMENT

L<dbrow> now defaults to running user supplied code without warnings
(as with fsdb-1.x).
Use C<--warnings> or C<-w> to turn them back on.

=item ENHANCEMENT

L<dbroweval> can now write different format output
than the input, using the C<-m> option.

=item KNOWN BUG

L<dbmapreduce> emits warnings on perl 5.10.0
about "Unbalanced string table refcount" and "Scalars leaked"
when run with an external program as a reducer.

L<dbmultistats> emits the warning "Attempt to free unreferenced scalar"
when run with quartiles.

In each case the output is correct.
I believe these can be ignored.

=item CHANGE

L<dbmapreduce> no longer logs a line for each reducer that is invoked.

=back


=head2 2.5, 24-Jun-08

Another alpha release, fixing more minor bugs in 
C<dbmapreduce> and lossage in C<Fsdb::IO>.

=over 4

=item ENHANCEMENT

L<dbmapreduce> can now tolerate non-map-aware reducers
that pass back the key column in put.
It also passes the current key as the last argument to 
external reducers.

=item BUG FIX

L<Fsdb::IO::Reader>, correctly handle C<-header> option again.
(Broken since fsdb-2.3.)

=back


=head2 2.6, 11-Jul-08

Another alpha release, needed to fix DaGronk.
One new port, small bug fixes, and important fix to L<dbmapreduce>.

=over 4

=item ENHANCEMENT

shifting more old programs to Perl modules.
New in 2.2:
L<dbcolpercentile>.

=item INCOMPATIBLE CHANGE and ENHANCEMENTS
L<dbcolpercentile> arguments changed,
use C<--rank> to require ranking instead of C<-r>.
Also, C<--ascending> and C<--descending> can now be specified separately,
both for C<--percentile> and C<--rank>.

=item BUG FIX

Sigh, the sense of the --warnings option in L<dbrow> was inverted.  No longer.

=item BUG FIX

I found and fixed the string leaks (errors like "Unbalanced string
table refcount" and "Scalars leaked") in L<dbmapreduce> and L<dbmultistats>.
(All C<IO::Handle>s in threads must be manually destroyed.)

=item BUG FIX

The C<-C> option to specify the column separator in L<dbcolsplittorows> 
now works again (broken since it was ported).

=back

2.7, 30-Jul-08 beta

The beta release of fsdb-2.x.  Finally, all programs are ported.
As statistics, the number of lines of non-library code doubled from
7.5k to 15.5k.  The libraries are much more complete,
going from 866 to 5164 lines.
The overall number of programs is about the same, 
although 19 were dropped and 11 were added.  
The number of test cases has grown from 116 to 175.
All programs are now in perl-5, no more shell scripts or perl-4.
All programs now have manual pages.

Although this is a major step forward, I still expect
to rename "fsdb" to "fsdb".

=over 4

=item ENHANCEMENT

shifting more old programs to Perl modules.
New in 2.7:
L<dbcolscorellate>.
L<dbcolsregression>.
L<cgi_to_db>.
L<dbfilevalidate>.
L<db_to_csv>.
L<csv_to_db>,
L<db_to_html_table>,
L<kitrace_to_db>,
L<tcpdump_to_db>,
L<tabdelim_to_db>,
L<ns_to_db>.

=item INCOMPATIBLE CHANGE

The following programs have been dropped from fsdb-2.x:
L<db2dcliff>,
L<dbcolmultiscale>,
L<crl_to_db>.
L<ipchain_logs_to_db>.
They may come back, but seemed overly specialized.
The following program 
L<dbrowsplituniq>
was dropped because it is superseded by L<dbmapreduce>.
L<dmalloc_to_db>
was dropped pending a test cases and examples.

=item ENHANCEMENT

L<dbfilevalidate> now has a C<-c> option to correct errors.

=item NEW

L<html_table_to_db> provides the inverse of
L<db_to_html_table>.

=back


=head2 2.8,  5-Aug-08

Change header format, preserving forwards compatibility.

=over 4

=item BUG FIX

Complete editing pass over the manual, making sure it aligns 
with fsdb-2.x.

=item SEMI-COMPATIBLE CHANGE

The header of fsdb files has changed, it is now #fsdb, not #h (or #L)
and parsing of -F and -R are also different.
See L<dbfilealter> for the new specification.
The v1 file format will be read, compatibly, but
not written.

=item BUG FIX

L<dbmapreduce> now tolerates comments that precede the first key,
instead of failing with an error message.

=back


=head2 2.9, 6-Aug-08

Still in beta; just a quick bug-fix for L<dbmapreduce>.

=over 4

=item ENHANCEMENT

L<dbmapreduce> now generates plausible output when given no rows
of input.

=back

=head2 2.10, 23-Sep-08

Still in beta, but picking up some bug fixes.

=over 4

=item ENHANCEMENT

L<dbmapreduce> now generates plausible output when given no rows
of input.

=item ENHANCEMENT

L<dbroweval> the warnings option was backwards;
now corrected.  As a result, warnings in user code now default off
(like in fsdb-1.x).

=item BUG FIX

L<dbcolpercentile> now defaults to assuming the target column is numeric.
The new option C<-N> allows selection of a non-numeric target.

=item BUG FIX

L<dbcolscorrelate> now includes C<--sample> and C<--nosample> options
to compute the sample or full population correlation coefficients.
Thanks to Xue Cai for finding this bug.

=back


=head2 2.11, 14-Oct-08

Still in beta, but picking up some bug fixes.

=over 4

=item ENHANCEMENT

L<html_table_to_db> is now more aggressive about filling in empty cells
with the official empty value, rather than leaving them blank or as whitespace.

=item ENHANCEMENT

L<dbpipeline> now catches failures during pipeline element setup
and exits reasonably gracefully.

=item BUG FIX

L<dbsubprocess> now reaps child processes, thus avoiding
running out of processes when used a lot.

=back

=head2 2.12, 16-Oct-08

Finally, a full (non-beta) 2.x release!

=over 4

=item INCOMPATIBLE CHANGE

Jdb has been renamed Fsdb, the flatfile-streaming database.
This change affects all internal Perl APIs,
but no shell command-level APIs.
While Jdb served well for more than ten years,
it is easily confused with the Java debugger (even though Jdb was there first!).
It also is too generic to work well in web search engines.
Finally, Jdb stands for ``John's database'', and we're a bit beyond that.
(However, some call me the ``file-system guy'', so 
one could argue it retains that meeting.)

If you just used the shell commands, this change should not affect you.
If you used the Perl-level libraries directly in your code,
you should be able to rename "Jdb" to "Fsdb" to move to 2.12.

The jdb-announce list not yet been renamed, but it will be shortly.

With this release I've accomplished everything I wanted to
in fsdb-2.x.  I therefore expect to return to boring, bugfix releases.

=back

=head2 2.13, 30-Oct-08

=over 4

=item BUG FIX

L<dbrowaccumulate> now treats non-numeric data as zero by default.

=item BUG FIX

Fixed a perl-5.10ism in L<dbmapreduce> that
breaks that program under 5.8. 
Thanks to Martin Lukac for reporting the bug.

=back

=head2 2.14, 26-Nov-08

=over 4

=item BUG FIX

Improved documentation for L<dbmapreduce>'s C<-f> option.

=item ENHANCEMENT

L<dbcolmovingstats> how computes a moving standard deviation in addition
to a moving mean.

=back


=head2 2.15, 13-Apr-09

=over 4

=item BUG FIX

Fix a F<make install> bug reported by Shalindra Fernando.

=back


=head2 2.16, 14-Apr-09

=over 4

=item BUG FIX

Another minor release bug: on some systems F<programize_module> looses
executable permissions.  Again reported by Shalindra Fernando.

=back

=head2 2.17, 25-Jun-09

=over 4

=item TYPO FIXES

Typo in the F<dbroweval> manual fixed.

=item IMPROVEMENT

There is no longer a comment line to label columns
in F<dbcolneaten>, instead the header line is tweaked to
line up.  This change restores the Jdb-1.x behavior, and
means that repeated runs of dbcolneaten no longer add comment lines
each time.

=item BUG FIX

It turns out  F<dbcolneaten> was not correctly handling trailing spaces
when given the C<-E> option to suppress them.  This regression is now
fixed.

=item EXTENSION

L<dbroweval(1)> can now handle direct references to the last row
via F<$lfref>, a dubious but now documented feature.

=item BUG FIXES

Separators set with C<-C> in F<dbcolmerge> and F<dbcolsplittocols>
were not properly
setting the heading, and null fields were not recognized.
The first bug was reported by Martin Lukac.

=back

=head2 2.18,  1-Jul-09  A minor release

=over 4

=item IMPROVEMENT

Documentation for F<Fsdb::IO::Reader> has been improved.

=item IMPROVEMENT

The package should now be PGP-signed.

=back


=head2 2.19,  10-Jul-09

=over 4

=item BUG FIX

Internal improvements to debugging output and robustness of
F<dbmapreduce> and F<dbpipeline>. 
F<TEST/dbpipeline_first_fails.cmd> re-enabled.

=back


=head2 2.20, 30-Nov-09
(A collection of minor bugfixes, plus a build against Fedora 12.)

=over 4

=item BUG FIX

Loging for 
F<dbmapreduce>
with code refs is now stable
(it no longer includes a hex pointer to the code reference).

=item BUG FIX

Better handling of mixed blank lines in F<Fsdb::IO::Reader>
(see test case F<dbcolize_blank_lines.cmd>).

=item BUG FIX

F<html_table_to_db> now handles multi-line input better,
and handles tables with COLSPAN.

=item BUG FIX

F<dbpipeline> now cleans up threads in an C<eval>
to prevent "cannot detach a joined thread" errors that popped
up in perl-5.10.  Hopefully this prevents a race condition
that causes the test suites to hang about 20% of the time
(in F<dbpipeline_first_fails>).

=item IMPROVEMENT

F<dbmapreduce> now detects and correctly fails
when the input and reducer have incompatible 
field separators.

=item IMPROVEMENT

F<dbcolstats>, F<dbcolhisto>, F<dbcolscorrelate>, F<dbcolsregression>,
and F<dbrowcount>
now all take an C<-F> option to let one specify the output field separator
(so they work better with F<dbmapreduce>).

=item BUG FIX

An omitted C<-k> from the manual page of F<dbmultistats>
is now there.  Bug reported by Unkyu Park.

=back


=head2 2.21, 17-Apr-10
bug fix release

=over 4

=item BUG FIX

F<Fsdb::IO::Writer> now no longer fails with -outputheader => never
(an obscure bug).

=item IMPROVEMENT

F<Fsdb> (in the warnings section)
and F<dbcolstats> now more carefully document how they
handle (and do not handle) numerical precision problems,
and other general limits.  Thanks to Yuri Pradkin for prompting
this documentation.

=item IMPROVEMENT

C<Fsdb::Support::fullname_to_sortkey>
is now restored from C<Jdb>.

=item IMPROVEMENT

Documention for multiple styles of input approaches
(including performance description) added to L<Fsdb::IO>.

=back

=head2 2.22, 2010-10-31
One new tool F<dbcolcopylast> and several bug fixes for Perl 5.10.

=over 4

=item BUG FIX

F<dbmerge> now correctly handles n-way merges.
Bug reported by Yuri Pradkin.

=item INCOMPARABLE CHANGE

F<dbcolneaten> now defaults to I<not> padding the last column.

=item ADDITION

F<dbrowenumerate> now takes B<-N NewColumn> to give the new
column a name other than "count".  Feature requested by Mike Rouch
in January 2005.

=item ADDITION

New program F<dbcolcopylast> copies the last value of a column
into a new column copylast_column of the next row.
New program requested by Fabio Silva;
useful for converting dbmultistats output into dbrvstatdiff input.

=item BUG FIX

Several tools (particularly F<dbmapreduce> and F<dbmultistats>) would
report errors like "Unbalanced string table refcount: (1) for "STDOUT"
during global destruction" on exit, at least on certain versions
of Perl (for me on 5.10.1), but similar errors have been off-and-on
for several Perl releases.  Although I think my code looked
OK, I worked around this problem with a different way of handling
standard IO redirection.

=back


=head2 2.23, 2011-03-10
Several small portability bugfixes; improved F<dbcolstats> for large datasets

=over 4

=item IMPROVEMENT

Documentation to F<dbrvstatdiff> was changed to use "sd" to refer to
standard deviation, not "ss" (which might be confused with sum-of-squares).

=item BUG FIX

This documentation about F<dbmultistats> was missing the F<-k> option
in some cases.

=item BUG FIX

F<dbmapreduce> was failing on MacOS-10.6.3 for some tests with
the error

    dbmapreduce: cannot run external dbmapreduce reduce program (perl TEST/dbmapreduce_external_with_key.pl)

The problem seemed to be only in the error, not in operation.
On MacOS, the error is now suppressed.
Thanks to Alefiya Hussain for providing access to a Mac system
that allowed debugging of this problem.

=item IMPROVEMENT

The F<csv_to_db> command requires an external
Perl library (F<Text::CSV_XS>).  On computers that
lack this optional library, previously Fsdb would configure
with a warning and then test cases would fail.
Now those test cases are skipped with an additional warning.

=item BUG FIX

The test suite now supports alternative valid output, as a hack
to account for last-digit floating point differences.
(Not very satisfying :-(

=item BUG FIX

F<dbcolstats> output for confidence intervals on very large
datasets has changed.  Previously it failed for more than 2^31-1
records, and handling of T-Distributions with thousands of rows
was a bit dubious.  Now datasets with more than 10000 are considered
infinitely large and hopefully correctly handled.

=back

=head2 2.24, 2011-04-15
Improvements to fix an old bug in dbmapreduce with different field separators

=over 4

=item IMPROVEMENT

The F<dbfilealter> command had a C<--correct> option to
work-around from incompatible field-separators,
but it did nothing.  Now it does the correct but sad, data-loosing
thing.

=item IMPROVEMENT

The F<dbmultistats> command
previously failed with an error message when invoked
on input with a non-default field separator.
The root cause was the underlying F<dbmapreduce>
that did not handle the case of reducers that generated
output with a different field separator than the input.
We now detect and repair incompatible field separators.
This change corrects a problem originally documented and detected
in Fsdb-2.20.
Bug re-reported by Unkyu Park.

=back

=head2 2.25, 2011-08-07
Two new tools, F<xml_to_db> and F<dbfilepivot>, and a bugfix for two people.

=over 4

=item IMPROVEMENT

F<kitrace_to_db> now supports a F<--utc> option, 
which also fixes this test case for users outside of the Pacific
time zone.  Bug reported by David Graff, and also by Peter Desnoyers
(within a week of each other :-)

=item NEW

F<xml_to_db> can convert simple, very regular XML files into Fsdb.

=item NEW

F<dbfilepivot> "pivots" a file, converting multiple rows
corresponding to the same entity into a single row with multiple columns.

=back

=head2 2.26, 2011-12-12
Bug fixes, particularly for perl-5.14.2.

=over 4

=item BUG FIX

Bugs fixed in L<Fsdb::IO::Reader(3)> manual page.

=item BUG FIX

Fixed problems where L<dbcolstats> was truncating floating point numbers
when sorting.  This strange behavior happens as of perl-5.14.2 and
it I<seems> like a Perl bug.  I've worked around it for the test suites,
but I'm a bit nervous.

=back

=head2 2.27, 2012-11-15
Accumulated bug fixes.

=over 4

=item IMPROVEMENT

F<csv_to_db> now reports errors in CVS input with real diagnostics.

=item IMPROVEMENT

F<dbcolmovingstats> can now compute median, when given the C<-m> option.

=item BUG FIX

F<dbcolmovingstats> non-numeric handling (the C<-a> option) now works properly.

=item DOCUMENTATION

The internal
F<t/test_command.t> test framework
is now documented.

=item BUG FIX

F<dbrowuniq> now correctly handles the case where there is no input
(previously it output a blank line, which is a malformed fsdb file).
Thanks to Yuri Pradkin for reporting this bug.

=back

=head2 2.28, 2012-11-15
A quick release to fix most rpmlint errors.

=over 4

=item BUG FIX

Fixed a number of minor release problems (wrong permissions, old FSF
address, etc.) found by rpmlint.

=back

=head2 2.29, 2012-11-20
a quick release for CPAN testing

=over 4

=item IMPROVEMENT

Tweaked the RPM spec.

=item IMPROVEMENT

Modified F<Makefile.PL> to fail gracefully on Perl installations
that lack threads.  (Without this fix, I get massive failures
in the non-ithreads test system.)

=back

=head2 2.30, 2012-11-25
improvements to perl portability

=over 4

=item BUG FIX

Removed unicode character in documention of F<dbcolscorrelated>
so pod tests will pass.  (Sigh, that should work :-( )

=item BUG FIX

Fixed test suite failures on 5 tests (F<dbcolcreate_double_creation>
was the first) due to L<Carp>'s addition of a period.
This problem was breaking Fsdb on perl-5.17.
Thanks to Michael McQuaid for helping diagnose this problem.

=item IMPROVEMENT

The test suite now prints out the names of tests it tries.

=back

=head2 2.31, 2012-11-28
A release with actual improvements to dbfilepivot and dbrowuniq.

=over 4

=item BUG FIX

Documentation fixes: typos in L<dbcolscorrelated>,
bugs in L<dbfilepivot>,
clarification for comment handling in L<Fsdb::IO::Reader>.

=item IMPROVEMENT

Previously L<dbfilepivot> assumed the input was grouped by keys
and didn't very that pre-condition.
Now there is no pre-condition (it will sort the input by default),
and it checks if the invariant is violated.

=item BUG FIX

Previously L<dbfilepivot> failed if the input had comments (oops :-);
no longer.

=item IMPROVEMENT

Now L<dbrowuniq> has the C<-L> option to preserve the last
unique row (instead of the first), a common idiom.

=back

=head2 2.32, 2012-12-21
Test suites should now be more numerically robust.

=over 4

=item NEW

New L<dbfilediff> does fsdb-aware file differencing.
It does not do smart intuition of add/removes like Unix diff(1),
but it does know about columns, and with C<-E>, it does
numeric-aware differences.

=item IMPROVEMENT

Test suites that are numeric now use L<dbfilediff> to do numeric-aware
comparisons, so the test suite should now be robust to slightly different
computers and operating systems and compilers than I<exactly> what I use.

=back

=head2 2.33, 2012-12-23
Minor fixes to some test cases.

=over 4

=item IMPROVEMENT

L<dbfilediff> and L<dbrowuniq>
now supports the C<-N> option to give the new column a 
different name.  (And a test cases where this duplication mattered
have been fixed.)

=item IMPROVEMENT

L<dbrvstatdiff> now show the t-test breakpoint with a reasonable number of
floating point digits.

=item BUG FIX

Fixed a numerical stability problem in the F<dbroweval_last> test case.

=back

=head1 WHAT'S NEW

=head2 2.34, 2013-02-10
Parallelism in L<dbmerge>.

=over 4

=item IMPROVEMENT

Documention for L<dbjoin> now includes resource requirements.

=item IMPROVEMENT

Default memory usage for L<dbsort> is now about 256MB.
(The world keeps moving forward.)

=item IMPROVEMENT

L<dbmerge> now does merging in parallel.
As a side-effect, L<dbsort> should be faster when
input overflows memory.  The level of parallelism
can be limited with the C<--parallelism> option.
(There is more work to do here, but we're off to a start.)

=back

=head2 2.35, 2013-02-23
Improvements to dbmerge parallelism

=over 4

=item BUG FIX

Fsdb temporary files are now created more securely (with File::Temp).

=item IMPROVEMENT

Programs that sort or merge on fields (L<dbmerge2>, L<dbmerge>, L<dbsort>, 
L<dbjoin>) now report an error if no fields on which to join or merge
are given.

=item IMPROVEMENT

Parallelism in L<dbmerge> is should now be more consistent,
with less starting and stopping.

=item IMPROVEMENT
In L<dbmerge>, the C<--xargs> option lets one give input filenames on
standard input, rather than the command line.
This feature paves the way for faster dbsort for large inputs
(by pipelining sorting and merging), expected in the next release.

=back


=head2 2.36, 2013-02-25
dbsort pipelines with dbmerge

=over 4

=item IMPROVEMENT
For large inputs,
L<dbsort> now pipelines sorting and merging,
allowing earlier processing.

=item BUG FIX
Since 2.35, L<dbmerge> delayed cleanup of intermediate files,
thereby requiring extra disk space.

=back

=head2 2.37, 2013-02-26
quick bugfix to support parallel sort and merge from recent releases

=over 4

=item BUG FIX
Since 2.35, L<dbmerge> delayed removal of input files given by 
C<--xargs>.  This problem is now fixed.

=back


=head2 2.38, 2013-04-29
minor bug fixes

=over 4

=item CLARIFICATION

Configure now rejects Windows since tests seem to hang
on some versions of Windows.
(I would love help from a Windows developer to get this problem fixed,
but I cannot do it.)  See F<https://rt.cpan.org/Ticket/Display.html?id=84201>.

=item IMPROVEMENT

All programs that use temporary files 
(L<dbcolpercentile>, L<dbcolscorrelate>, L<dbcolstats>, L<dbcolstatscores>)
now take the C<-T> option
and set the temporary directory consistently.

In addition, error messages are better when the temporary directory 
has problems.  Problem reported by Liang Zhu.

=item BUG FIX

L<dbmapreduce> was failing with external, map-reduce aware reducers
(when invoked with -M and an external program).
(Sigh, did this case ever work?)
This case should now work.
Thanks to Yuri Pradkin for reporting this bug (in 2011).

=item BUG FIX

Fixed perl-5.10 problem with L<dbmerge>.
Thanks to Yuri Pradkin for reporting this bug (in 2013).

=back

=head2 2.39, date 2013-05-31
quick release for the dbrowuniq extension

=over 4

=item BUG FIX

Actually in 2.38, the Fedora F<.spec> got cleaner dependencies.
Suggestion from Christopher Meng via L<https://bugzilla.redhat.com/show_bug.cgi?id=877096>.

=item ENHANCEMENT

Fsdb files are now explicitly set into UTF-8 encoding,
unless one specifies C<-encoding> to C<Fsdb::IO>.

=item ENHANCEMENT

L<dbrowuniq> now supports C<-I> for incremental counting.

=back

=head2 2.40, 2013-07-13
small bug fixes

=over 4

=item BUG FIX

L<dbsort> now has more respect for a user-given temporary directory;
it no longer is ignored for merging.

=item IMPROVEMENT

L<dbrowuniq> now has options to output the first, last, and both first
and last rows of a run (C<-F>, C<-L>, and C<-B>).

=item BUG FIX

L<dbrowuniq> now correctly handles C<-N>.  Sigh, it didn't work before.

=back

=head2 2.41, 2013-07-29
small bug and packaging fixes

=over 4

=item ENHANCEMENT

Documentation to L<dbrvstatdiff> improved
(inspired by questions from Qian Kun).

=item BUG FIX

L<dbrowuniq> no longer duplicates
singleton unique lines when outputting both (with C<-B>).

=item BUG FIX

Add missing C<XML::Simple> dependency to F<Makefile.PL>.

=item ENHANCEMENT

Tests now show the diff of the failing output
if run with C<make test TEST_VERBOSE=1>.

=item ENHANCEMENT

L<dbroweval> now includes documentation for how to output extra rows.
Suggestion from Yuri Pradkin.

=item BUG FIX

Several improvements to the Fedora package
from Michael Schwendt
via L<https://bugzilla.redhat.com/show_bug.cgi?id=877096>,
and from the harsh master that is F<rpmlint>.
(I am stymied at teaching it that "outliers" is spelled correctly.
Maybe I should send it Schneier's book.  And an unresolvable
invalid-spec-name lurks in the SRPM.)

=back

=head2 2.42, 2013-07-31
A bug fix and packaging release.

=over 4

=item ENHANCEMENT

Documentation to L<dbjoin> improved
to better memory usage.
(Based on problem report by Lin Quan.)

=item BUG FIX

The F<.spec> is now F<perl-Fsdb.spec>
to satisfy F<rpmlint>.
Thanks to Christopher Meng for a specific bug report.

=item BUG FIX

Test F<dbroweval_last.cmd> no longer has a column
that caused failures because of numerical instability.

=item BUG FIX

Some tests now better handle bugs in old versions of perl (5.10, 5.12).
Thanks to Calvin Ardi for help debugging this on a Mac with perl-5.12,
but the fix should affect other platforms.

=back

=head2 2.43, 2013-08-27
Adds in-file compression.

=over 4

=item BUG FIX

Changed the sort on F<TEST/dbsort_merge.cmd> to strings
(from numerics) so we're less susceptible to false test-failures
due to floating point IO differences.

=item EXPERIMENTAL ENHANCEMENT

Yet more parallelism in L<dbmerge>:
new "endgame-mode" builds a merge tree of processes at the end
of large merge tasks to get maximally parallelism.
Currently this feature is off by default
because it can hang for some inputs.
Enable this experimental feature with C<--endgame>.

=item ENHANCEMENT

C<Fsdb::IO> now handles being given C<IO::Pipe> objects
(as exercised by L<dbmerge>).

=item BUG FIX

Handling of NamedTmpfiles now supports concurrency.
This fix will hopefully fix occasional
"Use of uninitialized value $_ in string ne at ...NamedTmpfile.pm line 93."
errors.

=item BUG FIX

Fsdb now requires perl 5.10.
This is a bug fix because some test cases used to require it,
but this fact was not properly documented.
(Back-porting to 5.008 would require removing all C<//> operators.)

=item ENHANCEMENT

Fsdb now handles automatic compression of file contents.
Enable compression with C<dbfilealter -Z xz>
(or C<gz> or C<bz2>).
All programs should operate on compressed files
and leave the output with the same level of compression.
C<xz> is recommended as fastest and most efficient.
C<gz> is produces unrepeatable output (and so has no
output test), it seems to insist on adding a timestamp.

=back

=head2 2.44, 2013-10-02
A major change--all threads are gone.

=over 4

=item ENHANCEMENT

Fsdb is now thread free and only uses processes for parallelism.
This change is a big change--the entire motivation for Fsdb-2
was to exploit parallelism via threading.
Parallelism--good, but perl threading--bad for performance.
Horribly bad for performance.
About 20x worse than pipes on my box.
(See perl bug #119445 for the discussion.)

=item NEW

C<Fsdb::Support::Freds> provides a thread-like abstraction over forking,
with some nice support for callbacks in the parent upon child termination.

=item ENHANCEMENT

Details about removing threads:
C<dbpipeline> is thread free,
and new tests to verify each of its parts.
The easy cases are C<dbcolpercentile>, 
C<dbcolstats>, C<dbfilepivot>, C<dbjoin>, and
C<dbcolstatscores>, each of which use it in simple ways (2013-09-09).
C<dbmerge> is now thread free (2013-09-13),
but was a significant rewrite,
which brought C<dbsort> along.
C<dbmapreduce> is partly thread free (2013-09-21),
again as a rewrite,
and it brings C<dbmultistats> along.
Full C<dbmapreduce> support took much longer (2013-10-02).

=item BUG FIX

When running with user-only output (C<-n>),
L<dbroweval> now resets the output vector C<$ofref> 
after it has been output.

=item NEW

L<dbcolcreate> will create all columns at the head of each row
with the C<--first> option.

=item NEW

L<dbfilecat> will concatenate two files,
verifying that they have the same schema.

=item ENHANCEMENT

L<dbmapreduce> now passes comments through, 
rather than eating them as before.

Also, L<dbmapreduce> now supports a C<--> option to prevent misinterpreting
sub-program parameters as for dbmapreduce.

=item INCOMPATIBLE CHANGE

L<dbmapreduce> no longer figures out if it needs to add the key
to the output.  For multi-key-aware reducers, it never does
(and cannot).  For non-multi-key-aware reducers,
it defaults to add the key and will now fail if the reducer adds the key
(with error "dbcolcreate: attempt to create pre-existing column...").
In such cases, one must disable adding the key with the new
option C<--no-prepend-key>.

=item INCOMPATIBLE CHANGE

L<dbmapreduce> no longer copies the input field separator by default.
For multi-key-aware reducers, it never does
(and cannot).  For non-multi-key-aware reducers,
it defaults to I<not> copying the field separator,
but it will copy it (the old default) with the C<--copy-fs> option

=back

=head2 2.45, 2013-10-07
cleanup from de-thread-ification

=over 4

=item BUG FIX

Corrected a fast busy-wait in L<dbmerge>.

=item ENHANCEMENT

Endgame mode enabled in L<dbmerge>; it (and also large cases of L<dbsort>)
should now exploit greater parallelism.

=item BUG FIX

Test case with C<Fsdb::BoundedQueue> (gone since 2.44) now removed.

=back

=head2 2.46, 2013-10-08
continuing cleanup of our no-threads version

=over 4

=item BUG FIX

Fixed some packaging details.
(Really, threads are no longer required,
missing tests in the MANIFEST.)

=item IMPROVEMENT

L<dbsort> now better communicates with the merge process to avoid
bursty parallelism.

L<Fsdb::IO::Writer> now can take C<-autoflush => 1>
for line-buffered IO.

=back

=head2 2.47, 2013-10-12
test suite cleanup for non-threaded perls

=over 4

=item BUG FIX

Removed some stray "use threads" in some test cases.
We didn't need them, and these were breaking non-threaded perls.

=item BUG FIX

Better handling of Fred cleanup;
should fix intermittent L<dbmapreduce> failures on BSD.

=item ENHANCEMENT

Improved test framework to show output when tests fail.
(This time, for real.)

=back

=head2 2.48, 2014-01-03
small bugfixes and improved release engineering

=over 4

=item ENHANCEMENT

Test suites now skip tests for libraries that are missing.
(Patch for missing C<IO::Compresss:Xz> contributed by Calvin Ardi.)

=item ENHANCEMENT

Removed references to Jdb in the package specification.
Since the name was changed in 2008, there's no longer a huge
need for backwards comparability.
(Suggestion form Petr Šabata.)

=item ENHANCEMENT

Test suites now invoke the perl using the path from C<$Config{perlpath}>.
Hopefully this helps testing in environments where there are multiple installed
perls and the default perl is not the same as the perl-under-test
(as happens in cpantesters.org).

=item BUG FIX

Added specific encoding to this manpage to account for 
Unicode.  Required to build correctly against perl-5.18.

=back

=head2 2.49, 2014-01-04
bugfix to unicode handling in Fsdb IO (plus minor packaging fixes)

=over 4

=item BUG FIX

Restored a line in the F<.spec> to chmod g-s.

=item BUG FIX

Unicode decoding is now handled correctly for programs that read 
from standard input.
(Also: New test scripts cover unicode input and output.)

=item BUG FIX

Fix to L<Fsdb> documentation encoding line.
Addresses test failure in perl-5.16 and earlier.
(Who knew "encoding" had to be followed by a blank line.)

=back

=head1 WHAT'S NEW

=head2 2.50, 2014-05-27
a quick release for spec tweaks

=over 4

=item ENHANCEMENT

In L<dbroweval>, the C<-N> (no output, even comments) option now
implies C<-n>, and it now suppresses the header and trailer.

=item BUG FIX

A few more tweaks to the F<perl-Fsdb.spec> from Petr Šabata.

=item BUG FIX

Fixed 3 uses of C<use v5.10> in test suites that were causing test
failures (due to warnings, not real failures) on some platforms.

=back

=head2 2.51, 2014-09-05
Feature enhancements to L<dbcolmovingstats>, L<dbcolcreate>, L<dbmapreduce>, and new L<sqlselect_to_db>

=over 4

=item ENHANCEMENT

L<dbcolcreate> now has a C<--no-recreate-fatal>
that causes it to ignore creation of existing columns
(instead of failing).

=item ENHANCEMENT

L<dbmapreduce> once again is robust to reducers
that output the key;
C<--no-prepend-key> is no longer mandatory.

=item ENHANCEMENT

L<dbcolsplittorows> can now enumerate the output rows with C<-E>.

=item BUG FIX

L<dbcolmovingstats> is more mathematically robust.
Previously for some inputs and some platforms,
floating point rounding could 
sometimes cause squareroots of negative numbers.

=item NEW

L<sqlselect_to_db> converts the output of the MySQL or MarinaDB
select comment into fsdb format.

=item INCOMPATIBLE CHANGE

L<dbfilediff> now outputs the I<second> row
when doing sloppy numeric comparisons,
to better support test suites.

=back

=head2 2.52, 2014-11-03
Fixing the test suite for line number changes.

=over 4

=item ENHANCEMENT

Test suites changes to be robust to exact line numbers of failures,
since different Perl releases fail on different lines.
L<https://bugzilla.redhat.com/show_bug.cgi?id=1158380>

=back


=head2 2.53, 2014-11-26
bug fixes and stability improvements to dbmapreduce

=over 4

=item ENHANCEMENT

The L<dbfilediff> how supports a C<--quiet> option.

=item ENHANCEMENT

Better documention of L<dbpipeline_filter>.

=item BUGFIX

Added groff-base and perl-podlators to the Fedora package spec.
Fixes L<https://bugzilla.redhat.com/show_bug.cgi?id=1163149>.
(Also in package 2.52-2.)

=item BUGFIX

An important stability improvement to L<dbmapreduce>.
It, plus L<dbmultistats>, and L<dbcolstats> now support
controlled parallelism with the C<--pararallelism=N> option.
They default to run with the number of available CPUs.
L<dbmapreduce> also moderates its level of parallelism.
Previously it would create reducers as needed,
causing CPU thrashing if reducers ran much slower than data production.

=item BUGFIX

The combination of L<dbmapreduce> with L<dbrowenumerate> now works
as it should.  (The obscure bug was an interaction with L<dbcolcreate>
with non-multi-key reducers that output their own key.  L<dbmapreduce>
has too many useful corner cases.)

=back

=head2 2.54, 2014-11-28
fix for the test suite to correct failing tests on not-my-platform

=over 4

=item BUGFIX

Sigh, the test suite now has a test suite.
Because, yes, I broke it, causing many incorrect failures
at cpantesters.
Now fixed.

=back

=head2 2.55, 2015-01-05
many spelling fixes and L<dbcolmovingstats> tests are more robust to different numeric precision

=over 4

=item ENHANCEMENT

L<dbfilediff> now can be extra quiet, as I continue to try to track down 
a numeric difference on FreeBSD AMD boxes.

=item ENHANCEMENT

L<dbcolmovingstats> gave different test output
(just reflecting rounding error)
when stddev approaches zero.  We now detect hand handle this case.
See <https://rt.cpan.org/Public/Bug/Display.html?id=101220>
and thanks to H. Merijn Brand for the bug report.

=item BUG FIX

Many, many spelling bugs found by 
H. Merijn Brand; thanks for the bug report.

=item INCOMPATBLE CHANGE

A number of programs had misspelled "separator" 
in C<--fieldseparator> and C<--columnseparator> options as "seperator".
These are now correctly spelled.

=back

=head2 2.56, 2015-02-03
fix against Getopt::Long-2.43's stricter error checkign

=over 4

=item BUG FIX

Internal argument parsing uses Getopt::Long, but mixed pass-through and E<lt>E<gt>.
Bug reported by Petr Pisar at L<https://bugzilla.redhat.com/show_bug.cgi?id=1188538>.a

=item BUG FIX

Added missing BuildRequires for C<XML::Simple>.

=back

=head2 2.57, 2015-04-29
Minor changes, with better performance from L<dbmulitstats>.

=over 4

=item BUG FIX

L<dbfilecat> now honors C<--remove-inputs> (previously it didn't).
This omission meant that L<dbmapreduce> (and L<dbmultistats>) would accumulate
files in F</tmp> when running.  Bad news for inputs with 4M keys.

=item ENHANCMENT

L<dbmultistats> should be faster with lots of small keys.
L<dbcolstats> now supports C<-k> to get some of the functionality of
L<dbmultistats> (if data is pre-sorted and median/quartiles are not required).

L<dbfilecat> now honors C<--remove-inputs> (previously it didn't).
This omission meant that L<dbmapreduce> (and L<dbmultistats>) would accumulate
files in F</tmp> when running.  Bad news for inputs with 4M keys.

=back


=head2 2.58, 2015-04-30
Bugfix in L<dbmerge>

=over 4

=item BUG FIX

Fixed a case where L<dbmerge> suffered mojobake in endgame mode.
This bug surfaced when L<dbsort> was applied to large files
(big enough to require merging) with unicode in them;
the symptom was soemthing like:
  Wide character in print at /usr/lib64/perl5/IO/Handle.pm line 420, <GEN12> line 111.

=back


=head2 2.59, 2016-09-01
Collect a few small bug fixes and documentation improvements.

=over 4

=item BUG FIX

More IO is explicitly marked UTF-8 to avoid Perl's tendency to
mojibake on otherwise valid unicode input.
This change helps L<html_table_to_db>.

=item ENHANCEMENT

L<dbcolscorrelate> now crossreferences L<dbcolsregression>.

=item ENHANCEMENT

Documentation for L<dbrowdiff> now clarifies that the default is baseline mode.

=item BUG FIX

L<dbjoin> now propagates C<-T> into the sorting process (if it is required).
Thanks to Lan Wei for reporting this bug.

=back


=head2 2.60, 2016-09-04
Adds support for hash joins.

=over 4

=item ENHANCEMENT

L<dbjoin> now supports hash joins
with C<-t lefthash> and C<-t righthash>.
Hash joins cache a table in memory, but do not require
that the other table be sorted.
They are ideal when joining a large table against a small one.

=back

=head2 2.61, 2016-09-05
Support left and right outer joins.

=over 4

=item ENHANCEMENT

L<dbjoin> now handles left and right outer joins
with C<-t left> and C<-t right>.

=item ENHANCEMENT

L<dbjoin> hash joins are now selected 
with C<-m lefthash> and C<-m righthash>
(not the shortlived C<-t righthash> option).
(Technically this change is incompatible with Fsdd-2.60, but
no one but me ever used that version.)

=back

=head2 2.62, 2016-11-29
A new L<yaml_to_db> and other minor improvements.

=over 4

=item ENHANCEMENT

Documentation for L<xml_to_db> now includes sample output.

=item NEW

L<yaml_to_db> converts a specific form of YAML to fsdb.

=item BUG FIX

The test suite now uses C<diff -c -b> rather than C<diff -cb>
to make OpenBSD-5.9 happier, I hope.

=item ENHANCEMENT

Comments that log operations at the end of each file now do simple
quoting of spaces.  (It is not guaranteed to be fully shell-compliant.)

=item ENHANCEMENT

There is a new standard option, C<--header>,
allowing one to specify an Fsdb header for inputs that lack it.
Currently it is supported by L<dbcoldefine>,
L<dbrowuniq>, L<dbmapreduce>, L<dbmultistats>, L<dbsort>,
L<dbpipeline>.

=item ENHANCEMENT

L<dbfilepivot> now allows the B<--possible-pivots> option,
and if it is provided processes the data in one pass.

=item ENHANCEMENT

L<dbroweval> logs are now quoted.

=back

=head2 2.63, 2017-02-03
Re-add some features supposedly in 2.62 but not, and add more --header options.

=over 4

=item ENHANCEMENT

The option B<-j> is now a synonym for B<--parallelism>.
(And several documention bugs about this option are fixed.)

=item ENHANCEMENT

Additional support for C<--header> in L<dbcolmerge>, L<dbcol>, L<dbrow>,
and L<dbroweval>.

=item BUG FIX

Version 2.62 was supposed to have this improvement, but did not (and now does):
L<dbfilepivot> now allows the B<--possible-pivots> option,
and if it is provided processes the data in one pass.

=item BUG FIX

Version 2.62 was supposed to have this improvement, but did not (and now does):
L<dbroweval> logs are now quoted.

=back

=head2 2.64, 2017-11-20
several small bugfixes and enhancements

=over 4

=item BUG FIX

In L<dbroweval>, the C<next row> option previously did not
correctly set up C<_last_fieldname>.  It now does.

=item ENHANCEMENT

The L<csv_to_db> converter now has an optional C<-F x> option
to set the field separator.

=item ENHANCEMENT

Finally L<dbcolsplittocols> has a C<--header> option,
and a new C<-N> option to give the list of resulting output columns.

=item INCOMPATIBLE CHANGE

Now L<dbcolstats> and L<dbmultistats> produce no output
(but a schema) when given no input but a schema.
Previously they gave a null row of output.
The C<--output-on-no-input> and C<--no-output-on-no-input> 
options can control this behavior.

=back

=head2 2.65, 2018-02-16
Minor release, bug fix and -F option.

=over 4

=item ENHANCEMENT

L<dbmultistats> and L<dbmapreduce> now both take a C<-F x> option
to set the field separator.

=item BUG FIX

Fixed missing C<use Carp> in L<dbcolstats>.
Also went back and cleaned up all uses of C<croak()>.
Thanks to Zefram for the bug report.

=back

=head2 2.66, 2018-12-20
Critical bug fix in dbjoin.

=over 4

=item BUG FIX

Removed old tests from MANIFEST.  (Thanks to Hang Guo for reporting this bug.)

=item IMPROVEMENT

Errors for non-existing input files now include the bad filename
(before: "cannot setup filehandle", now: "cannot open input: cannot
open TEST/bad_filename").

=item BUG FIX

Hash joins with three identical rows were failing with the assertion
failure "internal error: confused about overflow" due to a now-fixed
bug.

=back

=head1 AUTHOR

John Heidemann, C<johnh@isi.edu>

See L</Contributors> for the many people who have contributed
bug reports and fixes.


=head1 COPYRIGHT

Fsdb is Copyright (C) 1991-2016 by John Heidemann <johnh@isi.edu>.

This program is free software; you can redistribute it and/or modify
it under the terms of version 2 of the GNU General Public License as
published by the Free Software Foundation.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

A copy of the GNU General Public License can be found in the file
``COPYING''.



=head1 COMMENTS and BUG REPORTS

Any comments about these programs should be sent to John Heidemann
C<johnh@isi.edu>.


=cut

1; # End of Fsdb

# LocalWords:  Exp rdb Manis Evan Schaffer passwd uid gid fullname homedir greg
# LocalWords:  gnuplot jgraph dbrow dbcol dbcolcreate dbcoldefine FSDB README un
# LocalWords:  dbcolrename dbcolmerge dbcolsplit dbjoin dbsort dbcoldiff Perl bw
# LocalWords:  dbmultistats dbrowdiff dbrowenumerate dbroweval dbstats dblistize
# LocalWords:  dbcolneaten dbcoltighten dbstripcomments dbstripextraheaders pct
# LocalWords:  dbstripleadingspace stddev rsd dbsetheader sprintf LIBDIR BINDIR
# LocalWords:  LocalWords isi URL com dbpercentile dbhistogram GRADEBOOK min ss
# LocalWords:  gradebook conf std dev dbrowaccumulate dbcolpercentile db dcliff
# LocalWords:  dbuniq uniq dbcolize distr pl Apr autoconf Jul html printf Fx fsdb
# LocalWords:  printfs dbrowuniq dbrecolize dbformmail kitrace geoff ns berkeley
# LocalWords:  comp lang perl Haobo Yu outliers Jorgensen csh dbrowsplituniq crl
# LocalWords:  dbcolmovingstats dbcolstats zscores tscores dbcolhisto columnar
# LocalWords:  dmalloc tabdelim stats numerics datapoint CDF xgraph max txt sed
# LocalWords:  login gecos div cmd nr hw hw assuing Kuenning Vikram Visweswariah
# LocalWords:  Kannan Varadahan Arkadi Gelfond Pavlin Radoslavov quartile getopt
# LocalWords:  dbcolscorrelate DbGetopt cp tmp nd Ya Xu dbfilesplit
# LocalWords:  MERCHANTABILITY tba dbcolsplittocols dbcolsplittorows cvs johnh
# LocalWords:  dbcolsregression datasets whitespace LaTeX FS columnname cgi pre
# LocalWords:  columname's dbfilevalidate  tcpdump http rv eq Bourne DbTDistr 
# LocalWords:  Goel Eggert Ning Strozzi NoSQL awk startup Sparcstation IPCs GHz
# LocalWords:  SunOS Arpaci Dusseau's SOSP Scheaffer STDIN dblib iso freebsd OO
# LocalWords:  sendmail unicode Makefile dbmapreduce dbcolmultiscale andersen
#  LocalWords:  lampson chen drovolis estrin floyd Lukac NIST SEMATECH RCS qw
#  LocalWords:  listize colize Unkyu dbpipeline ithreads dbfilealter dbrowcount
#  LocalWords:  dbrvstatdiff dbcolstatscores dbfilestripcomments csv nolog aho
#  LocalWords:  alfred david clark constantine debrorah Fsdb's colized listized
#  LocalWords:  Ashvin dbmerge na tmean tstddev wc logfiles stdin lseek SV xa
#  LocalWords:  refcount lossage DaGronk dbcolscorellate ipchain
