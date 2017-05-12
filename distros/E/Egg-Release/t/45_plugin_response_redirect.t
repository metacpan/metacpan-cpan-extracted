use Test::More tests=> 14;
use lib qw( ./lib ../lib );
use Egg::Helper;

ok my $e= Egg::Helper->run
   ( Vtest=> { vtest_plugins=> [qw/ Response::Redirect /] }), q{load plugin.};

ok my $c= $e->config->{plugin_response_redirect},
   q{my $c= $e->config->{plugin_response_redirect}};
  is $c->{default_url}, '/', q{$c->{default_url}, '/'};
  is $c->{default_wait}, 0, q{$c->{default_wait}, 0};
  is $c->{default_msg}, 'Processing was completed.',
     q{$c->{default_msg}, 'Processing was completed.'};
  ok $c->{style}{body}, q{$c->{style}{body}};
  ok $c->{style}{h1}, q{$c->{style}{h1}};
  ok $c->{style}{div}, q{$c->{style}{div}};

can_ok $e, 'redirect_body';
  ok $e->redirect_body, q{$e->redirect_body};
  ok $e->finished, q{$e->finished};
  is $e->res->status, 200, q{$e->res->status, 200};
  ok my $body= $e->res->body, q{my $body= $e->res->body};
  like $$body, qr{<meta http-equiv=\"refresh\" content="0;url=/" />},
     '$$body, qr{<meta http-equiv= ... ';

