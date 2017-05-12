HTML::Tabulate
==============

HTML::Tabulate is used to render/display a given set of data in an HTML
table. Conceptually, it takes a data set and a presentation definition and
applies the presentation to the data set to produce the HTML table output.
The presentation definition accepts arguments corresponding to HTML table
tags ('table', 'tr', 'th', 'td' etc.) to define attributes for those tags,
plus additional arguments for other aspects of the presentation. The 
presentation definition can also be defined in multiple stages, to allow
a base definition that is overridden according to more specific needs.
HTML::Tabulate also supports advanced features like automatic striping,
arbitrary cell formatting, link creation, etc.

For example:

    $t = HTML::Tabulate->new({ 
        table => { border => 0, cellpadding => 0, cellspacing => 3 },
        th => { class => 'head' },
        null => '&nbsp;',
        stripe => '#dddddd',
    });

    print $t->render(\@employees, {
        stripe => '#ffffcc',
        fields => [ qw(emp_id emp_name emp_title emp_status) ],
        field_attr => {
            emp_id => {
                 link => 'emp.html?id=%s',
                 align => 'center',
            },
        },
    });


INSTALLATION

The standard:

   perl Makefile.PL
   make
   make test
   make install


DEPENDENCIES

This module requires the URI::Escape module, as well as the standard Carp 
and Exporter modules; the test framework uses Test::More.


COPYRIGHT AND LICENCE

Copyright (C) 2003-2011 Gavin Carr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

