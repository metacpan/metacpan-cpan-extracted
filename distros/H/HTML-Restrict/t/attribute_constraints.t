use strict;
use warnings;

use Test::More;
use HTML::Restrict;

my $hr = HTML::Restrict->new(
    rules => {
        iframe => [
            qw( width height ),
            {
                src         => qr{^http://www\.youtube\.com},
                frameborder => qr{^(0|1)$},
            }
        ],
    },
);

cmp_ok(
    $hr->process(
        '<iframe width="560" height="315" frameborder="0" src="http://www.youtube.com/embed/9gKeRZM2Iyc"></iframe>'
    ),
    'eq',
    '<iframe width="560" height="315" frameborder="0" src="http://www.youtube.com/embed/9gKeRZM2Iyc"></iframe>',
    'all constraints pass',
);

cmp_ok(
    $hr->process(
        '<iframe width="560" height="315" src="http://www.hostile.com/" frameborder="0"></iframe>'
    ),
    'eq',
    '<iframe width="560" height="315" frameborder="0"></iframe>',
    'one constraint fails',
);

cmp_ok(
    $hr->process(
        '<iframe width="560" height="315" src="http://www.hostile.com/" frameborder="A"></iframe>'
    ),
    'eq',
    '<iframe width="560" height="315"></iframe>',
    'two constraints fail',
);

$hr = HTML::Restrict->new(
    rules => {
        iframe => [
            { src         => qr{^http://www\.youtube\.com} },
            { frameborder => qr{^(0|1)$} },
            { height      => qr{^315$} },
            { width       => qr{^560$} },
        ],
    },
);

cmp_ok(
    $hr->process(
        '<iframe width="560" height="315" frameborder="0" src="http://www.youtube.com/embed/9gKeRZM2Iyc"></iframe>'
    ),
    'eq',
    '<iframe src="http://www.youtube.com/embed/9gKeRZM2Iyc" frameborder="0" height="315" width="560"></iframe>',
    'possible to maintain order',
);

cmp_ok(
    $hr->process(
        q[<iframe src="http://www.youtube.com/&quot; onclick=&quot;alert('hi')"></iframe>]
    ),
    'eq',
    q[<iframe src="http://www.youtube.com/&quot; onclick=&quot;alert(&#39;hi&#39;)"></iframe>],
    'entities are re-encoded when regex match passes',
);

$hr = HTML::Restrict->new(
    rules => {
        span => [
            {
                style => sub {
                    my $value = shift;
                    my @values;
                    while ( $value
                        =~ /(?:\A|;)\s*([a-z-]+)\s*:\s*([^;\n]+?)\s*(?=;|$)/gc
                    ) {
                        my ( $prop, $prop_value ) = ( $1, $2 );
                        if (   $prop =~ /\A(?:margin|padding)\z/
                            && $prop_value =~ /\A\d+(?:em|px|)\z/ ) {
                            push @values, "$prop: $prop_value";
                        }
                    }
                    return
                        unless @values;
                    return join '; ', @values;
                }
            },
            {
                class => sub { return undef }
            },
        ],
    },
);

cmp_ok(
    $hr->process(
        '<span class="fish" style="margin: 2px; padding: 7px;border: 2px;">content</span>',
    ),
    'eq',
    '<span style="margin: 2px; padding: 7px">content</span>',
    'filter attributes by coderef',
);

done_testing;
