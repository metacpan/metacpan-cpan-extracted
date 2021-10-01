# NAME

HTML::FillInForm - Populates HTML Forms with data.

# VERSION

version 2.22

# SYNOPSIS

Fill HTML form with data.

    $output = HTML::FillInForm->fill( \$html,   $q );
    $output = HTML::FillInForm->fill( \@html,   [$q1,$q2] );
    $output = HTML::FillInForm->fill( \*HTML,   \%data );
    $output = HTML::FillInForm->fill( 't.html', [\%data1,%data2] );

The HTML can be provided as a scalarref, arrayref, filehandle or file.  The data can come from one or more
hashrefs, or objects which support a param() method, like CGI.pm, [Apache::Request](https://metacpan.org/pod/Apache%3A%3ARequest), etc. 

# DESCRIPTION

This module fills in an HTML form with data from a Perl data structure, allowing you
to keep the HTML and Perl separate.

Here are two common use cases:

1\. A user submits an HTML form without filling out a required field.  You want
to redisplay the form with all the previous data in it, to make it easy for the
user to see and correct the error. 

2\. You have just retrieved a record from a database and need to display it in
an HTML form.

# fill

The basic syntax is seen above the Synopsis. There are a few additional options.

## Options

### target => 'form1'

Suppose you have multiple forms in a html file and only want to fill in one.

    $output = HTML::FillInForm->fill(\$html, $q, target => 'form1');

This will fill in only the form inside

    <FORM name="form1"> ... </FORM>

### fill\_password => 0

Passwords are filled in by default. To disable:

    fill_password => 0

### ignore\_fields => \[\]

To disable the filling of some fields:

    ignore_fields => ['prev','next']

### disable\_fields => \[\]

To disable fields from being edited:

    disable_fields => [ 'uid', 'gid' ]

### invalid\_fields => \[\]

To mark fields as being invalid (CSS class set to "invalid" or
whatever you set invalid\_class to):

    invalid_fields => [ 'uid', 'gid' ]

### invalid\_class => "invalid"

The CSS class which will be used to mark fields invalid.  Defaults to
"invalid".

### clear\_absent\_checkboxes => 0

Absent fields are not cleared or in any way changed. This is
not what you want when you deal with checkboxes which are not sent
by browser at all when cleared by user.

To remove "checked" attribute from checkboxes and radio buttons and
attribute "selected" from options of select lists for which there's no
data:

    clear_absent_checkboxes => 1

## File Upload fields

File upload fields cannot be supported directly. Workarounds include asking the
user to re-attach any file uploads or fancy server-side storage and
referencing. You are on your own.

## Clearing Fields

Fields are cleared if you set their value to an empty string or empty arrayref but not undef:

    # this will leave the form element foo untouched
    HTML::FillInForm->fill(\$html, { foo => undef });

    # this will set clear the form element foo
    HTML::FillInForm->fill(\$html, { foo => "" });

It has been suggested to add a option to change the behavior so that undef
values will clear the form elements.  Patches welcome.

You can also use `clear_absent_checkboxes` option to clear
checkboxes, radio buttons and selects without corresponding keys in
the data:

    # this will set clear the form element foo (and all others except
    # bar)
    HTML::FillInForm->fill(\$html, { bar => 123 },
        clear_absent_checkboxes => 1);

# Old syntax

You probably need to read no further. The remaining docs concern the
1.x era syntax, which is still supported. 

## new

Call `new()` to create a new FillInForm object:

    $fif = HTML::FillInForm->new;
    $fif->fill(...);

In theory, there is a slight performance benefit to calling `new()` before `fill()` if you make multiple 
calls to `fill()` before you destroy the object. Benchmark before optimizing. 

## fill ( old syntax ) 

Instead of having your HTML and data types auto-detected, you can declare them explicitly in your
call to `fill()`:

HTML source options:

    arrayref  => @html
    scalarref => $html
    file      => \*HTML 
    file      => 't.html'

Fill Data options:

    fobject   => $data_obj  # with param() method
    fdat      => \%data

Additional methods are also available:

    fill_file(\*HTML,...);
    fill_file('t.html',...);
    fill_arrayref(\@html,...);
    fill_scalarref(\$html,...);

# USING AN ALTERNATE PARSER

It's possible to use an alternate parser to [HTML::Parser](https://metacpan.org/pod/HTML%3A%3AParser) if the alternate
provides a sufficiently compatible interface. For example, when a Pure Perl
implementation of HTML::Parser appears, it could be used for portability. The syntax
is simply to provide a `parser_class` to new();

    HTML::FillInForm->new( parser_class => 'MyAlternate::Parser' ); 

# CALLING FROM OTHER MODULES

## Apache::PageKit

To use HTML::FillInForm in [Apache::PageKit](https://metacpan.org/pod/Apache%3A%3APageKit) is easy.   It is
automatically called for any page that includes a &lt;form> tag.
It can be turned on or off by using the `fill_in_form` configuration
option.

## Apache::ASP v2.09 and above

HTML::FillInForm is now integrated with Apache::ASP.  To activate, use

    PerlSetVar FormFill 1
    $Response->{FormFill} = 1

## HTML::Mason

Using HTML::FillInForm from HTML::Mason is covered in the FAQ on
the masonhq.com website at
[http://www.masonhq.com/?FAQ:HTTPAndHTML#h-how\_can\_i\_populate\_form\_values\_automatically\_](http://www.masonhq.com/?FAQ:HTTPAndHTML#h-how_can_i_populate_form_values_automatically_)

# SECURITY

Note that you might want to think about caching issues if you have password
fields on your page.  There is a discussion of this issue at

http://www.perlmonks.org/index.pl?node\_id=70482

In summary, some browsers will cache the output of CGI scripts, and you
can control this by setting the Expires header.  For example, use
`-expires` in [CGI.pm](https://metacpan.org/pod/CGI.pm) or set `browser_cache` to _no_ in 
Config.xml file of [Apache::PageKit](https://metacpan.org/pod/Apache%3A%3APageKit).

# TRANSLATION

Kato Atsushi has translated these docs into Japanese, available from

http://perldoc.jp

# BUGS

Please submit any bug reports to tjmather@maxmind.com.

# NOTES

Requires Perl 5.005 and [HTML::Parser](https://metacpan.org/pod/HTML%3A%3AParser) version 3.26.

I wrote this module because I wanted to be able to insert CGI data
into HTML forms,
but without combining the HTML and Perl code.  CGI.pm and Embperl allow you so
insert CGI data into forms, but require that you mix HTML with Perl.

There is a nice review of the module available here:
[http://www.perlmonks.org/index.pl?node\_id=274534](http://www.perlmonks.org/index.pl?node_id=274534)

# SEE ALSO

[HTML::Parser](https://metacpan.org/pod/HTML%3A%3AParser), 
[Data::FormValidator](https://metacpan.org/pod/Data%3A%3AFormValidato), 
[HTML::Template](https://metacpan.org/pod/HTML%3A%3ATemplate), 
[Apache::PageKit](https://metacpan.org/pod/Apache%3A%3APageKit)

# CREDITS

Fixes, Bug Reports, Docs have been generously provided by:

    Alex Kapranoff                Miika Pekkarinen
    Michael Fisher                Sam Tregar
    Tatsuhiko Miyagawa            Joseph Yanni
    Boris Zentner                 Philip Mak
    Dave Rolsky                   Jost Krieger
    Patrick Michael Kane          Gabriel Burka
    Ade Olonoh                    Bill Moseley
    Tom Lancaster                 James Tolley
    Martin H Sluka                Dan Kubb
    Mark Stosberg                 Alexander Hartmaier
    Jonathan Swartz               Paul Miller
    Trevor Schellhorn             Anthony Ettinger
    Jim Miner                     Simon P. Ditner
    Paul Lindner                  Michael Peters
    Maurice Aubrey                Trevor Schellhorn
    Andrew Creer                

Thanks!

# AUTHOR

TJ Mather, tjmather@maxmind.com

# COPYRIGHT AND LICENSE

This software is copyright (c) 2000 by TJ Mather, tjmather@maxmind.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
