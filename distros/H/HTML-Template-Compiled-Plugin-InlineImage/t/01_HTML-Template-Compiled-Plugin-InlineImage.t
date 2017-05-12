# $Id: 01_HTML-Template-Compiled-Plugin-InlineImage.t,v 1.4 2006/08/27 10:22:10 tinita Exp $
use Test::More tests => 2;
use blib;
use HTML::Template::Compiled;
use MIME::Base64;
BEGIN { use_ok('HTML::Template::Compiled::Plugin::InlineImage') }

my $htc = HTML::Template::Compiled->new(
    scalarref => \qq{<%= foo escape=INLINE_IMG_PNG %>},
    plugin    => [qw(HTML::Template::Compiled::Plugin::InlineImage)],
);
my $gd_mock = bless {}, "GD::Image";
sub GD::Image::png { return "foo" }
sub GD::Image::getBounds  { return 42,42 }
my $encoded = encode_base64( GD::Image::png() );
$htc->param( foo => $gd_mock );
my $out = $htc->output;

#print $out, $/;
cmp_ok(
    $out, 'eq',
    qq{src="data:image/png;base64,$encoded" width="42" height="42"},
    "Simple INLINE_IMG_PNG test"
);

