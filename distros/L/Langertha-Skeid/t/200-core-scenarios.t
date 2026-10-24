#!/usr/bin/env perl
# ABSTRACT: Scenario suite: Skeid's core features against Langertha::Virtual::Server nodes (t/scenarios/*.yml)
use strict;
use warnings;
use utf8;
use Test2::V0;
use FindBin;
use lib "$FindBin::Bin/lib";
use Path::Tiny;
use YAML::PP;

BEGIN {
  eval { require Langertha::Engine::Virtual; require Langertha::Virtual::Server; 1 }
    or plan skip_all => 'needs Langertha::Virtual::Server (a Langertha with Engine::Virtual and its HTTP endpoint)';
}
BEGIN { delete @ENV{qw( SKEID_ADMIN_API_KEY SKEID_TRUST_KEY_ID_HEADER SKEID_USAGE_DB OPENBAO_ADDR OPENBAO_ROLE_ID OPENBAO_SECRET_ID )} }
use Langertha::Skeid;
use Test::Skeid::Virtual qw( skeid_virtual );

# Each F<t/scenarios/NN-name.yml> is one core feature of Skeid, end to end: a real
# proxy (routes, auth, routing, admission, usage) in front of nodes that are
# Langertha::Virtual::Server processes answering by rules. No network, no key.
#
#   title:   what the scenario shows
#   skip:    reason string; the scenario is skipped and stays visible
#   setup:
#     nodes:     [ { id, model, tags, max_conns, weight, healthy, upstream: <Virtual rules> } ]
#                (upstream = rules / after / fallback / script; a reaction
#                 { error: { status, message } } makes the node fail)
#     config:    the Skeid config beyond nodes (aliases, policies, default_policy, keys,
#                routing, client_auth, registry, ...); "@alice" as a key of keys: or
#                client_auth.keys is alice's customer key id
#     clients:   { alice: sk-alice }  name => key; "bearer: alice" in a step sends that key
#     admin_key: switches the /skeid/* routes on
#     env:       { NAME => value } set for the scenario (secret_env, api_key_env, ...), restored after
#   steps:   run in order, each one request:
#     - chat: { protocol (openai|anthropic|ollama), model, prompt, bearer }
#       or
#     - http: { method, path, bearer, headers, body }
#       expect:                      (all optional)
#         status:    HTTP status (default 200)
#         text, text_like, model, finish_reason      (chat only)
#         headers:   { name => value }
#         headers_like: { name => regex }
#         body_like: regex over the raw body
#         json:      { 'dotted.path' => value } into the decoded body
#         absent:    [ 'dotted.path' ] must not exist
#       upstream:                    what a node's engine saw
#         <node id>: { requests: N, last_user_text, request_model }
#       usage:       [ {field => value}, ... ]  the usage events so far, each a subset of the
#                    event at that index; "@alice" as a value is alice's customer key id
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
    my $setup   = $s->{setup} // {};
    my $clients = $setup->{clients} // {};
    my %ids     = map { $_ => Langertha::Skeid->key_id_for_key( $clients->{$_} ) } keys %$clients;
    my $at      = sub { my $v = shift; defined $v && !ref $v && $v =~ /\A\@(.+)\z/ ? $ids{$1} : $v };
    my %conf    = %{ $setup->{config} // {} };
    if ( my $ca = $conf{client_auth} ) { $conf{client_auth} = { %$ca, keys => [ map { $at->($_) } @{ $ca->{keys} // [] } ] } }
    local @ENV{ keys %{ $setup->{env} // {} } } = values %{ $setup->{env} // {} };
    my $sv = skeid_virtual( %{ { %$setup, env => undef } }, config => \%conf );
    my $n = 0;
    for my $step ( @{ $s->{steps} // [] } ) {
      $n++;
      my $e = $step->{expect} // {};
      my $res;
      if ( my $c = $step->{chat} ) {
        my %c = %$c;
        $c{bearer} = $clients->{ $c{bearer} } // $c{bearer} if defined $c{bearer};
        $c{headers} = { map { $_ => $at->( $c{headers}{$_} ) } keys %{ $c{headers} } } if $c{headers};
        $res = $sv->chat( delete $c{protocol}, %c );
      }
      elsif ( my $h = $step->{http} ) {
        my %h = %$h;
        $h{bearer} = $clients->{ $h{bearer} } // $h{bearer} if defined $h{bearer};
        $h{headers} = { map { $_ => $at->( $h{headers}{$_} ) } keys %{ $h{headers} } } if $h{headers};
        $res = $sv->http( delete $h{method}, delete $h{path}, %h );
      }
      else { fail("step $n has neither chat nor http"); next }
      my $tag = "step $n";

      is( $res->{status}, $e->{status} // 200, "$tag: status" );
      is( $res->{text}, $e->{text}, "$tag: text" ) if exists $e->{text};
      like( $res->{text} // '', qr/$e->{text_like}/s, "$tag: text matches" ) if defined $e->{text_like};
      is( $res->{finish_reason}, $e->{finish_reason}, "$tag: finish_reason" ) if exists $e->{finish_reason};
      is( $res->{model}, $e->{model}, "$tag: model" ) if exists $e->{model};
      for my $hn ( sort keys %{ $e->{headers} // {} } ) {
        is( $res->{headers}{ lc $hn }, $e->{headers}{$hn}, "$tag: header $hn" );
      }
      for my $hn ( sort keys %{ $e->{headers_like} // {} } ) {
        like( $res->{headers}{ lc $hn } // "", qr/$e->{headers_like}{$hn}/, "$tag: header $hn matches" );
      }
      like( $res->{raw}, qr/$e->{body_like}/s, "$tag: body matches" ) if defined $e->{body_like};
      for my $path ( sort keys %{ $e->{json} // {} } ) {
        my ( $found, $v ) = dig( $res->{body}, $path );
        ok( $found, "$tag: $path exists" ) && is( $v, $e->{json}{$path}, "$tag: $path" );
      }
      for my $path ( @{ $e->{absent} // [] } ) {
        my ( $found ) = dig( $res->{body}, $path );
        ok( !$found, "$tag: $path absent" );
      }

      for my $node ( sort keys %{ $step->{upstream} // {} } ) {
        my $w   = $step->{upstream}{$node};
        my @req = @{ $sv->upstream_requests($node) };
        is( scalar @req, $w->{requests}, "$tag: $node saw $w->{requests} request(s)" ) if exists $w->{requests};
        my $last = $req[-1] // {};
        is( $last->{last_user_text}, $w->{last_user_text}, "$tag: $node last user text" ) if exists $w->{last_user_text};
        is( $last->{model}, $w->{request_model}, "$tag: $node request model" ) if exists $w->{request_model};
      }

      if ( my $want = $step->{usage} ) {
        my @got = $sv->events;
        is( scalar @got, scalar @$want, "$tag: usage events" );
        for my $i ( 0 .. $#$want ) {
          my $g = $got[$i] or next;
          for my $k ( sort keys %{ $want->[$i] } ) {
            my ( $found, $v ) = dig( $g, $k );
            ok( $found, "$tag: usage $i has $k" ) && is( $v, $at->( $want->[$i]{$k} ), "$tag: usage $i $k" );
          }
        }
      }
    }
  };
}

done_testing;
