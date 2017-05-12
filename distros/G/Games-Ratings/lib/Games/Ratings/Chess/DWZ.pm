package Games::Ratings::Chess::DWZ;

## TODO: check arguments for subroutines (use Data::Checkers)?
## TODO: Error handling
##       * croak()
##       * adjust perldoc
## TODO: what to do with opponents without a DWZ rating?
## TODO: what to do if player doesn't have a DWZ rating yet?

use strict;
use warnings;
use Carp;

use 5.6.1;               # 'our' was introduced in perl 5.6
use version; our $VERSION = qv('0.0.5');

## look in Games::Ratings for methods not provide by this package
use base qw ( Games::Ratings );

## scoring probabilities depending from rating difference
our %scoring_probability_lookup_table;
_set_scoring_probability_lookup_table();

## lookup table needed to determine performance (Turnierleistung)
our %reverse_scoring_probability_lookup_table ;
_set_reverse_scoring_probability_lookup_table();

## values of iteration runs -- used to abort infinite loops
my %iteration_values_seen;

## calculate rating change
sub get_rating_change {
    my ($self) = @_;

    ## $W -- scored points (erzielte Punkte)
    my $W = $self->get_points_scored();
    
    ## $W_e -- expected points (Punkterwartung)
    my $W_e = $self->get_points_expected();

    ## $n -- number of games played
    my $n = $self->get_number_of_games_played();

    ## check whether development coefficient is provided -- guess otherwise
    my $coefficient = $self->get_coefficient();
    if ( ! defined $coefficient ) {
        $coefficient = _guess_coefficient( $self->get_rating() );
    }

    ## rating change
    my $rating_change = (800*( $W-$W_e )) / ( $coefficient+$n );
    
    ## return total rating change
    return $rating_change;
}

## calculate new rating (neue Wertzahl)
sub get_new_rating {
    my ($self) = @_;

    ## $R_o -- rating old (alte Wertzahl)
    my $R_o = $self->get_rating();

    ## $R_n -- rating new (rounded)
    my $R_n = sprintf( "%.f", $R_o + $self->get_rating_change() );

    ## return new rating
    return $R_n;
}

## calculate expected points (Punkterwartung)
sub get_points_expected {
    my ($self) = @_;
    
    ## $W_e -- expected points
    my $W_e;

    ## $A_rating -- own rating
    my $own_rating = $self->get_rating();
    
    ## sum up expected points for all games
    foreach my $game_ref ( $self->get_all_games() ) {
        $W_e += _get_scoring_probability(
                    $own_rating,
                    $game_ref->{opponent_rating},
                );
    }

    ## return expected points
    return sprintf("%.3f", $W_e);
}

## calculate performance (Turnierleistung)
sub get_performance {
    my ($self) = @_;

    ## $R_h -- performance (independent from old rating)
    my $R_h;

    ## $W -- points scored (Punkte)
    my $W = $self->get_points_scored();

    ## $n -- number of games played (Anzahl der Partien)
    my $n = $self->get_number_of_games_played();

    ## $R_c -- average rating of opponents
    my $R_c = $self->get_average_rating_of_opponents();

    ## $P -- percentage score (Gewinnanteil) -- three digits needed
    my $P = sprintf( "%.3f", $self->get_percentage_score() );

    ## if player scored 100 % or 0 % it's not possible to calc. performance
    if ($P == 1) {
        $R_h = $R_c + 667;
        return $R_h;
    }
    if ($P == 0) {
        $R_h = $R_c - 667;
        return $R_h;
    }

    ## lookup D (Wertungsdifferenz) according to $P from probability table
    my $D = _get_rating_difference_matching_percentage_score($P);

    ## temporarily changing rating of $self to be able to use methods
    ## it will be restored just before returning from this subroutine
    my $old_rating = $self->get_rating();

    ## $R_p -- first approximation of performance
    my $R_p = $R_c + $D;
    $self->set_rating($R_p);

    ## iterative process to calculate actual performance
    while ('1') {
        ## calculate W_e (expected points) with approximated performance
        my $W_e = $self->get_points_expected();

        ## $PD -- measure of difference between points scored and expected
        ##        points (if player's rating would have been = performance)
        my $PD = sprintf("%.3f", ($W - $W_e) / $n + 0.5);

        ## $iteration_id -- measures distance between $W and $W_e
        ##                  stop iteration if encountered second time
        my $iteration_id;
        if ( $W > $W_e ) {
            $iteration_id = sprintf("%.3f", $W - $W_e);
        }
        else {
            $iteration_id = sprintf("%.3f", $W_e - $W);
        }

        ## do we have to end iteration?
        my $stop_iteration = 0;
        ## was there already a run with same values
        if ( $iteration_values_seen{$iteration_id}++ ) {
            $stop_iteration = 1; 
        }

        ## end of iterative process
        if ( ( $PD == 0.5 ) or ( $stop_iteration ) ) {
            ## assign performance == temporarily changed rating
            $R_h = $self->get_rating();
            ## restore original rating
            $self->set_rating($old_rating);
            ## quit get_performanc() and return performance
            return $R_h;
        }

        ## lookup $D (rating diff.) according to $PD from probability table
        $D = _get_rating_difference_matching_percentage_score($PD);

        ## adjust own rating to approximated performance (temporarily)
        $self->set_rating( $self->get_rating() + $D );
    }
}

########################
## internal functions ##
########################

## calculate rating differences matching percentage score
## (used for iterative calculation of performance)
sub _get_rating_difference_matching_percentage_score {
    my ($P) = @_;

    ## lookup $D (rating difference, Wertungsdifferenz) from lookup table
    my $D;
    if ($P lt 0.5) {
        $D = -($reverse_scoring_probability_lookup_table{sprintf("%.3f",1-$P)});
    }
    else {
        $D = $reverse_scoring_probability_lookup_table{$P};
    }

    ## return $D
    return $D;
}

## calculate scoring probability (Gewinnerwartung) for a single game
sub _get_scoring_probability {
    my ($A_rating, $B_rating) = @_;

    ## determine rating difference
    my $rating_difference = _get_rating_difference($A_rating,$B_rating);

    ## get scoring probability of player A from lookup table 
    my $A_exp;
    if ($rating_difference >= 0) {
        $A_exp = $scoring_probability_lookup_table{$rating_difference};
    }
    else {
        $A_exp = 1 - $scoring_probability_lookup_table{0-$rating_difference};
    }

    ## return scoring probabilities for player A
    return $A_exp;
}

## try to guess development coefficient
sub _guess_coefficient {
    my ($player_rating) = @_;

    ## guess coefficient according to rating (cmp. Wertungsord. Appendix 2.4)
    ## http://www.schachbund.de/dwz/wo/anhang_2-4.html
    ## THIS IS JUST A ROUGH GUESS! It is assumed that player is 
    ## more than 25 years old and she has played more than five tournaments.
    ## There will be errors for younger players or players with only a few 
    ## tournaments played!
    my $player_coefficient;
    if ($player_rating <= 840) {
        $player_coefficient = 15;
    }
    elsif ($player_rating <= 1106) {
        $player_coefficient = 16;
    }
    elsif ($player_rating <= 1257) {
        $player_coefficient = 17;
    }
    elsif ($player_rating <= 1367) {
        $player_coefficient = 18;
    }
    elsif ($player_rating <= 1456) {
        $player_coefficient = 19;
    }
    elsif ($player_rating <= 1531) {
        $player_coefficient = 20;
    }
    elsif ($player_rating <= 1596) {
        $player_coefficient = 21;
    }
    elsif ($player_rating <= 1654) {
        $player_coefficient = 22;
    }
    elsif ($player_rating <= 1707) {
        $player_coefficient = 23;
    }
    elsif ($player_rating <= 1755) {
        $player_coefficient = 24;
    }
    elsif ($player_rating <= 1800) {
        $player_coefficient = 25;
    }
    elsif ($player_rating <= 1841) {
        $player_coefficient = 26;
    }
    elsif ($player_rating <= 1880) {
        $player_coefficient = 27;
    }
    elsif ($player_rating <= 1916) {
        $player_coefficient = 28;
    }
    elsif ($player_rating <= 1951) {
        $player_coefficient = 29;
    }
    else {
        $player_coefficient = 30;
    }

    ## return guessed coefficient
    return $player_coefficient;
}

## calculate rating difference which is used to calc the scoring probability
sub _get_rating_difference {
    my ($A, $B) = @_;

    ## compute real rating difference
    my $rating_difference = ( $A-$B );

    ## large rating differences are cut to 735 (cmp. lookup table)
    if ($rating_difference >= '735') {
        $rating_difference = '735';
    }
    if ($rating_difference <= '-735') {
        $rating_difference = '-735';
    }

    ## return rating difference used for rating calculations
    return $rating_difference;
}

