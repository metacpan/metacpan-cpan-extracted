use Test::More;

use Lingua::EN::Inflexion;

for my $term (<DATA>) {

    my ($a_an, $word) = $term =~ / \A \s* (an?) \s* (.*) \s* \Z /x
        or next;

    my $noun = noun($word);

    is $noun->indefinite,           "$a_an $word"  => "noun('$word')->indefinite";
    is $noun->indefinite(1),        "$a_an $word"  => "noun('$word')->indefinite(1)";
    is $noun->indefinite(0), "0 " . $noun->plural  => "noun('$word')->indefinite(0)";
    is $noun->indefinite(2), "2 " . $noun->plural  => "noun('$word')->indefinite(2)";
}


done_testing();


__DATA__
an Ath
 a Bth
 a Cth
 a Dth
an Eth
an Fth
 a Gth
an Hth
an Ith
 a Jth
 a Kth
an Lth
an Mth
an Nth
an Oth
 a Pth
 a Qth
an Rth
an Sth
 a Tth
 a Uth
 a Vth
 a Wth
an Xth
 a Yth
 a Zth
an a-th
 a b-th
 a c-th
 a d-th
an e-th
an f-th
 a g-th
an h-th
an i-th
 a j-th
 a k-th
an l-th
an m-th
an n-th
an o-th
 a p-th
 a q-th
an r-th
an s-th
 a t-th
 a u-th
 a v-th
 a w-th
an x-th
 a y-th
 a z-th
an A.B.C
an AI
an AGE
an agendum
an aide-de-camp
an albino
 a B.L.T. sandwich
 a BMW
 a BLANK
 a bacterium
 a Burmese restaurant
 a C.O.
 a CCD
 a COLON
 a cameo
 a CAPITAL
 a D.S.M.
 a DNR
 a DINNER
 a dynamo
an E.K.G.
an ECG
an EGG
an embryo
an erratum
 a eucalyptus
an Euler number
 a eulogy
 a euphemism
 a euphoria
 a ewe
 a ewer
an extremum
an eye
an F.B.I. agent
an FSM
 a FACT
 a FAQ
an F.A.Q.
 a fish
 a G-string
 a GSM phone
 a GOD
 a genus
 a Governor General
an H-Bomb
an H.M.S Ark Royal
an HSL colour space
 a HAL 9000
an H.A.L. 9000
 a has-been
 a height
an heir
 a honed blade
an honest man
 a honeymoon
an honorarium
an honorary degree
an honoree
an honorific
 a Hough transform
 a hound
an hour
an hourglass
 a houri
 a house
an I.O.U.
an IQ
an IDEA
an inferno
an Inspector General
 a jumbo
 a knife
an L.E.D.
 a LED
an LCD
 a lady in waiting
 a leaf
an M.I.A.
 a MIASMA
an MTV channel
 a Major General
an N.C.O.
an NCO
 a NATO country
 a note
an O.K.
an OK
an OLE
an octavo
an octopus
an okay
 a once-and-future-king
an oncologist
 a one night stand
an onerous task
an opera
an optimum
an opus
an ox
 a Ph.D.
 a PET
 a P.E.T. scan
 a plateau
 a quantum
an R.S.V.P.
an RSVP
 a REST
 a reindeer
an S.O.S.
 a SUM
an SST
 a salmon
 a T.N.T. bomb
 a TNT bomb
 a TENT
 a thought
 a tomato
 a U-boat
 a UNESCO representative
 a U.F.O.
 a UFO
 a UK citizen
 a ubiquity
 a unicorn
an unidentified flying object
 a uniform
 a unimodal system
an unimpressive record
an uninformed opinion
an uninvited guest
 a union
 a uniplex
 a uniprocessor
 a unique opportunity
 a unisex hairdresser
 a unison
 a unit
 a unitarian
 a united front
 a unity
 a univalent bond
 a univariate statistic
 a universe
an unordered meal
 a uranium atom
an urban myth
an urbane miss
an urchin
 a urea detector
 a urethane monomer
an urge
an urgency
 a urinal
an urn
 a usage
 a use
an usher
 a usual suspect
 a usurer
 a usurper
 a utensil
 a utility
an utmost urgency
 a utopia
an utterance
 a V.I.P.
 a VIPER
 a viper
an X-ray
an X.O.
 a XYLAPHONE
an XY chromosome
 a xenophobe
 a Y-shaped pipe
 a Y.Z. plane
 a YMCA
an YBLENT eye
an yblent eye
an yclad body
 a yellowing
 a yield
 a youth
 a youth
an ypsiliform junction
an yttrium atom
 a zoo
