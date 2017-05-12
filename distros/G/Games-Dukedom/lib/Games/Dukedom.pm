package Games::Dukedom;

our $VERSION = 'v0.1.3';

use Storable qw( freeze thaw );
use Carp;

use Games::Dukedom::Signal;

use Moo 1.004003;
use MooX::StrictConstructor;
use MooX::ClassAttribute;

use MooX::Struct -rw, Land => [
    qw(
      +trades
      +spoils
      +price
      +sell_price
      +planted
      )
  ],
  Population => [
    qw(
      +starvations
      +levy
      +casualties
      +looted
      +diseased
      +deaths
      +births
      )
  ],
  Grain => [
    qw(
      +food
      +trades
      +seed
      +spoilage
      +wages
      +spoils
      +yield
      +expense
      +taxes
      )
  ],
  War => [
    qw(
      +first_strike
      +tension
      +desire
      +will
      +grain_damage
      +risk
      )
  ];

# status codes
use constant RUNNING   => 0;
use constant RETIRED   => 1;
use constant KINGDOM   => 2;
use constant QUIT_GAME => -1;
use constant DEPOSED   => -2;
use constant ABOLISHED => -3;

# magic numbers
use constant TAX_RATE         => .5;
use constant MAX_YEAR         => 45;
use constant MIN_LAND         => 45;
use constant MIN_POPULATION   => 33;
use constant MIN_GRAIN        => 429;
use constant MAX_FOOD_BONUS   => 4;
use constant LABOR_CAPACITY   => 4;
use constant SEED_PER_HA      => 2;
use constant MAX_SALE         => 4000;
use constant MAX_SELL_TRIES   => 3;
use constant MIN_LAND_PRICE   => 4;
use constant MIN_EXPENSE      => 429;
use constant WAR_CONSTANT     => 1.95;
use constant UNREST_FACTOR    => .85;
use constant MAX_1YEAR_UNREST => 88;
use constant MAX_TOTAL_UNREST => 99;

my @steps = (
    qw(
      _init_year
      _feed_the_peasants
      _starvation_and_unrest
      _purchase_land
      _war_with_the_king
      _grain_production
      _kings_levy
      _war_with_neigbor
      _population_changes
      _harvest_grain
      _update_unrest
      )
);

my @settable_steps = (
    qw(
      _display_msg
      _feed_the_peasants
      _purchase_land
      _sell_land
      _king_wants_war
      _grain_production
      _kings_levy
      _first_strike
      _goto_war
      _quit_game
      )
);


my %traits = (
    price => {
        q1 => 4,
        q2 => 7,
    },
    yield => {
        q1 => 4,
        q2 => 8,
    },
    spoilage => {
        q1 => 4,
        q2 => 6,
    },
    levies => {
        q1 => 3,
        q2 => 8,
    },
    war => {
        q1 => 5,
        q2 => 8,
    },
    first_strike => {
        q1 => 3,
        q2 => 6,
    },
    disease => {
        q1 => 3,
        q2 => 8,
    },
    birth => {
        q1 => 4,
        q2 => 8,
    },
    merc_quality => {
        q1 => 8,
        q2 => 8,
    },
);

my $fnr = sub {
    my ( $q1, $q2 ) = @_;

    return int( rand() * ( 1 + $q2 - $q1 ) ) + $q1;
};

my $gauss = sub {
    my ( $q1, $q2 ) = @_;

    my $g0;

    my $q3 = &$fnr( $q1, $q2 );
    if ( &$fnr( $q1, $q2 ) > 5 ) {
        $g0 = ( $q3 + &$fnr( $q1, $q2 ) ) / 2;
    }
    else {
        $g0 = $q3;
    }

    return $g0;
};

class_has signal => (
    is       => 'ro',
    init_arg => undef,
    default  => 'Games::Dukedom::Signal',
    handles  => 'Throwable',
);

has _base_values => (
    is       => 'ro',
    init_arg => undef,
    default  => sub {
        my $base = {};
        for ( keys(%traits) ) {
            $base->{$_} = &$gauss( $traits{$_}{q1}, $traits{$_}{q2} );
        }
        return $base;
    },
);

has year => (
    is       => 'rwp',
    init_arg => undef,
    default  => 0,
);

has population => (
    is       => 'rwp',
    init_arg => undef,
    default  => 100,
);

has _population => (
    is       => 'ro',
    lazy     => 1,
    clearer  => 1,
    default  => sub { Population->new; },
    init_arg => undef,
);

has grain => (
    is       => 'rwp',
    init_arg => undef,
    default  => 4177,
);

has _grain => (
    is       => 'ro',
    clearer  => 1,
    lazy     => 1,
    default  => sub { Grain->new; },
    init_arg => undef,
);

has land => (
    is       => 'rwp',
    init_arg => undef,
    default  => 600,
);

has _land => (
    is       => 'ro',
    lazy     => 1,
    clearer  => 1,
    default  => sub { Land->new; },
    init_arg => undef,
);

has land_fertility => (
    is       => 'ro',
    init_arg => undef,
    default  => sub {
        {
            100 => 216,
            80  => 200,
            60  => 184,
            40  => 0,
            20  => 0,
            0   => 0,
        };
    },
);

