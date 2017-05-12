use strict;
use Test::More;
use Devel::StackTrace::AsHTMLExtended;

my $t = Devel::StackTrace->new(message => "\x{30c6}");
my $html = $t->as_html_extended;

like $html, qr/Error: &#12486;/;

done_testing;
