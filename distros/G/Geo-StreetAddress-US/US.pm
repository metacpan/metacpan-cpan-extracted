package Geo::StreetAddress::US;

use 5.008_001;
use strict;
use warnings;

our $VERSION = '1.04';

use base 'Class::Data::Inheritable';

=head1 NAME

Geo::StreetAddress::US - Perl extension for parsing US street addresses

=head1 SYNOPSIS

  use Geo::StreetAddress::US;

  $hashref = Geo::StreetAddress::US->parse_location(
                "1005 Gravenstein Hwy N, Sebastopol CA 95472" );

  $hashref = Geo::StreetAddress::US->parse_location(
                "Hollywood & Vine, Los Angeles, CA" );

  $hashref = Geo::StreetAddress::US->parse_address(
                "1600 Pennsylvania Ave, Washington, DC" );

  $hashref = Geo::StreetAddress::US->parse_address(
                "1600 Pennsylvania Ave, Washington, DC" );

  $hashref = Geo::StreetAddress::US->parse_informal_address(
                "Lot 3 Pennsylvania Ave" );

  $hashref = Geo::StreetAddress::US->parse_intersection(
                "Mission Street at Valencia Street, San Francisco, CA" );

  $hashref = Geo::StreetAddress::US->normalize_address( \%spec );
      # the parse_* methods call this automatically...

=head1 DESCRIPTION

Geo::StreetAddress::US is a regex-based street address and street intersection
parser for the United States. Its basic goal is to be as forgiving as possible
when parsing user-provided address strings. Geo::StreetAddress::US knows about
directional prefixes and suffixes, fractional building numbers, building units,
grid-based addresses (such as those used in parts of Utah), 5 and 9 digit ZIP
codes, and all of the official USPS abbreviations for street types, state
names and secondary unit designators.

=head1 RETURN VALUES

Most Geo::StreetAddress::US methods return a reference to a hash containing
address or intersection information. This
"address specifier" hash may contain any of the following fields for a
given address. If a given field is not present in the address, the
corresponding key will be set to C<undef> in the hash.

Future versions of this module may add extra fields.

=head1 ADDRESS SPECIFIER

=head2 number

House or street number.

=head2 prefix

Directional prefix for the street, such as N, NE, E, etc.  A given prefix
should be one to two characters long.

=head2 street

Name of the street, without directional or type qualifiers.

=head2 type

Abbreviated street type, e.g. Rd, St, Ave, etc. See the USPS official
type abbreviations at L<http://pe.usps.com/text/pub28/pub28apc.html>
for a list of abbreviations used.

=head2 suffix

Directional suffix for the street, as above.

=head2 city

Name of the city, town, or other locale that the address is situated in.

=head2 state

The state which the address is situated in, given as its two-letter
postal abbreviation.  for a list of abbreviations used.

=head2 zip

Five digit ZIP postal code for the address, including leading zero, if needed.

=head2 sec_unit_type

If the address includes a Secondary Unit Designator, such as a room, suite or
appartment, the C<sec_unit_type> field will indicate the type of unit.

=head2 sec_unit_num

If the address includes a Secondary Unit Designator, such as a room, suite or appartment,
the C<sec_unit_num> field will indicate the number of the unit (which may not be numeric).

=head1 INTERSECTION SPECIFIER

=head2 prefix1, prefix2

Directional prefixes for the streets in question.

=head2 street1, street2

Names of the streets in question.

=head2 type1, type2

Street types for the streets in question.

=head2 suffix1, suffix2

Directional suffixes for the streets in question.

=head2 city

City or locale containing the intersection, as above.

=head2 state

State abbreviation, as above.

=head2 zip

Five digit ZIP code, as above.

=cut

=head1 GLOBAL VARIABLES

Geo::StreetAddress::US contains a number of global variables which it
uses to recognize different bits of US street addresses. Although you
will probably not need them, they are documented here for completeness's
sake.

=cut

=head2 %Directional

Maps directional names (north, northeast, etc.) to abbreviations (N, NE, etc.).

=head2 %Direction_Code

Maps directional abbreviations to directional names.

=cut

our %Directional = (
    north       => "N",
    northeast   => "NE",
    east        => "E",
    southeast   => "SE",
    south       => "S",
    southwest   => "SW",
    west        => "W",
    northwest   => "NW",
);

our %Direction_Code; # setup in init();

=head2 %Street_Type

Maps lowercased USPS standard street types to their canonical postal
abbreviations as found in TIGER/Line.  See eg/get_street_abbrev.pl in
the distrbution for how this map was generated.

=cut

our %Street_Type = (
    allee       => "aly",
    alley       => "aly",
    ally        => "aly",
    anex        => "anx",
    annex       => "anx",
    annx        => "anx",
    arcade      => "arc",
    av          => "ave",
    aven        => "ave",
    avenu       => "ave",
    avenue      => "ave",
    avn         => "ave",
    avnue       => "ave",
    bayoo       => "byu",
    bayou       => "byu",
    beach       => "bch",
    bend        => "bnd",
    bluf        => "blf",
    bluff       => "blf",
    bluffs      => "blfs",
    bot         => "btm",
    bottm       => "btm",
    bottom      => "btm",
    boul        => "blvd",
    boulevard   => "blvd",
    boulv       => "blvd",
    branch      => "br",
    brdge       => "brg",
    bridge      => "brg",
    brnch       => "br",
    brook       => "brk",
    brooks      => "brks",
    burg        => "bg",
    burgs       => "bgs",
    bypa        => "byp",
    bypas       => "byp",
    bypass      => "byp",
    byps        => "byp",
    camp        => "cp",
    canyn       => "cyn",
    canyon      => "cyn",
    cape        => "cpe",
    causeway    => "cswy",
    causway     => "cswy",
    cen         => "ctr",
    cent        => "ctr",
    center      => "ctr",
    centers     => "ctrs",
    centr       => "ctr",
    centre      => "ctr",
    circ        => "cir",
    circl       => "cir",
    circle      => "cir",
    circles     => "cirs",
    ck          => "crk",
    cliff       => "clf",
    cliffs      => "clfs",
    club        => "clb",
    cmp         => "cp",
    cnter       => "ctr",
    cntr        => "ctr",
    cnyn        => "cyn",
    common      => "cmn",
    corner      => "cor",
    corners     => "cors",
    course      => "crse",
    court       => "ct",
    courts      => "cts",
    cove        => "cv",
    coves       => "cvs",
    cr          => "crk",
    crcl        => "cir",
    crcle       => "cir",
    crecent     => "cres",
    creek       => "crk",
    crescent    => "cres",
    cresent     => "cres",
    crest       => "crst",
    crossing    => "xing",
    crossroad   => "xrd",
    crscnt      => "cres",
    crsent      => "cres",
    crsnt       => "cres",
    crssing     => "xing",
    crssng      => "xing",
    crt         => "ct",
    curve       => "curv",
    dale        => "dl",
    dam         => "dm",
    div         => "dv",
    divide      => "dv",
    driv        => "dr",
    drive       => "dr",
    drives      => "drs",
    drv         => "dr",
    dvd         => "dv",
    estate      => "est",
    estates     => "ests",
    exp         => "expy",
    expr        => "expy",
    express     => "expy",
    expressway  => "expy",
    expw        => "expy",
    extension   => "ext",
    extensions  => "exts",
    extn        => "ext",
    extnsn      => "ext",
    falls       => "fls",
    ferry       => "fry",
    field       => "fld",
    fields      => "flds",
    flat        => "flt",
    flats       => "flts",
    ford        => "frd",
    fords       => "frds",
    forest      => "frst",
    forests     => "frst",
    forg        => "frg",
    forge       => "frg",
    forges      => "frgs",
    fork        => "frk",
    forks       => "frks",
    fort        => "ft",
    freeway     => "fwy",
    freewy      => "fwy",
    frry        => "fry",
    frt         => "ft",
    frway       => "fwy",
    frwy        => "fwy",
    garden      => "gdn",
    gardens     => "gdns",
    gardn       => "gdn",
    gateway     => "gtwy",
    gatewy      => "gtwy",
    gatway      => "gtwy",
    glen        => "gln",
    glens       => "glns",
    grden       => "gdn",
    grdn        => "gdn",
    grdns       => "gdns",
    green       => "grn",
    greens      => "grns",
    grov        => "grv",
    grove       => "grv",
    groves      => "grvs",
    gtway       => "gtwy",
    harb        => "hbr",
    harbor      => "hbr",
    harbors     => "hbrs",
    harbr       => "hbr",
    haven       => "hvn",
    havn        => "hvn",
    height      => "hts",
    heights     => "hts",
    hgts        => "hts",
    highway     => "hwy",
    highwy      => "hwy",
    hill        => "hl",
    hills       => "hls",
    hiway       => "hwy",
    hiwy        => "hwy",
    hllw        => "holw",
    hollow      => "holw",
    hollows     => "holw",
    holws       => "holw",
    hrbor       => "hbr",
    ht          => "hts",
    hway        => "hwy",
    inlet       => "inlt",
    island      => "is",
    islands     => "iss",
    isles       => "isle",
    islnd       => "is",
    islnds      => "iss",
    jction      => "jct",
    jctn        => "jct",
    jctns       => "jcts",
    junction    => "jct",
    junctions   => "jcts",
    junctn      => "jct",
    juncton     => "jct",
    key         => "ky",
    keys        => "kys",
    knol        => "knl",
    knoll       => "knl",
    knolls      => "knls",
    la          => "ln",
    lake        => "lk",
    lakes       => "lks",
    landing     => "lndg",
    lane        => "ln",
    lanes       => "ln",
    ldge        => "ldg",
    light       => "lgt",
    lights      => "lgts",
    lndng       => "lndg",
    loaf        => "lf",
    lock        => "lck",
    locks       => "lcks",
    lodg        => "ldg",
    lodge       => "ldg",
    loops       => "loop",
    manor       => "mnr",
    manors      => "mnrs",
    meadow      => "mdw",
    meadows     => "mdws",
    medows      => "mdws",
    mill        => "ml",
    mills       => "mls",
    mission     => "msn",
    missn       => "msn",
    mnt         => "mt",
    mntain      => "mtn",
    mntn        => "mtn",
    mntns       => "mtns",
    motorway    => "mtwy",
    mount       => "mt",
    mountain    => "mtn",
    mountains   => "mtns",
    mountin     => "mtn",
    mssn        => "msn",
    mtin        => "mtn",
    neck        => "nck",
    orchard     => "orch",
    orchrd      => "orch",
    overpass    => "opas",
    ovl         => "oval",
    parks       => "park",
    parkway     => "pkwy",
    parkways    => "pkwy",
    parkwy      => "pkwy",
    passage     => "psge",
    paths       => "path",
    pikes       => "pike",
    pine        => "pne",
    pines       => "pnes",
    pk          => "park",
    pkway       => "pkwy",
    pkwys       => "pkwy",
    pky         => "pkwy",
    place       => "pl",
    plain       => "pln",
    plaines     => "plns",
    plains      => "plns",
    plaza       => "plz",
    plza        => "plz",
    point       => "pt",
    points      => "pts",
    port        => "prt",
    ports       => "prts",
    prairie     => "pr",
    prarie      => "pr",
    prk         => "park",
    prr         => "pr",
    rad         => "radl",
    radial      => "radl",
    radiel      => "radl",
    ranch       => "rnch",
    ranches     => "rnch",
    rapid       => "rpd",
    rapids      => "rpds",
    rdge        => "rdg",
    rest        => "rst",
    ridge       => "rdg",
    ridges      => "rdgs",
    river       => "riv",
    rivr        => "riv",
    rnchs       => "rnch",
    road        => "rd",
    roads       => "rds",
    route       => "rte",
    rvr         => "riv",
    shoal       => "shl",
    shoals      => "shls",
    shoar       => "shr",
    shoars      => "shrs",
    shore       => "shr",
    shores      => "shrs",
    skyway      => "skwy",
    spng        => "spg",
    spngs       => "spgs",
    spring      => "spg",
    springs     => "spgs",
    sprng       => "spg",
    sprngs      => "spgs",
    spurs       => "spur",
    sqr         => "sq",
    sqre        => "sq",
    sqrs        => "sqs",
    squ         => "sq",
    square      => "sq",
    squares     => "sqs",
    station     => "sta",
    statn       => "sta",
    stn         => "sta",
    str         => "st",
    strav       => "stra",
    strave      => "stra",
    straven     => "stra",
    stravenue   => "stra",
    stravn      => "stra",
    stream      => "strm",
    street      => "st",
    streets     => "sts",
    streme      => "strm",
    strt        => "st",
    strvn       => "stra",
    strvnue     => "stra",
    sumit       => "smt",
    sumitt      => "smt",
    summit      => "smt",
    terr        => "ter",
    terrace     => "ter",
    throughway  => "trwy",
    tpk         => "tpke",
    tr          => "trl",
    trace       => "trce",
    traces      => "trce",
    track       => "trak",
    tracks      => "trak",
    trafficway  => "trfy",
    trail       => "trl",
    trails      => "trl",
    trk         => "trak",
    trks        => "trak",
    trls        => "trl",
    trnpk       => "tpke",
    trpk        => "tpke",
    tunel       => "tunl",
    tunls       => "tunl",
    tunnel      => "tunl",
    tunnels     => "tunl",
    tunnl       => "tunl",
    turnpike    => "tpke",
    turnpk      => "tpke",
    underpass   => "upas",
    union       => "un",
    unions      => "uns",
    valley      => "vly",
    valleys     => "vlys",
    vally       => "vly",
    vdct        => "via",
    viadct      => "via",
    viaduct     => "via",
    view        => "vw",
    views       => "vws",
    vill        => "vlg",
    villag      => "vlg",
    village     => "vlg",
    villages    => "vlgs",
    ville       => "vl",
    villg       => "vlg",
    villiage    => "vlg",
    vist        => "vis",
    vista       => "vis",
    vlly        => "vly",
    vst         => "vis",
    vsta        => "vis",
    walks       => "walk",
    well        => "wl",
    wells       => "wls",
    wy          => "way",
);

our %_Street_Type_List;     # set up in init() later;
our %_Street_Type_Match;    # set up in init() later;

=head2 %State_Code

Maps lowercased US state and territory names to their canonical two-letter
postal abbreviations. See eg/get_state_abbrev.pl in the distrbution
for how this map was generated.

=cut

our %State_Code = (
    "alabama" => "AL",
    "alaska" => "AK",
    "american samoa" => "AS",
    "arizona" => "AZ",
    "arkansas" => "AR",
    "california" => "CA",
    "colorado" => "CO",
    "connecticut" => "CT",
    "delaware" => "DE",
    "district of columbia" => "DC",
    "federated states of micronesia" => "FM",
    "florida" => "FL",
    "georgia" => "GA",
    "guam" => "GU",
    "hawaii" => "HI",
    "idaho" => "ID",
    "illinois" => "IL",
    "indiana" => "IN",
    "iowa" => "IA",
    "kansas" => "KS",
    "kentucky" => "KY",
    "louisiana" => "LA",
    "maine" => "ME",
    "marshall islands" => "MH",
    "maryland" => "MD",
    "massachusetts" => "MA",
    "michigan" => "MI",
    "minnesota" => "MN",
    "mississippi" => "MS",
    "missouri" => "MO",
    "montana" => "MT",
    "nebraska" => "NE",
    "nevada" => "NV",
    "new hampshire" => "NH",
    "new jersey" => "NJ",
    "new mexico" => "NM",
    "new york" => "NY",
    "north carolina" => "NC",
    "north dakota" => "ND",
    "northern mariana islands" => "MP",
    "ohio" => "OH",
    "oklahoma" => "OK",
    "oregon" => "OR",
    "palau" => "PW",
    "pennsylvania" => "PA",
    "puerto rico" => "PR",
    "rhode island" => "RI",
    "south carolina" => "SC",
    "south dakota" => "SD",
    "tennessee" => "TN",
    "texas" => "TX",
    "utah" => "UT",
    "vermont" => "VT",
    "virgin islands" => "VI",
    "virginia" => "VA",
    "washington" => "WA",
    "west virginia" => "WV",
    "wisconsin" => "WI",
    "wyoming" => "WY",
);

