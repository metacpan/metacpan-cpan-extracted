package Language::Farnsworth::Units::Standard;

use Encode;

sub init
{
	my $env = shift;
	
#	while(<DATA>)
#	{
#		$_=decode('UTF-8', $_); #fixes unicode variables
#		chomp;
#		s|//.*$||;
#		s|\s*$||;
#		$env->eval($_) if ($_ !~ /^\s*$/);
#	}

	{
		local $/;
		undef $/;
		my $data = <DATA>;
		$env->eval($data);
	}

	close(DATA); #this helps prevent annoyces in error messages
}

1;
__DATA__
//This file is borrowed and slightly modified from the original Frink Data file for non changing units
// 
// Frink data file for non-changing units.
// 
// This file is used by the Frink calculating tool/programming language:
// http://futureboy.us/frinkdocs/
//
// If you got to this page from a web search because you're trying to do a
// unit conversion or manipulation, try it at the following URL:
//
// http://futureboy.us/frink/
//
// Alan Eliasen
// eliasen@mindspring.com
//
// 
// This file is adapted, modified, and extended from the units database for use
// with GNU units, a units conversion program by Adrian Mariano
// adrian@cam.cornell.edu, who did a damn fine job collecting much of this.
// 
//
// Most units data was drawn from
//            1. NIST Special Publication 811, 1995 Edition
//            2. CRC Handbook of Chemistry and Physics 70th edition
//            3. Oxford English Dictionary
//            4. Websters New Universal Unabridged Dictionary
//            5. Units of Measure by Stephen Dresner
//            6. A Dictionary of English Weights and Measures by Ronald Zupko
//            7. British Weights and Measures by Ronald Zupko
//            8. Realm of Measure by Isaac Asimov
//            9. United States standards of weights and measures, their
//                   creation and creators by Arthur H. Frazier.
//           10. French weights and measures before the Revolution: a
//                   dictionary of provincial and local units by Ronald Zupko
//           11. Weights and Measures: their ancient origins and their
//                   development in Great Britain up to AD 1855 by FG Skinner
//           12. The World of Measurements by H. Arthur Klein
//           13. For Good Measure by William Johnstone
//           14. NTC's Encyclopedia of International Weights and Measures 
//                   by William Johnstone
//           15. Sizes by John Lord
//           16. Sizesaurus by Stephen Strauss
//           17. CODATA Recommended Values of Physical Constants available at
//                   http://physics.nist.gov/cuu/Constants/index.html
//
// Thanks to Jeff Conrad for assistance in ferreting out unit definitions.
//

/////////////////////////////////////////////////////////////////////////////
//                                                                         //
// Primitive units.  Any unit defined to contain a '!' character is a      //
// primitive unit which will not be reduced any further.  All units should //
// reduce to primitive units.                                              //
//                                                                         //
/////////////////////////////////////////////////////////////////////////////

// Prefixes
//   These are defined with the symbol :- to indicate a prefix which cannot
//  stand by itself (must be attached to a unit)
//  or with the symbol ::- for a prefix which can be either attached to a unit
//  or defines a standalone unit.
//   
//   A number specifed like "1ee20" with integers for the factor and the 
//   exponent are treated as exact numbers.

yotta ::- (1ee24);                      // 1E24 Greek or Latin octo, "eight"
zetta ::- 1ee21;                      // 1E21 Latin septem, "seven"
exa   ::- 1ee18;                      // 1E18 Greek hex, "six"
peta  ::- 1ee15;                      // 1E15 Greek pente, "five"
tera  ::- 1ee12;                      // 1E12 Greek teras, "monster"
giga  ::- 1ee9;                       // 1E9  Greek gigas, "giant"
mega  ::- 1ee6;                       // 1E6  Greek megas, "large"
myria ::- 1ee4;                       // 1E4  Not an official SI prefix
kilo  ::- 1000;                       // 1E3  Greek chilioi, "thousand"
hecto ::- 100;                        // 1E2  Greek hekaton, "hundred"
deca  ::- 10;                         // 1E1  Greek deka, "ten"
deka  ::- 10;    
deci  ::- 1/10;                       // 1E-1 Latin decimus, "tenth"
centi ::- 1/100;                      // 1E-2 Latin centum, "hundred"
milli ::- 1/1000;                     // 1E-3 Latin mille, "thousand"
micro ::- 1ee-6;                      // 1E-6 Latin micro/Greek mikros,"small"
nano  ::- 1ee-9;                      // 1E-9 Latin nanus or Greek nanos,"dwarf"
pico  ::- 1ee-12;                     // 1E-12 Spanish pico, "a bit"
femto ::- 1ee-15;                     // 1E-15 Danish-Norwegian femten,"fifteen"
atto  ::- 1ee-18;                     // 1E-18 Danish-Norwegian atten,"eighteen"
zepto ::- 1ee-21;                     // 1E-21 Latin septem, "seven"
yocto ::- 1ee-24;                     // 1E-24 Greek or Latin octo, "eight"

Y :-  yotta;
Z :-  zetta;
E :-  exa;
P :-  peta;
T :-  tera;
G :-  giga;
M :-  mega;
k :-  kilo;
h :-  hecto;
da :- deka;
d :-  deci;
c :-  centi;
m :-  milli;
   // Alan's notes:
   // I'd like to put a mu in here for micro.
   // Should we adopt the questionable Electrical Engineer policy of using
   // "u" to indicate micro?  I've added "uF" for microfarad later on to
   // tackle the most common case.
//\u00b5 :- micro   // Unicode "MICRO SIGN" //unicode like this doesn't work! in fact all unicode might not...
//µ :- micro;
u :- micro;
n :-  nano;
p :-  pico;
f :-  femto;
a :-  atto;
z :-  zepto;
y :-  yocto;

//
// SI units
//

length    =!= m;   // Length of the path traveled by light in a vacuum
meter :=  m;     //   during 1/299792458 seconds (exactly.)  
                //   Originally meant to be one ten-millionth
                //   of the length along a meridian from the equator
                //   to a pole, but the measurement was off.  
                //   
                //  Alan's notes:
                //   The earth's circumference would then be exactly 40
                //   million meters (which is a good thing to memorize.)

time      =!= s;   // Duration of 9192631770 periods of the radiation
second := s;     //   corresponding to the transition between the two hyperfine
                //   levels of the ground state of the cesium-133 atom

mass      =!=  kg; // Mass of the international prototype, whatever that is.
                //
                // Alan's editorializing:
                // I dislike having a prefixed unit as the base reference.
                // What a horrible decision.  Why don't you just have it go to
                // ten and make ten a little louder?

kilogram  := kg;
gram      := (1/1000) kg;
grams	  := gram;

current =!= A;    // The current which produces a force of 2e-7 N/m between two
ampere := A;    //   infinitely long wires that are 1 meter apart
amp :=   ampere;
               // Alan's editorializing:
               // I'd actually much rather define this in terms of the charge
               // of a fundamental particle.  electroncharge/sec
               // is less arbitrary.  I'd actually prefer to have the base
               // unit be charge instead of current.

temperature =!= K; // "1/273.16 of the thermodynamic temperature of the triple
kelvin := K;     // point of water."  Note that there is a minor discrepancy
                // between this value and the 273.15 K figure used to set
                // the zero point of the Celsius scale.  The *size* of a
                // Kelvin or a degree Celsius is the same, but you need
                // to remember that the offset point is slightly different.
                // Use the Celsius[x] functions defined below to convert
                // between these unit systems.

currency =!= dollar;// The US dollar is chosen arbitrarily to be the primitive
                 //   unit of money.  The dollar must be defined for use
                 //   in the CPISource (providing historical purchasing power
                 //   of the dollar) and for CurrencySource (providing 
                 //   exchange rate information
                 //   (and things like the price of Gold)) so
                 //   you can change the fundamental unit of currency, but you
                 //   have to be able to turn it into a dollar if you want
                 //   to use these other sources.
                 // If you want to define your own base currency, and you want
                 // currency conversions to still work, you
                 // should (for now) define the base currency as its 3-letter
                 // ISO-4217 currency code (say, "EUR" or "JPY").  This will
                 // allow the 
                 // currency converter to unambiguously figure out which
                 // currency you mean.   The units "Euro", "euro", the Euro 
                 // symbol \u20ac, the Japanese Yen symbol \u00a5,
                 // the U.K. pound symbol \u0163, and "dollar" are
                 // special cases that also work.
                 //
                 // If you change your base currency, you might get a few
                 // errors about units below that are defined in terms of the
                 // dollar.  You can probably comment those out and never miss
                 // them.  If you have a 3-letter ISO code for your base
                 // currency, it'll figure out what a "dollar" is later, so
                 // you shouldn't need to hard-code in a conversion rate.

substance =!= mol; //   The amount of substance of a system which contains as many
mole :=  mol;    //   elementary entities as there are atoms in 0.012 kg of
                //   carbon 12.  The elementary entities must be specified and
                //   may be atoms, molecules, ions, electrons, or other
                //   particles or groups of particles.  It is understood that
                //   unbound atoms of carbon 12, at rest and in the ground
                //   state, are referred to.
                //
                // Alan's editorializing:
                //   As useful as a mole may be, I really think that a mole is
                //   insufficient by itself.  It has to be a mole OF
                //   something.  How do you represent that?

radian := 1;
radians := radian; // The angle subtended at the center of a circle by an arc
                //   equal in length to the radius of the circle.
                // A circle thus subtends an angle of 2 pi radians.
                //
                // Alan's editorializing:
                // Despite what other units programs might have you believe, 
                // radians ARE dimensionless units and making them their own
                // unit leads to all sorts of arbitrary convolutions in
                // calculations (at the possible expense of some inclarity if
                // you don't know what you're doing.)
                // If you really want radians to be a fundamental unit,
                // replace the above with "angle =!= radian"
                // (This will give you a bit of artificiality in calculations.)

sr := 1;         // Solid angle which cuts off an area of the surface of
steradian :=  sr;//   the sphere equal to that of a square with sides of
                //   length equal to the radius of the sphere.
                // A sphere thus subtends 4 pi steradians.
                // Also a dimensionless unit (length^2/length^2)
                // If you really want steradians to be a fundamental unit,
                // replace the above with "solid_angle =!= sr"
                // (This will give you a bit of artificiality in calculations.)

information =!= bit;// Basic unit of information (entropy).  The entropy in bits
                //   of a random variable over a finite alphabet is defined
                //   to be the sum of -p(i)*log2(p(i)) over the alphabet where
                //   p(i) is the probability that the random variable takes
                //   on the value i.
                //
                //  Alan's editorializing:  That irrelevant non-sequitur
                //    about entropy isn't my doing.  What does that have to
                //    do with the bit itself?  I'm also considering changing 
                //    bits to be dimensionless units--it makes problems in
                //    information theory come out more reasonably.
bits := bit;

luminous_intensity =!= cd;
candela := cd;   // Official definition:
                // "The candela is the luminous intensity, in a given 
                //   direction, of a source that emits monochromatic radiation
                //   of frequency 540 x 10^12 hertz and that has a radiant 
                //   intensity in that direction of 1/683 watt per steradian."
                //
                //   (This differs from radiant
                //   intensity (W/sr) in that it is adjusted for human
                //   perceptual dependence on wavelength.  The frequency of
                //   540e12 Hz (yellow) is where human perception is most
                //   efficient.)
                //  
                // Alan's editorializing:
                //   I think the candela is a scam, and I am completely
                //   opposed to it.  Some good-for-nothing lighting "engineers"
                //   or psychologists probably got this perceptually-rigged
                //   abomination into the whole otherwise scientific endeavor.
                //
                //   What an unbelievably useless and stupid unit.  Is light
                //   at 540.00000001 x 10^12 Hz (or any other frequency) zero
                //   candela?  Is this expected to be an impulse function at
                //   this frequency?  Oh, wait, the Heisenberg Uncertainty
                //   Principle makes this impossible.  No mention for
                //   correction (ideally along the blackbody curve) for other
                //   wavelengths?  Damn you, 16th CGPM!  Damn you all to hell!

// Define the default symbol for the imaginary unit, that is, the square
// root of negative one.
i := (-1) ^ (1/2); //this is intrinsic to Math::PARI, i don't need to do anything special for it // if you include Functions::StdMath this gets redefined with the more accurate sqrt[]
 
// Define unit combinations
//1   ||| dimensionless //POINTLESS!

m^2 ||| area;
m^3 ||| volume;

s^-1   ||| frequency;

m s^-1 ||| velocity;
m s^-2 ||| acceleration;
m kg s^-1 ||| momentum;

m kg s^-2    ||| force;
m^2  kg s^-3 ||| power;
m^-1 kg s^-2 ||| pressure;
m^2  kg s^-2 ||| energy;
m^2  kg s^-1 ||| angular_momentum;
m^2  kg      ||| moment_of_inertia;

m^3 s^-1 ||| flow;

m^-3 kg ||| mass_density;
m^3  kg ||| specific_volume;

A m^-2  ||| electric_current_density;

dollar kg^-1 ||| price_per_mass;


//
// Names of some numbers
//

semi    :- 1/2;
demi    :- 1/2;
hemi    :- 1/2;
half    ::- 1/2;
third   ::- 1/3;
quarter ::- 1/4;
eighth  ::- 1/8;

uni :-   1;
bi :-    2;
tri :-   3;


one :=                 1;
two :=                 2;
double :=              2;
three :=               3;
triple :=              3;
treble :=              3;
four :=                4;
quadruple :=           4;
five :=                5;
quintuple :=           5;
six :=                 6;
sextuple :=            6;
seven :=               7;
septuple :=            7;
eight :=               8;
nine :=                9;
ten :=                 10;
twenty :=              20;
thirty :=              30;
forty :=               40;
fifty :=               50;
sixty :=               60;
seventy :=             70;
eighty :=              80;
ninety :=              90;

hundred :=             100;
thousand :=            1000;
million :=             1ee6;
billion :=             1ee9;
trillion :=            1ee12;
quadrillion :=         1ee15;
quintillion :=         1ee18;
sextillion :=          1ee21;
septillion :=          1ee24;
octillion :=           1ee27;
nonillion :=           1ee30;
noventillion :=        nonillion;
decillion :=           1ee33;
undecillion :=         1ee36;
duodecillion :=        1ee39;
tredecillion :=        1ee42;
quattuordecillion :=   1ee45;
quindecillion :=       1ee48;
sexdecillion :=        1ee51;
septendecillion :=     1ee54;
octodecillion :=       1ee57;
novemdecillion :=      1ee60;
vigintillion :=        1ee63;
centillion :=          1ee303;

googol :=              1ee100;

// These number terms were described by N. Chuquet and De la Roche in the 16th
// century as being successive powers of a million.  These definitions are 
// still used in most European countries.  The current US definitions for these
// numbers arose in the 17th century and don't make nearly as much sense.
// These numbers are listed in the CRC Concise Encyclopedia of Mathematics by
// Eric W. Weisstein.
brbillion :=           million^2;
brtrillion :=          million^3;
brquadrillion :=       million^4;
brquintillion :=       million^5;
brsextillion :=        million^6;
brseptillion :=        million^7;
broctillion :=         million^8;
brnonillion :=         million^9;
brnoventillion :=      brnonillion;
brdecillion :=         million^10;
brundecillion :=       million^11;
brduodecillion :=      million^12;
brtredecillion :=      million^13;
brquattuordecillion := million^14;
brquindecillion :=     million^15;
brsexdecillion :=      million^16;
brseptdecillion :=     million^17;
broctodecillion :=     million^18;
brnovemdecillion :=    million^19;
brvigintillion :=      million^20;

// These numbers fill the gaps left by the European system above.

milliard :=            1000 million;
billiard :=            1000 million^2;
trilliard :=           1000 million^3;
quadrilliard :=        1000 million^4;
quintilliard :=        1000 million^5;
sextilliard :=         1000 million^6;
septilliard :=         1000 million^7;
octilliard :=          1000 million^8;
nonilliard :=          1000 million^9;
noventilliard :=       nonilliard;
decilliard :=          1000 million^10;

// For consistency 

brmilliard :=          milliard;
brbilliard :=          billiard;
brtrilliard :=         trilliard;
brquadrilliard :=      quadrilliard;
brquintilliard :=      quintilliard;
brsextilliard :=       sextilliard;
brseptilliard :=       septilliard;
broctilliard :=        octilliard;
brnonilliard :=        nonilliard;
brnoventilliard :=     noventilliard;
brdecilliard :=        decilliard;

// The British Centillion would be 1ee600.  The googolplex is another 
// familiar large number equal to 10^googol.  These numbers give overflows.


//////////////////////////////////////////////////////////////////////////////
//                                                                          //
// Derived units which can be reduced to the primitive units                //
//                                                                          //
//////////////////////////////////////////////////////////////////////////////

//
// Named SI derived units (officially accepted)
//

newton :=              kg m / s^2;  // force
newtons := newton;
N :=                   newton;
pascal :=              N/m^2;       // pressure or stress
pascals := pascal;
Pa :=                  pascal;
joule :=               N m;         // energy
joules := joule;
J :=                   joule;
watt :=                J/s;         // power
watts := watt;
W :=                   watt;

J m^-2  ||| surface_tension;

coulomb :=             A s;         // charge
coulombs := coulomb;
coulomb ||| charge;
coulomb m^-2 ||| surface_charge_density;
coulomb m^-3 ||| electric_charge_density;
C :=                   coulomb;

volt :=                W/A;         // potential difference
volts := volt;
V :=                   volt;
volt ||| electric_potential;
V / m   ||| electric_field_strength;
A / m   ||| magnetic_field_strength;

ohm :=                 V/A;         // electrical resistance

//I need to add better unicode lexing support for this
//\u2126 :=              ohm;  // Official Unicode codepoint OHM SIGN
//\u03a9 :=              ohm;  // "Preferred" Unicode codepoint for ohm
                            // GREEK CAPITAL LETTER OMEGA
ohms := ohm;
ohm ||| electric_resistance;

siemens :=             A/V;         // electrical conductance
S :=                   siemens;
siemens ||| electric_conductance;

farad :=               C/V;         // capacitance
farads := farad;
farad ||| capacitance;

F :=                   farad;
uF :=                  microfarad;  // Concession to electrical engineers
                                   // without adding the questionable "u"
                                   // as a general prefix.

weber :=               V s;         // magnetic flux
weber ||| magnetic_flux;
Wb :=                  weber;

henry :=               Wb/A;        // inductance
henry ||| inductance;
henries :=             henry;       // Irregular plural
H :=                   henry;

tesla :=               Wb/m^2;      // magnetic flux density
tesla ||| magnetic_flux_density;
T :=                   tesla;

hertz :=               s^-1;        // frequency
Hz :=                  hertz;

J/K          ||| heat_capacity;
J kg^-1 K^-1 ||| specific_heat_capacity;

//
// time
//

sec :=                 s;
minute :=              60 s;
minutes := minute;
min :=                 minute;
mins := min;
hour :=                60 min;
hours := hour;
hr :=                  hour;
day :=                 24 hr;
days :=	day;
d :=                   day;
da :=                  day;
week :=                7 day;
weeks := week;
wk :=                  week;
sennight :=            7 day;
fortnight :=           14 day;
fortnights := fortnight;
blink :=               1ee-5 day;  // Actual human blink takes 1/3 second      
ce :=                  1ee-2 day;

//
// units derived easily from SI units
//

gm :=                  gram;
g :=                   gram;
tonne :=               1000 kg;
t :=                   tonne;
metricton :=           tonne;
sthene :=              tonne m / s^2;
funal :=               sthene;
pieze :=               sthene / m^2;
quintal :=             100 kg;
bar :=                 1ee5 Pa;    // About 1 atm
vac :=                 millibar;
micron :=              micrometer;// One millionth of a meter
bicron :=              picometer; // One brbillionth of a meter
cc :=                  cm^3;
are :=                 100 m^2;
liter :=               1000 cc;      // The liter was defined in 1901 as the
oldliter :=            1.000028 dm^3;// space occupied by 1 kg of pure water at
l :=                   liter;        // the temperature of its maximum density
                                     // under a pressure of 1 atm.  This was
                                     // supposed to be 1000 cubic cm, but it
                                     // was discovered that the original
                                     // measurement was off.  In 1964, the
                                     // liter was redefined to be exactly 1000
                                     // cubic centimeters.
L :=                   liter;  // This unit and its symbol l were adopted by 
                              // the CIPM in 1879. The alternative symbol for
                              // the liter, L, was adopted by the CGPM in 1979
                              // in order to avoid the risk of confusion 
                              // between the letter l and the number 1. Thus,
                              // although both l and L are internationally 
                              // accepted symbols for the liter, to avoid this
                              // risk the preferred symbol for use in the 
                              // United States is L.
mho :=                 siemens;   // Inverse of ohm, hence ohm spelled backward
galvat :=              ampere;    // Named after Luigi Galvani

angstrom :=            1ee-10 m;   // Convenient for describing molecular sizes
//\u212b :=              angstrom;   // Official Unicode codepoint for
                                  // Angstrom symbol: ANGSTROM SIGN
//\u00c5 :=              angstrom;   // "Preferred" Unicode codepoint for
                                  // Angstrom symbol:
                                  // LATIN CAPITAL LETTER A WITH RING ABOVE

xunit :=               1.00202e-13 meter;// Used for measuring wavelengths
siegbahn :=            xunit;            // of X-rays.  It is defined to be
                                         // 1/3029.45 of the spacing of calcite
                                         // planes at 18 degC.  It was intended
                                         // to be exactly 1e-13 m, but was
                                         // later found to be off slightly.
fermi :=               1ee-15 m;   // Convenient for describing nuclear sizes
                                  //   Nuclear radius is from 1 to 10 fermis
barn :=                1ee-28 m^2; // Used to measure cross section for
                                  //   particle physics collision, said to 
                                  //   have originated in the phrase "big as
                                  //   a barn".
