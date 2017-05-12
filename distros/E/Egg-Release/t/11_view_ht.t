use Test::More;
use strict;
use warnings;
use lib qw( ../lib ./lib );
use Egg::Helper;

my($page_title, $test_title, $port);

eval{ require HTML::Template };
if ($@) { plan skip_all => "HTML::Template is not installed." } else {

plan tests=> 48;

my $e= Egg::Helper->run('Vtest', {
  project_name=> 'HT',
  VIEW=> [
    [ HT => {
      path=> [qw/ \<e.dir.template> /],
      } ],
    ],
  });

$e->helper_create_files( $e->helper_yaml_load(join '', <DATA>) );

can_ok $e, 'view_manager';
  ok my $v= $e->view_manager, q{my $v= $e->view_manager};

can_ok $v, 'default';
  is $v->default, 'ht', q{$v->default, 'ht'};

can_ok $v, 'regists';
  ok my $reg= $v->regists, q{my $reg= $v->regists};
  isa_ok $reg, 'HASH';
  ok $reg->{ht}, q{$reg->{ht}};
  isa_ok $reg->{ht}, 'ARRAY';
  is $reg->{ht}[0], 'Egg::View::HT',
     q{$reg->{ht}[0], 'Egg::View::HT'};
  is $reg->{ht}[1], Egg::View::HT->VERSION,
     q{$reg->{ht}[1], Egg::View::HT->VERSION};

my $pkg= "$e->{namespace}::View::HT";
can_ok $pkg, 'config';
  ok my $c= $pkg->config, q{my $c= $pkg->config};
  isa_ok $c, 'HASH';
  isa_ok tied(%$reg), 'Tie::Hash::Indexed';
  isa_ok $c->{path}, 'ARRAY';
  is $c->{path}[0], $e->config->{dir}{template},
     q{$c->{path}[0], $e->config->{dir}{template}};

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
  ok -e "$c->{path}[0]/index.tt", q{"$c->{path}[0]/index.tt"};

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

}
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
 <head><title><TMPL_VAR NAME="page_title"></title></head>
 <body>
 <h1><TMPL_VAR NAME="test_title"></h1>
 <div>TEST OK</div>
 <p><TMPL_VAR NAME="server_port"></p>
 </body>
 </html>
