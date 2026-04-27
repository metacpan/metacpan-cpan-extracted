use strict;
use warnings;
use Test2::V0;

use Langertha::Knarr::Response;
use Langertha::Response;
use Langertha::ToolCall;

subtest 'plain string coerces to content' => sub {
  my $r = Langertha::Knarr::Response->coerce('hello');
  isa_ok $r, ['Langertha::Knarr::Response'];
  is $r->content, 'hello';
  is $r->model, undef;
  is $r->tool_calls, [];
  ok !$r->has_tool_calls;
};

subtest 'hashref coerces with content+model' => sub {
  my $r = Langertha::Knarr::Response->coerce({ content => 'hi', model => 'm1' });
  is $r->content, 'hi';
  is $r->model, 'm1';
};

subtest 'undef coerces to empty response' => sub {
  my $r = Langertha::Knarr::Response->coerce(undef);
  is $r->content, '';
};

subtest 'self passes through' => sub {
  my $r = Langertha::Knarr::Response->new( content => 'x', model => 'm' );
  my $r2 = Langertha::Knarr::Response->coerce($r);
  is $r2, $r, 'same instance';
};

subtest 'Langertha::Response is unwrapped' => sub {
  my $tc = Langertha::ToolCall->new( id => 'c1', name => 'lookup', arguments => { q => 'x' } );
  my $lr = Langertha::Response->new(
    content       => 'lresp',
    model         => 'gpt-4o',
    tool_calls    => [ $tc ],
    finish_reason => 'tool_calls',
  );
  my $r = Langertha::Knarr::Response->coerce($lr);
  isa_ok $r, ['Langertha::Knarr::Response'];
  is $r->content, 'lresp';
  is $r->model, 'gpt-4o';
  is $r->finish_reason, 'tool_calls';
  ok $r->has_tool_calls;
  is $r->tool_calls->[0]->name, 'lookup';
};

subtest 'foreign blessed object stringifies into content' => sub {
  my $obj = bless { x => 1 }, 'Some::Foreign::Thing';
  {
    no strict 'refs';
    *{'Some::Foreign::Thing::('}    = sub { 1 };
    *{'Some::Foreign::Thing::(""'}  = sub { 'stringified' };
    *{'Some::Foreign::Thing::()'}   = sub {};
  }
  use overload;
  bless $obj, 'Some::Foreign::Thing';
  my $r = Langertha::Knarr::Response->coerce("$obj");
  is $r->content, 'stringified';
};

subtest 'tool_calls default empty arrayref' => sub {
  my $r = Langertha::Knarr::Response->new( content => 'x' );
  is $r->tool_calls, [];
  ok !$r->has_tool_calls;
};

done_testing;