shed :=                1ee-24 barn;// Defined to be a smaller companion to the
                                  //   barn, but it's too small to be of
                                  //   much use.
brewster :=            micron^2/N; // measures stress-optical coef
diopter :=             m^-1;       // measures reciprocal of lens focal length
fresnel :=             1ee12 Hz;   // occasionally used in spectroscopy
shake :=               1ee-8 sec;
svedberg :=            1ee-13 s;   // Used for measuring the sedimentation
                                  // coefficient for centrifuging.
gamma :=               microgram;
lambda :=              microliter;
spat :=                1ee12 m;    // Rarely used for astronomical measurements
preece :=              1ee13 ohm m;// resistivity
planck :=              J s;        // action of one joule over one second
sturgeon :=            henry^-1;   // magnetic reluctance
sturgeon ||| magnetic_reluctance;

daraf :=               1/farad;    // elastance (farad spelled backwards)
leo :=                 10 m/s^2;
poiseuille :=          N s / m^2;  // viscosity
mayer :=               J/(g K);    // specific heat capacity
mired :=               microK^-1;  // reciprocal color temperature.  The name
                                  //   abbreviates micro reciprocal degree.
crocodile :=           megavolt;   // used informally in UK physics labs
metricounce :=         25 g;
mounce :=              metricounce;
finsenunit :=          1ee5 W/m^2; // Measures intensity of ultraviolet light
                                  // with wavelength 296.7 nm.
fluxunit :=            1ee-26 W/(m^2 Hz);// Used in radio astronomy to measure
                                      //   the energy incident on the receiving
                                      //   body across a specified frequency
                                      //   bandwidth.  [12]
jansky :=              fluxunit;  // K. G. Jansky identified radio waves coming
Jy :=                  jansky;    // from outer space in 1931.

// Basic constants

pi := 3.1415926535897932384626433832795028841971693993751058209749445923078164062862089986280348253421170679821480865132823066470938446095505822317253594081284811174502841027019385211055596446229489549303819644288109756659334461284756482337867831652712019091456485669234603486104543266482133936072602491412737245870066063155881748815209209628292540917153643678925903600113305305488204665213841469519415116094330572703657595919530921861173819326117931051185480744623799627495673518857527248912279381830119491298336733624406566430860213949463952247371907021798609437027705392171762931767523846748184676694051320005681271452635608277857713427577896091736371787214684409012249534301465495853710507922796892589235420199561121290219608640344181598136297747713099605187072113499999983729780499510597317328160963185950244594553469083026425223082533446850352619311881710100031378387528865875332083814206171776691473035982534904287554687311595628638823537875937519577818577805321712268066130019278766111959092164201989380952572010654858632788659361533818279682303019520353018529689957736225994138912497217752834791315155748572424541506959508295331168617278558890750983817546374649393192550604009277016711390098488240128583616035637076601047101819429555961989467678374494482553797747268471040475346462080466842590694912933136770289891521047521620569660240580381501935112533824300355876402474964732639141992726042699227967823547816360093417216412199245863150302861829745557067498385054945885869269956909272107975093029553211653449872027559602364806654991198818347977535663698074265425278625518184175746728909777727938000816470600161452491921732172147723501414419735685481613611573525521334757418494684385233239073941433345477624168625189835694855620992192221842725502542568876717904946016534668049886272327917860857843838279679766814541009538837863609506800642251252051173929848960841284886269456042419652850222106611863067442786220391949450471237137869609563643719172874677646575739624138908658326459958133904780275900994657640789512694683983525957098258226205224894077267194782684826014769909026401363944374553050682034962524517493996514314298091906592509372216964615157098583874105978859597729754989301617539284681382686838689427741559918559252459539594310499725246808459872736446958486538367362226260991246080512438843904512441365497627807977156914359977001296160894416948685558484063534220722258284886481584560285060168427394522674676788952521385225499546667278239864565961163548862305774564980355936345681743241125150760694794510965960940252288797108931456691368672287489405601015033086179286809208747609178249385890097149096759852613655497818931297848216829989487226588048575640142704775551323796414515237462343645428584447952658678210511413547357395231134271661021359695362314429524849371871101457654035902799344037420073105785390621983874478084784896833214457138687519435064302184531910484810053706146806749192781911979399520614196634287544406437451237181921799983910159195618146751426912397489409071864942319615679452080951465502252316038819301420937621378559566389377870830390697920773467221825625996615014215030680384477345492026054146659252014974428507325186660021324340881907104863317346496514539057962685610055081066587969981635747363840525714591028970641401109712062804390397595156771577004203378699360072305587631763594218731251471205329281918261861258673215791984148488291644706095752706957220917567116722910981690915280173506712748583222871835209353965725121083579151369882091444210067510334671103141267111369908658516398315019701651511685171437657618351556508849099898599823873455283316355076479185358932261854896321329330898570642046752590709154814165498594616371802709819943099244889575712828905923233260972997120844335732654893823911932597463667305836041428138830320382490375898524374417029132765618093773444030707469211201913020330380197621101100449293215160842444859637669838952286847831235526582131449576857262433441893039686426243410773226978028073189154411010446823252716201052652272111660396665573092547110557853763466820653109896526918620564769312570586356620185581007293606598764861179104533488503461136576867532494416680396265797877185560845529654126654085306143444318586769751456614068007002378776591344017127494704205622305389945613140711270004078547332699390814546646458807972708266830634328587856983052358089330657574067954571637752542021149557615814002501262285941302164715509792592309907965473761255176567513575178296664547791745011299614890304639947132962107340437518957359614589019389713111790429782856475032031986915140287080859904801094121472213179476477726224142548545403321571853061422881375850430633217518297986622371721591607716692547487389866549494501146540628433663937900397692656721463853067360965712091807638327166416274888800786925602902284721040317211860820419000422966171196377921337575114959501566049631862947265473642523081770367515906735023507283540567040386743513622224771589150495309844489333096340878076932599397805419341447377441842631298608099888687413260472156951623965864573021631598193195167353812974167729478672422924654366800980676928238280689964004824354037014163149658979409243237896907069779422362508221688957383798623001593776471651228935786015881617557829735233446042815126272037343146531977774160319906655418763979293344195215413418994854447345673831624993419131814809277771038638773431772075456545322077709212019051660962804909263601975988281613323166636528619326686336062735676303544776280350450777235547105859548702790814356240145171806246436267945612753181340783303362542327839449753824372058353114771199260638133467768796959703098339130771098704085913374641442822772634659470474587847787201927715280731767907707157213444730605700733492436931138350493163128404251219256517980694113528013147013047816437885185290928545201165839341965621349143415956258658655705526904965209858033850722426482939728584783163057777560688876446248246857926039535277348030480290058760758251047470916439613626760449256274204208320856611906254543372131535958450687724602901618766795240616342522577195429162991930645537799140373404328752628889639958794757291746426357455254079091451357111369410911939325191076020825202618798531887705842972591677813149699009019211697173727847684726860849003377024242916513005005168323364350389517029893922334517220138128069650117844087451960121228599371623130171144484640903890644954440061986907548516026327505298349187407866808818338510228334508504860825039302133219715518430635455007668282949304137765527939751754613953984683393638304746119966538581538420568533862186725233402830871123282789212507712629463229563989898935821167456270102183564622013496715188190973038119800497340723961036854066431939509790190699639552453005450580685501956730229219139339185680344903982059551002263535361920419947455385938102343955449597783779023742161727111723643435439478221818528624085140066604433258885698670543154706965747458550332323342107301545940516553790686627333799585115625784322988273723198987571415957811196358330059408730681216028764962867446047746491599505497374256269010490377819868359381465741268049256487985561453723478673303904688383436346553794986419270563872931748723320837601123029911367938627089438799362016295154133714248928307220126901475466847653576164773794675200490757155527819653621323926406160136358155907422020203187277605277219005561484255518792530343513984425322341576233610642506390497500865627109535919465897514131034822769306247435363256916078154781811528436679570611086153315044521274739245449454236828860613408414863776700961207151249140430272538607648236341433462351897576645216413767969031495019108575984423919862916421939949072362346468441173940326591840443780513338945257423995082965912285085558215725031071257012668302402929525220118726767562204154205161841634847565169998116141010029960783869092916030288400269104140792886215078424516709087000699282120660418371806535567252532567532861291042487761825829765157;

//\u03c0 :=              pi              // Unicode character for pi
                                       // as a mathematical constant
                                       // GREEK SMALL LETTER PI

degree := pi/180 radian;
degrees := degree;


e :=         2.718281828459045235360287471352662497757247093699959574966967627724076630353547594571382178525166427427466391932003059921817413596629043572900334295260595630738132328627943490763233829880753195251019011573834187930702154089149934884167509244761460668082264800168477411853742345442437107539077744992069551702761838606261331384583000752044933826560297606737113200709328709127443747047230696977209310141692836819025515108657463772111252389784425056953696770785449969967946864454905987931636889230098793127736178215424999229576351482208269895193668033182528869398496465105820939239829488793320362509443117301238197068416140397019837679320683282376464804295311802328782509819455815301756717361332069811250996181881593041690351598888519345807273866738589422879228499892086805825749279610484198444363463244968487560233624827041978623209002160990235304369941849146314093431738143640546253152096183690888707016768396424378140592714563549061303107208510383750510115747704171898610687396965521267154688957035035402123407849819334321068170121005627880235193033224745015853904730419957777093503660416997329725088687696640355570716226844716256079882651787134195124665201030592123667719432527867539855894489697096409754591856956380236370162112047742722836489613422516445078182442352948636372141740238893441247963574370263755294448337998016125492278509257782562092622648326277933386566481627725164019105900491644998289315056604725802778631864155195653244258698294695930801915298721172556347546396447910145904090586298496791287406870504895858671747985466775757320568128845920541334053922000113786300945560688166740016984205580403363795376452030402432256613527836951177883863874439662532249850654995886234281899707733276171783928034946501434558897071942586398772754710962953741521115136835062752602326484728703920764310059584116612054529703023647254929666938115137322753645098889031360205724817658511806303644281231496550704751025446501172721155519486685080036853228183152196003735625279449515828418829478761085263981395599006737648292244375287184624578036192981971399147564488262603903381441823262515097482798777996437308997038886778227138360577297882412561190717663946507063304527954661855096666185664709711344474016070462621568071748187784437143698821855967095910259686200235371858874856965220005031173439207321139080329363447972735595527734907178379342163701205005451326383544000186323991490705479778056697853358048966906295119432473099587655236812859041383241160722602998330535370876138939639177957454016137223618789365260538155841587186925538606164779834025435128439612946035291332594279490433729908573158029095863138268329147711639633709240031689458636060645845925126994655724839186564209752685082307544254599376917041977780085362730941710163434907696423722294352366125572508814779223151974778060569672538017180776360346245927877846585065605078084421152969752189087401966090665180351650179250461950136658543663271254963990854914420001457476081930221206602433009641270489439039717719518069908699860663658323227870937650226014929101151717763594460202324930028040186772391028809786660565118326004368850881715723866984224220102495055188169480322100251542649463981287367765892768816359831247788652014117411091360116499507662907794364600585194199856016264790761532103872755712699251827568798930276176114616254935649590379804583818232336861201624373656984670378585330527583333793990752166069238053369887956513728559388349989470741618155012539706464817194670834819721448889879067650379590366967249499254527903372963616265897603949857674139735944102374432970935547798262961459144293645142861715858733974679189757121195618738578364475844842355558105002561149239151889309946342841393608038309166281881150371528496705974162562823609216807515017772538740256425347087908913729172282861151591568372524163077225440633787593105982676094420326192428531701878177296023541306067213604600038966109364709514141718577701418060644363681546444005331608778314317444081194942297559931401188868331483280270655383300469329011574414756313999722170380461709289457909627166226074071874997535921275608441473782330327033016823719364800217328573493594756433412994302485023573221459784328264142168487872167336701061509424345698440187331281010794512722373788612605816566805371439612788873252737389039289050686532413806279602593038772769778379286840932536588073398845721874602100531148335132385004782716937621800490479559795929059165547050577751430817511269898518840871856402603530558373783242292418562564425502267215598027401261797192804713960068916382866527700975276706977703643926022437284184088325184877047263844037953016690546593746161932384036389313136432713768884102681121989127522305625675625470172508634976536728860596675274086862740791285657699631378975303466061666980421826772456053066077389962421834085988207186468262321508028828635974683965435885668550377313129658797581050121491620765676995065971534476347032085321560367482860837865680307306265763346977429563464371670939719306087696349532884683361303882943104080029687386911706666614680001512114344225602387447432525076938707777519329994213727721125884360871583483562696166198057252661220679754062106208064988291845439530152998209250300549825704339055357016865312052649561485724925738620691740369521353373253166634546658859728665945113644137033139367211856955395210845840724432383558606310680696492485123263269951460359603729725319836842336390463213671011619282171115028280160448805880238203198149309636959673583274202498824568494127386056649135252670604623445054922758115170931492187959271800194096886698683703730220047531433818109270803001720593553052070070607223399946399057131158709963577735902719628506114651483752620956534671329002599439766311454590268589897911583709341937044115512192011716488056694593813118384376562062784631049034629395002945834116482411496975832601180073169943739350696629571241027323913874175492307186245454322203955273529524024590380574450289224688628533654221381572213116328811205214648980518009202471939171055539011394331668151582884368760696110250517100739276238555338627255353883096067164466237092264680967125406186950214317621166814009759528149390722260111268115310838731761732323526360583817315103459573653822353499293582283685100781088463434998351840445170427018938199424341009057537625776757111809008816418331920196262341628816652137471732547772778348877436651882875215668571950637193656539038944936642176400312152787022236646363575550356557694888654950027085392361710550213114741374410613444554419210133617299628569489919336918472947858072915608851039678195942983318648075608367955149663644896559294818785178403877332624705194505041984774201418394773120281588684570729054405751060128525805659470304683634459265255213700806875200959345360731622611872817392807462309468536782310609792159936001994623799343421068781349734695924646975250624695861690917857397659519939299399556754271465491045686070209901260681870498417807917392407194599632306025470790177452751318680998228473086076653686685551646770291133682756310722334672611370549079536583453863719623585631261838715677411873852772292259474337378569553845624680101390572787101651296663676445187246565373040244368414081448873295784734849000301947788802046032466084287535184836495919508288832320652212810419044804724794929134228495197002260131043006241071797150279343326340799596053144605323048852897291765987601666781193793237245385720960758227717848336161358261289622611812945592746276713779448758675365754486140761193112595851265575973457301533364263076798544338576171533346232527057200530398828949903425956623297578248873502925916682589445689465599265845476269452878051650172067478541788798227680653665064191097343452887833862172615626958265447820567298775642632532159429441803994321700009054265076309558846589517170914760743713689331946909098190450129030709956622662030318264936573369841955577696378762491885286568660760056602560544571133728684020557441603083705231224258722343885412317948138855007568938112493538631863528708379984569261998179452336408742959118074745341955142035172618420084550917084568236820089773945584267921427347756087964427920270831215015640634134161716644806981548376449157390012121704154787259199894382536495051477137939914720521952907939613762110723849429061635760459623125350606853765142311534966568371511660422079639446662116325515772907097847315627827759878813649195125748332879377157145909106484164267830994972367442017586226940215940792448054125536043131799269673915754241929660731239376354213923061787675395871143610408940996608947141834069836299367536262154524729846421375289107988438130609555262272083751862983706678722443019579379378607210725427728907173285487437435578196651171661833088112912024520404868220007234403502544820283425418788465360259150644527165770004452109773558589762265548494162171498953238342160011406295071849042778925855274303522139683567901807640604213830730877446017084268827226117718084266433365178000217190344923426426629226145600433738386833555534345300426481847398921562708609565062934040526494324426144566592129122564889356965500915430642613425266847259491431423939884543248632746184284665598533231221046625989014171210344608427161661900125719587079321756969854401339762209674945418540711844643394699016269835160784892451405894094639526780735457970030705116368251948770118976400282764841416058720618418529718915401968825328930914966534575357142731848201638464483249903788606900807270932767312758196656394114896171683298045513972950668760474091542042842999354102582911350224169076943166857424252250902693903481485645130306992519959043638402842926741257342244776558417788617173726546208549829449894678735092958165263207225899236876845701782303809656788311228930580914057261086588484587310165815116753332767488701482916741970151255978257270740643180860142814902414678047232759768426963393577354293018673943971638861176420900406866339885684168100387238921448317607011668450388721236436704331409115573328018297798873659091665961240202177855885487617616198937079438005666336488436508914480557103976521469602766258359905198704230017946553678856743028597460014378548323706870119007849940493091891918164932725977403007487968148488234293202301212803232746039221968752834051690697419425761467397811071546418627336909158497318501118396048253351874843892317729261354302493256289637136197728545662292446164449728459786771157412567030787188510933634448014967524061853656953207417053348678275482781541556196691105510147279904038689722046555083317078239480878599050194756310898412414467282186545997159663901564194175182093593261631688838013275875260146050767609839262572641112013528859131784829947568247256488553335727977220554356812630253574821658541400080531482069713726214975557605189048162237679041492674260007104592269531483518813746388710427354476762357793399397063239660496914530327388787455790593493777232014295480334500069525698093528288778371067058556774948137385863038576282304069400566534058488752700530883245918218349431804983419963998145877343586311594057044368351528538360944295596436067609022174189688354813164399743776415836524223464261959739045545068069523285075186871944906476779188672030641863075105351214985105120731384664871754751838297999018931775155063998101646641459210240683829460320853555405814715927322067756766921366408150590080695254061062853640829327662193193993386162383606911176778544823612932685819996523927548842743541440288453645559512473554613940315495209739705189624015797683263945063323045219264504965173546677569929571898969047090273028854494541669979199294803825498028594602905276314558031651406622917122342937580614399348491436210799357673731794896425248881372043557928751138585697338197608352442324046677802094839963994668483377470672548361884827300064831916382602211055522124673332318446300550448184991699662208774614021615702102960331858872733329877935257018239386124402686833955587060775816995439846956854067117444493247951957215941964586373612691552645757478698596424217659289686238350637043393981167139754473622862550680368266413554144804899;

		// Base of natural logarithm
                                       // 'e' was previously used to be
                                       // the charge of the electron, but
                                       // changed to this.  Mathematicians and
                                       // particle physicists may battle this
                                       // out.

EulerMascheroniConstant := 0.577215664901532860606512;
                // See http://en.wikipedia.org/wiki/Euler-Mascheroni_constant

c :=                   299792458 m/s;   // speed of light in vacuum (exact)
light :=               c;
lightspeed :=          c;               // sure, why not.

mu0 :=                 4 pi 1e-7 N/A^2; // permeability of vacuum (exact)
magneticconstant :=     mu0;
permeabilityofvacuum := mu0;
mu0 ||| permeability;

epsilon0 :=            1/(mu0 c^2);     // permittivity of vacuum (exact)
                                       // This is equivalent to about
                                       // 8.85e-12 farads/meter
permittivityofvacuum := epsilon0;
electricconstant :=     epsilon0;

epsilon0 ||| permittivity;
energy :=              c^2;             // convert mass to energy

electroncharge :=   1.60217653e-19 C;     // electron charge, also called e
                                         // but that's reserved for the
                                         // base of the natural logarithm
                                     // This is the 2002 CODATA recommended
                                     // value.  Standard uncertainty is
                                     // +/- 14 in the last 2 digits.
                             // http://physics.nist.gov/cgi-bin/cuu/Value?e

h :=                 6.6260693e-34 J s;  // Planck's constant, given by 2002
                              // CODATA figures.  There is a standard
                              // uncertainty in the last 2 digits of +/- 11
                              // http://physics.nist.gov/cgi-bin/cuu/Value?h


classicalElectronRadius := 2.817940325e-15 m;   // 2002 CODATA value
                            // http://physics.nist.gov/cgi-bin/cuu/Value?re
                            // uncertainty is +/- 28 in the last 2 digits
r_e := classicalElectronRadius;

ThomsonCrossSection :=  0.665245873e-28 m^2;    // 2002 CODATA value
                    // http://physics.nist.gov/cgi-bin/cuu/Value?sigmae
                    // The "classical" cross-section of an electron when
                    // illuminated by radiation.
                    // Uncertainty is +/- 13 in the last 2 digits.
sigma_e := ThomsonCrossSection;
sigma_t := ThomsonCrossSection;
                              

plancksconstant :=     h;
//\u210e :=              h;          // Official Unicode char for Planck's const.
hbar :=                h / (2 pi);
//\u210f :=              hbar;       // Official Unicode char for Planck/2 pi

G :=             6.6742e-11 N m^2 / kg^2;  // Newtonian gravity constant
        // From 2002 CODATA figures.  There is a standard uncertainty in the
        // last two figures of +/- 10
        // Given by http://physics.nist.gov/cgi-bin/cuu/Value?bg

coulombconst :=        1/(4 pi epsilon0); // listed as "k" sometimes

au :=                  149597870691. m;  // astronomical unit, the average
                                        // radius of earth's orbit around the
                                        // sun, as defined by the IAU (1976).
                                        // Estimated error +/- 30 m

                       // Actually, the official definition from the IAU is:
                       // "the distance from the Sun at which a particle of
                       //  negligible mass, in an unperturbed circular orbit,
                       //  would have an orbital period of 365.2568983 days
                       // (a Gaussian year)."  Gee, thanks for that helpful
                       // definition, guys.

ua := au;               // The SI defines this abbreviation as its preferred 
                       // version

astronomicalunit :=    au;


//
// angular measure
//

circle :=              2 pi radian;
degree :=              (1/360) circle;
arcdegree :=           degree;
deg    :=              degree;
arcdeg :=              arcdegree;
arcminute :=           (1/60) degree;
arcmin :=              arcminute;
arcsecond :=           (1/60) arcmin;
arcsec :=              arcsecond;
mas :=                 milliarcsecond;
rightangle :=          90 degrees;
quadrant :=            (1/4) circle;
quintant :=            (1/5) circle;
sextant :=             (1/6) circle;

