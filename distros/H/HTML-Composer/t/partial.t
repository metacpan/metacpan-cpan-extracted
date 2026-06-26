use strict;
use warnings;

use lib '../lib';

use HTML::Composer;
use Test::More;

my $h = HTML::Composer->new();

my $html = $h->partial( [ div => ["Hello, World!"] ] );
is $html, '<div>Hello, World!</div>', 'basic partial renders correctly';

$html = $h->partial( [ div => { class => 'foo' } => ["Bar"] ] );
is $html, '<div class="foo">Bar</div>',
  'partial with attributes renders correctly';

$html = $h->partial(
    [
        div => [
            "Hello, World!",
            a => { href => "https://www.google.com" } => ["www.google.com"]
        ]
    ]
);
is $html,
  '<div>Hello, World!<a href="https://www.google.com">www.google.com</a></div>',
  'partial with nested elements renders correctly';

$html = $h->partial(
    [
        ul => [
            li => ["One"],
            li => ["Two"],
            li => ["Three"],
        ]
    ]
);
is $html, '<ul><li>One</li><li>Two</li><li>Three</li></ul>',
  'partial with multiple children renders correctly';

$html = $h->partial( [ div => [ "before", br => {}, "after" ] ] );
is $html, '<div>before<br>after</div>',
  'partial containing a void element renders correctly';

eval { $h->partial("not an array") };
like $@, qr/partial expects/, 'partial croaks on non-array argument';

eval { $h->partial( { div => [] } ) };
like $@, qr/partial expects/, 'partial croaks on hashref argument';

done_testing;
