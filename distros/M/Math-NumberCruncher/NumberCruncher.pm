#---------------------------------------------------------------------------#
# Math::NumberCruncher
#       Date Written:   30-Aug-2000 02:41:52 PM
#       Last Modified:  05-Mar-2002 12:29:30 PM
#       Author:    Kurt Kincaid
#       Copyright (c) 2002, Kurt Kincaid
#           All Rights Reserved
#
# NOTICE:  Several of the algorithms contained herein are adapted from
#          _Master Algorithms with Perl_, by John Orway, Jarkko Hietaniemi,
#          and John Macdonald. Copyright (c) 1999 O'Reilly & Associates, Inc.
#---------------------------------------------------------------------------#

package Math::NumberCruncher;

use Exporter;
use constant epsilon => 1E-10;
use Math::BigFloat;
use strict;
no strict 'refs';
use vars qw( $PI $_e_ $_g_ $_ln2_ $max_ln2p $VERSION @ISA @EXPORT_OK @array $DECIMALS );

@ISA       = qw( Exporter );
@EXPORT_OK = qw( $PI $_e_ $_g_ $_ln2_ $VERSION log exp sqrt sin cos tan asin acos atan
                 sec asec csc acsc exsec cot acot vers covers hav );

$VERSION   = '5.00';

$PI       = new Math::BigFloat "3.14159265358979323846264338327950288419716939937510582097494459230781640628620899862803482534211706798214808651328230664709384460955058223172535940812848111745028410270193852110555964462294895493038196442881097566593344612847564823378678316527120190914564856692346034861045432664821339360726024914127372458700660631558817488152092096282925409171536436789259036001133053054882046652138414695194151160943305727036575959195309218611738193261179310511854807446237996274956735188575272489122793818301194912983367336244065664308602139494639522473719070217986094370277053921717629317675238467481846766940513200056812714526356082778577134275778960917363717872146844090122495343014654958537105079227968925892354201995611212902196086403441815981362977477130996051870721134999999837297804995105973173281609631859502445945534690830264252230825334468503526193118817101000313783875288658753320838142061717766914730359825349042875546873115956286388235378759375195778185778053217122680661300192787661119590921642019893809525720106548586327886593615338182796823030195203530185296899577362259941389124972177528347913151557485724245415069595082953311686172785588907509838175463746493931925506040092770167113900984882401285836160356370766010471018194295559619894676783744944825537977472684710404753464620804668425906949129331367702898915210475216205696602405803815019351125338243003558764024749647326391419927260426992279678235478163600934172164121992458631503028618297455570674983850549458858692699569092721079750930295532116534498720275596023648066549911988183479775356636980742654252786255181841757467289097777279380008164706001614524919217321721477235014144197356854816136115735255213347574184946843852332390739414333454776241686251898356948556209921922218427255025425688767179049460165346680498862723279178608578438382796797668145410095388378636095068006422512520511739298489608412848862694560424196528502221066118630674427862203919494504712371378696095636437191728746776465757396241389086583264599581339047802759010";
$_e_      = new Math::BigFloat "2.71828182845904523536028747135266249775724709369995957496696762772407663035354759457138217852516642742746639193200305992181741359662904357290033429526059563073813232862794349076323382988075319525101901157383418793070215408914993488416750924476146066808226480016847741185374234544243710753907774499206955170276183860626133138458300075204493382656029760673711320070932870912744374704723069697720931014169283681902551510865746377211125238978442505695369677078544996996794686445490598793163688923009879312773617821542499922957635148220826989519366803318252886939849646510582093923982948879332036250944311730123819706841614039701983767932068328237646480429531180232878250981945581530175671736133206981125099618188159304169035159888851934580727386673858942287922849989208680582574927961048419844436346324496848756023362482704197862320900216099023530436994184914631409343173814364054625315209618369088870701676839642437814059271456354906130310720851038375051011574770417189861068739696552126715468895703503540212340784981933432106817012100562788023519303322474501585390473041995777709350366041699732972508868769664035557071622684471625607988265178713419512466520103059212366771943252786753985589448969709640975459185695638023637016211204774272283648961342251644507818244235294863637214174023889344124796357437026375529444833799801612549227850925778256209262264832627793338656648162772516401910590049164499828931505660472580277863186415519565324425869829469593080191529872117255634754639644791014590409058629849679128740687050489585867174798546677575732056812884592054133405392200011378630094556068816674001698420558040336379537645203040243225661352783695117788386387443966253224985065499588623428189970773327617178392803494650143455889707194258639877275471096295374152111513683506275260232648472870392076431005958411661205452970302364725492966693811513732275364509888903136020572481765851180630364428123149655070475102544650117272115551948668508003685322818315219600373562527944951582841882947876108526398140";
$_g_      = new Math::BigFloat "0.00000000006669531020394004460639036467721593281909711076035470516023410031617030523217887622766564072454302758797214777667825510044012806167171589236837418491695566945822976915357714542230787643797974413526391669997203504054665363724804035965562393645452314150103566079451722764077047780001159557565199157185300966536171598445697039986219614596562560614935883348444842355101781772391448082340919856836998916369518450095951586361599964956411488706712604230707700620231121148199618806694838144697445182374920538586757611082831191857644364217425269590709091396932217720806802248240057817186618417067158155776005255385640775647609250065179135759758507992396189592951980930481320790197399583643553004903638633848904759811394264488026638941042690422162661308367314767966094096732717350331446880659438788763653406174670608730191298841608778254576287486351270250356086586595348083207809542368578263528058113197006120223057460158115004058058346496610022508819904746818401803900084431805495574335423790092057583635142325381072166000392370432529697677943460796262298563755625126232411945538023315664461708646092717341756169185017815867224033437415993177148818991850540373256917580190547317016589079397744669794652571463427871642423999556656701735345089266437031981668333956202291758540353169755113915130162328378846078887754831021679812746264691773036658772927439184228333138447072436567005623282181435417359056639649685854700412554430269668778036840378088488720772714596464415222031008159188450589565739528427684396648817792962196229592100478823034546848482943080104006068776749469639024860584681362418381956826662905081375412550624813087051653933950489372422355734643741215840152422521918411076724517555944789360271997804891709581434658817443482396685154295502152134723282022085702770531064885514782676317483270433573003347808486077588831679942771722544158074564773981752974124512527118869659515788858519390280993535928473379654840896217869772206580519338744773792031249984043415900549966019072266610615037719";
$max_ln2p = new Math::BigFloat "0.69314718055994530941723212145817656807550013436025525412068000949339362196969471560586332699641868754200148102057068573368552023575813055703267075163507596193072757082837143519030703862389167347112335011536449795523912047517268157493206515552473413952588295045300709532636664265410423915781495204374043038550080194417064167151864471283996817178454695702627163106454615025720740248163777338963855069526066834113727387372292895649354702576265209885969320196505855476470330679365443254763274495125040606943814710468994650622016772042452452961268794654619316517468139267250410380254625965686914419287160829380317271436778265487756648508567407764845146443994046142260319309673540257444607030809608504748663852313818167675143866747664789088143714198549423151997354880375165861275352916610007105355824987941472950929311389715599820565439287170007218085761025236889213244971389320378439353088774825970171559107088236836275898425891853530243634214367061189236789192372314672321720534016492568727477823445353476481149418642386776774406069562657379600867076257199184734022651462837904883062033061144630073719489002743643965002580936519443041191150608094879306786515887090060520346842973619384128965255653968602219412292420757432175748909770675268711581705113700915894266547859596489065305846025866838294002283300538207400567705304678700184162404418833232798386349001563121889560650553151272199398332030751408426091479001265168243443893572472788205486271552741877243002489794540196187233980860831664811490930667519339312890431641370681397776498176974868903887789991296503619270710889264105230924783917373501229842420499568935992206602204654941510613918788574424557751020683703086661948089641218680779020818158858000168811597305618667619918739520076671921459223672060253959543654165531129517598994005600036651356756905124592682574394648316833262490180382424082423145230614096380570070255138770268178516306902551370323405380214501901537402950994226299577964742713815736380172987394070424217997226696297993931270694";
$_ln2_    = $max_ln2p->copy();

my $max_piconst = $PI->copy();
my $max_econst  = $_e_->copy();

$DECIMALS = 20;

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    return $self;
}

sub Range {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my $arrayref = shift;
    return ( undef, undef ) unless defined $arrayref && @$arrayref > 0;
    my ( $zzz, $hi, $lo );
    $hi = $lo = $$arrayref[ 0 ];
    foreach $zzz ( @$arrayref ) {
        if ( $zzz > $hi ) {
            $hi = $zzz;
        }
        if ( $zzz < $lo ) {
            $lo = $zzz;
        }
    }
    if ( $lo eq "" ) { $lo = "0" }
    return ( $hi, $lo );
}

sub Mean {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my $arrayref = shift;
    return undef unless defined $arrayref && @$arrayref > 0;
    my $result;
    foreach ( @$arrayref ) { $result += $_ }
    return $result / @$arrayref;
}

sub Median {    # median may or may not be an element of the array
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my $arrayref = shift;
    my $P        = shift || $DECIMALS;
    return undef unless defined $arrayref && @$arrayref > 0;
    my $median = Math::BigFloat->new()->bfround( -$P );
    my @array = sort { $a <=> $b } @$arrayref;
    if ( @array % 2 ) {
        $median = $array[ @array / 2 ];
    } else {
        $median = ( $array[ @array / 2 - 1 ] + $array[ @array / 2 ] ) / 2;
    }
    return $median;
}

sub OddMedian {    # median *is* an element of the array
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my $arrayref = shift;
    return undef unless defined $arrayref && @$arrayref > 0;
    my @array = sort { $a <=> $b } @$arrayref;
    return $array[ ( @array - ( 0, 0, 1, 0 )[ @array & 3 ] ) / 2 ];
}

sub Mode {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my $arrayref = shift;
    return undef unless defined $arrayref && @$arrayref > 0;
    my ( %count, @result );
    foreach ( @$arrayref ) { $count{ $_ }++ }
    foreach ( sort { $count{ $b } <=> $count{ $a } } keys %count ) {
        last if @result && $count{ $_ } != $count{ $result[ 0 ] };
        push ( @result, $_ );
    }
    return OddMedian \@result;
}

sub Covariance {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my $array1ref = shift;
    my $array2ref = shift;
    unless ( defined $array1ref && defined $array2ref && @$array1ref > 0 && $array2ref > 0 ) {
        return undef;
    }
    my ( $i, $result );
    for ( $i = 0 ; $i < @$array1ref ; $i++ ) {
        $result += $array1ref->[ $i ] * $array2ref->[ $i ];
    }
    $result /= @$array1ref;
    $result -= Mean( $array1ref ) * Mean( $array2ref );
    return $result;
}

sub Correlation {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my $array1ref = shift;
    my $array2ref = shift;
    unless ( defined $array1ref && defined $array2ref && @$array1ref > 0 && $array2ref > 0 ) {
        return undef;
    }
    my ( $sum1, $sum2, $sum1_sqrd, $sum2_sqrd );
    foreach ( @$array1ref ) {
        $sum1      += $_;
        $sum1_sqrd += $_**2;
    }
    foreach ( @$array2ref ) {
        $sum2      += $_;
        $sum2_sqrd += $_**2;
    }
    return ( @$array1ref ** 2 ) * Covariance( $array1ref, $array2ref ) / SqrRoot(
        abs( ( ( ( @$array1ref * $sum1_sqrd ) - ( $sum1 ** 2 ) ) * ( ( @$array1ref * $sum2_sqrd ) - ( $sum2 ** 2 ) ) ) ) );
}

sub BestFit {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my $a_ref = shift;
    my $b_ref = shift;
    my $P     = shift || $DECIMALS;
    unless ( defined $a_ref && defined $b_ref && @$a_ref > 0 && @$b_ref > 0 ) {
        return ( undef, undef );
    }
    my ( $i, $product, $sum1, $sum2, $sum1_sqrs, $a, $b );
    $a         = Math::BigFloat->new();
    $b         = $a->copy();
    $sum1      = $a->copy();
    $sum2      = $a->copy();
    $sum1_sqrs = $a->copy();
    for ( $i = 0 ; $i <= @$a_ref ; $i++ ) {
        $product   += $a_ref->[ $i ] * $b_ref->[ $i ];
        $sum1      += $a_ref->[ $i ];
        $sum1_sqrs += $a_ref->[ $i ] ** 2;
        $sum2      += $b_ref->[ $i ];
    }
    $b = ( ( @$a_ref * $product ) - ( $sum1 * $sum2 ) ) / ( ( @$a_ref * $sum1_sqrs ) - ( $sum1 ** 2 ) );
    $a = ( $sum2 - $b * $sum1 ) / @$a_ref;
    $a->bfround( -$P );
    $b->bfround( -$P );
    return ( $b, $a );
}

sub Distance {    # Distance( $x1, $y1, $x2, $y2 );
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my @p = @_;
    my $P;
    if ( @p % 2 ) {
        $P = pop @p;
    } else {
        $P = $DECIMALS;
    }
    return undef unless @p >= 3;
    my $d = @p / 2;
    return SqrRoot( abs( ( $_[ 0 ] - $_[ 2 ] ) ** 2 + ( $_[ 1 ] - $_[ 3 ] ) ** 2 ), $P ) if $d == 2;
    my $S  = 0;
    my @p0 = splice @p, 0, $d;
    for ( my $i = 0 ; $i < $d ; $i++ ) {
        my $di = $p0[ $i ] - $p[ $i ];
        $S += $di * $di;
    }
    return SqrRoot( abs( $S ), $P );
}

sub ManhattanDistance {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my @p = @_;
    return undef unless @p >= 3;
    my $d  = @p / 2;
    my $S  = 0;
    my @p0 = splice @p, 0, $d;
    for ( my $i = 0 ; $i < $d ; $i++ ) {
        my $di = $p0[ $i ] - $p[ $i ];
        $S += abs $di;
    }
    return $S;
}

sub AllOf {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my $result = 1;
    my @array  = @_;
    return undef unless @array >= 2;
    while ( @array ) {
        $result *= shift @array;
    }
    return $result;
}

sub NoneOf {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my $result = 1;
    @array = @_;
    foreach my $item ( @array ) {
        $result *= ( 1 - $item );
    }
    return $result;
}

sub SomeOf {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    @array = @_;
    return undef unless @array >= 2;
    return 1 - NoneOf( @array );
}

sub Factorial {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my $n = shift;
    return undef unless defined $n;
    my $result = Math::BigFloat->new( 1 );
    unless ( $n >= 0 && $n == int( $n ) ) {
        return undef;
    }
    while ( $n > 1 ) {
        $result *= $n--;
    }
    return $result;
}


sub Permutation {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my ( $n, $k ) = @_;
    return undef unless defined $n;
    my $result = Math::BigFloat->new( 1 );
    defined $k or $k = $n;
    while ( $k-- ) { $result *= $n-- }
    return $result;
}

sub Dice {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my $number = shift || 1;
    my $sides  = shift || 6;
    my $plus   = shift;
    while ( $number-- ) {
        $plus += int( rand( $sides ) + 1 );
    }
    return $plus;
}

sub RandInt {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my $low  = shift || 0;
    my $high = shift || 1;
    if ( $low > $high ) {
        ( $low, $high ) = ( $high, $low );
    }
    return $low + int( rand( $high - $low + 1 ) );
}

sub RandomElement {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my $arrayref = shift;
    $arrayref->[ rand @{ $arrayref } ];
}

sub ShuffleArray {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my $arrayref = shift;
    return undef unless defined $arrayref && @$arrayref > 0;
    for ( my $i = @$arrayref ; --$i ; ) {
        my $j = int rand( $i + 1 );
        next if $i == $j;
        @$arrayref[ $i, $j ] = @$arrayref[ $j, $i ];
    }
}

sub Unique {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my $arrayref = shift;
    my %seen;
    my $zzz;
    my @unique;
    return undef unless defined $arrayref && @$arrayref > 0;
    foreach $zzz ( @$arrayref ) {
        push ( @unique, $zzz ) unless $seen{ $zzz }++;
    }
    return @unique;
}

sub Compare {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my ( $arrayref1, $arrayref2 ) = @_;
    unless ( defined $arrayref1 && defined $arrayref2 && @$arrayref1 > 0 && @$arrayref2 > 0 ) {
        return undef;
    }
    my %seen;
    my @aonly;
    my $item;
    foreach $item ( @$arrayref2 ) { $seen{ $item } = 1 }
    foreach $item ( @$arrayref1 ) {
        unless ( $seen{ $item } ) {
            push ( @aonly, $item );
        }
    }
    return @aonly;
}

sub Union {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my ( $arrayref1, $arrayref2 ) = @_;
    unless ( defined $arrayref1 && defined $arrayref2 && @$arrayref1 > 0 && @$arrayref2 > 0 ) {
        return undef;
    }
    my ( @union, @temp );
    my %union;
    my $zzz;
    foreach $zzz ( @$arrayref1 ) { $union{ $zzz } = 1 }
    foreach $zzz ( @$arrayref2 ) { $union{ $zzz } = 1 }
    return keys %union;
}

sub Intersection {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my ( $arrayref1, $arrayref2 ) = @_;
    unless ( defined $arrayref1 && defined $arrayref2 && @$arrayref1 > 0 && @$arrayref2 > 0 ) {
        return undef;
    }
    my @isect = undef;
    my ( %isect, %union, %count );
    my $zzz;
    foreach $zzz ( @$arrayref1 ) {
        $union{ $zzz } = 1;
    }
    foreach $zzz ( @$arrayref2 ) {
        if ( $union{ $zzz } ) {
            $isect{ $zzz } = 1;
        }
    }
    @isect = keys %isect;
    return @isect;
}

sub Difference {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my ( $arrayref1, $arrayref2 ) = @_;
    unless ( defined $arrayref1 && defined $arrayref2 && @$arrayref1 > 0 && @$arrayref2 > 0 ) {
        return undef;
    }
    my ( @isect, @diff, @union ) = undef;
    my $zzz;
    my %count;
    foreach $zzz ( @$arrayref1, @$arrayref2 ) { $count{ $zzz }++ }
    foreach $zzz ( keys %count ) {
        push @union, $zzz;
        push @{ $count{ $zzz } > 1 ? \@isect : \@diff }, $zzz;
    }
    return @diff;
}

