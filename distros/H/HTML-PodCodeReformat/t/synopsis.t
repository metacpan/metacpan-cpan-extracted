#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 1;

use HTML::PodCodeReformat;

my $f = HTML::PodCodeReformat->new;
my $fixed_html = $f->reformat_pre( *DATA );

chomp( my $expected = <<'HTML' );
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
HTML

is( $fixed_html, $expected, 'Simple HTML reformat' )

# Don't add anything to DATA, not even a newline!
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