has _war => (
    is       => 'ro',
    lazy     => 1,
    clearer  => 1,
    default  => sub { War->new; },
    init_arg => undef,
);

has yield => (
    is       => 'rwp',
    init_arg => undef,
    default  => 3.95,
);

has unrest => (
    is       => 'rwp',
    init_arg => undef,
    default  => 0,
);

has _unrest => (
    is       => 'ro',
    default  => 0,
    init_arg => undef,
);

has king_unrest => (
    is       => 'rwp',
    init_arg => undef,
    default  => 0,
);

has tax_paid => (
    is       => 'ro',
    init_arg => undef,
    default  => 0,
);

has _black_D => (
    is       => 'ro',
    init_arg => undef,
    default  => 0,
);

has input => (
    is       => 'rw',
    init_arg => undef,
    clearer  => 1,
    default  => undef,
);

has _steps => (
    is       => 'lazy',
    init_arg => undef,
    clearer  => 1,
    default  => sub { [@steps] },
);

has status => (
    is       => 'rwp',
    init_arg => undef,
    default  => RUNNING,
);

has _msg => (
    is       => 'rw',
    init_arg => undef,
    clearer  => 1,
    default  => undef,
);

has detail_report => (
    is       => 'ro',
    init_arg => undef,
    default  => '',
);

sub BUILD {
    my $self = shift;

    return;
}

# guarantee we have a clean input if needed.
before throw => sub {
    my $self = shift;

    $self->clear_input;

    return;
};

# intercept a "quit" request
around input => sub {
    my $orig  = shift;
    my $self  = shift;
    my $input = $_[0] || '';

    $self->_next_step('_quit_game') if $input =~ /^(?:q|quit)\s*$/i;

    return $self->$orig(@_);
};

sub input_is_yn {
    my $self = shift;

    my $value = $self->input;
    chomp($value) if defined($value);

    return !!( defined($value) && $value =~ /^(?:y|n)$/i );
}

sub input_is_value {
    my $self = shift;

    my $value = $self->input;
    chomp($value) if defined($value);

    return !!( defined($value) && ( $value =~ /^\d+$/ ) );
}

sub play_one_year {
    my $self   = shift;
    my $params = @_;

    return if $self->game_over;

    while ( @{ $self->_steps } ) {
        my $step = shift( @{ $self->_steps } );

        $self->$step;
        $self->clear_input;
    }

    $self->_prep_detail_report();

    $self->{tax_paid} += $self->_grain->taxes;
    $self->_clear_steps;
    $self->_clear_population;
    $self->_clear_grain;
    $self->_clear_land;
    $self->_clear_war;

    $self->_end_of_game_check;

    return;
}

sub game_over {
    my $self = shift;

    return !( $self->status == RUNNING );
}

sub _next_step {
    my $self = shift;
    my $next = shift;

    croak "Illegal value for '_next_step': $next"
      unless grep( /^$next$/, @settable_steps);

    return unshift( @{ $self->_steps }, $next );
}

sub _randomize {
    my $self  = shift;
    my $trait = shift;

    return int( &$fnr( -2, 2 ) + $self->_base_values->{$trait} );
}

sub _init_year {
    my $self = shift;

    ++$self->{year};

    $self->{_unrest} = 0;

    $self->_land->{price} =
      int( ( 2 * $self->yield ) + $self->_randomize('price') - 5 );
    $self->_land->{price} = MIN_LAND_PRICE
      if $self->_land->price < MIN_LAND_PRICE;

    $self->_land->{sell_price} = $self->_land->price;

    $self->{_msg} = $self->_summary_report;
    $self->{_msg} .= $self->_fertility_report;

    $self->_next_step('_display_msg');

    return;
}

sub _display_msg {
    my $self = shift;

    # a Moo clearer returns the existing value, if any, like delete does.
    $self->throw( $self->_clear_msg );
}

sub _summary_report {
    my $self = shift;

    my $msg = sprintf( "\nYear %d Peasants %d Land %d Grain %d Taxes %d\n",
        $self->year, $self->population, $self->land, $self->grain,
        $self->tax_paid );

    return $msg;
}

sub _fertility_report {
    my $self = shift;

    my $msg = "Land Fertility:\n";
    $msg .= " 100%  80%  60%  40%  20% Depl\n";
    for ( 100, 80, 60, 40, 20, 0 ) {
        $msg .= sprintf( "%5d", $self->land_fertility->{$_} );
    }
    $msg .= "\n";

    return $msg;
}

sub _feed_the_peasants {
    my $self = shift;

    my $hint = ( $self->grain / $self->population ) < 11 ? $self->grain : 14;

    $self->_next_step('_feed_the_peasants')
      and $self->throw(
        msg     => "Grain for food [$hint]: ",
        action  => 'get_value',
        default => $hint,
      ) unless $self->input_is_value;

    my $food = $self->input;

    # shortcut
    $food *= $self->population if ( $food < 100 && $self->grain > $food );

    if ( $food > $self->grain ) {
        $self->_next_step('_feed_the_peasants');

        $self->throw( $self->_insufficient_grain('feed') );
    }
    elsif (( ( $food / $self->population ) < 11 )
        && ( $food != $self->grain ) )
    {
        $self->{_unrest} += 3;

        $self->_next_step('_feed_the_peasants');

        my $msg = "The peasants demonstrate before the castle\n";
        $msg .= "with sharpened scythes\n\n";
        $self->throw($msg);
    }

    $self->_grain->{food} = -$food;
    $self->{grain} += $self->_grain->{food};

    return;
}

