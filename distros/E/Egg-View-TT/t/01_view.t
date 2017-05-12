use Test::More tests=> 51;
use lib qw( ../lib ./lib );
use strict;
use warnings;
use Egg::Helper;

my($page_title, $test_title, $port);

ok my $e= Egg::Helper->run('vtest', {
 VIEW=> [
   [ TT => {
     INCLUDE_PATH=> ['\<e.dir.template>'],
     TEMPLATE_EXTENSION=> '.tt',
     } ],
     ],
 }), 'Constructor';

$e->helper_create_files( $e->helper_yaml_load(join '', <DATA>) );

my $pkg= "$e->{namespace}::View::TT";
can_ok $pkg, 'config';
  ok my $c= $pkg->config, q{my $c= $pkg->config};
  isa_ok $c, 'HASH';
  isa_ok $c->{INCLUDE_PATH}, 'ARRAY';
  is $c->{TEMPLATE_EXTENSION}, '.tt', q{$c->{TEMPLATE_EXTENSION}, '.tt'};
  is $c->{ABSOLUTE}, 1, q{$c->{ABSOLUTE}, 1};
  is $c->{RELATIVE}, 1, q{$c->{RELATIVE}, 1};

can_ok $e, 'view_manager';
  ok my $v= $e->view_manager, q{my $v= $e->view_manager};

can_ok $v, 'default';
  is $v->default, 'tt', q{$v->default, 'tt'};

can_ok $v, 'regists';
  ok my $reg= $v->regists, q{my $reg= $v->regists};
  isa_ok $reg, 'HASH';
  isa_ok tied(%$reg), 'Tie::Hash::Indexed';
  ok $reg->{tt}, q{$reg->{tt}};
  isa_ok $reg->{tt}, 'ARRAY';
  is $reg->{tt}[0], 'Egg::View::TT',
     q{$reg->{tt}[0], 'Egg::View::TT'};
  is $reg->{tt}[1], Egg::View::TT->VERSION,
     q{$reg->{tt}[1], Egg::View::TT->VERSION};

ok $page_title= $e->page_title('TEST PAGE'),
   q{$page_title= $e->page_title('TEST PAGE')};
ok $test_title= $e->stash( test_title => 'VIEW TEST' ),
   q{$test_title= $e->stash( test_title => 'VIEW TEST' )};

can_ok $e, 'view';
  ok my $view= $e->view, q{my $view= $e->view};
  ok $port= $view->param( server_port => $e->request->port ),
     q{$port= $view->param( server_port => $e->request->port )};

can_ok $view, 'e';
  is $view->e, $e, q{$view->e, $e};

can_ok $view, 'template';
  can_ok $e, 'template';
  ok $e->template('index.tt'), q{$e->template('index.tt')};
  is $view->template, 'index.tt', q{$view->template, 'index.tt'};
  ok -e "$c->{INCLUDE_PATH}[0]/index.tt", q{"$c->{INCLUDE_PATH}[0]/index.tt"};

can_ok $view, 'render';
  ok my $html= $view->render($view->template),
     q{my $html= $view->render($view->template)};
  isa_ok $html, 'SCALAR';
  body_check($html);

can_ok $view, 'output';
  ok ! $e->res->clear_body, q{$e->res->clear_body};
  ok ! $e->res->body, q{! $e->res->body};
  ok $html= $view->output, q{$html= $view->output};
  isa_ok $html, 'SCALAR';
  is $html, $e->res->body, q{$html, $e->res->body};
  body_check($html);

sub body_check {
	my($body)= @_;
	like $$body, qr{<html>.+?</html>}s, q{qr{<html>.+?</html>}s};
	like $$body, qr{<title>$page_title</title>}s, q{qr{<title>$page_title</title>}s};
	like $$body, qr{<h1>$test_title</h1>}s, q{qr{<h1>$test_title</h1>}s};
	like $$body, qr{<div>TEST OK</div>}s, q{qr{<div>TEST OK</div>}s};
	like $$body, qr{<p>$port</p>}s, q{qr{<p>$port</p>}s};
}

__DATA__
---
filename: root/index.tt
value: |
 <html>
 <head><title>[% e.page_title %]</title></head>
 <body>
 <h1>[% s.test_title %]</h1>
 <div>TEST OK</div>
 <p>[% p.server_port %]</p>
 </body>
 </html>
