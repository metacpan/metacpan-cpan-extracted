#!perl -T

use 5.010001;
use strict;
use warnings;

use Test::More tests => 3;

use HTML::Tidy5;
my $html = do { local $/ = undef; <DATA>; };

my $tidy = HTML::Tidy5->new;
isa_ok( $tidy, 'HTML::Tidy5' );
$tidy->clean( $html );
isa_ok( $tidy, 'HTML::Tidy5' );
pass( 'Cleaned OK' );

exit 0;

__DATA__
<form action="http://www.alternation.net/cobra/index.pl">
<td><input name="random" type="image" value="random creature" src="http://www.creaturesinmyhead.com/images/random.gif"></td>
</form>
