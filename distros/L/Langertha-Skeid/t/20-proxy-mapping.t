use strict;
use warnings;
use Test::More;
use Langertha::Skeid::Proxy;

{
  my $input = {
    model => 'qwen',
    system => 'sys',
    max_tokens => 123,
    temperature => 0.2,
    tools => [{
      name => 'add',
      description => 'sum',
      input_schema => {
        type => 'object',
        properties => {
          a => { type => 'number' },
          b => { type => 'number' },
        },
      },
    }],
    tool_choice => { type => 'tool', name => 'add' },
    messages => [
      { role => 'user', content => 'hello' },
      { role => 'assistant', content => [
        { type => 'text', text => 'ok' },
        { type => 'tool_use', id => 'tu_1', name => 'add', input => { a => 2, b => 3 } },
      ]},
      { role => 'user', content => [
        { type => 'tool_result', tool_use_id => 'tu_1', content => '5' },
      ]},
    ],
  };

  my $out = Langertha::Skeid::Proxy::_anthropic_request_to_openai($input);
  is $out->{model}, 'qwen', 'model mapped';
  is $out->{messages}[0]{role}, 'system', 'system mapped';
  is $out->{messages}[1]{role}, 'user', 'user mapped';
  is $out->{messages}[2]{tool_calls}[0]{id}, 'tu_1', 'tool_use mapped';
  is $out->{messages}[3]{role}, 'tool', 'tool_result mapped';
  is $out->{tools}[0]{function}{name}, 'add', 'tools mapped';
  is $out->{tool_choice}{function}{name}, 'add', 'tool_choice mapped';
}

{
  my $res = {
    id => 'chatcmpl_1',
    model => 'qwen',
    choices => [{
      finish_reason => 'tool_calls',
      message => {
        role => 'assistant',
        content => 'hi',
        tool_calls => [{
          id => 'call_1',
          type => 'function',
          function => {
            name => 'add',
            arguments => '{"a":2,"b":3}',
          },
        }],
      },
    }],
    usage => { prompt_tokens => 10, completion_tokens => 5 },
  };

  my $out = Langertha::Skeid::Proxy::_openai_response_to_anthropic($res, 'qwen');
  is $out->{type}, 'message', 'anthropic type';
  is $out->{stop_reason}, 'tool_use', 'stop reason mapped';
  is $out->{usage}{input_tokens}, 10, 'usage mapped';
  is $out->{content}[1]{type}, 'tool_use', 'tool_use emitted';
  is $out->{content}[1]{name}, 'add', 'tool name mapped';
}

{
  my $res = {
    model => 'qwen',
    choices => [{
      finish_reason => 'stop',
      message => { role => 'assistant', content => 'OK' },
    }],
    usage => { prompt_tokens => 3, completion_tokens => 1 },
  };

  my $out = Langertha::Skeid::Proxy::_openai_response_to_ollama_chat($res);
  is $out->{model}, 'qwen', 'ollama model mapped';
  is $out->{message}{content}, 'OK', 'ollama message mapped';
  is $out->{prompt_eval_count}, 3, 'ollama prompt tokens mapped';
  is $out->{eval_count}, 1, 'ollama completion tokens mapped';
}

{
  is Langertha::Skeid::Proxy::_endpoint_url_for_node('http://a:1/v1', '/chat/completions'), 'http://a:1/v1/chat/completions', 'v1 base mapping';
  is Langertha::Skeid::Proxy::_endpoint_url_for_node('http://a:1', '/chat/completions'), 'http://a:1/v1/chat/completions', 'non-v1 base mapping';
}

done_testing;