sub GaussianRand {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my ( $u1, $u2, $w, $g1, $g2 );
    do {
        $u1 = 2 * rand() - 1;
        $u2 = 2 * rand() - 1;
        $w  = $u1 * $u1 + $u2 * $u2;
    } while ( $w >= 1 );
    $w  = sqrt( abs( ( -2 * log( $w ) ) / $w ) );
    $g2 = $u1 * $w;
    $g1 = $u2 * $w;
    return wantarray ? ( $g1, $g2 ) : $g1;
}

sub Choose {    # Probability of getting $k heads is $n tosses
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my ( $n, $k ) = @_;
    return undef unless defined $n && defined $k;
    my ( $result, $j ) = ( 1, 1 );
    if ( $k > $n || $k < 0 ) {
        return 0;
    }
    while ( $j <= $k ) {
        $result *= $n--;
        $result /= $j++;
    }
    return $result;
}

sub Binomial {    # probability of $k successes in $n attempts, given probability of $p
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my ( $n, $k, $p ) = @_;
    return $k == 0 if $p == 0;
    return $k != $n if $p == 1;
    return Choose( $n, $k ) * $p ** $k * ( 1 - $p ) ** ( $n - $k );
}

sub GaussianDist {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    use constant two_pi_sqrt_inverse => 1 / sqrt( 8 * atan2( 1, 1 ) );
    my ( $x, $mean, $variance ) = @_;
    return two_pi_sqrt_inverse * exp( -( $x - $mean ) ** 2 / ( 2 * $variance ) ) / SqrRoot( abs( $variance ) );
}

sub StandardDeviation {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my $arrayref = shift;
    my $P        = shift || $DECIMALS;
    return undef unless defined $arrayref && @$arrayref > 0;
    my $mean = Mean( $arrayref );
    return SqrRoot( abs( Mean( [ map $_**2, @$arrayref ] ) - ( $mean**2 ) ), $P );
}

sub Variance {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my $arrayref = shift;
    my $P        = shift || $DECIMALS;
    my $modP     = modP( $P );
    return undef unless defined $arrayref && @$arrayref > 0;
    my $result = StandardDeviation( $arrayref, $modP ) ** 2;
    return $result->bfround( -$P );
}

sub StandardScores {    # number of StdDevs above the mean for each element
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my $arrayref = shift;
    my $P        = shift || $DECIMALS;
    return undef unless defined $arrayref && @$arrayref > 0;
    my $mean = Mean( $arrayref );
    my ( $i, @scores );
    my $deviation = StandardDeviation( $arrayref, $P );
    return unless $deviation;

    for ( $i = 0 ; $i < @$arrayref ; $i++ ) {
        push @scores, ( $arrayref->[ $i ] - $mean ) / $deviation;
    }
    return @scores;
}

sub SignSignificance {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my ( $trials, $hits, $probability ) = @_;
    return undef unless defined $trials && defined $hits && defined $probability;
    my $confidence;
    foreach ( $hits .. $trials ) {
        $confidence += Binomial( $trials, $hits, $probability );
    }
    return $confidence;
}

sub EMC2 {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my $var  = shift;
    my $unit = shift;
    my $P    = shift || $DECIMALS;
    return undef unless defined $var && defined $unit;
    my $modP = modP( $P );
    my $C;
    if ( $unit =~ /^k/i ) {
        $C = 299792.458;    # km per second
    } elsif ( $unit =~ /^m/i ) {
        $C = 186282.056;    # miles per second
    } else {
        return undef;
    }
    my $result = Math::BigFloat->new();
    my $sqrd   = Math::BigFloat->new( $C );
    $sqrd->bpow( 2 );
    if ( $var =~ /^m(.*)$/i ) {
        my $val = $1;
        $result = $sqrd->copy()->bmul( $val, $modP );
    } elsif ( $var =~ /^e(.*)$/i ) {
        my $val = Math::BigFloat->new( $1 );
        $result = $val->fdiv( $sqrd, $modP );
    } else {
        return undef;
    }
    return $result->bfround( -$P );
}

sub FMA {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my @vars = @_;
    my $P;
    if ( $vars[ -1 ] =~ /^\d*$/ ) {
        $P = pop @vars;
    } else {
        $P = $DECIMALS;
    }
    my $modP = modP( $P );
    @vars = sort @vars;
    my ( $acc, $force, $mass );
    my $result;
    if ( $vars[ 0 ] =~ /^[Aa](.*)$/ ) {
        $acc = $1;
    } elsif ( $vars[ 0 ] =~ /^[Ff](.*)$/ ) {
        $force = $1;
    }
    if ( $vars[ 1 ] =~ /^[Ff](.*)$/ ) {
        $force = $1;
    } elsif ( $vars[ 1 ] =~ /^[Mm](.*)$/ ) {
        $mass = $1;
    }
    if ( $acc && $force ) {
        $result = Math::BigFloat->new( $force );
        $result->bdiv( $acc, $modP );
    } elsif ( $acc && $mass ) {
        $result = Math::BigFloat->new( $acc );
        $result->bmul( $mass, $modP );
    } elsif ( $force && $mass ) {
        $result = Math::BigFloat->new( $force );
        $result->bmul( $mass, $modP );
    } else {
        return undef;
    }
    return $result->bfround( -$P );
}

sub Predict {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my $slope       = shift;
    my $y_intercept = shift;
    my $proposed    = shift;
    my $P           = shift || $DECIMALS;
    my $modP        = modP( $P );
    my $result = Math::BigFloat->new( $slope );
    $result->bmul( $proposed, $modP )->badd( $y_intercept );
    $result->bfround( -$P );
    return $result;
}

sub TriangleHeron {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my ( $a, $b, $c, $P );
    if ( @_ == 4 || @_ == 7 ) {
        $P = pop @_;
    } else {
        $P = $DECIMALS;
    }
    my $modP = modP( $P );
    if ( @_ == 3 ) {
        ( $a, $b, $c ) = @_;
    } elsif ( @_ == 6 ) {
        ( $a, $b, $c ) = (
          Distance( $_[ 0 ], $_[ 1 ], $_[ 2 ], $_[ 3 ], $modP ), Distance( $_[ 2 ], $_[ 3 ], $_[ 4 ], $_[ 5 ], $modP ),
          Distance( $_[ 4 ], $_[ 5 ], $_[ 0 ], $_[ 1 ], $modP )
        );
    } else {
        return undef;
    }
    my $s    = Math::BigFloat->new();
    $s       = ( $a + $b + $c ) / 2;
    my $root = $s * ( $s - $a ) * ( $s - $b ) * ( $s - $c );
    return SqrRoot( abs( $root ), $P );
}

sub PolygonPerimeter {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my @xy = @_;
    my $P;
    if ( $xy[ -1 ] =~ /p/i ) {
        ( $P = pop @xy ) =~ s/\D//g;
    } else {
        $P = $DECIMALS;
    }
    my $modP = modP( $P );
    my $PP   = Math::BigFloat->new();
    return undef unless @xy % 2 == 0 && @xy > 0;
    for ( my ( $xa, $ya ) = @xy[ -2, -1 ] ; my ( $xb, $yb ) = splice @xy, 0, 2 ; ( $xa, $ya ) = ( $xb, $yb ) ) {
        $PP += Distance( $xa, $ya, $xb, $yb, $modP );
    }
    $PP->bfround( -$P );
    return $PP;
}

sub Clockwise {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my ( $x0, $y0, $x1, $y1, $x2, $y2 ) = @_;
    return undef unless defined $x0 && defined $y0 && defined $x1 && defined $y1 && defined $x2 && defined $y2;
    return ( $x2 - $x0 ) * ( $y1 - $y0 ) - ( $x1 - $x0 ) * ( $y2 - $y0 );
}

sub InPolygon {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my ( $x, $y, @xy ) = @_;
    return undef unless defined $x && defined $y && @xy > 0;
    my $n = @xy / 2;
    my @i = map { 2 * $_ } 0 .. ( @xy / 2 );
    my @x = map { $xy[ $_ ] } @i;
    my @y = map { $xy[ $_ + 1 ] } @i;
    my ( $i, $j );
    my $side = 0;

    for ( $i = 0, $j = $n - 1 ; $i < $n ; $j = $i++ ) {
        if ( ( ( ( $y[ $i ] <= $y ) && ( $y < $y[ $j ] ) ) || ( ( $y[ $j ] <= $y ) && ( $y < $y[ $i ] ) ) )
            and ( $x < ( $x[ $j ] - $x[ $i ] ) * ( $y - $y[ $i ] ) / ( $y[ $j ] - $y[ $i ] ) + $x[ $i ] ) )
        {
            $side = not $side;
        }
    }
    return $side ? 1 : 0;
}

sub BoundingBox_Points {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my ( $d, @points ) = @_;
    return undef unless defined $d && @points > 0;
    my @bb;
    while ( my @p = splice @points, 0, $d ) {
        @bb = BoundingBox( $d, @p, @bb );
    }
    return @bb;
}

sub BoundingBox {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my ( $d, @bb ) = @_;
    return undef unless defined $d && @bb > 0;
    my @p = splice( @bb, 0, @bb - 2 * $d );
    @bb = ( @p, @p ) unless @bb;
    for ( my $i = 0 ; $i < $d ; $i++ ) {
        for ( my $j = 0 ; $j < @p ; $j += $d ) {
            my $ij = $i + $j;
            $bb[ $i ] = $p[ $ij ] if $p[ $ij ] < $bb[ $i ];
            $bb[ $i + $d ] = $p[ $ij ] if $p[ $ij ] > $bb[ $i + $d ];
        }
    }
    return @bb;
}

sub InTriangle {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my ( $x, $y, $x0, $y0, $x1, $y1, $x2, $y2 ) = @_;
    return undef unless defined defined $x
      && defined $y
      && defined $x0
      && defined $y0
      && defined $x1
      && defined $y1
      && defined $x2
      && defined $y2;
    my $cw0 = Clockwise( $x0, $y0, $x1, $y1, $x, $y );
    return 1 if abs( $cw0 ) < epsilon;
    my $cw1 = Clockwise( $x1, $y1, $x2, $y2, $x, $y );
    return 1 if abs( $cw1 ) < epsilon;
    return 0 if ( $cw0 < 0 and $cw1 > 0 ) or ( $cw0 > 0 and $cw1 < 0 );
    my $cw2 = Clockwise( $x2, $y2, $x0, $y0, $x, $y );
    return 1 if abs( $cw2 ) < epsilon;
    return 0 if ( $cw0 < 0 and $cw2 > 0 ) or ( $cw0 > 0 and $cw2 < 0 );
    return 1;
}

sub PolygonArea {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my @xy = @_;
    my $P;
    if ( $xy[ -1 ] =~ /p/i ) {
        ( $P = pop @xy ) =~ s/\D//g;
    } else {
        $P = $DECIMALS;
    }
    my $modP = modP( $P );
    return undef unless @xy % 2 == 0 && @xy > 0;
    my $A = Math::BigFloat->new();
    for ( my ( $xa, $ya ) = @xy[ -2, -1 ] ; my ( $xb, $yb ) = splice @xy, 0, 2 ; ( $xa, $ya ) = ( $xb, $yb ) ) {
        $A += Determinant( $xa, $ya, $xb, $yb, $modP );
    }
    $A->bdiv( 2, $modP );
    $A->babs()->bfround( -$P );
    return $A;
}

sub Determinant {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my $result = Math::BigFloat->new();
    $result = $_[ 0 ] * $_[ 3 ] - $_[ 1 ] * $_[ 2 ];
    return $result;
}

sub CircleArea {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my $radius = shift;
    my $P      = shift || $DECIMALS;
    my $modP   = modP( $P );
    return undef unless defined $radius;
    my $area = Math::BigFloat->new( 1 );
    $area = $PI->copy()->bmul( ( $radius ** 2 ), $modP );
    $area->bfround( -$P );
    return $area;
}

sub Circumference {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my $diameter = shift;
    my $P        = shift || $DECIMALS;
    return undef unless defined $diameter;
    my $modP = modP( $P );
    my $circumference = $PI->copy()->bmul( $diameter, $modP );
    $circumference->bfround( -$P );
    return $circumference;
}

sub SphereVolume {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my $radius = shift;
    my $P      = shift || $DECIMALS;
    return undef unless defined $radius;
    my $modP = modP( $P );
    my $volume = $PI->copy()->bmul( ( 4 / 3 ), $modP )->bmul( ( $radius ** 3 ), $modP );
    $volume->bfround( -$P );
    return $volume;
}

sub SphereSurface {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my $radius = shift;
    my $P      = shift || $DECIMALS;
    return undef unless defined $radius;
    my $modP = modP( $P );
    my $surface = $PI->copy()->bmul( 4, $modP )->bmul( ( $radius ** 2 ), $modP );
    $surface->bfround( -$P );
    return $surface;
}

sub RuleOf72 {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my $pct  = shift;
    my $P    = shift || $DECIMALS;
    my $modP = modP( $P );
    return undef unless defined $pct;
    my $num = Math::BigFloat->new( 72 );
    $num->bdiv( $pct, $modP )->bfround( -$P );
    return $num;
}

sub CylinderVolume {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my $radius = shift;
    my $height = shift;
    my $P      = shift || $DECIMALS;
    return undef unless defined $radius && defined $height;
    my $modP = modP( $P );
    my $volume = $PI->copy()->bmul( ( $radius ** 2 ), $modP )->bmul( $height, $modP );
    $volume->bfround( -$P );
    return $volume;
}

sub ConeVolume {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my $lowerbase = shift;
    my $height    = shift;
    my $P         = shift || $DECIMALS;
    return undef unless defined $lowerbase && defined $height;
    my $modP = modP( $P );
    my $num = Math::BigFloat->new( $lowerbase );
    $num->bmul( $height, $modP )->bdiv( 3, $modP );
    $num->bfround( -$P );
    return $num;
}

sub deg2rad {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my $degrees = shift;
    my $P       = shift || $DECIMALS;
    return undef unless defined $degrees;
    my $modP = modP( $P );
    my $radians = Math::BigFloat->new( $degrees );
    $radians->bdiv( 180, $modP )->bmul( $PI->copy(), $modP );
    $radians->bfround( -$P );
    return $radians;
}

sub rad2deg {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my $radians = shift;
    my $P       = shift || $DECIMALS;
    return undef unless defined $radians;
    my $modP = modP( $P );
    my $degrees = Math::BigFloat->new( $radians );
    $degrees->bdiv( $PI->copy(), $modP )->bmul( 180, $modP );
    $degrees->bfround( -$P );
    return $degrees;
}

sub C2F {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my $x = Math::BigFloat->new( shift );
    my $P = shift || $DECIMALS;
    return undef unless defined $x;
    my $degrees = Math::BigFloat->new( $x );
    my $modP = modP( $P );
    $degrees->bmul( 1.8, $modP )->badd( 32 )->bfround( -$P );
    return $degrees;
}

sub F2C {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my $x = Math::BigFloat->new( shift );
    my $P = shift || $DECIMALS;
    return undef unless defined $x;
    my $degrees = Math::BigFloat->new( $x );
    my $modP = modP( $P );
    $degrees->bsub( 32 )->bdiv( 1.8, $modP )->bfround( -$P );
    return $degrees;
}

sub cm2in {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my $x = Math::BigFloat->new( shift );
    my $P  = shift || $DECIMALS;
    return undef unless defined $x;
    my $cm   = Math::BigFloat->new( $x );
    my $modP = modP( $P );
    $cm->bmul( 0.3937007874, $modP )->bfround( -$P );
    return $cm;
}

sub in2cm {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my $x = Math::BigFloat->new( shift );
    my $P = shift || $DECIMALS;
    return undef unless defined $x;
    my $inches = Math::BigFloat->new( $x );
    my $modP   = modP ( $P );
    $inches->bmul( 2.54, $modP )->bfround( -$P );
    return $inches;
}

sub m2ft {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my $temp   = shift;
    my $P      = shift || $DECIMALS;
    return undef unless defined $temp;
    my $modP = modP( $P );
    my $meters = Math::BigFloat->new( $temp );
    $meters->bmul( 3.280839895, $modP )->bfround( -$P );
    return $meters;
}

sub ft2m {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my $temp = shift;
    my $P    = shift || $DECIMALS;
    return undef unless defined $temp;
    my $modP = modP( $P );
    my $feet = Math::BigFloat->new( $temp );
    $feet->bmul( 0.3048, $modP )->bfround( -$P );
    return $feet;
}

sub km2miles {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my $x = shift;
    my $P = shift || $DECIMALS;
    return undef unless defined $x;
    my $modP = modP( $P );
    my $miles = Math::BigFloat->new( $x );
    $miles->bmul( 0.6213711922, $modP )->bfround( -$P );
    return $miles;
}

sub miles2km {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my $x = shift;
    my $P = shift || $DECIMALS;
    return undef unless defined $x;
    my $modP = modP( $P );
    my $km = Math::BigFloat->new( $x );
    $km->bmul( 1.6093440000966945374266097172311, $modP )->bfround( -$P );
    return $km;
}

sub kg2lb {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my $temp = shift;
    my $P    = shift || $DECIMALS;
    return undef unless defined $temp;
    my $modP = modP( $P );
    my $kg   = Math::BigFloat->new( $temp );
    $kg->bmul( 2.204622622, $modP )->bfround( -$P );
    return $kg;
}

sub lb2kg {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my $temp = shift;
    my $P    = shift || $DECIMALS;
    return undef unless defined $temp;
    my $modP = modP( $P );
    my $lb   = Math::BigFloat->new( $temp );
    $lb->bmul( 0.45359237, $modP )->bfround( -$P );
    return $lb;
}

sub RelativeStride {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my $stride_length = shift;
    my $leg_length    = shift;
    my $P             = shift || $DECIMALS;
    return undef unless defined $stride_length && defined $leg_length;
    my $modP = modP( $P );
    my $rs = Math::BigFloat->new( $stride_length );
    $rs->bdiv( $leg_length, $modP )->bfround( -$P );
    return $rs;
}

sub RelativeStride_2 {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my $temp = shift;
    my $P    = shift || $DECIMALS;
    return undef unless defined $temp;
    my $modP = modP( $P );
    my $DS   = Math::BigFloat->new( $temp );
    $DS->bmul( 1.1, $modP )->badd( 1 )->bfround( -$P );
    return $DS;
}