sub _starvation_and_unrest {
    my $self = shift;

    my $food = -$self->_grain->food;

    my $x1 = $food / $self->population;
    if ( $x1 < 13 ) {
        $self->_population->{starvations} =
          -int( ( $self->population - ( $food / 13 ) ) );
        $self->{population} += $self->_population->starvations;
    }

    # only allow bonus for extra food up to 18HL/peasant
    $x1 -= 14;
    $x1 = MAX_FOOD_BONUS if $x1 > MAX_FOOD_BONUS;

    $self->{_unrest} =
      $self->_unrest - ( 3 * $self->_population->starvations ) - ( 2 * $x1 );

    if ( $self->_population->starvations < 0 ) {
        $self->_msg("Some peasants have starved during the winter\n");
        $self->_next_step('_display_msg');
    }

    return ( ( $self->_unrest > 88 ) || ( $self->population < 33 ) );
}

sub _purchase_land {
    my $self = shift;

    my $land  = $self->_land;
    my $grain = $self->_grain;

    my $msg = '';

    $msg .= sprintf( "Land to buy at %d HL/HA [0]: ", int( $land->{price} ) );
    $self->_next_step('_purchase_land')
      and $self->throw( msg => $msg, action => 'get_value', default => 0 )
      unless $self->input_is_value();

    $self->_next_step('_sell_land') and return
      unless my $buy = $self->input;

    $self->_next_step('_purchase_land')
      and $self->throw( $self->_insufficient_grain('buy') )
      if ( $buy * $land->price > $self->grain );

    $self->land_fertility->{60} += $buy;
    $land->{trades} = $buy;
    $self->{land} += $buy;
    $grain->{trades} = -$buy * $land->{price};
    $self->{grain} += $grain->{trades};

    return;
}

sub _sell_land {
    my $self = shift;

    my $land  = $self->_land;
    my $grain = $self->_grain;

    if ( $land->price - $land->sell_price > MAX_SELL_TRIES ) {
        $grain->{trades} = 0;

        $self->throw("Buyers have lost interest\n");
    }

    my $price = --$land->{sell_price};

    my $msg = sprintf( "Land to sell at %d HL/HA [0]: ", $price );
    $self->_next_step('_sell_land')
      and $self->throw( msg => $msg, action => 'get_value', default => 0 )
      unless $self->input_is_value();

    return unless my $sold = $self->input;

    my $x1 = 0;
    for ( 100, 80, 60 ) {
        $x1 += $self->land_fertility->{$_};
    }

    $self->{_msg} = undef;
    if ( $sold > $x1 ) {
        $self->_next_step('_display_msg');
        $self->{_msg} = sprintf( "You only have %d HA. of good land\n", $x1 );
    }
    elsif ( ( $grain->{trades} = $sold * $price ) > MAX_SALE ) {
        $self->_next_step('_display_msg');
        $self->{_msg} = "No buyers have that much grain - sell less\n";
    }
    return if $self->_msg;

    $land->{trades} = -$sold;

    my $valid = 0;
    my $sold_q;
    for ( 60, 80, 100 ) {
        $sold_q = $_;
        if ( $sold <= $self->land_fertility->{$_} ) {
            $valid = 1;
            last;
        }
        else {
            $sold -= $self->land_fertility->{$_};
            $self->land_fertility->{$_} = 0;
        }
    }

    if ( !$valid ) {
        my $msg = "LAND SELLING LOOP ERROR - CONTACT PROGRAM AUTHOR IF\n";
        $msg .= "ERROR IS NOT YOURS IN ENTERING PROGRAM,\n";
        $msg .= "AND SEEMS TO BE FAULT OF PROGRAM'S LOGIC.\n";

        die $msg;
    }

    $self->land_fertility->{$sold_q} -= $sold;
    $self->{land} += $land->trades;

    $self->_set_status(ABOLISHED) if $self->land < 10;

    $msg = '';
    if ( ( $price < MIN_LAND_PRICE ) && $sold ) {
        $grain->{trades} = int( $grain->{trades} / 2 );
        $msg = "\nThe High King appropriates half your earnings\n";
        $msg .= "as punishment for selling at such a low price\n";
    }

    $self->{grain} += $grain->{trades};
    $self->throw($msg) if $msg;

    return;
}

sub _war_with_the_king {
    my $self = shift;

    $self->_king_wants_war if $self->king_unrest > 0;

    return if $self->king_unrest > -2;

    my $mercs = int( $self->grain / 100 );

    my $msg = "\nThe King's army is about to attack your duchy\n";
    $msg .= sprintf( "You have hired %d foreign mercenaries\n", $mercs );
    $msg .= "at 100 HL. each (payment in advance)\n\n";

    # assuming a population > 200 at the time of your revolt, # the C source
    # i ported from allowed one to win with as few as 5 mercs.
    # if ( ( $self->grain * $mercs ) + $self->population > 2399 ) {
    #
    # the Java source changed it so it took significantly more, about 275 but
    # was still a fixed value.
    # if ( ( 8 * $mercs ) + $self->population > 2399 ) {
    #
    # i've added an element of chance. again, assuming a populaton of 200, it
    # now requires anywhere from 219 to 366 mercs to win depending on the
    # quality of merc you hire. this means you must have at least 22,000 in
    # grain to win, and as much as 37,000 if your mercs suck.
    if ( ( int( $self->_randomize('merc_quality') ) * $mercs ) +
        $self->population > 2399 )
    {
        $msg .= "Wipe the blood from the crown - you are now High King!\n\n";
        $msg .= "A nearby monarchy threatens war; ";
        $msg .= "how many .........\n\n\n\n";

        $self->_set_status(KINGDOM);
    }
    else {
        $msg .= "The placement of your head atop the castle gate signifies\n";
        $msg .= "that the High King has abolished your Ducal right\n\n";

        $self->_set_status(ABOLISHED);
    }

    $self->{_msg}   = $msg;
    $self->{_steps} = ['_display_msg'];

    return;
}

sub _king_wants_war {
    my $self = shift;

    return unless $self->king_unrest > 0;

    my $msg = "\nThe King demands twice the royal tax in the\n";
    $msg .= 'hope of provoking war.  Will you pay? [Y/n]: ';

    $self->_next_step('_king_wants_war')
      and $self->throw( msg => $msg, action => 'get_yn', default => 'Y' )
      unless $self->input_is_yn;

    my $ans = $self->input;
    $ans ||= 'Y';

    $self->_set_king_unrest( ( $ans =~ /^n/i ) ? -1 : 2 );

    return;
}

sub _grain_production {
    my $self = shift;

    my $done = 0;

    my $pop_plant   = $self->population * LABOR_CAPACITY;
    my $grain_plant = int( $self->grain / SEED_PER_HA );
    my $max_grain_plant =
      $grain_plant > $self->land ? $self->land : $grain_plant;
    my $max_plant =
      $pop_plant > $max_grain_plant ? $max_grain_plant : $pop_plant;

    my $msg = '';

    $msg .= sprintf( "Land to plant [%d]: ", $max_plant );
    $self->_next_step('_grain_production')
      and $self->throw(
        msg     => $msg,
        action  => 'get_value',
        default => $max_plant
      ) unless $self->input_is_value();

    my $plant = $self->input || $max_plant;

    my $grain = $self->_grain;
    $msg = '';

    if ( $plant > $self->land ) {
        $msg = "You don't have enough land\n";
        $msg .= sprintf( "You only have %d HA. of land left\n", $self->land );
    }
    if ( $plant > ($pop_plant) ) {
        $msg = "You don't have enough peasants\n";
        $msg .= sprintf( "Your peasants can only plant %d HA. of land\n",
            $pop_plant );
    }
    $grain->{seed} = -( SEED_PER_HA * $plant );
    if ( -$grain->seed > $self->grain ) {
        $msg = $self->_insufficient_grain('plant');
    }

    if ($msg) {
        $self->_next_step('_grain_production');
        $self->throw($msg);
    }

    $grain->{yield} = $plant;
    $self->_land->{planted} = $plant;
    $self->{grain} += $grain->seed;

    my $tmp_quality = $self->_update_land_tables($plant);
    $self->_crop_yield_and_losses($tmp_quality);

    return;
}

sub _update_land_tables {
    my $self  = shift;
    my $plant = shift;

    my $valid = 0;

    my %tmp_quality = (
        100 => 0,
        80  => 0,
        60  => 0,
        40  => 0,
        20  => 0,
        0   => 0,
    );

    my $quality = $self->land_fertility;

    my $qfactor;
    for (qw( 100 80 60 40 20 0 )) {
        $qfactor = $_;
        if ( $plant <= $quality->{$qfactor} ) {
            $valid = 1;
            last;
        }
        else {
            $plant -= $quality->{$qfactor};
            $tmp_quality{$qfactor} = $quality->{$qfactor};
            $quality->{$qfactor} = 0;
        }
    }

    if ( !$valid ) {
        warn "LAND TABLE UPDATING ERROR - PLEASE CONTACT PROGRAM AUTHOR\n";
        warn "IF ERROR IS NOT A FAULT OF ENTERING THE PROGRAM, BUT RATHER\n";
        warn "FAULT OF THE PROGRAM LOGIC.\n";

        exit(1);
    }

    $tmp_quality{$qfactor} = $plant;
    $quality->{$qfactor} -= $plant;
    $quality->{100} += $quality->{80};
    $quality->{80} = 0;

    for ( 60, 40, 20, 0 ) {
        $quality->{ $_ + 40 } += $quality->{$_};
        $quality->{$_} = 0;
    }

    for ( 100, 80, 60, 40, 20 ) {
        $quality->{ $_ - 20 } += $tmp_quality{$_};
    }

    $quality->{0} += $tmp_quality{0};

    return \%tmp_quality;
}

sub _crop_yield_and_losses {
    my $self  = shift;
    my $tmp_q = shift;

    $self->{_msg} = '';

    $self->{yield} = $self->_randomize('yield') + 3;
    if ( !( $self->year % 7 ) ) {
        $self->{_msg} .= "Seven year locusts\n";
        $self->{yield} /= 2;
    }

    my $x1 = 0;
    for ( 100, 80, 60, 40, 20 ) {
        $x1 += $tmp_q->{$_} * ( $_ / 100 );
    }

    my $grain = $self->_grain;

    if ( $self->_land->planted == 0 ) {
        $self->{yield} = 0;
    }
    else {
        $self->{yield} =
          int( $self->yield * ( $x1 / $self->_land->planted ) * 100 ) / 100;
    }
    $self->{_msg} .= sprintf( "Yield = %0.2f HL./HA.\n", $self->yield );

    $x1 = $self->_randomize('spoilage') + 3;
    unless ( $x1 < 9 ) {
        $grain->{spoilage} = -int( ( $x1 * $self->grain ) / 83 );
        $self->{grain} += $grain->{spoilage};
        $self->{_msg} .= "Rats infest the grainery\n";
    }

    $self->_next_step('_display_msg');

    return;
}

sub _kings_levy {
    my $self = shift;

    return if ( $self->population < 67 ) || ( $self->king_unrest == -1 );

    # there is an edge case where entering an invalid answer might allow
    # one to avoid this, but ... who cares
    my $x1 = $self->_randomize('levies');
    return if $x1 > ( $self->population / 30 );

    my $msg = sprintf( "\nThe High King requires %d peasants for his estates ",
        int($x1) );
    $msg .= "and mines.\n";
    $msg .= sprintf( "Will you supply them or pay %d ", int( $x1 * 100 ) );
    $msg .= "HL. of grain instead [Y/n]: ";

    $self->_next_step('_kings_levy')
      and $self->throw( msg => $msg, action => 'get_yn', default => 'Y' )
      unless $self->input_is_yn();

    if ( $self->input =~ /^n/i ) {
        $self->_grain->{taxes} = -100 * $x1;
        $self->{grain} += $self->_grain->{taxes};
    }
    else {
        $self->_population->{levy} = -int($x1);
        $self->{population} += $self->_population->{levy};
    }

    return;
}

# TODO: find names for the "magic numbers" and change them to constants
sub _war_with_neigbor {
    my $self = shift;

    if ( $self->king_unrest == -1 ) {
        $self->{_msg} = "\nThe High King calls for peasant levies\n";
        $self->{_msg} .= "and hires many foreign mercenaries\n";

        $self->{king_unrest} = -2;
    }
    else {
        my $war = $self->_war;

        # are you worth coming after?
        $war->{tension} = int( 11 - ( 1.5 * $self->yield ) );
        $war->{tension} = 2 if ( $war->tension < 2 );

        if (   $self->king_unrest
            || ( $self->population <= 109 )
            || ( ( 17 * ( $self->land - 400 ) + $self->grain ) <= 10600 ) )
        {
            $war->{desire} = 0;
        }
        else {
            $self->{_msg} = "\nThe High King grows uneasy and may\n";
            $self->{_msg} .= "be subsidizing wars against you\n";

            $war->{tension} += 2;
            $war->{desire} = $self->year + 5;
        }

        $war->{risk} = int( $self->_randomize('war') );
        $self->_next_step('_first_strike') if $war->tension > $war->risk;

        $war->{first_strike} =
          int(
            $war->{desire} + 85 + ( 18 * $self->_randomize('first_strike') ) );
    }
    $self->_next_step('_display_msg') if $self->_msg;

    return;
}

sub _first_strike {
    my $self = shift;

    my $war = $self->_war;
    $war->{will} = 1.2 - ( $self->_unrest / 16 );
    my $resistance = int( $self->population * $war->will ) + 13;

    my $msg = "A nearby Duke threatens war; Will you attack first [y/N]? ";

    $self->_next_step('_first_strike')
      and $self->throw( msg => $msg, action => 'get_yn', default => 'N' )
      unless $self->input_is_yn();

    my $population = $self->_population;

    $self->{_msg} = '';
    if ( $self->input !~ /^n/i ) {
        if ( $war->{first_strike} >= $resistance ) {
            $self->_next_step('_goto_war');
            $self->{_msg} = "First strike failed - you need professionals\n";
            $population->{casualties} = -$war->risk - $war->tension - 2;
            $war->{first_strike} += ( 3 * $population->casualties );
        }
        else {
            $self->{_msg} = "Peace negotiations were successful\n";

            $population->{casualties} = -$war->tension - 1;
            $war->{first_strike}      = 0;
        }
        $self->{population} += $population->casualties;
        if ( $war->first_strike < 1 ) {
            $self->{_unrest} -=
              ( 2 * $population->casualties ) + ( 3 * $population->looted );
        }
    }
    else {
        $self->_next_step('_goto_war');
    }
    $self->_next_step('_display_msg') if $self->_msg;

    return;
}

