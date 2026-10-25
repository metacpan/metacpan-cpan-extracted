#!/usr/bin/env perl
# ABSTRACT: Scenario suite: Knarr's core features against a Langertha::Engine::Virtual backend (t/scenarios/*.yml)
use strict;
use warnings;
use utf8;
use Test2::V0;
use FindBin;
use lib "$FindBin::Bin/lib";
use Path::Tiny;
use YAML::PP;

BEGIN {
  eval { require Langertha::Engine::Virtual; 1 }
    or plan skip_all => 'needs Langertha::Engine::Virtual (Langertha 0.504 or later)';
}
BEGIN { delete @ENV{qw( KNARR_API_KEY KNARR_ADMIN_KEY KNARR_REMOTE_CONFIG KNARR_LOG_FILE KNARR_LOG_DIR LANGFUSE_PUBLIC_KEY LANGFUSE_SECRET_KEY LANGFUSE_URL LANGFUSE_BASE_URL )} }
use Test::Knarr::Virtual qw( knarr_virtual );

# Each F<t/scenarios/NN-name.yml> is one core feature of Knarr, end to end: a
# real Knarr (Config, Stack, protocols, Admin) on a loopback port, with a
# Langertha::Engine::Virtual as the backend of its models. No network, no key.
#
#   title:   what the scenario shows
#   skip:    reason string; the scenario is skipped and stays visible
#   needs:   { Module::Name: why } core modules the scenario needs; skipped
#            with that reason when one does not load (an older Langertha)
#   setup:
#     config:        the Knarr config (models, default, proxy_api_key, ...);
#                    a model's engine is written KnarrVirtual
#     backends:      { upstream model => Virtual rules (rules / after / fallback / script) };
#                    '*' answers models without an entry
#     admin_key, remote_config, request_log: as for Test::Knarr::Virtual
#     a backends entry may carry engine_args: { stream_chunk_size, default_usage }
#   steps:   run in order, each one request:
#     - chat: { protocol, model, prompt, tools, messages, bearer, xkey }
#       or
#     - http: { method, path, bearer, xkey, body }
#       expect:                      (all optional)
#         status:        HTTP status
#         text:          the answer's text, exactly
#         text_like:     regex the text must match
#         finish_reason, model, tool_calls: [ { name, args } ]
#         usage:         { input, output } the answer reports (a stream: its last report)
#         no_usage:      true = the answer reports no token usage
#         chunks:        streamed answers: number of content frames
#         ended:         streamed answers: 1 = the stream ends with the protocol's exact end marker
#         body_like:     regex over the raw body
#         json:          { 'dotted.path' => value } into the decoded body
#         absent:        [ 'dotted.path' ] must not exist
#       backend:                     what a backend engine saw
#         <upstream model>: { requests: N, calls: N, last_user_text, request_model,
#                             tools: [names], api_key, body: { dotted.path => value },
#                             body_absent: [ dotted.path ] }   (body = last request as the backend got it)
#         log:           JSONL request-log entries (setup.request_log); each a subset of the entry at that index
#
# A new scenario is a new file; nothing here changes.

my $yaml  = YAML::PP->new( boolean => 'JSON::PP' );
my @files = sort glob "$FindBin::Bin/scenarios/*.yml";
ok( scalar @files, 'there are scenarios' );

sub dig {
  my ( $data, $path ) = @_;
  for my $k ( split /\./, $path ) {
    return ( 0, undef ) unless ref $data;
    if ( ref $data eq 'ARRAY' ) { return ( 0, undef ) unless $k =~ /\A\d+\z/ && $k < @$data; $data = $data->[$k] }
    else { return ( 0, undef ) unless exists $data->{$k}; $data = $data->{$k} }
  }
  return ( 1, $data );
}