## lookup table (scoring probability depending on rating difference)  
## table with three post decimal positions
## Official Wertungsordnung (http://www.schachbund.de/dwz/wo/index.html)
## gives tables with only two post decimal positions.
## But ELOBASE (the closed source software used for official calculations)
## uses the following table!
sub _set_scoring_probability_lookup_table {
    ## use hash as lookup table for scoring probability
    $scoring_probability_lookup_table{0}   = '0.500';
    $scoring_probability_lookup_table{1}   = '0.501';
    $scoring_probability_lookup_table{2}   = '0.503';
    $scoring_probability_lookup_table{3}   = '0.504';
    $scoring_probability_lookup_table{4}   = '0.506';
    $scoring_probability_lookup_table{5}   = '0.507';
    $scoring_probability_lookup_table{6}   = '0.508';
    $scoring_probability_lookup_table{7}   = '0.510';
    $scoring_probability_lookup_table{8}   = '0.511';
    $scoring_probability_lookup_table{9}   = '0.513';
    $scoring_probability_lookup_table{10}  = '0.514';
    $scoring_probability_lookup_table{11}  = '0.516';
    $scoring_probability_lookup_table{12}  = '0.517';
    $scoring_probability_lookup_table{13}  = '0.518';
    $scoring_probability_lookup_table{14}  = '0.520';
    $scoring_probability_lookup_table{15}  = '0.521';
    $scoring_probability_lookup_table{16}  = '0.523';
    $scoring_probability_lookup_table{17}  = '0.524';
    $scoring_probability_lookup_table{18}  = '0.525';
    $scoring_probability_lookup_table{19}  = '0.527';
    $scoring_probability_lookup_table{20}  = '0.528';
    $scoring_probability_lookup_table{21}  = '0.530';
    $scoring_probability_lookup_table{22}  = '0.531';
    $scoring_probability_lookup_table{23}  = '0.532';
    $scoring_probability_lookup_table{24}  = '0.534';
    $scoring_probability_lookup_table{25}  = '0.535';
    $scoring_probability_lookup_table{26}  = '0.537';
    $scoring_probability_lookup_table{27}  = '0.538';
    $scoring_probability_lookup_table{28}  = '0.539';
    $scoring_probability_lookup_table{29}  = '0.541';
    $scoring_probability_lookup_table{30}  = '0.542';
    $scoring_probability_lookup_table{31}  = '0.544';
    $scoring_probability_lookup_table{32}  = '0.545';
    $scoring_probability_lookup_table{33}  = '0.546';
    $scoring_probability_lookup_table{34}  = '0.548';
    $scoring_probability_lookup_table{35}  = '0.549';
    $scoring_probability_lookup_table{36}  = '0.551';
    $scoring_probability_lookup_table{37}  = '0.552';
    $scoring_probability_lookup_table{38}  = '0.553';
    $scoring_probability_lookup_table{39}  = '0.555';
    $scoring_probability_lookup_table{40}  = '0.556';
    $scoring_probability_lookup_table{41}  = '0.558';
    $scoring_probability_lookup_table{42}  = '0.559';
    $scoring_probability_lookup_table{43}  = '0.560';
    $scoring_probability_lookup_table{44}  = '0.562';
    $scoring_probability_lookup_table{45}  = '0.563';
    $scoring_probability_lookup_table{46}  = '0.565';
    $scoring_probability_lookup_table{47}  = '0.566';
    $scoring_probability_lookup_table{48}  = '0.567';
    $scoring_probability_lookup_table{49}  = '0.569';
    $scoring_probability_lookup_table{50}  = '0.570';
    $scoring_probability_lookup_table{51}  = '0.572';
    $scoring_probability_lookup_table{52}  = '0.573';
    $scoring_probability_lookup_table{53}  = '0.574';
    $scoring_probability_lookup_table{54}  = '0.576';
    $scoring_probability_lookup_table{55}  = '0.577';
    $scoring_probability_lookup_table{56}  = '0.578';
    $scoring_probability_lookup_table{57}  = '0.580';
    $scoring_probability_lookup_table{58}  = '0.581';
    $scoring_probability_lookup_table{59}  = '0.583';
    $scoring_probability_lookup_table{60}  = '0.584';
    $scoring_probability_lookup_table{61}  = '0.585';
    $scoring_probability_lookup_table{62}  = '0.587';
    $scoring_probability_lookup_table{63}  = '0.588';
    $scoring_probability_lookup_table{64}  = '0.590';
    $scoring_probability_lookup_table{65}  = '0.591';
    $scoring_probability_lookup_table{66}  = '0.592';
    $scoring_probability_lookup_table{67}  = '0.594';
    $scoring_probability_lookup_table{68}  = '0.595';
    $scoring_probability_lookup_table{69}  = '0.596';
    $scoring_probability_lookup_table{70}  = '0.598';
    $scoring_probability_lookup_table{71}  = '0.599';
    $scoring_probability_lookup_table{72}  = '0.600';
    $scoring_probability_lookup_table{73}  = '0.602';
    $scoring_probability_lookup_table{74}  = '0.603';
    $scoring_probability_lookup_table{75}  = '0.605';
    $scoring_probability_lookup_table{76}  = '0.606';
    $scoring_probability_lookup_table{77}  = '0.607';
    $scoring_probability_lookup_table{78}  = '0.609';
    $scoring_probability_lookup_table{79}  = '0.610';
    $scoring_probability_lookup_table{80}  = '0.611';
    $scoring_probability_lookup_table{81}  = '0.613';
    $scoring_probability_lookup_table{82}  = '0.614';
    $scoring_probability_lookup_table{83}  = '0.615';
    $scoring_probability_lookup_table{84}  = '0.617';
    $scoring_probability_lookup_table{85}  = '0.618';
    $scoring_probability_lookup_table{86}  = '0.619';
    $scoring_probability_lookup_table{87}  = '0.621';
    $scoring_probability_lookup_table{88}  = '0.622';
    $scoring_probability_lookup_table{89}  = '0.623';
    $scoring_probability_lookup_table{90}  = '0.625';
    $scoring_probability_lookup_table{91}  = '0.626';
    $scoring_probability_lookup_table{92}  = '0.628';
    $scoring_probability_lookup_table{93}  = '0.629';
    $scoring_probability_lookup_table{94}  = '0.630';
    $scoring_probability_lookup_table{95}  = '0.632';
    $scoring_probability_lookup_table{96}  = '0.633';
    $scoring_probability_lookup_table{97}  = '0.634';
    $scoring_probability_lookup_table{98}  = '0.636';
    $scoring_probability_lookup_table{99}  = '0.637';
    $scoring_probability_lookup_table{100} = '0.638';
    $scoring_probability_lookup_table{101} = '0.639';
    $scoring_probability_lookup_table{102} = '0.641';
    $scoring_probability_lookup_table{103} = '0.642';
    $scoring_probability_lookup_table{104} = '0.643';
    $scoring_probability_lookup_table{105} = '0.645';
    $scoring_probability_lookup_table{106} = '0.646';
    $scoring_probability_lookup_table{107} = '0.647';
    $scoring_probability_lookup_table{108} = '0.649';
    $scoring_probability_lookup_table{109} = '0.650';
    $scoring_probability_lookup_table{110} = '0.651';
    $scoring_probability_lookup_table{111} = '0.653';
    $scoring_probability_lookup_table{112} = '0.654';
    $scoring_probability_lookup_table{113} = '0.655';
    $scoring_probability_lookup_table{114} = '0.657';
    $scoring_probability_lookup_table{115} = '0.658';
    $scoring_probability_lookup_table{116} = '0.659';
    $scoring_probability_lookup_table{117} = '0.660';
    $scoring_probability_lookup_table{118} = '0.662';
    $scoring_probability_lookup_table{119} = '0.663';
    $scoring_probability_lookup_table{120} = '0.664';
    $scoring_probability_lookup_table{121} = '0.666';
    $scoring_probability_lookup_table{122} = '0.667';
    $scoring_probability_lookup_table{123} = '0.668';
    $scoring_probability_lookup_table{124} = '0.669';
    $scoring_probability_lookup_table{125} = '0.671';
    $scoring_probability_lookup_table{126} = '0.672';
    $scoring_probability_lookup_table{127} = '0.673';
    $scoring_probability_lookup_table{128} = '0.675';
    $scoring_probability_lookup_table{129} = '0.676';
    $scoring_probability_lookup_table{130} = '0.677';
    $scoring_probability_lookup_table{131} = '0.678';
    $scoring_probability_lookup_table{132} = '0.680';
    $scoring_probability_lookup_table{133} = '0.681';
    $scoring_probability_lookup_table{134} = '0.682';
    $scoring_probability_lookup_table{135} = '0.683';
    $scoring_probability_lookup_table{136} = '0.685';
    $scoring_probability_lookup_table{137} = '0.686';
    $scoring_probability_lookup_table{138} = '0.687';
    $scoring_probability_lookup_table{139} = '0.688';
    $scoring_probability_lookup_table{140} = '0.690';
    $scoring_probability_lookup_table{141} = '0.691';
    $scoring_probability_lookup_table{142} = '0.692';
    $scoring_probability_lookup_table{143} = '0.693';
    $scoring_probability_lookup_table{144} = '0.695';
    $scoring_probability_lookup_table{145} = '0.696';
    $scoring_probability_lookup_table{146} = '0.697';
    $scoring_probability_lookup_table{147} = '0.698';
    $scoring_probability_lookup_table{148} = '0.700';
    $scoring_probability_lookup_table{149} = '0.701';
    $scoring_probability_lookup_table{150} = '0.702';
    $scoring_probability_lookup_table{151} = '0.703';
    $scoring_probability_lookup_table{152} = '0.705';
    $scoring_probability_lookup_table{153} = '0.706';
    $scoring_probability_lookup_table{154} = '0.707';
    $scoring_probability_lookup_table{155} = '0.708';
    $scoring_probability_lookup_table{156} = '0.709';
    $scoring_probability_lookup_table{157} = '0.711';
    $scoring_probability_lookup_table{158} = '0.712';
    $scoring_probability_lookup_table{159} = '0.713';
    $scoring_probability_lookup_table{160} = '0.714';
    $scoring_probability_lookup_table{161} = '0.715';
    $scoring_probability_lookup_table{162} = '0.717';
    $scoring_probability_lookup_table{163} = '0.718';
    $scoring_probability_lookup_table{164} = '0.719';
    $scoring_probability_lookup_table{165} = '0.720';
    $scoring_probability_lookup_table{166} = '0.721';
    $scoring_probability_lookup_table{167} = '0.723';
    $scoring_probability_lookup_table{168} = '0.724';
    $scoring_probability_lookup_table{169} = '0.725';
    $scoring_probability_lookup_table{170} = '0.726';
    $scoring_probability_lookup_table{171} = '0.727';
    $scoring_probability_lookup_table{172} = '0.728';
    $scoring_probability_lookup_table{173} = '0.730';
    $scoring_probability_lookup_table{174} = '0.731';
    $scoring_probability_lookup_table{175} = '0.732';
    $scoring_probability_lookup_table{176} = '0.733';
    $scoring_probability_lookup_table{177} = '0.734';
    $scoring_probability_lookup_table{178} = '0.735';
    $scoring_probability_lookup_table{179} = '0.737';
    $scoring_probability_lookup_table{180} = '0.738';
    $scoring_probability_lookup_table{181} = '0.739';
    $scoring_probability_lookup_table{182} = '0.740';
    $scoring_probability_lookup_table{183} = '0.741';
    $scoring_probability_lookup_table{184} = '0.742';
    $scoring_probability_lookup_table{185} = '0.743';
    $scoring_probability_lookup_table{186} = '0.745';
    $scoring_probability_lookup_table{187} = '0.746';
    $scoring_probability_lookup_table{188} = '0.747';
    $scoring_probability_lookup_table{189} = '0.748';
    $scoring_probability_lookup_table{190} = '0.749';
    $scoring_probability_lookup_table{191} = '0.750';
    $scoring_probability_lookup_table{192} = '0.751';
    $scoring_probability_lookup_table{193} = '0.752';
    $scoring_probability_lookup_table{194} = '0.754';
    $scoring_probability_lookup_table{195} = '0.755';
    $scoring_probability_lookup_table{196} = '0.756';
    $scoring_probability_lookup_table{197} = '0.757';
    $scoring_probability_lookup_table{198} = '0.758';
    $scoring_probability_lookup_table{199} = '0.759';
    $scoring_probability_lookup_table{200} = '0.760';
    $scoring_probability_lookup_table{201} = '0.761';
    $scoring_probability_lookup_table{202} = '0.762';
    $scoring_probability_lookup_table{203} = '0.764';
    $scoring_probability_lookup_table{204} = '0.765';
    $scoring_probability_lookup_table{205} = '0.766';
    $scoring_probability_lookup_table{206} = '0.767';
    $scoring_probability_lookup_table{207} = '0.768';
    $scoring_probability_lookup_table{208} = '0.769';
    $scoring_probability_lookup_table{209} = '0.770';
    $scoring_probability_lookup_table{210} = '0.771';
    $scoring_probability_lookup_table{211} = '0.772';
    $scoring_probability_lookup_table{212} = '0.773';
    $scoring_probability_lookup_table{213} = '0.774';
    $scoring_probability_lookup_table{214} = '0.775';
    $scoring_probability_lookup_table{215} = '0.776';
    $scoring_probability_lookup_table{216} = '0.777';
    $scoring_probability_lookup_table{217} = '0.779';
    $scoring_probability_lookup_table{218} = '0.780';
    $scoring_probability_lookup_table{219} = '0.781';
    $scoring_probability_lookup_table{220} = '0.782';
    $scoring_probability_lookup_table{221} = '0.783';
    $scoring_probability_lookup_table{222} = '0.784';
    $scoring_probability_lookup_table{223} = '0.785';
    $scoring_probability_lookup_table{224} = '0.786';
    $scoring_probability_lookup_table{225} = '0.787';
    $scoring_probability_lookup_table{226} = '0.788';
    $scoring_probability_lookup_table{227} = '0.789';
    $scoring_probability_lookup_table{228} = '0.790';
    $scoring_probability_lookup_table{229} = '0.791';
    $scoring_probability_lookup_table{230} = '0.792';
    $scoring_probability_lookup_table{231} = '0.793';
    $scoring_probability_lookup_table{232} = '0.794';
    $scoring_probability_lookup_table{233} = '0.795';
    $scoring_probability_lookup_table{234} = '0.796';
    $scoring_probability_lookup_table{235} = '0.797';
    $scoring_probability_lookup_table{236} = '0.798';
    $scoring_probability_lookup_table{237} = '0.799';
    $scoring_probability_lookup_table{238} = '0.800';
    $scoring_probability_lookup_table{239} = '0.801';
    $scoring_probability_lookup_table{240} = '0.802';
    $scoring_probability_lookup_table{241} = '0.803';
    $scoring_probability_lookup_table{242} = '0.804';
    $scoring_probability_lookup_table{243} = '0.805';
    $scoring_probability_lookup_table{244} = '0.806';
    $scoring_probability_lookup_table{245} = '0.807';
    $scoring_probability_lookup_table{246} = '0.808';
    $scoring_probability_lookup_table{247} = '0.809';
    $scoring_probability_lookup_table{248} = '0.810';
    $scoring_probability_lookup_table{249} = '0.811';
    $scoring_probability_lookup_table{250} = '0.812';
    $scoring_probability_lookup_table{251} = '0.813';
    $scoring_probability_lookup_table{252} = '0.814';
    $scoring_probability_lookup_table{253} = '0.814';
    $scoring_probability_lookup_table{254} = '0.815';
    $scoring_probability_lookup_table{255} = '0.816';
    $scoring_probability_lookup_table{256} = '0.817';
    $scoring_probability_lookup_table{257} = '0.818';
    $scoring_probability_lookup_table{258} = '0.819';
    $scoring_probability_lookup_table{259} = '0.820';
    $scoring_probability_lookup_table{260} = '0.821';
    $scoring_probability_lookup_table{261} = '0.822';
    $scoring_probability_lookup_table{262} = '0.823';
    $scoring_probability_lookup_table{263} = '0.824';
    $scoring_probability_lookup_table{264} = '0.825';
    $scoring_probability_lookup_table{265} = '0.826';
    $scoring_probability_lookup_table{266} = '0.827';
    $scoring_probability_lookup_table{267} = '0.827';
    $scoring_probability_lookup_table{268} = '0.828';
    $scoring_probability_lookup_table{269} = '0.829';
    $scoring_probability_lookup_table{270} = '0.830';
    $scoring_probability_lookup_table{271} = '0.831';
    $scoring_probability_lookup_table{272} = '0.832';
    $scoring_probability_lookup_table{273} = '0.833';
    $scoring_probability_lookup_table{274} = '0.834';
    $scoring_probability_lookup_table{275} = '0.835';
    $scoring_probability_lookup_table{276} = '0.835';
    $scoring_probability_lookup_table{277} = '0.836';
    $scoring_probability_lookup_table{278} = '0.837';
    $scoring_probability_lookup_table{279} = '0.838';
    $scoring_probability_lookup_table{280} = '0.839';
    $scoring_probability_lookup_table{281} = '0.840';
    $scoring_probability_lookup_table{282} = '0.841';
    $scoring_probability_lookup_table{283} = '0.841';
    $scoring_probability_lookup_table{284} = '0.842';
    $scoring_probability_lookup_table{285} = '0.843';
    $scoring_probability_lookup_table{286} = '0.844';
    $scoring_probability_lookup_table{287} = '0.845';
    $scoring_probability_lookup_table{288} = '0.846';
    $scoring_probability_lookup_table{289} = '0.847';
    $scoring_probability_lookup_table{290} = '0.847';
    $scoring_probability_lookup_table{291} = '0.848';
    $scoring_probability_lookup_table{292} = '0.849';
    $scoring_probability_lookup_table{293} = '0.850';
    $scoring_probability_lookup_table{294} = '0.851';
    $scoring_probability_lookup_table{295} = '0.852';
    $scoring_probability_lookup_table{296} = '0.852';
    $scoring_probability_lookup_table{297} = '0.853';
    $scoring_probability_lookup_table{298} = '0.854';
    $scoring_probability_lookup_table{299} = '0.855';
    $scoring_probability_lookup_table{300} = '0.856';
    $scoring_probability_lookup_table{301} = '0.856';
    $scoring_probability_lookup_table{302} = '0.857';
    $scoring_probability_lookup_table{303} = '0.858';
    $scoring_probability_lookup_table{304} = '0.859';
    $scoring_probability_lookup_table{305} = '0.860';
    $scoring_probability_lookup_table{306} = '0.860';
    $scoring_probability_lookup_table{307} = '0.861';
    $scoring_probability_lookup_table{308} = '0.862';
    $scoring_probability_lookup_table{309} = '0.863';
    $scoring_probability_lookup_table{310} = '0.863';
    $scoring_probability_lookup_table{311} = '0.864';
    $scoring_probability_lookup_table{312} = '0.865';
    $scoring_probability_lookup_table{313} = '0.866';
    $scoring_probability_lookup_table{314} = '0.867';
    $scoring_probability_lookup_table{315} = '0.867';
    $scoring_probability_lookup_table{316} = '0.868';
    $scoring_probability_lookup_table{317} = '0.869';
    $scoring_probability_lookup_table{318} = '0.870';
    $scoring_probability_lookup_table{319} = '0.870';
    $scoring_probability_lookup_table{320} = '0.871';
    $scoring_probability_lookup_table{321} = '0.872';
    $scoring_probability_lookup_table{322} = '0.873';
    $scoring_probability_lookup_table{323} = '0.873';
    $scoring_probability_lookup_table{324} = '0.874';
    $scoring_probability_lookup_table{325} = '0.875';
    $scoring_probability_lookup_table{326} = '0.875';
    $scoring_probability_lookup_table{327} = '0.876';
    $scoring_probability_lookup_table{328} = '0.877';
    $scoring_probability_lookup_table{329} = '0.878';
    $scoring_probability_lookup_table{330} = '0.878';
    $scoring_probability_lookup_table{331} = '0.879';
    $scoring_probability_lookup_table{332} = '0.880';
    $scoring_probability_lookup_table{333} = '0.880';
    $scoring_probability_lookup_table{334} = '0.881';
    $scoring_probability_lookup_table{335} = '0.882';
    $scoring_probability_lookup_table{336} = '0.883';
    $scoring_probability_lookup_table{337} = '0.883';
    $scoring_probability_lookup_table{338} = '0.884';
    $scoring_probability_lookup_table{339} = '0.885';
    $scoring_probability_lookup_table{340} = '0.885';
    $scoring_probability_lookup_table{341} = '0.886';
    $scoring_probability_lookup_table{342} = '0.887';
    $scoring_probability_lookup_table{343} = '0.887';
    $scoring_probability_lookup_table{344} = '0.888';
    $scoring_probability_lookup_table{345} = '0.889';
    $scoring_probability_lookup_table{346} = '0.889';
    $scoring_probability_lookup_table{347} = '0.890';
    $scoring_probability_lookup_table{348} = '0.891';
    $scoring_probability_lookup_table{349} = '0.891';
    $scoring_probability_lookup_table{350} = '0.892';
    $scoring_probability_lookup_table{351} = '0.893';
    $scoring_probability_lookup_table{352} = '0.893';
    $scoring_probability_lookup_table{353} = '0.894';
    $scoring_probability_lookup_table{354} = '0.895';
    $scoring_probability_lookup_table{355} = '0.895';
    $scoring_probability_lookup_table{356} = '0.896';
    $scoring_probability_lookup_table{357} = '0.897';
    $scoring_probability_lookup_table{358} = '0.897';
    $scoring_probability_lookup_table{359} = '0.898';
    $scoring_probability_lookup_table{360} = '0.898';
    $scoring_probability_lookup_table{361} = '0.899';
    $scoring_probability_lookup_table{362} = '0.900';
    $scoring_probability_lookup_table{363} = '0.900';
    $scoring_probability_lookup_table{364} = '0.901';
    $scoring_probability_lookup_table{365} = '0.902';
    $scoring_probability_lookup_table{366} = '0.902';
    $scoring_probability_lookup_table{367} = '0.903';
    $scoring_probability_lookup_table{368} = '0.903';
    $scoring_probability_lookup_table{369} = '0.904';
    $scoring_probability_lookup_table{370} = '0.905';
    $scoring_probability_lookup_table{371} = '0.905';
    $scoring_probability_lookup_table{372} = '0.906';
    $scoring_probability_lookup_table{373} = '0.906';
    $scoring_probability_lookup_table{374} = '0.907';
    $scoring_probability_lookup_table{375} = '0.908';
    $scoring_probability_lookup_table{376} = '0.908';
    $scoring_probability_lookup_table{377} = '0.909';
    $scoring_probability_lookup_table{378} = '0.909';
    $scoring_probability_lookup_table{379} = '0.910';
    $scoring_probability_lookup_table{380} = '0.910';
    $scoring_probability_lookup_table{381} = '0.911';
    $scoring_probability_lookup_table{382} = '0.912';
    $scoring_probability_lookup_table{383} = '0.912';
    $scoring_probability_lookup_table{384} = '0.913';
    $scoring_probability_lookup_table{385} = '0.913';
    $scoring_probability_lookup_table{386} = '0.914';
    $scoring_probability_lookup_table{387} = '0.914';
    $scoring_probability_lookup_table{388} = '0.915';
    $scoring_probability_lookup_table{389} = '0.915';
    $scoring_probability_lookup_table{390} = '0.916';
    $scoring_probability_lookup_table{391} = '0.917';
    $scoring_probability_lookup_table{392} = '0.917';
    $scoring_probability_lookup_table{393} = '0.918';
    $scoring_probability_lookup_table{394} = '0.918';
    $scoring_probability_lookup_table{395} = '0.919';
    $scoring_probability_lookup_table{396} = '0.919';
    $scoring_probability_lookup_table{397} = '0.920';
    $scoring_probability_lookup_table{398} = '0.920';
    $scoring_probability_lookup_table{399} = '0.921';
    $scoring_probability_lookup_table{400} = '0.921';
    $scoring_probability_lookup_table{401} = '0.922';
    $scoring_probability_lookup_table{402} = '0.922';
    $scoring_probability_lookup_table{403} = '0.923';
    $scoring_probability_lookup_table{404} = '0.923';
    $scoring_probability_lookup_table{405} = '0.924';
    $scoring_probability_lookup_table{406} = '0.924';
    $scoring_probability_lookup_table{407} = '0.925';
    $scoring_probability_lookup_table{408} = '0.925';
    $scoring_probability_lookup_table{409} = '0.926';
    $scoring_probability_lookup_table{410} = '0.926';
    $scoring_probability_lookup_table{411} = '0.927';
    $scoring_probability_lookup_table{412} = '0.927';
    $scoring_probability_lookup_table{413} = '0.928';
    $scoring_probability_lookup_table{414} = '0.928';
    $scoring_probability_lookup_table{415} = '0.929';
    $scoring_probability_lookup_table{416} = '0.929';
    $scoring_probability_lookup_table{417} = '0.930';
    $scoring_probability_lookup_table{418} = '0.930';
    $scoring_probability_lookup_table{419} = '0.931';
    $scoring_probability_lookup_table{420} = '0.931';
    $scoring_probability_lookup_table{421} = '0.932';
    $scoring_probability_lookup_table{422} = '0.932';
    $scoring_probability_lookup_table{423} = '0.933';
    $scoring_probability_lookup_table{424} = '0.933';
    $scoring_probability_lookup_table{425} = '0.934';
    $scoring_probability_lookup_table{426} = '0.934';
    $scoring_probability_lookup_table{427} = '0.934';
    $scoring_probability_lookup_table{428} = '0.935';
    $scoring_probability_lookup_table{429} = '0.935';
    $scoring_probability_lookup_table{430} = '0.936';
    $scoring_probability_lookup_table{431} = '0.936';
    $scoring_probability_lookup_table{432} = '0.937';
    $scoring_probability_lookup_table{433} = '0.937';
    $scoring_probability_lookup_table{434} = '0.938';
    $scoring_probability_lookup_table{435} = '0.938';
    $scoring_probability_lookup_table{436} = '0.938';
    $scoring_probability_lookup_table{437} = '0.939';
    $scoring_probability_lookup_table{438} = '0.939';
    $scoring_probability_lookup_table{439} = '0.940';
    $scoring_probability_lookup_table{440} = '0.940';
    $scoring_probability_lookup_table{441} = '0.941';
    $scoring_probability_lookup_table{442} = '0.941';
    $scoring_probability_lookup_table{443} = '0.941';
    $scoring_probability_lookup_table{444} = '0.942';
    $scoring_probability_lookup_table{445} = '0.942';
    $scoring_probability_lookup_table{446} = '0.943';
    $scoring_probability_lookup_table{447} = '0.943';
    $scoring_probability_lookup_table{448} = '0.943';
    $scoring_probability_lookup_table{449} = '0.944';
    $scoring_probability_lookup_table{450} = '0.944';
    $scoring_probability_lookup_table{451} = '0.945';
    $scoring_probability_lookup_table{452} = '0.945';
    $scoring_probability_lookup_table{453} = '0.945';
    $scoring_probability_lookup_table{454} = '0.946';
    $scoring_probability_lookup_table{455} = '0.946';
    $scoring_probability_lookup_table{456} = '0.947';
    $scoring_probability_lookup_table{457} = '0.947';
    $scoring_probability_lookup_table{458} = '0.947';
    $scoring_probability_lookup_table{459} = '0.948';
    $scoring_probability_lookup_table{460} = '0.948';
    $scoring_probability_lookup_table{461} = '0.948';
    $scoring_probability_lookup_table{462} = '0.949';
    $scoring_probability_lookup_table{463} = '0.949';
    $scoring_probability_lookup_table{464} = '0.950';
    $scoring_probability_lookup_table{465} = '0.950';
    $scoring_probability_lookup_table{466} = '0.950';
    $scoring_probability_lookup_table{467} = '0.951';
    $scoring_probability_lookup_table{468} = '0.951';
    $scoring_probability_lookup_table{469} = '0.951';
    $scoring_probability_lookup_table{470} = '0.952';
    $scoring_probability_lookup_table{471} = '0.952';
    $scoring_probability_lookup_table{472} = '0.952';
    $scoring_probability_lookup_table{473} = '0.953';
    $scoring_probability_lookup_table{474} = '0.953';
    $scoring_probability_lookup_table{475} = '0.953';
    $scoring_probability_lookup_table{476} = '0.954';
    $scoring_probability_lookup_table{477} = '0.954';
    $scoring_probability_lookup_table{478} = '0.954';
    $scoring_probability_lookup_table{479} = '0.955';
    $scoring_probability_lookup_table{480} = '0.955';
    $scoring_probability_lookup_table{481} = '0.955';
    $scoring_probability_lookup_table{482} = '0.956';
    $scoring_probability_lookup_table{483} = '0.956';
    $scoring_probability_lookup_table{484} = '0.956';
    $scoring_probability_lookup_table{485} = '0.957';
    $scoring_probability_lookup_table{486} = '0.957';
    $scoring_probability_lookup_table{487} = '0.957';
    $scoring_probability_lookup_table{488} = '0.958';
    $scoring_probability_lookup_table{489} = '0.958';
    $scoring_probability_lookup_table{490} = '0.958';
    $scoring_probability_lookup_table{491} = '0.959';
    $scoring_probability_lookup_table{492} = '0.959';
    $scoring_probability_lookup_table{493} = '0.959';
    $scoring_probability_lookup_table{494} = '0.960';
    $scoring_probability_lookup_table{495} = '0.960';
    $scoring_probability_lookup_table{496} = '0.960';
    $scoring_probability_lookup_table{497} = '0.961';
    $scoring_probability_lookup_table{498} = '0.961';
    $scoring_probability_lookup_table{499} = '0.961';
    $scoring_probability_lookup_table{500} = '0.961';
    $scoring_probability_lookup_table{501} = '0.962';
    $scoring_probability_lookup_table{502} = '0.962';
    $scoring_probability_lookup_table{503} = '0.962';
    $scoring_probability_lookup_table{504} = '0.963';
    $scoring_probability_lookup_table{505} = '0.963';
    $scoring_probability_lookup_table{506} = '0.963';
    $scoring_probability_lookup_table{507} = '0.963';
    $scoring_probability_lookup_table{508} = '0.964';
    $scoring_probability_lookup_table{509} = '0.964';
    $scoring_probability_lookup_table{510} = '0.964';
    $scoring_probability_lookup_table{511} = '0.965';
    $scoring_probability_lookup_table{512} = '0.965';
    $scoring_probability_lookup_table{513} = '0.965';
    $scoring_probability_lookup_table{514} = '0.965';
    $scoring_probability_lookup_table{515} = '0.966';
    $scoring_probability_lookup_table{516} = '0.966';
    $scoring_probability_lookup_table{517} = '0.966';
    $scoring_probability_lookup_table{518} = '0.966';
    $scoring_probability_lookup_table{519} = '0.967';
    $scoring_probability_lookup_table{520} = '0.967';
    $scoring_probability_lookup_table{521} = '0.967';
    $scoring_probability_lookup_table{522} = '0.968';
    $scoring_probability_lookup_table{523} = '0.968';
    $scoring_probability_lookup_table{524} = '0.968';
    $scoring_probability_lookup_table{525} = '0.968';
    $scoring_probability_lookup_table{526} = '0.969';
    $scoring_probability_lookup_table{527} = '0.969';
    $scoring_probability_lookup_table{528} = '0.969';
    $scoring_probability_lookup_table{529} = '0.969';
    $scoring_probability_lookup_table{530} = '0.970';
    $scoring_probability_lookup_table{531} = '0.970';
    $scoring_probability_lookup_table{532} = '0.970';
    $scoring_probability_lookup_table{533} = '0.970';
    $scoring_probability_lookup_table{534} = '0.970';
    $scoring_probability_lookup_table{535} = '0.971';
    $scoring_probability_lookup_table{536} = '0.971';
    $scoring_probability_lookup_table{537} = '0.971';
    $scoring_probability_lookup_table{538} = '0.971';
    $scoring_probability_lookup_table{539} = '0.972';
    $scoring_probability_lookup_table{540} = '0.972';
    $scoring_probability_lookup_table{541} = '0.972';
    $scoring_probability_lookup_table{542} = '0.972';
    $scoring_probability_lookup_table{543} = '0.973';
    $scoring_probability_lookup_table{544} = '0.973';
    $scoring_probability_lookup_table{545} = '0.973';
    $scoring_probability_lookup_table{546} = '0.973';
    $scoring_probability_lookup_table{547} = '0.973';
    $scoring_probability_lookup_table{548} = '0.974';
    $scoring_probability_lookup_table{549} = '0.974';
    $scoring_probability_lookup_table{550} = '0.974';
    $scoring_probability_lookup_table{551} = '0.974';
    $scoring_probability_lookup_table{552} = '0.975';
    $scoring_probability_lookup_table{553} = '0.975';
    $scoring_probability_lookup_table{554} = '0.975';
    $scoring_probability_lookup_table{555} = '0.975';
    $scoring_probability_lookup_table{556} = '0.975';
    $scoring_probability_lookup_table{557} = '0.976';
    $scoring_probability_lookup_table{558} = '0.976';
    $scoring_probability_lookup_table{559} = '0.976';
    $scoring_probability_lookup_table{560} = '0.976';
    $scoring_probability_lookup_table{561} = '0.976';
    $scoring_probability_lookup_table{562} = '0.977';
    $scoring_probability_lookup_table{563} = '0.977';
    $scoring_probability_lookup_table{564} = '0.977';
    $scoring_probability_lookup_table{565} = '0.977';
    $scoring_probability_lookup_table{566} = '0.977';
    $scoring_probability_lookup_table{567} = '0.977';
    $scoring_probability_lookup_table{568} = '0.978';
    $scoring_probability_lookup_table{569} = '0.978';
    $scoring_probability_lookup_table{570} = '0.978';
    $scoring_probability_lookup_table{571} = '0.978';
    $scoring_probability_lookup_table{572} = '0.978';
    $scoring_probability_lookup_table{573} = '0.979';
    $scoring_probability_lookup_table{574} = '0.979';
    $scoring_probability_lookup_table{575} = '0.979';
    $scoring_probability_lookup_table{576} = '0.979';
    $scoring_probability_lookup_table{577} = '0.979';
    $scoring_probability_lookup_table{578} = '0.980';
    $scoring_probability_lookup_table{579} = '0.980';
    $scoring_probability_lookup_table{580} = '0.980';
    $scoring_probability_lookup_table{581} = '0.980';
    $scoring_probability_lookup_table{582} = '0.980';
    $scoring_probability_lookup_table{583} = '0.980';
    $scoring_probability_lookup_table{584} = '0.981';
    $scoring_probability_lookup_table{585} = '0.981';
    $scoring_probability_lookup_table{586} = '0.981';
    $scoring_probability_lookup_table{587} = '0.981';
    $scoring_probability_lookup_table{588} = '0.981';
    $scoring_probability_lookup_table{589} = '0.981';
    $scoring_probability_lookup_table{590} = '0.982';
    $scoring_probability_lookup_table{591} = '0.982';
    $scoring_probability_lookup_table{592} = '0.982';
    $scoring_probability_lookup_table{593} = '0.982';
    $scoring_probability_lookup_table{594} = '0.982';
    $scoring_probability_lookup_table{595} = '0.982';
    $scoring_probability_lookup_table{596} = '0.982';
    $scoring_probability_lookup_table{597} = '0.983';
    $scoring_probability_lookup_table{598} = '0.983';
    $scoring_probability_lookup_table{599} = '0.983';
    $scoring_probability_lookup_table{600} = '0.983';
    $scoring_probability_lookup_table{601} = '0.983';
    $scoring_probability_lookup_table{602} = '0.983';
    $scoring_probability_lookup_table{603} = '0.983';
    $scoring_probability_lookup_table{604} = '0.984';
    $scoring_probability_lookup_table{605} = '0.984';
    $scoring_probability_lookup_table{606} = '0.984';
    $scoring_probability_lookup_table{607} = '0.984';
    $scoring_probability_lookup_table{608} = '0.984';
    $scoring_probability_lookup_table{609} = '0.984';
    $scoring_probability_lookup_table{610} = '0.984';
    $scoring_probability_lookup_table{611} = '0.985';
    $scoring_probability_lookup_table{612} = '0.985';
    $scoring_probability_lookup_table{613} = '0.985';
    $scoring_probability_lookup_table{614} = '0.985';
    $scoring_probability_lookup_table{615} = '0.985';
    $scoring_probability_lookup_table{616} = '0.985';
    $scoring_probability_lookup_table{617} = '0.985';
    $scoring_probability_lookup_table{618} = '0.986';
    $scoring_probability_lookup_table{619} = '0.986';
    $scoring_probability_lookup_table{620} = '0.986';
    $scoring_probability_lookup_table{621} = '0.986';
    $scoring_probability_lookup_table{622} = '0.986';
    $scoring_probability_lookup_table{623} = '0.986';
    $scoring_probability_lookup_table{624} = '0.986';
    $scoring_probability_lookup_table{625} = '0.986';
    $scoring_probability_lookup_table{626} = '0.987';
    $scoring_probability_lookup_table{627} = '0.987';
    $scoring_probability_lookup_table{628} = '0.987';
    $scoring_probability_lookup_table{629} = '0.987';
    $scoring_probability_lookup_table{630} = '0.987';
    $scoring_probability_lookup_table{631} = '0.987';
    $scoring_probability_lookup_table{632} = '0.987';
    $scoring_probability_lookup_table{633} = '0.987';
    $scoring_probability_lookup_table{634} = '0.988';
    $scoring_probability_lookup_table{635} = '0.988';
    $scoring_probability_lookup_table{636} = '0.988';
    $scoring_probability_lookup_table{637} = '0.988';
    $scoring_probability_lookup_table{638} = '0.988';
    $scoring_probability_lookup_table{639} = '0.988';
    $scoring_probability_lookup_table{640} = '0.988';
    $scoring_probability_lookup_table{641} = '0.988';
    $scoring_probability_lookup_table{642} = '0.988';
    $scoring_probability_lookup_table{643} = '0.988';
    $scoring_probability_lookup_table{644} = '0.989';
    $scoring_probability_lookup_table{645} = '0.989';
    $scoring_probability_lookup_table{646} = '0.989';
    $scoring_probability_lookup_table{647} = '0.989';
    $scoring_probability_lookup_table{648} = '0.989';
    $scoring_probability_lookup_table{649} = '0.989';
    $scoring_probability_lookup_table{650} = '0.989';
    $scoring_probability_lookup_table{651} = '0.989';
    $scoring_probability_lookup_table{652} = '0.989';
    $scoring_probability_lookup_table{653} = '0.990';
    $scoring_probability_lookup_table{654} = '0.990';
    $scoring_probability_lookup_table{655} = '0.990';
    $scoring_probability_lookup_table{656} = '0.990';
    $scoring_probability_lookup_table{657} = '0.990';
    $scoring_probability_lookup_table{658} = '0.990';
    $scoring_probability_lookup_table{659} = '0.990';
    $scoring_probability_lookup_table{660} = '0.990';
    $scoring_probability_lookup_table{661} = '0.990';
    $scoring_probability_lookup_table{662} = '0.990';
    $scoring_probability_lookup_table{663} = '0.990';
    $scoring_probability_lookup_table{664} = '0.991';
    $scoring_probability_lookup_table{665} = '0.991';
    $scoring_probability_lookup_table{666} = '0.991';
    $scoring_probability_lookup_table{667} = '0.991';
    $scoring_probability_lookup_table{668} = '0.991';
    $scoring_probability_lookup_table{669} = '0.991';
    $scoring_probability_lookup_table{670} = '0.991';
    $scoring_probability_lookup_table{671} = '0.991';
    $scoring_probability_lookup_table{672} = '0.991';
    $scoring_probability_lookup_table{673} = '0.991';
    $scoring_probability_lookup_table{674} = '0.991';
    $scoring_probability_lookup_table{675} = '0.991';
    $scoring_probability_lookup_table{676} = '0.992';
    $scoring_probability_lookup_table{677} = '0.992';
    $scoring_probability_lookup_table{678} = '0.992';
    $scoring_probability_lookup_table{679} = '0.992';
    $scoring_probability_lookup_table{680} = '0.992';
    $scoring_probability_lookup_table{681} = '0.992';
    $scoring_probability_lookup_table{682} = '0.992';
    $scoring_probability_lookup_table{683} = '0.992';
    $scoring_probability_lookup_table{684} = '0.992';
    $scoring_probability_lookup_table{685} = '0.992';
    $scoring_probability_lookup_table{686} = '0.992';
    $scoring_probability_lookup_table{687} = '0.992';
    $scoring_probability_lookup_table{688} = '0.993';
    $scoring_probability_lookup_table{689} = '0.993';
    $scoring_probability_lookup_table{690} = '0.993';
    $scoring_probability_lookup_table{691} = '0.993';
    $scoring_probability_lookup_table{692} = '0.993';
    $scoring_probability_lookup_table{693} = '0.993';
    $scoring_probability_lookup_table{694} = '0.993';
    $scoring_probability_lookup_table{695} = '0.993';
    $scoring_probability_lookup_table{696} = '0.993';
    $scoring_probability_lookup_table{697} = '0.993';
    $scoring_probability_lookup_table{698} = '0.993';
    $scoring_probability_lookup_table{699} = '0.993';
    $scoring_probability_lookup_table{700} = '0.993';
    $scoring_probability_lookup_table{701} = '0.993';
    $scoring_probability_lookup_table{702} = '0.993';
    $scoring_probability_lookup_table{703} = '0.994';
    $scoring_probability_lookup_table{704} = '0.994';
    $scoring_probability_lookup_table{705} = '0.994';
    $scoring_probability_lookup_table{706} = '0.994';
    $scoring_probability_lookup_table{707} = '0.994';
    $scoring_probability_lookup_table{708} = '0.994';
    $scoring_probability_lookup_table{709} = '0.994';
    $scoring_probability_lookup_table{710} = '0.994';
    $scoring_probability_lookup_table{711} = '0.994';
    $scoring_probability_lookup_table{712} = '0.994';
    $scoring_probability_lookup_table{713} = '0.994';
    $scoring_probability_lookup_table{714} = '0.994';
    $scoring_probability_lookup_table{715} = '0.994';
    $scoring_probability_lookup_table{716} = '0.994';
    $scoring_probability_lookup_table{717} = '0.994';
    $scoring_probability_lookup_table{718} = '0.994';
    $scoring_probability_lookup_table{719} = '0.994';
    $scoring_probability_lookup_table{720} = '0.995';
    $scoring_probability_lookup_table{721} = '0.995';
    $scoring_probability_lookup_table{722} = '0.995';
    $scoring_probability_lookup_table{723} = '0.995';
    $scoring_probability_lookup_table{724} = '0.995';
    $scoring_probability_lookup_table{725} = '0.995';
    $scoring_probability_lookup_table{726} = '0.995';
    $scoring_probability_lookup_table{727} = '0.995';
    $scoring_probability_lookup_table{728} = '0.995';
    $scoring_probability_lookup_table{729} = '0.995';
    $scoring_probability_lookup_table{730} = '0.995';
    $scoring_probability_lookup_table{731} = '0.995';
    $scoring_probability_lookup_table{732} = '0.995';
    $scoring_probability_lookup_table{733} = '0.995';
    $scoring_probability_lookup_table{734} = '0.995';
    $scoring_probability_lookup_table{735} = '1.000';
}

