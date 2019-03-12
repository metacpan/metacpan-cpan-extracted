use strict;
use warnings;

use Test::More;

use HTML::Restrict;

my $before = <<'EOF';
two element open & close break<br></br>
one element open & close break <br />
one element open & close break no space<br/>
EOF

my $after = <<'EOF';
two element open &amp; close break<br></br>
one element open &amp; close break <br>
one element open &amp; close break no space<br>
EOF

my $hr = HTML::Restrict->new(
    trim  => 0,
    rules => {
        br => [],
    },
);

my $got = $hr->process($before);

is( $got, $after, '<br/> preserved' );

done_testing();