sub _goto_war {
    my $self = shift;

    my $possible = int( $self->grain / 40 );
    $possible = 75 if $possible > 75;
    $possible = 0  if $possible < 0;

    my $msg = "Hire how many mercenaries at 40 HL each [$possible]? ";
    $self->_next_step('_goto_war')
      and $self->throw(
        msg     => $msg,
        action  => 'get_value',
        default => $possible
      ) unless $self->input_is_value();

    my $hired = $self->input || $possible;

    if ( $hired > 75 ) {
        my $msg = "There are only 75 mercenaries available for hire\n";
        $self->_next_step('_goto_war');

        $self->throw($msg);
    }

    my $war  = $self->_war;
    my $land = $self->_land;

    my $resistance = int( ( $self->population * $war->will ) + ( 7 * $hired ) + 13 );

    $war->{desire} = int( $war->desire * WAR_CONSTANT );

    my $x6 = $war->desire - ( 4 * $hired ) - int( $resistance / 4 );
    $war->{desire}  = $resistance - $war->desire;
    $land->{spoils} = int( 0.8 * $war->desire );
    if ( -$land->spoils > int( 0.67 * $self->land ) ) {
        $self->{_steps} = [];
        $self->_set_status(ABOLISHED);

        my $msg = "You have been overrun and have lost the entire Dukedom\n";
        $msg .= "The placement of your head atop the castle gate\n";
        $msg .= "signifies that ";
        $msg .= "the High King has abolished your Ducal right\n\n";

        $self->throw($msg);
    }

    my $x1 = $land->spoils;

    my $fertility = $self->land_fertility;
    for ( 100, 80, 60 ) {
        my $x3 = int( $x1 / ( 3 - ( 5 - ( $_ / 20 ) ) ) );
        if ( -$x3 <= $fertility->{$_} ) {
            $resistance = $x3;
        }
        else {
            $resistance = -$fertility->{$_};
        }
        $fertility->{$_} += $resistance;
        $x1 = $x1 - $resistance;
    }
    for ( 40, 20, 0 ) {
        if ( -$x1 <= $fertility->{$_} ) {
            $resistance = $x1;
        }
        else {
            $resistance = -$fertility->{$_};
        }
        $fertility->{$_} += $resistance;
        $x1 = $x1 - $resistance;
    }

    my $grain = $self->_grain;

    $msg = '';
    if ( $land->spoils < 399 ) {
        if ( $war->desire >= 0 ) {
            $msg = "You have won the war\n";

            $war->{grain_damage} = 0.67;
            $grain->{spoils}     = int( 1.7 * $land->spoils );
            $self->{grain} += $grain->spoils;
        }
        else {
            $msg = "You have lost the war\n";

            $war->{grain_damage} =
              int( ( $grain->yield / $self->land ) * 100 ) / 100;
        }
        if ( $x6 <= 9 ) {
            $x6 = 0;
        }
        else {
            $x6 = int( $x6 / 10 );
        }
    }
    else {
        $msg = "You have overrun the enemy and annexed his entire Dukedom\n";

        $grain->{spoils} = 3513;
        $self->{grain} += $grain->spoils;
        $x6 = -47;
        $war->{grain_damage} = 0.55;
        if ( $self->king_unrest <= 0 ) {
            $self->{king_unrest} = 1;
            $msg .= "The King fears for his throne and\n";
            $msg .= "may be planning direct action\n";
        }
    }

    $x6 = $self->population if ( $x6 > $self->population );

    my $population = $self->_population;

    $population->{casualties} -= $x6;
    $self->{population}       -= $x6;
    $grain->{yield} += int( $war->grain_damage * $land->spoils );
    $x6 = 40 * $hired;
    if ( $x6 <= $self->grain ) {
        $grain->{wages} = -$x6;

        # what is P[5] (looted) in this case?
    }
    else {
        $grain->{wages} = -$self->grain;
        $population->{looted} = -int( ( $x6 - $self->grain ) / 7 ) - 1;
        $msg .= "There isn't enough grain to pay the mercenaries\n";
    }
    $self->{grain} += $grain->wages;

    --$self->{population} if ( -$population->looted > $self->population );

    $self->{population} += $population->looted;
    $self->{land}       += $land->spoils;
    $self->{_unrest} -=
      ( 2 * $population->casualties ) - ( 3 * $population->looted );

    $self->_next_step('_display_msg') if $self->{_msg} = $msg;

    return;
}

sub _population_changes {
    my $self = shift;

    my $x1 = $self->_randomize('disease');

    my $population = $self->_population;
    my $x2;
    if ( $x1 <= 3 ) {
        if ( $x1 != 1 ) {
            $self->{_msg} = "A POX EPIDEMIC has broken out\n";
            $self->_next_step('_display_msg');

            $x2 = $x1 * 5;
            $population->{diseased} = -int( $self->population / $x2 );
            $self->{population} += $population->diseased;
        }
        elsif ( $self->_black_D <= 0 ) {
            $self->{_msg} = "The BLACK PLAGUE has struck the area\n";
            $self->_next_step('_display_msg');

            $self->{_black_D}       = 13;
            $x2                     = 3;
            $population->{diseased} = -int( $self->population / $x2 );
            $self->{population} += $population->diseased;
        }
    }

    $x1 = $population->looted ? 4.5 : $self->_randomize('birth') + 4;

    $population->{births} = int( $self->population / $x1 );
    $population->{deaths} = int( 0.3 - ( $self->population / 22 ) );
    $self->{population} += $population->deaths + $population->births;

    --$self->{_black_D};

    return;
}

