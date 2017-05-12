use Test::More tests => 1;

use Graphics::Primitive::CSS;

my $styler = Graphics::Primitive::CSS->new(
    styles => '.foo { background-color: #fff }'
);
ok(defined($styler->css_dom), 'got css dom');