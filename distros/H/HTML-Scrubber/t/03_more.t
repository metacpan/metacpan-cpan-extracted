# perl Makefile.PL && nmake realclean && cls && perl Makefile.PL && nmake test
# cpan-upload -mailto yo@yo.yo -verbose -user podmaster HTML-Scrubber-0.04.tar.gz

use strict;
use Test::More tests => 7;
BEGIN { $^W = 1 }

use_ok('HTML::Scrubber');

my $s    = HTML::Scrubber->new;
my $html = q[<a href=1>link </a><br><B> bold </B><U> UNDERLINE </U>];

isa_ok( $s, 'HTML::Scrubber' );

$s->rules( 'font' => { face => 1 } );

is( $s->scrub('<font face="gothic">'), '<font face="gothic">', 'font face gothic' );

$s->allow(qw[ U ]);

#use Data::Dumper;warn $/,Dumper($s);

is( $s->scrub($html), q[link  bold <u> UNDERLINE </u>], 'only U' );

$s->allow(qw[ B U ]);

#use Data::Dumper;warn $/,Dumper($s);

is( $s->scrub($html), q[link <b> bold </b><u> UNDERLINE </u>], 'B and U' );

$s->allow(qw[ A B ]);
$s->deny('U');
$s->default( 0, { '*' => 1 } );

#use Data::Dumper;warn $/,Dumper($s);

is( $s->scrub($html), q[<a href="1">link </a><b> bold </b> UNDERLINE ], 'A and B' );

$s = HTML::Scrubber->new( default => [ 1, { '*' => 1 } ] );

is( $s->scrub($html), q[<a href="1">link </a><br><b> bold </b><u> UNDERLINE </u>], 'A B U and BR' );

#use Data::Dumper;warn $/,Dumper($s);
