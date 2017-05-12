use strict;
use warnings;

use Global::Context -all, '$Context';

use Global::Context::AuthToken::Basic;
use Global::Context::Terminal::Basic;

use Test::More;
use Test::Fatal;

ctx_init({
  terminal => Global::Context::Terminal::Basic->new({ uri => 'ip://1.2.3.4' }),
  auth_token => Global::Context::AuthToken::Basic->new({
    uri   => 'websession://1234',
    agent => 'customer://abcdef',
  }),
});

like(
  exception { ctx_init({}) },
  qr/already/,
  "we can't ctx_init twice",
);

{
  my @frames = map {; $_->as_string } $Context->stack->frames;
  is(@frames, 1, "there's one frame, to start with");
  like($frames[0], qr/^context initialized/, '...it is the ctx_init frame');

  is(
    $Context->auth_token->agent,
    'customer://abcdef',
    '...the agent we specified'
  );

  is(
    $Context->auth_token->uri,
    'websession://1234',
    '...the token we specified',
  );

  is(
    $Context->auth_token->as_string,
    'websession://1234',
    '...the token stringification we expect',
  );

  is(
    $Context->terminal->as_string,
    'ip://1.2.3.4',
    '...the terminal stringification we expect',
  );
}

{
  local $Context = ctx_push("eat some pie");

  {
    my @frames = map {; $_->as_string } $Context->stack->frames;
    is(@frames, 1, 'after pushing a frame, the first is gone');
    is($frames[0], 'eat some pie', '...only our new frame remains');
  }

  {
    local $Context = ctx_push("drink some coffee");
    my @frames = map {; $_->as_string } $Context->stack->frames;
    is(@frames, 2, 'after pushing another frame, we have two frames');
    is($frames[0], 'eat some pie',      '...0th frame is what we expect');
    is($frames[1], 'drink some coffee', '...1st frame is what we expect');
    is("@frames", join(" ", $Context->stack_trace), "->stack_trace method");
  }

  {
    my @frames = map {; $_->as_string } $Context->stack->frames;
    is(@frames, 1, 'after leaving deeper context, one frame in stack');
    is($frames[0], 'eat some pie', '...and it is the one we expect');
  }
}

{
  my @frames = map {; $_->as_string } $Context->stack->frames;
  is(@frames, 1, 'when we leave the frame-pushed context, still 1 stack left');
  like($frames[0], qr/^context initialized/, '...the ctx_init frame again');
}

{
  local $Context = ctx_push({ description => "eat some pie" });

  {
    my @frames = map {; $_->as_string } $Context->stack->frames;
    is(@frames, 1, 'after pushing a frame (hashref), the first is gone');
    is($frames[0], 'eat some pie', '...only our new frame remains');
  }
}

{
  local $Context = ctx_push(
    Global::Context::StackFrame::Basic->new({
      description => "eat some pie"
    })
  );

  {
    my @frames = map {; $_->as_string } $Context->stack->frames;
    is(@frames, 1, 'after pushing a frame (object), the first is gone');
    is($frames[0], 'eat some pie', '...only our new frame remains');
  }
}

done_testing;
