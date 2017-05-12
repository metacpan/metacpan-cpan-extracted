# NAME

HTML::ExtractMeta - Helper class for extracting useful meta data from HTML pages.

# VERSION

Version 0.21

# SYNOPSIS

    use HTML::ExtractMeta;

    my $em = HTML::ExtractMeta->new( $html );

    print "Title       = " . $em->title       . "\n";
    print "Description = " . $em->description . "\n";
    print "Author      = " . $em->author      . "\n";
    print "URL         = " . $em->url         . "\n";
    print "Site name   = " . $em->site_name   . "\n";
    print "Type        = " . $em->type        . "\n";
    print "Locale      = " . $em->locale      . "\n";
    print "Image URL   = " . $em->image_url   . "\n";
    print "Authors     = " . join( ', ', @{$em->authors} )  . "\n";
    print "Keywords    = " . join( ', ', @{$em->keywords} ) . "\n";

# DESCRIPTION

HTML::ExtractMeta is a helper class for extracting useful metadata from HTML
pages, like their title, description, authors etc.

# METHODS

## new( %opts )

Returns a new HTML::ExtractMeta instance. Requires HTML as input argument;

    my $em = HTML::ExtractMeta->new( $html );

## title

Returns the HTML page's title.

## description

Returns the HTML page's description.

## url

Returns the HTML page's URL.

## image\_url

Returns the HTML page's descriptive image URL.

## site\_name

Returns the HTML page's site name.

## type

Returns the HTML page's type.

## locale

Returns the HTML page's locale.

## authors

Returns the HTML page's author names as an array reference.

## author

Helper method; returns the HTML page's first mentioned author. Basically the
same as:

    my $author = $em->authors->[0];

## keywords

Returns the HTML page's keywords.

# AUTHOR

Tore Aursand, `<toreau at gmail.com>`

# BUGS

Please report any bugs or feature requests to the web interface at [https://rt.cpan.org/Public/Dist/Display.html?Name=HTML-ExtractMeta](https://rt.cpan.org/Public/Dist/Display.html?Name=HTML-ExtractMeta).

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc HTML::ExtractMeta

You can also look for information at:

- AnnoCPAN: Annotated CPAN documentation

    [http://annocpan.org/dist/HTML-ExtractMeta](http://annocpan.org/dist/HTML-ExtractMeta)

- CPAN Ratings

    [http://cpanratings.perl.org/d/HTML-ExtractMeta](http://cpanratings.perl.org/d/HTML-ExtractMeta)

- Search CPAN

    [http://search.cpan.org/dist/HTML-ExtractMeta/](http://search.cpan.org/dist/HTML-ExtractMeta/)

# LICENSE AND COPYRIGHT

Copyright 2012-2016 Tore Aursand.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

[http://www.perlfoundation.org/artistic\_license\_2\_0](http://www.perlfoundation.org/artistic_license_2_0)

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
