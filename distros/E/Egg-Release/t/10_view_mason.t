use Test::More;
use strict;
use warnings;
use lib qw( ../lib ./lib );
use Egg::Helper;

my($page_title, $test_title, $port);

eval{ require HTML::Mason };
if ($@) { plan skip_all => "HTML::Mason is not installed." } else {

plan tests=> 51;

my $e= Egg::Helper->run('vtest', {
 VIEW=> [
   [ Mason => {
     comp_root=> [
       [ main   => '\<e.dir.template>' ],
       [ private=> '\<e.dir.comp>' ],
       ],
     data_dir=> '\<e.dir.tmp>',
     } ],
   ],
 });

$e->helper_create_files( $e->helper_yaml_load(join '', <DATA>) );

my $pkg= "$e->{namespace}::View::Mason";
can_ok $pkg, 'config';
  ok my $c= $pkg->config, q{my $c= $pkg->config};
  isa_ok $c, 'HASH';
  isa_ok $c->{comp_root}, 'ARRAY';
  isa_ok $c->{comp_root}[0], 'ARRAY';
  is $c->{comp_root}[0][1], $e->config->{dir}{template},
     q{$c->{comp_root}[0][1], $e->config->{dir}{template}};
  is $c->{comp_root}[1][1], $e->config->{dir}{comp},
     q{$c->{comp_root}[1][1], $e->config->{dir}{comp}};
  is $c->{data_dir}, $e->config->{dir}{tmp},
     q{$c->{data_dir}, $e->config->{dir}{tmp}};

can_ok $e, 'view_manager';
  ok my $v= $e->view_manager, q{my $v= $e->view_manager};

can_ok $v, 'default';
  is $v->default, 'mason', q{$v->default, 'mason'};

can_ok $v, 'regists';
  ok my $reg= $v->regists, q{my $reg= $v->regists};
  isa_ok $reg, 'HASH';
  isa_ok tied(%$reg), 'Tie::Hash::Indexed';
  ok $reg->{mason}, q{$reg->{mason}};
  isa_ok $reg->{mason}, 'ARRAY';
  is $reg->{mason}[0], 'Egg::View::Mason',
     q{$reg->{mason}[0], 'Egg::View::Mason'};
  is $reg->{mason}[1], Egg::View::Mason->VERSION,
     q{$reg->{mason}[1], Egg::View::Mason->VERSION};

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
  ok -e "$c->{comp_root}[0][1]/index.tt", q{"$c->{comp_root}[0][1]/index.tt"};

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
 <head><title><% $e->page_title %></title></head>
 <body>
 <h1><% $s->{test_title} %></h1>
 <div>TEST OK</div>
 <p><% $p->{server_port} %></p>
 </body>
 </html>
