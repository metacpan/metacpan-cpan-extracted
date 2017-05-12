################################################################################
#
# $Project: /Devel-Tokenizer-C $
# $Author: mhx $
# $Date: 2008/12/13 16:00:43 +0100 $
# $Revision: 9 $
# $Source: /t/301_build.t $
#
################################################################################
# 
# Copyright (c) 2002-2008 Marcus Holland-Moritz. All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
# 
################################################################################

use Test;
use Devel::Tokenizer::C;
use strict;

do 't/common.sub';

$^W = 1;

BEGIN { plan tests => 768 }

chomp(my @words = <DATA>);
$_ = eval qq("$_") for @words;

my $skip = can_compile() ? '' : 'skip: cannot run compiler';

my @configs = (
  [ppflags  => [0, 1]],
  [case     => [0, 1]],
  [unk_code => [0, 1]],
  [merge    => [0, 1]],
  [comments => [0, 1]],
);

run_tests_rec($skip, \@words, [@configs, [strlen => [0, 1]]], {});
run_tests_rec($skip, \@words, [@configs, [strategy => [qw(narrow wide)]]], {strlen => 1});

sub run_tests_rec
{
  my($skip, $words, $stack, $config) = @_;
  my($cfg, @rest) = @$stack;
  my %config = %$config;
  for my $o (@{$cfg->[1]}) {
    if (defined $o) {
      $config{$cfg->[0]} = $o;
    }
    else {
      delete $config{$cfg->[0]};
    }
    if (@rest) {
      run_tests_rec($skip, $words, \@rest, \%config);
    }
    else {
      run_tests($skip, $words, \%config);
    }
  }
}

