###########################################################################
#
# $Id: LRpt.pm,v 1.12 2006/09/17 20:10:50 pkaluski Exp $
# $Name: Stable_0_16 $
#
# As for now, there is no direct use of this object. It serves only as a 
# gathering object for CPAN and ppm modules. 
# 
# $Log: LRpt.pm,v $
# Revision 1.12  2006/09/17 20:10:50  pkaluski
# Corrected POD
#
# Revision 1.11  2006/09/17 19:35:09  pkaluski
# Updated for release 0_16
#
# Revision 1.10  2006/09/10 18:56:36  pkaluski
# Added chunking. Major redesign continued.
#
# Revision 1.9  2006/04/09 15:42:58  pkaluski
# Small code clean-up. Each module has comprehensive POD
#
# Revision 1.8  2006/02/10 22:32:14  pkaluski
# Major redesign in progress. Updated POD. Works.
#
# Revision 1.7  2006/01/21 20:39:47  pkaluski
# Improved lcsvdiff output format
#
# Revision 1.6  2005/09/02 19:59:31  pkaluski
# Next refinement of PODs. Ready for distribution. Some work on clarity still to be done
#
# Revision 1.5  2005/09/01 20:00:17  pkaluski
# Refined PODs. Separation between public and private methods still to be done
#
# Revision 1.4  2005/01/28 23:20:17  pkaluski
# Got rid of DBSource and Config. They are almost not used
#
# Revision 1.3  2005/01/22 07:08:25  pkaluski
# Updated for release Stable_0_11
#
# Revision 1.2  2005/01/18 20:49:21  pkaluski
# Converted files from DOS to Unix format
#
# Revision 1.1  2004/12/10 22:26:56  pkaluski
# Making module CPAN and ppm compatible
#
#
############################################################################
package LRpt;

use 5.008;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use LRpt ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.16';


# Preloaded methods go here.

1;
__END__
# 

=head1 NAME

LRpt - Perl extension for comparing and reporting results of database selects 

=head1 SYNOPSIS

  ###################################################################
  #
  # Simple report
  #
  ###################################################################
  
  lks.pl --keys=keys.txt selects.txt > sel_subs.txt
  
  lcsvdmp.pl --conn_file=conn_file.txt --path=data sel_subs.txt 
  
  lrptxml.pl --rldf=rldf.xml --selects=sel_subs.txt --keys_file=keys.txt 
             data > report.xml
  
  
  ###################################################################
  #
  # Diff report
  #
  ###################################################################
  
  lks.pl --keys=keys.txt selects.txt > sel_subs.txt
  
  lcsvdmp.pl --conn_file=conn_file.txt --path=data_state1 sel_subs.txt
  
  ... some actions on the database...
  
  lcsvdmp.pl --conn_file=conn_file.txt --path=data_state2 sel_subs.txt
  
  lcsvdiff.pl --all --keys_file=keys.txt data_state1 data_state2 
             > diffs.txt
  
  lrptxml.pl --diffs --rldf=rldf.xml --selects=sel_subs.txt 
             --keys_file=keys.txt diffs.txt > report_aft.xml
  
  
  ###################################################################
  #
  # Expected-actual diff report
  #
  ###################################################################
  
  lks.pl --keys=keys.txt selects.txt > sel_subs.txt
  
  lcsvdmp.pl --conn_file=conn_file.txt --path=data sel_subs.txt
  
  lcsveadiff.pl --keys_file=keys.txt --expectations=exp.xml
            --cmp_rules=cmp_rules.xml data > eadiffs.xml
  
  

=head1 INSTALLATION

You can get the most recent code from B<lreport> project on source forge 
L<http://lreport.sourceforge.net>. You are given
2 options - you can either download a ppm active state package or
a CPAN package.