sign :=                (1/12) circle;// Angular extent of one sign of the zodiac
turn :=                circle;
revolution :=          turn;
rev :=                 turn;
pulsatance :=          radian / sec;
gon :=                 (1/100) rightangle; // measure of grade
grade :=               gon;
centesimalminute :=    (1/100) grade;
centesimalsecond :=    (1/100) centesimalminute;
milangle :=            (1/6400) circle;    // Official NIST definition.
                                         // Another choice is 1ee-3 radian.
pointangle :=          (1/32) circle;
centrad :=             (1/100) radian; // Used for angular deviation of light
                                    // through a prism.

brad := (1/256) circle;  // Binary radian--used to fit angular measurements into
                      // a byte.  Questionable but what the hell.

//
// Solid angle measure
//

sphere :=              4 pi sr;
squaredegree :=        (1/180^2) pi^2 sr;
squareminute :=        (1/60^2) squaredegree;
squaresecond :=        (1/60^2) squareminute;
squarearcmin :=        squareminute;
squarearcsec :=        squaresecond;
sphericalrightangle := (1/2) pi sr;
octant :=              (1/2) pi sr;

//
// Concentration measures
//

percent :=             1/100;
proof :=               1/200;     // Alcohol content measured by volume at
                                 // 60 degrees Fahrenheit.  This is a USA
                                 // measure.  In Europe proof=percent.
ppm :=                 1ee-6;
partspermillion :=     ppm;
ppb :=                 1ee-9;
partsperbillion :=     ppb;      // USA billion
ppt :=                 1ee-12;
partspertrillion :=    ppt;      // USA trillion
karat :=               1/24;     // measure of gold purity
fine :=                1/1000;   // Measure of gold purity
caratgold :=           karat;
gammil :=              mg/l;
basispoint :=          (1/100) percent;// Used in finance 

//
// Temperature difference
// The units below are NOT an absolute temperature measurement in Fahrenheit,
// but represents the size of a degree in the specified systems.
degcelsius :=          K;
degreeCelsius :=       K;     // Per http://physics.nist.gov/Pubs/SP811/sec04.html#4.2.1.1     
degC :=                K;     // The *size* of a degree in the Celsius scale.
                             // This is identical to the size of a Kelvin.
                             // WARNING: This should only be used when 
                             // you're indicating the *difference* between
                             // two temperatures, (say, how much energy to 
                             // raise the temperature of a gram of water by 5
                             // degrees Celsius, *not* for absolute
                             // temperatures.  (I wonder if they should go 
                             //   entirely to eliminate this confusion...)
                             // For calculating absolute temperatures, use
                             // the Celsius[] or C[] functions below.
                             //
                                 // In 1741  Anders Celsius introduced a
                                 // Temperature scale with water boiling at 0
                                 // degrees and freezing at 100 degrees at
                                 // standard pressure.  After his death the
                                 // fixed points were reversed and the scale
                                 // was called the centigrade scale.  Due to 
                                 // the difficulty of accurately measuring the
                                 // temperature of melting ice at standard
                                 // pressure, the centigrade scale was replaced
                                 // in 1954 by the Celsius scale which is
                                 // defined by subtracting 273.15 from the
                                 // temperature in Kelvins.  This definition
                                 // differed slightly from the old centigrade
                                 // definition, but the Kelvin scale depends on
                                 // the triple point of water rather than a
                                 // melting point, so it can be measured
                                 // accurately.

zerocelsius := 273.15 K;      // Defined by the 10th CGPM, 1954, Resolution 3;
                             // CR, 79.  The triple point of water was defined
                             // at the same time to be 273.16 Kelvin, and
                             // the reference temperature 273.15 K (the ice
                             // point) to be the scale difference between
                             // Kelvin and Celsius.  So, the size of a Kelvin
                             // and a degree Celsius are the same, but
                             // the zero point of the Celsius scale is actually
                             // set to .01 Kelvin below the triple point.


degfahrenheit :=  (5/9) degC;   // The *size* of a degree in the Fahrenheit scale.
degreeFahrenheit := degfahrenheit; // The *size* of a degree in the Fahrenheit scale.
degF :=        degfahrenheit; // WARNING: These should only be used when 
                             // you're indicating the *difference* between
                             // two temperatures, (say, how much energy to 
                             // raise the temperature of a gram of water by 5
                             // degrees Fahrenheit, *not* for absolute
                             // temperatures.  (I wonder if they should go 
                             //   entirely to eliminate this confusion...)
                             // For calculating absolute temperatures, use
                             // the Fahrenheit[] or F[] functions below.
                             //
                             // Fahrenheit defined his temperature scale
                             // by setting 0 to the coldest temperature
                             // he could produce and by setting 96 degrees
                             // to body heat (for reasons unknown).


//\u2109 :=              degfahrenheit  // Single Unicode codepoint for 
                                      // DEGREE FAHRENHEIT

degreesRankine :=      (5/9) K;
degreesrankine :=      degreesRankine;   // The Rankine scale has the 
degrankine :=          degreesRankine;   // Fahrenheit degree, but its zero
degreerankine :=       degrankine;       // is at absolute zero.
degR :=                degrankine;
Rankine :=             degreesrankine;

degreaumur :=          (10/8) degC; // The Reaumur scale was used in Europe and
                                 // particularly in France.  It is defined
                                 // to be 0 at the freezing point of water
                                 // and 80 at the boiling point.  Reaumur
                                 // apparently selected 80 because it is
                                 // divisible by many numbers.

// Function for converting Fahrenheit to/from standard units

// This is a less legible version of the revised function below
Fahrenheit{x} := (x conforms K) ? ((x - zerocelsius) / K) * 9/5 + 32 : ((x conforms 1) ? ((x-32) * 5/9) K + zerocelsius : "Error");

//Fahrenheit[x] := 
//{ 
//   if (x conforms K)  // If x is already a temperature, convert to F
//      return ((x - zerocelsius) / K) * 9/5 + 32 
//   else
//      if (x conforms 1) // If x is a pure number, treat as Fahrenheit degrees
//         return ((x-32) * 5/9) K + zerocelsius
//      else
//         return "Error"
//}

// TODO: Change the implementation of the following idiom so that it aliases 
// the function instead of chaining function calls. 
F{x} := Fahrenheit[x];

// Function for converting Celsius to/from standard units
Celsius{x} := (x conforms K) ? (x-zerocelsius) / K : ((x conforms 1) ? (x K + zerocelsius) : "Error");

C{x} := Celsius[x];

Reaumur{x} := (x conforms K) ? (8/10 (x-zerocelsius)) / K : ((x conforms 1) ? (10/8 * x * K + zerocelsius) : "Error");

//   Physical constants
//

gravity :=             (980665/100000) m/s^2;  // std acceleration of gravity 
                                            // (exact)
g_n :=                 gravity;
gee :=                 gravity;
gravities :=           gravity;             // Irregular plural
force :=               gravity;         // use to turn masses into forces

// Various conventional values

atm :=                 101325 Pa;       // Standard atmospheric pressure (exact)
atmosphere :=          atm;
Hg :=         13.5951 gram / cm^3;      // Density of mercury (defined)
mercurydensity :=      Hg;
water :=               gram / cm^3;     // Standard density of water (defined)
H2O :=                 water;
wc :=                  water;           // water column
mach :=                331.46 m/s;      // speed of sound in dry air at STP
standardtemp :=        273.15 K;        // standard temperature
stdtemp :=             standardtemp;

// Physico-chemical constants

// Atomic mass unit is given by the 2002 CODATA value
// http://physics.nist.gov/cgi-bin/cuu/Value?u
atomicmassunit :=      1.66053886e-27 kg;   // atomic mass unit 
                                           // error is +/- 28 in last 2 digits
                                       // (defined to be 1/12 of the mass of
                                       //  carbon 12)

m_u :=                 atomicmassunit;
u :=                   atomicmassunit;  // 1/12 of the mass of carbon 12)
amu :=                 atomicmassunit;

amu_chem :=            1.66026e-27 kg;  // 1/16 of the weighted average mass of
                                       //   the 3 naturally occuring neutral
                                       //   isotopes of oxygen

amu_phys :=            1.65981e-27 kg;  // 1/16 of the mass of a neutral
                                       //   oxygen 16 atom

dalton :=              u;               // Maybe this should be amu_chem?
avogadro :=            grams/(amu mol); // size of a mole
N_A :=                 avogadro;

gasconstant :=       8.314472 J / (mol K);  // molar gas constant, 2006 CODATA
                                       // value.  Standard uncertainty is
                                       // +/- 15 in last 2 digits
                          // http://physics.nist.gov/cgi-bin/cuu/Value?r

R :=                   gasconstant;
boltzmann :=           R / N_A;         // Boltzmann's constant
boltzmannsconstant :=  boltzmann;       // Boltzmann's constant
k :=                   boltzmann;
molarvolume :=     mol R stdtemp / atm; // Volume occupied by one mole of an
                                       //   ideal gas at STP.

molar :=               mol / l;         // Unit of concentration (moles/liter)
Molar :=               molar;           // Sometimes capitalized

molar ||| concentration_by_volume;

molal :=               mol / kg;        // Unit of concentration (moles/kg)

molal ||| concentration_by_mass;

m^3/mol ||| molar_volume;

loschmidt := avogadro mol / molarvolume;// Molecules per cubic meter of an
                                       //   ideal gas at STP.  Loschmidt did
                                       //   work similar to Avogadro.  
stefanboltzmann :=  2 pi^5 k^4 / (15 h^3 c^2);  // The radiant emittance by a 
                                       //   blackbody 
sigma :=               stefanboltzmann; //   at temperature T is given by 
                                       //   sigma T^4.

wiendisplacement :=  2.8977685e-3 m K;   // Wien's Displacement Law gives the
                                        //   frequency at which the the Planck
                                        //   spectrum has maximum intensity.
                                        //   The relation is lambda T = b where
                                        //   lambda is wavelength, T is
                                        //   temperature and b is the Wien
                                        //   displacement.  This relation is
                                        //   used to determine the temperature
                                        //   of stars.  This is the 2002
                                        //   CODATA value.  Standard
                                        // uncertainty is +/- 51 in last 2
                                        // digits.

K_J := 2 electroncharge/h;  // Josephson Constant
                       // Direct measurement of the volt is difficult.  Until
                       //   recently, laboratories kept Weston cadmium cells as
                       //   a reference, but they could drift.  In 1987 the
                       //   CGPM officially recommended the use of the
                       //   Josephson effect as a laboratory representation of
                       //   the volt.  The Josephson effect occurs when two
                       //   superconductors are separated by a thin insulating
                       //   layer.  A "supercurrent" flows across the insulator
                       //   with a frequency that depends on the potential
                       //   applied across the superconductors.  This frequency
                       //   can be very accurately measured.  The Josephson
                       //   constant K_J, which is equal to 2e/h, relates the
                       //   measured frequency to the potential.  The value
                       //   given here is the officially specified value for
                       //   use beginning in 1990.  The 1998 recommended value
                       //   of the constant is 483597.898 GHz/V.

R_K := h/electroncharge^2; 
                       // Measurement of the ohm also presents difficulties.
                       //   The old approach involved maintaining resistances
                       //   that were subject to drift.  The new standard is
                       //   based on the Hall effect.  When a current carrying
                       //   ribbon is placed in a magnetic field, a potential
                       //   difference develops across the ribbon.  The ratio
                       //   of the potential difference to the current is
                       //   called the Hall resistance.  Klaus von Klitzing
                       //   discovered in 1980 that the Hall resistance varies
                       //   in discrete jumps when the magnetic field is very
                       //   large and the temperature very low.  This enables
                       //   accurate realization of the resistance h/e^2 in the
                       //   lab.  This is approximately equal to 25812.807 ohms


// Density of mercury and water at different temperatures using the standard
// force of gravity.

// Hg10C :=     13.5708 gram / cm^3 // These units, when used to form  
// Hg20C :=     13.5462 gram / cm^3 // pressure measures, are not accurate
// Hg23C :=     13.5386 gram / cm^3 // because of considerations of the
// Hg30C :=     13.5217 gram / cm^3 // revised practical temperature scale.
// Hg40C :=     13.4973 gram / cm^3
// Hg60F :=     13.5574 gram / cm^3  
// H2O0C :=     0.99987 gram / cm^3
// H2O5C :=     0.99999 gram / cm^3
// H2O10C :=    0.99973 gram / cm^3
// H2O15C :=    0.99913 gram / cm^3
// H2O18C :=    0.99862 gram / cm^3
// H2O20C :=    0.99823 gram / cm^3
// H2O25C :=    0.99707 gram / cm^3
// H2O50C :=    0.98807 gram / cm^3
// H2O100C :=   0.95838 gram / cm^3


// Masses of elementary particles, as given by 2002 CODATA-recommended values.
// http://physics.nist.gov/cuu/Constants/index.html

electronmass :=        9.1093826e-31 kg;     // +/- 16 in last 2 digits
m_e :=                 electronmass;

protonmass :=          1.67262171e-27 kg;    // +/- 27 in last 2 digits
m_p :=                 protonmass;

neutronmass :=         1.67492728e-27 kg;    // +/- 29 in last 2 digits
m_n :=                 neutronmass;

muonmass :=            1.88353140e-28 kg;    // +/- 33 in last 2 digits
m_mu :=                muonmass;
m_muon   :=            muonmass;

deuteronmass :=        3.34358335e-27 kg;    // +/- 57 in last 2 digits
m_d :=                 deuteronmass;

alphaparticlemass :=   6.6446565e-27 kg;     // +/- 11 in last 2 digits
m_alpha :=             alphaparticlemass;

taumass :=             3.16777e-27 kg;       // +/- 52 in last 2 digits
m_tau   :=             taumass;


// Atomic constants

alpha :=               7.297352568e-3;   // 2002 CODATA value
                        // http://physics.nist.gov/cgi-bin/cuu/Value?alph
                        // Standard uncertainty is +/- 24 in the last 2 
                        // decimal places.
                        // This can also be given by:
                                        // mu0 c electroncharge^2 / (2 h)
                                        // The fine structure constant was
                                        //   introduced to explain fine
                                        //   structure visible in spectral
                                        //   lines.
finestructureconstant :=  alpha;

// Rydberg constant
Rydberg_constant :=    10973731.568525 m^-1;  // 2002 CODATA value
          // http://physics.nist.gov/cgi-bin/cuu/Value?ryd
          // The standard uncertainty is +/- 73 in the last 2 decimal places.

Rinfinity :=           Rydberg_constant; //m_e c alpha^2 / (2 h)

                                        // The wavelengths of a spectral series
R_H :=                 10967760 /m;      //   can be expressed as 
                                        //     1/lambda = R (1/m^2 - 1/n^2).
                                        //   where R is a number that various
                                        //   slightly from element to element.
                                        //   For hydrogen, R_H is the value,
                                        //   and for heavy elements, the value
                                        //   approaches Rinfinity.

bohrradius :=          alpha / (4 pi Rinfinity);

// Planck constants

planckmass :=          (hbar c / G)^(1/2);
m_P :=                 planckmass;
plancktime :=          hbar / (planckmass c^2);
t_P :=                 plancktime;
plancklength :=        plancktime c;
l_P :=                 plancklength;

// particle wavelengths: the compton wavelength of a particle is
// defined as h / m c where m is the mass of the particle.

electronwavelength :=  h / (m_e c);
lambda_C :=            electronwavelength;
Comptonwavelength :=   electronwavelength;

protonwavelength :=    h / (m_p c);
lambda_C_p :=          protonwavelength;
neutronwavelength :=   h / (m_n c);
lambda_C_n :=          neutronwavelength;


// Magnetic moments

bohrmagneton :=        electroncharge hbar / (2 electronmass);
mu_B :=                bohrmagneton;
nuclearmagneton :=     electroncharge hbar / (2 protonmass);
mu_N :=                nuclearmagneton;


// Values below are from 2002 CODATA values

muonmagneticmoment :=   -4.49044799e-26 J/T; // +/- 40 in last 2 digits
mu_mu :=               muonmagneticmoment;

protonmagneticmoment := 1.41060671e-26 J/T;  // +/- 12 in last 2 digits
mu_p :=                 protonmagneticmoment;

electronmagneticmoment:= -928.476412e-26 J/T; // +/- 80 in last 2 digits
mu_e :=                  electronmagneticmoment;

neutronmagneticmoment := -0.96623645e-26 J/T; // +/- 24 in last 2 digits
mu_n :=                  neutronmagneticmoment;

deuteronmagneticmoment := 0.433073482e-26 J/T; // +/- 38 in last 2 digits
mu_d :=                   deuteronmagneticmoment;


//
// United States units
//

// linear measure

// The US Metric Law of 1866 gave the exact relation 1 meter = 39.37 inches.
// From 1893 until 1959, the foot was exactly 1200/3937 meters.  In 1959
// the definition was changed to bring the US into agreement with other
// countries.  Since then, the foot has been exactly 0.3048 meters.  At the
// same time it was decided that any data expressed in feet derived from
// geodetic surveys within the US would continue to use the old definition.

inch :=                254/100 cm;    
inches := inch;
foot :=                12 inch;
feet :=                foot;
ft :=                  foot;
survey ::-             1200/3937 m/ft;  // Ratio to give survey length
geodetic ::-           survey;
statute ::-            survey;
int :-                3937/1200 ft/m;   // Convert US Survey measures to
                                       //   international measures

inches :=              inch;   // Wacky plural
in :=                  inch;
yard :=                3 ft;
yd :=                  yard;
mile :=                5280 ft;
miles := mile;

line :=                1/12 inch; // Also defined as '.1 in' or as '1e-8 Wb'
rod :=                 11/2 surveyyard;
rd  :=                 rod;
perch :=               rod;
furlong :=             40 rod;          // From "furrow long" 
statutemile :=         statute mile;
league :=              3 statute mile;

// Calories: energy to raise a gram of water one degree celsius

cal_IT :=              41868/10000 J;    // International Table calorie
cal_th :=              4184/1000 J;     // Thermochemical calorie
cal_fifteen :=         4.18580 J;   // Energy to go from 14.5 to 15.5 degC
cal_twenty :=          4.18190 J;   // Energy to go from 19.5 to 20.5 degC
cal_mean :=            4.19002 J;   // 1/100 energy to go from 0 to 100 degC
calorie :=             cal_IT;
cal :=                 calorie;
calorie_IT :=          cal_IT;
thermcalorie :=        cal_th;
calorie_th :=          thermcalorie;
Calorie :=             kilocalorie; // the food Calorie
thermie :=          1ee6 cal_fifteen;// Heat required to raise the
                                    // temperature of a tonne of
                                    // water from 14.5 to 15.5 degC.

//
// Units derived from physical constants
//

inHg :=                inch gravity Hg;   // Inches of mercury
inH2O :=               inch gravity water;
inchmercury :=         inHg;
inchesmercury :=       inHg;              // Irregular plural
mmH2O :=               mm gravity water;
mmHg :=                mm gravity Hg;

kgf :=                 kg gravity;
technicalatmosphere := kgf / cm^2;
at :=                  technicalatmosphere;
hyl :=                 kgf s^2 / m;  // Also gram-force s^2/m according to [15]
torr :=                101325/760 Pa; // Exactly defined.  Differs from mmHg by
                                     // about 1 part in 7 million.
Torr :=                torr;     // Accepted symbol is Torr
                                // These units, both named after Evangelista
tor :=                 Pa;       // Torricelli, should not be confused.  
                                // Acording to [15] the torr is actually 
                                // atm/760 which is slightly different.

eV :=        electroncharge V;  // Energy acquired by a particle with charge e
electronvolt :=        eV;      //   when it is accelerated through 1 V
lightyear :=           c 365.25 day; // The 365.25 day year is specified in
                                    // NIST publication 811
ly :=                  lightyear;
lightsecond :=         c s;
lightminute :=         c min;
parsec :=              au radian / arcsec; // Unit of length equal to distance
pc :=                  parsec;             //   from the sun to a point having
                                           //   heliocentric parallax of 1
                                           //   arcsec (derived from parallax
                                           //   second) The formula should use
                                           //   tangent, but the error is about
                                           //   1e-12.
rydberg :=             h c Rinfinity;      // Rydberg energy
crith :=               0.089885 gram;      // The crith is the mass of one
                                           //   liter of hydrogen at standard
                                           //   temperature and pressure.
amagatvolume :=        molarvolume;
amagat :=  mol/amagatvolume;               // Used to measure gas densities
lorentz :=             bohrmagneton / (h c);// Used to measure the extent
                                           //   that the frequency of light
                                           //   is shifted by a magnetic field.
cminv :=               h c / cm;            // Unit of energy used in infrared
invcm :=               cminv;               //   spectroscopy.  
wavenumber :=          cminv;
kcal_mol :=            kcal / (mol N_A);     // kcal/mol is used as a unit of
                                            //   energy by physical chemists.
//
// CGS system based on centimeter, gram and second
//

dyne :=                cm gram / s^2 ; // force
dyn :=                 dyne;
erg :=                 cm dyne;        // energy
poise :=               gram / (cm s);  // viscosity, honors Jean Poiseuille
P :=                   poise;
poise ||| viscosity;

rhe :=                 poise^-1;        // reciprocal viscosity
rhe ||| reciprocal_viscosity;

stokes :=              cm^2 / s;       // kinematic viscosity
St :=                  stokes;
stokes ||| kinematic_viscosity;
stoke :=               stokes;
lentor :=              stokes;         // old name
Gal :=                 cm / s^2;       // acceleration, used in geophysics
galileo :=             Gal;            // for earth's gravitational field
                                       // (note that "gal" is for gallon
                                       // but "Gal" is the standard symbol
                                       // for the gal which is evidently a
                                       // shortened form of "galileo".)
