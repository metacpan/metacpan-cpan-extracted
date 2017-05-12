# perl Makefile.PL && nmake realclean && cls && perl Makefile.PL && nmake test

use strict;
use Test::More tests => 9;
BEGIN { $^W = 1 }

use_ok('HTML::Scrubber');

my $s    = HTML::Scrubber->new;
my $html = q[start <!--comment--> mid1 <?html pi> mid2 <?xml pi?> end];

isa_ok( $s, 'HTML::Scrubber' );

is( $s->comment, 0, 'comment off by default' );
is( $s->process, 0, 'process off by default' );
is( $s->scrub($html), 'start  mid1  mid2  end' );

$s->comment(1);
is( $s->comment, 1, 'comment on' );
is( $s->scrub($html), 'start <!--comment--> mid1  mid2  end', 'comment on' );

$s->process(1);
is( $s->process, 1, 'process on' );
is( $s->scrub($html), 'start <!--comment--> mid1 <?html pi> mid2 <?xml pi?> end', 'process on' );
