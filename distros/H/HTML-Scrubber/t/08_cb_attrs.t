use strict;
use warnings;
use Test::More;

use_ok('HTML::Scrubber');
use HTML::Scrubber;

my $scrubber = HTML::Scrubber->new;
$scrubber->default(1);

my $cb = sub {
    my ( $self, $tag, $attr, $avalue ) = @_;
    my %h = (
        drop  => [],
        bool  => [undef],
        empty => [''],
        foo   => ['bar'],
    );
    return @{ $h{$avalue} };
};

$scrubber->rules( p => { a => $cb } );
is( $scrubber->scrub('<p a="drop">'),  '<p>',         "correct result" );
is( $scrubber->scrub('<p a="bool">'),  '<p a>',       "correct result" );
is( $scrubber->scrub('<p a="empty">'), '<p a="">',    "correct result" );
is( $scrubber->scrub('<p a="foo">'),   '<p a="bar">', "correct result" );

done_testing;