## lookup table (rating difference given a difference in percentage score)
## table with three post decimal positions
## Official Wertungsordnung (http://www.schachbund.de/dwz/wo/index.html)
## gives tables with only two post decimal positions.
## But ELOBASE (the closed source software used for official calculations)
## uses the following table!
sub _set_reverse_scoring_probability_lookup_table {
    ## use hash as lookup table for scoring probability
    $reverse_scoring_probability_lookup_table{'0.500'} = '0';
    $reverse_scoring_probability_lookup_table{'0.501'} = '1';
    $reverse_scoring_probability_lookup_table{'0.502'} = '1';
    $reverse_scoring_probability_lookup_table{'0.503'} = '2';
    $reverse_scoring_probability_lookup_table{'0.504'} = '3';
    $reverse_scoring_probability_lookup_table{'0.505'} = '4';
    $reverse_scoring_probability_lookup_table{'0.506'} = '4';
    $reverse_scoring_probability_lookup_table{'0.507'} = '5';
    $reverse_scoring_probability_lookup_table{'0.508'} = '6';
    $reverse_scoring_probability_lookup_table{'0.509'} = '6';
    $reverse_scoring_probability_lookup_table{'0.510'} = '7';
    $reverse_scoring_probability_lookup_table{'0.511'} = '8';
    $reverse_scoring_probability_lookup_table{'0.512'} = '9';
    $reverse_scoring_probability_lookup_table{'0.513'} = '9';
    $reverse_scoring_probability_lookup_table{'0.514'} = '10';
    $reverse_scoring_probability_lookup_table{'0.515'} = '11';
    $reverse_scoring_probability_lookup_table{'0.516'} = '11';
    $reverse_scoring_probability_lookup_table{'0.517'} = '12';
    $reverse_scoring_probability_lookup_table{'0.518'} = '13';
    $reverse_scoring_probability_lookup_table{'0.519'} = '13';
    $reverse_scoring_probability_lookup_table{'0.520'} = '14';
    $reverse_scoring_probability_lookup_table{'0.521'} = '15';
    $reverse_scoring_probability_lookup_table{'0.522'} = '16';
    $reverse_scoring_probability_lookup_table{'0.523'} = '16';
    $reverse_scoring_probability_lookup_table{'0.524'} = '17';
    $reverse_scoring_probability_lookup_table{'0.525'} = '18';
    $reverse_scoring_probability_lookup_table{'0.526'} = '18';
    $reverse_scoring_probability_lookup_table{'0.527'} = '19';
    $reverse_scoring_probability_lookup_table{'0.528'} = '20';
    $reverse_scoring_probability_lookup_table{'0.529'} = '21';
    $reverse_scoring_probability_lookup_table{'0.530'} = '21';
    $reverse_scoring_probability_lookup_table{'0.531'} = '22';
    $reverse_scoring_probability_lookup_table{'0.532'} = '23';
    $reverse_scoring_probability_lookup_table{'0.533'} = '23';
    $reverse_scoring_probability_lookup_table{'0.534'} = '24';
    $reverse_scoring_probability_lookup_table{'0.535'} = '25';
    $reverse_scoring_probability_lookup_table{'0.536'} = '26';
    $reverse_scoring_probability_lookup_table{'0.537'} = '26';
    $reverse_scoring_probability_lookup_table{'0.538'} = '27';
    $reverse_scoring_probability_lookup_table{'0.539'} = '28';
    $reverse_scoring_probability_lookup_table{'0.540'} = '28';
    $reverse_scoring_probability_lookup_table{'0.541'} = '29';
    $reverse_scoring_probability_lookup_table{'0.542'} = '30';
    $reverse_scoring_probability_lookup_table{'0.543'} = '31';
    $reverse_scoring_probability_lookup_table{'0.544'} = '31';
    $reverse_scoring_probability_lookup_table{'0.545'} = '32';
    $reverse_scoring_probability_lookup_table{'0.546'} = '33';
    $reverse_scoring_probability_lookup_table{'0.547'} = '33';
    $reverse_scoring_probability_lookup_table{'0.548'} = '34';
    $reverse_scoring_probability_lookup_table{'0.549'} = '35';
    $reverse_scoring_probability_lookup_table{'0.550'} = '36';
    $reverse_scoring_probability_lookup_table{'0.551'} = '36';
    $reverse_scoring_probability_lookup_table{'0.552'} = '37';
    $reverse_scoring_probability_lookup_table{'0.553'} = '38';
    $reverse_scoring_probability_lookup_table{'0.554'} = '38';
    $reverse_scoring_probability_lookup_table{'0.555'} = '39';
    $reverse_scoring_probability_lookup_table{'0.556'} = '40';
    $reverse_scoring_probability_lookup_table{'0.557'} = '41';
    $reverse_scoring_probability_lookup_table{'0.558'} = '41';
    $reverse_scoring_probability_lookup_table{'0.559'} = '42';
    $reverse_scoring_probability_lookup_table{'0.560'} = '43';
    $reverse_scoring_probability_lookup_table{'0.561'} = '43';
    $reverse_scoring_probability_lookup_table{'0.562'} = '44';
    $reverse_scoring_probability_lookup_table{'0.563'} = '45';
    $reverse_scoring_probability_lookup_table{'0.564'} = '46';
    $reverse_scoring_probability_lookup_table{'0.565'} = '46';
    $reverse_scoring_probability_lookup_table{'0.566'} = '47';
    $reverse_scoring_probability_lookup_table{'0.567'} = '48';
    $reverse_scoring_probability_lookup_table{'0.568'} = '48';
    $reverse_scoring_probability_lookup_table{'0.569'} = '49';
    $reverse_scoring_probability_lookup_table{'0.570'} = '50';
    $reverse_scoring_probability_lookup_table{'0.571'} = '51';
    $reverse_scoring_probability_lookup_table{'0.572'} = '51';
    $reverse_scoring_probability_lookup_table{'0.573'} = '52';
    $reverse_scoring_probability_lookup_table{'0.574'} = '53';
    $reverse_scoring_probability_lookup_table{'0.575'} = '53';
    $reverse_scoring_probability_lookup_table{'0.576'} = '54';
    $reverse_scoring_probability_lookup_table{'0.577'} = '55';
    $reverse_scoring_probability_lookup_table{'0.578'} = '56';
    $reverse_scoring_probability_lookup_table{'0.579'} = '56';
    $reverse_scoring_probability_lookup_table{'0.580'} = '57';
    $reverse_scoring_probability_lookup_table{'0.581'} = '58';
    $reverse_scoring_probability_lookup_table{'0.582'} = '59';
    $reverse_scoring_probability_lookup_table{'0.583'} = '59';
    $reverse_scoring_probability_lookup_table{'0.584'} = '60';
    $reverse_scoring_probability_lookup_table{'0.585'} = '61';
    $reverse_scoring_probability_lookup_table{'0.586'} = '61';
    $reverse_scoring_probability_lookup_table{'0.587'} = '62';
    $reverse_scoring_probability_lookup_table{'0.588'} = '63';
    $reverse_scoring_probability_lookup_table{'0.589'} = '64';
    $reverse_scoring_probability_lookup_table{'0.590'} = '64';
    $reverse_scoring_probability_lookup_table{'0.591'} = '65';
    $reverse_scoring_probability_lookup_table{'0.592'} = '66';
    $reverse_scoring_probability_lookup_table{'0.593'} = '67';
    $reverse_scoring_probability_lookup_table{'0.594'} = '67';
    $reverse_scoring_probability_lookup_table{'0.595'} = '68';
    $reverse_scoring_probability_lookup_table{'0.596'} = '69';
    $reverse_scoring_probability_lookup_table{'0.597'} = '69';
    $reverse_scoring_probability_lookup_table{'0.598'} = '70';
    $reverse_scoring_probability_lookup_table{'0.599'} = '71';
    $reverse_scoring_probability_lookup_table{'0.600'} = '72';
    $reverse_scoring_probability_lookup_table{'0.601'} = '72';
    $reverse_scoring_probability_lookup_table{'0.602'} = '73';
    $reverse_scoring_probability_lookup_table{'0.603'} = '74';
    $reverse_scoring_probability_lookup_table{'0.604'} = '75';
    $reverse_scoring_probability_lookup_table{'0.605'} = '75';
    $reverse_scoring_probability_lookup_table{'0.606'} = '76';
    $reverse_scoring_probability_lookup_table{'0.607'} = '77';
    $reverse_scoring_probability_lookup_table{'0.608'} = '78';
    $reverse_scoring_probability_lookup_table{'0.609'} = '78';
    $reverse_scoring_probability_lookup_table{'0.610'} = '79';
    $reverse_scoring_probability_lookup_table{'0.611'} = '80';
    $reverse_scoring_probability_lookup_table{'0.612'} = '80';
    $reverse_scoring_probability_lookup_table{'0.613'} = '81';
    $reverse_scoring_probability_lookup_table{'0.614'} = '82';
    $reverse_scoring_probability_lookup_table{'0.615'} = '83';
    $reverse_scoring_probability_lookup_table{'0.616'} = '83';
    $reverse_scoring_probability_lookup_table{'0.617'} = '84';
    $reverse_scoring_probability_lookup_table{'0.618'} = '85';
    $reverse_scoring_probability_lookup_table{'0.619'} = '86';
    $reverse_scoring_probability_lookup_table{'0.620'} = '86';
    $reverse_scoring_probability_lookup_table{'0.621'} = '87';
    $reverse_scoring_probability_lookup_table{'0.622'} = '88';
    $reverse_scoring_probability_lookup_table{'0.623'} = '89';
    $reverse_scoring_probability_lookup_table{'0.624'} = '89';
    $reverse_scoring_probability_lookup_table{'0.625'} = '90';
    $reverse_scoring_probability_lookup_table{'0.626'} = '91';
    $reverse_scoring_probability_lookup_table{'0.627'} = '92';
    $reverse_scoring_probability_lookup_table{'0.628'} = '92';
    $reverse_scoring_probability_lookup_table{'0.629'} = '93';
    $reverse_scoring_probability_lookup_table{'0.630'} = '94';
    $reverse_scoring_probability_lookup_table{'0.631'} = '95';
    $reverse_scoring_probability_lookup_table{'0.632'} = '95';
    $reverse_scoring_probability_lookup_table{'0.633'} = '96';
    $reverse_scoring_probability_lookup_table{'0.634'} = '97';
    $reverse_scoring_probability_lookup_table{'0.635'} = '98';
    $reverse_scoring_probability_lookup_table{'0.636'} = '98';
    $reverse_scoring_probability_lookup_table{'0.637'} = '99';
    $reverse_scoring_probability_lookup_table{'0.638'} = '100';
    $reverse_scoring_probability_lookup_table{'0.639'} = '101';
    $reverse_scoring_probability_lookup_table{'0.640'} = '101';
    $reverse_scoring_probability_lookup_table{'0.641'} = '102';
    $reverse_scoring_probability_lookup_table{'0.642'} = '103';
    $reverse_scoring_probability_lookup_table{'0.643'} = '104';
    $reverse_scoring_probability_lookup_table{'0.644'} = '104';
    $reverse_scoring_probability_lookup_table{'0.645'} = '105';
    $reverse_scoring_probability_lookup_table{'0.646'} = '106';
    $reverse_scoring_probability_lookup_table{'0.647'} = '107';
    $reverse_scoring_probability_lookup_table{'0.648'} = '107';
    $reverse_scoring_probability_lookup_table{'0.649'} = '108';
    $reverse_scoring_probability_lookup_table{'0.650'} = '109';
    $reverse_scoring_probability_lookup_table{'0.651'} = '110';
    $reverse_scoring_probability_lookup_table{'0.652'} = '111';
    $reverse_scoring_probability_lookup_table{'0.653'} = '111';
    $reverse_scoring_probability_lookup_table{'0.654'} = '112';
    $reverse_scoring_probability_lookup_table{'0.655'} = '113';
    $reverse_scoring_probability_lookup_table{'0.656'} = '114';
    $reverse_scoring_probability_lookup_table{'0.657'} = '114';
    $reverse_scoring_probability_lookup_table{'0.658'} = '115';
    $reverse_scoring_probability_lookup_table{'0.659'} = '116';
    $reverse_scoring_probability_lookup_table{'0.660'} = '117';
    $reverse_scoring_probability_lookup_table{'0.661'} = '117';
    $reverse_scoring_probability_lookup_table{'0.662'} = '118';
    $reverse_scoring_probability_lookup_table{'0.663'} = '119';
    $reverse_scoring_probability_lookup_table{'0.664'} = '120';
    $reverse_scoring_probability_lookup_table{'0.665'} = '121';
    $reverse_scoring_probability_lookup_table{'0.666'} = '121';
    $reverse_scoring_probability_lookup_table{'0.667'} = '122';
    $reverse_scoring_probability_lookup_table{'0.668'} = '123';
    $reverse_scoring_probability_lookup_table{'0.669'} = '124';
    $reverse_scoring_probability_lookup_table{'0.670'} = '124';
    $reverse_scoring_probability_lookup_table{'0.671'} = '125';
    $reverse_scoring_probability_lookup_table{'0.672'} = '126';
    $reverse_scoring_probability_lookup_table{'0.673'} = '127';
    $reverse_scoring_probability_lookup_table{'0.674'} = '128';
    $reverse_scoring_probability_lookup_table{'0.675'} = '128';
    $reverse_scoring_probability_lookup_table{'0.676'} = '129';
    $reverse_scoring_probability_lookup_table{'0.677'} = '130';
    $reverse_scoring_probability_lookup_table{'0.678'} = '131';
    $reverse_scoring_probability_lookup_table{'0.679'} = '131';
    $reverse_scoring_probability_lookup_table{'0.680'} = '132';
    $reverse_scoring_probability_lookup_table{'0.681'} = '133';
    $reverse_scoring_probability_lookup_table{'0.682'} = '134';
    $reverse_scoring_probability_lookup_table{'0.683'} = '135';
    $reverse_scoring_probability_lookup_table{'0.684'} = '135';
    $reverse_scoring_probability_lookup_table{'0.685'} = '136';
    $reverse_scoring_probability_lookup_table{'0.686'} = '137';
    $reverse_scoring_probability_lookup_table{'0.687'} = '138';
    $reverse_scoring_probability_lookup_table{'0.688'} = '139';
    $reverse_scoring_probability_lookup_table{'0.689'} = '139';
    $reverse_scoring_probability_lookup_table{'0.690'} = '140';
    $reverse_scoring_probability_lookup_table{'0.691'} = '141';
    $reverse_scoring_probability_lookup_table{'0.692'} = '142';
    $reverse_scoring_probability_lookup_table{'0.693'} = '143';
    $reverse_scoring_probability_lookup_table{'0.694'} = '143';
    $reverse_scoring_probability_lookup_table{'0.695'} = '144';
    $reverse_scoring_probability_lookup_table{'0.696'} = '145';
    $reverse_scoring_probability_lookup_table{'0.697'} = '146';
    $reverse_scoring_probability_lookup_table{'0.698'} = '147';
    $reverse_scoring_probability_lookup_table{'0.699'} = '148';
    $reverse_scoring_probability_lookup_table{'0.700'} = '148';
    $reverse_scoring_probability_lookup_table{'0.701'} = '149';
    $reverse_scoring_probability_lookup_table{'0.702'} = '150';
    $reverse_scoring_probability_lookup_table{'0.703'} = '151';
    $reverse_scoring_probability_lookup_table{'0.704'} = '152';
    $reverse_scoring_probability_lookup_table{'0.705'} = '152';
    $reverse_scoring_probability_lookup_table{'0.706'} = '153';
    $reverse_scoring_probability_lookup_table{'0.707'} = '154';
    $reverse_scoring_probability_lookup_table{'0.708'} = '155';
    $reverse_scoring_probability_lookup_table{'0.709'} = '156';
    $reverse_scoring_probability_lookup_table{'0.710'} = '157';
    $reverse_scoring_probability_lookup_table{'0.711'} = '157';
    $reverse_scoring_probability_lookup_table{'0.712'} = '158';
    $reverse_scoring_probability_lookup_table{'0.713'} = '159';
    $reverse_scoring_probability_lookup_table{'0.714'} = '160';
    $reverse_scoring_probability_lookup_table{'0.715'} = '161';
    $reverse_scoring_probability_lookup_table{'0.716'} = '162';
    $reverse_scoring_probability_lookup_table{'0.717'} = '162';
    $reverse_scoring_probability_lookup_table{'0.718'} = '163';
    $reverse_scoring_probability_lookup_table{'0.719'} = '164';
    $reverse_scoring_probability_lookup_table{'0.720'} = '165';
    $reverse_scoring_probability_lookup_table{'0.721'} = '166';
    $reverse_scoring_probability_lookup_table{'0.722'} = '167';
    $reverse_scoring_probability_lookup_table{'0.723'} = '167';
    $reverse_scoring_probability_lookup_table{'0.724'} = '168';
    $reverse_scoring_probability_lookup_table{'0.725'} = '169';
    $reverse_scoring_probability_lookup_table{'0.726'} = '170';
    $reverse_scoring_probability_lookup_table{'0.727'} = '171';
    $reverse_scoring_probability_lookup_table{'0.728'} = '172';
    $reverse_scoring_probability_lookup_table{'0.729'} = '172';
    $reverse_scoring_probability_lookup_table{'0.730'} = '173';
    $reverse_scoring_probability_lookup_table{'0.731'} = '174';
    $reverse_scoring_probability_lookup_table{'0.732'} = '175';
    $reverse_scoring_probability_lookup_table{'0.733'} = '176';
    $reverse_scoring_probability_lookup_table{'0.734'} = '177';
    $reverse_scoring_probability_lookup_table{'0.735'} = '178';
    $reverse_scoring_probability_lookup_table{'0.736'} = '178';
    $reverse_scoring_probability_lookup_table{'0.737'} = '179';
    $reverse_scoring_probability_lookup_table{'0.738'} = '180';
    $reverse_scoring_probability_lookup_table{'0.739'} = '181';
    $reverse_scoring_probability_lookup_table{'0.740'} = '182';
    $reverse_scoring_probability_lookup_table{'0.741'} = '183';
    $reverse_scoring_probability_lookup_table{'0.742'} = '184';
    $reverse_scoring_probability_lookup_table{'0.743'} = '185';
    $reverse_scoring_probability_lookup_table{'0.744'} = '185';
    $reverse_scoring_probability_lookup_table{'0.745'} = '186';
    $reverse_scoring_probability_lookup_table{'0.746'} = '187';
    $reverse_scoring_probability_lookup_table{'0.747'} = '188';
    $reverse_scoring_probability_lookup_table{'0.748'} = '189';
    $reverse_scoring_probability_lookup_table{'0.749'} = '190';
    $reverse_scoring_probability_lookup_table{'0.750'} = '191';
    $reverse_scoring_probability_lookup_table{'0.751'} = '192';
    $reverse_scoring_probability_lookup_table{'0.752'} = '193';
    $reverse_scoring_probability_lookup_table{'0.753'} = '193';
    $reverse_scoring_probability_lookup_table{'0.754'} = '194';
    $reverse_scoring_probability_lookup_table{'0.755'} = '195';
    $reverse_scoring_probability_lookup_table{'0.756'} = '196';
    $reverse_scoring_probability_lookup_table{'0.757'} = '197';
    $reverse_scoring_probability_lookup_table{'0.758'} = '198';
    $reverse_scoring_probability_lookup_table{'0.759'} = '199';
    $reverse_scoring_probability_lookup_table{'0.760'} = '200';
    $reverse_scoring_probability_lookup_table{'0.761'} = '201';
    $reverse_scoring_probability_lookup_table{'0.762'} = '202';
    $reverse_scoring_probability_lookup_table{'0.763'} = '203';
    $reverse_scoring_probability_lookup_table{'0.764'} = '203';
    $reverse_scoring_probability_lookup_table{'0.765'} = '204';
    $reverse_scoring_probability_lookup_table{'0.766'} = '205';
    $reverse_scoring_probability_lookup_table{'0.767'} = '206';
    $reverse_scoring_probability_lookup_table{'0.768'} = '207';
    $reverse_scoring_probability_lookup_table{'0.769'} = '208';
    $reverse_scoring_probability_lookup_table{'0.770'} = '209';
    $reverse_scoring_probability_lookup_table{'0.771'} = '210';
    $reverse_scoring_probability_lookup_table{'0.772'} = '211';
    $reverse_scoring_probability_lookup_table{'0.773'} = '212';
    $reverse_scoring_probability_lookup_table{'0.774'} = '213';
    $reverse_scoring_probability_lookup_table{'0.775'} = '214';
    $reverse_scoring_probability_lookup_table{'0.776'} = '215';
    $reverse_scoring_probability_lookup_table{'0.777'} = '216';
    $reverse_scoring_probability_lookup_table{'0.778'} = '217';
    $reverse_scoring_probability_lookup_table{'0.779'} = '217';
    $reverse_scoring_probability_lookup_table{'0.780'} = '218';
    $reverse_scoring_probability_lookup_table{'0.781'} = '219';
    $reverse_scoring_probability_lookup_table{'0.782'} = '220';
    $reverse_scoring_probability_lookup_table{'0.783'} = '221';
    $reverse_scoring_probability_lookup_table{'0.784'} = '222';
    $reverse_scoring_probability_lookup_table{'0.785'} = '223';
    $reverse_scoring_probability_lookup_table{'0.786'} = '224';
    $reverse_scoring_probability_lookup_table{'0.787'} = '225';
    $reverse_scoring_probability_lookup_table{'0.788'} = '226';
    $reverse_scoring_probability_lookup_table{'0.789'} = '227';
    $reverse_scoring_probability_lookup_table{'0.790'} = '228';
    $reverse_scoring_probability_lookup_table{'0.791'} = '229';
    $reverse_scoring_probability_lookup_table{'0.792'} = '230';
    $reverse_scoring_probability_lookup_table{'0.793'} = '231';
    $reverse_scoring_probability_lookup_table{'0.794'} = '232';
    $reverse_scoring_probability_lookup_table{'0.795'} = '233';
    $reverse_scoring_probability_lookup_table{'0.796'} = '234';
    $reverse_scoring_probability_lookup_table{'0.797'} = '235';
    $reverse_scoring_probability_lookup_table{'0.798'} = '236';
    $reverse_scoring_probability_lookup_table{'0.799'} = '237';
    $reverse_scoring_probability_lookup_table{'0.800'} = '238';
    $reverse_scoring_probability_lookup_table{'0.801'} = '239';
    $reverse_scoring_probability_lookup_table{'0.802'} = '240';
    $reverse_scoring_probability_lookup_table{'0.803'} = '241';
    $reverse_scoring_probability_lookup_table{'0.804'} = '242';
    $reverse_scoring_probability_lookup_table{'0.805'} = '243';
    $reverse_scoring_probability_lookup_table{'0.806'} = '244';
    $reverse_scoring_probability_lookup_table{'0.807'} = '245';
    $reverse_scoring_probability_lookup_table{'0.808'} = '246';
    $reverse_scoring_probability_lookup_table{'0.809'} = '247';
    $reverse_scoring_probability_lookup_table{'0.810'} = '248';
    $reverse_scoring_probability_lookup_table{'0.811'} = '249';
    $reverse_scoring_probability_lookup_table{'0.812'} = '250';
    $reverse_scoring_probability_lookup_table{'0.813'} = '251';
    $reverse_scoring_probability_lookup_table{'0.814'} = '253';
    $reverse_scoring_probability_lookup_table{'0.815'} = '254';
    $reverse_scoring_probability_lookup_table{'0.816'} = '255';
    $reverse_scoring_probability_lookup_table{'0.817'} = '256';
    $reverse_scoring_probability_lookup_table{'0.818'} = '257';
    $reverse_scoring_probability_lookup_table{'0.819'} = '258';
    $reverse_scoring_probability_lookup_table{'0.820'} = '259';
    $reverse_scoring_probability_lookup_table{'0.821'} = '260';
    $reverse_scoring_probability_lookup_table{'0.822'} = '261';
    $reverse_scoring_probability_lookup_table{'0.823'} = '262';
    $reverse_scoring_probability_lookup_table{'0.824'} = '263';
    $reverse_scoring_probability_lookup_table{'0.825'} = '264';
    $reverse_scoring_probability_lookup_table{'0.826'} = '265';
    $reverse_scoring_probability_lookup_table{'0.827'} = '267';
    $reverse_scoring_probability_lookup_table{'0.828'} = '268';
    $reverse_scoring_probability_lookup_table{'0.829'} = '269';
    $reverse_scoring_probability_lookup_table{'0.830'} = '270';
    $reverse_scoring_probability_lookup_table{'0.831'} = '271';
    $reverse_scoring_probability_lookup_table{'0.832'} = '272';
    $reverse_scoring_probability_lookup_table{'0.833'} = '273';
    $reverse_scoring_probability_lookup_table{'0.834'} = '274';
    $reverse_scoring_probability_lookup_table{'0.835'} = '276';
    $reverse_scoring_probability_lookup_table{'0.836'} = '277';
    $reverse_scoring_probability_lookup_table{'0.837'} = '278';
    $reverse_scoring_probability_lookup_table{'0.838'} = '279';
    $reverse_scoring_probability_lookup_table{'0.839'} = '280';
    $reverse_scoring_probability_lookup_table{'0.840'} = '281';
    $reverse_scoring_probability_lookup_table{'0.841'} = '282';
    $reverse_scoring_probability_lookup_table{'0.842'} = '284';
    $reverse_scoring_probability_lookup_table{'0.843'} = '285';
    $reverse_scoring_probability_lookup_table{'0.844'} = '286';
    $reverse_scoring_probability_lookup_table{'0.845'} = '287';
    $reverse_scoring_probability_lookup_table{'0.846'} = '288';
    $reverse_scoring_probability_lookup_table{'0.847'} = '290';
    $reverse_scoring_probability_lookup_table{'0.848'} = '291';
    $reverse_scoring_probability_lookup_table{'0.849'} = '292';
    $reverse_scoring_probability_lookup_table{'0.850'} = '293';
    $reverse_scoring_probability_lookup_table{'0.851'} = '294';
    $reverse_scoring_probability_lookup_table{'0.852'} = '296';
    $reverse_scoring_probability_lookup_table{'0.853'} = '297';
    $reverse_scoring_probability_lookup_table{'0.854'} = '298';
    $reverse_scoring_probability_lookup_table{'0.855'} = '299';
    $reverse_scoring_probability_lookup_table{'0.856'} = '301';
    $reverse_scoring_probability_lookup_table{'0.857'} = '302';
    $reverse_scoring_probability_lookup_table{'0.858'} = '303';
    $reverse_scoring_probability_lookup_table{'0.859'} = '304';
    $reverse_scoring_probability_lookup_table{'0.860'} = '306';
    $reverse_scoring_probability_lookup_table{'0.861'} = '307';
    $reverse_scoring_probability_lookup_table{'0.862'} = '308';
    $reverse_scoring_probability_lookup_table{'0.863'} = '309';
    $reverse_scoring_probability_lookup_table{'0.864'} = '311';
    $reverse_scoring_probability_lookup_table{'0.865'} = '312';
    $reverse_scoring_probability_lookup_table{'0.866'} = '313';
    $reverse_scoring_probability_lookup_table{'0.867'} = '315';
    $reverse_scoring_probability_lookup_table{'0.868'} = '316';
    $reverse_scoring_probability_lookup_table{'0.869'} = '317';
    $reverse_scoring_probability_lookup_table{'0.870'} = '319';
    $reverse_scoring_probability_lookup_table{'0.871'} = '320';
    $reverse_scoring_probability_lookup_table{'0.872'} = '321';
    $reverse_scoring_probability_lookup_table{'0.873'} = '323';
    $reverse_scoring_probability_lookup_table{'0.874'} = '324';
    $reverse_scoring_probability_lookup_table{'0.875'} = '325';
    $reverse_scoring_probability_lookup_table{'0.876'} = '327';
    $reverse_scoring_probability_lookup_table{'0.877'} = '328';
    $reverse_scoring_probability_lookup_table{'0.878'} = '330';
    $reverse_scoring_probability_lookup_table{'0.879'} = '331';
    $reverse_scoring_probability_lookup_table{'0.880'} = '332';
    $reverse_scoring_probability_lookup_table{'0.881'} = '334';
    $reverse_scoring_probability_lookup_table{'0.882'} = '335';
    $reverse_scoring_probability_lookup_table{'0.883'} = '337';
    $reverse_scoring_probability_lookup_table{'0.884'} = '338';
    $reverse_scoring_probability_lookup_table{'0.885'} = '340';
    $reverse_scoring_probability_lookup_table{'0.886'} = '341';
    $reverse_scoring_probability_lookup_table{'0.887'} = '342';
    $reverse_scoring_probability_lookup_table{'0.888'} = '344';
    $reverse_scoring_probability_lookup_table{'0.889'} = '345';
    $reverse_scoring_probability_lookup_table{'0.890'} = '347';
    $reverse_scoring_probability_lookup_table{'0.891'} = '348';
    $reverse_scoring_probability_lookup_table{'0.892'} = '350';
    $reverse_scoring_probability_lookup_table{'0.893'} = '351';
    $reverse_scoring_probability_lookup_table{'0.894'} = '353';
    $reverse_scoring_probability_lookup_table{'0.895'} = '355';
    $reverse_scoring_probability_lookup_table{'0.896'} = '356';
    $reverse_scoring_probability_lookup_table{'0.897'} = '358';
    $reverse_scoring_probability_lookup_table{'0.898'} = '359';
    $reverse_scoring_probability_lookup_table{'0.899'} = '361';
    $reverse_scoring_probability_lookup_table{'0.900'} = '362';
    $reverse_scoring_probability_lookup_table{'0.901'} = '364';
    $reverse_scoring_probability_lookup_table{'0.902'} = '366';
    $reverse_scoring_probability_lookup_table{'0.903'} = '367';
    $reverse_scoring_probability_lookup_table{'0.904'} = '369';
    $reverse_scoring_probability_lookup_table{'0.905'} = '371';
    $reverse_scoring_probability_lookup_table{'0.906'} = '372';
    $reverse_scoring_probability_lookup_table{'0.907'} = '374';
    $reverse_scoring_probability_lookup_table{'0.908'} = '376';
    $reverse_scoring_probability_lookup_table{'0.909'} = '377';
    $reverse_scoring_probability_lookup_table{'0.910'} = '379';
    $reverse_scoring_probability_lookup_table{'0.911'} = '381';
    $reverse_scoring_probability_lookup_table{'0.912'} = '383';
    $reverse_scoring_probability_lookup_table{'0.913'} = '385';
    $reverse_scoring_probability_lookup_table{'0.914'} = '386';
    $reverse_scoring_probability_lookup_table{'0.915'} = '388';
    $reverse_scoring_probability_lookup_table{'0.916'} = '390';
    $reverse_scoring_probability_lookup_table{'0.917'} = '392';
    $reverse_scoring_probability_lookup_table{'0.918'} = '394';
    $reverse_scoring_probability_lookup_table{'0.919'} = '396';
    $reverse_scoring_probability_lookup_table{'0.920'} = '397';
    $reverse_scoring_probability_lookup_table{'0.921'} = '399';
    $reverse_scoring_probability_lookup_table{'0.922'} = '401';
    $reverse_scoring_probability_lookup_table{'0.923'} = '403';
    $reverse_scoring_probability_lookup_table{'0.924'} = '405';
    $reverse_scoring_probability_lookup_table{'0.925'} = '407';
    $reverse_scoring_probability_lookup_table{'0.926'} = '409';
    $reverse_scoring_probability_lookup_table{'0.927'} = '411';
    $reverse_scoring_probability_lookup_table{'0.928'} = '413';
    $reverse_scoring_probability_lookup_table{'0.929'} = '415';
    $reverse_scoring_probability_lookup_table{'0.930'} = '417';
    $reverse_scoring_probability_lookup_table{'0.931'} = '420';
    $reverse_scoring_probability_lookup_table{'0.932'} = '422';
    $reverse_scoring_probability_lookup_table{'0.933'} = '424';
    $reverse_scoring_probability_lookup_table{'0.934'} = '426';
    $reverse_scoring_probability_lookup_table{'0.935'} = '428';
    $reverse_scoring_probability_lookup_table{'0.936'} = '430';
    $reverse_scoring_probability_lookup_table{'0.937'} = '433';
    $reverse_scoring_probability_lookup_table{'0.938'} = '435';
    $reverse_scoring_probability_lookup_table{'0.939'} = '437';
    $reverse_scoring_probability_lookup_table{'0.940'} = '440';
    $reverse_scoring_probability_lookup_table{'0.941'} = '442';
    $reverse_scoring_probability_lookup_table{'0.942'} = '445';
    $reverse_scoring_probability_lookup_table{'0.943'} = '447';
    $reverse_scoring_probability_lookup_table{'0.944'} = '450';
    $reverse_scoring_probability_lookup_table{'0.945'} = '452';
    $reverse_scoring_probability_lookup_table{'0.946'} = '455';
    $reverse_scoring_probability_lookup_table{'0.947'} = '457';
    $reverse_scoring_probability_lookup_table{'0.948'} = '460';
    $reverse_scoring_probability_lookup_table{'0.949'} = '463';
    $reverse_scoring_probability_lookup_table{'0.950'} = '465';
    $reverse_scoring_probability_lookup_table{'0.951'} = '468';
    $reverse_scoring_probability_lookup_table{'0.952'} = '471';
    $reverse_scoring_probability_lookup_table{'0.953'} = '474';
    $reverse_scoring_probability_lookup_table{'0.954'} = '477';
    $reverse_scoring_probability_lookup_table{'0.955'} = '480';
    $reverse_scoring_probability_lookup_table{'0.956'} = '483';
    $reverse_scoring_probability_lookup_table{'0.957'} = '486';
    $reverse_scoring_probability_lookup_table{'0.958'} = '489';
    $reverse_scoring_probability_lookup_table{'0.959'} = '492';
    $reverse_scoring_probability_lookup_table{'0.960'} = '495';
    $reverse_scoring_probability_lookup_table{'0.961'} = '498';
    $reverse_scoring_probability_lookup_table{'0.962'} = '502';
    $reverse_scoring_probability_lookup_table{'0.963'} = '505';
    $reverse_scoring_probability_lookup_table{'0.964'} = '509';
    $reverse_scoring_probability_lookup_table{'0.965'} = '512';
    $reverse_scoring_probability_lookup_table{'0.966'} = '516';
    $reverse_scoring_probability_lookup_table{'0.967'} = '520';
    $reverse_scoring_probability_lookup_table{'0.968'} = '524';
    $reverse_scoring_probability_lookup_table{'0.969'} = '528';
    $reverse_scoring_probability_lookup_table{'0.970'} = '532';
    $reverse_scoring_probability_lookup_table{'0.971'} = '536';
    $reverse_scoring_probability_lookup_table{'0.972'} = '541';
    $reverse_scoring_probability_lookup_table{'0.973'} = '545';
    $reverse_scoring_probability_lookup_table{'0.974'} = '550';
    $reverse_scoring_probability_lookup_table{'0.975'} = '554';
    $reverse_scoring_probability_lookup_table{'0.976'} = '559';
    $reverse_scoring_probability_lookup_table{'0.977'} = '564';
    $reverse_scoring_probability_lookup_table{'0.978'} = '570';
    $reverse_scoring_probability_lookup_table{'0.979'} = '575';
    $reverse_scoring_probability_lookup_table{'0.980'} = '581';
    $reverse_scoring_probability_lookup_table{'0.981'} = '587';
    $reverse_scoring_probability_lookup_table{'0.982'} = '593';
    $reverse_scoring_probability_lookup_table{'0.983'} = '600';
    $reverse_scoring_probability_lookup_table{'0.984'} = '607';
    $reverse_scoring_probability_lookup_table{'0.985'} = '614';
    $reverse_scoring_probability_lookup_table{'0.986'} = '621';
    $reverse_scoring_probability_lookup_table{'0.987'} = '630';
    $reverse_scoring_probability_lookup_table{'0.988'} = '638';
    $reverse_scoring_probability_lookup_table{'0.989'} = '648';
    $reverse_scoring_probability_lookup_table{'0.990'} = '658';
    $reverse_scoring_probability_lookup_table{'0.991'} = '669';
    $reverse_scoring_probability_lookup_table{'0.992'} = '681';
    $reverse_scoring_probability_lookup_table{'0.993'} = '695';
    $reverse_scoring_probability_lookup_table{'0.994'} = '711';
    $reverse_scoring_probability_lookup_table{'0.995'} = '729';
    $reverse_scoring_probability_lookup_table{'0.996'} = '750';
    $reverse_scoring_probability_lookup_table{'0.997'} = '777';
    $reverse_scoring_probability_lookup_table{'0.998'} = '814';
    $reverse_scoring_probability_lookup_table{'0.999'} = '874';
}

