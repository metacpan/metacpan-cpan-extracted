# test the docs in TT.pm

use Test::More tests => 2;

use Inline TT => 'DATA';

my $hello_out = hello( { name => 'Rob' } );

is( $hello_out, '<H1> Hello Rob, how are you? </H1>', 'call of hello' );

my $bye_out = goodbye( { name => 'Mr. Mitchell' } );

is( $bye_out,
	'<H1> Goodbye Mr. Mitchell, have a nice day. </H1>',
	'call of bye' );

__DATA__
__TT__
[% BLOCK hello %]
    <H1> Hello [% name %], how are you? </H1>
[% END %]
[% BLOCK goodbye %]
	<H1> Goodbye [% name %], have a nice day. </H1>
[% END %]

