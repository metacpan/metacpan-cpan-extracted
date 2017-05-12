#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 1;

use HTML::PodCodeReformat;

my $html = do { local $/; <DATA> };
my $f = HTML::PodCodeReformat->new;
my $fixed_html = $f->reformat_pre( \$html );

is( $fixed_html, $html, 'First line only indented block' )

__DATA__
<!-- HTML produced by a Pod transformer -->
<html>
<h1>SYNOPSIS</h1>
<pre>
                           columns
<------------------------------------------------------------>
<----------><------><---------------------------><----------->
 leftMargin  indent  text is formatted into here  rightMargin
</pre>
<h1>DESCRIPTION</h1>
<p>Remove trailing newline from every line.</p>
</html>
