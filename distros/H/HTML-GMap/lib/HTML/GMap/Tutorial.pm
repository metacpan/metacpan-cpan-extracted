package HTML::GMap::Tutorial;

our $VERSION = '0.06';

# $Id: Tutorial.pm,v 1.12 2007/07/27 15:38:36 canaran Exp $

use warnings;
use strict;

=head1 NAME

HTML::GMap::Tutorial - HTML::GMap distribution tutorial

=head1 DESCRIPTION

This is the tutorial for HTML::GMap module.

=head1 INTRODUCTION

Google Maps service provides an AJAX-based geographic map and a Javascript API that allows operations such as overlaying images and lines on the geographic map. The map can be dragged using the mouse.

HTML::GMap wraps around the Google Maps API and provides a generic Perl infrastructure that can be used to easily build interactive web applications that display geographic data stored in a database. HTML::GMap handles HTML page rendering, graph/icon generation, Javascript components and interaction with the underlying database.

For example, let's say that you have a database that contains locations of stores that belong to a grocery store chain. Each row in your database contains the name of the store, its geographic location (a latitude and a longitude) and some additional properties of each store such as whether the store has a pharmacy department and whether the store is open 24-hours. Using HTML::GMap you can easily set up a page which displays the stores on a geographic map. You can display stores that have a pharmacy store as a square icon and ones that do not as a triangle icon. You can display stores that are open 24-hours with orange icons and ones which are not as blue icons. Up to two properties can be used in this manner. Using HTML::GMap you can set up filters on the side of the view. The user can select from a drop-down list, the stores that are open 24-hours and click filter to display only the ones that match the criteria.

HTML::GMap can be used to view data cumulatively using pie charts as well. For example, let's say that you have a database of physicians. Each row in your database contains the name of the physician, his/her geographic location (a latitude and a longitude) and some additional properties such as physicians specialty and whether he/she accepts a particular insurance plan. Using HTML::GMap you can display this information easily on a geographic map. The map is divided into a 10x10 grid based on equal latitudes and longitudes. For each tile, a pie chart is generated on-the-fly with each move of the map and distribution of physician specialties for each tile is displayed. Since map can be zoomed in and out, the tiles can be made larger and smaller. A filter is displayed on the side so that only a single specialty or whether a physician accepts the insurance plan can be selected for views.

=head1 DESIGN

The setup described above require two types of server-side functionality. The first one generates the initial HTML page. A second functionality is needed to respond to client requests initiated by dragging the map. The HTML::GMap module combines these two functionalities in a single package allowing a simple integrated structure. For more complex applications, the module supports the second functionality to be provided by external sources.

=head1 INSTALLATION AND COMPONENTS

HTML::GMap package can be installed as any other CPAN module.

The package contains the following modules:

  HTML::GMap           - Core module.
  HTML::GMap::Files    - A container to store HTML and Javascript templates
                         and a CSS file. This file is not intended to be used
                         directly. It is used by HTML::GMap to create temp 
                         copies of these non-Perl files.
  HTML::GMap::Tutorial - Tutorial.

=head1 REQUIREMENTS

=head2 Environment

This code was developed for a Linux environment, running Apache as the web server and MySQL as the back-end database server. Running in other compatible environments may require modifications.

=head2 Using the Google Maps Service

In order to use Google Maps on your website, you need to sign up for the Google Maps API and create an API key. Please refer to Google's Terms & Conditions to determine the service's suitability for your site. The API key is a long string of characters that is specific for your site. Save this key as you will later need to place it in the configuration file.

Google Maps API Sign up Page: <http://www.google.com/apis/maps/signup.html>

=head2 Back-end Database

The display requires a back-end MySQL table that contains the data and the geographic coordinates. For each data point (a row) a "latitude" and a "longitude" column is required. Additional columns are needed to associate more information with each data point.

=head2 Web Server (Apache)