barye :=               dyne/cm^2;      // pressure
barad :=               barye;          // old name
kayser :=              1/cm;           // Proposed as a unit for wavenumber
balmer :=              kayser;         // Even less common name than "kayser"
kine :=                cm/s;           // velocity
bole :=                g cm / s;       // momentum
pond :=                gram force;
glug :=            gram force s^2 / cm;// Mass which is accelerated at
                                       //   1 cm/s^2 by 1 gram force
darcy :=       centipoise cm^2 /(s atm);// Measures permeability to fluid flow.
                                       // One darcy is the permeability of a
                                       // medium that allows a flow of cc/s of
                                       // a liquid of centipoise viscosity
                                       // under a pressure gradient of atm/cm.
mohm :=                cm / (dyn s);   // mobile ohm, measure of mechanical
mobileohm :=           mohm;           //   mobility
mechanicalohm :=       dyn s / cm;     // mechanical resistance
acousticalohm :=       dyn s / cm^5;   // ratio of the sound pressure of
                                      //   1 dyn/cm^2 to a source of strength
                                      //   1 cm^3/s

ray :=                 acousticalohm;
rayl :=                dyn s / cm^3;   // Specific acoustical resistance
eotvos :=              1ee-9 Gal/cm;   // Change in gravitational acceleration
                                      //   over horizontal distance

// Electromagnetic units derived from the abampere

abampere :=            10 A;           // Current which produces a force of
abamp :=               abampere;       //   2 dyne/cm between two infinitely
aA :=                  abampere;       //   long wires that are 1 cm apart
biot :=                aA;             // alternative name for abamp
Bi :=                  biot;
abcoulomb :=           abamp sec;
abcoul :=              abcoulomb;
abvolt :=              dyne cm  / (abamp sec);
abfarad :=             abampere sec / abvolt;
abhenry :=             abvolt sec / abamp;
abohm :=               abvolt / abamp;
abmho :=               abohm^-1;
gauss :=               abvolt sec / cm^2;
Gs :=                  gauss;
maxwell :=             abvolt sec;     // Also called the "line"
Mx :=                  maxwell;
oersted :=             gauss / mu0;
Oe :=                  oersted;
gilbert :=             gauss cm / mu0;
Gb :=                  gilbert;
Gi :=                  gilbert;
unitpole :=            4 pi maxwell;

// Gaussian system: electromagnetic units derived from statampere.
//
// Note that the Gaussian units are often used in such a way that Coulomb's law
// has the form F= q1 * q2 / r^2.  The constant 1/(4*pi*epsilon0)
// is incorporated
// into the units.  From this, we can get the relation force=charge^2/dist^2.
// This means that the simplification esu^2 = dyne cm^2 can be used to simplify
// units in the Gaussian system, with the curious result that capacitance can 
// be measured in cm, resistance in sec/cm, and inductance in sec^2/cm.  These
// units are given the names statfarad, statohm and stathenry below.  

statampere :=          10 A cm / (s c);
statamp :=             statampere;
statvolt :=            dyne cm / (statamp sec);
statcoulomb :=         statamp s;
esu :=                 statcoulomb;
statcoul :=            statcoulomb;
statfarad :=           statamp sec / statvolt;
cmcapacitance :=       statfarad;
stathenry :=           statvolt sec / statamp;
statohm :=             statvolt / statamp;
statmho :=             statohm^-1;
statmaxwell :=         statvolt sec;
franklin :=            statcoulomb;
debye :=               1ee-18 statcoul cm;// unit of electrical dipole moment
debye ||| electrical_dipole_moment;
helmholtz :=           debye/angstrom^2; // Dipole moment per area
jar :=                 1000 statfarad;   // approx capacitance of Leyden jar

//
// Some historical eletromagnetic units
//

intampere :=           0.999835 A;   // Defined as the current which in one
intamp :=              intampere;    //   second deposits .001118 gram of
                                     //   silver from an aqueous solution of
                                     //   silver nitrate.
intfarad :=            0.999505 F;
intvolt :=             1.00033 V;
intohm :=              1.000495 ohm; // Defined as the resistance of a
                                     //   uniform column of mercury containing
                                     //   14.4521 gram in a column 1.063 m
                                     //   long and maintained at 0 degC.
daniell :=             1.042 V;      // Meant to be electromotive force of a
                                     //   Daniell cell, but in error by .04 V
faraday := N_A electroncharge mol;    // Charge that must flow to deposit or
faraday_phys :=        96521.9 C;    //   liberate one gram equivalent of any
faraday_chem :=        96495.7 C;    //   element.  (The chemical and physical
                                     //   values are off slightly from what is
                                     //   obtained by multiplying by amu_chem
                                     //   or amu_phys.  These values are from
                                     //   a 1991 NIST publication.)  Note that
                                     //   there is a Faraday constant which is
                                     //   equal to N_A e and hence has units of
                                     //   C/mol.  
kappline :=            6000 maxwell; // Named by and for Gisbert Kapp
siemensunit :=         0.9534 ohm;   // Resistance of a meter long column of
                                     //   mercury with a 1 mm cross section.

//
// Photometric units
//

candle :=              1.02 candela; // Standard unit for luminous intensity
hefnerunit :=          0.9 candle;   //   in use before candela
hefnercandle :=        hefnerunit;   //
violle :=              20.17 cd;     // luminous intensity of 1 cm^2 of
                                     //   platinum at its temperature of
                                     //   solidification (2045 K)

lumen :=               cd sr;        // Luminous flux 
lm :=                  lumen;        //

talbot :=              lumen s;      // Luminous energy
lumberg :=             talbot;
talbot ||| luminous_energy;

m^-2 cd sr ||| illuminance;
lux :=                 lm/m^2;       // Illuminance or exitance (luminous
lx :=                  lux;          //   flux incident on or coming from
phot :=                lumen / cm^2; //   a surface)
ph :=                  phot;         //
footcandle :=          lumen/ft^2;   // Illuminance from a 1 candela source
                                     //    at a distance of one foot
metercandle :=         lumen/m^2;    // Illuminance from a 1 candela source
                                     //    at a distance of one meter

mcs :=                 metercandle s;// luminous energy per area, used to
                                     //    measure photographic exposure

// Luminance measures

nit :=                 cd/m^2;       // Luminance: the intensity per projected
stilb :=               cd / cm^2;    // area of an extended luminous source.
sb :=                  stilb;        // (nit is from latin nitere = to shine.)

apostilb :=            cd/(pi m^2);
asb :=                 apostilb;
blondel :=             apostilb;     // Named after a French scientist.
nox :=                 1ee-3 lux;     // These two units were proposed for
skot :=                1ee-3 apostilb;// measurements relating to dark adapted
                                     // eyes.

// Equivalent luminance measures.  These units are units which measure
// the luminance of a surface with a specified exitance which obeys
// Lambert's law.  (Lambert's law specifies that luminous intensity of
// a perfectly diffuse luminous surface is proportional to the cosine
// of the angle at which you view the luminous surface.)

equivalentlux :=       cd / (pi m^2);  // luminance of a 1 lux surface
equivalentphot :=      cd / (pi cm^2); // luminance of a 1 phot surface
lambert :=             cd / (pi cm^2);
footlambert :=         cd / (pi ft^2);

// Some luminance data from the IES Lighting Handbook, 8th ed, 1993

sunlum :=              1.6e9 cd/m^2; // at zenith
sunillum :=            100e3 lux;    // clear sky
sunillum_o :=          10e3 lux;     // overcast sky
sunlum_h :=            6e6 cd/m^2;   // value at horizon
skylum :=              8000 cd/m^2;  // average, clear sky
skylum_o :=            2000 cd/m^2;  // average, overcast sky
moonlum :=             2500 cd/m^2;

//
// Astronomical time measurements
//

anomalisticyear :=     365.2596 days;      // The time between successive
                                          //   perihelion passages of the 
                                          //   earth.
siderealyear :=        365.256360417 day;  // The time for the earth to make
                                          //   one revolution around the sun
                                          //   relative to the stars.
tropicalyear :=        365.242198781 day;  // The mean interval between vernal
                                          //   equinoxes.  Differs from the
                                          //   sidereal year by 1 part in
                                          //   26000 due to precession of the
                                          //   earth about its rotational axis
                                          //   combined with precession of the
                                          //   perihelion of the earth's
                                          //   orbit.
gaussianyear :=        365.2690 days;      // The orbital period of a body in
                                          //   circular orbit at a distance of
                                          //   1 au from the sun.  Calculated
                                          //   from Kepler's third law.
siderealday :=         23.934469444 hour;  // The sidereal day is the interval
siderealhour :=        1/24 siderealday;   //   between two successive transits
siderealminute :=      1/60 siderealhour;  //   of a star over the meridian,
siderealsecond :=      1/60 siderealminute;//   or the time required  for the
                                          //   earth to make one rotation
                                          //   relative to the stars.  The
                                          //   more usual solar day is the
                                          //   time required to make a
                                          //   rotation relative to the sun.
                                          //   Because the earth moves in its
                                          //   orbit, it has to turn a bit
                                          //   extra to face the sun again,
                                          //   hence the solar day is slightly
                                          //   longer.
anomalisticmonth :=    27.55454977 day;    // Time from perigee to perigee
nodicalmonth :=        27.2122199 day;     // The nodes are the points where
draconicmonth :=       nodicalmonth;       //   an orbit crosses the ecliptic.
draconiticmonth :=     nodicalmonth;       //   This is the time required to
                                          //   travel from the ascending node
                                          //   to the next ascending node.
siderealmonth :=       27.321661 day;      // Time required for the moon to
                                          //   orbit the earth
lunarmonth :=          29.5305555 day;     // Time between full moons. Full 
synodicmonth :=        lunarmonth;         //   moon occur when the sun and 
lunation :=            synodicmonth;       //   moon are on opposite sides of
lune :=                1/30 lunation;      //   the earth.  Since the earth
lunour :=              1/24 lune;          //   moves around the sun, the moon
                                          //   has to revolve a bit farther to
                                          //   get into the full moon
                                          //   configuration.
year :=                tropicalyear;
yr :=                  year;
years :=	year;

month :=              1/12 year;   // This is obviously an average for the 
                                   // limiting case... so is accurate in the
                                   // long term but useless for adding an 
                                   // offset to a specific date.

mo :=                  month;
decade :=              10 years;
century :=             100 years;
centuries :=           century;    // Irregular plural
millennium :=          1000 years;
millennia :=           millennium;
solaryear :=           year;
lunaryear :=           12 lunarmonth;
calendaryear :=        365 day;
commonyear :=          365 day;
leapyear :=            366 day;
julianyear :=          365.25 day;
juliancentury :=       36525 day;
juliancenturies :=     36525 day;
gregorianyear :=       365.2425 day;
islamicyear :=         354 day;         // A year of 12 lunar months. They
islamicleapyear :=     355 day;         // began counting on July 16, AD 622
                                        // when Muhammad emigrated to Medina
                                        // (the year of the Hegira).  They need
                                        // 11 leap days in 30 years to stay in
                                        // sync with the lunar year which is a
                                        // bit longer than the 29.5 days of the
                                        // average month.  
islamicmonth :=        1/12 islamicyear;// They have 29 day and 30 day months.
cron :=                1ee6 years;
lustrum :=             5 years;             // The Lustrum was a Roman
                                            //  purification ceremony that took
                                            //  place every five years.
                                            //  Classically educated Englishmen
                                            //  used this term. 

// The following are sidereal days unless otherwise noted

mercuryday :=          58.6462 day;
venusday :=            243.01 day;       // retrograde
earthday :=            siderealday;
marssiderealday :=     24 hours + 37 min + 22.663 sec;
marsday :=             marssiderealday;
marssolarday :=        24 hours + 39 min + 35.24409 sec;
jupiterday :=          0.41354 day;
saturnday :=           0.4375 day;
uranusday :=           0.65 day;         // retrograde
neptuneday :=          0.768 day;
plutoday :=            6.3867 day;

// Solar days

// Planetary sidereal years

mercuryyear :=         86.96 day;
venusyear :=           224.68 day;
earthyear :=           siderealyear;
marsyear :=            686.95 day;
jupiteryear :=         11.862 tropicalyear;
saturnyear :=          29.458 tropicalyear;
uranusyear :=          84.012 tropicalyear;
neptuneyear :=         164.798 tropicalyear;
plutoyear :=           248.5 tropicalyear;

//
// Some other astronomical values
//

sunmass :=             1.9891e30 kg;
sunradius :=           6.96e8 m;
sunpower :=            3.86e26 watts;

landarea :=            148.847e6 km^2;
oceanarea :=           361.254e6 km^2;

moonmass :=            7.3483e22 kg;
moonradius :=          1738 km;        // mean value

// Distances
sundist :=             1.0000010178 au;// mean earth-sun distance
sundist_near :=        1.471e11 m;     // earth-sun distance at perihelion
sundist_far :=         1.521e11 m;     // earth-sun distance at aphelion

// Average distances between planets and the sun.
mercurydist :=          57910. Mm;
venusdist   :=         108200. Mm;
earthdist   :=         sundist;
marsdist    :=         227940. Mm;
jupiterdist :=         778330. Mm;
saturndist  :=        1429400. Mm;
uranusdist  :=        2870990. Mm;
neptunedist :=        4497070. Mm;
plutodist   :=        5913520. Mm;

moondist :=            384400. km;      // mean earth-moon distance

mercurymass :=         0.33022e24 kg;
venusmass :=           4.8690e24 kg;
marsmass :=            0.64191e24 kg;
earthmass :=           5.9742e24 kg;
jupitermass :=         1898.8e24 kg;
saturnmass :=          568.5e24 kg;
uranusmass :=          86.625e24 kg;
neptunemass :=         102.78e24 kg;
plutomass :=           0.0127e24 kg;

mercuryradius :=        2439. km;
venusradius :=          6052. km;
marsradius :=           3397. km;
earthradius :=          6371.01 km;    // mean +/- 0.02 km
jupiterradius :=       71492. km;
saturnradius :=        60268. km;
uranusradius :=        25559. km;
neptuneradius :=       24764. km;
plutoradius :=          1137. km;

// These use the WGS84 datum, which is currently most commonly used
// in mapping.
earthradius_equatorial :=   6378137. m;
earthradius_polar :=        6356752.3142 m;
earth_flattening :=         (earthradius_equatorial-earthradius_polar)/earthradius_equatorial;
                    // http://www.uwgb.edu/dutchs/UsefulData/UTMFormulas.HTM
                            // http://ssd.jpl.nasa.gov/phys_props_earth.html

// Larger moons... their distances are the average distances from their planet.

// Mars
phobosdist := 9378.5 km;
phobosmass := 1.08e16 kg;

deimosdist := 23458. km;
deimosmass := 1.8e15 kg;

// Jupiter
iodist       := 422000. km;
ioradius     :=   1815. km;
iomass       := 8.93e22 kg;

europadist   := 670900. km;
europaradius :=   1569. km;
europamass   :=  4.80e22 kg;

ganymededist := 1070000. km;
ganymederadius := 2631. km;
ganymedemass := 1.48e23 kg;

callistodist := 1883000. km;
callistoradius := 2400. km;
callistomass := 1.08e23 kg;

// Saturn
titandist    := 1221850. km;
titanradius  := 2575. km;
titanmass    := 1.35e23 kg;

// Pluto
charondist := 19640. km;
charonradius := 586. km;
charonmass := 1.90e21 kg;

moongravity :=         1.62 m/s^2;

// General cosmological observations
hubbleconstant := 71 km/s/megaparsec;  // WMAP data, +0.04/-0.03 (factor)
H_0            := hubbleconstant;

atomicmass :=          electronmass;
atomiccharge :=        electroncharge;
atomicaction :=        hbar;


// Inverse time units
annually :=            1/year;
annual :=              annually;
yearly :=              annual;
daily :=               1/day;
weekly :=              1/week;
monthly :=             1/month;
hourly :=              1/hour;


// Perfect intervals

octave :=                 2;
majorthird :=             5/4;
minorthird  :=            6/5; 
musicalfourth :=          4/3;
musicalfifth :=           3/2;
majorsecond :=            musicalfifth^2 / octave;
majorsixth :=             musicalfourth majorthird;
minorsixth :=             musicalfourth minorthird;
majorseventh :=           musicalfifth majorthird;
minorseventh :=           musicalfifth minorthird;

pythagoreanthird :=       majorsecond musicalfifth^2 / octave;
syntoniccomma :=          pythagoreanthird / majorthird; 
pythagoreancomma :=       musicalfifth^12 / octave^7;

// Equal tempered definitions

semitone :=               octave^(1/12);


//
// The Hartree system of atomic units, derived from fundamental units
// of mass (of electron), action (planck's constant), charge, and
// the coulomb constant.

// Fundamental units
// derived units (Warning: accuracy is lost from deriving them this way)

atomiclength :=        bohrradius;
atomictime :=          hbar^3/(coulombconst^2 atomicmass electroncharge^4);
                       // Period of first Bohr orbit
atomicvelocity :=      atomiclength / atomictime;
atomicenergy :=        hbar / atomictime;
hartree :=             atomicenergy;
Hartree :=             hartree;

//
// These thermal units treat entropy as charge, from [5]
//

thermalcoulomb :=      J/K;       // entropy
thermalampere :=       W/K;       // entropy flow
thermalfarad :=        J/K^2;
thermalohm :=          K^2/W;     // thermal resistance
fourier :=             thermalohm;
thermalhenry :=        J K^2/W^2; // thermal inductance
thermalvolt :=         K;         // thermal potential difference



// surveyor's measure

surveyorschain :=      66 surveyft;
surveyorspole :=       1/4 surveyorschain;
surveyorslink :=       1/100 surveyorschain;
chain :=               surveyorschain;
surveychain :=         chain;
ch :=                  chain;
link :=                surveyorslink;
acre :=                43560 surveyfoot^2;  // NIST Handbook 44 has a
                                           // typographical error (forgetting
                                           // to underline feet in one place
                                           // on middle of page C-16 in 2003
                                           // edition) with
                                           // respect to this, but it's
                                           // clear from corroborating 
                                           // different figures in that 
                                           // document and NIST Special
                                           // Publication 811, Sec. B.6,
                                           // that the survey foot is
                                           // the proper definition.  Have
                                           // filed errata with NIST and 
                                           // requested confirmation.
                                           // 2003-08-27

intacre :=             43560 ft^2;  // Acre based on international ft
acrefoot :=            acre surveyfoot;
acrefeet :=            acrefoot;    // Irregular plural
section :=             surveymile^2;
township :=            36 section;
homestead :=           160 acre; // Area of land granted by the 1862 Homestead
                                // Act of the United States Congress
gunterschain :=        surveyorschain;

engineerschain :=      100 ft;
engineerslink :=       1/100 engineerschain;
ramsdenschain :=       engineerschain;
ramsdenslink :=        engineerslink;


// nautical measure

fathom :=              6 surveyft;  // Originally defined as the distance from
                                   //   fingertip to fingertip with arms fully
                                   //   extended.
fathoms := fathom;
nauticalmile :=        1852 m;  // Supposed to be one minute of latitude at
                               // the equator.  That value is about 1855 m.
                               // Early estimates of the earth's circumference
                               // were a bit off.  The value of 1852 m was
                               // made the international standard in 1929.
                               // The US did not accept this value until 
                               // July 1, 1954.  The UK switched in 1970.
                               // The value of this unit was adopted by the 
                               // First International Extraordinary 
                               // Hydrographic Conference, Monaco, 1929, 
                               // under the name "International nautical mile."

oldUSnauticalmile :=     6080.20 feet;  // Used in U.S. before July 1, 1954
oldUSknot :=             oldUSnauticalmile / hour;

cable :=               720 surveyfoot;    // NIST Handbook 44, 2003 Appendix C
cablelength :=         cable;
cableslength :=        cable;

metriccable :=         200 m;   // Used by France and Spain

navycablelength :=     720 surveyft;
marineleague :=        3 nauticalmile;
knot :=                nauticalmile / hr;
shackle := 15 fathoms;             // Adopted 1949 by British navy
oldUKRNshackle :=      12.5 fathoms; // Used by Royal Navy until 1949
watch :=               4 hours;    // time a sentry stands watch or a ship's
                                  // crew is on duty. 
bell :=                1/8 watch;  // Bell would be sounded every 30 minutes.

datamile :=            6000 feet;  // Defined by U.S. Department of Defense
                                  // as a unit used in radar measurements.

// Avoirdupois weight
// These are actually defined as mass units to follow the recommendations
// of the SI.

pound :=               45359237/100000000 kg;  // Defined exactly
pounds := pound;

lb :=                  pound;          // From the latin libra
lbs := pound;
grain :=               1/7000 pound;   // The grain is the same in all three
                                      // weight systems.  It was originally
                                      // defined as the weight of a barley
                                      // corn taken from the middle of the
                                      // ear.
gr := grain;
ounce :=               1/16 pound;
oz :=                  ounce;
dram :=                1/16 ounce;
drams := dram;
dr :=                  dram;
hundredweight :=       100 pounds;     // This is the USA hundredweight
cwt :=                 hundredweight;
shorthundredweight :=  hundredweight;
ton :=                 2000 lb;
shortton :=            ton;
shortquarter :=        1/4 shortton;


// Troy Weight.  In 1828 the troy pound was made the first United States
// standard weight.  It was to be used to regulate coinage.

troypound :=           5760 grain;
troyounce :=           1/12 troypound;
ozt :=                 troyounce;
pennyweight :=         1/20 troyounce;  // Abbreviated "d" in reference to a
dwt :=                 pennyweight;     //   Frankish coin called the "denier"
                                       //   minted in the late 700's.  There  
                                       //   were 240 deniers to the pound.
assayton :=            mg ton / troyounce;  // mg / assayton = troyounce / ton

// Some other jewelers units;

metriccarat :=         2/10 gram;
metricgrain :=         50 mg;
carat :=               metriccarat;
ct :=                  carat;
jewelerspoint :=       1/100 carat;
silversmithpoint :=    1/4000 inch;


