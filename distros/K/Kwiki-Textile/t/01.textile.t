#!/usr/bin/perl

use lib 't/lib';
use KwikiTextileTest;

plan tests => 1 * blocks;

run_is input => 'expected';

__END__
=== Test one
--- input textile_filter
h1. Heading

A _simple_ demonstration of Textile markup.

* One
* Two
* Three

"More information":http://www.textism.com/tools/textile is available.
--- expected chomp
<h1>Heading</h1>

<p>A <em>simple</em> demonstration of Textile markup.</p>

<ul>
<li>One</li>
<li>Two</li>
<li>Three</li>
</ul>

<p><a href="http://www.textism.com/tools/textile">More information</a> is available.</p>
