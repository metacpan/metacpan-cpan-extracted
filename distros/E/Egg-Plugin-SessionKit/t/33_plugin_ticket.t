use Test::More;
use lib qw( ../lib ./lib );
use Egg::Helper;

eval { require Cache::FileCache };
if ($@) { plan skip_all => "Cache::FileCache is not installed." } else {
	&test;
}
sub test {

plan tests=> 31;

my $tool = Egg::Helper->helper_tools;
my $root = $tool->helper_tempdir. '/Vtest';

$tool->helper_create_file
  ($tool->helper_yaml_load(join '', <DATA>), { root=> $root });

my $e= Egg::Helper->run( vtest=> {
  vtest_root=> $root,
  vtest_config=> { MODEL=> ['Session'] },
  });

ok my $ss= $e->model('session_test'), q{$ss= $e->model('session_test')};

can_ok $ss, 'context';
  isa_ok $ss->context, 'Egg::Model::Session::Plugin::Ticket';

can_ok $ss->context, 'ticket';
  $e->request->path('/hooo');
  ok my $hooo= $ss->ticket(1), q{my $hooo= $ss->ticket(1)};
  isa_ok $ss->{_session_ticket}, 'HASH';
  isa_ok $ss->{_session_ticket}{'/hooo'}, 'ARRAY';
  is $ss->{_session_ticket}{'/hooo'}[0], $hooo, q{$ss->{_session_ticket}{'/hooo'}[0], $hooo};

  $e->request->path('/hoge');
  ok my $hoge= $ss->ticket(1), q{my $ticket= $ss->ticket(1)};
  is $ss->{_session_ticket}{'/hoge'}[0], $hoge, q{$ss->{_session_ticket}{'/hoge'}[0], $hoge};

  ok my $myticket= $ss->ticket( myticket => 1 ), q{my $myticket= $ss->ticket( myticket => 1 )};
  is $ss->{_session_ticket}{myticket}[0], $myticket, q{$ss->{_session_ticket}{myticket}[0], $myticket};

  $e->request->path('/hooo');
  is $ss->ticket, $hooo, q{$ss->ticket, $hooo};

  $e->request->path('/hoge');
  is $ss->ticket, $hoge, q{$ss->ticket, $hoge};

  is $ss->ticket('myticket'), $myticket, q{$ss->ticket('myticket'), $myticket};

can_ok $ss->context, 'valid_ticket';
  ok $ss->valid_ticket($hooo), q{$ss->valid_ticket($hooo)};
  ok $ss->valid_ticket($hoge), q{$ss->valid_ticket($hoge)};
  ok $ss->valid_ticket($myticket), q{$ss->valid_ticket($myticket)};
  ok ! $ss->valid_ticket('badticket'), q{! $ss->valid_ticket('badticket')};

can_ok $ss->context, 'ticket_check';
  $e->request->path('/hooo');
  ok $ss->ticket_check($hooo), q{$ss->ticket_check($hooo)};

  $e->request->path('/hoge');
  ok $ss->ticket_check($hoge), q{$ss->ticket_check($hoge)};

  ok $ss->ticket_check( myticket => $myticket ), q{$ss->ticket_check( myticket => $myticket )};

can_ok $ss->context, 'ticket_remove';
  $e->request->path('/hooo');
  ok $ss->ticket_remove, q{$ss->ticket_remove};
  ok ! $ss->ticket, q{! $ss->ticket};

can_ok $ss->context, 'ticket_clear';
  ok my $count= $ss->ticket_clear, q{$ss->ticket_clear};
  is $count, 2, q{$count, 2};

can_ok $ss->context, 'ticket_purge';

}

__DATA__
filename: <e.root>/lib/Vtest/Model/Session/Test.pm
value: |
  package Vtest::Model::Session::Test;
  use strict;
  use warnings;
  use base qw/ Egg::Model::Session::Manager::Base /;
  
  __PACKAGE__->config(
    label_name => 'session_test',
    );
  
  __PACKAGE__->startup qw/
    Plugin::Ticket
    ID::SHA1
    Bind::Cookie
    Base::FileCache
    /;
  
  package Vtest::Model::Session::Test::TieHash;
  use strict;
  use warnings;
  use base qw/ Egg::Model::Session::Manager::TieHash /;
  
  1;