// Apothecaries' weight

appound :=             troypound;
apounce :=             troyounce;
apdram :=              1/8 apounce;
scruple :=             1/3 apdram;

// Liquid measure

gallon :=              231 in^3;
gallons := gallon;
gal :=                 gallon;
quart :=               1/4 gallon;
quarts := quart;
qt :=                  quart;
pint :=                1/2 qt;
pints := pint;
pt :=                  pint;
gill :=                1/4 pint;
gills := gill;
fluidounce :=          1/16 pint;
fluidounces := fluidounce;
floz :=                fluidounce;
fluiddram :=           1/8 floz;
fluiddrams := fluiddram;
fldr :=                fluiddram;
minim :=               1/60 fldr;
liquidbarrel :=        31.5 gallon;
petroleumbarrel :=     42 gallon;      // Originated in Pennsylvania oil
                                      // fields, from the winetierce
barrel :=              petroleumbarrel;
oilbarrel :=           petroleumbarrel;
bbl :=                 barrel;
hogshead :=            63 gallon;
firkin :=              9 gallon;

// Dry measures: The Winchester Bushel was defined by William III in 1702 and
// legally adopted in the US in 1836.

drybarrel :=           7056 in^3;
bushel :=              2150.42 in^3; // Volume of 8 inch cylinder with 18.5
bushels := bushel;
bu :=                  bushel;       // inch diameter (rounded)
peck :=                1/4 bushel;
pecks := peck;
pk :=                  peck;
drygallon :=           1/2 peck;
dryquart :=            1/4 drygallon;
drypint :=             1/2 dryquart;

// Grain measures.  The bushel as it is used by farmers in the USA is actually
// a measure of mass which varies for different commodities.  Canada uses the
// same bushel masses for most commodities, but not for oats.

wheatbushel :=         60 lb;
soybeanbushel :=       60 lb;
cornbushel :=          56 lb;
ryebushel :=           56 lb;
barleybushel :=        48 lb;
oatbushel :=           32 lb;
ricebushel :=          45 lb;
canada_oatbushel :=    34 lb;

// Wine and Spirits measure

pony :=                1 floz;
jigger :=              1.5 floz;  // Can vary between 1 and 2 floz
shot :=                jigger;    // Sometimes 1 floz
eushot :=              20 ml;     // EU standard spirits measure
                  // See http://bundesrecht.juris.de/eo_1988/anhang_c_119.html
fifth :=               1/5 gallon;
winebottle :=          750 ml;    // US industry standard, 1979
winesplit :=           1/4 winebottle;
wineglass :=           4 floz;
magnum :=              1.5 liter; // Standardized in 1979, but given
                                 // as 2 qt in some references
metrictenth :=         375 ml;
metricfifth :=         750 ml;
metricquart :=         1 liter;

// French champagne bottle sizes

split :=               200 ml;
jeroboam :=            2 magnum;
rehoboam :=            3 magnum;
methuselah :=          4 magnum;
salmanazar :=          6 magnum;
balthazar :=           8 magnum;
nebuchadnezzar :=      10 magnum;

// Shoe measures

shoeiron :=            1/48 inch;   // Used to measure leather in soles
shoeounce :=           1/64 inch;   // Used to measure non-sole shoe leather

//
// USA slang units
//

buck :=                dollar;
fin :=                 5 dollar;
sawbuck :=             10 dollar;
key :=                 kg;          // usually of marijuana, 60's
lid :=                 1 oz;        // Another 60's weed unit
footballfield :=       100 yards;
marathon :=            26 miles + 385 yards;

//
// British
//

british :-             1200000/3937014 m/ft; // The UK lengths were defined by
                                            // a bronze bar manufactured in
                                            // 1844.  Measurement of that bar
                                            // revealed the dimensions given
                                            // here.

// Old nautical definitions;
// See:  http://www.hemyockcastle.co.uk/nautical.htm
oldbrnauticalmile :=   6080 ft;                 // Used until 1970 when the UK
oldbrknot :=           oldbrnauticalmile / hr;  // switched to the international
oldbrcable :=          1/10 oldbrnauticalmile;  // nautical mile.
geographicalmile :=    oldbrnauticalmile;
admiraltymile :=       oldbrnauticalmile;
admiraltyknot :=       oldbrknot;
admiraltycable :=      oldbrcable;
seamile :=             6000 ft;
cablet :=              120 fathoms;
hawserlaidcable :=     130 fathoms;

oldrussiancable :=     100 fathoms;
oldhollandcable :=     123 fathoms;
oldportugalcable:=     141 fathoms;

// British Imperial weight is mostly the same as US weight.  A few extra
// units are added here.

clove :=               7 lb;
stone :=               14 lb;
brhundredweight :=     8 stone;
brquartermass :=       1/4 brhundredweight;
longhundredweight :=   brhundredweight;
longton :=             20 brhundredweight;
brton :=               longton;
brassayton :=          mg brton / troyounce;

// British Imperial volume measures

brgallon :=        454609/100000 l;    // The British Imperial gallon was
canadiangallon :=      brgallon;       // defined in 1824 to be the volume of
cangallon :=           brgallon;       // water which weighed 10 pounds at 62
                                      // deg F with a pressure of 30 inHg.
                                      // In 1963 it was defined to be the space
                                      // occupied by 10 pounds of distilled
                                      // water of density 0.998859 g/ml weighed
                                      // in air of density 0.001217 g/ml
                                      // against weights of density 8.136 g/ml.
                                      // The value given here is given by [1]
                                      // as an exact value.
imperialgallon :=      brgallon;
brquart :=             1/4 brgallon;
imperialquart :=       brquart;
brpint :=              1/2 brquart;
imperialpint :=        brpint;
brfloz :=              1/20 brpint;  // Note difference in definition
imperialfloz :=        brfloz;
brdram :=              1/8 brfloz;
imperialdram :=        brdram;
brminim :=             1/60 brdram;
imperialminim :=       brminim;
brscruple :=           1/3 brdram;
imperialscruple :=     brscruple;
fluidscruple :=        brscruple;
brfluidounce :=        brfloz;
imperialfluidounce :=  brfloz;
brgill :=              1/4 brpint;
imperialgill :=        brgill;
brpeck :=              2 brgallon;
imperialpeck :=        brpeck;
brbarrel :=            36 brgallon; // Used for beer
imperialbarrel :=      brbarrel;
brbushel :=            4 brpeck;
imperialbushel :=      brbushel;
brheapedbushel := 1.278 brbushel;
brquarter := 8 brbushel;
brchaldron := 36 brbushel;

// Obscure British volume measures.  These units are generally traditional
// measures whose definitions have fluctuated over the years.  Often they
// depended on the quantity being measured.  They are given here in terms of
// British Imperial measures.  For example, the puncheon may have historically
// been defined relative to the wine gallon or beer gallon or ale gallon
// rather than the British Imperial gallon.

bag :=                 4 brbushel;
bucket :=              4 brgallon;
last :=                40 brbushel;
noggin :=              brgill;
pottle :=              1/2 brgallon;
pin :=                 4.5 brgallon;
puncheon :=            72 brgallon;
seam :=                8 brbushel;
coomb :=               4 brbushel;
boll :=                6 brbushel;
firlot :=              1/4 boll;
brfirkin :=            9 brgallon;    // Used for ale and beer
cran :=                37.5 brgallon; // measures herring, about 750 fish
barrelbulk :=          5 feet^3;
brhogshead :=          63 brgallon;
registerton :=         100 ft^3; // Used for internal capacity of ships
shippington :=         40 ft^3;  // Used for ship's cargo freight or timber
brshippington :=       42 ft^3;  //
freightton :=        shippington;// Both register ton and shipping ton derive
                                // from the "tun cask" of wine.
displacementton :=     35 ft^3;  // Approximate volume of a longton weight of
                                // sea water used to measure ship displacement
waterton :=            224 brgallon;
strike :=              70.5 l;    // 16th century unit, sometimes
                                 //   defined as .5, 2, or 4 bushels
                                 //   depending on the location.  It
                                 //   probably doesn't make a lot of
                                 //   sense to define in terms of imperial
                                 //   bushels.  Zupko gives a value of
                                 //   2 Winchester grain bushels or about
                                 //   70.5 liters.

// obscure British lengths

barleycorn :=     1/3 britishinch;  // Given in Realm of Measure as the
                                   // difference between successive shoe sizes
nail :=           1/16 britishyard; // Originally the width of the thumbnail,
                                   //   or 1/16 ft.  This took on the general
                                   //   meaning of 1/16 and settled on the
                                   //   nail of a yard or 1/16 yards as its
                                   //   final value.  [12]
pole :=                16.5 britishft;
rope :=                20 britishft;
englishell :=          45 britishinch;
flemishell :=          27 britishinch;
ell :=                 englishell;  // supposed to be measure from elbow to
                                   //   fingertips
span :=                9 britishinch;    // supposed to be distance from thumb
                                   //   to pinky with full hand extension
goad := 4.5 britishft;     // used for cloth

// misc obscure British units

rood :=                1/4 acre;
englishcarat :=        3.163 grain;    // Originally intended to be 4 grain
                                      //   but this value ended up being
                                      //   used in the London diamond market
mancus :=              2 oz;
mast :=                2.5 lb;
basebox :=             31360 in^2;     // Used in metal plating

// alternate spellings

metre :=               meter;
gramme :=              gram;
litre :=               liter;
dioptre :=             diopter;

//
// Units derived the human body (may not be very accurate)
//

geometricpace :=       5 ft;  // distance between points where the same
                             // foot hits the ground
pace :=                2.5 ft;// distance between points where alternate
                             // feet touch the ground
USmilitarypace :=      30 in; // United States official military pace
USdoubletimepace :=    36 in; // United States official doubletime pace
fingerbreadth :=       7/8 in;// The finger is defined as either the width
fingerlength :=        4.5 in;//   or length of the finger
finger :=              fingerbreadth;
hand :=                4 inch;// width of hand
palmwidth :=           hand;  // The palm is a unit defined as either the width
palmlength :=          8 in;  //    or the length of the hand

//
// Cooking measures
//

// US measures

cup :=                 8 floz;
cups := cup;
tablespoon :=          1/16 cup;
tablespoons := tablespoon;
tbl :=                 tablespoon;
tbsp :=                tablespoon;
Tbsp :=                tablespoon;
Tsp :=                 tablespoon;
teaspoon :=            1/3 tablespoon;
tsp :=                 teaspoon;
metriccup :=           250 ml;

// US can sizes. 

number1can :=          10 floz;
number2can :=          19 floz;
number2_5can :=        3.5 cups;
number3can :=          4 cups;
number5can :=          7 cups;
number10can :=         105 floz;

// British measures

brcup :=               1/2 brpint;
brteacup :=            1/3 brpint;
brtablespoon :=        15 ml;            // Also 5/8 brfloz, approx 17.7 ml
brteaspoon :=          1/3 brtablespoon; // Also 1/4 brtablespoon
dessertspoon :=        2 brteaspoon;
brtsp :=               brteaspoon;
brtbl :=               brtablespoon;
dsp :=                 dessertspoon;

// Australian

australiatablespoon := 20 ml;
austbl :=              australiatablespoon;

// Chinese
// Thai measurements are very similar so the name must be qualified
chinesecatty :=               1/2 kg;         
oldchinesecatty :=            4/3 lbs;       // Before metric conversion.
chinesetael :=           1/16 oldchinesecatty;
chinesemace :=           1/10 chinesetael;
oldchinesepicul :=             100 oldchinesecatty;
chinesepicul :=                100 chinesecatty;      // Chinese usage

// Thai weights
thaitical  := 15 grams;     
thaibaht   := thaitical;    // New name for thaitical, not to be confused with
                           // the Thai currency called "Thailand_baht". 
thaisalung := 1/4 thaitical;
thaifung   := 1/2 thaisalung;
thaisatang := 1/100 thaitical;
thaisadtahng := thaisatang;         // Alternate transliteration 
thaitamlung := 4 thaitical;
thaicatty   := 10 thaitamlung;
thaichang   := 2 thaicatty;
thaihap     := 50 thaichang;
thaipicul   := thaihap;
thaikoyan   := 20 thaipicul;


// Japanese

japancup :=            200 ml;

jo := 71 inches * 35.5 inches;   // The area of a standard tatami mat.
tatamimat := jo;

tsubo := 2 jo;	// Used in agriculture

// densities of cooking ingredients from The Cake Bible by Rose Levy Beranbaum
// so you can convert '2 cups sugar' to grams, for example, or in the other
// direction grams could be converted to 'cup flour_scooped'.  

butter :=              8. oz/cup;
butter_clarified :=    6.8 oz/cup;
cocoa_butter :=        9. oz/cup;
shortening :=          6.75 oz/cup;    // vegetable shortening
stickbutter := 1/4 lb; 
vegetable_oil :=       7.5 oz/cup;
cakeflour_sifted :=    3.5 oz/cup;     // The density of flour depends on the  
cakeflour_spooned :=   4. oz/cup;      // measuring method.  "Scooped",  or    
cakeflour_scooped :=   4.5 oz/cup;     // "dip and sweep" refers to dipping a  
flour_sifted :=        4. oz/cup;      // measure into a bin, and then sweeping
flour_spooned :=       4.25 oz/cup;    // the excess off the top.  "Spooned"   
flour_scooped :=       5. oz/cup;      // means to lightly spoon into a measure
breadflour_sifted :=   4.25 oz/cup;    // and then sweep the top.  Sifted means
breadflour_spooned :=  4.5 oz/cup;     // sifting the flour directly into a    
breadflour_scooped :=  5.5 oz/cup;     // measure and then sweeping the top.   
cornstarch :=          120. grams/cup;
dutchcocoa_sifted :=   75. g/cup;       // These are for Dutch processed cocoa
dutchcocoa_spooned :=  92. g/cup;
dutchcocoa_scooped :=  95. g/cup;
cocoa_sifted :=        75. g/cup;       // These are for nonalkalized cocoa
cocoa_spooned :=       82. g/cup;
cocoa_scooped :=       95. g/cup;
heavycream :=          232. g/cup;
milk :=                242. g/cup;
sourcream :=           242. g/cup;
molasses :=            11.25 oz/cup;
cornsyrup :=           11.5 oz/cup;
honey :=               11.75 oz/cup;
sugar :=               200. g/cup;
powdered_sugar :=      4. oz/cup;
brownsugar_light :=    217. g/cup;      // packed
brownsugar_dark :=     239. g/cup;

baking_powder :=       4.6 grams / tsp;
salt :=                6 g / tsp;
koshersalt :=          2.8 g / tsp;    // Diamond Crystal salt, from package
                                      // Note that Morton kosher salt is 
                                      // much denser.  

ethanol := .7893 g/cm^3;   // Density of ethanol
alcohol := ethanol;        // For now, density of ethanol
methanol := .79130 g/cm^3; // Density of methanol

// Egg weights and volumes for a USA large egg

egg :=                 50. grams;
eggwhite :=            30. grams;
eggyolk :=             18.6 grams;
eggvolume :=           3. tablespoons + 1/2 tsp;
eggwhitevolume :=      2. tablespoons;
eggyolkvolume :=       3.5 tsp;


//
// Units derived from imperial system
//

ouncedal :=            oz ft / s^2;    // force which accelerates an ounce
                                      //    at 1 ft/s^2
poundal :=             lb ft / s^2;    // same thing for a pound
tondal :=              ton ft / s^2;   // and for a ton
pdl :=                 poundal;
psi :=                 pound force / inch^2;
psia :=                psi;            // absolute pressure
tsi :=                 ton force / inch^2;
reyn :=                psi sec;
lbf :=                 lb force;
slug :=                lbf s^2 / ft;
slugf :=               slug force;
slinch :=              lbf s^2 / inch; // Mass unit derived from inch second
slinchf :=             slinch force;   //   pound-force system.  Used in space
                                      //   applications where in/sec^2 was a
                                      //   natural acceleration measure. 
geepound :=            slug;
tonf :=                ton force;
lbm :=                 lb;
kip :=                 1000 lbf;    // from kilopound
mil :=                 1/1000 inch;
thou :=                1/1000 inch;
circularinch :=        1/4 pi in^2; // area of a one-inch diameter circle
circularmil :=         1/4 pi mil^2;// area of one-mil diameter circle
cmil :=                circularmil;
cental :=              100 pound;
centner :=             cental;
caliber :=             1/100 inch;   // for measuring bullets
duty :=                ft lbf;
celo :=                ft / s^2;
jerk :=                ft / s^3;
australiapoint :=      1/100 inch;   // The "point" is used to measure rainfall
                                    //   in Australia
sabin :=               ft^2;         // Measure of sound absorption equal to the
                                    //   absorbing power of one square foot of
                                    //   a perfectly absorbing material.  The
                                    //   sound absorptivity of an object is the
                                    //   area times a dimensionless
                                    //   absorptivity coefficient.
standardgauge :=      4 ft + 8.5 in; // Standard width between railroad track
flag :=               5 ft^2;        // Construction term referring to sidewalk.
rollwallpaper :=      30 ft^2;       // Area of roll of wall paper
fillpower :=          in^3 / ounce;  // Density of down at standard pressure.
                                    //   The best down has 750-800 fillpower. 
pinlength :=          1/16 inch;     // A//17 pin is 17/16 in long in the USA.
buttonline :=         1/40 inch;     // The line was used in 19th century USA
                                    //   to measure width of buttons.
scoopnumber :=        quart^-1;      // Ice cream scoops are labeled with a  
                                    //   number specifying how many scoops  
                                    //   fill a quart.
//
// Other units of work, energy, power, etc
//


// Btu definitions: energy to raise a pound of water 1 degF
// "Btu" is the correct capitalization.
Btu :=                 cal lb degrankine / (gram K);// international table BTU
btu :=                 Btu;
BTU :=                 btu;
britishthermalunit :=  Btu;
Btu_IT :=              Btu;
btu_IT :=              Btu_IT;
Btu_th :=              cal_th lb degrankine / (gram K);
btu_th :=              Btu_th;
Btu_mean :=            cal_mean lb degrankine / (gram K);
btu_mean :=            Btu_mean;
quad :=                quadrillion Btu;

ECtherm :=             105506000 J;   // Exact definition, close to 1e5 Btu
UStherm :=             105480400 J;  // Exact definition
therm :=               UStherm;

// The horsepower is supposedly the power of one horse pulling.   Obviously
// different people had different horses.

horsepower :=          550 foot pound force / sec;  // Invented by James Watt
hp :=                  horsepower;
metrichorsepower :=    75 kilogram force meter / sec;
electrichorsepower :=  746 W;
boilerhorsepower :=    9809.50 W;
waterhorsepower :=     746.043 W;
brhorsepower :=        745.70 W;
donkeypower :=         250 W;
Wh :=                  watt hour;

// Thermal insulance and conductivity.

Rvalue :=         degrankine ft^2 hr / Btu;  // r-value, U.S. insulation figure
Cvalue :=         1/Rvalue;       // C-value U.S. insulation conductance rating
kvalue := Btu in / (ft^2 hr degF); // k-value, insulation conductance/in thick
Uvalue :=         1/Rvalue;
europeanUvalue := watt / (m^2 K);
RSI :=                 K m^2 / W;                 // SI insulation figure

// The following definitions are per NIST Special Publication 811:
// http://physics.nist.gov/Pubs/SP811/appenB9.html
W / (m K)   ||| thermal_conductivity;
m^2 K / W   ||| thermal_insulance;
K / W       ||| thermal_resistance;
m K / W     ||| thermal_resistivity;

// Term not defined by SI, somewhat questionable.  Used in building trade.
W / (m^2 K) ||| thermal_conductance;

// Defined by the BIPM,
//  http://www.bipm.org/pdf/si-brochure.pdf
J/kg        ||| specific_energy;
W/m^2       ||| heat_flux_density;
J/mol       ||| molar_energy;
J/(mol K)   ||| molar_heat_capacity;


// kvalue is defined as the amount of
// heat that will be transmitted through a one inch thick piece of
// homogenous material, one square foot in size, in one hour, when
// there is a one degree Fahrenheit temperature difference.
//
// Cvalue is the kvalue multiplied by the thickness in inches and thus
// gives the thermal conductance of a real piece of material with a given
// thickness.   
// Rvalue is the reciprocal of this, and refers to the thermal insulance of a
// real piece of material of a given, concrete thickness.

clo :=                 0.155 K m^2 / W;// Supposed to be the insulance 
                                      // required to keep a resting person
                                      // comfortable indoors.  The value
                                      // given is from NIST and the CRC,
                                      // but [5] gives a slightly different
                                      // value of 0.875 ft^2 degF hr / Btu.
// Misc other measures

clausius :=            1ee3 cal/K;      // A unit of physical entropy
langley :=             thermcalorie/cm^2;
poncelet :=            100 kg force m / s;
tonrefrigeration :=    ton 144 Btu / (lb day);// One ton refrigeration is
                                       // the rate of heat extraction required
                                       // turn one ton of water to ice in
                                       // a day.  Ice is defined to have a
                                       // latent heat of 144 Btu/lb.

tonsrefrigeration :=   tonrefrigeration;  // Irregular plural
tonref :=              tonrefrigeration;
refrigeration :=       tonref / ton;
frigorie :=            1000 cal_fifteen;// Used in refrigeration engineering.


// Energy in combustible fuels

TNT :=                 4184000000 J/ton;   // So you can write tons TNT, this
                                       // is a defined, not measured, value
PETN :=                6.01e6 J/kg;     // An explosive compound,
                                        // Pentaerythrite tetranitrate
                                        // used in plastic explosive like Semtex
gasoline :=            1.4e8 J/gallon;  // So you can convert energy
                                       // to gallons gasoline