When you write your Perl script that uses HTML::GMap, you will need to place it in a CGI-executable directory in your web server. In addition to this, you will need a directory which is writable by the user that your web server runs under. This directory will be used to store temp files (mostly icon images). This directory needs to be able to be accessible through the web.

=head2 Prototype Javascript Framework

You need the Prototype Javascript Framework, a single file that can be downloaded from its home page at <http://www.prototypejs.org/>.

=head1 DEMO

As described earlier, HTML::GMap can be used to present data in two different modes:

 - High Resolution (hires) mode
 - Pie Chart (piechart) mode

The following two examples demonstrate these two modes. Please read both examples as many features apply to both modes. These will be introduced in the first example and referenced back by the second example.

=head2 Displaying Data in hires mode

Let's build the chain store example which we explained in the Introduction section above.

We will need a table that contains the data. Here's a sample table populated with random data.

The table looks like this:

 mysql> desc html_gmap_hires_sample;
 +-----------+-------------+------+-----+---------+----------------+
 | Field     | Type        | Null | Key | Default | Extra          |
 +-----------+-------------+------+-----+---------+----------------+
 | id        | int(11)     | NO   | PRI | NULL    | auto_increment |
 | latitude  | double      | YES  | MUL | NULL    |                |
 | longitude | double      | YES  | MUL | NULL    |                |
 | name      | varchar(30) | YES  |     | NULL    |                |
 | pharmacy  | char(3)     | YES  | MUL | NULL    |                |
 | open24    | char(3)     | YES  | MUL | NULL    |                |
 +-----------+-------------+------+-----+---------+----------------+

 id        : the primary key
 latitude  : latitude of store
 longitude : longitude of store
 name      : the name of the store
 pharmacy  : whether the store has a pharmacy department
 open24    : whether the store is open 24-hours

First 10 rows in the table look like this:

 mysql> select * from html_gmap_hires_sample limit 10;
 +----+------------------+-------------------+-----------+----------+--------+
 | id | latitude         | longitude         | name      | pharmacy | open24 |
 +----+------------------+-------------------+-----------+----------+--------+
 |  1 | 40.9238307736974 | -75.4030897185631 | Store #1  | Yes      | Yes    |
 |  2 | 40.7992166092141 | -75.5955783495462 | Store #2  | No       | No     |
 |  3 | 40.2296733106477 | -74.9588939230624 | Store #3  | No       | Yes    |
 |  4 | 40.6157298274265 | -74.7609734908294 | Store #4  | No       | Yes    |
 |  5 | 40.3437587749323 | -75.6761027474891 | Store #5  | No       | Yes    |
 |  6 | 39.8856390921787 | -72.8002781457194 | Store #6  | Yes      | Yes    |
 |  7 | 40.3589340793951 | -73.8374056778696 | Store #7  | No       | Yes    |
 |  8 |  39.911120200648 | -73.6606559871681 | Store #8  | Yes      | No     |
 |  9 |  41.548534604991 | -74.0078654025807 | Store #9  | Yes      | Yes    |
 | 10 | 41.8260254817441 | -75.3182839751613 | Store #10 | No       | Yes    |
 +----+------------------+-------------------+-----------+----------+--------+

