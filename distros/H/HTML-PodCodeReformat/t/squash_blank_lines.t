#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 2;

use HTML::PodCodeReformat;

my $f;
my $fixed_html;
my ( $html_code, $fixed_unaltered, $fixed_squashed )
    = split /^---\s*?\n/m, do { local $/; <DATA> };

$f = HTML::PodCodeReformat->new(
    squash_blank_lines => 1
);
$fixed_html = $f->reformat_pre( \$html_code );

is( $fixed_html, $fixed_squashed, 'Squashed' );

$f->squash_blank_lines(undef);
$fixed_html = $f->reformat_pre( \$html_code );

is( $fixed_html, $fixed_unaltered, 'Unaltered' )

__DATA__
<!-- HTML produced by a Pod transformer -->
<html>
<h1>SYNOPSIS</h1>
<pre>
    while (<>) {
        chomp;
        
        print;
    }
</pre>
<h1>DESCRIPTION</h1>
<p>Remove trailing newline from every line.</p>
</html>
---
<!-- HTML produced by a Pod transformer -->
<html>
<h1>SYNOPSIS</h1>
<pre>
while (<>) {
    chomp;
    
    print;
}
</pre>
<h1>DESCRIPTION</h1>
<p>Remove trailing newline from every line.</p>
</html>
---
<!-- HTML produced by a Pod transformer -->
<html>
<h1>SYNOPSIS</h1>
<pre>
while (<>) {
    chomp;

    print;
}
</pre>
<h1>DESCRIPTION</h1>
<p>Remove trailing newline from every line.</p>
</html>
---
