package Labyrinth::Demo;

use warnings;
use strict;

our $VERSION = '1.04';

1;

__END__

=head1 NAME

Labyrinth::Demo - Labyrinth Website Management Framework - Demo Website

=head1 DESCRIPTION

Documentation overview for the Demo Website of the Labyrinth Website 
Management Framework.

Labyrinth began life in 2002, with a small set of plugins to enable various
features of web site management. 

This demo website uses the core set of plugins to provide an example of a
website management system. 

These plugins provide the functionality to manipulate core aspects of the data
used within Labyrinth. Several of these plugins only provide administration 
features.

=head1 ADDITIONAL FILES

In order for your website to work with Labyrinth, some additional files are 
required. This package provides the standard set of files to enable Labyrinth
and the Core plugins to work with a blank canvas. These files consist of SQL, 
template and configuration files, together with some basic CSS and Javascript 
files.

Install these into the website structure and edit as necessary to implement
the layout and functionality you require for your purposes.

Please note that included with this distribution are files designed and 
developed by other people. Notable are the following:

=head2 PixelGreen

Version 1.2

CSS Layout and Design by Erwin Aligam, release under the Creative Commons 
Attribution 2.5 License - http://creativecommons.org/licenses/by/2.5/

See http://www.styleshout.com/ for more details.

=head2 TinyMCE

Version 3.211

A Javascript WYSIWYG Content Editor by Moxiecode Systems AB, released under the
GNU Leseer General Public License (LGPL) - 
http://tinymce.moxiecode.com/js/tinymce/jscripts/tiny_mce/license.txt

See http://tinymce.moxiecode.com/ for more details.

=head1 INSTALLATION

To set up the Demo Website, install via a CPAN client (such as CPAN.pm, 
CPANPLUS or cpanminus) to ensure you install required prerequisites. Then copy
the directory contents under the 'vhost' directory into your web server 
directory. For this example the path to these files and directories is assumed
to be '/var/www/demo'. If you wish to change this, please update the file paths
used in 'cgi-bin/pages.cgi' and 'cgi-bin/config/settings.ini'

If you use Apache, include the configuration snippet contained in the file
'vhosts.conf', in the appropriate Apache configuration file. Directions for
other web servers will be included at a later date.

Create a MySQL database called 'demo' and use the base file 
'cgi-bin/db/demo-base.sql' as a starting point. If you wish to specify a fixed
user to access the database, you may wish to review the 'grant.sql' file or
amend the 'settings.ini' as appropriate.

You should now be able to start your Apache instance. Update your hosts file 
as necessary to point to your new virtual host.

A more complete installation and configuration script is planned for the 
future, which can also install plugins.

=head1 LABYRINTH DIRECTORY STRUCTURE

    ./cgi-bin
        /config		- contains top level configuration files
           /requests	- contains despatch tables
        /db			- database dumps
        /lib
           /Labyrinth	- Labyrinth Core modules
              /Plugin	- Labyrinth Plugin modules
        /templates		- Template Toolkit templates
    ./html
        /cache		- cache where reports are produced
        /css		- website CSS files
        /images		- website image files
        /js			- website JavaScript files
           /tiny_mce	- Tiny MCE JavaScript application files
    ./toolkit

As mentioned included in the package is the vhost entry from an Apache 
configuration file. This file contains the rewrite rules that translate user 
friendly URLs to the local CGI call. However, it is not necessary to have 
rewrite rules, in the event you are unable to use them, and the application 
can quite happily function with full 'cgi-bin/' type paths.

The './cgi-bin/pages.cgi' file is the core startup script, that simply passes
the settings file, and initiates Labyrinth. The 'act' CGI parameter contains 
the primary action required. Throughout the duration of a request, the current
action may change several times, with each referencing the despatch tables to 
load and run the correct functions and render the correct templates. Each user 
has a nominated "realm", which is the section of the site they are given access
to. The realm despatch table is used to load and run and default functions, and
can thus be used to render different skins and/or layout templates.

The CGI parameters are validated against the './cgi-bin/config/parserules.ini'
file. The rules are built from these entries and passed to Data::FormValidator. 
Each entry's fields refer to parameter name, whether mandatory, default value, 
preprocessing function, constraint function and finally the regular expression. 
If a constraint is provided the regular expression is ignored. Where the 
parameter name looks like ':^LISTED', this is a regular expression match 
against the parameter name (where the ':' character is removed). This enables 
parameters which have a changeable suffix, can apply the same constraint or 
regular expression against each matching parameter's value.

All SQL statements are called using a Phrasebook Design Pattern. As such the 
'./cgi-bin/config/phrasebook.ini' file contains all each phrase and associated 
SQL as used within the application. To aid readability SQL can be split onto 
multiple lines, using the '\' character as the last entry on a line to continue 
onto the next.

Templates are built from the given layout, see the appropriate realm entry in 
the despatch table, incorporating other templates as required, including the 
'content' template as specified by the last action command. See the appropriate
despatch table to reference the appropriate content template.

Tiny MCE is used by Labyrinth where appropriate for text area input. However, 
this is only activated on the pages where it is appropriate. 

The set of scripts within the toolkit directory typically provide ad-hoc or 
timed (e.g. via cron) functionality. The scripts are not intended to be run via
the web server, but often provide support functionality, such as creating 
static pages or running periodic cleanup tasks.

=head1 DEMO WEBSITE

To see a working example of this distribution, please see the following link:

L<http://demo.missbarbell.co.uk>

=head1 ADDITION INFORMATION

Although Labyrinth has long been in development, documentation has not been a
priority. As such much of the documentation you may need to understand how to
use Labyrinth is the code itself. If you have the inclination, documentation
patches would be very gratefully received.

The Labyrinth website [1] will eventually feature a documentation site, wiki
and other features which are intended to provide you with the information to
use and extend Labyrinth as you wish.

[1] http://labyrinth.missbarbell.co.uk

=head1 SEE ALSO

L<Labyrinth>,
L<Labyrinth-Plugin-Core>

http://labyrinth.missbarbell.co.uk

=head1 AUTHOR

Barbie, <barbie@missbarbell.co.uk> for
Miss Barbell Productions, L<http://www.missbarbell.co.uk/>

=head1 COPYRIGHT & LICENSE

  Copyright (C) 2002-2014 Barbie for Miss Barbell Productions
  All Rights Reserved.

  This distribution is free software; you can redistribute it and/or
  modify it under the Artistic License 2.0.

=cut
