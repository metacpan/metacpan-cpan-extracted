# test the docs in TT.pm

use Test::More tests => 1;

use Inline TT => 'DATA';

my $output = simple( { names => ['Rob', 'Derek'] } );

is( $output,
	"Hello Rob and Derek, how are you?",
	'passing array ref');

__DATA__
__TT__
[% BLOCK simple %]
Hello [% names.join(' and ') %], how are you?
[% END %]
