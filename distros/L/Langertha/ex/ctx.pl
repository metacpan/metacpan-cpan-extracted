#!/usr/bin/env perl
# ABSTRACT: Context test

$|=1;

use FindBin;
use lib "$FindBin::Bin/../lib";

use utf8;
use open ':std', ':encoding(UTF-8)';
use strict;
use warnings;
use Data::Dumper;
use JSON::MaybeXS;
use POSIX qw( ceil );
use Time::HiRes qw( time );
use URI;

use Langertha::Engine::Ollama;

use Text::ASCIITable;

my $json = JSON::MaybeXS->new( utf8 => 1 );

my @words = qw( Admire assemble balance conquer control create drift enter escape explore flourish gather govern journey launch master observe persevere pursue rescue radiate retreat surrender vanish witness Emotions Feelings Aching captivated contented dazzled ecstatic envious fearful fervent gleeful hopeless joyful longing melancholy measured nostalgic passionate pensive restless serene terrified triumphant vulnerable Nature Environment Atmosphere breeze canopy clarity cycle dusk energy emergence erosion forest foliage ground habitat horizon illusion light motion nature ocean particles rainfall reflection resilience sky storm temperature valley Time Structure Algorithm change code dawn episode foundation function growth hierarchy momentum order process revolution sequence structure timeline transition urgency Abstract Concepts Anomaly connection conflict control creativity destiny evolution force fulfillment freedom intuition legacy limit perspective potential power relationship significance truth Other Abundance ambition balance belief burden character clarity courage dedication defiance delusion dream essence expectation fear formality generosity identity influence inspiration legacy limit loyalty metamorphosis myth paradox purpose reality risk serenity trust uncertainty wisdom );
my $words_count = scalar @words;

my %ws = (
  1024 => '',
  2048 => '',
  4096 => '',
  8192 => '',
);

my %wc;

for my $k (keys %ws) {
  my $wc = ceil($k - ($k/4));
  for (1..$wc) {
    $ws{$k} .= $words[rand @words];
    $ws{$k} .= " ";
  }
  $wc{$k} = scalar (grep { length } split(/\s+/, $ws{$k}));
}

{
  if ($ENV{OLLAMA_URL}) {

    my $model = $ENV{OLLAMA_MODEL}||'gemma2:2b';
    my $url = URI->new($ENV{OLLAMA_URL});

    my $t = Text::ASCIITable->new({ headingText => 'Context Test '.$model.' at '.$url->host_port });
       
    $t->setCols('num_ctx','p len','p words','p_e_c','size_vram','time','reply nums');

    for my $ctx (sort { $a <=> $b } keys %ws) {      

      print "#";

      my $ollama = Langertha::Engine::Ollama->new(
        url => $url->as_string,
        model => $model,
        num_ctx => $ctx,
      );

      for my $tctx (map { $_, $_ } sort { $a <=> $b } keys %ws) {

        print ".";

        my $start = time;

        my $request = $ollama->chat({
          role => 'user',
          content => $ws{$tctx},
        },{
          role => 'user',
          content => 'How many words I said so far',
        });
        my $response = $ollama->user_agent->request($request);
        my $data = $json->decode($response->content);
        my $reply = $request->response_call->($response);
        my $end = time;

        $reply =~ s/,//g;
        $reply =~ s/\.//g;

        my @nums = $reply =~ m/(\d+)/g;

        my ( $model_ps ) = grep { $_->{model} eq $model } @{$ollama->simple_ps};

        my $nt = scalar @nums < 4
          ? ( scalar @nums ? join(',', @nums) : "" )
          : join(',', @nums[0..2])."...";

        $t->addRow(
          $ctx,
          length($ws{$tctx}),
          $wc{$tctx},
          $data->{prompt_eval_count},
          sprintf("%.1f GB", $model_ps->{size_vram} / 1024 / 1024 / 1024 ),
          sprintf("%.1f s", $end - $start),
          $nt,
        );

      }

      $t->addRowLine();

    }

    print "\n\n".$t."\n\n";
  }
}

exit 0;