Currently, the module is not available on CPAN (L<http://www.cpan.org>).

=head1 DESCRIPTION

LRpt (B<LReport>) is a set of tools for database row sets 
comparison and reporting.
The core logic operates on I<csv> files, however, B<LReport> also provides
tools for converting select results to I<csv> files.

=head1 HOW IS THIS MANUAL ORGANIZED

Although the concepts behind this tool are not particularly sophisticated,
it is not easy to put shortly and concisely what does the tool actually
do. So firstly, I will give you an L<example|"EXAMPLE 1">, 
showing what does the tool do.
This will help you to quickly decide if this tool is something you are 
looking for.

If you consider B<LReport> usefull, and want to find out how to use it, go on
and read the L<second example|"EXAMPLE 2">. 
It will guide you step by step on how to make
the tool to do the stuff you want it to do.

Once you are done with examples, you can go on and read the 
L<REFERENCE MANUAL chapter|"REFERENCE MANUAL">, which is
a more systematic treament of the topic.

=head1 WHAT DOES THE TOOL REALLY DO

I created B<LReport> to help me in my tests. When I worked as a tester of
business applications, I have noticed that I am wasting much of my time
checking what has changed in the database and documenting my observations.
Although you cannot fully replace human beings in testing, 
you can at least support them in the most repetitive, boring and 
error prone tasks.

=head2 EXAMPLE 1

You want to check how a given transaction affects a database. 

You are not going to observe the whole database. Just results of 2 selects:

=over 4

=item C<select1: select * from customer where customer id = 1234>

=item C<select2: select * from service where customer id = 1234>

=back

Say, results of those selects before the transaction are as follows:

  select1 (customer) :
     ---------------------------------------------
     | customer_id | name  | last_name | address  |
     ---------------------------------------------
     |        1234 | Jan   | Nowak     | Warszawa |
     --------------------------------------------- 
  
  select2 (service) :
     ---------------------------------------------------
     | customer_id | service_type | price | status      |
     ---------------------------------------------------
     |        1234 |         MAIL | 1.30  | ACTIVE      |
     ---------------------------------------------------
     |        1234 |        VOICE | 0.34  | ACTIVE      |
     ---------------------------------------------------
     

After the transaction, the same selects return the following results:

  select1:
     ---------------------------------------------
     | customer_id | name  | last_name | address  |
     ---------------------------------------------
     |        1234 | Jan   | Nowak     | Warszawa |
     --------------------------------------------- 
  
  select2:
     ---------------------------------------------------
     | customer_id | service_type | price | status      |
     ---------------------------------------------------
     |        1234 |         GPRS | 2.05  | ACTIVE      |
     ---------------------------------------------------
     |        1234 |        VOICE | 0.34  | DEACTIVATED |
     ---------------------------------------------------
     

You would like to see what are differences between select results 
before and after 
the transaction. After processing the data through the tool chain, you get
the following diff report
  
  lcsvdiff.pl before/service.txt after/service.txt 
  INS( 1234#GPRS )
  DEL( 1234#MAIL )
  UPD( 1234#VOICE ): status: ACTIVE =#=> DEACTIVATED
  

Those entries mean the following:

=over 4

=item C<INS( 1234#GPRS )>

New row has been inserted with a key I<1234#GPRS>

=item C<DEL( 1234#MAIL )>

The row with a key I<1234#MAIL> has been removed

=item C<UPD( 1234#VOICE ): status>

In a row with a key (which is I<customer_id> and I<service_type> ) 
I<1234#VOICE>, 
value in a column I<status> has changed from I<ACTIVE> to I<DEACTIVATED>

=back

As you see, there is nothing about I<select1>. 
This is fine because nothing has changed in I<customer> table.

You can also generate an xml report about the current results of selects.
The report will look like this:

  <report>
      <customer>
          <statement><![CDATA[select * from customer where customer_id = 1234]]>
          </statement>
          <header>
              <customer_id/>
              <name/>
              <last_name/>
              <address/>
          </header>
          <data>
              <equal>
                  <customer_id>1234</customer_id>
                  <name>Jan</name>
                  <last_name>Nowak</last_name>
                  <address>Warszawa</address>
              </equal>
          </data>
      </customer>
      <service>
          <statement><![CDATA[select * from service where customer_id = 1234]]>
          </statement>
          <header>
              <customer_id/>
              <service_type/>
              <price/>
              <status/>
          </header>
          <data>
              <additional>
                  <customer_id>1234</customer_id>
                  <service_type>GPRS</service_type>
                  <price>2.05</price>
                  <status>ACTIVE</status>
              </additional>
              <missing>
                  <customer_id>1234</customer_id>
                  <service_type>MAIL</service_type>
                  <price>1.30</price>
                  <status>ACTIVE</status>
              </missing>
              <different>
                  <customer_id>1234</customer_id>
                  <service_type>VOICE</service_type>
                  <price>0.34</price>
                  <status>
                      <old_value>ACTIVE</old_value>
                      <new_value>DEACTIVATED</new_value>
                  </status>
              <different>
          </data>
      </service>
  </report>

You can transform it to some other formats using XSLT. You can transform it
to RTF. You can find an RTF document for this example at http:/xxxx.

=head3 CONCLUSION

I hope, you now know what can you expect from B<LReport>. 
There is more B<LReport> can offer you, for example 
L<expected-actual comparison|"EXPECTED-ACTUAL COMPARISON">. 
But for starters this example should be enough. If this is what
you are looking for, read on. In the 
L<next example|"HOW DOES IT WORK">, I am going to be 
more specific on how does the B<LReport> tool chain work.

=head1 HOW DOES IT WORK

Now I am going to show you another example. It will work on the same data
as in the L<first example|"EXAMPLE 1">. However, 
now I will be more specific on how do
you use B<LReport> tools to achieve results you want.

=head2 EXAMPLE 2

Let's see what steps do we need to perform in order to get results presented
in L<previous example|"EXAMPLE 1">.

You can split the whole processing on the following steps:

=over 4

=item 1. L<Run selects and dump their results to csv files|"Step 1: Run selects and dump their results to csv files">

=item 2. L<Run the transaction, which is about to modify a database|"Step 2: Run the transaction, which will modify the database">

=item 3. L<Run selects again and dump their results to another set of csv files|"Step 3: Run selects again and dump their results to csv files">

=item 4. L<Compare csv files from before- and after-transaction state|"Step 4: Compare csv files from before- and after-transaction state">

=item 5. L<Generate XML report|"Step 5: Generate XML report">

=back

Let's observe those steps one by one.

=head3 Step 1: Run selects and dump their results to csv files

It is important to understand that B<LReport> operates on I<csv> files. All
comparisons and reporting is done on I<csv> files as a source of data. 
I will elaborate in L<LIMITATIONS AND WARNINGS|"LIMITATIONS AND WARNINGS">, 
what are potential benefits and flaws of
such an approach. B<LReport> makes the following assumptions about the
format of I<csv> files:

=over 4

=item * Result of each select is placed in a separate file

=item * File extension is I<txt>

=item * Field separator is I<tab> (tabulation)

=item * First row in each file should be a row with columns' names

=back

You can modify some of those defaults. You can read about it in section 
L<DEFAULTS AND ENVIRONMENT VARIABLES|"DEFAULTS AND ENVIRONMENT VARIABLES">.

The goal of step 1 is to put the data into I<csv> files so other tools from
B<LReport> tool chain can work with them. If your database server provides you
 with
tools allowing to create such files, you don't have to use the tool provided
by B<LReport>. But let's assume we will use B<LReport> to do it for us. The tool
we have to use is B<lcsvdmp.pl> which stands for "B<LReport> csv dump". 
You call the B<lcsvdmp.pl> in a following way:

  lcsvdmp.pl --conn_file=conn_file.txt --path=data_dir selects.txt

Meaning of parameters:

=over 4

=item --path

This is a directory in which I<csv> files will be placed. If this
parameter is not given, files will be created in the current directory.

=item --conn_file

This may be difficult to understand on the beginning. 
This is the name of the database connection file, which contains 
instructions on how to
connect to the database. B<lcsvdmp.pl> uses 
L<DBI|DBI> to connect to database. As
you know each database driver (I<DBD>) has a slightly different flavour. So
the syntax of the connection string for Sybase is slightly different from that
for Oracle, and is slightly different from Mysql and so on. In order
to make B<lcsvdmp.pl> flexible and be able to deal with any source for which
I<DBD> exists, I passed the responsibility of opening a connection on a user. 
Connection file should contain a perl code, which opens a connection and 
assigns a reference to datbase handle to a variable named I<$dbh>.
B<lcsvdmp.pl> will load contents of connection file and eval it.

This an example of opening a connection to I<ODBC> source. As you can see
you can even include additional configuration code there:

  use Win32::ODBC;
  my $DBName     = "INVOICES";
  my $DBServer   = "MYSERVER";
  my $DBUser     = "pkaluski";
  my $DBPassword = "password";
  
  no strict;
  Win32::ODBC::ConfigDSN( ODBC_CONFIG_DSN, 
                          "Sybase ASE ODBC Driver",
                          "DSN=BolekSybase",
                          "Database=$DBName",
                          "InterfacesFileServerName=$DBServer");
  use strict;
  my $error = Win32::ODBC::Error();
  if( $error ){
      die $error;
  } 
  $dbh = DBI->connect( "DBI:ODBC:DBSybaseSource", $DBUser, $DBPassword,
                       {RaiseError => 1, AutoCommit => 1}
                     );

=item selects

Points to a file containing selects to be executed and dumped to
I<csv> files. For our example it has the following format:

  name: customer
  select: selects * from customer where customer_id = 1234
  %%
  name: service
  select: selects * from customer where customer_id = 1234
  %%

Each select should have a name. B<LReport> for each of selects will create a file
with a file name equal to select's name, plus extension. So results of select
named 'customer' will go to a file F<customer.txt>.


=back

In our example we run the tool in the following way

  lcsvdmp.pl --conn_file=conn_file.txt --path=before selects.txt

Note that we have given a B<--path> option with value I<before>. It will make
B<lcsvdmp.pl> to put all I<csv> files in I<before> directory, which should
exist before we run the tool. 

Once we run it, in the I<before> directory you should have 2 files - 
F<customer.txt> and F<service.txt> with results of according selects.

The generated files will look like this:

=over 4

=item F<customer.txt>

  customer_id   name    last_name       address
  1234  Jan     Nowak   Warszawa
  

=item F<service.txt>

  customer_id   service_type    price   status
  1234  VOICE   0.34    ACTIVE
  1234  MAIL    1.30    ACTIVE

=back

Fields are separated by I<tab> characters.

It is time for the step 2.

=head3 Step 2: Run the transaction, which will modify the database

Just do it. Once you are done, you have to see what has changed.

=head3 Step 3: Run selects again and dump their results to csv files

We use B<lcsvdmp.pl> again. We will run it as follows:

  lcsvdmp.pl --conn_file=conn_file.txt --path=after selects.txt

As you can see, the only difference is that we specify different destination
directory for I<csv> files. If we use I<before>, 
new csvs will simply overwrite
the previous ones and we will loose the information about the state before
the transaction.

At this stage, we have information about database states 
before and after the transaction, stored in separate directories.
It's time to compare them.

=head3 Step 4: Compare csv files from before- and after-transaction state

It's time for the next tool - B<lcsvdiff.pl>.

The command line syntax is as follows

  lcsvdiff.pl --keys_file=keys.txt $before_dir $after_dir

Meaning of parameters:

=over 4

=item --keys_file

The name of the file, which contains definitions of row keys
for each I<csv> file. Some explanation is needed here. In order to be able to 
compare 2 sets of rows, you have to define a kind of primary key, which will be
a direct link between I<after> and I<before> rows to be compared.
You can read more about rows keys in  
L<BEFORE-AFTER COMPARISON|"BEFORE-AFTER COMPARISON"> and
L<ROW KEYS|"ROW KEYS">.
The file for our example will look like this
  
  select_name: customer
  key_columns: customer_id:4
  %%
  select_name: service
  key_columns: customer_id:4, service_type
  %%
  

For I<customer> select, the key is a field I<customer_id>. Note the digit in a 
definition. It describes a length of the field and you should always specify
it for numeric fields. Why? As you know B<lcsvdiff.pl> operates on I<csv> files.
Those files, by their nature, carry no information about the field type, so
they will treat all columns as text. It does not have severe consequences
but there is one, which is good to be aware of. 2 is less then 1000 for
numeric types. But is greater then 1000 for text comparison. When you specify
a field lenght, B<lcsvdiff.pl> will leftpad the value with zeros. So the 
comparison will be 0002 with 1000 which will give the correct result.

=item $before_dir

Directory containing I<csv> files with data before the transaction

=item $after_dir

Directory containing I<csv> files with data after the transaction

=back

B<lcsvdiff.pl> will work as follows:

=over 4

=item 1. It will load F<customer.txt> files from I<before> and I<after> directories.

=item 2. A row key for each of rows will be calculated

In our case there is one row only

=item 3. It will find out that in both files there is a row with a key 
I<1234> and values in all columns are the same. So there are no differences.

=item 4. It will load F<service.txt> files from both locations.

=item 5. It will calculate a row key for each row. 

In case of service, there
is a composite key, consisting of columns I<customer_id> and I<service_type>.

=item 6. It will find that a row with a key I<1234#GPRS> exists in I<after> 
file but does not exist in I<before> file. 

So it concludes that this row was 
inserted by the transaction. So it will generate an INS entry:

  INS( 1234#GPRS )

=item 7. Then it will find that a row with a key I<1234#MAIL> exists in 
I<before> file but does exist in I<after> file. 

So it concludes that this row was removed
by the transaction. So it generates the I<DEL> entry:

  DEL( 1234#MAIL )

=item 8. It will notice that in both files there is a row with a key 
I<(1234,VOICE)> (presented as I<1234#VOICE>). 

It will find out that the value of column status
is different. So it will generate an I<UPD> entry like below

  UPD( 1234#VOICE ): status: ACTIVE =#=> DEACTIVATED

=item 9. Since there would be no more rows, the tool will finish.

=back

The tool will generate all the output on the standard output.

If you were interested in finding the diffences, you are done at this point.
If you would like to generate more readable, nicely formated report, you go
to step 5:

=head3 Step 5: Generate XML report

We have to use B<lrptxml.pl> tool. 
But I am not going to describe it here, to avoid
bogging you down with too much details. You can read about reporting in
manual page for B<lrptxml.pl>.

=head1 REFERENCE MANUAL 

In this and following chapters you will find a more systematic treatment
of B<LReport>. If you haven't read examples above, I recommend you at least to
skim over them. They will help you to understand concepts explained below.
When appropriate, you are given links to other documentation pages.

=head2 LREPORT SUITE

B<LReport> consits of the following tools:

=over 4

=item C<lks.pl>

Tool for replacing I<where key> place holders in select files. You can read
more about it in man page for L<C<LRpt::KeySubst>|LRpt::KeySubst>.

=item C<lcsvdmp.pl>

Tool for dumping results of a group of selects to I<csv> files. You can read
more about it in man page for L<C<LRpt::CSVDumper>|LRpt::CSVDumper>.

=item C<lcsvdiff.pl>

Tool for comparing 2 sets of I<csv> files. You can read more about in in man page
for L<C<LRpt::CSVDiff>|LRpt::CSVDiff>.

=item C<lcsveadiff.pl>

Tool for comparing a group of I<csv> files with expectations. You can read more
about it on a man page for L<C<LRpt::CSVEADiff>|LRpt::CSVEADiff>.

=item C<lrptxml.pl>

Tool for creating and xml report from results generated by B<lcsvdmp.pl> and
B<lcsvdiff.pl>. You can read more about it on a man page for 
L<C<LRpt::XMLReport>|LRpt::XMLReport>.

=back

=head2 COMPARISON TYPES

There are 2 types of possible comparisons:

=over 4

=item L<Before-after comparison|"BEFORE-AFTER COMPARISON">

=item L<Expected-actual comparison|"BEFORE-AFTER COMPARISON">

=back

=head3 BEFORE-AFTER COMPARISON

A set of selects is executed twice - before and after some transaction, which
could potentialy change the data. For each select, rows returned before
change are compared with rows returned by the same select after the change.
When differences are found, they are reported.

The following differences can be reported:

=over 4

=item missing row

The row, which existed before a transaction does not exist any more. 

=item additional row

The row did not exist before a transaction and appeared after the change.

=item not equal

The row existed before a transaction, still exists after it but
some fields of the row are modified.

=back

In order to determine a direct relationship between I<before> and I<after> rows
(i.e. to determine which I<after> row should be compared with which I<before>
row) a row key is used. A row key is an equivalent of primary
key in a database table. It has to be unique and may consist of many columns. 

During comparison for particular select, B<LReport> sorts I<after> and I<before> rows
by a row key (I<after> and I<before> rows are sorted separately). Then
it iterates through all keys found in both collections of rows (I<before> and
I<after> rows). If for example I<before> collections have 3 rows with keys 
I<(01,AB)>, I<(02,GT)>, I<(02,JT)> and the I<after> collection has rows with keys
I<(01,AB)>, I<(03,KP)>, then B<LReport> will iterate through a following list:
I<(01,AB)>, I<(02,GT)>, I<(02,JT)>, I<(03,KP)>. So it's basically a sum of sets.

For each value of a row key, B<LReport> finds an I<after> and I<before> row with this
key value. If there is no such row in I<before> collection, that means that
a new row was created. So it is reported as I<additional row>. If there is
no such row in I<after> collection, that means that a row was deleted. It is then
reported as I<missing row>. If both I<after> and I<before> row exist, they are 
compared field by field. If any difference is found, the row is reported
as I<not equal>. Otherwise rows are considered I<equal>.


=head3 EXPECTED-ACTUAL COMPARISON

NOTE: This functionality is experimental. 

This type of comparison may be used for test automation. Sometimes
you can create a static set of expected data, which you can use for
comparison with actual data. There are many cases, however, when you
cannot create static files with expectations, because some column values
depend on a date, environment and some circumstances, which are difficult
to recreate. So instead, you can implement a script/program, which will
predict what could be the output of a test and then generate expectations.

Those expecations may be then compared with results of selects done on
actual data. 
Although it may seem that there is nothing special in I<expected-actual>
comparison and it is a slightly modified version of 
I<L<before-after comparison|"BEFORE-AFTER COMPARISON">>,
this is not the case. There are some nuances, which forces an introduction
of some new notions and concepts.

In general, I<expected-actual> comparison uses the same core logic as 
I<L<before-after comparison|"BEFORE-AFTER COMPARISON">>. 
It parses the expectations and builds collections
of expected rows and then compares them with collections of actual rows.

The first big difference is that not all columns are defined in expectations.
It makes sense. We often deal with rows, which consist of 40 columns, but
we are only interested in 10 of them. It would be infeasible to force 
a user to define expected values for all those 40 columns. So the user can
decide not to specify them.

From the other hand, it would be good to have a protection mechanism,
which would warn a user when a really important column has no expectation
defined. This is where 
I<L<comparing rules|"COMPARING RULES">> come to the rescue.

I<L<Comparing rules|"COMPARING RULES">> are defined for a 
particular select. They define what to
do if an expected value for a given column in not specified. 
You can make the application terminate, do nothing, warn, use default value.
You can find details in L<COMPARING RULES chapter|"COMPARING RULES">.

Another big difference is a direct consequence of the previous one.
If you are allowed to not specify all columns values, it may happen
that a value for column belonging to a row key is not defined.
As a result a value of a row key for this row cannot be calculated.
So the mechanism of I<L<before-after comparison|"BEFORE-AFTER COMPARISON">> 
cannot be used in this case.
The solution is provided by I<unkeyed rows> and I<column matching>. It is 
explained below.

The following differences are reported:

=over 4

=item missing row

The row was expected to exist but doesn't. 

=item additional row

The row exists even though it is not expected.

=item not equal

The row exists as expected but some fields contain values different
from expected. 

=item unmatched

This type of difference is used for rows, for which row keys are not 
defined in expectations (due to not giving a value for one more
columns belonging to a row key). Such rows are called I<unkeyed rows>

=back

If case of I<unkeyed row> (missing values in columns which are parts
of a row key), rows can not be compared
on a row by row basis since row key is the only information allowing
to determine a direct relationship between rows. Hence, the following
solution was developed for such rows:

Each I<unkeyed row> defined in expectations is tried to be matched with
all its fields with any of actual rows. If there is no such match, the
row is reported as I<unmatched>.

The detailed rules are as follows:

=over 4

=item 1. Expectations rows with row keys values defined (keyed rows)
, have priority. 

All actual rows, which are matched with keyed expectation
rows are excluded from further comparison.

=item 2. If all I<keyed expectation rows> are processed, 
I<unkeyed expectation rows> are processed

=item 3. From all I<unkeyed rows>, rows having the biggest 
number of column values
defined are taken first for processing

=item 4. For each I<unkeyed row>, B<LReport> tries to find a remaining actual 
row (not 
matched earlier by any other exectation row), whose columns' values match with
all column values in expectation row. 

If such a row is found, the row is
considered I<matched>. If there is no such actual row, the
expectation row is reported as unmatched. In addition, the result of 
comparison with the closest match is reported (see below).

=back

Reporting of matching and unmatching has some additional specifics.
Since row key is not defined, it is possible to define a set of identical 
expectation rows. B<LReport> catches those identical rows and count them.
When it reports I<unmatching> rows, it groups identical rows and shows how
many of them were not matched. If for example, expectations rows for a given
select are 

  1, ABC, ACT
  1, ABC, ACT
  1, ABC, ACT

and only 2 of them have been matched with actual rows, row 
I<(1, ABC, ACT)> is reported to be unmatched once.

You can find details on configuring and using expected-actual comparison
(with a step by step example) 
in manual for L<C<LRpt:CSVEADiff>|LRpt::CSVEADiff>.

=head2 SELECTS

B<LReport> does not operate on database tables but on I<select results>. Single
I<csv> file contain results of one select statement. If the statement
is C<select * from table> then it is actually the whole table. But this
is a specific example. In general, I<csv> file contain results from one select.

=head3 SELECT NAMES

In order to manage select results, choose a proper row key, report format etc. 
each select should be given a name. In some simple cases it is not required
to give select a name, but it is recommended to use a meaningful name
whenever possible. 

Select name is used for following purposes:

=over 4

=item Creating I<csv> file name

Results for each select are stored in a file F<select_name.ext>, where I<ext>
 is an I<csv> file extension.

=item Choosing a row key

When a row key is defined, it contains information about names of selects to
which it applies

=item Choosing a report layout

A report layout contains a name of a select, to which it applies

=back

=head3 SELECT FILES

Selects are defined in files called I<select files>. They use jar record
format. Definition of each select ends with a line
beginning with I<%%> with white spaces after it.

Definition of each select consists of 2 fields: I<name> and I<select>.
Their meaning is as follows:

=over 4

=item name

Name of a select used for I<csv> file creation, row key choosing and so on.

=item select

Full text of a select. The text can be divided on several lines, no 
continuation characters are needed on end of lines. The only restrictions
you have to obey are:

* No line of a select text may start with I<string:> or I<%%>. Adding single 
space in front of them is enough to get rid of this limitation. 

=back

=head2 REPORTING AND FORMATING

B<LReport> provides some facilities for generating nicely formatted reports
of selects results and found differences. It does that by generating
xml reports, which can be then transformed to some document format using
XSLT.

B<LReport> package in the source forge also contain XSLT stylesheet for
converting xml report to an RTF document.

Reporting is a wide topic by itself so it is not described in details here.
You can read more on reporting in L<C<LRpt::XMLReport>|LRpt::XMLReport>.

=head2 ROW KEYS

The I<row key> is more or less an equivalent of primary key in database
theory. It defines a set of columns, which values uniquely identify each row.

Row key is crucial in L<before-after comparison|"BEFORE-AFTER COMPARISON">, 
since it determines the direct
link between I<before> and I<after> row.

In its code B<LReport> treats row key value as a string. If a row key
consists of one column, the key value for a row equals the value of the
specified column from this row. 

If a row key consists of several columns, then <LReport> creates key value
by joining values from those columns, using I<#> as a separator. So if
values from columns are I<3>, I<Kaluski> and <20050601>, then the key
value will be I<3#Kaluski#20050601>. Using a column, which values may
contain I<#> as a row key part, may lead to unpredicted affects.
It would be good to be able to define, what should be the row key value 
separator. But it is currently not implemented. The hash character I<#> was
chosen for the following reasons:

* It is low in characters order. So it not should disturb in string comparisons.
The strings I<abc#1234> and I<abcd#1234> are compared correctly. I<abc#1234>
is less then I<abcd#1234>. If I<#> would be high in characters order (having
ascii code 123 for example), then the comparison above would consider 
I<abc#1234> to be greater then I<abcd#1234>

* I found it very unlikely to use such a character in columns which are parts
of unique keys.

Row keys values are treated as strings, so they are compared as strings.
Therefore keys value I<2> is greater then I<1000>. In order to achieve correct
numerical comparison, column value has to be left padded with zeros.
I<0002> is lower then I<1000>.

There are several ways of defining a row key. We can define it in a file,
give it at command line and use default key. Currently it is recommended
to use only a file method. I am still working on the most convinient and 
expressive way of defining row keys in command line, so things may change.
The default row key is a first column of a table/select results.

=head3 ROW KEY FILE

Row key file is in jar record format. Definition of each key ends with a line
beginning with I<%%> with white spaces after it.

Definition of each key consists of 2 fields: I<select_name> and I<key_columns>.
Their meaning is as follows:

=over 4

=item select_name

Name or names (comma separarated) of selects, which should use this key.
This why giving names to all used selects is important.

=item key_columns

Comma separated list of columns, which constitute a row key. Column names
should be given in the order, in which they appear in the key.
In order to left pad with zeros a given column, containing numeric value,
the field length has to be specified after the column's name. The field
length has to be given after a colon after a column name 
(no spaces in between). 
See example below.

=back

Example of a row key file:

  select_name: customer
  key_columns: customer_id:4
  %%
  select_name: service, service_history
  key_columns: customer_id:4, service_type
  %%

As you can see one row key may be defined for several selects.
Note that values of customer_id column will be left padded with zeros to
create 4 character string.

=head2 FORMAT OF CSV FILES

It's an ordinary I<csv> file. B<LReport> expects that a first line of
each such a file contains columns' names. Default field separator is I<tab>.
You can read more on defaults and changing them in L<DEFAULTS AND ENVIRONMENT VARIABLES|"DEFAULTS AND ENVIRONMENT VARIABLES">
section.

=head2 COMPARING RULES

Comparing rules are used in expected-actual comparison. They are used
to determine what to do when expectations for a given column are not
specified.  Currently, the following possibilities are available:

=over 4

=item skip_and_warn 

Column is important, but not so important to stop the processing. 
A warning is printed and the comparison goes on

=item die

Column is so important, that further comparison does not make any sense.
B<LReport> (actually B<lcsveadiff.pl>) terminates.

=item use_default 

If column value is not given a default value is used.

=item use_default_and_warn

If column value is not given a default value is used and a warning is logged

=item skip

[default] Column is not important. It is not a problem if 
expectations are not defined. The comparison goes on

=back

You can read more about comparing rules in man page for 
L<C<LRpt::CSVEADiff>|LRpt::CSVEADiff>.

=head2 SELECT TEMPLATES

A I<select template> is an additional feature 
provided by B<LReport>. It's usefull
in cases when a user executes the same select or set of selects many times 
but for different values in a I<where> clause. 

=head3 EXAMPLE 3

We would like to run the selects from previous example. We want to run
it not only for I<customer_id = 1234> but also for 
I<customer_id = 1334> and
I<customer_id = 3476>. And maybe some others in future.

We can use a select template here. We define the following file 
(let's call it F<sel_tmpl.txt>):

  name: customer
  select: select * from customer where --customer_id--
  %%
  name: service
  select: select * from service where --customer_id--

Then we have create a where key file (F<wkey.txt>):

  name: customer_id
  key: customer_id = 1234
  %%

When we now run B<lks.pl>:

  lks.pl --keys=wkey.txt sel_tmpl.txt

Meaning of parameters is as follows:

=over 4

=item --keys

A file containing a text, with which a I<where key> placeholder should
be replaced.

=item sel_tmpl.txt

A file containing selects templates

=back

it will print on standard output following lines:

  name: customer
  select: select * from customer where customer_id = 1234
  %%
  name: service
  select: select * from service where customer_id = 1234
  %%

B<lks.pl> will basically replace all entries C<--entry--> from F<sel_tmp.txt> 
with a proper definition from F<wkey.txt>. Should we run this to selects for
I<customer_id = 1334>, we have to modify F<wkey.txt> only. Output generated by
B<lks.pl> can be fed as input to B<lcsvdmp.pl> (in B<--select> option).

You can read more on how B<lks.pl> work in man page for 
L<C<LRpt::KeySubst>|LRpt::KeySubst>.

Also have a look at L<SYNOPSIS|"SYNOPSIS">.

=head3 WHERE KEY FILES

Where keys are defined in files called I<where key files>. 
They use jar record
format. Definition of each key ends with a line
beginning with I<%%> with white spaces after it.

Definition of each select consists of 2 fields: I<name> and I<select>.
Their meaning is as follows:

=over 4

=item name

Name of a key. Has to match with a placeholder in a select template. 
Where key named I<abc> will replace a placeholder I<--abc--> in 
a select template

=item key

A text with, which a key placeholder in a select template should be 
replaced.  The text can be divided on several lines, no 
continuation characters are needed on end of lines. The only restrictions
you have to obey are:

* No line of a select text may start with I<string:> or I<%%>. Adding single 
space in front of them is enough to get rid of this limitation. 

=back

=head2 WORKING WITH DATABASES

Core logic of B<LReport> operates on I<csv> files. However, before we can 
operate on them, we have to create them first. A tool for creating
I<csv> files from select results is B<lcsvdmp.pl> and its usage is explained
in L<example 2|"EXAMPLE 2">.

=head3 DATABASE CONNECTION FILE

A database connection file contains instructions on how to
connect to the database. It is used by B<lcsvdmp.pl>.
As you know each database driver (I<DBD>) has a slightly different flavour. So
the syntax of the connection string for Sybase is slightly different from that
for Oracle, and is slightly different from Mysql and so on. In order
to make B<lcsvdmp.pl> flexible and be able to deal with any source for which
I<DBD> exists, I passed the responsibility of opening a connection on a user. 
Connection file should contain a perl code, which opens a connection and 
assigns a reference to datbase handle to a variable named I<$dbh>.
B<lcsvdmp.pl> will load contents of connection file and eval it.

This an example of opening a connection to I<ODBC> source. As you can see
you can even include additional configuration code there:

  use Win32::ODBC;
  my $DBName     = "INVOICES";
  my $DBServer   = "MYSERVER";
  my $DBUser     = "pkaluski";
  my $DBPassword = "password";
  
  no strict;
  Win32::ODBC::ConfigDSN( ODBC_CONFIG_DSN, 
                          "Sybase ASE ODBC Driver",
                          "DSN=DBSybaseSource",
                          "Database=$DBName",
                          "InterfacesFileServerName=$DBServer");
  use strict;
  my $error = Win32::ODBC::Error();
  if( $error ){
      die $error;
  } 
  $dbh = DBI->connect( "DBI:ODBC:DBSybaseSource", $DBUser, $DBPassword,
                       {RaiseError => 1, AutoCommit => 1}
                     );

Do not forget about assigning a reference to opened connection to I<$dbh>
variable.

=head3 SUPPORTED DATABASES

Since B<LReport> core logic operates on I<csv> files, you can use B<LReport> for
any database for which you are able to create I<csv> files for select results.
If you use B<lcsvdmp.pl> to do it, you need to have a 
DBI driver for a database you
are working with. B<LReport> uses the following DBI methods:

=over

=item C<connect>

=item C<prepare>

=item C<execute>

=item C<fetchall_arrayref>

=back

If the DBD for you database supports those methods, B<lcsvdmp.pl> 
should be able to do its job.

=head2 LIMITATIONS AND WARNINGS

B<LReport> core logic works on I<csv> files. This gives the tool significant
flexibility, since it can work with virtually any database. However, such 
an approach does have some consequences, which you should be aware of.

=over 4

=item No information on columns data types.

I<csv> files carry no information on data type of each column. B<LReport> 
treats all columns as texts. This may give surprising results for numeric
data. You would expect that 1 and 1.0 are equal, but for B<LReport> they are
different texts

=item B<LReport> does not support database schema comparison

B<LReport> will help you to detect that a field's value has changes from 1 to 2.
It also detect that a particular columns is new or does not exist any more.
But it will not detect that column datatype has changed from I<int> to I<char>. 

=item No support for null values

B<LReport> does not see null values, since it is problematic how to put
null values in I<csv> file. No value (I<tabtab>) in I<csv> file 
is treated as an 
empty string. So basically B<LReport> will not be able to find a difference 
between field containing a null value and a field containing an empty string.

=back

=head2 DEFAULTS AND ENVIRONMENT VARIABLES

=head2 ENVIRONMENT

B<LReport> has some hardcoded defaults. Each of those defaults can be 
overriden by environment variable. In some cases, those defaults
can be further overriden by command line switches. So the general rule is this:

=over 4

=item Check if the command switch specifies a parameter's value. If is does not
then
=item Check if there is an environmental variable, which defines it. If 
there is no such variable, use hardcoded default.

=back

There are following parameters, which are used by B<LReport> tools.
The list below is given in the format:
meaning: hardcoded default -> Environment variable -> command line option

=over 4

=item I<csv> filename extension:

  txt -> LRPT_CSV_FILE_EXT -> --ext=ext

=item Field separator in I<csv> files

  tab -> LRPT_CSV_FIELD_SEPARATOR -> --sep=separator

=item Location in which I<csv> files should be created

  . (current directory) -> LRPT_CSV_FILE_PATH -> --path=path

=item Database connection file

  conn_file.txt -> LRPT_CONNECTION_FILE -> --conn_file=file.txt

=item Chunk size

  1000 -> LRPT_CHUNK_SIZE -> --conn_file=file.txt

=item Location of global keys file

  keys.txt -> LRPT_GLOBAL_KEYS_FILE --> No command line switch

=item Separator between different values in diff file

  --#> -> LRPT_DIFF_VALUE_SEPARATOR --> No command line switch

=back

=head2 SUPPORTED PLATFORMS

The tool was developed and tested on Windows. I can't think of any reason
why it will not work on Unix but it was not tested. 
Currently it assumes that a name separator in file paths is slash (/) so
it probably won't work on VMS and other systems, which do not use slash
as a name separator.

=head1 DEVELOPMENT RELATED INFORMATION

B<NOTE: This sections is under construction>

If you are brave enough to try to modify the B<LReport> code and the ugliness
of the code did not scare you to death, read this chapter. It will
provide you with some guidance on how all things are organized. I hope
it will make your coding advanture less painfull.

=head2 OBJECT/PACKAGE MODEL

All B<LReport> logic is encapsulated in packages. All *.pl tools are
only wrappers calling one exported function. For example, B<lcsvdmp.pl>
looks as follows:

  use strict;
  use LRpt::CSVDumper;
  
  dump_selects( @ARGV );
  
Some packages are object oriented, some are not. 

LRpt provides 4 main objects to perform expected job (see SYNOPSIS):

=over 4

=item L<C<LRpt::CSVDumper>|LRpt::CSVDumper>

Dumps results of selects to a I<csv> file. Wrapped by B<lcsvdmp.pl>.

=item L<C<LRpt::CSVDiff>|LRpt::CSVDiff>

Compares two sets of I<csv> files. Wrapped by B<lcsvdiff.pl>

=item L<C<LRpt::CSVEADiff>|LRpt::CSVEADiff>

Compares set of I<csv> files with expectations. Wrapped by B<lcsveadiff.pl>

=item L<C<LRpt::XMLReport>|LRpt::XMLReport>

Converts I<csv> and I<diff> files to I<xml> format. Wrapped by B<lrptxml.pl>

=item L<C<LRpt::KeySubst>|LRpt::KeySubst>

Substitutes I<where keys> place holders in select templates.

=back

Apart from those packages there is a bunch of other classes 
defined. Some of them may appear
pretty usefull. Be careful though. I do not consider them public,
so I may decide to change them in future. If you find some of
them extremely useful, let me know so I will be more careful in my 
future desing decisions.

LRpt library consists of the following classes:

=over 4

=item L<C<LRpt::CollDiff>|LRpt::CollDiff>

Object for comparing two collections of rows

=item L<C<LRpt::CollEADiff>|LRpt::CollEADiff>

Object for comparing collection of rows with a set of expectations

=item L<C<LRpt::Collection>|LRpt::Collection>

Container for data loaded from I<csv> files.

=item L<C<LRpt::CollUnkeyed>|LRpt::CollUnkeyed>

Container for unkeyed rows.

=item L<C<LRpt::Config>|LRpt::Config>

Object for managing defaults and runtime parameters.

=item L<C<LRpt::JarReader>|LRpt::JarReader>

Object for reading jar records files.

=item L<C<LRpt::RKeysRdr>|LRpt::RKeysRdr>

Object for reading row keys definition files.

=back

Each of this modules have its POD, so if you would like to know more about
them, you can go ahead and read it.

=head2 REGRESSION TESTS

B<LReport> consists of a bunch of tools. Currently regression tests do not
test particular modules separately. Instead there are some end-to-end 
test scenarios. For each testcase there is set of expectations and the results
are compared with those expectations.

As of 10-09-2006 tests are divided into 2 groups: tests of simple reporting
and tests of difference reporting. The 't' directory contains
2 directories, 1 for each group - F<DiffRpt> and F<Report>. 
Let's have a look at DiffRpt directory.
It constains the following subdirectories/files:

  dbschema
  dbschema1
  dbschema2
  dbschema3
  t1
  t2
  t3
  t4
  t5
  driver.pl

F<driver.pl> is test driver for diff reporting tests. It contains perl
code running scenarious of four tests.

F<dbschema> and F<dbschema1> are databases. They are based on I<csv> files and 
are handled by DBD::CVS. They are used to simulate changes in the database.
Instead of changing the contents of the database, selects for I<before>
state are done on I<dbschema> database and selects for I<after> state are done
on I<dbschema1>.

F<t1> to F<t4> are directories used by test cases. Let's have a look at t1.
The test case code looks like this (it is in t\DiffRpt\driver.pl file):

CODE

On the beginning, I<t1> contains configuration and input files. It also 
contains F<expected> directory. It contains a directory structure 
with files expected to be generated by tested tools. 
Once you run the test, it will create F<actual> 
directory in I<t1>. All output files generated by the test case will be placed
in the I<actual> directory and its subdirectories. Once the scenario is done,
contents of I<actual> and I<expected> directories are compared. If they are
the same, that means that the test case generated exactly what we expected.
Otherwise, it behaves differently which means that we either introduced a 
new bug or modified the functionality. We should either remove the bug, or
if changes were intentional - modify the test case.

=head1 BUGS

As of 15-01-2006 the tool have only one user, which is me. I used it
in one environment. You can imagine that there are plenty of undetected bugs
which will jump out, once you will start using it for your specific needs.
I expect that regression tests may fail on Unix. This is due to end of line
incompatibilities.

In case you find a bug, let me know. 

=head1 TO DO

=head2 PERFORMANCE

Thanks to chunking, LReport can dump and compare huge files. 
Some performance tuning has been already done but there is still some space for
improvement.

=head2 MANAGING COMPARING RULES

Currently comparing rules 
(for expected-actual comparison) have to be specified in command lines 
options. I expect that for intensive use of B<LReport>, it would be convenient
to have a common place where all this is defined. B<LReport> tools should look
there if nothing is given in the command line.

=head2 DOCUMENTATION

This is the first version of a documentation. Some parts of it are still under
construction. Some links does not work. I am aware of that. My goal is
to provide you with something you can play with. I will keep working on
documentation refinements.

=head1 SEE ALSO

Project is maintained on Source Forge (L<http://lreport.sourceforge.net>). 
You can find links to documentation there.

=head1 AUTHOR

Piotr Kaluski, E<lt>pkaluski@piotrkaluski.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004-2006 by Piotr Kaluski

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut



