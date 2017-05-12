use strict;
use warnings;
use Test::More qw(no_plan);
use Lingua::JA::Romaji::Valid;

my @aliases  = Lingua::JA::Romaji::Valid->aliases;
my @patterns = test_patterns();

while ( my ($word, $fails) = splice @patterns, 0, 2 ) {
  foreach my $alias ( @aliases ) {
    my $validator = Lingua::JA::Romaji::Valid->new( $alias );

    $validator->verbose(0);

    if ( $fails->{$alias} ) {
      ok $validator->as_romaji($word), "$word should be valid ($alias)";
    }
    else {
      ok !$validator->as_romaji($word), "$word should be invalid ($alias)";
    }
  }
}

sub _fails {
  my @fails = @_;
  my %hash  = map { $_ => 1 } @aliases;
  foreach my $fail ( @fails ) { $hash{$fail} = 0; }

  return \%hash;
}

sub _passes {
  my @passes = @_;
  my %hash  = map { $_ => 0 } @aliases;
  foreach my $pass ( @passes ) { $hash{$pass} = 1; }

  return \%hash;
}

sub test_patterns {
  return (
    # all green
    akasaka => _fails(qw()),
    maekawa => _fails(qw()),

    # 'shi'
    ishigaki => _fails(qw( kunrei japanese )),

    # 'si'
    isigaki => _passes(qw( kunrei japanese liberal loose )),

    # 'chi'
    ichiro => _fails(qw( kunrei japanese )),

    # 'ti'
    itiro => _fails(qw( traditional hepburn railway passport )),

    # 'tsu'
    tatsuhiko => _fails(qw( kunrei japanese )),

    # 'tu'
    tatuhiko => _fails(qw( traditional hepburn railway passport )),

    # 'fu'
    furuta => _fails(qw( kunrei japanese railway )),

    # 'hu'
    huruta => _fails(qw( traditional hepburn passport international )),

    # 'ye' (rarely found in modern Japanese words)
    yebisu => _fails(qw( kunrei japanese loose passport railway )),

    # 'wo' (used as a particle but rarely found in Japanese words)
    woe => _fails(qw( passport railway )),

    # 'ji'
    ojisan => _fails(qw( kunrei japanese )),

    # 'di' (rarely found in Japanese words)
    madison => _passes(qw( japanese international loose liberal )),

    # 'du' (rarely found in Japanese words)
    duke => _passes(qw( japanese international loose liberal )),

    # 'zi' (rarely found in Japanese words)
    zippo => _passes(qw( kunrei japanese liberal loose )),

    # 'sha'
    kaisha => _fails(qw( kunrei japanese )),

    # 'sya'
    kaisya => _passes(qw( kunrei japanese liberal loose )),

    # 'cha'
    chasen => _fails(qw( kunrei japanese )),

    # 'tya'
    tyasen => _passes(qw( kunrei japanese liberal loose )),

    # 'ja'
    jabara => _fails(qw( kunrei japanese )),

    # 'zya'
    zyabara => _passes(qw( kunrei japanese liberal loose )),

    # syllabic n
    tenpura => _fails(qw( traditional passport railway )),

    # syllabic nn
    tennpura => _passes(qw( liberal )),

    # syllabic m
    tempura => _passes(qw( traditional passport railway liberal )),

    # geminate tch
    matcha => _fails(qw( kunrei japanese )),

    # geminate cch
    maccha => _passes(qw( liberal )),

    # geminate
    mattya => _passes(qw( kunrei japanese liberal loose )),

    # n with apostrophe
    "san'in" => _fails(qw( passport railway )),

    # n with hyphen
    "san-in" => _passes(qw( railway liberal )),

    # oh 
    ohira => _fails(qw()),
    ohta  => _passes(qw( passport liberal )),

    # long vowel with h
    naitah => _passes(qw( liberal )),

    # long vowel with hyphen
    "naita-" => _passes(qw( liberal )),
  );
}
