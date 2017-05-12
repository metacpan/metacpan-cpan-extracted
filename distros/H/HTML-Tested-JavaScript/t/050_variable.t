use strict;
use warnings FATAL => 'all';

use Test::More tests => 19;
use JSON::XS;

BEGIN { use_ok('HTML::Tested::JavaScript', qw(HTJ));
	use_ok("HTML::Tested::JavaScript::Variable");
	use_ok("HTML::Tested::Test");
};

package H;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget(::HTJ . "::Variable", "v");

package main;

my $obj = H->new({ v => "Hello" });
my $stash = {};
$obj->ht_render($stash);
is_deeply($stash, { v => "<script>//<![CDATA[\nvar v = \"Hello\";//]]>\n</script>" });

$obj->v("Hell\"o");
$obj->ht_render($stash);
is_deeply($stash, { v => "<script>//<![CDATA[\nvar v = \"Hell\\\"o\";//]]>\n</script>" });

$obj->v(0);
$obj->ht_render($stash);
is_deeply($stash, { v => "<script>//<![CDATA[\nvar v = 0;//]]>\n</script>" });

$obj->v(-5);
$obj->ht_render($stash);
is_deeply($stash, { v => "<script>//<![CDATA[\nvar v = -5;//]]>\n</script>" });

$obj->v(1);
$obj->ht_render($stash);
is_deeply($stash, { v => "<script>//<![CDATA[\nvar v = 1;//]]>\n</script>" });

$obj->v(undef);
$obj->ht_render($stash);
is_deeply($stash, { v => "<script>//<![CDATA[\nvar v = \"\";//]]>\n</script>" });

$obj->v("4a4");
$obj->ht_render($stash);
is_deeply($stash, { v => "<script>//<![CDATA[\nvar v = \"4a4\";//]]>\n</script>" });

$obj->v("4\t4");
$obj->ht_render($stash);
is_deeply($stash, { v => "<script>//<![CDATA[\nvar v = \"4\\t4\";//]]>\n</script>" });

my $et = HTML::Tested::JavaScript::Serializer::Extract_Text("v", $stash->{v});
is($et, "\"4\\t4\"");
is(JSON::XS->new->allow_nonref->decode($et), "4\t4");

$obj->v("4</Script>4");
$obj->ht_render($stash);
unlike($stash->{v}, qr#</Scr#);

$et = HTML::Tested::JavaScript::Serializer::Extract_Text("v", $stash->{v});
is(JSON::XS->new->allow_nonref->decode($et), $obj->v);
is(HTML::Tested::JavaScript::Serializer::Extract_JSON("v", $stash->{v})
	, $obj->v);
is(HTML::Tested::JavaScript::Serializer::Extract_JSON("j", $stash->{v}), undef);

$obj->v(0);
$obj->ht_render($stash);
is(HTML::Tested::JavaScript::Serializer::Extract_JSON("v", $stash->{v}), 0);

$obj->v("<A>G</A>");
$obj->ht_render($stash);
is_deeply([ HTML::Tested::Test->check_text(ref($obj), $stash->{v}, {
	v => "<A>G</A>" }) ], []) or exit 1;
