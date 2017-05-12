package HTML::SearchPage::Tutorial;

our $VERSION = '0.05';

# $Id: Tutorial.pm,v 1.10 2007/09/19 21:30:18 canaran Exp $

use warnings;
use strict;

=head1 NAME

HTML::SearchPage::Tutorial - HTML::SearchPage distribution tutorial

=head1 DESCRIPTION

This is the tutorial for HTML::SearchPage module.

=head1 INTRODUCTION

HTML::SearchPage is a generic distribution for developing web-based search pages that run on top of a database. The search pages can be constructed independent of the schema of the database.

For example, let's say that you have scientific experiment data spread across a number of tables in a relational database. For one case, you one table that contains experiment data results in a way that each row contains a single experiment, the researcher that performed the particular experiment, a number of experimental conditions for that particular iteration and the result of the experiment. The experiment table contains a foreign key to another table that contains name and contact information for each researcher. Using HTML::SearchPage, you can easily set up a web page that allows users to query the database for experiment results, filtering results by experimental conditions and generating result tables and formatting result sets as comma/tab-separated text or Excel files.

HTML::SearchPage generates the HTML code for the search form, parses CGI params returned in response to using the search form, generates the SQL statement based on parsed parameters, executes them and renders the HTML table that contains the results. It also implements the pagination of the result set, code for generating result dumps and sortable fields.

=head1 INSTALLATION AND COMPONENTS

HTML::SearchPage distribution can be installed as any other CPAN distribution.

The distribution contains the following modules:

  HTML::SearchPage           - Core module that represents a search page.
  HTML::SearchPage::Param    - Side module that represents a parameter
                               field in a search page.
  HTML::SearchPage::Files    - A container to store image and CSS files.
                               This file is not intended to be used directly.
                               It is used by HTML::SearchPage to create temp
                               copies of these non-Perl files.
  HTML::SearchPage::Tutorial - Tutorial.

=head1 REQUIREMENTS

=head2 Environment

This code was developed for a Linux environment, running Apache as the web server and MySQL as the back-end database server. Running in other compatible environments may require modifications.

=head2 Web Server (Apache)

When you write your Perl script that uses HTML::SearchPage, you will need to place it in a CGI-executable directory in your web server. In addition to this, you will need a directory which is writable by the user that your web server runs under. This directory will be used to store temp files (few images and a CSS file). This directory needs to be able to be accessible through the web.

=head1 DEMO

HTML::SearchPage is typically used for making interactive search pages that query a database. In addition, simpler pages that display a single row from a table in a vertical orientation can be generated. Also, results retrieved from the database can be post-processed by external project-specific custom modules.

Let's begin by building the sample database described earlier.

First table: Each row contains information about a single experiment and a foreign key to a person record in the second table.

 mysql> describe html_searchpage_experiment;
 +---------------+--------------+------+-----+---------+----------------+
 | Field         | Type         | Null | Key | Default | Extra          |
 +---------------+--------------+------+-----+---------+----------------+
 | experiment_id | int(11)      | NO   | PRI | NULL    | auto_increment |
 | person_id     | int(11)      | YES  |     | NULL    |                |
 | temperature   | int(3)       | YES  | MUL | NULL    |                |
 | sample_size   | int(3)       | YES  | MUL | NULL    |                |
 | attribute     | varchar(30)  | YES  | MUL | NULL    |                |
 | result        | varchar(30)  | YES  | MUL | NULL    |                |
 | comments      | varchar(100) | YES  |     | NULL    |                |
 +---------------+--------------+------+-----+---------+----------------+

 experiment_id : the primary key
 person_id     : foreign key to person table
 temperature   : temperature (experimental condition)
 sample_size   : sample_size (experimental condition)
 attribute     : attribute   (experimental condition)
 result        : result      (experimental condition)
 comments      : additional comments

First 10 rows in the table look like this:

 mysql> select * from html_searchpage_experiment limit 10;
 +---------------+-----------+-------------+-------------+-----------+--------+---------------+
 | experiment_id | person_id | temperature | sample_size | attribute | result | comments      |
 +---------------+-----------+-------------+-------------+-----------+--------+---------------+
 |             1 |         2 |         143 |         346 | color     | high   |               |
 |             2 |         3 |         154 |         220 | weight    | normal |               |
 |             3 |         5 |          70 |         672 | color     | high   | comments here |
 |             4 |         4 |          95 |         997 | height    | high   | comments here |
 |             5 |         3 |          74 |         598 | height    | normal |               |
 |             6 |         3 |          62 |         672 | height    | normal | comments here |
 |             7 |         4 |         109 |        1061 | color     | high   | comments here |
 |             8 |         3 |          27 |         969 | weight    | normal | comments here |
 |             9 |         4 |         147 |         756 | weight    | low    |               |
 |            10 |         2 |         154 |         955 | height    | high   | comments here |
 +---------------+-----------+-------------+-------------+-----------+--------+---------------+