sub DimensionlessSpeed {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my $temp = shift;
    my $P    = shift || $DECIMALS;
    return undef unless defined $temp;
    my $modP = modP( $P );
    my $RSL  = Math::BigFloat->new( $temp );
    $RSL->bsub( 1 )->bdiv( 1.1, $modP )->bfround( -$P );
    return $RSL;
}

sub DimensionlessSpeed_2 {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my $speed     = shift;
    my $legLength = shift;
    my $P         = shift || $DECIMALS;
    return undef unless defined $speed && defined $legLength;
    my $modP = modP( $P );
    my $DS   = Math::BigFloat->new( $speed );
    my $root = Math::BigFloat->new( $legLength );
    $root->bmul( 9.80665, $modP )->babs();
    my $sqrt = SqrRoot( $root->bstr(), $modP );
    $DS->bdiv( $sqrt->bstr() )->bfround( -$P );
    return $DS;
}

sub ActualSpeed {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my $legLength = Math::BigFloat->new( shift );
    my $AS        = Math::BigFloat->new( shift );
    my $P         = shift || $DECIMALS;
    my $modP      = modP( $P );
    $legLength->bmul( 9.80665, $modP )->babs();
    my $root = Root2( $legLength->bstr(), 2, $modP );
    $AS->bmul( $root->bstr(), $modP );
    return $AS->bfround( -$P );
}

sub Eccentricity {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my $a    = Math::BigFloat->new( shift );
    my $b    = Math::BigFloat->new( shift );
    my $P    = shift || $DECIMALS;
    my $modP = modP( $P );
    my $root = Math::BigFloat->new();
    my $A    = $a->copy();
    $a->bpow( 2 );
    $b->bpow( 2 );
    $a->bsub( $b->copy() )->babs();
    $root = SqrRoot( $a->bstr(), $modP );
    $root /= $A;
    return $root->bfround( -$P );
}

sub LatusRectum {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my $a    = shift;
    my $b    = shift;
    my $P    = shift || $DECIMALS;
    unless ( $a && $b ) { return undef }
    my $modP = modP( $P );
    my $result = Math::BigFloat->new( 2 );
    $result->bmul( $b ** 2, $modP )->bdiv( $a, $modP )->bfround( -$P );
    return $result;
}

sub EllipseArea {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my $a = shift;
    my $b = shift;
    my $P = shift || $DECIMALS;
    unless ( $a && $b ) { return undef }
    my $modP = modP( $P );
    my $area = Math::BigFloat->new( $a );
    $area->bmul( $b, $modP )->bmul( $PI->copy(), $modP )->bfround( -$P );
    return $area;
}

sub OrbitalVelocity {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    unless ( scalar @_ >= 3 ) { return undef }
    my $r    = Math::BigFloat->new( shift );
    my $a    = Math::BigFloat->new( shift );
    my $M    = Math::BigFloat->new( shift );
    my $P    = shift || $DECIMALS;
    my $modP = modP( $P );
    my $num = Math::BigFloat->new( 2 );
    $num->bmul( $_g_, $modP )->bmul( $M, $modP )->bmul( ( ( 1 / $r ) - ( 1 / ( 2 * $a ) ) ), $modP );
    my $x    = Math::BigFloat->bstr( $num );
    my $v    = SqrRoot( $x, $modP );
    $v /= 1000000;
    return $v->bfround( -$P );
}

sub sin {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my $x = shift;
    my $P = shift || $DECIMALS;
    return undef unless defined $x;
    my $num;
    if ( ref $x eq "Math::BigFloat" ) {
        $num = $x->copy();
    } else {
        $num = Math::BigFloat->new( $x );
    }
    my $sign = -1;
    my $power = 3;
    my $sin = Math::BigFloat->new();
    my $current = $num->copy();
    my $modP = modP( $P );
    my $factorial = Math::BigFloat->new( 6 );
    while ( $sin ne $current ) {
        $sin = $current->copy();
        my $numerator = $num->copy()->bpow( $power );
        my $denominator = $factorial;
        my $fraction = $numerator->bdiv( $denominator, $modP )->bmul( $sign );
        $current->badd( $fraction );
        $factorial->bmul( $power + 1 )->bmul( $power + 2 );
        $sign *= -1;
        $power += 2;
    }
    return $current->bfround( -$P );
}

sub cos {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my $x = shift;
    my $P = shift || $DECIMALS;
    return undef unless defined $x;
    my $num;
    if ( ref $x eq "Math::BigFloat" ) {
        $num = $x->copy();
    } else {
        $num = Math::BigFloat->new( $x );
    }
    my $sign = -1;
    my $power = 2;
    my $cos = Math::BigFloat->new();
    my $current = Math::BigFloat->new( 1 );
    my $modP = modP( $P );
    my $factorial = Math::BigFloat->new( 2 );
    while ( $cos ne $current ) {
        $cos = $current->copy();
        my $numerator = $num->copy()->bpow( $power );
        my $denominator = $factorial;
        my $fraction = $numerator->bdiv( $denominator, $modP )->bmul( $sign );
        $current->badd( $fraction );
        $factorial->bmul( $power + 1 )->bmul( $power + 2 );
        $sign *= -1;
        $power += 2;
    }
    return $current->bfround( -$P );
}

sub tan {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my $num = shift;
    my $P   = shift || $DECIMALS;
    my $modP = modP( $P );
    my $sin = &sin( $num, $modP );
    my $tan = Math::BigFloat->new();
    my $cos = &cos( $num, $modP );
    $tan = $sin / $cos;
    return $tan->bfround( -$P );
}

sub asin {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my $x = Math::BigFloat->new( shift );
    my $P = shift || $DECIMALS;
    my $modP = modP( $P );
    my $asin = $x->copy();
    my $i = 3;
    my $last = 0;
    while ( $last ne $asin ) {
        $last = $asin->copy();
        my $frac = $x->copy()->bpow( $i )->bdiv( $i, $modP );
        my $z = $i;
        while ( $z > 1 ) {
            my $n1 = --$z;
            my $n2 = --$z;
            $frac->bmul( $n2 / $n1, $modP );
        }
        $asin->badd( $frac );
        $i += 2;
    }
    return $asin->bfround( -$P );
}

sub acos {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my $x    = shift;
    my $P    = shift || $DECIMALS;
    return undef unless defined $x;
    if ( $x == 0 ) {
        return $PI->copy()->bdiv( 2, $P );
    }
    my $num;
    if ( ref $x eq "Math::BigFloat" ) {
        $num = $x->copy();
    } else {
        $num = Math::BigFloat->new( $x );
    }
    my $modP = modP( $P );
    my $asin = asin( $num->bstr(), $modP );
    my $acos = $PI->copy()->bdiv( 2, $modP );
    $acos->bsub( $asin->bstr() )->bfround( -$P );
    return $acos;
}

sub atan {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my $x = shift;
    my $P = shift || $DECIMALS;
    return undef unless defined $x;
    my ( $num, $current, $numerator, $fraction, $atan );
    if ( ref( $x ) eq "Math::BigFloat" ) {
        $num = $x->copy();
        $current = $x->copy();
    } else {
        $num = Math::BigFloat->new( $x );
        $current = Math::BigFloat->new( $x );
    }
    my $sign = -1;
    my $power = 3;
    my $modP = modP( $P );
    my $atan2 = 0;
    while ( $atan ne $current ) {
        $atan = "$current";
        $numerator = $num->copy()->bpow( $power );
        $fraction = $numerator->bdiv( $power, $modP )->bmul( $sign );
        $current->badd( $fraction );
        $sign *= -1;
        $power += 2;
    }
    return $current->bfround( -$P );
}

sub sec {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my $num = shift;
    my $P   = shift || $DECIMALS;
    return undef unless defined $num;
    if ( ref $num eq "Math::BigFloat" ) {
        $num = $num->bstr();
    }
    my $modP = modP ( $P );
    my $cos = &cos( $num, $modP );
    return Inverse( $cos->bstr(), $P );
}

sub asec {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my $x    = shift;
    my $P    = shift || $DECIMALS;
    my $modP = modP( $P );
    return undef unless defined $x;
    my $num;
    if ( ref $x eq "Math::BigFloat" ) {
        $num = $x->copy();
    } else {
        $num = Math::BigFloat->new( $x );
    }
    my $inv = Inverse( $x, $modP );
    my $acos = acos( $inv->bstr(), $modP );
    return $acos->bfround( -$P );
}

sub csc {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my $num  = shift;
    my $P    = shift || $DECIMALS;
    my $modP = modP( $P );
    my $csc = Math::BigFloat->new( 1 );
    my $sin = &sin( $num, $modP );
    return Inverse( $sin->bstr(), $P );
}

sub acsc {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my $x = shift;
    my $P = shift || $DECIMALS;
    return undef unless defined $x;
    my $modP = modP( $P );
    my $inv = Inverse( $x, $modP );
    return asin( $inv->bstr(), $P );
}

sub exsec {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my $x = shift;
    return undef unless defined $x;
    my $P = shift || $DECIMALS;
    my $modP = modP( $P );
    my $cos = &cos( $x, $modP );
    my $inv = Inverse( $cos->bstr(), $P );
    $inv->bdec();
    return $inv;
}

sub cot {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my $num = shift;
    my $P   = shift || $DECIMALS;
    return undef unless defined $num;
    my $modP = modP ( $P );
    my $cos = &cos( $num, $modP );
    my $sin = &sin( $num, $modP );
    my $cot = Math::BigFloat->new();
    $cot = $cos / $sin;
    return $cot->bfround( -$P );
}

sub acot {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my $x = shift;
    my $P = shift || $DECIMALS;
    return undef unless defined $x;
    my $modP = modP( $P );
    my $num  = Math::BigFloat->new( $x );
    my $atan = atan( $num, $modP );
    my $acot = $PI->copy()->bdiv( 2, $modP )->bsub( $atan->bstr() );
    return $acot->bfround( -$P );
}

sub vers {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my $num = shift;
    my $P   = shift || $DECIMALS;
    return undef unless defined $num;
    my $modP = modP( $P );
    my $vers = Math::BigFloat->new( 1 );
    my $cos = &cos( $num, $modP );
    $vers->bsub( $cos->bstr() );
    return $vers->bfround( -$P );
}

sub covers {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my $num = shift;
    my $P   = shift || $DECIMALS;
    return undef unless defined $num;
    my $modP   = modP( $P );
    my $covers = Math::BigFloat->new( 1 );
    my $sin    = &sin( $num, $modP );
    $covers->bsub( $sin->bstr() );
    return $covers->bfround( -$P );
}

sub hav {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my $num = shift;
    my $P   = shift || $DECIMALS;
    return undef unless defined $num;
    my $modP = modP( $P );
    my $vers = vers( $num, $modP );
    my $hav = $vers / 2;
    return $hav->bfround( -$P );
}

sub Commas {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    local $_ = shift;
    1 while s/^(-?\d+)(\d{3})/$1,$2/;
    return $_;
}

sub SqrRoot {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my $num = abs( shift );
    my $P   = shift || $DECIMALS;
    return Root( $num, 2, $P );    
}

sub sqrt {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my $num = abs( shift );
    my $P   = shift || $DECIMALS;
    return Root( $num, 2, $P );
}

sub Root {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my $num  = shift;
    my $root = shift;
    my $P    = shift || $DECIMALS;
    my $modP = modP( $P );
    if ( $num < 0 ) { return undef }
    if ( $root == 0 ) { return 1 }
    my $Num;
    if ( ref( $num ) eq "Math::BigFloat" ) {
        $Num = $num->copy();
    } else {
        $Num = Math::BigFloat->new( $num );
    }
    my $Root    = Math::BigFloat->new( $root );
    my $current = Math::BigFloat->new()->bfround( -$modP );
    my $guess   = Math::BigFloat->new( $num ** ( 1 / $root ) )->bfround( -$modP );
    my $t       = Math::BigFloat->new( $guess ** ( $root - 1 ) );
    {
        $current = $guess - ( $guess * $t - $Num ) / ( $Root * $t );
        $guess =~ /^(.{$P})/;
        my $x = $1;
        $current =~ /^(.{$P})/;
        my $y = $1;
        last unless $x cmp $y;
        $t     = $current ** ( $root - 1 );
        $guess = $current->copy();
        redo;
    }
    return $current->bfround( -$P );
}

sub Root2 {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my ( $n, $r, $p ) = @_;
    $p++;
    my $log = Ln( $n, $p ) / $r;
    Exp( $log, $p )->bfround( 1 - $p );
}

sub PICONST {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my $max_pi = $PI->length() - 1;
    my $P      = shift || $DECIMALS;
    if ( $P <= $max_pi ) {
        return $max_piconst->copy()->bfround( -$P );
    }
    my $x = Root( 2, 2, $P );
    my $Pi = 2 + $x;
    my $y = Root2( $x, 2, $P );
    $x = $y;
    {
        $x = 0.5 * ( $x + 1 / $x );
        my $NewPi = $Pi * ( $x + 1 ) / ( $y + 1 );
        last unless $Pi cmp $NewPi;
        $Pi = $NewPi;
        $x = Root2( $x, 2, $P );
        $y = ( $y * $x + 1 / $x ) / ( $y + 1 );
        redo;
    }
    return $Pi;
}

sub ECONST {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my $max_p = $_e_->length() - 1;
    my $P     = shift || $DECIMALS;
    if ( $P <= $max_p ) {
        return $max_econst->copy()->bfround( -$P );
    }
    my $Eps = 0.5 * Math::BigFloat->new( "1" . "0" x $P );
    my $N   = Math::BigFloat->new( "1" )->bfround( -$P );
    my $D   = Math::BigFloat->new( "1" )->bfround( -$P );
    my $J   = Math::BigFloat->new( "1" )->bfround( -$P );
    {
        $N = $J * $N + 1;
        $D = $J * $D;
        if ( $D >= $Eps ) {
            $max_p = $P;
            return $max_econst = $N / $D;
        }
        $J++;
        redo;
    }
}

sub exp {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my $num = shift;
    my $P   = shift || $DECIMALS;
    return undef unless defined $num;
    return Exp( $num, $P );
}

sub Exp {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my $x = shift;
    my $P = shift || $DECIMALS;
    my $X;
    if ( ref( $x ) eq "Math::BigFloat" ) {
        $X = $x->copy();
    } else {
        $X = Math::BigFloat->new( $x );
    }
    my $modP = modP( $P );
    $X->bfround( -$modP );
    my $Y = $X->copy->bfround( 0 );
    $Y->bfround( -$modP );
    $Y += ( 0 cmp $X ) if abs( $X - $Y ) > 0.5;
    $X = $X - $Y;
    my $Sum  = Math::BigFloat->new( "1" )->bfround( -$modP );
    my $Term = Math::BigFloat->new( "1" )->bfround( -$modP );
    my $J    = Math::BigFloat->new( "1" )->bfround( -$modP );
    {
        $Term *= $X / $J;
        my $NewSum = $Sum + $Term;
        last unless $NewSum cmp $Sum;
        $Sum = $NewSum;
        $J++;
        redo;
    }
    return $Sum->bfround(-$P) unless $Y cmp 0;
    my $E   = ECONST( $modP );
    my $E_Y = 1;
    $E_Y *= $E for 1 .. $Y;
    $E_Y *= $Sum;
    return $E_Y->bfround(-$P);
}

sub log {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my $num = abs( shift );
    my $P   = shift || $DECIMALS;
    return undef unless defined $num;
    return Ln( $num, $P );
}

sub Ln {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my $X = shift;
    my $P = shift || $DECIMALS;
    $X = ref( $X ) ? $X->copy : Math::BigFloat->new( $X );
    my $modP = sprintf( "%.0f", $P * 1.1 );
    $X->bfround( -$modP );
    return -Ln( 1 / $X, $P ) if $X < 1;
    my $M = 0;
    ++$M until ( 2 ** $M ) > $X;
    $M--;
    my $Z        = $X / ( 2 ** $M );
    my $Zeta     = ( 1 - $Z ) / ( 1 + $Z );
    my $N        = $Zeta;
    my $Ln       = $Zeta;
    my $Zetasup2 = $Zeta * $Zeta;
    my $J        = 1;
    {
        $N = $N * $Zetasup2;
        my $NewLn = $Ln + $N / ( 2 * $J + 1 );
        unless ( $NewLn cmp $Ln ) {
            my $ans = $M * LN2P( $modP ) - 2 * $Ln;
            return $ans->bfround(-$P);
        }
        $Ln = $NewLn;
        $J++;
        redo;
    }
}

sub LN2P {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my $max_p = $max_ln2p->length() - 1;
    my $P     = shift || $DECIMALS;
    my $modP  = modP( $P );
    if ( $P <= $max_p ) {
        return $max_ln2p->copy->bfround( -$P );
    }
    my $one      = Math::BigFloat->new( "1" )->bfround( -$modP );
    my $N        = $one / 3;
    my $Ln       = $N->copy();
    my $Zetasup2 = $one / 9;
    my $J        = 1;
    {
        $N->bmul( $Zetasup2 );
        my $NewLn = $Ln + $N / ( 2 * $J + 1 );
        unless ( $NewLn cmp $Ln ) {
            $max_ln2p = $Ln * 2;
            return $max_ln2p->bfround(-$P);
        }
        $Ln = $NewLn;
        $J++;
        redo;
    }
}

sub PythagTriples {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my $s = shift;
    my $t = shift;
    my $P = shift || $DECIMALS;
    if ( $s <= 0 || $t <= 0 ) { return undef }
    my $x = Math::BigFloat->new( abs( $t ** 2 - $s ** 2 ) )->bfround( -$P );
    my $y = Math::BigFloat->new( 2 * $s * $t )->bfround( -$P );
    my $z = Math::BigFloat->new( $t ** 2 + $s ** 2 )->bfround( -$P );
    return $x, $y, $z;
}

sub PythagTriplesSeq {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my $s = shift;
    my $t = shift;
    my $P = shift || $DECIMALS;
    if ( $s <= 0 || $t <= 0 ) { return undef }
    my $x   = Math::BigFloat->new( $s ** 2 );
    my $y   = Math::BigFloat->new( $t ** 2 );
    my $sum = $x->copy()->badd( $y );
    return SqrRoot( Math::BigFloat->bstr( $sum ), $P );
}

sub SIS {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my $num  = shift || 1;
    my $nums = shift || 50;
    my $inc  = shift || 1;
    my @nums;
    push ( @nums, $num );
    my $next = Math::BigFloat->new( $num + 2 );
    my $sum  = Math::BigFloat->new( $num + $next );
    for ( 1 .. --$nums ) {
        $num = $next;
        push ( @nums, $next );
        $next = $sum + $inc;
        $sum += $next;
    }
    return @nums;
}