gasoline_density := 0.694 g / cm^3; //Density at 300K, according to, http://wiki.answers.com/Q/How_does_temperature_affect_the_density_of_gasoline_or_petrol
natural_gas :=         1.09e6 J/foot^3; // Energy in natural gas
naturalgas :=          natural_gas;
propane :=             9.63e7 J/gallon; // Energy in liquid propane
kerosene :=            1.42e8 J/gallon; // Energy in liquid kerosene
oil :=                 41.868 GJ/metricton;
coal :=                18.20 GJ/metricton;

//
// Permeability: The permeability or permeance, n, of a substance determines
// how fast vapor flows through the substance.  The formula W = n A dP
// holds where W is the rate of flow (in mass/time), n is the permeability,
// A is the area of the flow path, and dP is the vapor pressure difference.
//
// Alan's Veto:  These are damned, damned sketchy, and are going to go.

// perm_0C :=             grain / (hr ft^2 inHg);
// perm_zero :=           perm_0C;
// perm_0 :=              perm_0C;
// perm :=                perm_0C;
//perm_23C :=            grain / (hr ft^2 in-Hg23C);
//perm_twentythree :=    perm_23C;

//
// Counting measures
//

unity :=               1;
pair :=                2;
couple :=              2;
brace :=               2;
nest :=                3;
dickers :=             10;
dozen :=               12;
bakersdozen :=         13;
score :=               20;
flock :=               40;
timer :=               40;
shock :=               60;
gross :=               144;
greatgross :=          12 gross;

// Paper counting measure

shortquire :=          24;
quire :=               25;
shortream :=           480;
ream :=                500;    
reams := ream;
perfectream :=         516;
bundle :=              2 reams;
bale :=                5 bundle;

//
// Paper measures
//

// USA paper sizes 

lettersize :=          8.5 inch 11 inch;
legalsize :=           8.5 inch 14 inch;
ledgersize :=          11 inch 17 inch;
executivesize :=       7.25 inch 10.5 inch;
Apaper :=              8.5 inch 11 inch;
Bpaper :=              11 inch 17 inch;
Cpaper :=              17 inch 22 inch;
Dpaper :=              22 inch 34 inch;
Epaper :=              34 inch 44 inch;

// The metric paper sizes are defined so that if a sheet is cut in half
// along the short direction, the result is two sheets which are
// similar to the original sheet.  This means that for any metric size,
// the long side is close to sqrt(2) times the length of the short
// side.  Each series of sizes is generated by repeated cuts in half, 
// with the values rounded down to the nearest millimeter.  

A0paper :=             841 mm 1189 mm;  // The basic size in the A series
A1paper :=             594 mm  841 mm;  // is defined to have an area of 
A2paper :=             420 mm  594 mm;  // one square meter.
A3paper :=             297 mm  420 mm;
A4paper :=             210 mm  297 mm;
A5paper :=             148 mm  210 mm;
A6paper :=             105 mm  148 mm;
A7paper :=              74 mm  105 mm;
A8paper :=              52 mm   74 mm;
A9paper :=              37 mm   52 mm;
A10paper :=             26 mm   37 mm;

B0paper :=            1000 mm 1414 mm;  // The basic B size has an area
B1paper :=             707 mm 1000 mm;  // of sqrt(2) square meters.  
B2paper :=             500 mm  707 mm;
B3paper :=             353 mm  500 mm;
B4paper :=             250 mm  353 mm;
B5paper :=             176 mm  250 mm;
B6paper :=             125 mm  176 mm;
B7paper :=              88 mm  125 mm;
B8paper :=              62 mm   88 mm;
B9paper :=              44 mm   62 mm;
B10paper :=             31 mm   44 mm;

C0paper :=             917 mm 1297 mm;  // The basic C size has an area
C1paper :=             648 mm  917 mm;  // of sqrt(sqrt(2)) square meters.
C2paper :=             458 mm  648 mm;
C3paper :=             324 mm  458 mm;  // Intended for envelope sizes
C4paper :=             229 mm  324 mm;
C5paper :=             162 mm  229 mm;
C6paper :=             114 mm  162 mm;
C7paper :=              81 mm  114 mm;
C8paper :=              57 mm   81 mm;
C9paper :=              40 mm   57 mm;
C10paper :=             28 mm   40 mm;

// gsm (Grams per Square Meter), a sane, metric paper weight measure

gsm :=                 grams / meter^2;

// In the USA, a collection of crazy historical paper measures are used.  Paper
// is measured as a weight of a ream of that particular type of paper.  This is
// sometimes called the "substance" or "basis" (as in "substance 20" paper).
// The standard sheet size or "basis size" varies depending on the type of
// paper.  As a result, 20 pound bond paper and 50 pound text paper are actually
// about the same weight.  The different sheet sizes were historically the most
// convenient for printing or folding in the different applications.  These
// different basis weights are standards maintained by American Society for
// Testing Materials (ASTM) and the American Forest and Paper Association
// (AF&PA).

poundbookpaper :=      lb / 25 inch 38 inch ream;
lbbook :=              poundbookpaper;
poundtextpaper :=      poundbookpaper;
lbtext :=              poundtextpaper;
poundoffsetpaper :=    poundbookpaper;   // For offset printing
lboffset :=            poundoffsetpaper;
poundbiblepaper :=     poundbookpaper;   // Designed to be lightweight, thin,
lbbible :=             poundbiblepaper;  // strong and opaque.
poundtagpaper :=       lb / 24 inch 36 inch ream;
lbtag :=               poundtagpaper;
poundbagpaper :=       poundtagpaper;
lbbag :=               poundbagpaper;
poundnewsprintpaper := poundtagpaper;
lbnewsprint :=         poundnewsprintpaper;
poundposterpaper :=    poundtagpaper;
lbposter :=            poundposterpaper;
poundtissuepaper :=    poundtagpaper;
lbtissue :=            poundtissuepaper;
poundwrappingpaper :=  poundtagpaper;
lbwrapping :=          poundwrappingpaper;
poundwaxingpaper :=    poundtagpaper;
lbwaxing :=            poundwaxingpaper;
poundglassinepaper :=  poundtagpaper;
lbglassine :=          poundglassinepaper;
poundcoverpaper :=     lb / 20 inch 26 inch ream;
lbcover :=             poundcoverpaper;
poundindexpaper :=     lb / 25.5 inch 30.5 inch ream;
lbindex :=             poundindexpaper;
poundindexbristolpaper :=   poundindexpaper;
lbindexbristol :=      poundindexpaper;
poundbondpaper :=      lb / 17 inch 22 inch ream; // Bond paper is stiff and
lbbond :=              poundbondpaper;            // durable for repeated
poundwritingpaper :=   poundbondpaper;            // filing, and it resists
lbwriting :=           poundwritingpaper;         // ink penetration.  
poundledgerpaper :=    poundbondpaper;
lbledger :=            poundledgerpaper;
poundcopypaper :=      poundbondpaper;
lbcopy :=              poundcopypaper;
poundblottingpaper :=  lb / 19 inch 24 inch ream;
lbblotting :=          poundblottingpaper;
poundblankspaper :=    lb / 22 inch 28 inch ream;
lbblanks :=            poundblankspaper;
poundpostcardpaper :=  lb / 22.5 inch 28.5 inch ream;
lbpostcard :=          poundpostcardpaper;
poundweddingbristol := poundpostcardpaper;
lbweddingbristol :=    poundweddingbristol;
poundbristolpaper :=   poundweddingbristol;
lbbristol :=           poundbristolpaper;
poundboxboard :=       lb / (1000 ft^2);
lbboxboard :=          poundboxboard;
poundpaperboard :=     poundboxboard;
lbpaperboard :=        poundpaperboard;

// When paper is marked in units of M, it means the weight of 1000 sheets of the
// given size of paper.  To convert this to paper weight, divide by the size of
// the paper in question.

paperM :=              lb / 1000;       

//
// Old French distance measures, from French Weights and Measures
// Before the Revolution by Zupko
//

frenchfoot :=          4500/13853 m;     // pied de roi, the standard of Paris.
pied :=                frenchfoot;       //   Half of the hashimicubit,
frenchfeet :=          frenchfoot;       //   instituted by Charlemagne.
frenchinch :=          1/12 frenchfoot;  //   This exact definition comes from
frenchthumb :=         frenchinch;       //   a law passed on 10 Dec 1799 which
pouce :=               frenchthumb;      //   fixed the meter at 
                                         //   3 frenchfeet + 11.296 lignes.
frenchline :=          1/12 frenchinch;  // This is supposed to be the size
ligne :=               frenchline;       //   of the average barleycorn
frenchpoint :=         1/12 frenchline;
toise :=               6 frenchfeet;
arpent :=              180^2 pied^2;     // The arpent is 100 square perches,
                                         // but the perche seems to vary a lot
                                         // and can be 18 feet, 20 feet, or 22
                                         // feet.  This measure was described
                                         // as being in common use in Canada in
                                         // 1934 (Websters 2nd).  The value
                                         // given here is the Paris standard
                                         // arpent.

//
// Printing
//

fournierpoint :=       0.1648 inch / 12; // First definition of the printers
                                         // point made by Pierre Fournier who
                                         // defined it in 1737 as 1/12 of a
                                         // cicero which was 0.1648 inches.
olddidotpoint :=       1/72 frenchinch;  // Fran¿ois Ambroise Didot, one of 
                                         // a family of printers, changed
                                         // Fournier's definition around 1770 
                                         // to fit to the French units then in
                                         // use.  
bertholdpoint :=       1/2660 m;         // H. Berthold tried to create a 
                                         // metric version of the didot point
                                         // in 1878.  
INpoint :=             0.4 mm;           // This point was created by a 
                                         // group directed by Fermin Didot in
                                         // 1881 and is associated with the 
                                         // imprimerie nationale.  It doesn't
                                         // seem to have been used much.
germandidotpoint :=    0.376065 mm;      // Exact definition appears in DIN
                                        // 16507, a German standards document
                                        // of 1954.  Adopted more broadly  in
                                        // 1966 by ???
metricpoint :=         3/8 mm;           // Proposed in 1977 by Eurograf

point :=          13837/1000000 inch;    // exact, NIST Handbook 44, Appendix 3
printerspoint :=       point;

texscaledpoint :=      1/65536 point;    // The TeX typesetting system uses
texsp :=               texscaledpoint;   // this for all computations.
computerpoint :=       1/72 inch;        // The American point was rounded 
computerpica :=        12 computerpoint; // to an even 1/72 inch by computer
postscriptpoint :=     computerpoint;    // people at some point. 
pspoint :=             postscriptpoint;
Q :=                   1/4 mm;           // Used in Japanese phototypesetting
                                        // Q is for quarter
frenchprinterspoint := olddidotpoint;
didotpoint :=          germandidotpoint; // This seems to be the dominant value
europeanpoint :=       didotpoint;       // for the point used in Europe
cicero :=              12 didotpoint;

stick :=               2 inches;

// Type sizes

excelsior :=           3 point;
brilliant :=           3.5 point;
diamond :=             4 point;
pearl :=               5 point;
agate :=               5.5 point;
ruby :=                agate;     // British
nonpareil :=           6 point;
mignonette :=          6.5 point;
emerald :=             mignonette;// British
minion :=              7 point;
brevier :=             8 point;
bourgeois :=           9 point;
longprimer :=          10 point;
smallpica :=           11 point;
pica :=                12 point;
english :=             14 point;
columbian :=           16 point;
greatprimer :=         18 point;
paragon :=             20 point;
meridian :=            44 point;
canon :=               48 point;

// German type sizes
nonplusultra :=        2 didotpoint;
brillant :=            3 didotpoint;
diamant :=             4 didotpoint;
perl :=                5 didotpoint;
nonpareille :=         6 didotpoint;
kolonel :=             7 didotpoint;
petit :=               8 didotpoint;
borgis :=              9 didotpoint;
korpus :=              10 didotpoint;
corpus :=              korpus;
garamond :=            korpus;
mittel :=              14 didotpoint;
tertia :=              16 didotpoint;
text :=                18 didotpoint;
kleine_kanon :=        32 didotpoint;
kanon :=               36 didotpoint;
grosse_kanon :=        42 didotpoint;
missal :=              48 didotpoint;
kleine_sabon :=        72 didotpoint;
grosse_sabon :=        84 didotpoint;

//
// Information theory units
//

nat :=                 0.69314718056 bits;  // Entropy measured base e
hartley :=             3.32192809488 bits;  // log2(10) bits, or the entropy
                                           //   of a uniformly distributed
                                           //   random variable over 10
                                           //   symbols.
//
// Computer
//

bps :=                 bit/sec;             // Sometimes the term "baud" is
                                            //   incorrectly used to refer to
                                            //   bits per second.  Baud refers
                                            //   to symbols per second.  Modern
                                            //   modems transmit several bits
                                            //   per symbol.
byte :=                8 bit;               // Not all machines had 8 bit
                                            //   bytes, but these days most of
                                            //   them do.  But beware: for
                                            //   transmission over modems, a
                                            //   few extra bits are used so
                                            //   there are actually 10 bits per
                                            //   byte.
nybble :=              4 bits;              // Half of a byte. Sometimes 
                                            //   equal to different lengths
                                            //   such as 3 bits.  
nibble :=              nybble;               

// In computers, "kilo" tends to mean a multiple of 1024 or 2^10.
// This obviously interferes with the standard meanings.
//
// In December 1998 the International Electrotechnical Commission (IEC), the
// leading international organization for worldwide standardization in
// electrotechnology, approved as an IEC International Standard names and 
// symbols for prefixes for binary multiples for use in the fields of data
// processing and data transmission.  One would say "kibibit" to mean 1024 bits
//
// http://physics.nist.gov/cuu/Units/binary.html

// Prefixes
kibi ::- 2^10;           // kilobinary
mebi ::- 2^20;           // megabinary
gibi ::- 2^30;           // gigabinary
tebi ::- 2^40;           // terabinary
pebi ::- 2^50;           // petabinary
exbi ::- 2^60;           // exabinary

// Official symbols
Ki :- kibi;
Mi :- mebi;
Gi :- gibi;
Ti :- tebi;
Pi :- pebi;
Ei :- exbi;

jiffy :=               1/100 sec;    // This is defined in the Jargon File
jiffies :=             jiffy;       // (http://www.jargon.org) as being the
                                    // duration of a clock tick for measuring
                                    // wall-clock time.  Supposedly the value
                                    // used to be 1/60 sec or 1/50 sec
                                    // depending on the frequency of AC power,
                                    // but then 1/100 sec became more common.
                                    // On linux systems, this term is used and
                                    // for the Intel based chips, it does have
                                    // the value of .01 sec.  The Jargon File
                                    // also lists two other definitions:
                                    // millisecond, and the time taken for
                                    // light to travel one foot.
//
// yarn and cloth measures
//

// yarn linear density

m kg^-1 ||| reciprocal_linear_mass_density;

woolyarnrun :=         1600 yard/pound;// 1600 yds of "number 1 yarn" weighs
                                       // a pound.  
yarncut :=             300 yard/pound; // Less common system used in
                                       // Pennsylvania for wool yarn
cottonyarncount :=     840 yard/pound;
linenyarncount :=      300 yard/pound; // Also used for hemp and ramie
worstedyarncount :=    1680 ft/pound;
metricyarncount :=     meter/gram;
kg/m ||| linear_mass_density;
tex :=                 gram / km;   // rational metric yarn measure, meant
denier :=              1/9 tex;           // used for silk and rayon
manchesteryarnnumber := drams/(1000 yards);// old system used for silk
pli :=                 lb/in;
typp :=                1000 yd/lb;
asbestoscut :=         100 yd/lb;   // used for glass and asbestos yarn

drex :=                0.1 tex;     // to be used for any kind of yarn


// yarn and cloth length

skeincotton :=         80*54 inch;  // 80 turns of thread on a reel with a
                                    //  54 in circumference (varies for other
                                    //  kinds of thread)
cottonbolt :=          120 ft;      // cloth measurement
woolbolt :=            210 ft;
bolt :=                cottonbolt;
heer :=                600 yards;
cut :=                 300 yards;   // used for wet-spun linen yarn
lea :=                 300 yards;

//
// drug dosage
//

mcg :=                 microgram;       // Frequently used for vitamins
iudiptheria :=         62.8 microgram;  // IU is for international unit
iupenicillin :=        0.6 microgram;
iuinsulin :=           41.67 microgram;
drop :=                1/20 ml;         // The drop was an old "unit" that was
                                       // replaced by the minim.  But I was
                                       // told by a pharmacist that in his
                                       // profession, the conversion of 20
                                       // drops per ml is actually used. 
bloodunit :=          450 ml;           // For whole blood.  For blood
                                         // components, a blood unit is the
                                         // quanity of the component found in a
                                         // blood unit of whole blood.  The
                                         // human body contains about 12 blood
                                         // units of whole blood.  

//
// fixup units for times when prefix handling doesn't do the job
//

hectare :=             hectoare;
ha      :=             hectare;
megohm :=              megaohm;
kilohm :=              kiloohm;
microhm :=             microohm;

cent :=                1/100 dollar;

// British currency
//
// These have been supplanted by the PoundSource definitions which include
// historical exchange rates for years back to 1600.
//
//shilling :=            1/20 britainpound;  // Before decimalisation, there
//oldpence :=            1/12 shilling;      // were 20 shillings to a pound,
                                            // each of twelve old pence
//quid :=                britainpound;       // Slang names
//fiver :=               5 quid;
//tenner :=              10 quid;

//
// Units used for measuring volume of wood
//

cord :=                4 ft * 4 ft * 8 ft;// 4 ft by 4 ft by 8 ft bundle of wood
facecord :=            1/2 cord;
cordfoot :=            1/8 cord;    // One foot long section of a cord
cordfeet :=            cordfoot;
rick := 4 ft 8 ft 16 inches;        // Stack of firewood

housecord :=           1/3 cord;    // Used to sell firewood for residences, 
                                   //   often confusingly called a "cord"
boardfoot :=           ft^2 inch;   // Usually 1 inch thick wood
boardfeet :=           boardfoot;
fbm :=                 boardfoot;   // feet board measure
stere :=               m^3;
st :=                  stere;
timberfoot :=          ft^3;        // Used for measuring solid blocks of wood
standard :=            120 12 ft 11 in 1.5 in; // This is the St Petersburg or
                                    //   Pittsburg standard.  Apparently the
                                    //   term is short for "standard hundred"
                                    //   which was meant to refer to 100 pieces
                                    //   of wood (deals).  However, this
                                    //   particular standard is equal to 120
                                    //   deals which are 12 ft by 11 in by 1.5
                                    //   inches (not the standard deal). 

// In Britain, the deal is apparently any piece of wood over 6 feet long, over
// 7 wide and 2.5 inches thick.  The OED doesn't give a standard size.  A piece
// of wood less than 7 inches wide is called a "batten".  This unit is now used
// exclusively for fir and pine.

deal :=         12 ft 11 in 2.5 in; // The standard North American deal [OED]
wholedeal :=    1/2 deal;           // If it's half as thick as the standard
                                   //   deal it's called a "whole deal"!
splitdeal :=    1/2 wholedeal;      // And half again as thick is a split deal.


//
// Gas and Liquid flow units
//

// Some horribly-named flow units that I've never seen used other than once
// (unexplained) in the Guinness Book of World Records which has degraded into
// tabloid trash.
cumec :=               m^3/s;
cusec :=               ft^3/s;

// Conventional abbreviations for fluid flow units

gph :=                 gal/hr;
gpm :=                 gal/min;
mgd :=                 megagal/day;
cf  :=                 ft^3;
ccf :=                 100 cf;      // sorta dubious, but used.
cfs :=                 cf/s;
cfh :=                 cf/hour;
cfm :=                 cf/min;
lpm :=                 liter/min;

// Miner's inch:  This is an old historic unit used in the Western  United
// States.  It is generally defined as the rate of flow through a one square
// inch hole at a specified depth such as 4 inches.  In the late 19th century,
// volume of water was sometimes measured in the "24 hour inch".  Values for the
// miner's inch were fixed by state statues.  (This information is from a web
// site operated by the Nevada Division of Water Planning:  The Water Words
// Dictionary at http://www.state.nv.us/cnr/ndwp/dict-1/waterwds.htm.)

minersinchAZ :=        1.5 ft^3/min;
minersinchCA :=        1.5 ft^3/min;
minersinchMT :=        1.5 ft^3/min;
minersinchNV :=        1.5 ft^3/min;
minersinchOR :=        1.5 ft^3/min;
minersinchID :=        1.2 ft^3/min;
minersinchKS :=        1.2 ft^3/min;
minersinchNE :=        1.2 ft^3/min;
minersinchNM :=        1.2 ft^3/min;
minersinchND :=        1.2 ft^3/min;
minersinchSD :=        1.2 ft^3/min;
minersinchUT :=        1.2 ft^3/min;
minersinchCO :=        1.56 ft^3/min;
minersinchBC :=        1.68 ft^3/min;  // British Columbia

// In vacuum science and some other applications, gas flow is measured
// as the product of volumetric flow and pressure.  This is useful
// because it makes it easy to compare with the flow at standard
// pressure (one atmosphere).  It also directly relates to the number
// of gas molecules per unit time, and hence to the mass flow if the
// molecular mass is known.

sccm :=                atm cc/min;    // 's' is for "standard" to indicate
sccs :=                atm cc/sec;    // flow at standard pressure
scfh :=                atm ft^3/hour; //
scfm :=                atm ft^3/min;
slpm :=                atm liter/min;
slph :=                atm liter/hour;
lusec :=               liter micron Hg force / s; // Used in vacuum science

// Wire gauge: this area is a nightmare with huge charts of wire gauge
// diameters that usually have no clear origin.  There are at least 5 competing
// wire gauge systems to add to the confusion.

// The use of wire gauge is related to the manufacturing method: a metal rod is
// heated and drawn through a hole.  The size change can't be too big.  To get
// smaller wires, the process is repeated with a series of smaller holes.  

