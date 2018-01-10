#!perl -Tw

use strict;
use warnings;

use Test::More tests => 1;

use HTML::Lint;
use HTML::Lint::Error;
use Test::HTML::Lint;


my $lint = HTML::Lint->new();
$lint->only_types( HTML::Lint::Error::FLUFF );

# This code is invalid, but the linter should ignore it
my $chunk = << 'END';
<P><TABLE>This is a fine chunk of code</P>
END

html_ok( $lint, $chunk, 'STRUCTUREally naughty code passed' );
