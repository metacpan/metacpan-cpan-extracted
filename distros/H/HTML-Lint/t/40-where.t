#!perl

use strict;
use warnings;

use lib 't/';
use Util;

my $html = '</body>';

checkit( [
    [ 'elem-unopened'    => 'Set #1 (1:1) </body> with no opening <body>' ],
    [ 'doc-tag-required' => 'Set #1 (1:1) <body> tag is required' ],
    [ 'doc-tag-required' => 'Set #1 (1:1) <head> tag is required' ],
    [ 'doc-tag-required' => 'Set #1 (1:1) <html> tag is required' ],
    [ 'doc-tag-required' => 'Set #1 (1:1) <title> tag is required' ],
], [$html] );

__END__
This doesn't test the error finding as much as the where() method.
It fixes the following bug:

Date: Mon, 22 Dec 2003 22:07:54 -0800
From: Adam Monsen <adamm@wazamatta.com>
To: Andy Lester <andy@petdance.com>
Subject: HTML::Lint::Error bug

The following demonstrates a bug in HTML::Lint that is seen when an
offending tag is flush left ...

use HTML::Lint;
my $lint = HTML::Lint->new();
$lint->parse('</body>');
warn $_->as_string."\n" for $lint->errors;

The warning I'm getting looks like this:
Argument "" isn't numeric in addition (+) at /usr/lib/perl5/site_perl/5.8.1/HTML/Lint/Error.pm line 176.

If I change the parse() call as follows (by adding a leading space):
$lint->parse(' </body>');

the warning disappears.