=head2 %State_FIPS

Maps two-digit FIPS-55 US state and territory codes (including the
leading zero!) as found in TIGER/Line to the state's canonical two-letter
postal abbreviation. See eg/get_state_fips.pl in the distrbution for
how this map was generated. Yes, I know the FIPS data also has the state
names. Oops.

=cut

our %State_FIPS = (
    "01" => "AL",
    "02" => "AK",
    "04" => "AZ",
    "05" => "AR",
    "06" => "CA",
    "08" => "CO",
    "09" => "CT",
    "10" => "DE",
    "11" => "DC",
    "12" => "FL",
    "13" => "GA",
    "15" => "HI",
    "16" => "ID",
    "17" => "IL",
    "18" => "IN",
    "19" => "IA",
    "20" => "KS",
    "21" => "KY",
    "22" => "LA",
    "23" => "ME",
    "24" => "MD",
    "25" => "MA",
    "26" => "MI",
    "27" => "MN",
    "28" => "MS",
    "29" => "MO",
    "30" => "MT",
    "31" => "NE",
    "32" => "NV",
    "33" => "NH",
    "34" => "NJ",
    "35" => "NM",
    "36" => "NY",
    "37" => "NC",
    "38" => "ND",
    "39" => "OH",
    "40" => "OK",
    "41" => "OR",
    "42" => "PA",
    "44" => "RI",
    "45" => "SC",
    "46" => "SD",
    "47" => "TN",
    "48" => "TX",
    "49" => "UT",
    "50" => "VT",
    "51" => "VA",
    "53" => "WA",
    "54" => "WV",
    "55" => "WI",
    "56" => "WY",
    "72" => "PR",
    "78" => "VI",
);

