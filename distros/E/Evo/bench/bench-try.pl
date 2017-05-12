package main;
use Evo 'Try::Tiny; -Lib try:evo_try; Benchmark cmpthese';

my $c;
sub inc_c { $c++ }
sub dec_c { $c-- }

my ($tt, $evo);
cmpthese - 1, {
  'Try::Tiny' => sub {
    try {inc_c} catch {dec_c} finally {dec_c};
  },
  'Evo::Lib::try' => sub {
    evo_try {inc_c} sub {dec_c}, sub {dec_c};
  },
  'eval' => sub {
    eval {inc_c};
    my $err;
    if (ref($@) || $@) { $err = $@; dec_c; }
    dec_c;
    die $err if $err;
  },
};

die if $c;
