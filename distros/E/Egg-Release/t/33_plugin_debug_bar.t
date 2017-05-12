use Test::More tests=> 7;
use lib qw( ../lib ./lib );
use Egg::Helper;

my $template= <<END_TEMPLATE;
<html>
<body>
<h1>TEST</h1>
</body>
</html>
END_TEMPLATE

ok my $e= Egg::Helper->run( Vtest => {
  vtest_plugins=> [qw/ -Debug Debug::Bar /],
  }), 'Constructor';

isa_ok $e, 'Egg::Plugin::Debug::Bar';

ok $e->debug, q{$e->debug};
ok $e->response->body($template), q{$e->response->body($template)};
ok $e->helper_stdout(sub { $e->_output }), q{$e->_output};
ok my $body= $e->response->body, q{my $body= $e->response->body};
like $$body, qr{<div id=\"debug_bar\">.+</div>}s, q{$$body, qr{<div id="debug_bar">.+</div>}};

