package Test::ReasoningProfileSnapshot;
# ABSTRACT: Snapshot of a model id's resolved reasoning profile and its wire output on every reasoning wire

# Used by t/48_reasoning_profile_single_digit_pin.t (karr k196) to pin the
# pre-k196 behavior of every single-digit id: the resolved classification plus
# the kwargs Langertha::Reasoning emits on each reasoning wire for each effort.
# Each cell is a canonical JSON string so JSON booleans compare across backends.

use strict;
use warnings;

use Exporter 'import';
use JSON::MaybeXS ();

use Langertha::Reasoning;
use Langertha::Reasoning::Profile;

our @EXPORT_OK = qw( snapshot @PIN_IDS );

my $JSON = JSON::MaybeXS->new( canonical => 1, allow_nonref => 1 );

my @WIRES   = qw( openai responses anthropic gemini ollama );
my @EFFORTS = qw( none minimal low medium high xhigh max );

# Every single-digit id whose resolution k196 must not change: each dotted
# gpt-5.N (N = 0..9) with its chat, codex-max, pro and mini variants, and a
# representative of every other registry row plus the unlisted default.
our @PIN_IDS = (
  qw( gpt-5 gpt-5-mini gpt-5-nano gpt-5-codex gpt-5-pro gpt-5-chat gpt-5-chat-latest ),
  ( map {
      my $d = $_;
      map { "gpt-5.$d$_" } ( '', qw( -chat -chat-latest -codex-max -codex -pro -mini ) )
    } 0 .. 9 ),
  qw( gpt-6 gpt-6-astra gpt-6.1 o1 o3 o3-mini o4-mini gpt-4o gpt-4o-mini gpt-4.1 ),
  qw( qwen3.5 qwen3.8 Qwen/Qwen3.8-27B-FP8 qwen3-32b ),
  qw( gemini-2.5-flash gemini-2.5-flash-lite gemini-2.5-pro gemini-2.5 ),
  qw( gemini-3-pro gemini-3-pro-preview gemini-3.1-pro gemini-3.7-flash gemini-3.8-flash gemini-3-flash ),
  qw( claude-opus-4-6 claude-sonnet-4-6 claude-opus-4-8 claude-fable-1 mythos-1 ),
  qw( gpt-oss-20b gpt-image-1 some-unknown-model ),
  '',
);

my @ATTRS = qw(
  control levels levels_by_wire can_disable default_reasoning_off
  is_reasoning_model disable_form wire_format is_gemini3
);

sub snapshot {
  my ( $id ) = @_;
  my $profile = Langertha::Reasoning::Profile->for_model($id);
  my %snap = map { ( "profile.$_" => $JSON->encode( $profile->$_ ) ) } @ATTRS;
  $snap{'profile.ollama_levels'} = $JSON->encode(
    $profile->has_ollama_levels ? $profile->ollama_levels : undef );
  for my $bound (qw( budget_min budget_max off_value dynamic_value )) {
    my $has = "has_$bound";
    $snap{"profile.$bound"} = $JSON->encode( $profile->$has ? $profile->$bound : undef );
  }
  for my $wire (@WIRES) {
    for my $effort (@EFFORTS) {
      my $out = eval {
        $JSON->encode( { Langertha::Reasoning->new( model => $id, effort => $effort )->to($wire) } );
      };
      $snap{"$wire.$effort"} = defined $out ? $out : 'CROAK';
    }
  }
  return \%snap;
}

1;
