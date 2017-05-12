# test the docs in TT.pm

use Test::More tests => 2;

use Inline (
    TT         => 'DATA',
    PRE_CHOMP  => 1,
    POST_CHOMP => 1,
);

my $output = simple( { name => 'Rob' } );

is( $output,
	"<H1>Greetings!</H1>Hello Rob, how are you?",
	'simple include without data pass');

$output = data_pass( { name => 'Rob' } );

is( $output,
	'<H1>Hello Rob, how are you?</H1>',
	'include with regular pass' );

__DATA__
__TT__
[% BLOCK simple %]
[% INCLUDE 't/header.tt' %]
Hello [% name %], how are you?
[% END %]

[% BLOCK data_pass %]
[% INCLUDE 't/datarec.tt' %]
[% END %]