sub Inverse {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my $x = shift;
    my $P = shift || $DECIMALS;
    return undef unless defined $x;
    my $modP = modP( $P );
    my $num;
    if ( ref $x eq "Math::BigFloat" ) {
        $num = $x->copy();
    } else {
        $num = Math::BigFloat->new( $x );
    }
    my $inv = Math::BigFloat->new( 1 );
    $inv->bdiv( $num, $modP );
    return $inv->bfround( -$P );
}

sub modP {
    my $num = shift;
    return $num + 5;
}

sub CONSTANT {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my @const = @_;
    my $prec  = 0;
    my $temp;
    my @array;
    if ( $const[-1] =~ /^\d*$/ ) {
        $prec = pop @const;
    }
    foreach $_ ( @const ) {
        if ( /_gm_/i || /all/i ) {
            $temp = new Math::BigFloat "1.61803398874989484820458683436563811772030917980576286213544862270526046281890244970720720418939113748475408807538689175212663386222353693179318006076672635443338908659593958290563832266131992829026788067520876689250171169620703222104321626954862629631361443814975870122034080588795445474924618569536486444924104432077134494704956584678850987433944221254487706647809158846074998871240076521705751797883416625624940758906970400028121042762177111777805315317141011704666599146697987317613560067087480710131795236894275219484353056783002287856997829778347845878228911097625003026961561700250464338243776486102838312683303724292675263116533924731671112115881863851331620384005222165791286675294654906811317159934323597349498509040947621322298101726107059611645629909816290555208524790352406020172799747175342777592778625619432082750513121815628551222480939471234145170223735805772786160086883829523045926478780178899219902707769038953219681986151437803149974110692608867429622675756052317277752035361393621076738937645560606059216589466759551900400555908950229530942312482355212212415444006470340565734797663972394949946584578873039623090375033993856210242369025138680414577995698122445747178034173126453220416397232134044449487302315417676893752103068737880344170093954409627955898678723209512426893557309704509595684401755519881921802064052905518934947592600734852282101088194644544222318891319294689622002301443770269923007803085261180754519288770502109684249362713592518760777884665836150238913493333122310533923213624319263728910670503399282265263556209029798642472759772565508615487543574826471814145127000602389016207773224499435308899909501680328112194320481964387675863314798571911397815397807476150772211750826945863932045652098969855567814106968372884058746103378105444390943683583581381131168993855576975484149144534150912954070050194775486163075422641729394680367319805861833918328599130396072014455950449779212076124785645916160837059498786006970189409886400764436170933417270919143365013716";
            if ( $prec ) {
                $temp->bfround( -$prec );
            }
            if ( wantarray ) {
                push ( @array, $temp );
            }
        }
        if ( /_catalan_/i || /all/i ) {
            $temp = new Math::BigFloat "0.91596559417721901505460351493238411077414937428167213426649811962176301977625476947935651292611510624857442261919619957903589880332585905943159473748115840699533202877331946051903872747816408786590902470648415216300022872764094238825995774150881639747025248201156070764488380787337048990086477511322599713434074854075532307685653357680958352602193823239508007206803557610482357339423191498298361899770690364041808621794110191753274314997823397610551224779530324875371878665828082360570225594194818097535097113157126158042427236364398500173828759779765306837009298087388749561089365977194096872684444166804621624339864838916280448281506273022742073884311722182721904722558705319086857354234985394983099191159673884645086151524996242370437451777372351775440708538464401321748392999947572446199754961975870640074748707014909376788730458699798606448749746438720623851371239273630499850353922392878797906336440323547845358519277777872709060830319943013323167124761587097924554791190921262018548039639342434956537596739494354730014385180705051250748861328564129344959502298722983162894816461622573989476231819542006607188142759497559958983637303767533853381354503127681724011814072153468831683568168639327293677586673925839540618033387830687064901433486017298106992179956530958187157911553956036689036990493966753843775810493189955385516262196253316804016273752130120940604538795076053827123197467900882369178615573389124417223833938148120775994298491724397668575632718068808279982979378849432724934657607490543874819526813074437046294635892810276531705076547974494839948959477092788591195848724127866084088554597823812492260505610094584486698958576871611171786662336847409949385541321093755281815525881591502228244454441718609946588151766496078223678970519269711312571375454370124329673057246845015819313016087766215650957554679666786617082347682558133518681937745650014565261704096074688953930234791980600084245562175108423471736387879369577878440933792219894575340961647424554622478788002922914803690712";
            if ( $prec ) {
                $temp->bfround( -$prec );
            }
            if ( wantarray ) {
                push ( @array, $temp );
            }
        }
        if ( /_apery_/i || /all/i ) {
            $temp = new Math::BigFloat "1.20205690315959428539973816151144999076498629234049888179227155534183820578631309018645587360933525814619915779526071941849199599867328321377639683720790016145394178294936006671919157552224249424396156390966410329115909578096551465127991840510571525598801543710978110203982753256678760352233698494166181105701471577863949973752378527793703095602570185318279000307654710756304884332086971157374238079344503160762531771453544441183117818224971852635709182448998796203508335756172022603393785870328131267807990054177348691152537065623705744096622171290262732073236149224291304052855537234103307757779806424202430488281521000914602653822069627155202082274335001015294801198690117625951676366998171835575234880703719555742347294083595208861666202572853755813079282586487282173705566196898952662018776810629200817792338135876828426412432431480282173674506720693507626895304345939375032966363775750624733239923482883107733905276802007579843567937115050900502736604711400853350343646722485653151811776618109222791910224883968002666065687051906275973877353574444787753791641427381322569573196020187488474710469933656614008069303256185371886007271853594828847886245041855546408571556300712509027138634689374168266546657729261117182460363056604653004752217032651363910586988578842450413400076174727913718427741087508679050188965396356958643081961372990232749349702416226454339239292672783678655715558177739663771912814182246641268663452811055140131673253668418279295372660503415185270488028902683158334795920387559849886178670059637310157271720001143347673515418825525246632629720253866142593759334901124954451888445879883653237605006862164259284618801137166666350356560100251312752001243465381788522516645056739550573863152637659543028146224230177475011676844571496704880344021307302412787315402904251150919940878348620142801404071621446547887481775826042066673402505321077025830183813299386697331994584062329039605703190927264068388085608407473895683350520941514917330483633047714345825539212218204516560042779";
            if ( $prec ) {
                $temp->bfround( -$prec );
            }
            if ( wantarray ) {
                push ( @array, $temp );
            }
        }
        if ( /_gamma_/i || /all/i ) {
            $temp = new Math::BigFloat "0.57721566490153286060651209008240243104215933593992359880579380974513817815465490800204253092981070122661042345860326928047135164791203948800536606461037345976626826019171409439518699073089342082681115272480646074000944609116161372351563626398584332141045445255931180817233263931404751492309635212264793910054305740237382398192590888596562246640403865322573375012737199489715017633198800855368701197527793558011235088254024640367896574303325878962716603487225275031179009858629238810808962050809520067455082680224906319303106435436009045606431673108916223923423190040278230666282475597561157456466827358396496682688009413716435206727056861387351803685766804293903992265911164881521862119020073349724767061284456884146036064744615108373824011763115970464920405436675762580329560583963444735408889698752182450095288981177450041810756648904797158973756550829956482367512558077410478243365464613480082832289424563397700319507555405116866793330362135883160170752605749442210232264689088158360185921103264127646556897969599278787214257345380787716603498201211893231736410397999823581853335889687416623200928470782748962584090972449329340007986308871514443489019148224047176657926174820342428101040873335655351128574656826084318283564695216594139535628369271429378337337433379686429368401688003555383437291075008327921702577375368037141188793180192584269933204984701562366914646472808066790853122048683498800599411781499587969727029583663306226025115000498496743205991135161767514469471756389224373936066230391750756913421783083438469788717316008107601214614336979590782255534871391388706661385738263517698540450095680405658465359138468527276721930455900430554051676747620967652827322185928446094750362369908488472423752534464421059769032210076173483219811625852956410683745061833659140846327500871722721667257557546723325255507410472504211384839027461378721484740738636819445610096494307626397264106526101612141759589572570377325729026542963991795591864852272592134741602693673095062700415514589022024205056";
            if ( $prec ) {
                $temp->bfround( -$prec );
            }
            if ( wantarray ) {
                push ( @array, $temp );
            }
        }
        if ( /_khintchine_/i || /all/i ) {
            $temp = new Math::BigFloat "2.68545200106530644530971483548179569382038229399446295305115234555721885953715200280114117493184769799515346590528809008289767771641096305179253348325966838185231542133211949962603932852204481940961806866416642893084778806203607370535010336726335772890499042707027234517026252370235458106863185010323746558037750264425248528694682341899491573066189872079941372355000579357366989339508790212446420752897414591476930184490506017934993852254704042033779856398310157090222339100002207725096513324604444391916914608596823482128324622829271012690697418234847767545734898625420339266235186208677813665096965831469952718374480540121953666660496482698908275481152547211773303196759473837193935781060592304018907113496246737068412217946810740608918276695667117166837405904739368809534504899970471763904513432323771510321965150382469888832487093539946960826478181205663494671257843666457974097784836620497777486827656970871631929385128993141995186116737926546205635059513857137616971268722998053276732787105137639563719023145289003058136910904799672757571385043565050641590820999623402779053834180985121278529455415101923273972716796875156245586879771758718269365955450251304196818650938031303858435298686363516207327699768066589087224447928200866225489913933297068356193419225233102502064171141533503247429916507784663858387916406031641983699585984006546488792260661608729245292500798046966253372984581955631152133430603971500916257685064406302588048429495308259622428230270523401977496361785043061562923047970063433750838442657870812777765055245804574026584834104343691031824570657550964215122825303405704026824079955791184653756937399558705407245503084329065125986768185602850521404175676201486584618506998513595754222651824007565424310843506639303023675791283864525364442268496173451042322285580615818211343332191663663651426916459806509174002240402290641026530659304514091234316906333539039761913861815498584776177231773745183069689797687961364339064741256229235947371959033823110561543639353830741004542531";
            if ( $prec ) {
                $temp->bfround( -$prec );
            }
            if ( wantarray ) {
                push ( @array, $temp );
            }
        }
        if ( /_landau_/i || /_ramanujan_/i || /_lr_/i || /all/i ) {
            $temp = new Math::BigFloat "0.76422365358922066299069873125009232811679054139340951472168667374961464165873285883840150501313123372193726912079259263418742064678084323063315434629380531605171169636177508819961243824994277683469051623513921871962056905329564467041917634977065956990571293866028938589982961051662960890991779298360729736972006403169851286365173473921065768550978681981674707359066921830288751501689624646710918081710618090086517493799082420450570666204898612757713333895484325083035682950407721597524121430942470953115765559404064229125772724071563491218723272555640889999512705135849728552347645942418505999635800934732669411548076911671455813028066898593167493626295259560163215843892463887558347193993864581698751045893518777945872755226448709943505595943671299977780669880564555921300690852242867691102264527531455816088116296997029876937094388422089495290791626363527791432286156863284215944899347183748322904155863814951281527102068249218645827978145098870379211809629840943604891233924014852514327407923660178532707078811584944045092539519718157085780907690772192962552262890529967200510669638584207655081660527132551761150093619010182152039541621744474356571314026496051480322439134457528009739604967190734667398621127034770623094786463721777245551191609693349580116501538146897732947400254272699518373881294004390465050310091210361980535760952228835847669743267507757379848939356645406017251962513826671863828822629657399438626453078913514555113206475947913245582423662405126070382560901984614575152951511943211356814416716008974384391847402590826495013602834007260634108659796382596784136373377680857831279147106417370573337040146024737648200768231118490558678994106995743922457089666910491534089500139419890965785853368531985664042350494746329804481593573838687414276915611134778612290893976432134279879206472381493290546264824907766030881348705331723336407298994245656611424036824812873959790915799781062723446426357233234127834780836022424212901203199698485951429216878840715626887034517436895639117073";
            if ( $prec ) {
                $temp->bfround( -$prec );
            }
            if ( wantarray ) {
                push ( @array, $temp );
            }
        }
        if ( /_sierpinski_/i || /all/i ) {
            $temp = new Math::BigFloat "2.5849817595792532170658935873831711600880516518526309173215449879719320440011571202111177245270642830313439675271584928060821923187897872299047382419051407714877706637709789429909195090538916174018888831788039474837941321858645411399643090785375197001772338459009456944053756794492374579585597585179674255629788277342303908244843480262486476177584815605758512072553110971230816071780849788881500097806833030977613625019242141160511588550990118827059119218516656116658218146525723473922090837893539685181949438885982596384972943476477372870062514541167941067265109122200895264359146879706881090332595323182513862833772115297045105929773651123477119322088137378396355981597690986669776205753580929932151604999024815911781450614362312734398131562638214155851981996626439748302199986452462457953855125313088680611106070915380230497079775582427852984168946632924118537731025052638887185848026204906420983889401089245443403362540129958473807838153959208083537401553970775472153329227768035176719828981294382970877918341439096416723782335709603207108445520524820489725953913958704083992677439523357417468867744155305621034247542053834049067381062651986166749473771332141368588137842121600803261051984625149759697256509652152510827678630218450123284235823215983358532186222762388342128395782679202593945375516184778819579281898007193722908635995686666472901738758059961533111087477134416091651746860298589917405489412578156737071439005466554727980569541597398523605309831919658877736650415899607456983010590346999086310281901369036616807688073485295874875200896192730898004336728426431758229969326891997729365727971979849493629766039927445616318901564033213832906150701871783495293008326554891249827853248516958090952881854747420204575686195783951958051727205868237631974666042360351571383265906332448659953586584188803129625125027777547500955928437209118570584106256159701299968613543163628083412230815949199322528466660157369540251616007609659383652145974190555337555264511348670765096655113592156822083955";
            if ( $prec ) {
                $temp->bfround( -$prec );
            }
            if ( wantarray ) {
                push ( @array, $temp );
            }
        }
        if ( /_wilbraham_/i || /_gibbs_/i || /all/i ) {
            $temp = new Math::BigFloat "1.8519370519824661703610533701579913633458097289811549098047837818769818901663483585327103365029547577016843616480071570093724507999019639342272322414165036365074788027757760407005425387045947037548070012549126196000327078575312602462781280151598692712625156658037819170657049819111714215383017286869095002766891969837835648786933759294319175361858839873281361537111741600533650285988928906414670095488877382247112955736673406636533206353917604135172039112403028911351451318386134929257744182407526476030905279207782148560221871814904254471501463635842777947117746613775605839980813601589774035700341407559120370214113987005974964457642432794571720297914619514587500552129836800839402275440787337189077600233378591748197346154415354013755202065349536370774797232235307627711101354680926841172462714308267187960091741576168508046447756294559627846381809450570206315108346086296761158384244642331395026518568824439952885040681806714182600926258083237153223244690004091924289785349238396416174935955727240494968269552946845809079249430987481637553106432748666108251208300982355329789484892215432004091308695606679907614565980645118075299785348720969353909946887244982337583293642008796934457410799803453503483850708482981091242218216243859534562275020112435860924659080184472456129920697558489165392134942490568469061049118625847278188759772510374005405482372866324572279022748900193843433072546840353737116696380141809972845395860023313759602450865523234036167185219941330755467527227101818708316522432071143111039033646408977079116322065177143217096902088039791122531643152182505080070064980216107233022936897562281947118346305483027762905687068773859998729098422829244431023193577879027813710683659782342659876790900757742205098230554650080486761301518847811425034427156656362916286133872434789956033111453170457363680159688876278436595524346040307734465776554486790217538281709048389723416938426939063740559103208012841498333933171221169378991591489862913304490585047568388032591042048255902683612038";
            if ( $prec ) {
                $temp->bfround( -$prec );
            }
            if ( wantarray ) {
                push ( @array, $temp );
            }
        }
        if ( /_sqrt2_/i || /all/i ) {
            $temp = new Math::BigFloat "1.41421356237309504880168872420969807856967187537694807317667973799073247846210703885038753432764157273501384623091229702492483605585073721264412149709993583141322266592750559275579995050115278206057147010955997160597027453459686201472851741864088919860955232923048430871432145083976260362799525140798968725339654633180882964062061525835239505474575028775996172983557522033753185701135437460340849884716038689997069900481503054402779031645424782306849293691862158057846311159666871301301561856898723723528850926486124949771542183342042856860601468247207714358548741556570696776537202264854470158588016207584749226572260020855844665214583988939443709265918003113882464681570826301005948587040031864803421948972782906410450726368813137398552561173220402450912277002269411275736272804957381089675040183698683684507257993647290607629969413804756548237289971803268024744206292691248590521810044598421505911202494413417285314781058036033710773091828693147101711116839165817268894197587165821521282295184884720896946338628915628827659526351405422676532396946175112916024087155101351504553812875600526314680171274026539694702403005174953188629256313851881634780015693691768818523786840522878376293892143006558695686859645951555016447245098368960368873231143894155766510408839142923381132060524336294853170499157717562285497414389991880217624309652065642118273167262575395947172559346372386322614827426222086711558395999265211762526989175409881593486400834570851814722318142040704265090565323333984364578657967965192672923998753666172159825788602633636178274959942194037777536814262177387991945513972312740668983299898953867288228563786977496625199665835257761989393228453447356947949629521688914854925389047558288345260965240965428893945386466257449275563819644103169798330618520193793849400571563337205480685405758679996701213722394758214263065851322174088323829472876173936474678374319600015921888073478576172522118674904249773669292073110963697216089337086611567345853348332952546758516447107578486024636008";
            if ( $prec ) {
                $temp->bfround( -$prec );
            }
            if ( wantarray ) {
                push ( @array, $temp );
            }
        }
        if ( /_sqrt3_/i || /all/i ) {
            $temp = new Math::BigFloat "1.73205080756887729352744634150587236694280525381038062805580697945193301690880003708114618675724857567562614141540670302996994509499895247881165551209437364852809323190230558206797482010108467492326501531234326690332288665067225466892183797122704713166036786158801904998653737985938946765034750657605075661834812960610094760218719032508314582952395983299778982450828871446383291734722416398458785539766795806381835366611084317378089437831610208830552490167002352071114428869599095636579708716849807289949329648428302078640860398873869753758231731783139599298300783870287705391336956331210370726401924910676823119928837564114142201674275210237299427083105989845947598766428889779614783795839022885485290357603385280806438197234466105968972287286526415382266469842002119548415527844118128653450703519165001668929441548084607127714399976292683462957743836189511012714863874697654598245178855097537901388066496191196222295711055524292372319219773826256163146884203285371668293864961191704973883639549593814575767185337363312591089965542462483478719760523599776919232357022030530284038591541497107242955920670620250952017596318587276635997528366343108015066585371064732853862592226058222051040368027029750479872807946165810041705268194001909573346217594389367024932042269103436981246372011118526108426891029972031120210006350717637458240520384755519727993379761490610789498554422332600401885130363156114488684728158928816324518726506664538487759916257664287211124084206801676351710010294318071551519096164246090703940812921690351749296136400413967043104125363232703092257732796029237659774553709546911574214042423078199232761740190642451245487751686269610533369421621360539460424565414012853300781363344985673640670397734222981196104292553450160140594047954715453454840727173765626236654916664023300601326574407010783685846845231316046775448050040224063991197036221860292023886715071101716940029686875966350004089531621423342522795683406701347018590202836071676214774349344956359580808213044258646946852261";
            if ( $prec ) {
                $temp->bfround( -$prec );
            }
            if ( wantarray ) {
                push ( @array, $temp );
            }
        }
        if ( /_sqrt5_/i || /all/i ) {
            $temp = new Math::BigFloat "2.23606797749978969640917366873127623544061835961152572427089724541052092563780489941441440837878227496950817615077378350425326772444707386358636012153345270886677817319187916581127664532263985658053576135041753378500342339241406444208643253909725259262722887629951740244068161177590890949849237139072972889848208864154268989409913169357701974867888442508975413295618317692149997742480153043411503595766833251249881517813940800056242085524354223555610630634282023409333198293395974635227120134174961420263590473788550438968706113566004575713995659556695691756457822195250006053923123400500928676487552972205676625366607448585350526233067849463342224231763727702663240768010444331582573350589309813622634319868647194698997018081895242644596203452214119223291259819632581110417049580704812040345599494350685555185557251238864165501026243631257102444961878942468290340447471611545572320173767659046091852957560357798439805415538077906439363972302875606299948221385217734859245351512104634555504070722787242153477875291121212118433178933519103800801111817900459061884624964710424424830888012940681131469595327944789899893169157746079246180750067987712420484738050277360829155991396244891494356068346252906440832794464268088898974604630835353787504206137475760688340187908819255911797357446419024853787114619409019191368803511039763843604128105811037869895185201469704564202176389289088444637782638589379244004602887540539846015606170522361509038577541004219368498725427185037521555769331672300477826986666244621067846427248638527457821341006798564530527112418059597284945519545131017230975087149652943628290254001204778032415546448998870617799819003360656224388640963928775351726629597143822795630795614952301544423501653891727864091304197939711135628213936745768117492206756210888781887367167162762262337987711153950968298289068301825908140100389550972326150845283458789360734639611723667836657198260792144028911900899558424152249571291832321674118997572013940378819772801528872341866834541838286730027432";
            if ( $prec ) {
                $temp->bfround( -$prec );
            }
            if ( wantarray ) {
                push ( @array, $temp );
            }
        }
    }
    return wantarray ? @array : $temp;
}

