BEGIN { $ENV{PERL_JSON_BACKEND}=0; }

use File::Slurp 'read_file';
use JSON;
use JSON::Tiny;
use Benchmark 'cmpthese';

my @json = split /-{4}/, read_file('sample.json');

sub json_pp {
  my $j = JSON->new->relaxed;
  [ map { $j->decode($_) } @json ];
}

sub json_tiny { [ map { JSON::Tiny::decode_json $_ } @json ]; }

cmpthese -15, { JSON_PP => \&json_pp, JSON_Tiny => \&json_tiny };
