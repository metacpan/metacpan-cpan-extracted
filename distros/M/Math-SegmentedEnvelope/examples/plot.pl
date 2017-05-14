use strict;
use warnings;
use Benchmark 'cmpthese';
use Math::SegmentedEnvelope;
use PDL;
use PDL::Graphics::Prima::Simple;

my $env = "Math::SegmentedEnvelope";
my $e = $env->new(is_morph => 1, is_fold_over => 1);
my $s = $e->static;
my $d = $env

line_plot pdl map $e->at($_/5000*8-4), 0..4999;
line_plot pdl map $s->($_/5000*8-4), 0..4999;
line_plot pdl map $d->($_/5000), 0..4999;


# cmpthese(1e1, {
#     'oo' => sub { map $e->at($_/4999), 0..4999 },
#     'fo' => sub { map $s->($_/4999), 0..4999 },
# });

# cmpthese(1e5, {
#     'oo' => sub { $e->at(rand) },
#     'fo' => sub { $s->(rand) }
# });


#map { $e->at($_/5000); $s->($_/5000) } (0..5000);