// American Wire Gauge (AWG) or Brown & Sharpe Gauge appears to be the most
// important gauge. ASTM B-258 specifies that this gauge is based on geometric
// interpolation between gauge 0000, which is 0.46 inches exactly, and gauge 36
// which is 0.005 inches exactly.  Therefore, the diameter in inches of a wire
// is given by the formula 1/200 92^((36-g)/39).  Note that 92^(1/39) is close
// to 2^(1/6), so diameter is approximately halved for every 6 gauges.  For the
// repeated zero values, use negative numbers in the formula.  The same document
// also specifies rounding rules which seem to be ignored by makers of tables.
// Gauges up to 44 are to be specified with up to 4 significant figures, but no
// closer than 0.0001 inch.  Gauges from 44 to 56 are to be rounded to the
// nearest 0.00001 inch.  The table below gives 4 significant figures for all
// gauges.
//
// In addition to being used to measure wire thickness, this gauge is used to
// measure the thickness of sheets of aluminum, copper, and most metals other
// than steel, iron and zinc.

// The numbers below are DIAMETERS.
wire0000gauge :=       0.4600 in;
wire000gauge :=        0.4096 in;
wire00gauge :=         0.3648 in;
wire0gauge :=          0.3249 in;
wire1gauge :=          0.2893 in;
wire2gauge :=          0.2576 in;
wire3gauge :=          0.2294 in;
wire4gauge :=          0.2043 in;
wire5gauge :=          0.1819 in;
wire6gauge :=          0.1620 in;
wire7gauge :=          0.1443 in;
wire8gauge :=          0.1285 in;
wire9gauge :=          0.1144 in;
wire10gauge :=         0.1019 in;
wire11gauge :=         0.09074 in;
wire12gauge :=         0.08081 in;
wire13gauge :=         0.07196 in;
wire14gauge :=         0.06408 in;
wire15gauge :=         0.05707 in;
wire16gauge :=         0.05082 in;
wire17gauge :=         0.04526 in;
wire18gauge :=         0.04030 in;
wire19gauge :=         0.03589 in;
wire20gauge :=         0.03196 in;
wire21gauge :=         0.02846 in;
wire22gauge :=         0.02535 in;
wire23gauge :=         0.02257 in;
wire24gauge :=         0.02010 in;
wire25gauge :=         0.01790 in;
wire26gauge :=         0.01594 in;
wire27gauge :=         0.01420 in;
wire28gauge :=         0.01264 in;
wire29gauge :=         0.01126 in;
wire30gauge :=         0.01003 in;
wire31gauge :=         0.008928 in;
wire32gauge :=         0.007950 in;
wire33gauge :=         0.007080 in;
wire34gauge :=         0.006305 in;
wire35gauge :=         0.005615 in;
wire36gauge :=         0.005000 in;
wire37gauge :=         0.004453 in;
wire38gauge :=         0.003965 in;
wire39gauge :=         0.003531 in;
wire40gauge :=         0.003145 in;
wire41gauge :=         0.002800 in;
wire42gauge :=         0.002494 in;
wire43gauge :=         0.002221 in;
wire44gauge :=         0.001978 in;
wire45gauge :=         0.001761 in;
wire46gauge :=         0.001568 in;
wire47gauge :=         0.001397 in;
wire48gauge :=         0.001244 in;
wire49gauge :=         0.001108 in;
wire50gauge :=         0.0009863 in;
wire51gauge :=         0.0008783 in;
wire52gauge :=         0.0007822 in;
wire53gauge :=         0.0006966 in;
wire54gauge :=         0.0006203 in;
wire55gauge :=         0.0005524 in;
wire56gauge :=         0.0004919 in;

// Next we have the SWG, the Imperial or British Standard Wire Gauge.  This one
// is piecewise linear, so it is not generated by a simple formula.  It was used
// for aluminum sheets.

brwire0000000gauge :=  0.500 in;
brwire000000gauge :=   0.464 in;
brwire00000gauge :=    0.432 in;
brwire0000gauge :=     0.400 in;
brwire000gauge :=      0.372 in;
brwire00gauge :=       0.348 in;
brwire0gauge :=        0.324 in;
brwire1gauge :=        0.300 in;
brwire2gauge :=        0.276 in;
brwire3gauge :=        0.252 in;
brwire4gauge :=        0.232 in;
brwire5gauge :=        0.212 in;
brwire6gauge :=        0.192 in;
brwire7gauge :=        0.176 in;
brwire8gauge :=        0.160 in;
brwire9gauge :=        0.144 in;
brwire10gauge :=       0.128 in;
brwire11gauge :=       0.116 in;
brwire12gauge :=       0.104 in;
brwire13gauge :=       0.092 in;
brwire14gauge :=       0.080 in;
brwire15gauge :=       0.072 in;
brwire16gauge :=       0.064 in;
brwire17gauge :=       0.056 in;
brwire18gauge :=       0.048 in;
brwire19gauge :=       0.040 in;
brwire20gauge :=       0.036 in;
brwire21gauge :=       0.032 in;
brwire22gauge :=       0.028 in;
brwire23gauge :=       0.024 in;
brwire24gauge :=       0.022 in;
brwire25gauge :=       0.0200 in;
brwire26gauge :=       0.0180 in;
brwire27gauge :=       0.0164 in;
brwire28gauge :=       0.0149 in;
brwire29gauge :=       0.0136 in;
brwire30gauge :=       0.0124 in;
brwire31gauge :=       0.0116 in;
brwire32gauge :=       0.0108 in;
brwire33gauge :=       0.0100 in;
brwire34gauge :=       0.0092 in;
brwire35gauge :=       0.0084 in;
brwire36gauge :=       0.0076 in;
brwire37gauge :=       0.0068 in;
brwire38gauge :=       0.0060 in;
brwire39gauge :=       0.0052 in;
brwire40gauge :=       0.0048 in;
brwire41gauge :=       0.0044 in;
brwire42gauge :=       0.0040 in;
brwire43gauge :=       0.0036 in;
brwire44gauge :=       0.0032 in;
brwire45gauge :=       0.0028 in;
brwire46gauge :=       0.0024 in;
brwire47gauge :=       0.0020 in;
brwire48gauge :=       0.0016 in;
brwire49gauge :=       0.0012 in;
brwire50gauge :=       0.0010 in;

// The following is from the Appendix to ASTM B 258
// 
// For example, in U.S. gage, the standard for sheet metal is based on the
// weight of the metal, not on the thickness. 16-gage is listed as approximately
// .0625 inch thick and 40 ounces per square foot (the original standard was
// based on wrought iron at .2778 pounds per cubic inch; steel has almost
// entirely superseded wrought iron for sheet use, at .2833 pounds per cubic
// inch). Smaller numbers refer to greater thickness. There is no formula for
// converting gage to thickness or weight.
// 
// It's rather unclear from the passage above whether the plate gauge values are
// therefore wrong if steel is being used.  Reference [15] states that steel is
// in fact measured using this gauge (under the name Manufacturers' Standard
// Gauge) with a density of 501.84 lb/ft3 = 0.2904 lb/in3 used for steel.
// But this doesn't seem to be the correct density of steel (.2833 lb/in3 is
// closer), and nobody else lists these values.  
//
// This gauge was established in 1893 for purposes of taxation.

plate000000gauge :=    15/32 in;   // 300 oz / ft^2
plate00000gauge :=     14/32 in;   // 280 oz / ft^2
plate0000gauge :=      13/32 in;   // 260 oz / ft^2
plate000gauge :=       12/32 in;   // 240 oz / ft^2
plate00gauge :=        11/32 in;   // 220 oz / ft^2
plate0gauge :=         10/32 in;   // 200 oz / ft^2
plate1gauge :=          9/32 in;   // 180 oz / ft^2 
plate2gauge :=         17/64 in;   // 170 oz / ft^2
plate3gauge :=         16/64 in;   // 160 oz / ft^2
plate4gauge :=         15/64 in;   // 150 oz / ft^2
plate5gauge :=         14/64 in;   // 140 oz / ft^2
plate6gauge :=         13/64 in;   // 130 oz / ft^2
plate7gauge :=         12/64 in;   // 120 oz / ft^2
plate8gauge :=         11/64 in;   // 110 oz / ft^2
plate9gauge :=         10/64 in;   // 100 oz / ft^2
plate10gauge :=         9/64 in;   //  90 oz / ft^2
plate11gauge :=         8/64 in;   //  80 oz / ft^2
plate12gauge :=         7/64 in;   //  70 oz / ft^2
plate13gauge :=         6/64 in;   //  60 oz / ft^2
plate14gauge :=         5/64 in;   //  50 oz / ft^2
plate15gauge :=         9/128 in;  //  45 oz / ft^2
plate16gauge :=         8/128 in;  //  40 oz / ft^2
plate17gauge :=         9/160 in;  //  36 oz / ft^2
plate18gauge :=         8/160 in;  //  32 oz / ft^2
plate19gauge :=         7/160 in;  //  28 oz / ft^2
plate20gauge :=         6/160 in;  //  24 oz / ft^2
plate21gauge :=        11/320 in;  //  22 oz / ft^2
plate22gauge :=        10/320 in;  //  20 oz / ft^2
plate23gauge :=         9/320 in;  //  18 oz / ft^2
plate24gauge :=         8/320 in;  //  16 oz / ft^2
plate25gauge :=         7/320 in;  //  14 oz / ft^2
plate26gauge :=         6/320 in;  //  12 oz / ft^2
plate27gauge :=        11/640 in;  //  11 oz / ft^2
plate28gauge :=        10/640 in;  //  10 oz / ft^2
plate29gauge :=         9/640 in;  //   9 oz / ft^2
plate30gauge :=         8/640 in;  //   8 oz / ft^2
plate31gauge :=         7/640 in;  //   7 oz / ft^2
plate32gauge :=        13/1280 in; //   6.5 oz / ft^2
plate33gauge :=        12/1280 in; //   6 oz / ft^2
plate34gauge :=        11/1280 in; //   5.5 oz / ft^2
plate35gauge :=        10/1280 in; //   5 oz / ft^2
plate36gauge :=         9/1280 in; //   4.5 oz / ft^2
plate37gauge :=        17/2560 in; //   4.25 oz / ft^2
plate38gauge :=        16/2560 in; //   4 oz / ft^2

// Zinc sheet metal gauge

zinc1gauge :=          0.002 in;
zinc2gauge :=          0.004 in;
zinc3gauge :=          0.006 in;
zinc4gauge :=          0.008 in;
zinc5gauge :=          0.010 in;
zinc6gauge :=          0.012 in;
zinc7gauge :=          0.014 in;
zinc8gauge :=          0.016 in;
zinc9gauge :=          0.018 in;
zinc10gauge :=         0.020 in;
zinc11gauge :=         0.024 in;
zinc12gauge :=         0.028 in;
zinc13gauge :=         0.032 in;
zinc14gauge :=         0.036 in;
zinc15gauge :=         0.040 in;
zinc16gauge :=         0.045 in;
zinc17gauge :=         0.050 in;
zinc18gauge :=         0.055 in;
zinc19gauge :=         0.060 in;
zinc20gauge :=         0.070 in;
zinc21gauge :=         0.080 in;
zinc22gauge :=         0.090 in;
zinc23gauge :=         0.100 in;
zinc24gauge :=         0.125 in;
zinc25gauge :=         0.250 in;
zinc26gauge :=         0.375 in;
zinc27gauge :=         0.500 in;
zinc28gauge :=         1.000 in;

// USA ring sizes.  Several slightly different definitions seem to be in
// circulation.  According to [15], the interior diameter of size n ring in
// inches is 0.32 n + 0.458 for n ranging from 3 to 13.5 by steps of 0.5.  The
// size 2 ring is inconsistently 0.538in and no 2.5 size is listed.  
//
// However, other sources list 0.455 + 0.0326 n and 0.4525 + 0.0324 n as the
// diameter and list no special case for size 2.  (Or alternatively they are
// 1.43 + .102 n and 1.4216+.1018 n for measuring circumference in inches.)  One
// reference claimed that the original system was that each size was 1/10 inch
// circumference, but that source doesn't have an explanation for the modern
// system which is somewhat different.
//
// This table gives circumferences as listed in [15].  

size2ring :=           0.538 in pi;
size3ring :=           0.554 in pi;
size3_5ring :=         0.570 in pi;
size4ring :=           0.586 in pi;
size4_5ring :=         0.602 in pi;
size5ring :=           0.618 in pi;
size5_5ring :=         0.634 in pi;
size6ring :=           0.650 in pi;
size6_5ring :=         0.666 in pi;
size7ring :=           0.682 in pi;
size7_5ring :=         0.698 in pi;
size8ring :=           0.714 in pi;
size8_5ring :=         0.730 in pi;
size9ring :=           0.746 in pi;
size9_5ring :=         0.762 in pi;
size10ring :=          0.778 in pi;
size10_5ring :=        0.794 in pi;
size11ring :=          0.810 in pi;
size11_5ring :=        0.826 in pi;
size12ring :=          0.842 in pi;
size12_5ring :=        0.858 in pi;
size13ring :=          0.874 in pi;
size13_5ring :=        0.890 in pi;

// Old practice in the UK measured rings using the "Wheatsheaf gauge" with sizes
// specified alphabetically and based on the ring inside diameter in steps of
// 1/64 inch.  This system was replaced in 1987 by British Standard 6820 which
// specifies sizes based on circumference.  Each size is 1.25 mm different from
// the preceding size.  The baseline is size C which is 40 mm circumference.
// The new sizes are close to the old ones.  Sometimes it's necessary to go
// beyond size Z to Z+1, Z+2, etc.  

sizeAring :=           37.50 mm;
sizeBring :=           38.75 mm;
sizeCring :=           40.00 mm;
sizeDring :=           41.25 mm;
sizeEring :=           42.50 mm;
sizeFring :=           43.75 mm;
sizeGring :=           45.00 mm;
sizeHring :=           46.25 mm;
sizeIring :=           47.50 mm;
sizeJring :=           48.75 mm;
sizeKring :=           50.00 mm;
sizeLring :=           51.25 mm;
sizeMring :=           52.50 mm;
sizeNring :=           53.75 mm;
sizeOring :=           55.00 mm;
sizePring :=           56.25 mm;
sizeQring :=           57.50 mm;
sizeRring :=           58.75 mm;
sizeSring :=           60.00 mm;
sizeTring :=           61.25 mm;
sizeUring :=           62.50 mm;
sizeVring :=           63.75 mm;
sizeWring :=           65.00 mm;
sizeXring :=           66.25 mm;
sizeYring :=           67.50 mm;
sizeZring :=           68.75 mm;

// Japanese sizes start with size 1 at a 13mm inside diameter and each size is
// 1/3 mm larger in diameter than the previous one.  They are multiplied by pi
// to give circumference. 

jpsize1ring :=         39/3 pi mm;
jpsize2ring :=         40/3 pi mm;
jpsize3ring :=         41/3 pi mm;
jpsize4ring :=         42/3 pi mm;
jpsize5ring :=         43/3 pi mm;
jpsize6ring :=         44/3 pi mm;
jpsize7ring :=         45/3 pi mm;
jpsize8ring :=         46/3 pi mm;
jpsize9ring :=         47/3 pi mm;
jpsize10ring :=        48/3 pi mm;
jpsize11ring :=        49/3 pi mm;
jpsize12ring :=        50/3 pi mm;
jpsize13ring :=        51/3 pi mm;
jpsize14ring :=        52/3 pi mm;
jpsize15ring :=        53/3 pi mm;
jpsize16ring :=        54/3 pi mm;
jpsize17ring :=        55/3 pi mm;
jpsize18ring :=        56/3 pi mm;
jpsize19ring :=        57/3 pi mm;
jpsize20ring :=        58/3 pi mm;
jpsize21ring :=        59/3 pi mm;
jpsize22ring :=        60/3 pi mm;
jpsize23ring :=        61/3 pi mm;
jpsize24ring :=        62/3 pi mm;
jpsize25ring :=        63/3 pi mm;
jpsize26ring :=        64/3 pi mm;
jpsize27ring :=        65/3 pi mm;
jpsize28ring :=        66/3 pi mm;
jpsize29ring :=        67/3 pi mm;
jpsize30ring :=        68/3 pi mm;

// The European ring sizes are the length of the circumference in mm minus 40.

eusize1ring :=         41 mm;
eusize2ring :=         42 mm;
eusize3ring :=         43 mm;
eusize4ring :=         44 mm;
eusize5ring :=         45 mm;
eusize6ring :=         46 mm;
eusize7ring :=         47 mm;
eusize8ring :=         48 mm;
eusize9ring :=         49 mm;
eusize10ring :=        50 mm;
eusize11ring :=        51 mm;
eusize12ring :=        52 mm;
eusize13ring :=        53 mm;
eusize14ring :=        54 mm;
eusize15ring :=        55 mm;
eusize16ring :=        56 mm;
eusize17ring :=        57 mm;
eusize18ring :=        58 mm;
eusize19ring :=        59 mm;
eusize20ring :=        60 mm;
eusize21ring :=        61 mm;
eusize22ring :=        62 mm;
eusize23ring :=        63 mm;
eusize24ring :=        64 mm;
eusize25ring :=        65 mm;
eusize26ring :=        66 mm;
eusize27ring :=        67 mm;
eusize28ring :=        68 mm;
eusize29ring :=        69 mm;
eusize30ring :=        70 mm;

//
// Abbreviations
//

mph :=                 mile/hr;
mpg :=                 mile/gal;
kph :=                 km/hr;
fL :=                  footlambert;
fpm :=                 ft/min;
fps :=                 ft/s;
rpm :=                 rev/min;
rps :=                 rev/sec;
mi :=                  mile;
mbh :=                 1ee3 Btu/hour;
mcm :=                 1ee3 circularmil;

//
// Radioactivity units
//

becquerel :=           s^-1;         // Activity of radioactive source
Bq :=                  becquerel;    //
curie :=               37ee9 Bq;   // Defined in 1910 as the radioactivity
Ci :=                  curie;        // emitted by the amount of radon that is
                                    // in equilibrium with 1 gram of radium.
rutherford :=          1ee6 Bq;      //

gray :=                J/kg;         // Absorbed dose of radiation
Gy :=                  gray;         //
rad :=                 1ee-2 Gy;     // From Radiation Absorbed Dose
rep :=                 8.38 mGy;     // Roentgen Equivalent Physical, the amount
                                    //   of radiation which , absorbed in the
                                    //   body, would liberate the same amount
                                    //   of energy as 1 roentgen of X rays
                                    //   would, or 97 ergs.

sievert :=             J/kg;         // Dose equivalent:  dosage that has the
Sv :=                  sievert;      //   same effect on human tissues as 200
rem :=                 1ee-2 Sv;     //   keV X-rays.  Different types of
                                    //   radiation are weighted by the
                                    //   Relative Biological Effectiveness
                                    //   (RBE).
                                    //
                                    //      Radiation type       RBE
                                    //       X-ray, gamma ray     1
                                    //       beta rays, > 1 MeV   1
                                    //       beta rays, < 1 MeV  1.08
                                    //       neutrons, < 1 MeV   4-5
                                    //       neutrons, 1-10 MeV   10
                                    //       protons, 1 MeV      8.5
                                    //       protons, .1 MeV      10
                                    //       alpha, 5 MeV         15
                                    //       alpha, 1 MeV         20
                                    //
                                    //   The energies are the kinetic energy
                                    //   of the particles.  Slower particles
                                    //   interact more, so they are more
                                    //   effective ionizers, and hence have
                                    //   higher RBE values.
                                    //
                                    // rem stands for Roentgen Equivalent
                                    // Mammal

roentgen :=          258ee-6 C / kg; // Ionizing radiation that produces
                                    //   1 statcoulomb of charge in 1 cc of
                                    //   dry air at stp.
rontgen :=             roentgen;     // Sometimes it appears spelled this way
sievertunit :=         8.38 rontgen; // Unit of gamma ray dose delivered in one
                                    //   hour at a distance of 1 cm from a
                                    //   point source of 1 mg of radium
                                    //   enclosed in platinum .5 mm thick.

eman :=                1ee-7 Ci/m^3; // radioactive concentration
mache :=               3.7e-7 Ci/m^3;

//
// Atomic weights.  The atomic weight of an element is the ratio of the mass of
// a mole of the element to 1/12 of a mole of Carbon 12.  The Standard Atomic
// Weights apply to the elements as they occur naturally on earth.  Elements
// which do not occur naturally or which occur with wide isotopic variability do
// not have Standard Atomic Weights.  For these elements, the atomic weight is
// based on the longest lived isotope, as marked in the comments.  In some
// cases, the comment for these entries also gives a number which is an atomic
// weight for a different isotope that may be of more interest than the longest
// lived isotope.
//

g/mol ||| molar_mass;

