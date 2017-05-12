use strict;
use warnings;

use Test::More 0.88;

use Test::Requires {
    'HTML::Differences' => 0,
};

use HTML::Differences qw( html_text_diff );
use Markdent::Simple::Fragment;

## no critic (InputOutput::RequireCheckedSyscalls)
binmode $_, ':encoding(UTF-8)'
    for map { Test::Builder->new->$_ }
    qw( output failure_output todo_output );
## use critic

my $text = <<"EOF";
# \x{1f600} smiley face

Unicode in span - <span class="foo">\x{1f600} smiley face</span> - works

<h2>\x{1f600} smiley face</h2>
EOF

my $simple = Markdent::Simple::Fragment->new;
my $got = $simple->markdown_to_html( markdown => $text );

my $expect = <<"EOF";
<h1>\x{1f600} smiley face</h1>

<p>
Unicode in span - <span class="foo">\x{1f600} smiley face</span> - works
</p>

<h2>\x{1f600} smiley face</h2>
EOF

my $diff = html_text_diff( $got, $expect );
ok(
    !$diff,
    'got expected HTML containing Unicode characters as-is (not as entities)'
) or diag($diff);

done_testing;
