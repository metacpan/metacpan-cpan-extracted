#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 4;

# RewriteAttributes {{{
my $html = << "END";
<html>
    <body background="baroque.jpg">
        <a href="http://en.wikipedia.org/wiki/COBOL">COBOL</a><br />
        <a href="http://en.wikipedia.org/wiki/FORTRAN">FORTRAN</a><br />

        <img src="http://example.com/img/COBOL.bmp" title="COBOL rocks" />
        <img src="http://example.com/img/FORTRAN.bmp" title="FORTRAN rocks" />
    </body>
</html>
END

use HTML::RewriteAttributes;
$html = HTML::RewriteAttributes->rewrite($html, sub {
    my ($tag, $attr, $value) = @_;

    # delete any attribute that mentions..
    return if $value =~ /COBOL/i;

    $value =~ s/\brocks\b/rules/g;
    return $value;
});

is($html, << "END", "rewrote the html correctly");
<html>
    <body background="baroque.jpg">
        <a>COBOL</a><br />
        <a href="http://en.wikipedia.org/wiki/FORTRAN">FORTRAN</a><br />

        <img />
        <img src="http://example.com/img/FORTRAN.bmp" title="FORTRAN rules" />
    </body>
</html>
END
# }}}
# Resources {{{
$html = << "END";
<html>
    <body background="baroque.jpg">
        <a href="http://en.wikipedia.org/wiki/COBOL">COBOL</a><br />
        <a href="http://en.wikipedia.org/wiki/FORTRAN">FORTRAN</a><br />

        <img src="http://example.com/img/COBOL.bmp" title="COBOL rocks" />
        <img src="http://example.com/img/FORTRAN.bmp" title="FORTRAN rocks" />
    </body>
</html>
END

use HTML::RewriteAttributes::Resources;
my $cid = 0;
$html = HTML::RewriteAttributes::Resources->rewrite($html, sub {
    my $uri = shift;
    ++$cid;
    return "cid:$cid";
});

is($html, << "END", "rewrote the html correctly");
<html>
    <body background="cid:1">
        <a href="http://en.wikipedia.org/wiki/COBOL">COBOL</a><br />
        <a href="http://en.wikipedia.org/wiki/FORTRAN">FORTRAN</a><br />

        <img src="cid:2" title="COBOL rocks" />
        <img src="cid:3" title="FORTRAN rocks" />
    </body>
</html>
END
# }}}
# Links {{{
$html = << "END";
<html>
    <body background="baroque.jpg">
        <a href="http://en.wikipedia.org/wiki/COBOL">COBOL</a><br />
        <a href="http://en.wikipedia.org/wiki/FORTRAN">FORTRAN</a><br />

        <img src="http://example.com/img/COBOL.bmp" title="COBOL rocks" />
        <img src="http://example.com/img/FORTRAN.bmp" title="FORTRAN rocks" />
    </body>
</html>
END

use HTML::RewriteAttributes::Links;
my @links;
HTML::RewriteAttributes::Links->rewrite($html, sub {
    my ($tag, $attr, $value) = @_;
    push @links, $value;
    $value
});

is_deeply(\@links, [
    "baroque.jpg",
    "http://en.wikipedia.org/wiki/COBOL",
    "http://en.wikipedia.org/wiki/FORTRAN",
    "http://example.com/img/COBOL.bmp",
    "http://example.com/img/FORTRAN.bmp",
]);


$html = HTML::RewriteAttributes::Links->rewrite($html, "http://search.cpan.org");

is($html, << "END", "rewrote the html correctly");
<html>
    <body background="http://search.cpan.org/baroque.jpg">
        <a href="http://en.wikipedia.org/wiki/COBOL">COBOL</a><br />
        <a href="http://en.wikipedia.org/wiki/FORTRAN">FORTRAN</a><br />

        <img src="http://example.com/img/COBOL.bmp" title="COBOL rocks" />
        <img src="http://example.com/img/FORTRAN.bmp" title="FORTRAN rocks" />
    </body>
</html>
END
# }}}

