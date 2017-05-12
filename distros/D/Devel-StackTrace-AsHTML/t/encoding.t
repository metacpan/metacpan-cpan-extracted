use strict;
use Test::More;
use Devel::StackTrace::AsHTML;

my $t = Devel::StackTrace->new(message => "\x{30c6}");
my $html = $t->as_html;

like $html, qr/Error: &#12486;/;

done_testing;