sub Bernoulli {
    shift if UNIVERSAL::isa( $_[ 0 ], __PACKAGE__ );
    my $n = shift || return undef;
    if ( $n > 498 || $n < 2 || $n % 2 ) { return undef }
    my @bernoulli = (
        "1","6",
        "-1","30",
        "1","42",
        "-1","30",
        "5","66",
        "-691","2730",
        "7","6",
        "-3617","510",
        "43867","798",
        "-174611","330",
        "854513","138",
        "-236364091","2730",
        "8553103","6",
        "-23749461029","870",
        "8615841276005","14322",
        "-7709321041217","510",
        "2577687858367","6",
        "-26315271553053477373","1919190",
        "2929993913841559","6",
        "-261082718496449122051","13530",
        "1520097643918070802691","1806",
        "-27833269579301024235023","690",
        "596451111593912163277961","282",
        "-5609403368997817686249127547","46410",
        "495057205241079648212477525","66",
        "-801165718135489957347924991853","1590",
        "29149963634884862421418123812691","798",
        "-2479392929313226753685415739663229","870",
        "84483613348880041862046775994036021","354",
        "-1215233140483755572040304994079820246041491","56786730",
        "12300585434086858541953039857403386151","6",
        "-106783830147866529886385444979142647942017","510",
        "1472600022126335654051619428551932342241899101","64722",
        "-78773130858718728141909149208474606244347001","30",
        "1505381347333367003803076567377857208511438160235","4686",
        "-5827954961669944110438277244641067365282488301844260429","140100870",
        "34152417289221168014330073731472635186688307783087","6",
        "-24655088825935372707687196040585199904365267828865801","30",
        "414846365575400828295179035549542073492199375372400483487","3318",
        "-4603784299479457646935574969019046849794257872751288919656867","230010",
        "1677014149185145836823154509786269900207736027570253414881613","498",
        "-2024576195935290360231131160111731009989917391198090877281083932477","3404310",
        "660714619417678653573847847426261496277830686653388931761996983","6",
        "-1311426488674017507995511424019311843345750275572028644296919890574047","61410",
        "1179057279021082799884123351249215083775254949669647116231545215727922535","272118",
        "-1295585948207537527989427828538576749659341483719435143023316326829946247","1410",
        "1220813806579744469607301679413201203958508415202696621436215105284649447","6",
        "-211600449597266513097597728109824233673043954389060234150638733420050668349987259","4501770",
        "67908260672905495624051117546403605607342195728504487509073961249992947058239","6",
        "-94598037819122125295227433069493721872702841533066936133385696204311395415197247711","33330",
        "3204019410860907078243020782116241775491817197152717450679002501086861530836678158791","4326",
        "-319533631363830011287103352796174274671189606078272738327103470162849568365549721224053","1590",
        "36373903172617414408151820151593427169231298640581690038930816378281879873386202346572901","642",
        "-3469342247847828789552088659323852541399766785760491146870005891371501266319724897592306597338057","209191710",
        "7645992940484742892248134246724347500528752413412307906683593870759797606269585779977930217515","1518",
        "-2650879602155099713352597214685162014443151499192509896451788427680966756514875515366781203552600109","1671270",
        "21737832319369163333310761086652991475721156679090831360806110114933605484234593650904188618562649","42",
        "-309553916571842976912513458033841416869004128064329844245504045721008957524571968271388199595754752259","1770",
        "366963119969713111534947151585585006684606361080699204301059440676414485045806461889371776354517095799","6",
        "-51507486535079109061843996857849983274095170353262675213092869167199297474922985358811329367077682677803282070131","2328255930",
        "49633666079262581912532637475990757438722790311060139770309311793150683214100431329033113678098037968564431","6",
        "-95876775334247128750774903107542444620578830013297336819553512729358593354435944413631943610268472689094609001","30",
        "5556330281949274850616324408918951380525567307126747246796782304333594286400508981287241419934529638692081513802696639","4357878",
        "-267754707742548082886954405585282394779291459592551740629978686063357792734863530145362663093519862048495908453718017","510",
        "1928215175136130915645299522271596435307611010164728458783733020528548622403504078595174411693893882739334735142562418015","8646",
        "-410951945846993378209020486523571938123258077870477502433469747962650070754704863812646392801863686694106805747335370312946831","4206930",
        "264590171870717725633635737248879015151254525593168688411918554840667765591690540727987316391252434348664694639349484190167","6",
        "-84290226343367405131287578060366193649336612397547435767189206912230442242628212786558235455817749737691517685781164837036649737","4110",
        "2694866548990880936043851683724113040849078494664282483862150893060478501559546243423633375693325757795709438325907154973590288136429","274386",
        "-3289490986435898803930699548851884006880537476931130981307467085162504802973618096693859598125274741604181467826651144393874696601946049","679470",
        "14731853280888589565870080442453214239804217023990642676194878997407546061581643106569966189211748270209483494554402556608073385149191","6",
        "-3050244698373607565035155836901726357405007104256566761884191852434851033744761276392695669329626855965183503295793517411526056244431024612640493","2381714790",
        "4120570026280114871526113315907864026165545608808541153973817680034790262683524284855810008621905238290240143481403022987037271683989824863","6",
        "-1691737145614018979865561095112166189607682852147301400816480675916957871178648433284821493606361235973346584667336181793937950344828557898347149","4470",
        "463365579389162741443284425811806264982233725425295799852299807325379315501572305760030594769688296308375193913787703707693010224101613904227979066275","2162622",
        "-3737018141155108502105892888491282165837489531488932951768507127182409731328472084456653639812530140212355374618917309552824925858430886313795805601","30",
        "10259718682038021051027794238379184461025738652460569233992776489750881337506863808448685054322627708245455888249006715516690124228801409697850408284121","138",
        "-81718086083262628510756459753673452313595710396116467582152090596092548699138346942995509488284650803976836337164670494733866559829768848363506624334818961419869","1794590070",
        "171672676901153210072183083506103395137513922274029564150500135265308148197358551999205867870374013289728260984269623579880772408522396975250682773558018919","6",
        "-4240860794203310376065563492361156949989398087086373214710625778458441940477839981850928830420029285687066701804645453159767402961229305942765784122421197736180867","230010",
        "1584451495144416428390934243279426140836596476080786316960222380784239380974799880364363647978168634590418215854419793716549388865905348534375629928732008786233507729","130074",
        "-20538064609143216265571979586692646837805331023148645068133372383930344948316600591203926388540940814833173322793804325084945094828524860626092013547281335356200073083","2490",
        "5734032969370860921631095311392645731505222358555208498573088911303001784652122964703205752709194193095246308611264121678834250704468082648313788124754168671815815821441","1002",
        "-13844828515176396081238346585063517228531109156984345249260453934317772754836791258987516540324983611569758649525983347408589045734176589270143058509026392246407576578281097477","3404310",
        "195334207626637530414976779238462234481410337350988427215139995707346979124686918267688171536352650572535330369818176979951931477427594872783018749894699157917782460035894085","66",
        "-11443702211333328447187179942991846613008046506032421731755258148665287832264931024781365962633301701773088470841621804328201008020129996955549467573217659587609679405537739509973","5190",
        "4166161554662042831884959593250717297395614318182561412048180684077407803317591270831194619293832107482426945655143357909807251852859279483176373435697607639883085093246499347128331","2478",
        "-1369347910486705707645621362512824332220360774476594348356938715366608044588614657557436131706543948464159947970464346070253278291989696390096800799614617317655510118710460076077638883999","1043970",
        "1124251816617941290026484851206299982774720467712867275292043701618829826708395745459654170718363182143418314514085426692857018428614935412736063946853033094328968069656979232446257101741","1074",
        "-6173136454016248924640522272263470960199559328290655337530202055853397791747341312347030141906500993752700612233695954532816018207721731818225290076670213481102834647254685911917265818955932383093313","7225713885390",
        "4277269279349192541137304400628629348327468135828402291661683018622451659989595510712915810436238721139546963558655260384328988773219688091443529626531335687951612545946030357929306651006711","6",
        "-857321333523056180131194437347933216431403305730705359015465649285681432317514010686029079324479659634642384809061711319481020030715989009140595170556956196762318625529645723516532076273012244047","1410",
        "22258646098436968050639602221816385181596567918515338169946670500599612225742487595012775838387331550474751212260636163500086787417640903770807353228157478339547041472679880890292167353534100797481","42",
        "-14158277750623758793309386870401397333112823632717478051426522029712001260747920789473711562165031101665618225654329210473605281619696918061316240634857984019071572591940586875558943580878119388321001","30",
        "5411555842544259796131885546196787277987837486638756184149141588783989774511509608733429067517383750706299486822702171672522203106730993581242777825864203487238429479957280273093904025319950569633979493395","12606",
        "-346465752997582699690191405750952366871923192340955593486485715370392154894102000406980162521728492501917598012711402163530166516991115122131398542029056286959857727373568402417020319761912636411646719477318166587","868841610",
        "2269186825161532962833665086968359967389321429297588337232986752409765414223476696863199759981611817660735753831323900456495253961837175924312108872915089534970310604331636484174526399721365966337809334021247","6",
        "-62753135110461193672553106699893713603153054153311895305590639107017824640241378480484625554578576142115835788960865534532214560982925549798683762705231316611716668749347221458005671217067357943416524984438771831113","171390",
        "88527914861348004968400581010530565220544526400339548429439843908721196349579494069282285662653465989920237253162555666526385826449862863083834096823053048072002986184254693991336699593468906111158296442729034119206322233","244713882",
        "-498384049428333414764928632140399662108495887457206674968055822617263669621523687568865802302210999132601412697613279391058654527145340515840099290478026350382802884371712359337984274122861159800280019110197888555893671151","1366530",
        "2250525326187264545900714460628885135841050444551247116222631411681549780530233516069957534394574922579290608180427520318235621123686109474343887857944611842438698399885295153935574958275021715116120056995036417537079471","6",
        "-110636644250856903590976481422794879200517231299540994715372334521128669716264196333811025709747746193210786820114369025849897345722531098042760530922656878891556664782168465095563132092311332073097630676251482491663634626858373","281190",
        "2525292668891404920279427026668969389456388249389889339455604316691573384284678293620100066924361693666444722338743839198221347931651916807651198800935942493038194104759967208073711284671045255047521429204396148980705984836743","6",
        "-12407390668433023412711473483696990726334795896412761472587854072142800403373577087021298541061094633377354326966623278849423631924808044397822651135905640812063181221280972334965193338438214107578486417026806166184210160001817890901","27030",
        "4708181368529492614110644197951837317202610608341257204206693195241245204360822875910613010433572133227831741097261618833206537519198885812254347219150482005543422997225440204041473518187636442241332621804718967775203938403965710395632762155","9225988926",
        "-1856110669947388268389361040689764027464160460436671923253131176853224087741924378432403442710398247642246902212818749685974336641529240178398124235555437625251481044526024910356131819016670047949661636539964662370375622630863327168696307","3210",
        "4005748930070152861935826766476856180706477227448622268042052745245798242539770546339789899546160341590069109467023517085578618986055969187202731878271685432460708841118506310943865592568791360294244451765746911808994482063783730693703607","6",
        "-11993122770108617858536443322964878003618156069559794803117809279608039120818829088000103355036592864877954563564831932363414886811786054601318517206937549605059298307895591515771731031691422489377098686236263367916404512751010916862894129855138281961","15270994830",
        "5646413644023523531472659729552574911763686780871700375627426663366507837122353997075891736706811337698248660838754243486778190331522785903661556458651175061469825204821206611273990250663647381261360659950519735730925202117606150672170127523599","6",
        "-8717064809960074651332043679796544474420053189621803209941154764877242575579617540185166306094852502223738126111951612525627910517501081576202264770178546608710937474005742969950212404955732473198451623024108934373488641161751158901712323446768306053","7590",
        "13368053158552172665210852539359893340369870651951497976111882891296650008003955172160792457229376320993686817755409436399268291095350295968657381088168219133490277914269064723832062615431730061224649980566693258603099340996988542301914519271322675688591","9366",
        "-3018240015081392087620978688311925380399983229633120268872695911807562982111154053235820050168829922189401964755775948260724401542319799566237745986245598102255191922935742610508280966462644022540839619861091049093129359799053781543195492373882916779852781709","1671270",
        "3168221108903401670436878558215734893322849540781208738796672473984272484396317849596978630272031342024194689871467916186898192771267438982228710525079886956295106197431401217357893460897221381410667385636049264583380749631776691121592016493432807733153743581","1362",
        "-1906502909997888166123201923177385833567729039151413143876271870599057704445939156075718972624235764657102074902610737729027517674632609562387841658709266014329005407533521950744449109807215808770201247724932231495252981632908042371307965561986133763291349835081839","625170",
        "12620737044909818561832856090355555624016887319605261762997689571062646649745107532482632213152948299491122977690702642386377706799989565320538433072623252159464115918057294711396625436506736041542403370025258477205101808063594056759977272469883621048184279331863155","3102",
        "-2277782962749544647786193093844710000584561145527861043594866852071596440076587235747852022645695523676561694856919437156369375152041285055935622032497285897151359345040171955786899011718891877065760345722163063921177723102631428767500963315657655779698470644544064472947","412410",
        "480867224771001697116513683699011649496855159878152931805742068517626950204279499281932407966997815888727039144001177194783700618900740782637516562256421883686495287564849123342843286211825800198337962453448529082007644439295666002669973893196613894216505936316966183107269","63042",
        "-321467133590936589398380572003196190798000628347443663674019204361034039315014370869884972981404460888272855773233080186485230316544246541168364468343631969225480324799028067015621769939718443419712110857965409179947456994970687005134042835903494172569465751671057323145801","30",
        "21954828084819816230623427376391154946628510524415478471365831649487269438565442138452375719697629394886161086199009071745032148355699097673730377547354631757000924688032674454208386076360699273002129330161098228962653466112032300056534380609136268347425707537340996253935261001","1434",
        "-212191008579182060478563837945461872287372869333130175188325135660897759482730035448146388858205966593247205572842356279587190846758925659038643395344396334821348861518596112373605365460921821915409949436456394757252173113308288776951844012432992719925522001911419529928297005743854184672707","9538864545210",
        "4535049728315239205021018362829154800039522502549714840841943960634084990270225535043892135549408608572877513963384530325758104248133124392959997485849004663162061065909846598215984547677506961593292880902830325868627515047168286738527241360778218692535254144583771935549805772798793","138",
        "-1480677868678810347062135814574727890490996459903153909612611791768134015908900253197632543925157559965099005581639883558125985134242978146873558628010545299879178299856929100217178891524159543673803785481607540954533057560554704283718320006046424881681934129216249889269701182688055001","30",
        "262668605206102118430195944953058387315319589613263079853189811674338644589939356676047394737425651989092115424635212785341601958591806782599345416064945113338168378810138043832891536358769753916174695061208903056552776976154338169779827414504134808495078925108569042616724875466536400029203","3486",
        "-3507445546375253318342667741949651253516986113349672180095468758145505921133172244240023419466113277413785800736682458966212429373095894934752041434119711352215164597094886530278429206637066302031501412499166263642447542289785723225064437740655097573160922291075175522551466276032634749948001","30",
        "3053985414762198703102020975667535181880294373982570358384262712216099013630127381226064671248970168701164841859177635139561220373102316273710980757409295039231697360536736113380473515993580188204966808323201772081668695321316425977503713933894934399351348240918411922863059423248058823372368106375","16566",
        "-89774288871630307843644520580598652632613559409413344033893019938898862113876440183943307724290509165539815764354254584162176909463971675189351699717189454959415964995262823025743004001915975128242680213612581748367743077774468104545056300803334120339537905702856877606246855867891786763741486735368783092237","303940201110",
        "2884759276650094186013272224259584433367802183845217969121665253431996536437413850716488026971480747022580182931940812035472752343853999483816456012957551120812115224018480617695398681102870535795278832047330709610952952566962354787854087985127629191094880078635434933391568643930279007460403102076327","6",
        "-104203435297641800915507592803138769896333127491490532929531166632958450572751929026080533456531382568746630428805839898606131705503722712567379172835813497582706763790263297372586804372654090271412733654409742029405259156130663560412599913831518338400385290760913773448329773518728092595019422753511174189569","131070",
        "56081693586889462275051589447484617682656486262465693822181172785524218338951641908717980184709547885060218908068568000776767834360070429300833879662707069272458173745883316346369196270761641325176838738153606175963665383216626724969370509650128327157862121275587666040290047452303859942885949047756404247033","42",
        "-5218507479961513801890596392421261361036935624312258325065379143295948300812040703848766095836974598734762472300638625802884257082786883956679824964010841565051175167717451747328911935282639583972372470105587187736495055501208701522099921363239317373617854217050435670713936357978555246779460902210809009009539232173","2291190",
        "6225500408881102797510043328034969466304425964851480796588968345345616249056035479080489691323529597769377127237910326626106353639640430862662758276037155818313797361926063056784629357346246050085674910484712331211955483400507386944492614175497512823803191508029088188458205305675244351279445756172428826335261196513","1578",
        "-2597900408162896058710572658949818524468219266931291835479959418094890120803707468900281325124704535527442908101022615930505212028093980003061941163493997948367473301269937152541190254678821414979800759785215240308773060568770563333752614741579673909061322574414039421772773951907381124389083123642187877106727324831409104559","374416770",
        "74333782054653889423743469213152655799143173104421681719953140280099539295673341397636592724713785397334372991707306538931885461890982390991361955644690371434518008626267056713898856350449471518770634624568188698734199687848634136577815884007651660546155376602651878199847336975669075705029220024942988801596540479832623","6",
        "-181215287752963297591649028858266281596159320543301504003425598637697061538040522696126018237983659329700516696739148841351912957174525785315414144429136591554131215700560325949733256954674813149699783016318415338094395743152932542723256830883071638325957369194991055197776850603497527503600109515880553950890416293966947553269","8070",
        "3046520935696995573515824242272701117754774305790084108344788704634810391537752246673386049133783821395486096239148415641722199623177956366799133314531041402021345562799254459886856571341036470447536143349353694309187363616222605848012490292828963830868021774140963898080446961958927794750526681977409210580806334902707423302910890705","73743978",
        "-5389479287019828859012200442343326192355509012382167997444221939499202340581932428533725140323939479047999949436682248001244967154707104896269136682582392582110484972339408510822230035412430172890925658230152084954903826143390588854318458185729506889417244891371385482660658834892925089584501833253476537744400283864408173645832802729","69870",
        "876921640102601760383168273082801324788039055564836901409234298002253995782034121007322766508391364331313364222035613918206397636790569250311165509441010945170696883786500399759308075144882184008248023432975450281978336106603716700929424210717924897570827498252893067062775490058563356806930680935200945326351681714440032862515566687","6",
        "-1388182772753480224524259543538426023294781120119840766760993950456297256537536762358314128425435909635398077811882539199662711471185655335807263675649242817349083277475519035786895107126764049407549359856712249235123586468592541328115099760851178135792262280438168965402774928136789551166963401124472782522202058296880872854126156007513528607131","4940319930",
        "3288574272791325983707258196648395370596305758341699742238893225440550539879910098002426164478935667759666907669638986616709137799200377160559516125812795457124992507785560266265469172399329113247421069765604730822849303184464007727659407021486798188927253139176046166778181472669994161900278671855691024038916704559966546186751742476372279","6",
        "-8490228242595311199119920565849009760217791023572798918266374350550246366225435144540895862924269878096526376888988896473279190955432566511173411205746712397692187887537779437718173050158951105924254322875775498449791436769311967741327489636985694874281460516082075289295724305512800386456299241907049270636679469815489106102786158831873003971980149529","7828173870",
        "25875593499348128833220857256544133843109199942629172661571575831896009002717379314993110538912888759932261638883397790531299585084426973156913779915781848556311555818927755071422637872741239146696501724664788565419251002500248036396312656297993421996811407029386847063439782311617981818206546311041142991312322619717261878315979033851316268092742291","11886",
        "-132959963583526612558423182997702578242047892089625754241387587021938995020766563989990185987109982064786136276402406795608981540644133005568845598733701027267134930895872207756078937107416605123323092749911180763524271940975157312568091937739185681066178901105822385739566191012805835839265694429000135104051173197039224461050364993416415448157657001","30",
        "1262786340764743836543650366374180273258073609841543441787781675688541881984249268360325012510167918286412665710785332495002470256724535451201518584261363284544626088778140281353574806840036456927404244048497506339393258324386379574048562781825209799628261527492591555049229691481538713081331723845462120745928641410668923052992096071568118182416749081409","138",
        "-4426158122015997656918081228667589801499808940970897924307086870252646875948841652238923933674489065786806672342321537012751674084821846458685429618183214525289276658012594349154796284960120596423811831259041410965661717709958659062147534583171671141655182016580199364485449629732438469542501153689517957906763036169880300563526920600913900347892060168169080524563821","231026334630",
        "158378960459933745353732673983377704622086418682000111407542005580986544145352715435649528631197645211762019722767661122078958064217177336225880988737955740461066476486097551548991955116319546315427449493825430704787375985685635337262886136570504412827663590990198163434342208367501561777230870660164068668650416176368657029205310526817730948015526849382859712055","3894",
        "-769496271232217048566454403451119653773906354892060893481293713784107951847019857310739767770463076516560575249619621659718985646126964039659981825577646225301189082287264198134787013538174178383958494473734277012586809351930781277345290942985827690026019144748986116319143448962997698665018791994064217597704711709748695678908604180272686662449493086793580970828093","8790",
        "344977368185637380304333898730614153996525419281986770522385915720139215554847760949870834982202303432587625997234795118134923343663265548204594792841811439303451011251437993865656175552484850145014444202587617378736472160288579064961864004275382498994164923679644150818450558302750885234058860046684381556954878962153088786251490404112306387375170114820733240249707147","1806",
        "-1888575590158495996440108433926788958859450449505827069108529221911737605491094242128180304966356165162290173103044092702582217959772178183606221416867140355106476799094653551123469827906281690228047604677838808485752658196964935031379587556530427680306537879720377479310817318584744711522453387072627648438830200285728320936098194745411999104991803838665658699650727659349","4470",
        "5683175611528696607080062478072501820703250802520963611339740016328084145085898175251616359343168595858108624167762131679681416977895536025003761007598913177279789271071880600643885302907670572288368816385439218707793725555126269377090645484013184046265389329719449523663221529092764894703813815177897980268745011893371899061378940560801507189664711567121796987700152153839","6",
        "-1863878995204859011995045341848156066182191846635905937518715320655775958174360523134990756922303410810482600528769479642021001218415879006164302955370460829146434807964717737195356935144151583424833154250047747433575584999029126775186293388721514970183351129809976971603227633930434923843984829580311593372565398574762880028289167635570012415606941367995702212211519561707046505473575241","866054419230",
        "29732914652005326308069038299046877228165947489285775398232775554326821654997284254954541436759755619186929818878962419179787160694148360451817997811323189321730570436847238527392204080083670713746104123180927363450365552833743396887002966884296848913481132785586683120732369858597153076261127975076406564459518695821788635361711463230165952857117226399909961673058570176834883271","6",
        "-5896752302971586952817880137553548037522952101385717862219869597959540714708235406233632122536677446426246295692119684486036889235399687553979484886254426933587637080451003789769961323298135257953657891721726854085498886402779031921701364180427128346719739542203363106920603436185256970882544947794042043194815113693600814746189709447821507079960920412101317160689806936226622681106017","510",
        "689735739192864790938869842200448522491622174065530181755219067505817267965189978776569968680399983089600630968341102178380777713630583306140103562669027424552384203113812510243331805627699809267240054344772443480095752572066698167737729190346148297831547431732607091731942172905658944645576233950351675859756367833238423434368779109181349635099892383418900862720397266277623080279813067604999","25233558",
        "-1310028313878567907114692495908315703121191755911131111984360268010339291958527789632281425987720420051304810543373657881574797353695997625625576992435250954115647419075544944736054854015711074248873686155373327776946348644567049129984144807198780234107278733859628145334731952115798551768101817753443736023659080348249001450368140437083583099127029870537678245450148711191680759214684176445667","20010",
        "3260606235276851195099437047707916012280054709370077715052312896011476347066426313756906147929976324639617487079038182718315850586912998681890040154101217023601746358548442139356881761209491879344448144235471024519916730280314406401197057752850694124801781598205133338269426259564611182358074475139266646779460335469700559434884540406485299632013344690352700850048935613677493364152601347478976955","20526",
        "-219310221923496085124921823808404575155215719519880743817262187359846676808720933963496193287320441312135479981243085410780329920552595746251706979452929554249409283208988310305531179583355242953344731240610852110199480347842183280905881606393786883347661578747110380713468900860626627458517735797820729101052113795399477516376330508889102106163067720003973339359314302749857453315620772706780505888813811597","561706691910",
        "5831963211655227469096364047000879785191356939385161602680269994879257080042651495531334620369899431331189755049833242684170073167978643108706019166324688447112227778757784415956624614457808484212568132108937476630344240535741105415692911032767001030027558118855855057952089777910853586423077582781831060554157175555095233630076901455631073919888020711465283697536929732899568769525385745975473155407","6",
        "-23306762036180954707239902303733182709978468580325093149239040051634149745258544596562134540960231525935441270015799599621135682414015382311861534597843756730857227145200622246509066032795288017634942726754909458234645264430702930529842456653080378544365215066466596986953601385998432554535709196917229350478449221406496506432167664369239478872974247912601100426306339312275565475595669640092216631914518917","9510",
        "28122967090195287981055019523746421026174611154606607881410834553821571195600077156388139504050817072318352135336014937133504488344591033637378875175488860842142200215544952457462251551728305545862703146471647483394138505742989863336231595764600339418866218322681285266901817977284569573044604541872422517736195703069383015638214571378546092320911382385141634160156861783095114673655212399723765743717305197851","4494",
        "-3721822981147963543473628721718160389675395897437503779226807860482566691214705959016239951890193486758232537597591642279654459920857716018601998378015710967458002507660860624568924448328452560808376796224541899685756821793434321138838512925307216420554703983171171540795387100799809353390519107647717976213032752752815159815739322121041527686676774334782328158773314452206678687770745486976844581551304048486668867","230010",
        "11947011202513683767723104489271471097868501873399758887514336934592822829976646702161909309680237660201998669294617552009638464244432709441651377979627696796385888263305915811924616794303093449550416640107641304231571552322204363229110497299236034396583681906657985198177302972578027688117382447661848083476283296893356637990999976607059658190271101386708876477455968880271181353449021120174672279118531405266405457","282",
        "-3829393826694851442367963605345986414644123194149055126713238369521199883032584377556163984602775965899294620028160948209504229098195604243661949859717087550540749941206115020546490009175884700307199551574107407855402424207686775155726579245497021834551699678553804651177095786249593672236240744422195553711332954204942399883879329051596664648871055498926334411033125995310873151284771962309916237507813788879633942447325937291","34098248730",
        "1808383072515392862130370135635372000131626793093148880779287649928820293768508592707521055628027708276165829705670838064031068574527612930799078981578676791129015219438793213734036863426110360623900757855812426023541159774905365518756692026508213803668789819570234151094586211640196633499617063941661470860479560003474875427679061750173843509685528353151826146684405535206504936136026796030365288231301797295663647612503","6",
        "-2038920955732166704563544675871539298534664548832344594940419211031004686244887980129990722833481906996574995006272283772989552251711645339529824674672295721387444989765197094356625686277258759887529063884063441729464466695304817154879753936013360244814470171255312860420052459456595966677396165132301906628818307744454944935388834925108370678592735494494812411438800013100442226704887804736057100084506757161238437561170752083","2490",
        "16450740261761201488286514086666341385844412580813949724000155038308870188720719658119876451207931032748030811189911338403495201879917853940007778344522354341186748832271809821828409298207968739139227014609598106703237472043228932298563800984396865943755795758369082954888437302866500408097109163018555655697695594114688192421141599313689189778427690359665256283948257291245464556741556264558183330312680675299274129472749543281530376155","7305236862",
        "-31404740573139387013607323899060788461129734403267877740839079468522117216337083625061725107066347029224470970177830290797457104821060170534363148276651160571699094881049180803660482733644591278636224534484481850814754420273709821201199908209760469191567840252247706876075856090781209456764232767086688491357087469900906692342923336064928179724546370791109956974800789303951709599892246386582961297095349501749155074025993332911366367","5010",
        "105959450712139358561614326750678748291627849550191512662380413294068107407247886566713525350838198788534238121678429166419664041236233803606051817627731575939553790154021616196778501189528768078400811107009317850171384096998455082824610437919969197421385189475358775596537026092374519645052975059595487888618614275545703577191947383711761849232715855501325445057452043875112980841528855594013764288125280661970576229405994478822053767","6",
        "-110968358518556750910569006059104612436322304793290197896476208195051113971187304256671882613201063543710887491006989203213468862095728086421327649757926706375373160032479060881414285316805050049998250096629298691714712337731033133063244894833650574221421335477496494331790029997128928883270452912343595756835759921082499027715633187483508227173954421007445739076452215234463953952029377612275096135644427285378787750547213980148328191792731369493029","2203871994870",
        "871667613876289947152259213998641324359438367113245978510277002562210922288209180150151793852558736029189876363096736208315035600167649273464678134646229708161579214485318416128870291425640987624153304026736765522468963515580422620761261195314156252082303726799452238319359220112879725078451979791840912313059346932550771416018721541922207119333620480831014488368439858212426770461809324187079997350701358985200574078187666941445255865364959","6",
        "-139969199374294532188729693702577000000465664934371179035889932037927222630615161871008568258760858093560212970955512057983700284904139662988796471588843837914664871339017278834524915750717069973487760152722966363103180527139199261072959205960570607504345672675033426810959288741490491658133099197637151741354653719448795255505120643394167214213806837785207626077991226383344774422283805854628774864645574223075309564129905544107459811288704862611","330",
        "999866869350557363722458479004395830847953169240152118030482972984856254139343285563059710426142001310818604300278555911104883557186325333153917124330048368249458087059040520529706556642732809436335612822769043297715578151918469336944179483860946506334004186007324467864842978559250174108263899703085692274142353761805113570952308838426945093917953996642662776561930695988488695006166233701104386823791719249365863288962981240951731129450241042813203","798",
        "-19435667946412236600006355752680318177378018998686558693047046847185922842569405850478643326624807107024135785299799674685846584030230598008329461654964640062557602833521189158599030670653044302429200521250792329717629531968392422269289900710918148435060503372045597753741275339144955223007618411222546697775810780747446478661790743019087588298611993809224843559412437328287256779856482337754827908028601591041648043989896358637724179061858684905231780173","5190",
        "23574815095404701575006138342677814737611117002189168884514625588124591088321558700476292561495266316421750730681754426899890383276767887403267480686627676268685966493677023072554534770488586483642062259843015737466820417963854802166458232968082382836216212063844897312505105552626378830504014452088433926239997258280111620289793360632141212087877945966075033938687737132829040482438463044913103827680386355585682702291192692673999705957317036687127526488661","2082",
        "-1946958244926408519819928540035312319794025231154312283846941445533833885684884185938663359749293528922631351379885288320544746558558870084671027543542465268801245629638273090846490014696481293058172945225573249920181321736453062629022981688433233577329127459928765113606300176648832109875139888454987326886636880988465878410619882237596781152380489370724295257792104332503696582825373077048086525583941198173749084587321884232599450628448598711165788748886648206781","56213430",
        "502172089109637973079905157308517324166048351810351159422375337574332573514046742139861365117790762795398322755462389540876498686325519933386024542998456467504352201616875674226702066988781736776780983675270711591178536297327588046501114273115924942240089195877277170211145955479537604561876530663522061491492548171664129861255728492613537859772665546205365872403842851465588616941966018356565181922169705164734493393477247978508055348618032704534473742084629023675","4686",
        "-123595612458163473336102111542838674764831835495331502431774135351050074096606458390189947949855899933224956382090454659506523733852842909886351324966274684823091833542355636103776512914842749831251392589846063826895163366115470020631076054800071496634622909233303706997995125130120515859762839469193960001284685791277467069230539953616534532549898448827387071275667857164787765007253139087944551495091418632200084873393873944046407490699550148256008464127109223283763137247","368521410",
        "44586958800126786790452414833451737276485269217604041493957832153847748776691019563443875873891685730191225792159808508144405955278309411839337401759278396174609624192685884123993968501104767184346477939067903846512439522927159649898761965816525286791728854346485686727420275292569511311545587705052888988969140031330003151200601432709893613802729701685072968681090703554561525613786761794587069881004247080811531298610122589066840923344874780872870506826198179146216889","42",
        "-18249520604687390491188873019557839254274215818941916557220148305863171323999328631073000715354712349442824804877473011208435647924577393976121564194070391790525169749128982828132077146902780721841387850162775862442199934474879939605150425883830706636702361084052335568869843628198626221242494076538767614229186803516353130263179834649242288787960314531149564506544752097614513847899020629776701115098262552562151629993531946710430672386743677617308205579019072302696542508379","5370",
        "23698146493089350432280213985162669959262841111102470546871456237323693618435911411642184657663645971277792033537906347762183635901158641375259341789919760310568146035244593237879245436647800609988327386298127942914981131212727307691555784531721623262685912374782653802898934200911324353096490548706043962852465907958751649549222286885339380268684947173053181005751121488921877337975992137735046528729900037937548187674111044469106308867226010497700021930277136809473041010432321","2154",
        "-778920925563520089023277887716919839298513486135455047496265119151473505464734957690937635048394537294415972122421086877478533967411348994474171388256074145035237797802154822761617528172700015731068657547092679836095543042179681364991968425138238530710252585175316218097390905698054739393609117605669741881868029805237983772228322424502491583995084065878787104609542382045050185577023575049548616444750140539582676309391395859436260664778641733708499657047550739325300732722680932200039559718809","21626561658972270",
        "715341102258098940319912343996707811685084551356244645540933308810413928160891724298276851619649551829973697033587181069271380692407132317161739109284011945227649892560360729074672778640720680874112214109997197387525352062913504682830983772725393570468326491083187300331970668449041594296073065276692887678729691114916079642579900288026881432235979137544823640729868705093774645241454622836223176904124630526882732099120398430089179339282190314646212515622936459121100998906169917551","6",
        "-18399470428456050908014333117886494595730651014055636288722717429950917809500136272557117402977052839042105693597404693257617634201600598895359708213302738206862242849606975947076539483777341046657860376203296993121539300815161693660027527850273081527494673550440357634430596208643360358204371232957151165657607509017253243152916116719712350843286172274487990507840124030754833011930721808729659207188165402273267771908929719004881279785191361391914450528631012111465559730900716078151518537","46110",
        "20813243679670197402657864594700362248333105628735574505407748752194329210363364029904045498683920274785904391711886368296491226342074760936891789529952828353712861964615536938434038079631985205838319830159148784466890765577478710750411239086707279314113340423502528151089538256774657292895067372560433868261285932669643784461912885034984352745012134324851266880718011466493208024572308839966018431480701067038072465848677106468318507151450224167148317101357641051334844151154035628560478914687","15414",
        "-110725230879881321879568054811797526267115166186538309029826133137308115277324207270571040263441920262386242076342056949047866353534514266980024412370434220187359560062050493440457221035440089226046696014690219122751069156630764313360960761587856716000690131098571105908045239988081704908481660126863809763243757816063349431021332536632587298653399772920535661074013239670953426088742833252653499763654446938447050846790045870317112050534444840968778815676707175954631059728590843972403931253118799","23970",
        "1054364681019267121830159662373420279818225480653781839149178920561555806813202030269003305294989784104213489890426332509828119920399712689187184649711689415835280384720994979874232796860338473523737136345243289020296312370876276856303158404225225651223912805235434755784151235675589206423964860803286777387807480810963355146229723274524146948489417884118537852386976826754447246469153480716621041563108596300892747446848622658459755002905969181236655822204297783975692352381312064835994355860201685","66",
        "-56868988747972506254659596935683883463716573524427146597376366171981802233487630537261600452515928180502785214820124586232687460333822056190451678107485446400177877446417556715711032055230455854240595868388654451080202675047744244991416192115524025084813812227930163123287145588705727429456779082968390877093897979160965323905993195706278985485896440595636775123847679345910845046714163301325224520710766325936895600819434580574518875433796519293151389916795779147962584026929392606854485528272956190655743","1018290",
        "27233521998844117466571164441681703778822231688822656418920849017523981696494911618651082582707143082377020546888216407884466480834780583096823087696141619926246646927066679156637706667759198043548965512948036645725109831717082230384665542660596536212413188407637782216353393129995452568219713750918323446571634462816666446106121343241772625570723451925602179037604045813434065564118195563426039220880907100156027093090547687363620867038635244235643402355449232121698090257432456131056504444320853157345201","138",
        "-21144886325968847421136862640933605790730878065158231117894812330764874940817232709655287449203776974910988576503561661800249278991319113309582335281592647442495030553208258548341339318764197461147432848991686338242711098654931144304725148541437215370995347051713517773502906169174089944259231510484935144428438091067266131242394201122670888252772064856423958372374082615970685597386991737179844349495505700142239123902982043714578671787314293339023048726217119025452344630237832665698519639606247957083240801","30",
        "4202152324841490851582198491734154054898910989229835692416027795481485467411812516892366095348619673337490550280425989691409092856177027846893427878738640633197809375983848427036487478678839362355759610808529212110936501477008097429319817529927993776215011685533261432410077791728458394351343228912812829117361997697793433448908490531697660725893829519644454139967318758247135377025444352170089166553939801451419735179550891309557305319624844923751198154628001739638691998206529289924753014269328705445340396548203417533","1651635762",
        "-585016197049150516429606755440285431916223316191798033687181061470667150509536113671258201054717866226570169976401850360230659699699301963057743166370714339259000981058060988677132844370590538962044247092297537672905410985648312911796535010450651733583075122028847986584025427113069993778348629306554503407744980050377057969061170508810412927919930789637438916383763636475443274955653725558963454824998976936559504337387796596709727547538729277633022545136032386860825147973153846428111580196229784765036789760566304701","63030",
        "78631979609289345055469501119395008379118096513723589634568877004799927202495863945986283823608714469880713486237817037414979036031006235383025032476262083964387973243898060840722936009590301165543812264089314197515688838727901018644687053389435289951515626740339208758682375061416597195951759290458697298602770109818453665947288873748972700580769864649544946817207071904078063454972954577208463927530056857030200986057709786810533019838606174872050746460837475834260566055441410395805129523481902672214740177851314801113","2298",
        "-110754162756402172153014550168566972984876925083693264831143127544432717811904992984077240231351850620045442158975752476209437945003921292257289655906112174208294630503691959241009346814626779961417257948400146389011140929210993075671069409245612465372014808443841918963732454979635619634196765514065569765406021995951240364020270070411437377187081353045931837302854850452592893523482298799136698133585855070465304605234654821626817847160151252277371211732021978740981118935331815732788765628347320001270460720535171080710693555387","868841610",
        "2879114883186609620826723532068276104139845449825894019948530676086618349883233245139084663416929458760597036667413717978530021472148264070597286070616857893183807259158771980877711836973364470227289919568822358886590073234578910075775184060367188577311832614887005612354400063672439629984465735358226535865532910705094242132700635264096296205052370626838252677418749801518077664289390262828965585623070897002640768910479324438878660938953441067263764560452279108930457475258025425810584201571774449957241464340109525100976383","6",
        "-21299114788094757397153706724714536413292077775222009197296487570276368549767668483739905654759629794289722059088574391474394384116388842393472198779890845792835783368209072403070166818305644992935634095949389005892015797599060514475400351300665686095027668428158520105490245612578226308332064019874832238296603858849991741989885454092253889660892754436759635904520725519771622791567806625636568537908996210911982475409155309551762403125143065067389753960600797968698009862634474184891040512288957749239742206998790145616588343479389","11670",
        "1039554412204304060999050471842935871664238236129525031050621197904673190252061816306076783004652192616133527774723493749394461545816137751676691165637363944930483826319036927422553141330104483296290342476507053344206817648719129001417301179730182909494636606795995576156560517060235847592695182729113023238975218843912996538779543747649999358252604590089345118921257104639445913236211149024538216358616556115899687337155136781007563112551684977465108319504450250735437471011340987371661862741413337000516697089619657504784045957077408711185","148218378",
        "-4666956320257517816926480178489878702719387148900232522527912339796188714409776663856362141719980502875970806945762712937180144475887677992558175799481301586019202060028185307056311432687319799854135340241062231395259919629305490635354239890090217072557890791528689479267987496699263598146171495893203013485575227547175970131771602894568516495986613037151863666577390670765165933422564746168996994413125484969251071189411262200344536746879649016328422523901374916569404613335757056186544409616787583076594896302119414868190918059336879970513","171390",
        "640808912350356174378073333715330795309912947431801296035514496305956924194050478724997308276302531933458844716623312895516343306208024932183790655351844102967791249508631724180677304236114904329953319103713608769803340518450516179464461284806009110502342220743568034682133273443656465906102058462073733441986152637932219455262690498783033366796807895595451968974170018589790265173871732540219203496470134837096254721957294282692027321105998231580155273075570903000709400332769684568638209079266772432973508791091418552966827434770217964847","6",
        "-98872162196656114876533219362632891391774839342005000436956938726481191695417122725991435991920485003784886516420949151408274403750897124053086048470809705387715020563676318491207223028465413318847625119271235350352217955302858427960756286710348612322463571556662841990100314844270405671459605112346068263402145070889841697007530455932282600691314028702416310723147417755942945877131986599840610369192441659461647425950295710718456957848137284733782503430592302360661270817820862416426647830439342025098395116603056716015807642935747540566951812504354652379","233649143825370",
        "10161900313215566319953421591388637402328180425349211048816698980319072816903521145345726221163084105611450343443221137527690722856383209708142471452342875346539666863558482835019156804751669116932322755085721460877938790181414341174421583630169802248409852214724801939766701626707662229904797008779706437578874336997303238218116573968772216970036489561373747407630110362020821819680854208929607112013855668348426244596961480597381595137016528270815603652018778457314919825182032768360703403384404569260876760458965758437801728169587522360995301639","6",
        "-63783639210289998710088973624588233946566075008131539459746377225328551512763402330278905606150965942861218654753440979855135225080751599455762303374322801376784474875903535720147084146967619965166480436166324915138652313161158459147438440579563255414402868679468643443725452316589751257887343519347376962412796543353378510329227640325960354800434372777469890448460017461964152127411007649663198873691188302850776549851095445319674329831032713432828366945325817352958745749412125525231627662590308189489017131904402298383855303749523779093820302379681027746367","9315635010",
        "1174239835539994552190497513182360535032387583605057260007722004883059102557958144704940674287492304226247212849059989833910250445125922032127665436388239538661698487981932513000579577766999325929606223291472664224576178291713742872723127632853994169543584403270186239889883934311766077803787140536031309605772620994720158177432481254737877501095184402972656917745175226661913130878960138618730840741958163788195850901560843232573640710143138001159729682511610291187234554610346621711370121346135534129198492308718185558865166313048808914617330314355609497","42",
        "-3459038918426949807320150484933956945853243159595350413053075601122470521916955664973829953506019998422380872167968566067266857401026670310184013796611289015884412134623896705526558633772056365694507697389600886696154015160862337140032194111117938579681157914085424486545326355341017764587852271884318010152210498883089816668030790992239717499457275164513815414692072356653908445653642502944394623033131400812242246305136709927393331111317205972671896631185417486747798871333208226992838344653421293924893416433794558513589011611309370041563779286876725823001","30",
        "170003857441113621055924711218201581479060969973774823543550655221015298985029713903581691625806778175064153013683952617568923683195904825491671562597778394848940698100060988046881674679194048284424046096930240621809667552628402886187489064670995742803216624905991737595831860741767548013712391467620520309900241319253287943675129083092747241525094828376937402590205346662298390862562643436019735148452642958172300132516340448730506554851256643796686115524433824609798825320819953662000059899761347431172299049404919145053054118348793890650129877368554102264664237","354",
        "-31826882167847269036795264135997035261326106742393531631262513546951621739538129483912871462979086464612269631159787510831358937051013784806855551647371523568233230776308094926266913151377871925647720334390123342313810138336493293789276924639127443823386014514502682882716709333886588047556737429630427737978891250291212164857441066067952971934975332936367526583068834875982474415309122221371543750940258579267452360489050995048217629796997409692793673935051432353130414145045187876172429836566644615416398029958336369046123993446514393441794181039041943485420490171529217309","15755919270",
        "47002375233508680615492575022874518250580216595322188118729388581779057270357890909757660925961204865010764157357677339640679419801075529375841405834200075859710151539426985792722765113963198773076233038710305332376160833224527455197843754378242330663125902354233318353062799203163603734366135826055833545210943663972100422012871119726280972153082552774282015316310107675884741591238987329522432070124995685585469794166878230612009713252291615918394199230644202167695522574730295764175556463982949470912949002495605091357997599244798045099081157657094553333043809915382015","5478",
        "-1104074382679040449322457640474906559564674033012018040552761693975196623398701263395843134574919063111979334979001689856745801791431844835192880349897217288293513020820761816536292340772895413243616457931467439624320619545324679396693426479472670415005491693729301629890910865952928640236591593400805258179861429283108782677380853799729252550169975507441841656878779871922009807575659278905966164200037561186284335874588669047079319694680280463911923325143499841983743646211629813016265241858462427586701167961402272877528256110590588675820001821779929699856406082793746601","30",
        "830966056816864165219563221691255172504816245427194942775778460297239574008254673723276280782798993878568376502765275874049468633347470545478154168815827272595416765071482194437630416545142455883532025709379623773918422191234979559992742090527602639659473260751398640580101548381014113971979542275363074811349527026580264739170503267212543977947471780118824749687917395812884246155157646166836076504356150965742303158590029916282708649948973023160673477590749360021799996465506161348017383225242179003450331850903647117458837892565999818223864269663453594385683125383821474811083023","5213334",
        "-18840632174653835864968232583541556084424607654449238363350816356454780409921315489669153042640423571904583615446707687427327682018540206290243741793046153140931788677169249364676259458302231885326120895149522010431725107071591063425627272025446059167464033814661996655342902404678020463898666363623366708637084399729725592271785009331862696316729612579245598615561813162507665448387066401343329999818243511962109583265019621658883154231991893552479038765074765515515428784392050898556152995633956321371743766583910838111997813677461374152418833832478425757962198139801618258600291701","27030",
        "177948829071244383748461224300047737954439245366393998814954157666837290036442548237545354559654248140762601235025124016956688571054331709927511568833209554328300942088687575803158770352778902946800416194092364129368960809507136675944946524355529271391513095831833834095214141413201872443533465259338559071060276534081662109185490926535115165429017697889522123426359409741271701359896235732490827288153220352311977810488328925043422296933754175073177948425972950246944493271200423473793223213272148300689418662045121140562185310116950518967585206995379939580805302928813353440147414740763","57822",
        "-6126914449391766463123273102284652981370509248391971126816109275821466096976801669348238710361647712578179757979414761992440067232917335164055107920780363262942782633482006999971350591213671109122331751122081373688391335194625200099100643843244514246383231743873282258287892336340426940736781587230644995704054335003998425945469627545685623200550970324534080404065484535299953386337281009271537528001339179644699195404880031646796095372570028624110131487675467842335793522121252328612723178264941963550114480615755660790108038424472918326815297861578110970433546154844146996383907171442617576638221916277","446617991732222310",
        "370417641649773203811105792421530317349989434553176611030631322780037740921920903496806496686319103807921979015270437429241936687918394087764863038019578527638851481686403847480960464641545840936004289242306394237365086284210791291343989458767793541220855587660095196948191905734357956461535121861354233393019487098593606068830314737953863466706245485662337370451037774820208643752612698330292374600196793018724057118532300846184682702881492970790966220893763118615367891028920559173128847556946881708070136133779182213573320504698972245409107308503781210793753700634159761806826499289415831","6",
        "-900309704889057549412703055487959300250691255243632314995356843469409197586598181836315775665695203810817228257767800995208832223406044287944134381117528642679552487333128252142131375359121793415508211496537834167452784284536412724329064314223405159310288664698829339128075019109308684058290006604682848685269913509631592635991061291910848588896849609801431590823098722376633326783362640890294817117428008250878447534568070706275064939211743430644145531251375121140903646902567865610094036531542192311798685900713287395549217317410664958760801352234360088468504559813801913565013476710034147368107","3210",
        "54022537803660305299034619951080701815883244369748020425073564798052876966542443431399087275857901045210724481101594546860129641620399468102807793533371090463155019439376300426001111110082554857406340378848339696012824680258786824575893953186081095194738031315027987901599699063076400850373460929533644671669856383541718682959908309284048987253429549866158169260473899283324734840555471844451471581906629081405048357875350755464695286397907639138344100989311969291336190793916170606327076279174475858929332637620247498179721571404122810497608597392310341741689230018260320576738940580419471886026121","42",
        "-178631832601908536171004558032761096296603555642069337022466657948224618220000462860819307447255038425012723042570990636159393162920489265496945881843415223197089039558399046230412722134470564185454526546692168928856644009854678892565378884116563496393911506002791803756925372034984042436244890477408434546164564440123159575118382731762120541349243900708792397436983071602078285813659425066659156365690242457074462226267478374244243395380526750495191218544888861880143020865916520055167383158922400486128739977249726236354738468036532667283720083951543434880992597829033564904575040629182418739065389001","30",
        "791452428000395052990463674367408774641299277169449382275797418384963666743647706199968141726577699871535620647877271680371011363641725875016441804003162706216814077280766553803448788712737779201122868425785256450531121303233116813021906603098871081632396261587905577208955217566658493203885877312418398060846091120975165767009344894679683148265158035296420969642632188332444968324025169811975004853721487927435823390089679208323886268818820308870377103259885100640557295098484358112295185600733503211183865432570364543715288518332255545140994972346903247999234036372815320143622542006284391778075614230370915","28446",
        "-14750577990707069090892640643627890396790588057597932870361312797605339877218555318290483697927533647647152620207786705312787195868985834595937926758107692208298403338603695989231215167692521223914659443461688651180043473122600527834618929052569980773595567060954830287077779819370475900148020136696922033144977602316267162377565896641961582226753571000379259049438007003714263998786954349001656043288757745179230747108219268158244213583535560775121257993743283335146172958812409641851314398652207671071800026121000251318559834563893238437683153099891646143428578083417759291169439869395337214083816200847999672131739013721","112409792943630",
        "3747779487230132491900784839670360702621969953197210049501251358419118141986190115493564102700854690955620245536804192644210548283959203482329576239229460642292110251158496706142540965642461705544532623844725391336993674360586090434899264849404330015359243509766947985382840962057755044491819343032537950612194324352600097426145059000885091707883730246793387324549656578506520410600783165826659781478577755966537904539285939024535631431583555662911156572916830417427298791392192762504813321994018595884981406242206002171583618182559028568019214315784771237935918859841167713230012475726056827372638626381963585567","6",
        "-90024360230387232926513776967323326794697521699014742623495978698606015115117275163938036449925194916848722477911818639649193586017040660336424190717814222779195576374240102808595115759449145109628358599211511306846046027111627976699604296466038648254628913968475783753631135765609682725844055075467512860033319632741902401109514097069147699670253945763189080474357381924555174022637039432337932007567967360013189225484557699891500723386807516891972255376800483482791579348941380904127063436404359870716285253826928676282091132256974170075250937201408937099856598602948280585945432968199829410867368026769199252595801","30",
        "268255361246337126367778228815259545045868431029437849645589178925638795843497414272945160749514714084165426561127725005493039810079480452517290207498185200717509668055892683546318815665341535697032808106797631781867079778636900617376382054640817598394038676153517033958597909974830544311249490853122270098045783563026899566057862076965478508567587449877041567729076139718636854981066664507897053160317558190734639340443419436918626125596334898307900637096349388220502296543130848656587202710882968136604232104512201075293126007959863944130551986019010434312311477565523149656237135607816533477227160969517648113475415388407","18438",
        "-1971549561515498045945281707781358725202052418820469210287100375124408635052889958528421462206148998040363604314916692108315970766317682360194568697651597939992942608607863240436440670587263898825900455009148047595679837461799849465343687138591048044960789240368282898014290879082621858961237901928382366671020037189395193173411370422088058940123720113875828797411348581899556685938975754080936775135639140747303520886284176117348920517204041675362641162399925576576653291783247744987573436710429594592096815313807926352292662762861675065257056115521036077036706726455044401225578559120921795944351508096992367201543994966078858397","27695910",
        "934217844394639862121876161182125782629662966798874841047916685310521671553962326103991809647198275117953002131456853984058360472753503867675200497447364861473654065939291320525986944570166180778722315422080724702421323386482784126733369118721815203984881266971497573448614086191554625693617723971683850141789064565402372607797348631247017594179350444633051496340472506374723019936564961282558140233726105870589191017887960191293607258806456016263231512800235871497605920995641449875958591869460832774676734017514779283735936104646380107986104389604327378999649850427118391694149262577932479289635308490619974233553612397882181813","2658",
        "-158845135682583637310050414378214595799174539534413035558457927180260655307343938945950776141757261524377755785578389794390713400424204955224064287421714210308705949074744929596932632241358688262813726174958748320025797188191224303535908875129465586234092629175800592249211106320935394054787272761311671502199224520443098879151573888801771623192883526328927129807622792528335792700318705689540933290598347707055522491251314640804320693900281215224262309217387438431268666875059083616022905739177343532424279695920452691897028237708410245697642781733124304062104070106669202262888345577753573178251769219880004565578924500260455594131928657","90709710",
        "52820988550912804071451884491873707077611397679084704441786148606552305037050330902476831330763618274617948135285949957728028695870688501651855365293214261665763024004555565085202897776922988749231163862901818153108264790734253251559229193150038194654616836673701295399639842711610882623238385854157477150420529686140635722118527587063478286467506193498289348590140209058848431175257465051090606564081140432276211107220257560552836024246626312132223879207171064190421730933829702220468746118116687590172977326777807226148473634828964585294322560361223896420954749054906526495733099883401725824247665659378641424764700866014787892724263","6",
        "-33509969560310951077673300385182939173120218233464878294252193880216174489593173505823838246617056145585882555706860451887313675357842060706217782059762885287365030658978615168275599290138352468354789757259008089648541137547348110439089815672768327313180473534796888815851856313394644427062261422524265399511451721069073409293158382781768172256354047772889044225230507510811482737634673210381142106400974943160605739571810507050337114409751599167906471400307782233953490003352622899793151422802066630790773271959078676470883432223098011999197297967048507289842238199051754189231014498571762573655266437187969662451821328060350075608863875769571341","750400230",
        "9391055572765375337084396117314557817718180166181509161271561059129443589397485081513018424705071474206174166639082356181454829444072491877870552062694059378849770958442322223463829270989901750468144609171516219648902784638712130372569713998758894226403154437364546237046936234486878313444740508912905759996491085406313529674400225188471243945850641568659710670402270969430805001894842922440442618558016542494360661268867597331176547554831945263940482855409773467788716571946235493331362953065136196925332392537268524281812660120686916907551456071718059004900562940126515655638458838017179782433551203385736031994621640626329584486625252298313721425","41089818",
        "-8036788600329789637554905408606434751151763343827636999239373595458189088012226087443084910869936431803106244357312755090962116368482475276694252905815888538084063223859971526076599239358507163699508542178943276854150562290682856423508900798777112787185623445870747150615150782172422604213843730688721433197193927654307261557625517124764287228841421171512634534585391620401335799765458353101463743603983062786131145017655611914534755704275915462765633857066185411573999789535405190641054970837982446446314245641839258145246102021303507933166787126508119006984137728812640057612823780541560848078401500756860998000273851310662643557278203530509156427","6810",
        "36887651095190359395978631707450897701552180104326675120919609694820560648030474979171133539537862210662044736026621541679008373532300695155313150561362479551904410240432070856446263923979299500092444516028968803538104878672539814981236198854450478175391010338000353791751383268673072000938944246515277386132140583257856132696558562847161814996976075174769694748695438632575090586824991284249542651404132205213670261425227222486264304182560679963038720949995579422933796694986011135385677383318542530506241731018476230796808445574699332521366132935744942092063737117719972419446305379041821531028902499051591918182645467840089773846410376436748099927","6",
        "-9231251497205337786805280106627035365614237424730160108604924651736976180075798896215248792654225922031690989989936814428616639799004585592248516552105228745115600772090469618649949110864874437364870818222898493364585027928374556652768749981360929058298243205794495656723748164403781748730579086335638752417431277593473211309077070359896017274789066550552469547698979828077256389389589765286385150263946322137435703489322701057413339409715907420401015745559280769997899350755949293570194811595617539775432300877948131084500469766803745905331871839118178605120693482483577762003279580322707699760471279269534859347690610372106577357727353920929624706796074041823","285702690",
        "1027825635381261025084137509518564962560728450132223539521526948817353636181702656928583828828717439941582449877622669707429906934288552278291471518913824570952553234368789724603442838567318141441615655257676812187239952554217908948438076178377910225560489116748839886969453337695309781684455928141552611581080216941930192968523416897195063762538557409287539980661256894009392408089358915496977576627225148859236468505369342003480428366798569334698706219583396397757047422466674537196192952267180837549901710490935337309113676890484857602521544773316821275084647927509602731787989854783170081148513873085444058741939360926584684355544622280387129474006982319","6",
        "-6550760154113509955322519520324689762818345309330319372044343946911206397745316500483812442237014438941335293944750087907405849513426436624910542114024406950056919447434524096723352448017446297358873710248617421245570015225121262135612027972284197922153718331776532945085169610851088437877134878008919341980631531214431991715959299563428081327762284421994333768251921757188656927704213872171465925501861603885110199062495929817244864046765240300372782070942306808931353298237329193104023648523727135025613272860312485759776097808925561726646874622086120677449738708016595010877049123286575216517173385795826972669505322466175106064791167244415577645190187783109558537","7150110",
        "6368886588855890529015573157270243329857473927510055032448029799766753973277733490743802481131249684574480516536707396064341401134831688716527812955468642497995612469570965195817160487421985680788793411096140356661976146745150228102075529102340373723482996983265766606390143860966670113764902836475227042342140853703902690953653738071098617987052339494008437294258743953709135498602090607507693690330811502343804351805921729587694688949530767925472547494085687987805410410505963373499481785590861551304643751957929639863906451583045448988420712969430083368919548554903489673904877295745230080254098114031395040280378645921227902389659674535661931328259201472684713522055433","1288550298",
        "-188572988301799749241127705615416162812212213841895020766690762649760470928083270444552850572643956114497215752611047787304109375175847805695151784532184851620320647579855705925496701761448465808354795813973779680808888167818764964700925538842134054390992956001669225520942778629366261309269472085949866705644243058822229069911401050274835800403163105897188918692416516840686738234446171587614205164199212128303162013809506690718962024295099161224082167003915292076143373222944136866167556404170101140178710147326875675233494871699877286279336655831877302931691870727029196060937873178589575033953909097962613832380524097498719417990532304114093172036385627503846689476887699","7010970",
        "413664867987222956244209355804553132010737311619873937552617773013514076367023256312176160835062661892330568050774492900833764272232882273128949537336490168744752502048943049241434525025420643944559491826884487174091266835019079457750298308269731643882842579624683236689298288625957015934020852065186333120537819299541510992711232749590370342660947186143661434743740645683801183663840994358198551336011498396150912151423938206307866725487635171065947029616755552973030152102744795495331947296938243287814790516243968203740094323906300807997945263580249967044922095488324059855868304323339162224087731767838889133184638682384777584272685488996638922752221799803151101166568141","2802",
        "-1031107841715829258343463911912030698033011526937248355743056689674697602723540112990172956648590063031143260600724004347065027947507100488450593390705595096537384272550134562580809036689346664720973019306107636742232165503223693884139986374204369981544077656811163988149479258369895200746359684803254154401124622678491322587940166253688363451761279210145812935556959005617096357884154904315169217040557989251752098016262897990226072225936970292748900280469462419239068829802849814616525273947160256662458312243507612184481586372693712226732955571148746164223940290646509705984881548422992991644255618458312931517172972824955609103863870050004830358982153156128215328921678827090764016307","1261596819210",
        "301188512670574409973522039731799774332284237966284386701245748565406164428681036128926063056095855532173991462477799681429260898037617758622985941710976235577943559100259786932475830383970536995316845412258295246742979426181833225367398491810295210078233611825547244385629725708901995508766557190851612705431746456650510895626334976810141560416672624945285953742157497174172068239724208754377218814505115022247180573164262593883452362474468782982223281207823275802362572430210812017251300349771480681113489830696638136842926883664618708287688430079713258060558978096084995295625323965331459365135957743350303225791768643943305879602716567061428469743627314569410061103860282955485","66",
        "-770937004570847542710916650565931789612450235859854061364164699012203056638918055135259895416107273426948797500232897203853071790393885116465171393875976673693385000879337198213556447794398434782352654738563122022624642967864571454383814267648876048449590603480115693689162580755992686116534563663816203506520969500954741353683081691871170841572853932684457019190727452579388269518761070066012225637906766598808889134766906870857170491069727522854987604110140202165701028056317715546755482888281141979064206161119893213557441124682697844058662867837317718568074632672139404775850673801367503450134341628737627508058275331031355246875710092188894581462212753275513865164976897399277601","30",
        "6129522921698903924225094098894493975355342495202583967070268649960491527425425546286128994652359747795614576729300901193288468364098351921425898605865990737737763196859623939630382031884908027628137877044490771874628629780057338048896492947577968007519815003168246395643465584343043193237880881635998419368585273823574720837496255282601496997088803126305575254814207239481124819310777601851780008004534530982225452330277362311532174615219685651873091360796309808900938980799843045197724124205459703692404692815206856959614667498156439854860378606039596585529438689777885628862162187008631192421450307071680585728728072572580947780239520470275779631590328798136283209653623721740978652009","42",
        "-173794233423007364057178441776478220477329295247992746246194028033098955394598434863688615219916214324301023001093357893746330083903744204991166650812061841423746487587175286790822799578241212757499312100323647899801856816587814694250535160608651214203178715194330829602196319299830498255481024809653516681647938371069642056989453238492194899464534194575984259211778777474726825907276342679607943595029925764974686120493830750858815144111018156639748863065679944594300279690320295481014774768770077734050367942856894507914571711299927762683035011101547081082113463840150439878440505062095907817860452253434600485043521832982039217192780017205043143542812887267054217968944656636429743815938366731","207930",
        "13873674832923745170636547493407974778812031787162484396922203584245099363875266410392579249977654901546226138255725682890165166445534326211967788770965050606335620329629392266509006667636060346080828403980900870728472844701200849051031032721110383896992993960600720447264177011379489696922012639234054945046493515830646916075528778995875263891724422324224871104321292779816866047869594198817075501831319907776354543266924566231340617726210269713505336228589002649382821152876769886796237625064939931597087898226387660507299139385252112368241337865982079462586705656758449262979906152409703115811425535504703782935179149721682887228861005266932595149810184020272544138033841220106232249961984874041","2874",
        "-26012984231082938122321205711106137025736836308811099420978321017146930273005671218213801512995150233049010223325808387207760652312185884489040204754381130425223206104908949348483694397053700779323806598166397483624967026385155584314813089275200872985931085543928822164664368156111249818285706698582816847860316768251385568355911376789419906820360322920270272727732554866797105317523759568495736021299387762599572352567156747373223964524139683333489545030164669822955224449969772265055374313158826483073058617899550929715104043848380098396583498089878468223019258239295983312553586622706514962679548326500707178484227310027019877548445744372693423428185302230083093969160616600533454208539007576331211435405256579","925269860885370",
        "990616118004405209547336756803741296643221987382321931721822820900299097210222317336001831102939236490395767769383589450743538317573906480157831910388399026009549363482047723522295682385225255084608513720106406633464966275709378145660935302980557499077874664887504148114522460257788204486783699727500508138689641080038916313291730518751063292404119140988768624151887967557709255327422581104429283482510069570158085040668138860662778558327704232203358594262804010229103345601462990376149249652299540260177492690219461257167020609270211173637016502365724336529333125021542322561542486553234490872949324335738034611680591470710376104053043734142034650737431499785882884589522913671849942865299633710178111","6",
        "-674583921974243806727583626605726893305001263343470277847644141353711283719144748396214643464815527720051176636837830641202715031912558545751272265963459158832678711777574436725109883048688054377892408030247686556398952252471378342025741011438575099484896341336771053946168596117603779433009583486087778261092733102095362575294914815257723299413552987428930625441349976483182063565793384408266465380474529520534826114954047630754878668040735849610788709880820541989250906334800119386014176221640220454426941644202670624599594997416757514254570930031264863092952803531973860879930032899029342578124854325385199562765121526103213588359312368828453688417972133504757523704888418645741605357575301183566273541023","690",
        "369763997577304898527792056092078784633064579850215089906718927953975408532819407204558577594984146089620623998022051043813802512840569387856574528038951679028036813020229062675066916989178254799161955591299056486170972788431152654760791766791190599466061280142672740585701636947897534361260451582259758691868004875864277790983654375073056163053627813804545640618169241729192679530964042280652574338325670662894789508966565337142721844903092886592945025900894162911247219665577745221033424450158824779569415157792860757313903143859765449917326253963605938268777389669269349544451932422774330893531316131993509969738757701435869993709233337662014445697606454995935095546520785205839498933104702647973917548450654482159","63346038",
        "-1054181687381409638131616910853911354455980657913781692616470855145305376442167447677966359041858772154880528891461759759408670524036867330393458847554077805022113371551512761301353668641881943315640673862411986402084705908271833037248441148559758203373649679290148162009307104085713861437407027770249084665069566424802818695978402723455508336525572007924797995088668996393412803006736971627889522618048536287908252622198057721526239638561752413227961375709262141133204448616567780414625262935283998346756442958214463663418419136319815181399963230777047415998079220041299699187067412714951204651656933821520847527577289722382000754063804433988042815372396860021515945936788059415457004917777955610189853432234056001","30",
        "490708060345718168482949551065008296976352341812156850912460754793773228598743021163789697895339848508047563198613297970895771272423084451586762411542433689884882582217920150615320261296412657655420294950882472519077107436411891314989684272827405143453664676299901282427746214002776016429289992734596941647026794542862610180682813869753438462413802302318288921935542654412271101075502309306996459972517715826132089736597584320511669263794701105417099176436055541622722611853665479429929243382275785136760788118477444370781356616739167758192241507716005871662971992278037186350173271291067722673038829083878521474773044108789762491726385320922397469619970046438378452390321367551511627206765616414040686450916033159995734945","2300826",
        "-295710682036368660462889828594612232955924955002201524705248520206592222985898208468564409024643552663319217301279279456599515167727625150606450018918397365866826625510003837807762234721907229268939728260753209578951485832358379661753320905096937054954098245328282838820612002927999827875337943367582502020545668956501113411001279555402079055392887648432396357270387066730514118593546561439603919778742559512015901475146476123141564243291327909428505227081149290897384800809797729594081307795911125761034063373560371910341119307145118793762233074626775908914657621875311827273319354160489425009975655550242275976199551186361927525119846700395907422799296606519248369841030425783198567324724905036753320437659605858401058641353","226590",
        "48304952056070024985817756788239978908682438355340656791822950062590796355241246689448963611728938505601369463215719576289607035969877364225474402150107267021033472617633002498666739540719726067208908400868629471652429458078768484626439283884479517280978247192859399400878296914805548929586054952054550941690046726387385343252474507896205536559285343999286125673465838911018803676968634234058996143076453319007358347695097769648224143191413651220988411012365741972645136470905240747776225223601701498704103140362659865756058524036705273180849600017203422636276522059566343973347678362590339657974928808786150211385800610012387411013195229675295096785833478392423958039918096194458403331849842918089944679987935690252652536647","6",
        "-25535109222241698972694173193973518774716242178265877234279078154218306288190453574391345349607020347701104389306082727640662249328994752154372973422361999092715922759633521270378541507790769763357456276378726595626459724623679603915577643947700472106673593583118436960062894166402312867190376592931480464022802240967436286930003098509086131781553808335933575272888361402715107788113154287996385861486207257531899222760762747086758473894396360217594584387656887231071811145643960111628458232775253525983817907496407600357182919744162523813712195436135703038816616947504736640465073624938220282345566631808140813969037396579578863663701714202683178828730441933582773514024218332915875259194767588507001149870106803558286434937883617","510",
        "1098651228481515846116735605942901657544418942763685605483819128454976385464899434737242367240952385067444749008365642568063670579728409673461751272924549125285602795045413203741844230426358616759853983294227411821897092348333446120995756339616373490620446536298890167517709746328742870299157366295356390032576984786436553789735950197578753614711411671045054914305425293539519785975913292188458435472840034103326532984267720997838197057411785852422605414587329459898626238314431604983174665957920693815755227736013545929781603072985638923688324355299338791368472239159091263112230452362400314432752766640687084000308229806355172210181524971644942859893996940410875091940649202106109066788663807627887433701124817799811432100659519242101309","3499986"
    );
    my $P = shift || $DECIMALS;
    my $x = Math::BigFloat->new( $bernoulli[ $n - 2 ] );
    my $y = Math::BigFloat->new( $bernoulli[ $n - 1 ] );
    return wantarray ? ( $x, $y ) : $x->bdiv( $y )->bfround( -$P );
}

1;
__END__

=head1 NAME

Math::NumberCruncher - Collection of useful math-related functions.

=head1 AUTHOR

Kurt Kincaid <sifukurt@yahoo.com>