actinium :=            227.0278 g/mol;
aluminum :=            26.981539 g/mol;
aluminium :=           aluminum;
americium :=           243.0614 g/mol;   // Longest lived. 241.06
antimony :=            121.760 g/mol;
argon :=               39.948 g/mol;
arsenic :=             74.92159 g/mol;
astatine :=            209.9871 g/mol;   // Longest lived
barium :=              137.327 g/mol;
berkelium :=           247.0703 g/mol;    // Longest lived. 249.08
beryllium :=           9.012182 g/mol;
bismuth :=             208.98037 g/mol;
boron :=               10.811 g/mol;
bromine :=             79.904 g/mol;
cadmium :=             112.411 g/mol;
calcium :=             40.078 g/mol;
californium :=         251.0796 g/mol;    // Longest lived.  252.08
carbon :=              12.011 g/mol;
cerium :=              140.115 g/mol;
cesium :=              132.90543 g/mol;
chlorine :=            35.4527 g/mol;
chromium :=            51.9961 g/mol;
cobalt :=              58.93320 g/mol;
copper :=              63.546 g/mol;
curium :=              247.0703 g/mol;
dysprosium :=          162.50 g/mol;
einsteinium :=         252.083 g/mol;     // Longest lived 
erbium :=              167.26 g/mol;
europium :=            151.965 g/mol;
fermium :=             257.0951 g/mol;    // Longest lived
fluorine :=            18.9984032 g/mol;
francium :=            223.0197 g/mol;    // Longest lived
gadolinium :=          157.25 g/mol;
gallium :=             69.723 g/mol;
germanium :=           72.61 g/mol;
gold :=                196.96654 g/mol;
hafnium :=             178.49 g/mol;
helium :=              4.002602 g/mol;
holmium :=             164.93032 g/mol;
hydrogen :=            1.00794 g/mol;
indium :=              114.818 g/mol;
iodine :=              126.90447 g/mol;
iridium :=             192.217 g/mol;
iron :=                55.845 g/mol;
krypton :=             83.80 g/mol;
lanthanum :=           138.9055 g/mol;
lawrencium :=          262.11 g/mol;      // Longest lived
lead :=                207.2 g/mol;
lithium :=             6.941 g/mol;
lutetium :=            174.967 g/mol;
magnesium :=           24.3050 g/mol;
manganese :=           54.93805 g/mol;
mendelevium :=         258.10 g/mol;      // Longest lived
mercury :=             200.59 g/mol;
molybdenum :=          95.94 g/mol;
neodymium :=           144.24 g/mol;
neon :=                20.1797 g/mol;
neptunium :=           237.0482 g/mol;
nickel :=              58.6934 g/mol;
niobium :=             92.90638 g/mol;
nitrogen :=            14.00674 g/mol;
nobelium :=            259.1009 g/mol;    // Longest lived
osmium :=              190.23 g/mol;
oxygen :=              15.9994 g/mol;
palladium :=           106.42 g/mol;
phosphorus :=          30.973762 g/mol;
platinum :=            195.08 g/mol;
plutonium :=           244.0642 g/mol;    // Longest lived.  239.05
polonium :=            208.9824 g/mol;    // Longest lived.  209.98
potassium :=           39.0983 g/mol;
praseodymium :=        140.90765 g/mol;
promethium :=          144.9127 g/mol;    // Longest lived.  146.92
protactinium :=        231.03588 g/mol;
radium :=              226.0254 g/mol;
radon :=               222.0176 g/mol;    // Longest lived
rhenium :=             186.207 g/mol;
rhodium :=             102.90550 g/mol;
rubidium :=            85.4678 g/mol;
ruthenium :=           101.07 g/mol;
samarium :=            150.36 g/mol;
scandium :=            44.955910 g/mol;
selenium :=            78.96 g/mol;
silicon :=             28.0855 g/mol;
silver :=              107.8682 g/mol;
sodium :=              22.989768 g/mol;
strontium :=           87.62 g/mol;
sulfur :=              32.066 g/mol;
sulphur :=             sulfur;
tantalum :=            180.9479 g/mol;
technetium :=          97.9072 g/mol;     // Longest lived.  98.906
tellurium :=           127.60 g/mol;
terbium :=             158.92534 g/mol;
thallium :=            204.3833 g/mol;
thorium :=             232.0381 g/mol;
thullium :=            168.93421 g/mol;
tin :=                 118.710 g/mol;
titanium :=            47.867 g/mol;
tungsten :=            183.84 g/mol;
uranium :=             238.0289 g/mol;
vanadium :=            50.9415 g/mol;
xenon :=               131.29 g/mol;
ytterbium :=           173.04 g/mol;
yttrium :=             88.90585 g/mol;
zinc :=                65.39 g/mol;
zirconium :=           91.224 g/mol;

//
// Before the Imperial Weights and Measures Act of 1824, various different
// weights and measures were in use in different places.
//

// Scots linear measure

scotsinch :=    1.00540054 britishinch;
scotsell :=     37 scotsinch;
scotsfall :=    6 scotsell;
scotschain :=   4 scotsfall;
scotslink :=    1/100 scotschain;
scotsfoot :=    12 scotsinch;
scotsfeet :=    scotsfoot;
scotsfurlong := 10 scotschain;
scotsmile :=    8 scotsfurlong;

// Scots area measure

scotsrood :=    40 scotsfall^2;
scotsacre :=    4 scotsrood;

// Irish linear measure

irishinch :=   britishinch;
irishpalm :=   3 irishinch;
irishspan :=   3 irishpalm;
irishfoot :=   12 irishinch;
irishfeet :=   irishfoot;
irishcubit :=  18 irishinch;
irishyard :=   3 irishfeet;
irishpace :=   5 irishfeet;
irishfathom := 6 irishfeet;
irishpole :=   7 irishyard;     // Only these values
irishperch :=  irishpole;       // are different from
irishchain :=  4 irishperch;    // the British Imperial
irishlink :=   1/100 irishchain;// or English values for
irishfurlong :=10 irishchain;   // these lengths.
irishmile :=   8 irishfurlong;  //

//  Irish area measure

irishrood :=   40 irishpole^2;
irishacre :=   4 irishrood;

// Modern US Beer capacity
beerbarrel := 31 gallons;     // A full beer barrel
keg        := 1/2 beerbarrel; // The standard "keg" is a half barrel
beerkeg    := keg;
ponykeg    := 1/2 keg;
case       := 24 12 floz;     // Why not?
beercase   := case;

// English wine capacity measures (Winchester measures)

winegallon := 231 britishinch^3; // Sometimes called the Winchester Wine Gallon,
                             // it was legalized in 1707 by Queen Anne, and
                             // given the definition of 231 cubic inches.  It
                             // had been in use for a while as 8 pounds of wine
                             // using a merchant's pound of 7200 grains or
                             // 15 troy ounces.  (The old mercantile pound had
                             // been 15 tower ounces.)
winequart :=  1/4 winegallon;
winepint :=   1/2 winequart;
winerundlet :=18 winegallon;
winebarrel := 31.5 winegallon;
winetierce := 42 winegallon;
winehogshead :=    2 winebarrel;
winepuncheon :=    2 winetierce;
winebutt :=   2 winehogshead;
winepipe :=   winebutt;
winetun :=    2 winebutt;

// English beer and ale measures used 1803-1824 and used for beer before 1688

englishbeergallon := 282 britishinch^3;
englishbeerquart :=  1/4 englishbeergallon;
englishbeerpint :=   1/2 englishbeerquart;
englishbeerbarrel := 36 englishbeergallon;
englishbeerhogshead :=    1.5 englishbeerbarrel;

// English ale measures used from 1688-1803 for both ale and beer

alegallon :=  englishbeergallon;
alequart :=   1/4 alegallon;
alepint :=    1/2 alequart;
alebarrel :=  34 alegallon;
alehogshead :=1.5 alebarrel;

// Scots capacity measure

scotsgallon :=827.232 britishinch^3;
scotsquart := 1/4 scotsgallon;
scotspint :=  1/2 scotsquart;
choppin :=    1/2 scotspint;
mutchkin :=   1/2 choppin;
scotsgill :=  1/4 mutchkin;
scotsbarrel :=8 scotsgallon;

// Scots dry capacity measure

scotswheatlippy :=    137.333 britishinch^3;   // Also used for peas, beans, rye, salt
scotswheatlippies :=  scotswheatlippy;
scotswheatpeck :=4 scotswheatlippy;
scotswheatfirlot :=   4 scotswheatpeck;
scotswheatboll :=4 scotswheatfirlot;
scotswheatchalder :=  16 scotswheatboll;

scotsoatlippy := 200.345 britishinch^3;   // Also used for barley and malt
scotsoatlippies :=    scotsoatlippy;
scotsoatpeck :=  4 scotsoatlippy;
scotsoatfirlot :=4 scotsoatpeck;
scotsoatboll :=  4 scotsoatfirlot;
scotsoatchalder :=    16 scotsoatboll;

// Scots Tron weight

tronpound :=  9520 grain;
tronounce :=  1/20 tronpound;
trondrop :=   1/16 tronounce;
tronstone :=  16 tronpound;

// Irish liquid capacity measure

irishgallon :=217.6 britishinch^3;
irishpottle :=1/2 irishgallon;
irishquart := 1/2 irishpottle;
irishpint :=  1/2 irishquart;
irishnoggin :=1/4 irishpint;
irishrundlet :=    18 irishgallon;
irishbarrel :=31.5 irishgallon;
irishtierce :=42 irishgallon;
irishhogshead :=   2 irishbarrel;
irishpuncheon :=   2 irishtierce;
irishpipe :=  2 irishhogshead;
irishtun :=   2 irishpipe;

// Irish dry capacity measure

irishpeck :=  2 irishgallon;
irishbushel :=4 irishpeck;
irishstrike :=2 irishbushel;
irishdrybarrel :=  2 irishstrike;
irishquarter :=    2 irishbarrel;

// English Tower weights, abolished in 1528

towerpound :=   5400 grain;
towerounce :=   1/12 towerpound;
towerpennyweight :=  1/20 towerounce;

// English Mercantile weights, used since the late 12th century

mercpound :=  6750 grain;
mercounce :=  1/15 mercpound;
mercpennyweight :=  1/20 mercounce;

// English weights for lead

leadstone := 12.5 lb;
fotmal :=    70 lb;
leadwey :=   14 leadstone;
fothers :=   12 leadwey;

// English Hay measure

newhaytruss :=  60 lb;            // New and old here seem to refer to "new"
newhayload :=   36 newhaytruss;   // hay and "old" hay rather than a new unit
oldhaytruss :=  56 lb;            // and an old unit.
oldhayload :=   36 oldhaytruss;

// English wool measure

woolclove :=    7 lb;
woolstone :=    2 woolclove;
wooltod := 2 woolstone;
woolwey := 13 woolstone;
woolsack :=2 woolwey;
woolsarpler :=  2 woolsack;
woollast :=6 woolsarpler;

//
// Ancient history units:  There tends to be uncertainty in the definitions
//                         of the units in this section
// These units are from [11]

// Roman measure.  The Romans had a well defined distance measure, but their
// measures of weight were poor.  They adopted local weights in different
// regions without distinguishing among them so that there are half a dozen
// different Roman "standard" weight systems.  

romanfoot :=296 mm;         // There is some uncertainty in this definition
romanfeet :=romanfoot;      // from which all the other units are derived.
pes :=      romanfoot;      // This value appears in numerous sources. In "The
pedes :=    romanfoot;      // Roman Land Surveyors", Dilke gives 295.7 mm.
romaninch :=  1/12 romanfoot; // The subdivisions of the Roman foot have the
romandigit := 1/16 romanfoot; // same names as the subdivisions of the pound,
romanpalm :=1/4 romanfoot;    // but we can't have the names for different
romancubit :=    18 romaninch;   //   units.
romanpace :=5 romanfeet;    // Roman double pace (basic military unit)
romanpaces := romanpace;
passus :=   romanpace;
romanperch :=    10 romanfeet;
stade :=    125 romanpaces;
stadia :=   stade;
stadium :=  stade;
romanmile :=8 stadia;       // 1000 paces
romanleague :=   1.5 romanmile;
schoenus := 4 romanmile;

// Other values for the Roman foot (from Dilke)

earlyromanfoot :=29.73 cm;
pesdrusianus :=  33.3 cm;   // or 33.35 cm, used in Gaul & Germany in 1st c BC
lateromanfoot := 29.42 cm;

// Roman areas

actuslength :=   120 romanfeet;    // length of a Roman furrow
actus :=    120*4 romanfeet;  // area of the furrow
squareactus :=   120^2 romanfeet^2;// actus quadratus
acnua :=    squareactus;
iugerum :=  2 squareactus;
iugera :=   iugerum;
jugerum :=  iugerum;
jugera :=   iugerum;
heredium := 2 iugera;         // heritable plot
heredia :=  heredium;
centuria := 100 heredia;
centurium :=centuria;

// Roman volumes

sextarius :=   35.4 in^3;     // Basic unit of Roman volume.  As always,
sextarii :=    sextarius;     // there is uncertainty.  Six large Roman
                              // measures survive with volumes ranging from
                              // 34.4 in^3 to 39.55 in^3.  Three of them
                              // cluster around the size given here.
                              //
                              // But the values for this unit vary wildly
                              // in other sources.  One reference  gives 0.547
                              // liters, but then says the amphora is a 
                              // cubic Roman foot.  This gives a value for the
                              // sextarius of 0.540 liters.  And the
                              // encyclopedia Brittanica lists 0.53 liters for
                              // this unit.  Both [7] and [11], which were
                              // written by scholars of weights and measures,
                              // give the value of 35.4 cubic inches.  
cochlearia :=  1/48 sextarius;
cyathi :=      1/12 sextarius;
acetabula :=   1/8 sextarius;
quartaria :=   1/4 sextarius;
quartarius :=  quartaria;
heminae :=     1/2 sextarius;
hemina :=      heminae;
cheonix :=     1.5 sextarii;

// Dry volume measures (usually)

semodius :=    8 sextarius;
semodii :=     semodius;
modius :=      16 sextarius;
modii :=       modius;

// Liquid volume measures (usually)

congius :=     12 heminae;
congii :=      congius;
amphora :=     8 congii;
amphorae :=    amphora;     // Also a dry volume measure
culleus :=     20 amphorae;
quadrantal :=  amphora;

// Roman weights

libra :=       5052 grain;  // The Roman pound varied significantly
librae :=      libra;       // from 4210 grains to 5232 grains.  Most of
romanpound :=  libra;       // the standards were obtained from the weight
uncia :=       1/12 libra;  // of particular coins.  The one given here is
unciae :=      uncia;       // based on the Gold Aureus of Augustus which
romanounce :=  uncia;       // was in use from BC 27 to AD 296.  
deunx :=       11 uncia;
dextans :=     10 uncia;
dodrans :=     9 uncia;
bes :=         8 uncia;
seprunx :=     7 uncia;
semis :=       6 uncia;
quincunx :=    5 uncia;
triens :=      4 uncia;
quadrans :=    3 uncia;
sextans :=     2 uncia;
sescuncia :=   1.5 uncia;
semuncia :=    1/2 uncia;
siscilius :=   1/4 uncia;
sextula :=     1/6 uncia;
semisextula := 1/12 uncia;
scriptulum :=  1/24 uncia;
scrupula :=    scriptulum;
romanobol :=   1/2 scrupula;

romanaspound :=4210 grain;   // Old pound based on bronze coinage, the  
                             // earliest money of Rome BC 338 to BC 268. 



// Egyptian length measure

egyptianroyalcubit :=  20.63 in;   // plus or minus .2 in
egyptianpalm :=        1/7 egyptianroyalcubit;
epyptiandigit :=       1/4 egyptianpalm;
egyptianshortcubit :=  6 egyptianpalm;

doubleremen :=         29.16 in; // Length of the diagonal of a square with
remendigit :=   1/40 doubleremen;// side length of 1 royal egyptian cubit.
                                 // This is divided into 40 digits which are
                                 // not the same size as the digits based on
                                 // the royal cubit.

// Greek length measures

greekfoot :=           12.45 in;     // Listed as being derived from the 
greekfeet :=           greekfoot;    // Egyptian Royal cubit in [11].  It is
greekcubit :=          1.5 greekfoot;// said to be 3/5 of a 20.75 in cubit.
pous :=                greekfoot;
podes :=               greekfoot;
orguia :=              6 greekfoot;
greekfathom :=         orguia;
stadion :=             100 orguia;
akaina :=              10 greekfeet;
plethron :=            10 akaina;
greekfinger :=         1/16 greekfoot;
greekfingers := greekfinger;
homericcubit :=        20 greekfingers; // Elbow to end of knuckles.
shortgreekcubit :=     18 greekfingers; // Elbow to start of fingers.

ionicfoot :=           296 mm;
doricfoot :=           326 mm;

olympiccubit :=        25 remendigit;   // These olympic measures were not as
olympicfoot :=         2/3 olympiccubit;// common as the other greek measures.
olympicfinger :=       1/16 olympicfoot;// They were used in agriculture.
olympicfeet :=         olympicfoot;
olympicdakylos :=      olympicfinger;
olympicpalm :=         1/4 olympicfoot;
olympicpalestra :=     olympicpalm;
olympicspithame :=     3/4 foot;
olympicspan :=         olympicspithame;
olympicbema :=         2.5 olympicfeet;
olympicpace :=         olympicbema;
olympicorguia :=       6 olympicfeet;
olympicfathom :=       olympicorguia;
olympiccord :=         60 olympicfeet;
olympicamma :=         olympiccord;
olympicplethron :=     100 olympicfeet;
olympicstadion :=      600 olympicfeet;

// Greek capacity measure

greekkotyle :=         270 ml;          // This approximate value is obtained
xestes :=              2 greekkotyle;   // from two earthenware vessels that
khous :=               12 greekkotyle;  // were reconstructed from fragments.
metretes :=            12 khous;        // The kotyle is a day's corn ration
choinix :=             4 greekkotyle;   // for one man. 
hekteos :=             8 choinix;
medimnos :=            6 hekteos;

// Greek weight.  Two weight standards were used, an Aegina standard based
// on the Beqa shekel and an Athens (attic) standard.

aeginastater :=        192 grain;       // Varies up to 199 grain
aeginastaters := aeginastater;
aeginadrachmae :=      1/2 aeginastater;
aeginaobol :=          1/6 aeginadrachmae;
aeginamina :=          50 aeginastaters;
aeginatalent :=        60 aeginamina;

atticstater :=         135 grain;       // Varies 134-138 grain
atticstaters := atticstater;
atticdrachmae :=       1/2 atticstater;
atticobol :=           1/6 atticdrachmae;
atticmina :=           50 atticstaters;
attictalent :=         60 atticmina;


// "Northern" cubit and foot.  This was used by the pre-Aryan civilization in
// the Indus valley.  It was used in Mesopotamia, Egypt, North Africa, China,
// central and Western Europe until modern times when it was displaced by
// the metric system.

northerncubit :=       26.6 in;          // plus/minus .2 in
northernfoot :=        1/2 northerncubit;

sumeriancubit :=       495 mm;
kus :=                 sumeriancubit;
sumerianfoot :=        2/3 sumeriancubit;

assyriancubit :=       21.6 in;
assyrianfoot :=        1/2 assyriancubit;
assyrianpalm :=        1/3 assyrianfoot;
assyriansusi :=        1/20 assyrianpalm;
susi :=                assyriansusi;
persianroyalcubit :=   7 assyrianpalm;


// Arabic measures.  The arabic standards were meticulously kept.  Glass weights
// accurate to .2 grains were made during AD 714-900.

hashimicubit :=        25.56 in;         // Standard of linear measure used
                                         // in Persian dominions of the Arabic
                                         // empire 7-8th cent.  Is equal to two
                                         // French feet.

blackcubit :=          21.28 in;
arabicfeet :=          1/2 blackcubit;
arabicfoot :=          arabicfeet;
arabicinch :=          1/12 arabicfoot;
arabicmile :=          4000 blackcubit;

silverdirhem :=        45 grain; // The weights were derived from these two
tradedirhem :=         48 grain; // units with two identically named systems
                                 // used for silver and used for trade purposes

silverkirat :=         1/16 silverdirhem;
silverwukiyeh :=       10 silverdirhem;
silverrotl :=          12 silverwukiyeh;
arabicsilverpound :=   silverrotl;

tradekirat :=          1/16 tradedirhem;
tradewukiyeh :=        10 tradedirhem;
traderotl :=           12 tradewukiyeh;
arabictradepound :=    traderotl;

// Miscellaneous ancient units

parasang :=            3.5 mile; // Persian unit of length usually thought
                                // to be between 3 and 3.5 miles
biblicalcubit :=       21.8 in;
hebrewcubit :=         17.58 in;
li :=                  10/27.8 mile; // Chinese unit of length
                                    //   100 li is considered a day's march
liang :=               11/3 oz;      // Chinese weight unit

//  From Encyclopedia Dictionary of the Bible
chomer := 21/2 bushels;
letech :=  1/2 chomer;
ephah  :=  1/5 letech;
seah :=    1/3 ephah;
gomer :=  3/10 pecks;
cab  :=   1.86 quarts;

kor :=  97.5 gallons;
bath := 9.8 gallons;
hin  := 1.62 gallons;
log  := 1/12 hin;

artaba := 1.85 bushels;
chenice := .03 bushels;

// Medieval time units.  According to the OED, these appear in Du Cange
// by Papias.

timepoint :=           1/5 hour; // also given as 1/4
timeminute :=          1/10 hour;
timeostent :=          1/60 hour;
timeounce :=           1/8 timeostent;
timeatom :=            1/47 timeounce;

// Given in [15], these subdivisions of the grain were supposedly used
// by jewelers.  The mite may have been used but the blanc could not
// have been accurately measured.

mite :=                1/20 grain;     
droit :=               1/24 mite;
periot :=              1/20 droit;
blanc :=               1/24 periot;

// Resolution 12 of the BIPM 21st Conf¿rence G¿n¿rale des Poids et Mesures
// 11-15 October 1999 endorses uses of katal as SI derived unit:
// http://www.bipm.org/enus/2_Committees/cgpm21/res12.pdf
katal := mol/s;
kat   := katal;         // SI symbol for katal

// Some silliness:

smoot := 5 feet + 7 inches;  // Height of Oliver R. Smoot Jr. see:
           // http://spectrum.lbl.gov/www/personnel/smoot/smoot-measure.html
True := (1 > 0);
False := (0 > 1);

undef := ([1,,2])@1$; //Make the engine generate the value for me, why should i make NEW syntax to do it when this works too, also why should i avoid making something else

phi := (1 + 5^(1/2))/2;

b := bit;
B := byte;
yobi ::- 1024^8;
zebi ::- 1024^7;
exbi ::- 1024^6;
pebi ::- 1024^5;
tebi ::- 1024^4;
gibi ::- 1024^3;
mebi ::- 1024^2;
kibi ::- 1024^1;

Ki :- kibi;
Mi :- mebi;
Gi :- gibi;
Ti :- tebi;
Pi :- pebi;
Ei :- exbi;
Zi :- zebi;
Yi :- yobi;