1; # Magic true value required at end of module
__END__


=head1 NAME
 
Games::Ratings::Chess::DWZ - calculate changes to German ratings (DWZ)
 

=head1 VERSION
 
This documentation refers to Games::Ratings::Chess::DWZ version 0.0.3
 

=head1 SYNOPSIS
 
 use Games::Ratings::Chess::DWZ;

 my $player = Games::Ratings::Chess::DWZ->new();
 $player->set_rating(2135);
 $player->set_coefficent(30);
 $player->add_game( {
                      'opponent_rating' => 2114,
                      'result'          => 'win', ## or 'draw' or 'loss'
                    }
                  );

 my $rating_change = $player->get_rating_change();
 my $new_rating = $player->get_new_rating();


=head1 DESCRIPTION

This module provides methods to calculate German chess rating (DZW) changes
for one player, having played one or more rated games. Gains and losses are
calculated according to Wertungsordnung of the German Chess Federation
(http://www.schachbund.de/dwz/wo/index.html). 

Actually the official rating calculation _does not_ follow the Wertungsordnung
exactly(!) For official rating calculations a closed source program (ELOBASE)
is used. That program uses tables with three post decimal positions -- in
contrast to the tables from appendix 2.1 and 2.2 of the official
Wertungsordnung. Therefore my module uses those more detailed tables as well.

 
=head1 INTERFACE 

This modules provides the following methods specific to German ratings. Other
(more generic) methods for rating calculation are provided by
Games::Ratings.

=head2 get_rating_change

  my $rating_change = sprintf( "%+.2f", $player->get_rating_change() );

Calculate rating changes for all stored games and return sum of those
changes.

=head2 get_new_rating

  my $new_rating = $player->get_new_rating();

Calculate new rating after the given games.

=head2 get_points_expected

  my $points_expected = $player->get_points_expected();

Calculate expected points (Punkterwartung) according to rating differences
between own rating and opponents ratings. This method uses the detailed
probability tables mentioned above (see DESCRIPTION).

=head2 get_performance

  my $performance = $player->get_performance();

Calculate performance (Turnierleistung). This method uses the detailed
probability tables mentioned above (see DESCRIPTION).


=head1 CONFIGURATION AND ENVIRONMENT

Games::Ratings requires no configuration files or environment variables.


=head1 DEPENDENCIES

This module relies on Games::Ratings which provides some generic methods, e.g.
  * new()
  * get_rating()
  * set_rating()
  * get_coefficient()
  * set_coefficient()
  * add_game()
  * remove_all_games()
  * DESTROY()


=head1 DIAGNOSTICS
 
At the moment, there are no error or warning messages that the module can
generate.

=for author to fill in:
    List every single error and warning message that the module can
    generate (even the ones that will "never happen"), with a full
    explanation of each problem, one or more likely causes, and any
    suggested remedies.

=over

=item C<< Error message here, perhaps with %s placeholders >>

[Description of error here]

=item C<< Another error message here >>

[Description of error here]

[Et cetera, et cetera]

=back


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

At the moment it's not possible to compute a DWZ rating for a previously
unrated player. Also, every opponent has to have a rating.

Note, that a missing development coefficient (set via
$player->set_coefficient()) will probably lead to incorrect results. The
program tries to guess the correct factor according to the players rating, but
it will err for younger players (less than 25 years old) and for players new
to the rating list (with less than six tournaments).

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-games-ratings@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Christian Bartolomaeus  C<< <bartolin@gmx.de> >>


=head1 ACKNOWLEDGMENTS

I have to thank Bernd Schacht -- author of TopTurnier
(see http://www.schach-itzehoe.de/TopTurnier/TT95.htm) -- who confirmed that
for official rating calculations detailed probability tables are used -- in
contrast to the official Wertungsordnung
(http://www.schachbund.de/dwz/wo/index.html).


=head1 SEE ALSO

http://de.wikipedia.org/wiki/DWZ_(Schach) for general informations about
the DWZ rating system.

http://www.schachbund.de/dwz/wo/index.html for technical informations
about the DWZ rating system.


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2010, Christian Bartolomaeus C<< <bartolin@gmx.de> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