The following script is sufficient to display the data in this table. In its most basic form, you only need to instantiate a HTML::GMap object and call its display method.

 #!/usr/bin/perl

 use warnings;
 use strict;

 use HTML::GMap;

 my $gmap = HTML::GMap->new (
     initial_format        => 'xml-hires',
     page_title            => 'HTML::GMap hires View Demo',
     header                => '[Placeholder for Header]',
     footer                => '[Placeholder for Header]',
     db_access_params      => ['DBI:mysql:database=temp;host=localhost;port=3306',
                               'gmap', 'gmap'],         
     base_sql_table        => qq[html_gmap_hires_sample],
     base_sql_fields       => ['id',
                               'latitude',
                               'longitude',
                               'name',
                               'pharmacy',
                               'open24',
                               ],
     base_output_headers   => ['Id',
                               'Latitude',
                               'Longitude',
                               'Store Name',
                               'Pharmacy',
                               'Open 24 Hours',
                               ],
     legend_field1         => 'pharmacy',
     legend_field2         => 'open24',
     param_fields          => {
       pharmacy => ['all:All', 'Yes', 'No'],
       open24   => ['all:All', 'Yes', 'No'],
     },
     gmap_key              => qq[.... <gmap_key> ....],
     temp_dir              => qq[/usr/local/panzea/html/demo/tmp],
     temp_dir_eq           => qq[http://localhost:8080/demo/tmp],
 );

 # Display
 $gmap->display;

Let's go through the parameters passed on to the constructor:

I<initial_format>

This parameter defines the mode. It can be one of 'xml-hires' or 'xml-piechart'.

I<page_title, header & footer>

You can customize the pages with your page title, header and footer. "page_title" is the title of the page that is displayed on the title bar of the browser and top of the page. "header" and "footer" contain the HTML content that make up the header and footer.

I<db_access_params>

The data displayed on the map lives on a MySQL database. "db_access_params" is used to pass on the database access parameters. It is formatted as and array ref containing the datasource, username and password. The datasource is formatted for DBI (please refer to DBI documentation if you need details on the format).

 [$password, $username, $password]

I<base_sql_table, base_sql_fields & base_output_headers>

These three parameters describe how the data is stored in the database.

"base_sql_table" describes the name of the table. This can be a clause consisting of JOINs. However, for simplicity and speed, it is recommended to use a single denormalized table. This parameter is passed on as a string (scalar).

Every time the map is moved, a request is made to the server for data corresponding to the location where the map is then placed. The server returns an XML document with the relevant information. "base_sql_fields" describes which fields are returned for each data point. The primary key ("id"), "latitude", "longitude" fields are mandatory. In addition, "name", "pharmacy" and "open24" fields are returned. Please note that "pharmacy" and "open24" fields are the fields that are used in the filter. This parameter is passed on as an array ref.

For each column name passed on by "base_sql_fields", a header is provided by the "base_output_headers" parameter. These headers are used in display. This parameter is passed on as an array ref.

I<legend_field1 & legend_field2>

In hires mode, each data point has two attributes, first of which determines the icon used for the data point on the map and the second one determines the color of the icon used. "legend_field1" and "legend_field2" describe the two columns that are used for this purpose. These fields are passed on as scalars.

I<param_fields>

This parameter describes the parameter fields that are going to be used as filters. It is passed on as a hash ref.

In this example, first parameter field is "pharmacy". The keys come from base_sql_fields. The value for pharmacy is an array ref which contains the values that will be displayed for the filter parameter as a drop-down list.

 pharmacy => ['all:All', 'Yes', 'No']

There are three values 'all:All", 'Yes' and 'No'.

'all:All' describes that the value 'all' will be used. However, when  this is displayed on a drop-down list, 'All' is displayed instead of 'all'. This format allows a value in the database to be displayed by a different view on the page. The following parameters, 'Yes' and 'No" do not have an alternate view, they are displayed as they are.

It should also be noted that, the value 'all' is a reserved value as a parameter.

I<gmap_key>

This the Google Maps API key described earlier.

I<temp_dir & temp_dir_eq>

HTML::GMap uses a temp directory to store generated icons and other files. This directory needs to be writable by the user which Apache runs as. Also, it needs to be accessible through the web.

"temp_dir" is the full path to the location of the directory. "temp_dir_eq" is the URL-equivalent of this directory.

For example, if the DOCUMENT_ROOT of the web site that will be hosting the view is "/usr/local/demo/html" and temp_dir is "/usr/local/demo/html/demo/tmp", the temp_dir_ew would be "http://<domain_name>/demo/tmp".

After we construct the HTML::GMap object, we can now call the display method:

 $gmap->display;

This creates the initial display and handles any subsequent AJAX requests to serve more data.

=head2 Displaying Data in piechart mode

Similar to the previous example, let's build the physician example described in the Introduction section. Please go through the previous section before reading this one as shared features not discussed in this example.

A sample table populated with random data follows:

The table looks like this:

 mysql> desc html_gmap_piechart_sample;
 +-----------+-------------+------+-----+---------+----------------+
 | Field     | Type        | Null | Key | Default | Extra          |
 +-----------+-------------+------+-----+---------+----------------+
 | id        | int(11)     | NO   | PRI | NULL    | auto_increment |
 | latitude  | double      | YES  | MUL | NULL    |                |
 | longitude | double      | YES  | MUL | NULL    |                |
 | name      | varchar(30) | YES  |     | NULL    |                |
 | specialty | varchar(30) | YES  | MUL | NULL    |                |
 | insurance | char(3)     | YES  | MUL | NULL    |                |
 +-----------+-------------+------+-----+---------+----------------+

 id        : the primary key
 latitude  : latitude of physician
 longitude : longitude of physician
 name      : the name of the physician
 specialty : physician's specialty
 insurance : whether the physician accepts a particular insurance plan

First 10 rows in the table look like this:

 mysql> select * from html_gmap_piechart_sample limit 10;
 +----+------------------+-------------------+---------------+--------------+-----------+
 | id | latitude         | longitude         | name          | specialty    | insurance |
 +----+------------------+-------------------+---------------+--------------+-----------+
 |  1 | 40.4884296913242 | -77.1003155108648 | Physician #1  | Specialty #3 | No        |
 |  2 | 41.8454302160773 |   -75.16482267814 | Physician #2  | Specialty #5 | No        |
 |  3 | 41.2721700896335 |  -78.622291319768 | Physician #3  | Specialty #1 | No        |
 |  4 | 41.4016346345324 | -78.0504781535355 | Physician #4  | Specialty #3 | Yes       |
 |  5 |  41.513092057257 | -76.3753730044735 | Physician #5  | Specialty #3 | Yes       |
 |  6 | 41.3368285220529 | -76.8610737601246 | Physician #6  | Specialty #1 | No        |
 |  7 | 40.6684951710926 | -78.8420805090634 | Physician #7  | Specialty #4 | Yes       |
 |  8 |  41.064080827709 |  -77.789377537904 | Physician #8  | Specialty #2 | Yes       |
 |  9 |  40.151821055458 | -75.0997523063612 | Physician #9  | Specialty #5 | No        |
 | 10 | 41.6288865333676 | -77.8815743236442 | Physician #10 | Specialty #5 | Yes       |
 +----+------------------+-------------------+---------------+--------------+-----------+

Similar to the previous example, the following script is sufficient to display the data in this table.

 #!/usr/bin/perl

 use warnings;
 use strict;

 use HTML::GMap;

 my $gmap = HTML::GMap->new (
     initial_format        => 'xml-piechart',
     page_title            => 'HTML::GMap piechart View Demo',
     header                => '[Placeholder for Header]',
     footer                => '[Placeholder for Header]',
     db_access_params      => ['DBI:mysql:database=temp;host=localhost;port=3306',
                               'gmap', 'gmap'],
     base_sql_table        => qq[html_gmap_piechart_sample],
     base_sql_fields       => ['id',
                               'latitude',
                               'longitude',
                               'name',
                               'specialty',
                               'insurance',
                               ],
     base_output_headers   => ['Id',
                               'Latitude',
                               'Longitude',
                               'Name',
                               'Specialty',
                               'Insurance',
                               ],
     cluster_field         => 'specialty',
     param_fields          => {
       specialty => ['all:All',      'Specialty #1', 'Specialty #2',
                     'Specialty #3', 'Specialty #4', 'Specialty #5'],
       insurance => ['all:All', 'Yes', 'No'],
     },
     gmap_key              => qq[.... <gmap_key> ....],
     temp_dir              => qq[/usr/local/panzea/html/demo/tmp],
     temp_dir_eq           => qq[http://localhost:8080/demo/tmp],
 );

 # Display
 $gmap->display;

Let's go through the parameters passed on to the constructor:

I<initial_format>

Same as previous example.

I<page_title, header & footer>

Same as previous example.

I<db_access_params>

Same as previous example.

I<base_sql_table, base_sql_fields & base_output_headers>

Same as previous example. Please see "cluster_field" param below for additional information.

I<cluster_field>

In piechart mode, pie charts are prepared by the count of data points by a single attribute. In this example, the number of physicians with a particular specialty is used to make pie charts. "cluster_field" describes the field which is used to cluster the data.

"cluster_field" in piechart mode is analogous to "legend_field1" and "legend_field2" in hires mode. This field must be among the fields retrieved by "base_sql_fields".

I<param_fields>

Same as previous example.

I<gmap_key>

Same as previous example.

I<temp_dir & temp_dir_eq>

Same as previous example.

Similar to the previous example, after we construct the HTML::GMap object, we can now call the display method:

 $gmap->display;

This creates the initial display and handles any subsequent AJAX requests to serve more data.

=head2 Additional Features & Further Customization

As demonstrate with two examples above, you can build a fully functional display simply by instantiating a HTML::GMap object and then calling its display method.

However, there may be cases in which you might want to create the HTML::GMap object and use the database handle, session id, etc. to calculate some features and pass them back on to the object before calling its display method.

For example, in the piechart example given earlier, the "parameter_fields" parameter is passed on as follows:

    param_fields          => {
      specialty => ['all:All',      'Specialty #1', 'Specialty #2',
                    'Specialty #3', 'Specialty #4', 'Specialty #5'],
      insurance => ['all:All', 'Yes', 'No'],
    },

Hardcoding names as such might not be desirable. Instead, you can do the following:

   ...

   my $gmap = HTML::GMap->new (
   ...
   );

   my $dbh = $gmap->dbh;

   my @specialties = ... # Use dbh to retrieve a "distinct"
                           set of specialties from the database

   $gmap->param_fields({
      specialty => \@specialties,
      insurance => ['all:All', 'Yes', 'No'],
    });

    $gmap->display;                      

In addition to the constructor params demonstrated in the examples, the following params can be used to further customize the display. Please note that all the params can be used as get/set methods as well.

I<page_title, header & footer>

These were demonstrated with the examples. They are not mandatory.

I<messages>

This attribute can be set to display a message in the lower right hand corner of the display.

I<center_latitude & center_longitude>

These parameters can be set to the geographic coordinate that map should pan to when first loaded. If not specified, map pans to default coordinates.

I<max_hires_display>

In hires mode, when there are more than "max_hires_display" points in display, a lower resolution view of the data points is displayed. The view switches to higher resolution as map is zoomed in. If not specified, this attribute defaults to 100.

I<install_dir & install_dir_eq>

These parameters define installation directory and its equivalent. Currently its only purpose is to store the prototype.js file. If not specified, defaults to temp-dir and temp_dir_eq respectively.

I<image_height_pix & image_width_pix>

Height and width of map in pixels. Defaults to 600. *** Currently, alternate values are not tested. ***

I<tile_height_pix & tile_width_pix>

Height and width of tiles in pixels. Defaults to 60. *** Currently, alternate values are not tested. ***

=head1 REMARKS

Please refer to HTML::GMap for a list of all attributes and methods and sub-classing information.

=head1 TO-DO

 - Test additional image/tile dimensions.
 - Implement color/shape persistence in hires mode.
 - Test and add docs for sub-classing.

=head1 AUTHOR

Payan Canaran <pcanaran@cpan.org>

=head1 BUGS

Please report them.

=head1 VERSION

Version 0.06

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright (c) 2006-2007 Cold Spring Harbor Laboratory

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See DISCLAIMER.txt for
disclaimers of warranty.

=cut

1;