Second table: Each row contains information on a single researcher.

 mysql> describe html_searchpage_person;
 +--------------+--------------+------+-----+---------+----------------+
 | Field        | Type         | Null | Key | Default | Extra          |
 +--------------+--------------+------+-----+---------+----------------+
 | person_id    | int(11)      | NO   | PRI | NULL    | auto_increment |
 | name         | varchar(100) | YES  |     | NULL    |                |
 | organization | varchar(100) | YES  |     | NULL    |                |
 | email        | varchar(100) | YES  |     | NULL    |                |
 | address      | varchar(200) | YES  |     | NULL    |                |
 | comments     | varchar(100) | YES  |     | NULL    |                |
 +--------------+--------------+------+-----+---------+----------------+

 person_id    : the primary key
 name         : name of researcher
 organization : organization
 email        : email
 address      : address
 comments     : additional comments

Rows of the table look like this:

 mysql> select * from html_searchpage_person;
 +-----------+---------------+----------------+------------------------------+--------------------------+---------------------------------+
 | person_id | name          | organization   | email                        | address                  | comments                        |
 +-----------+---------------+----------------+------------------------------+--------------------------+---------------------------------+
 |         1 | Researcher #1 | Research Lab A | researcher at research_lab_a | 123 Main St, City, State | comments here for first person  |
 |         2 | Reseracher #2 | Research Lab B | researcher at research_lab_b | 456 Main St, City, State | comments here for second person |
 |         3 | Researcher #3 | Research Lab C | researcher at research_lab_c | 789 Main St, City, State | comments here for third person  |
 |         4 | Researcher #4 | Research Lab D | researcher at research_lab_d | 234 Main St, City, State | comments here for fourth person |
 |         5 | Researcher #5 | Research Lab E | researcher at research_lab_e | 567 Main St, City, State | comments here for fifth person  |
 +-----------+---------------+----------------+------------------------------+--------------------------+---------------------------------+

The following examples demonstrate main functionality provided by the distribution.

=head2 Example 1 - An Interactive Web Page to Query Experiment Data