our %FIPS_State; # setup in init() later;

=head2 %Addr_Match

A hash of compiled regular expressions corresponding to different
types of address or address portions. Defined regexen include
type, number, fraction, state, direct(ion), dircode, zip, corner,
street, place, address, and intersection.

Direct use of these patterns is not recommended because they may change in
subtle ways between releases.

=cut

our %Addr_Match; # setup in init()

init();

our %Normalize_Map = (
    prefix  => \%Directional,
    prefix1 => \%Directional,
    prefix2 => \%Directional,
    suffix  => \%Directional,
    suffix1 => \%Directional,
    suffix2 => \%Directional,
    type    => \%Street_Type,
    type1   => \%Street_Type,
    type2   => \%Street_Type,
    state   => \%State_Code,
);


=head1 CLASS ACCESSORS

=head2 avoid_redundant_street_type

If true then L</normalize_address> will set the C<type> field to undef
if the C<street> field contains a word that corresponds to the C<type> in L<\%Street_Type>.

For example, given "4321 Country Road 7", C<street> will be "Country Road 7"
and C<type> will be "Rd". With avoid_redundant_street_type set true, C<type>
will be undef because C<street> matches /\b (rd|road) \b/ix;

Also applies to C<type1> for C<street1> and C<type2> for C<street2>
fields for intersections.

The default is false, for backwards compatibility.

=cut

BEGIN { __PACKAGE__->mk_classdata('avoid_redundant_street_type' => 0) }

=head1 CLASS METHODS

=head2 init

    # Add another street type mapping:
    $Geo::StreetAddress::US::Street_Type{'cur'}='curv';
    # Re-initialize to pick up the change
    Geo::StreetAddress::US::init();

Runs the setup on globals.  This is run automatically when the module is loaded,
but if you subsequently change the globals, you should run it again.

=cut