for my $file (@files) {
  my $s    = $yaml->load_file($file);
  my $name = path($file)->basename;
  subtest "$name: " . ( $s->{title} // '' ) => sub {
    skip_all $s->{skip} if $s->{skip};
    for my $module ( sort keys %{ $s->{needs} // {} } ) {
      ( my $pm = "$module.pm" ) =~ s{::}{/}g;
      skip_all "needs $module: $s->{needs}{$module}" unless eval { require $pm; 1 };
    }
    my $kv = knarr_virtual( %{ $s->{setup} // {} } );
    my $n = 0;
    for my $step ( @{ $s->{steps} // [] } ) {
      $n++;
      my $e = $step->{expect} // {};
      my $res;
      if ( my $c = $step->{chat} ) {
        $res = $kv->chat( $c->{protocol}, %$c );
      }
      elsif ( my $h = $step->{http} ) {
        $res = $kv->http( $h->{method}, $h->{path}, %$h );
      }
      else { fail("step $n has neither chat nor http"); next }
      my $tag = "step $n";

      is( $res->{status}, $e->{status} // 200, "$tag: status" );
      is( $res->{text}, $e->{text}, "$tag: text" ) if exists $e->{text};
      like( $res->{text} // '', qr/$e->{text_like}/s, "$tag: text matches" ) if defined $e->{text_like};
      is( $res->{finish_reason}, $e->{finish_reason}, "$tag: finish_reason" ) if exists $e->{finish_reason};
      is( $res->{model}, $e->{model}, "$tag: model" ) if exists $e->{model};
      is( $res->{tool_calls}, $e->{tool_calls}, "$tag: tool calls" ) if exists $e->{tool_calls};
      is( $res->{usage}, $e->{usage}, "$tag: usage" ) if exists $e->{usage};
      is( $res->{usage}, undef, "$tag: no usage" ) if $e->{no_usage};
      is( $res->{chunks}, $e->{chunks}, "$tag: content frames" ) if exists $e->{chunks};
      is( $res->{ended}, $e->{ended}, "$tag: ends with the end marker" ) if exists $e->{ended};
      like( $res->{raw}, qr/$e->{body_like}/s, "$tag: body matches" ) if defined $e->{body_like};
      for my $path ( sort keys %{ $e->{json} // {} } ) {
        my ( $found, $v ) = dig( $res->{body}, $path );
        ok( $found, "$tag: $path exists" ) && is( $v, $e->{json}{$path}, "$tag: $path" );
      }
      for my $path ( @{ $e->{absent} // [] } ) {
        my ( $found ) = dig( $res->{body}, $path );
        ok( !$found, "$tag: $path absent" );
      }

      for my $model ( sort keys %{ $step->{backend} // {} } ) {
        my $w = $step->{backend}{$model};
        my $engine = $kv->backend($model);
        ok( $engine, "$tag: backend $model was built" ) or next;
        my @req = @{ $engine->requests };
        is( scalar @req, $w->{requests}, "$tag: $model saw $w->{requests} request(s)" ) if exists $w->{requests};
        is( scalar @{ $engine->calls }, $w->{calls}, "$tag: $model emitted $w->{calls} tool call(s)" ) if exists $w->{calls};
        my $last = $req[-1] // {};
        is( $last->{last_user_text}, $w->{last_user_text}, "$tag: $model last user text" ) if exists $w->{last_user_text};
        is( $last->{model}, $w->{request_model}, "$tag: $model request model" ) if exists $w->{request_model};
        is( [ map { $_->{function}{name} } @{ $last->{tools} // [] } ], $w->{tools}, "$tag: $model saw the tools" )
          if exists $w->{tools};
        is( $engine->api_key, $w->{api_key}, "$tag: $model built with its key" ) if exists $w->{api_key};
        for my $path ( sort keys %{ $w->{body} // {} } ) {
          my ( $found, $v ) = dig( $last->{body}, $path );
          ok( $found, "$tag: $model body has $path" ) && is( $v, $w->{body}{$path}, "$tag: $model body $path" );
        }
        for my $path ( @{ $w->{body_absent} // [] } ) {
          my ( $found ) = dig( $last->{body}, $path );
          ok( !$found, "$tag: $model body has no $path" );
        }
      }

      if ( my $want = $e->{log} ) {
        my @got = $kv->log_entries;
        is( scalar @got, scalar @$want, "$tag: log entries" );
        for my $i ( 0 .. $#$want ) {
          my $g = $got[$i] or next;
          for my $k ( sort keys %{ $want->[$i] } ) {
            my ( $found, $v ) = dig( $g, $k );
            ok( $found, "$tag: log $i has $k" ) && is( $v, $want->[$i]{$k}, "$tag: log $i $k" );
          }
        }
      }
    }
  };
}

done_testing;