sub _harvest_grain {
    my $self = shift;

    my $grain = $self->_grain;

    $grain->{yield} = int( $self->yield * $self->_land->planted );
    $self->{grain} += $grain->yield;

    my $x1 = $grain->yield - 4000;
    $grain->{expense} = -int( 0.1 * $x1 ) if $x1 > 0;

    $grain->{expense} -= MIN_EXPENSE;
    $self->{grain} += $grain->expense;

    # you've already told the King what to do with his taxes, he's coming
    # to collect them (and more) in person now.
    return if $self->king_unrest < 0;

    my $tax_rate = $self->king_unrest >= 2 ? TAX_RATE * 2 : TAX_RATE;
    $x1 = -int( $self->land * $tax_rate );

    if ( -$x1 > $self->grain ) {
        $self->{_msg} = "You have insufficient grain to pay the royal tax\n";
        $self->{_msg} .= "the High King has abolished your Ducal right\n\n";
        $self->_next_step('_display_msg');

        $self->_set_status(ABOLISHED);
        return 1;
    }
    $grain->{taxes} += $x1;
    $self->{grain}  += $x1;

    return;
}

sub _update_unrest {
    my $self = shift;

    $self->{unrest} = int( $self->unrest * UNREST_FACTOR ) + $self->_unrest;

    return;
}

sub _quit_game {
    my $self = shift;

    # empty the stack, don't clear it or it will re-initialize!
    $self->{_steps} = [];
    $self->_set_status(QUIT_GAME);

    return;
}

sub _end_of_game_check {
    my $self = shift;

    my $msg = '';

    if ( $self->status eq QUIT_GAME ) {
        $msg = "\nYou have conceded the game\n\n";
    }
    elsif (( $self->grain < MIN_GRAIN )
        || ( $self->_unrest > MAX_1YEAR_UNREST )
        || ( $self->unrest > MAX_TOTAL_UNREST ) )
    {
        $msg = "\nThe peasants tire of war and starvation\n";
        $msg .= "You are deposed!\n\n";

        $self->_set_status(DEPOSED);
    }
    elsif ( $self->population < MIN_POPULATION ) {
        $msg = "You have so few peasants left that\n";
        $msg .= "the High King has abolished your Ducal right\n\n";

        $self->_set_status('ABOLISHED');
    }
    elsif ( $self->land < MIN_LAND ) {
        $msg = "You have so little land left that\n";
        $msg .= "the High King has abolished your Ducal right\n\n";

        $self->_set_status(ABOLISHED);
    }
    elsif ( $self->year >= MAX_YEAR && !$self->king_unrest ) {
        $msg = "You have reached the age of mandatory retirement\n\n";

        $self->_set_status(RETIRED);
    }

    $self->throw($msg) if $self->game_over;

    return;
}

sub _insufficient_grain {
    my $self   = shift;
    my $action = shift;

    my %msgs = (
        feed => sprintf( "You have %d HL. of grain left,\n", $self->grain ),
        buy  => sprintf( "Enough to buy %d HA. of land\n",
            int( $self->grain / $self->_land->{price} ) ),
        plant => sprintf( "Enough to plant %d HA. of land\n\n",
            int( $self->grain / SEED_PER_HA ) ),
    );

    my $msg = "You don't have enough grain\n";
    $msg .= $msgs{$action};

    return $msg;
}

sub _prep_detail_report {
    my $self = shift;

    my $msg = "\n";
    for ( sort( keys( %{ $self->_population } ) ) ) {
        $msg .= sprintf( "%-20.20s %d\n", $_, $self->_population->$_ );
    }
    $msg .= sprintf( "%-20.20s %d\n\n", "Peasants at end", $self->population );

    for ( sort( keys( %{ $self->_land } ) ) ) {
        $msg .= sprintf( "%-20.20s %d\n", $_, $self->_land->$_ );
    }
    $msg .= sprintf( "%-20.20s %d\n\n", "Land at end", $self->land );

    for ( sort( keys( %{ $self->_grain } ) ) ) {
        $msg .= sprintf( "%-20.20s %d\n", $_, $self->_grain->$_ );
    }
    $msg .= sprintf( "%-20.20s %d\n\n", "Grain at end", $self->grain );

    for ( sort( keys( %{ $self->_war } ) ) ) {
        $msg .= sprintf( "%-20.20s %d\n", $_, $self->_war->$_ );
    }

    $self->{detail_report} = $msg;

    return;
}

1;

__END__

=pod

=head1 NAME

Games::Dukedom - The classic big-iron game

=head1 SYNOPSIS

  
 use Games::Dukedom;
  
 my $game = Games::Dukedom->new();
  

=head1 DESCRIPTION

This is an implementation of the classic game of "Dukedom". It is intended
to be display agnostic so that it can be used not only by command line
scripts such as the one included but also by graphical UIs such as Tk
or web sites.

It has been implemented as an "interrupt driven" state-machine. The actual
executable application need only concern itself with displaying messages
and collecting appropriate input as requested.

