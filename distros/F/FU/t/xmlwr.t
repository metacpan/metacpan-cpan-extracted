use v5.36;
use Test::More;
use FU::XMLWriter qw/:html5_ fragment/;

is fragment {}, '';
is fragment { lit_ '<hi>'; txt_ '<hi>' }, '<hi>&lt;hi>';
is fragment { tag_ 'br', undef }, '<br />';
is fragment { tag_ 'a', href => '/&ops', 't&xt' }, '<a href="/&amp;ops">t&amp;xt</a>';
is fragment { a_ href => '/&ops', 't&xt' }, '<a href="/&amp;ops">t&amp;xt</a>';
is fragment { txt_ "\x{1f973}" }, '🥳';

ok !eval { lit_ 'hi'; 1 };
ok !eval { txt_ 'hi'; 1 };
ok !eval { a_ 'hi'; 1 };

is fragment {
    ok !eval { a_; 1 };
    ok !eval { lit_; 1 };
    ok !eval { tag_ 'é'; 1 };
    ok !eval { tag_ ';'; 1 };
    ok !eval { tag_ ''; 1 };
    ok !eval { tag_ 'a', 'é', 1, 1 };
    ok !eval { tag_ 'a', ';', 1, 1 };
    ok !eval { tag_ 'a', '', 1, 1 };
    ok !eval { a_ undef, 1, 1 };
    ok !eval { a_ [], 1, 1 };
}, '<a<a<a<a<a';  # Arguably a bug, but rolling back earlier writes on error seems not worth the effort.

is fragment {
    tag_ 'customTag', 1;
    tag_ 'custom-selfclose', undef;
}, '<customTag>1</customTag><custom-selfclose />';

is fragment { div_ x => 1, '+' => 2, '+', 3, undef }, '<div x="1 2 3" />';
is fragment { div_ x => 1, '+' => 2, '+', undef, undef }, '<div x="1 2" />';
is fragment { div_ x => 1, '+' => undef, '+', 3, undef }, '<div x="1 3" />';
is fragment { div_ x => 1, '+' => undef, y => undef, '+', 3, undef }, '<div x="1" y="3" />';
is fragment { div_ x => undef, '+' => undef, y => undef, '+', 3, undef }, '<div y="3" />';
is fragment { div_ x => undef, '+' => undef, '+', 1, undef }, '<div x="1" />';

ok !eval { fragment { div_ '+' => 1, undef } };

sub lit { lit_ "<ok\x{1f973}ay>"; }

sub t {
    is $_[0], 'arg';
    div_ attr1 => $_[0], sub {
        is $_[0], 'arg';

        span_ 'ab" < c &< d';
        span_ \&lit;

        is fragment(\&lit), "<ok🥳ay>";

        is fragment {
            is fragment { br_ }, '<br />';
        }, '';

        eval { fragment { tag_ '<oops>', '' } };
        like $@, qr/Invalid tag or attribute name/;

        txt_ "\x{1f973}";
    };
}

is fragment { t 'arg' }, '<div attr1="arg"><span>ab&quot; &lt; c &amp;&lt; d</span><span><ok🥳ay></span>🥳</div>';

ok !eval { fragment { tag_ 'hi', \1 } };
like $@, qr/Invalid attempt to output bare reference/;

ok !eval { fragment { tag_ 'hi', {} } };
like $@, qr/Invalid attempt to output bare reference/;

is fragment { tag_ 'hi', bless {}, 'XTEST1' }, '<hi>string</hi>';
like fragment { tag_ 'hi', bless {}, 'XTEST2' }, qr{<hi>HASH\(.*\)</hi>}; # Yeah, whatever.
like fragment { tag_ 'hi', ''.{} }, qr{<hi>HASH\(.*\)</hi>};

done_testing;


package XTEST1;
use overload '""' => sub { 'string' };

package XTEST2;
use overload '""' => sub { {} };