The following script builds a page that allows the user to query experiment results on a join of the two tables with ability to filter on a number of fields.

 #!/usr/bin/perl

 use warnings;
 use strict;

 use HTML::SearchPage;
 use HTML::SearchPage::Param;

 my $sp = HTML::SearchPage->new(
     page_title     => 'HTML::SearchPage Demo',
     header         => '[Placeholder for header]',
     css            => '',
     temp_dir       => qq[/usr/local/demo/html/demo/tmp],
     temp_dir_eq    => qq[http://localhost:8080/demo/tmp],
     instructions   => '[Placeholder for instructions]',
     footer         => '[Placeholder for footer]',
     db_access_params =>
       ['DBI:mysql:database=temp;host=localhost;port=3306', 'test', 'test'],
     base_sql_table => qq[
         html_searchpage_experiment hse
         JOIN html_searchpage_person hsp ON (hsp.person_id = hse.person_id)
     ],
     base_sql_fields => [
         'hsp.name',
         'hse.temperature',
         'hse.sample_size',
         'hse.attribute',
         'hse.result',
         'hse.comments',
     ],
     base_output_headers => [
          'Researcher:hsp.name',
         'Temperature (F):hse.temperature',
         'Sample Size:hse.sample_size',
         'Attribute:hse.attribute',
         'Result:hse.result',
         'Comments',
     ],
     sort_fields   => 2,
     method        => 'GET',
     page_size     => 20,
     debug_level => 1,
 );    # Displays error page if fails

 my $pf;

 $pf = HTML::SearchPage::Param->new(
     -label            => 'Temperature (F):',
     -sql_column       => 'hse.temperature',
     -form_name        => 'temperature',
     -operator_list    => ['<:less than', '=:equals', '>:greater than'],
     -operator_default => '<',
     -param_type       => 'text:12',
 ) or $sp->display_error_page($@);

 $sp->param_field('temperature', $pf);

 $pf = HTML::SearchPage::Param->new(
     -label            => 'Sample Size:',
     -sql_column       => 'hse.sample_size',
     -form_name        => 'sample_size',
     -operator_list    => ['<:less than', '=:equals', '>:greater than'],
     -operator_default => '>',
     -param_type       => 'text:12',
 ) or $sp->display_error_page($@);

 $sp->param_field('sample_size', $pf);

 $pf = HTML::SearchPage::Param->new(
     -label         => 'Attribute:',
     -sql_column    => 'hse.attribute',
     -form_name     => 'attribute',
     -operator_list => ['=:equals'],
     -param_type    => 'drop_down',
     -param_list =>
       ['DISTINCT:SELECT DISTINCT attribute FROM html_searchpage_experiment'],
     -auto_all  => 1,
     -auto_null => 1,
 ) or $sp->display_error_page($@);

 $sp->param_field('attribute', $pf);

 $pf = HTML::SearchPage::Param->new(
     -label         => 'Result:',
     -sql_column    => 'hse.result',
     -form_name     => 'result',
     -operator_list => ['=:equals'],
     -param_type    => 'drop_down',
     -param_list =>
       ['DISTINCT:SELECT DISTINCT result FROM html_searchpage_experiment'],
     -auto_all  => 1,
     -auto_null => 1,
 ) or $sp->display_error_page($@);

 $sp->param_field('result', $pf);

 $sp->display_page;

The script consists of 3 main sections:

 - Instantiating a HTML::SearchPage object (this represents the
   search page)
 - Instantiating multiple HTML::SearchPage::Param objects (these represent
   the parameter fields used to filter results) and adding them to the
   search page object
 - Calling the "display_page" method on the search page object

Let's begin with the HTML::SearchPage object and the parameters passed on to its constructor:

I<page_title, header, footer, css & instructions>

You can customize the pages with your page title, header and footer. "page_title" is the title of the page that is displayed on the title bar of the browser and top of the page. "header" and "footer" contain the HTML content that make up the header and footer. The module contains a default CSS but an additional CSS file can be added using the "css" parameter. Also, you can include instructions to be displayed using the "instructions" param. For these parameters, you can simply include the HTML content or you can place content of a file, retrieve it dynamically from a URL or insert output from a script. Please see HTML::SearchPage documentation for implementation details.

I<temp_dir & temp_dir_eq>

The package uses a temp directory to store temp copies of a few images and a CSS file. This directory needs to be writable by the user which Apache runs under. Also, it needs to be accessible through the web.

"temp_dir" is the full path to the location of the directory. "temp_dir_eq" is the URL-equivalent of this directory.

For example, if the DOCUMENT_ROOT of the web site that hosts the page is "/usr/local/demo/html" and temp_dir is "/usr/local/demo/html/demo/tmp", the temp_dir_eq would be "http://<domain_name>/demo/tmp".

I<db_access_params>

The data presented on the page is stored on a MySQL database. "db_access_params" specifies the database access parameters. It is formatted as and array ref containing the datasource, username and password. The datasource is formatted for DBI (please refer to DBI documentation if you need details on the format).

 [$password, $username, $password]

You can specify multiple databases for which a drop-down database selector is generated. Please see HTML::SearchPage documentation for format.

I<base_sql_table, base_sql_fields & base_output_headers>

These three parameters describe how the data is retrieved from the database.

"base_sql_table" describes the table from which data will be retrieved. This can be name of a single table or a clause consisting of JOINs.

"base_sql_fields" describes the fields that are retrieved from the database. In this example, we specify 5 fields for retrieval. This parameter is passed as an array ref.

For each column name passed by "base_sql_fields", a header is provided by the "base_output_headers" parameter. These headers are used in the display. This parameter is passed as an array ref. For some of the fields, the "base_output_header" is specified in the format:

  <header>:<sort_field>

If a <sort_field> is specified after the header, the corresponding field becomes sortable using <sort_field> as basis for sorting. When a field becomes sortable, a small "S" icon is displayed on its header and it's name appears in the sorting drop-down list.

I<sort_fields>

A number of sorting drop-downs are provided on the interface. The results can be sorted by multiple fields (e.g. sort by field 1, then by field 2)
"sort_fields" specifies the number of sorting drop-downs to display.

I<method>

This specifies the method used by the form submission, which can be one of 'GET' or 'POST'.

I<page_size>

The results retrieved from the database are paginated. This parameter defines the number of records to display in each page.

I<debug_level>

The package provides debugging information on each page. This parameter defines the level of debugging information. Please refer to HTML::SearchPage documentation for details on different debug levels.

Now we have a search page object and we are ready to add parameter fields that will be used to query the database. For each field, we create a HTML::SearchPage::Param object and add it to the search page object using search page object's "param_field" method.

In this example, 4 parameter fields are added. This means that there will be 4 fields displayed on the top of the page that allow the user to specify constraints in querying the database.

Each parameter field, acts on a SQL column. There may be one operator or multiple operators that a user can select for each parameter field. When there is only one operator you can hide it from display.

The following are parameters we use with the HTML::SearchPage::Param constructor.

I<label>

Label of the parameter as displayed on the drop-down.

I<sql_column>

SQL column that the parameter acts on.

I<form_name>

Defines the name, which the parameter is represented as in the HTML form.

I<operator_list>

Operators that are listed for the parameter field. This parameter is passed as an array ref.

The following operators are supported:

 - =          : Equal to
 - like_m     : Matches pattern (like; * converted to %; ? converted to _)
 - like_c     : Contains (like; %pattern%)
 - >       	: Greater than
 - >=         : Greater than or equal to
 - <          : Less than
 - <=         : Less than or equal to
 - <>         : Not equal to
 - not_like_m : Not <like_m>
 - not_like_c : Not <like_c>

To display an alternate text for a particular operator, you can use the "<operator>:<display>" format.

I<operator_default>

The default operator (one that will be displayed when page is first loaded) is specified by this parameter.

I<param_type>

This parameter specifies the type of the parameter field.

The following parameter field types are supported:

     - text:<length>         : Text field, <length> characters long
     - drop_down             : Drop-down list from which a single parameter
                               can be selected
     - scrolling_list:<size> : Drop-down list from which multiple parameters
                               can be selected

I<param_list>

For "drop_down" and "scrolling_list" parameter types, multiple parameter values are provided as an array ref. For "text" parameter type, a scalar is needed (if an array ref is provided, all but the first element is ignored).

=head2 Example 2 - A Non-interactive Page to Display a Single Row

The module also supports simple non-interactive displays. For example, the following implementation is designed to retrieve one record from the person table and present information on the person in a single page. When the script is set up, it can be called by a URL that contains the identifier for the record.

 #!/usr/bin/perl

 our $VERSION = '0.01';

 # $Id: Tutorial.pm,v 1.10 2007/09/19 21:30:18 canaran Exp $

 use warnings;
 use strict;

 use HTML::SearchPage;
 use HTML::SearchPage::Param;

 my $sp = HTML::SearchPage->new(
     page_title     => 'HTML::SearchPage Demo',
     header         => '[Placeholder for header]',
     css            => '',
     temp_dir       => qq[/usr/local/demo/html/demo/tmp],
     temp_dir_eq    => qq[http://localhost:8080/demo/tmp],
     instructions   => '',
     footer         => '[Placeholder for footer]',
     base_sql_table => qq[html_searchpage_person hsp],
     base_sql_fields => [
         'hsp.name',
         'hsp.organization',
         'hsp.email',
         'hsp.address',
         'hsp.comments',
     ],
     base_output_headers => [
         'Name',
         'Organization',
         'E-mail',
         'Address',
         'Comments',
     ],
     base_identifier => 'hsp.person_id',
     method        => 'GET',
     db_access_params =>
       ['DBI:mysql:database=temp;host=localhost;port=3306', 'test', 'test'],
     debug_level => 1,
 );    # Displays error page if fails

 $sp->display_info;

All the parameters serve the same functions as in the earlier example.

The only new parameter is "base_identifier" which defines the unique column which the module will query for.

In this particular example, the URL to call this page is constructed as:

 http://<domain>/<script>?identifier=1

The word "identifier" is reserved and must be used as is.

Since the "base_identifier" is specified as "hsp.person_id", the module queries the html_searchpage_person table (which is specified by the base_sql_table) for [person_id = "1"].

Please note that, this functionality is intended to query for unique identifiers. If multiple records are retrieved as a result of the query an exception is raised and the error page is displayed. Similarly, an exception is raised if no record that match the criteria is found. You might want to perform checks before linking in this manner.

=head1 REMARKS

Please refer to HTML::SearchPage for a list of all parameters.

=head1 TO-DO

 - add docs on modifiers

=head1 AUTHOR

Payan Canaran <pcanaran@cpan.org>

=head1 BUGS

Please report them.

=head1 VERSION

Version 0.05

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright (c) 2005-2007 Cold Spring Harbor Laboratory

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See DISCLAIMER.txt for
disclaimers of warranty.

=cut

1;