Here is a minimal script that implements a fully functional game:

  
 #!/usr/local/bin/perl
  
 $| = 1;
  
 use strict;
 use warnings;
  
 use Scalar::Util qw( blessed );
 use Try::Tiny;
  
 use Games::Dukedom;
  
 my $input_yn = sub {
    my $default = shift || '';
  
    my $ans = <>;
    chomp($ans);
    $ans ||= $default;
  
    return ( $ans =~ /^(?:q|quit)\s*$/i || $ans =~ /^(?:y|n)$/i )
      ? lc($ans)
      : undef;
 };
  
 my $input_value = sub {
    my $default = shift || 0;
  
    my $ans = <>;
    chomp($ans);
    $ans = $default unless length($ans);
  
    return ( $ans =~ /^(?:q|quit)\s*$/i || $ans !~ /\D/ ) ? $ans : undef;
 };
  
 my %actions = (
    get_yn    => $input_yn,
    get_value => $input_value,
 );
  
 play_game();
  
 exit;
  
 sub play_game {
    my $game = Games::Dukedom->new;
  
    do {
        try {
            $game->play_one_year;
        }
        catch {
            if ( blessed($_) && $_->isa('Games::Dukedom::Signal') ) {
                print $_->msg if $_->msg;
                return unless defined( $_->action );
  
                my $action = $_->action;
                $game->input( &{ $actions{$action} }( $_->default ) );
            }
            else {
                die $_;
            }
        };
    } until ( $game->game_over );
  
    return;
 }
  
 __END__
  

The important thing to take away from this is how C<play_one_year> is wrapped
in a try/catch construct and how the script displays messages and requests
input as needed. This is the heart of the state-machine design.

All of the logic for the game is provided by the module itself and any given
implementation framework need only handle the I/O as needed.

=head1 CONSTRUCTOR

One begins the game by calling the expected C<new> method like so:

  
 my $game = Games::Dukedom->new();
  
  
It currently does not take any parameters.

=head2 ATTRIBUTES

All attributes, except for C<input>, have read-only accessors.

It should be noted that the values in the attributes will probably not be
of much use to a game implementation other than to provide specialized reports
if so desired, hence the reason for being read-only (except for the obvious
case of C<input>).

On the other hand, they do provide the current environment for a given year
of play and B<must> be preserved at all times. It is anticipated that a
stateless environment such as a CGI script will need to save state in some
fashion when requesting input and then restore it prior to applying the
input and re-entering the state-machine.

=over 4

=item input (read-write)

This attribute should hold the latest value requested by the state-machine.
It will recognize the values 'q' and 'quit' (case-insensitive) and set
the game status to C<QUIT_GAME> if either of those are submitted.

=item grain

The current amount of grain on hand.

=item king_unrest

Used to indicate the level of the King's mistrust.

=item land

The current amount of land on hand.

=item land_fertility

A hash containing "buckets" that indicate how much land is in what condition
of productivity at any given time. The game assumes that land that is planted
will lose 20% of it's full productivity each each it is used without being
allowed to lie fallow.

Basically this means that you should have twice as much total land available
as what is needed to plant to ensure 100% productivity each year.

=item population

The current number of peasants in the Dukedom.

=item status

Indicates that the game is either C<RUNNING> or in one of the conditions that
indicate that the end of the game has been reached.

A "win" is indicated by a positive value, a "loss" by a negative one.

=over 4

=item 2 - It's GOOD to be the King!

=item 1 - You have retired

=item 0 - Game is running

=item -1 - You have abandoned the game

=item -2 - You have been deposed

=item -3 - Don't mess with the King!

=back

=item unrest

Holds the cummulative population unrest factor. There is also an annual
unrest factor that gets reset at the start of each game year. The two are
relatively independent in that an excess of either one can cause you
to be deposed and end the game.

=item tax_paid

Total amount of taxes paid to the King since the beginnig of the game.

=item year

The current game year. The will automatically end with you being forced into
retirement at the end of 45 years unless some other cause occurs first.

NOTE: This will be ignored if a state of war currently exists between you and
the King that must be resolved.

=item yield

The amound of grain produced in the prior yield expressed as HL/HA.

=back

=head1 METHODS

=head2 play_one_year

This method begins a new year of play. It initializes the temporary structures
and factors and resets the state-machine.

Note: The caller should trap any errors thrown by this method to determine
the correct course of action to take based on the value of the exception's
C<msg> and C<action> attributes.

=head2 game_over

Boolean that indicates that current game is over and further play is not
possible. Check C<status> for reason if desired.

=head2 input_is_yn

Boolean that returns C<1> if the current content of C<< $game->input >>
is either "Y" or "N" (case insensitive) or C<undef> otherwise.

=head2 input_is_value

Boolean that returns C<1> if the current content of C<< $game->input >>
is "0" or a positive integer and C<undef> otherwise.

=head1 SEE ALSO

L<Games::Dukedom::Signal>

This package is based on the logic found in this C code, which appears to
have been derived from an older source written in Basic:

L<https://github.com/caryo/Dukedom/blob/master/imports/dukedom.c>

A good description of the goals of the game and how to play is here:

L<http://dukedomsbv.codeplex.com/documentation>

and here:

L<http://www.atariarchives.org/bigcomputergames/showpage.php?page=11>

=head1 BUGS

Seriously? Look at the version number.

=head1 AUTHOR

Jim Bacon, E<lt>jim@nortx.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Jim Bacon

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself, either Perl version 5.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