sub run_tests
{
  my($skip, $words, $options) = @_;
  my $unknown = @$words;
  my(%words, %ucwords);
  my($prefix, $suffix);
  @words{@$words} = (0 .. $#$words);
  @ucwords{map uc, @$words} = (1)x@$words;

  my @args = ( TokenFunc     => sub { "return KEY_".get_key($_[0]).";\n" }
             , CaseSensitive => $options->{case}
             , TokenEnd      => 'TOKEN_END'
             );

  if ($options->{strlen}) {
    push @args, StringLength => 'mystrlen';
    $prefix = <<CODE
int mystrlen = 0;

while (tokstr[mystrlen] != TOKEN_END)
  mystrlen++;
CODE
  }

  if (exists $options->{strategy}) {
    push @args, Strategy => $options->{strategy};
  }

  if ($options->{merge}) {
    push @args, MergeSwitches => $options->{merge};
  }

  if ($options->{comments}) {
    push @args, Comments => $options->{comments};
  }

  if ($options->{unk_code}) {
    push @args, UnknownCode => "return KEY_UNKNOWN;";
  }
  else {
    $suffix = <<CODE;
unknown:
  return KEY_UNKNOWN;
CODE
  }

  print "# ", join(', ', @args), "\n";

  my $t = new Devel::Tokenizer::C @args;

  my($c, %dir) = 0;
  for( @$words ) {
    unless( $c ) {
      $c = int( 1 + rand( length ) );
      $dir{uc get_key($_)}++;
      $t->add_tokens( [$_], "defined HAVE_".uc(get_key($_)) );
    }
    else {
      $t->add_tokens( [$_] );
    }
  
    $c--;
  }

  my $src = gencode( $t, $words, $prefix, $suffix );

  my @ppflags;
  if( $options->{ppflags} ) {
    @ppflags = keys %dir;
    while( @ppflags > 5 ) {
      splice @ppflags, rand @ppflags, 1;
    }
    delete @dir{@ppflags};
    for( @ppflags ) { s/^/-DHAVE_/ }
  }

  my @test = @$words;

  print "# generating random words\n";
  while( @test < 1000 ) {
    my $key = rand_key();
    if (exists $ucwords{uc($key)}) {
      print "# skipping [$key]\n";
    }
    else {
      push @test, $key;
    }
  }

  my(@in, @ref);

  for my $k ( @test ) {
    my($up, $lo, $rev) = (uc($k), lc($k), $k);
    $rev =~ tr/a-zA-Z/A-Za-z/;
    my @p = ($k, $up, $lo, $rev);
    push @in, @p;

    if( exists $words{$k} ) {
      if( exists $dir{uc get_key($k)} ) {
        push @ref, map [$_ => $unknown], @p;
      }
      else {
        push @ref, map [$_ => $_ eq $k || $options->{case} == 0 ? $words{$k} : $unknown], @p;
      }
    }
    else {
      push @ref, map [$_ => $unknown], @p;
    }
  }
  
  my($out) = runtest( $skip, $src, \@in, ccflags => \@ppflags );

  my $count = -1;
  my @fail;

  if( defined $out ) {
    $count = 0;
    for( @$out ) {
      my($key, $val) = /"(.*)"\s+=>\s+(\d+)/ or next;
      my $ref = shift @ref;
      if( $ref->[0] ne $key ) {
        print "# [$count] wrong keyword, expected $ref->[0], got $key\n";
        push @fail, "[$count] $key";
      }
      if( $ref->[1] ne $val ) {
        print "# [$count] [$key] wrong value, expected $ref->[1], got $val\n";
        push @fail, "[$count] $key ($val)";
      }
      $count++;
    }
  }

  skip( $skip, scalar @fail, 0, "recognition failed (".join(", ", @fail).")" );
  skip( $skip, $count, 4000, "invalid number of words parsed" );
}

sub rand_key
{
  my $key = '';
  my @letters = ('a' .. 'z', 'A' .. 'Z', '0' .. '9',
                 qw( _ . : ; . ' + * ? ! " $ % [ ] & / < > = } { ),
                 '\t');
  for (0 .. rand(30)) {
    $key .= $letters[rand @letters];
  }
  $key;
}

# following are random words from /usr/share/dict/words

__DATA__
Abrus
Aegithognathae
Aganice
Agaricus
Amentiferae
Amentifera
Argas
Ascanian
Asterolepis
Babeldom
Brahmoism
Buddh
Burhinidae
Dasypodidae
Dolichos
Doric
Dowieite
Esselen
Fouquieria
Gapa
Gloiosiphoniaceae
Hura
Iceland
Ichthyosaurus
Igdyr
Irelander
Janizary
Lanuvian
Lincolnian
Lithuanian
Marylandian
Monacanthidae
Monocondyla
Myxosporidiida
Nectrioidaceae
Nymphalinae
Palmyrene
Parthenolatry
Patricia
Pepysian
Petrea
Phaet
Punic
Reichsland
Rinde
Romane
Salva
Seleucidae
Serranus
Silicospongiae
Strongylosis
Tahiti
Tebu
Teutomaniac
Tigre
Tomkin
Trypaneidae
Urocerata
Ventriculites
Vermetidae
Winnipesaukee
Yukian
abbreviator
aberrance
acquisited
adenosine
adrenine
afterpeak
aga
albumoscope
alkool
allocute
alterably
amphistomous
anabibazon
anisate
antelegal
antic
antiserum
antorbital
appliableness
apsidal
archigastrula
ardent
armor
armpiece
arni
assume
astragalocentral
astrologize
atroscine
auricyanide
axmaking
balker
basifugal
beal
beaverish
becuffed
bedmate
bedspring
beeswax
bellwaver
bemuddy
benzoglycolic
beshackle
beshower
bicipital
bicostate
bidarka
biogenetical
blastocoele
blastodermic
blennogenic
blushfulness
boomorah
bott
bovate
brachiorrhachidian
broche
bufo
butcherdom
buxomness
cacocholia
cacotrophy
caitiff
cargoose
carmoisin
cathro
cephalodymus
cessionaire
changeably
cheating
cheeker
childless
chips
chocker
chough
circumspection
colloquiality
communicatory
complotter
concilium
conductible
consumpted
copatentee
coppering
coprophagy
corneule
corymbous
cosmical
coumaric
counterturned
crabweed
crosshand
cube
cycadofilicale
cyclocoelic
dactylous
dally
daviesite
dawdling
dedicatorily
deducibleness
degelatinize
derived
dermolysis
devouringness
dialytically
diapalma
dicyanodiamide
didymate
difficile
digitogenin
dirge
disconventicle
disputability
doctrinarianism
doctrinization
dotting
drachmae
drest
dun
durwaun
earringed
easiness
ecphoria
eelboat
electrodeless
electroengraving
electrometrically
encouragement
engolden
enter
envy
enwind
epigraphy
epilimnion
ergatoid
errite
ethical
euhemeristic
eutomous
exclamational
extracystic
extradition
fattable
faunology
ferme
ferratin
filemaker
flange
foundationless
fribblery
fulgurite
gaol
gastronosus
genual
geoponics
gimleteyed
glaciation
glimmerous
goatish
gooseflower
gratility
gryllos
haggle
hagiocracy
hagiography
halisteretic
handbarrow
harbor
hematogenic
hemitery
hepatoportal
hereunder
hieratically
historicus
honestness
hugeous
hyperbatically
ichthyism
immovable
inaccessibleness
incendiarism
inemotivity
integrally
interruptedly
intramundane
introthoracic
invectively
inveigle
inventorial
itchless
jawsmith
karyolytic
ketembilla
kikumon
ladylove
leath
leptocardian
liomyofibroma
lithopone
litterateur
lumpfish
mackenboy
macropterous
maggot
maholi
male
malease
masterer
medusiferous
meeken
megacoulomb
mensurably
meny
metope
metrocarat
metropolis
microlitic
micropaleontology
micropathology
microphotographic
micropyle
misbelievingly
missentence
mogulship
monopsonistic
muteness
mutualize
myopically
myringodermatitis
myristin
narratively
necromancer
neomedievalism
nephrogastric
netleaf
nodulate
nonattribution
noncondimental
nonconservative
nondetachable
nonperformance
nonswimming
nothous
nuditarian
ocelliferous
odontonecrosis
oleo
oleose
oligohydramnios
oliviform
ombrological
onchocercosis
onerary
oniomania
organismic
osseoalbuminoid
ossifluence
otoblennorrhea
ottajanite
ovatocylindraceous
overlively
oxyrhinous
pahutan
palmatilobate
pangful
papillosarcoma
paragram
parallelinervate
parochin
pastoral
phlogogenous
phoronomy
photesthesis
photoelectric
phylactic
physiognomically
physiurgic
physoclist
piddler
pietic
planetologist
pleomorphic
plurisporous
plutocracy
polycrystalline
porching
portionless
potboy
prakriti
praseodidymium
preimagination
preobjective
prescient
presider
procrastinating
profitmongering
progambling
proleptical
prosaically
prostatodynia
pulldevil
rabbinically
rabbinize
radiodigital
reaggregate
reaminess
reave
reckla
reem
regia
rejustify
relentless
remonetization
repartee
resinoid
retromingently
reverend
revisership
reviviscence
rhizotomi
rho
rhodanate
riempie
risk
roast
rober
roosters
roughslant
rubican
rummagy
rustre
sabadine
salfern
sandan
sandnatter
sandust
saprophyte
saturninely
sauld
scarlet
scourging
selvage
semideponent
senseful
septuagenarianism
shuler
sikhra
sinoatrial
slobber
slotter
socky
solio
soulish
southwards
spencerite
spherule
spindleful
splayfooted
splinty
sprug
squamosity
squidgy
stagewise
stalk
startfulness
stately
stepgrandson
stickily
sticktight
stiffleg
strounge
suaharo
subcolumnar
subphylar
suddle
sunburntness
surette
symbolizer
syndetic
synodite
tanglement
teatime
tectricial
teetotaler
temptability
terminist
thaumaturgy
torchon
toweringly
towniness
toxicologically
transpanamic
transpository
trichuriasis
tricky
trochitic
trustableness
tryingness
turfy
tylopodous
unadventurous
unbearably
unbenefiting
unbreakableness
uncrediting
undesire
undetached
unfussy
unherded
unjustled
unlegacied
unlight
unnaturalized
unpersuadably
unputtied
unquoted
unrevested
unstaidly
untractable
uranography
urediniospore
usury
vascularly
vermeology
virgate
virgulate
vocalizer
voltmeter
watertight
wealthiness
whits
wiring
woodeny
wride
xenomorphosis
xiphiid
zac
t\tab
