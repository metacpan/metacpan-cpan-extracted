# perl Makefile.PL && nmake realclean && cls && perl Makefile.PL && nmake test

use strict;
use Test::More tests => 9;
BEGIN { $^W = 1 }

use_ok('HTML::Scrubber');

my $s    = HTML::Scrubber->new;
my $html = q[start <style>in the style</style> middle <script>in the script</script> end];

isa_ok( $s, 'HTML::Scrubber' );

is( $s->script,       0,                    'script off by default' );
is( $s->style,        0,                    'style off by default' );
is( $s->scrub($html), 'start  middle  end', 'default (no style no script)' );

$s->script(1);
is( $s->script, 1, 'script on' );
is( $s->scrub($html), 'start  middle in the script end', 'script off' );

$s->style(1);
is( $s->style, 1, 'style on' );
is( $s->scrub($html), 'start in the style middle in the script end', 'style off and script off' );
