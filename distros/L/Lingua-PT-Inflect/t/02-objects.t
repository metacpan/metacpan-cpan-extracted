# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 28;
BEGIN { use_ok('Lingua::PT::Inflect') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my %words = (
  '' => '',

  'mesa' => 'mesas',
  'pai' => 'pais',

  'flor' => 'flores',
  'líquene' => 'líquenes',
  'país' => 'países',
  'raíz' => 'raízes',

  'mão' => 'mãos',
  'cão' => 'cães',
  'leão' => 'leões',

  'homem' => 'homens',
  'tom' => 'tons',

  'casal' => 'casais',
  'boi' => 'bois',
  'paul' => 'pauis',

  'anel' => 'anéis',
  'farol' => 'faróis',

  'funil' => 'funis',
  'barril' => 'barris',

  'réptil' => 'répteis',
  'fóssil' => 'fósseis',

  'gas' => 'gases',
  'francês' => 'franceses',

  'lápis' => 'lápis',
  'pires' => 'pires',
  'pírex' => 'pírex',
  'inox' => 'inox',
);

for my $word (keys %words) {
  my $object = Lingua::PT::Inflect->new("$word");
  is($object->sing2plural,$words{$word});
}
