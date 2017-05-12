use Test::More;
use Lingua::EN::Inflexion;

for my $line (<DATA>) {
    chomp $line;

    next if $line =~ m{\A \s* \Z  }xms;
    next if $line =~ m{\A \s* [#] }xms;

    my (                     $singular,       $plural,              $classical) 
        = $line =~ m{ \A \s* (.*?) \s* => \s* ([^|]*?) \s* (?: [|] \s* (.*?) )? \s* \Z }xms
            or fail "Unexpected test data: $line";

    $plural ||= $classical;

    my $n_sing  = noun($singular  );
    my $n_plur  = noun($plural    );

    subtest "$singular -> $plural" => sub {
        is $n_sing->singular, $singular  =>  "s->s: $singular -> $singular";
        is $n_sing->plural,   $plural    =>  "s->p: $singular -> $plural";
        is $n_plur->singular, $singular    =>  "p->s: $plural -> $singular";
        is $n_plur->plural,   $plural      =>  "p->p: $plural -> $plural";
        done_testing();
    };

    if ($classical) {
        subtest "$singular -> $classical" => sub {
            my $n_class = noun($classical);

            is $n_sing->classical->singular,  $singular  =>  "sc->s: $singular -> $singular";
            is $n_sing->classical->plural,    $classical =>  "sc->p: $singular -> $classical";
            is $n_class->classical->singular, $singular  =>  "pc->s: $plural -> $singular";
            is $n_class->classical->plural,   $classical =>  "pc->pc: $plural -> $plural";
            done_testing();
        };
    }
}

done_testing();

__DATA__

    aba               =>  abas               |
    accusal           =>  accusals           |
    afrizz            =>  afrizzes           |
    afterlife         =>                     |  afterlives
    aircraft          =>  aircraft           |
    aleph             =>  alephs             |
    analysis          =>  analyses           |
    angiosarcoma      =>  angiosarcomas      |  angiosarcomata
    antihelix         =>                     |  antihelices
    aperitif          =>  aperitifs          |
    archthief         =>                     |  archthieves
    aviatrix          =>  aviatrixes         |  aviatrices
    bacillus          =>                     |  bacilli
    bale              =>  bales              |
    bass              =>  basses             |  bass
    bay               =>  bays               |
    beau              =>  beaus              |  beaux
    bedlouse          =>  bedlice            |
    bellsheep         =>                     |  bellsheep
    bema              =>  bemas              |  bemata
    best man          =>  best men           |
    biceps            =>  biceps             |
    bikini            =>  bikinis            |
    blitz             =>  blitzes            |
    blob              =>  blobs              |
    bole              =>  boles              |
    bookshelf         =>                     |  bookshelves
    box               =>  boxes              |
    box               =>  boxes              |
    brother           =>  brothers           |  brethren
    burr              =>  burrs              |
    buzz              =>  buzzes             |
    calf              =>  calves             |
    callus            =>  calluses           |
    can               =>  cans               |
    car               =>  cars               |
    cart-ox           =>                     |  cart-oxen
    cat               =>  cats               |
    catfish           =>                     |  catfish
    child             =>                     |  children
    church            =>  churches           |
    cow               =>  cows               |  kine
    craft             =>  craft              |
    cry               =>  cries              |
    datum             =>                     |  data
    deed              =>  deeds              |
    deer              =>                     |  deer
    dog               =>  dogs               |
    dormouse          =>  dormice            |
    drama             =>  dramas             |
    dramm             =>  dramms             |
    dress             =>  dresses            |
    duo               =>  duos               |
    edema             =>  edemas             |  edemata
    egg               =>  eggs               |
    eidergoose        =>  eidergeese         |
    elf               =>                     |  elves
    endostoma         =>  endostomas         |  endostomata
    epiphenomenon     =>                     |  epiphenomena
    fish              =>                     |  fish
    fizz              =>  fizzes             |
    foot              =>  feet               |
    forehoof          =>  forehoofs          |  forehooves
    fowl              =>  fowls              |  fowl
    frizz             =>  frizzes            |
    fuzz              =>  fuzzes             |
    gem               =>  gems               |
    genus             =>                     |  genera
    German measles    =>  German measles     |
    goose             =>  geese              |
    guy               =>  guys               |
    hah               =>  hahs               |
    half-elf          =>                     |  half-elves
    hedron            =>  hedrons            |  hedra
    helion            =>  helions            |  helia
    helix             =>                     |  helices
    hertz             =>  hertz              |
    hoof              =>  hoofs              |  hooves
    human             =>  humans             |
    humbuzz           =>  humbuzzes          |
    inn               =>  inns               |
    jacknife          =>  jacknives          |
    jam               =>  jams               |
    jazz              =>  jazzes             |
    joy               =>  joys               |
    kilolux           =>  kilolux            |
    knife             =>                     |  knives
    lactobacillus     =>                     |  lactobacilli
    lapp              =>  lapps              |
    leaf              =>                     |  leaves
    legomenon         =>                     |  legomena
    lemma             =>  lemmas             |  lemmata
    lesiy             =>  lesiys             |
    life              =>                     |  lives
    loaf              =>                     |  loaves
    louse             =>  lice               |
    low-fizz          =>  low-fizzes         |
    lumen             =>  lumens             |  lumina
    lux               =>  lux                |
    lymphedema        =>  lymphedemas        |  lymphedemata
    man               =>  men                |
    measles           =>  measles            |
    megahertz         =>  megahertz          |
    melodrama         =>  melodramas         |
    mensch            =>  menschen           |
    menu              =>  menus              |
    mesh              =>  meshes             |
    midwife           =>                     |  midwives
    milieu            =>  milieus            |  milieux
    milk-cow          =>  milk-cows          |  milk-kine
    millilumen        =>  millilumens        |  millilumina
    mouse             =>  mice               |
    nanosiemens       =>  nanosiemens        |
    nova              =>  novas              |  novae
    nucleus           =>                     |  nuclei
    null-datum        =>                     |  null-data
    oberwildebeest    =>  oberwildebeests    |  oberwildebeest
    osprey            =>  ospreys            |
    padfoot           =>  padfeet            |
    panic             =>  panics             |
    parabema          =>  parabemas          |  parabemata
    paranucleus       =>                     |  paranuclei
    peachfuzz         =>  peachfuzzes        |
    penknife          =>                     |  penknives
    penumbra          =>  penumbras          |  penumbrae
    perihelion        =>  perihelions        |  perihelia
    person            =>  people             |  persons
    phalanx           =>  phalanxes          |  phalanges
    phenomenon        =>                     |  phenomena
    pikestaff         =>  pikestaffs         |  pikestaves
    pill              =>  pills              |
    play              =>  plays              |
    polyhedron        =>  polyhedrons        |  polyhedra
    pox               =>  pox                |
    proboscis         =>  proboscises        |  proboscides
    prolegomenon      =>                     |  prolegomena
    protozoon         =>  protozoa           |
    pseudoproboscis   =>  pseudoproboscises  |  pseudoproboscides
    quiz              =>  quizzes            |
    radio             =>  radios             |
    reindeer          =>                     |  reindeer
    rodeo             =>  rodeos             |
    salesperson       =>  salespeople        |  salespersons
    sarcolemma        =>  sarcolemmas        |  sarcolemmata
    sarcoma           =>  sarcomas           |  sarcomata
    sawtooth          =>  sawteeth           |
    scarf             =>  scarves            |
    sea-bass          =>  sea-basses         |  sea-bass
    sheaf             =>  sheaves            |
    sheep             =>                     |  sheep
    shelf             =>                     |  shelves
    shelf             =>  shelves            |
    she-wolf          =>                     |  she-wolves
    shiv              =>  shivs              |
    show              =>  shows              |
    siemens           =>  siemens            |
    silk              =>  silks              |
    slow jazz         =>  slow jazzes        |
    smallpox          =>  smallpox           |
    soliloquy         =>  soliloquies        |
    sphinx            =>  sphinxes           |  sphinges
    staff             =>  staffs             |  staves
    stepbrother       =>  stepbrothers       |  stepbrethren
    stepchild         =>                     |  stepchildren
    stoma             =>  stomas             |  stomata
    stratum           =>  stratums           |  strata
    subgenus          =>                     |  subgenera
    substratum        =>  substratums        |  substrata
    sugarloaf         =>                     |  sugarloaves
    superhuman        =>  superhumans        |
    supernova         =>  supernovas         |  supernovae
    syrynx            =>  syrynxes           |  syrynges
    tao               =>  taos               |
    tea-leaf          =>                     |  tea-leaves
    thief             =>                     |  thieves
    tiff              =>  tiffs              |
    toe               =>  toes               |
    tomato            =>  tomatoes           |
    tooth             =>  teeth              |
    top               =>  tops               |
    toy               =>  toys               |
    two-star general  =>  two-star generals  |
    ubermensch        =>  ubermenschen       |
    umbra             =>  umbras             |  umbrae
    watt              =>  watts              |
    wife              =>                     |  wives
    wildebeest        =>  wildebeests        |  wildebeest
    wolf              =>                     |  wolves
    wolf              =>  wolves             |
    zoo               =>  zoos               |