sub init {

    %Direction_Code = reverse %Directional;

    %FIPS_State     = reverse %State_FIPS;

    %_Street_Type_List  = map { $_ => 1 } %Street_Type;

    # build hash { 'rd' => qr/\b (?: rd|road ) \b/xi, ... }
    %_Street_Type_Match = map { $_ => $_ } values %Street_Type;
    while ( my ($type_alt, $type_abbrv) = each %Street_Type ) {
        $_Street_Type_Match{$type_abbrv} .= "|\Q$type_alt";
    }
    %_Street_Type_Match = map {
        my $alts = $_Street_Type_Match{$_};
        $_ => qr/\b (?: $alts ) \b/xi;
    } keys %_Street_Type_Match;

    use re 'eval';

    %Addr_Match = (
        type    => join("|", keys %_Street_Type_List),
        fraction => qr{\d+\/\d+},
        state   => '\b(?:'.join("|",
            # escape spaces in state names (e.g., "new york" --> "new\\ york")
            # so they still match in the x environment below
            map { ( quotemeta $_) } keys %State_Code, values %State_Code
            ).')\b',
        direct  => join("|",
            # map direction names to direction codes
            keys %Directional,
            # also map the dotted version of the code to the code itself
            map {
                my $c = $_; $c =~ s/(\w)/$1./g; ( quotemeta $c, $_ )
            } sort { length $b <=> length $a } values %Directional
        ),
        dircode => join("|", keys %Direction_Code),
        zip     => qr/\d{5}(?:-?\d{4})?/,  # XXX add \b?
        corner  => qr/(?:\band\b|\bat\b|&|\@)/i,
    );

    # we don't include letters in the number regex because we want to
    # treat "42S" as "42 S" (42 South). For example,
    # Utah and Wisconsin have a more elaborate system of block numbering
    # http://en.wikipedia.org/wiki/House_number#Block_numbers
    $Addr_Match{number} = qr/(\d+-?\d*)(?=\D) (?{ $_{number} = $^N })/ix,

    # note that expressions like [^,]+ may scan more than you expect
    $Addr_Match{street} = qr/
        (?:
          # special case for addresses like 100 South Street
          (?:($Addr_Match{direct})\W+           (?{ $_{street} = $^N })
             ($Addr_Match{type})\b              (?{ $_{type}   = $^N }))
             #(?{ $_{_street}.=1 })
          |
          (?:($Addr_Match{direct})\W+           (?{ $_{prefix} = $^N }))?
          (?:
            ([^,]*\d)                           (?{ $_{street} = $^N })
            (?:[^\w,]*($Addr_Match{direct})\b   (?{ $_{suffix} = $^N; $_{type}||='' }))
            #(?{ $_{_street}.=3 })
           |
            ([^,]+)                             (?{ $_{street} = $^N })
            (?:[^\w,]+($Addr_Match{type})\b     (?{ $_{type}   = $^N }))
            (?:[^\w,]+($Addr_Match{direct})\b   (?{ $_{suffix} = $^N }))?
            #(?{ $_{_street}.=2 })
           |
            ([^,]+?)                            (?{ $_{street} = $^N; $_{type}||='' })
            (?:[^\w,]+($Addr_Match{type})\b     (?{ $_{type}   = $^N }))?
            (?:[^\w,]+($Addr_Match{direct})\b   (?{ $_{suffix} = $^N }))?
            #(?{ $_{_street}.=4 })
          )
        )
    /ix;


    # http://pe.usps.com/text/pub28/pub28c2_003.htm
    # TODO add support for those that don't require a number
    # TODO map to standard names/abbreviations
    $Addr_Match{sec_unit_type_numbered} = qr/
          (su?i?te
            |p\W*[om]\W*b(?:ox)?
            |(?:ap|dep)(?:ar)?t(?:me?nt)?
            |ro*m
            |flo*r?
            |uni?t
            |bu?i?ldi?n?g
            |ha?nga?r
            |lo?t
            |pier
            |slip
            |spa?ce?
            |stop
            |tra?i?le?r
            |box)(?![a-z])            (?{ $_{sec_unit_type}   = $^N })
        /ix;

    $Addr_Match{sec_unit_type_unnumbered} = qr/
          (ba?se?me?n?t
            |fro?nt
            |lo?bby
            |lowe?r
            |off?i?ce?
            |pe?n?t?ho?u?s?e?
            |rear
            |side
            |uppe?r
            )\b                      (?{ $_{sec_unit_type}   = $^N })
        /ix;

    $Addr_Match{sec_unit} = qr/
        (:?
            (?: (?:$Addr_Match{sec_unit_type_numbered} \W*)
                | (\#)\W*            (?{ $_{sec_unit_type}   = $^N })
            )
            (  [\w-]+)               (?{ $_{sec_unit_num}    = $^N })
        )
        |
            $Addr_Match{sec_unit_type_unnumbered}
        /ix;

    $Addr_Match{city_and_state} = qr/
        (?:
            ([^\d,]+?)\W+            (?{ $_{city}   = $^N })
            ($Addr_Match{state})     (?{ $_{state}  = $^N })
        )
        /ix;

    $Addr_Match{place} = qr/
        (?:$Addr_Match{city_and_state}\W*)?
        (?:($Addr_Match{zip})        (?{ $_{zip}    = $^N }))?
        /ix;

    # the \x23 below is an alias for '#' to avoid a bug in perl 5.18.1
    # https://rt.cpan.org/Ticket/Display.html?id=91420
    $Addr_Match{address} = qr/
        ^
        [^\w\x23]*    # skip non-word chars except # (eg unit)
        (  $Addr_Match{number} )\W*
        (?:$Addr_Match{fraction}\W*)?
           $Addr_Match{street}\W+
        (?:$Addr_Match{sec_unit}\W+)?
           $Addr_Match{place}
        \W*         # require on non-word chars at end
        $           # right up to end of string
        /ix;

    my $sep = qr/(?:\W+|\Z)/;

    $Addr_Match{informal_address} = qr/
        ^
        \s*         # skip leading whitespace
        (?:$Addr_Match{sec_unit} $sep)?
        (?:$Addr_Match{number})?\W*
        (?:$Addr_Match{fraction}\W*)?
           $Addr_Match{street} $sep
        (?:$Addr_Match{sec_unit} $sep)?
        (?:$Addr_Match{place})?
        # don't require match to reach end of string
        /ix;

    $Addr_Match{intersection} = qr/^\W*
           $Addr_Match{street}\W*?

        \s+$Addr_Match{corner}\s+

            (?{ exists $_{$_} and $_{$_.1} = delete $_{$_} for (qw{prefix street type suffix})})
           $Addr_Match{street}\W+
            (?{ exists $_{$_} and $_{$_.2} = delete $_{$_} for (qw{prefix street type suffix})})

           $Addr_Match{place}
        \W*$/ix;
}

=head2 parse_location

    $spec = Geo::StreetAddress::US->parse_location( $string )

Parses any address or intersection string and returns the appropriate
specifier. If $string matches the $Addr_Match{corner} pattern then
parse_intersection() is used.  Else parse_address() is called and if that
returns false then parse_informal_address() is called.

=cut

sub parse_location {
    my ($class, $addr) = @_;

    if ($addr =~ /$Addr_Match{corner}/ios) {
        return $class->parse_intersection($addr);
    }
    return $class->parse_address($addr)
        || $class->parse_informal_address($addr);
}


=head2 parse_address

    $spec = Geo::StreetAddress::US->parse_address( $address_string )

Parses a street address into an address specifier using the $Addr_Match{address}
pattern. Returning undef if the address cannot be parsed as a complete formal
address.

You may want to use parse_location() instead.

=cut

sub parse_address {
    my ($class, $addr) = @_;
    local %_;

    $addr =~ /$Addr_Match{address}/ios
        or return undef;

    return $class->normalize_address({ %_ });
}


=head2 parse_informal_address

    $spec = Geo::StreetAddress::US->parse_informal_address( $address_string )

Acts like parse_address() except that it handles a wider range of address
formats because it uses the L</informal_address> pattern. That means a
unit can come first, a street number is optional, and the city and state aren't
needed. Which means that informal addresses like "#42 123 Main St" can be parsed.

Returns undef if the address cannot be parsed.

You may want to use parse_location() instead.

=cut

sub parse_informal_address {
    my ($class, $addr) = @_;
    local %_;

    $addr =~ /$Addr_Match{informal_address}/ios
        or return undef;

    return $class->normalize_address({ %_ });
}


=head2 parse_intersection

    $spec = Geo::StreetAddress::US->parse_intersection( $intersection_string )

Parses an intersection string into an intersection specifier, returning
undef if the address cannot be parsed. You probably want to use
parse_location() instead.

=cut

sub parse_intersection {
    my ($class, $addr) = @_;
    local %_;

    $addr =~ /$Addr_Match{intersection}/ios
        or return undef;

    my %part = %_;
    # if we've a type2 and type1 is either missing or the same,
    # and the type seems plural,
    # and is still valid if the trailing 's' is removed, then remove it.
    # So "X & Y Streets" becomes "X Street" and "Y Street".
    if ($part{type2} && (!$part{type1} or $part{type1} eq $part{type2})) {
        my $type = $part{type2};
        if ($type =~ s/s\W*$//ios and $type =~ /^$Addr_Match{type}$/ios) {
            $part{type1} = $part{type2} = $type;
        }
    }

    return $class->normalize_address(\%part);
}


=head2 normalize_address

    $spec = Geo::StreetAddress::US->normalize_address( $spec )

Takes an address or intersection specifier, and normalizes its components,
stripping out all leading and trailing whitespace and punctuation, and
substituting official abbreviations for prefix, suffix, type, and state values.
Also, city names that are prefixed with a directional abbreviation (e.g. N, NE,
etc.) have the abbreviation expanded.  The original specifier ref is returned.

Typically, you won't need to use this method, as the C<parse_*()> methods
call it for you.

N.B., C<normalize_address()> crops 9-digit ZIP codes to 5 digits. This is for
the benefit of Geo::Coder::US and may not be what you want. E-mail me if this
is a problem and I'll see what I can do to fix it.

=cut

sub normalize_address {
    my ($class, $part) = @_;

    #m/^_/ and delete $part->{$_} for keys %$part; # for debug

    # strip off some punctuation
    defined($_) && s/^\s+|\s+$|[^\w\s\-\#\&]//gos for values %$part;

    while (my ($key, $map) = each %Normalize_Map) {
        $part->{$key} = $map->{lc $part->{$key}}
              if  defined $part->{$key}
              and exists $map->{lc $part->{$key}};
    }

    $part->{$_} = ucfirst lc $part->{$_}
        for grep(exists $part->{$_}, qw( type type1 type2 ));

    if ($class->avoid_redundant_street_type) {
        for my $suffix ('', '1', '2') {
            next unless my $street = $part->{"street$suffix"};
            next unless my $type   = $part->{"type$suffix"};
            my $type_regex = $_Street_Type_Match{lc $type}
                or die "panic: no _Street_Type_Match for $type";
            $part->{"type$suffix"} = undef
                if $street =~ $type_regex;
        }
    }

    # attempt to expand directional prefixes on place names
    $part->{city} =~ s/^($Addr_Match{dircode})\s+(?=\S)
                      /\u$Direction_Code{uc $1} /iosx
                      if $part->{city};

    # strip ZIP+4 (which may be missing a hyphen)
    $part->{zip} =~ s/^(.{5}).*/$1/os if $part->{zip};

    return $part;
}


1;
__END__

=head1 BUGS, CAVEATS, MISCELLANY

Geo::StreetAddress::US might not correctly parse house numbers that contain
hyphens, such as those used in parts of Queens, New York. Also, some addresses
in rural Michigan and Illinois may contain letter prefixes to the building
number that may cause problems. Fixing these edge cases is on the to-do list,
to be sure. Patches welcome!

This software was originally part of Geo::Coder::US (q.v.) but was split apart
into an independent module for your convenience. Therefore it has some
behaviors which were designed for Geo::Coder::US, but which may not be right
for your purposes. If this turns out to be the case, please let me know.

Geo::StreetAddress::US does B<NOT> perform USPS-certified address normalization.

Grid based addresses, like those in Utah, where the direction comes before the
number, e.g. W164N5108 instead of 164 W 5108 N, aren't handled at the moment.
A workaround is to apply a regex like this

    s/([nsew])\s*(\d+)\s*([nsew])\s*(\d+)/$2 $1 $4 $3/

=head1 SEE ALSO

This software was originally part of Geo::Coder::US(3pm).

Lingua::EN::AddressParse(3pm) and Geo::PostalAddress(3pm) both do something
very similar to Geo::StreetAddress::US, but are either too strict/limited in
their address parsing, or not really specific enough in how they break down
addresses (for my purposes). If you want USPS-style address standardization,
try Scrape::USPS::ZipLookup(3pm). Be aware, however, that it scrapes a form on
the USPS website in a way that may not be officially permitted and might break
at any time. If this module does not do what you want, you might give the
othersa try. All three modules are available from the CPAN.

You can see Geo::StreetAddress::US in action at L<http://geocoder.us/>.

USPS Postal Addressing Standards: L<http://pe.usps.com/text/pub28/welcome.htm>

=head1 APPRECIATION

Many thanks to Dave Rolsky for submitting a very useful patch to fix fractional
house numbers, dotted directionals, and other kinds of edge cases, e.g. South
St. He even submitted additional tests!

=head1 AUTHOR

Schuyler D. Erle E<lt>schuyler@geocoder.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Schuyler D. Erle.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut
# vim: ts=8:sw=4:et
