package Finance::Contract;

use strict;
use warnings;

our $VERSION = '0.009';

=head1 NAME

Finance::Contract - represents a contract object for a single bet

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    use feature qw(say);
    use Finance::Contract;
    # Create a simple contract
    my $contract = Finance::Contract->new(
        contract_type => 'CALLE',
        duration      => '5t',
    );

=head1 DESCRIPTION

This is a generic abstraction for financial stock market contracts.

=head2 Construction

    Finance::Contract->new({
        underlying    => 'frxUSDJPY',
        contract_type => 'CALL',
        date_start    => $now,
        duration      => '5t',
        currency      => 'USD',
        payout        => 100,
        barrier       => 100,
    });

=head2 Dates

All date-related parameters:

=over 4

=item * L</date_pricing>

=item * L</date_expiry>

=item * L</date_start>

=back

are L<Date::Utility> instances. You can provide them as epoch values
or L<Date::Utility> objects.

=cut

use Moose;
use MooseX::Types::Moose qw(Int Num Str);
use MooseX::Types -declare => ['contract_category'];
use Moose::Util::TypeConstraints;

use Time::HiRes qw(time);
use List::Util qw(min max first);
use Scalar::Util qw(looks_like_number);
use Math::Util::CalculatedValue::Validatable;
use Date::Utility;
use Format::Util::Numbers qw(roundnear);
use POSIX qw( floor );
use Time::Duration::Concise;

# Types used for date+time-related handling

use Finance::Contract::Category;

use constant _FOREX_BARRIER_MULTIPLIER => 1e6;

unless(find_type_constraint('time_interval')) {
    subtype 'time_interval', as 'Time::Duration::Concise';
    coerce 'time_interval',  from 'Str', via { Time::Duration::Concise->new(interval => $_) };
}

unless(find_type_constraint('date_object')) {
    subtype 'date_object',   as 'Date::Utility';
    coerce 'date_object', from 'Str', via { Date::Utility->new($_) };
}

my @date_attribute = (
    isa        => 'date_object',
    lazy_build => 1,
    coerce     => 1,
);

=head1 ATTRIBUTES

These are the parameters we expect to be passed when constructing a new contract.

=cut

=head2 bet_type

(required) The type of this contract as an upper-case string.

Current types include:

=over 4

=item * ASIAND

=item * ASIANU

=item * CALL

=item * CALLE

=item * DIGITDIFF

=item * DIGITEVEN

=item * DIGITMATCH

=item * DIGITODD

=item * DIGITOVER

=item * DIGITUNDER

=item * EXPIRYMISS

=item * EXPIRYMISSE

=item * EXPIRYRANGE

=item * EXPIRYRANGEE

=item * NOTOUCH

=item * ONETOUCH

=item * PUT

=item * PUTE

=item * RANGE

=item * UPORDOWN

=back

=cut

has bet_type => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

=head2 currency

(required) The currency of the payout for this contract, e.g. C<USD>.

=cut

has currency => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

=head2 date_expiry

(optional) When the contract expires.

One of C<date_expiry> or L</duration> must be provided.

=cut

has date_expiry => (
    is => 'rw',
    @date_attribute,
);

=head2 date_pricing

(optional) The date at which we're pricing the contract. Provide C< undef > to indicate "now".

=cut

has date_pricing => (
    is => 'ro',
    @date_attribute,
);

=head2 date_start

For American contracts, defines when the contract starts.

For Europeans, this is used to determine the barrier when the requested barrier is relative.

=cut

has date_start => (
    is => 'ro',
    @date_attribute,
);

=head2 duration

(optional) The requested contract duration, specified as a string indicating value with units.
The unit is provided as a single character suffix:

=over 4

=item * t - ticks

=item * s - seconds

=item * m - minutes

=item * h - hours

=item * d - days

=back

Examples would be C< 5t > for 5 ticks, C< 3h > for 3 hours.

One of L</date_expiry> or C<duration> must be provided.

=cut

has duration => (is => 'ro');

=head2 is_forward_starting

True if this contract is considered as forward-starting at L</date_pricing>.

=cut

# TODO This should be a method, but will cause test failures since there are
# places where we set this explicitly.
has is_forward_starting => (
    is         => 'ro',
    lazy_build => 1,
);

=head2 payout

Payout amount value, see L</currency>. Optional - only applies to binaries.

=cut

has payout => (
    is         => 'ro',
    isa        => 'Num',
    lazy_build => 1,
);

=head2 prediction

Prediction (for tick trades) is what client predicted would happen.

=cut

has prediction => (
    is  => 'ro',
    isa => 'Maybe[Num]',
);

=head2 starts_as_forward_starting

This attribute tells us if this contract was initially bought as a forward starting contract.
This should not be mistaken for L</is_forward_starting> attribute as that could change over time.

=cut

has starts_as_forward_starting => (
    is      => 'ro',
    default => 0,
);

=head2 pip_size

Barrier pip size the minimum fluctuation amount for type of market. It is normally fraction.

=cut

has pip_size => (
    is         => 'ro',
    isa        => 'Num',
    lazy_build => 1
);

=head2 absolute_barrier_multiplier

Should barrier multiplier be applied for absolute barried on this market

=cut

has 'absolute_barrier_multiplier' => (
    is  => 'ro',
    isa => 'Bool',
);

=head2 supplied_barrier_type

One of:

=over 4

=item * C<relative> - this is of the form C<< S10P >> or C<< S-4P >>, which would be 10 pips above the spot
or 4 pips below the spot.

=item * C<absolute> - this is a number that can be compared directly with the spot, e.g. C<< 103.45 >>.

=item * C<difference> - a numerical difference from the spot, can be negative, e.g. C<< -0.035 >>.

=back

=cut

has supplied_barrier_type => (
    is         => 'ro',
);

=head2 supplied_high_barrier

For a 2-barrier contract, this is the high barrier string. The meaning of these barrier values is controlled by L</supplied_barrier_type>.

=head2 supplied_low_barrier

For a 2-barrier contract, this is the low barrier string.

=head2 supplied_barrier

For a single-barrier contract, this is the barrier string.

=cut

has [qw(supplied_barrier supplied_high_barrier supplied_low_barrier)] => (is => 'ro');

=head2 tick_count

Number of ticks in this trade.

=cut

has tick_count => (
    is  => 'ro',
    isa => 'Maybe[Num]',
);

has remaining_time => (
    is         => 'ro',
    isa        => 'Time::Duration::Concise',
    lazy_build => 1,
);

=head2 underlying_symbol

The underlying asset, as a string (for example, C< frxUSDJPY >).

=cut

has xxx_underlying_symbol => (
    is  => 'ro',
    isa => 'Str',
);

# This is needed to determine if a contract is newly priced
# or it is repriced from an existing contract.
# Milliseconds matters since UI is reacting much faster now.
has _date_pricing_milliseconds => (
    is => 'rw',
);

=head1 ATTRIBUTES - From contract_types.yml

=head2 id

A unique numeric ID.

=head2 pricing_code

Used to determine the pricing engine that should be used for this contract. Examples
include 'PUT' or 'CALL'.

=head2 display_name

This is a human-readable name for the contract type, brief description of what it does.

=head2 sentiment

Indicates whether we are speculating on market rise or fall.

=head2 other_side_code

Opposite type for this contract - PUT for CALL, etc.

=head2 payout_type

Either C< binary > or C< non-binary >.

=head2 payouttime

Indicates when the contract pays out. Can be C< end > or C< hit >.

=cut

has [qw(id pricing_code display_name sentiment other_side_code payout_type payouttime)] => (
    is      => 'ro',
    default => undef,
);

=head1 ATTRIBUTES - From contract_categories.yml

=cut

subtype 'contract_category', as 'Finance::Contract::Category';
coerce 'contract_category', from 'Str', via { Finance::Contract::Category->new($_) };

has category => (
    is      => 'ro',
    isa     => 'contract_category',
    coerce  => 1,
    handles => [qw(
        allow_forward_starting
        barrier_at_start
        is_path_dependent
        supported_expiries
        two_barriers
    )],
);

=head2 allow_forward_starting

True if we allow forward starting for this contract type.

=cut

=head2 barrier_at_start

Boolean which will false if we don't know what the barrier is at the start of the contract (Asian contracts).

=cut

=head2 category_code

The code for this category.

=cut

sub category_code {
    my $self = shift;
    return $self->category->code;
}

=head2 is_path_dependent

True if this is a path-dependent contract.

=cut

=head2 supported_expiries

Which expiry durations we allow for this category. Values can be:

=over 4

=item * intraday

=item * daily

=item * tick

=back

=cut

=head2 two_barriers

True if the contract has two barriers.

=cut

=head1 METHODS

=cut

our $BARRIER_CATEGORIES = {
    callput      => ['euro_atm', 'euro_non_atm'],
    endsinout    => ['euro_non_atm'],
    touchnotouch => ['american'],
    staysinout   => ['american'],
    digits       => ['non_financial'],
    asian        => ['asian'],
};

=head2 barrier_category

Type of barriers we have for this contract, depends on the contract type.

Possible values are:

=over 4

=item * C<american> - barrier for American-style contract

=item * C<asian> - Asian-style contract

=item * C<euro_atm> - at-the-money European contract

=item * C<euro_non_atm> - non-at-the-money European contract

=item * C<non_financial> - digits

=back

=cut

sub barrier_category {
    my $self = shift;

    my $barrier_category;
    if ($self->category->code eq 'callput') {
        $barrier_category = ($self->is_atm_bet) ? 'euro_atm' : 'euro_non_atm';
    } else {
        $barrier_category = $BARRIER_CATEGORIES->{$self->category->code}->[0];
    }

    return $barrier_category;
}

=head2 effective_start

=over 4

=item * For backpricing, this is L</date_start>.

=item * For a forward-starting contract, this is L</date_start>.

=item * For all other states - i.e. active, non-expired contracts - this is L</date_pricing>.

=back

=cut

sub effective_start {
    my $self = shift;

    return
          ($self->date_pricing->is_after($self->date_expiry)) ? $self->date_start
        : ($self->date_pricing->is_after($self->date_start))  ? $self->date_pricing
        :                                                       $self->date_start;
}

=head2 fixed_expiry

A Boolean to determine if this bet has fixed or flexible expiries.

=cut

has fixed_expiry => (
    is      => 'ro',
    default => 0,
);

=head2 get_time_to_expiry

Returns a TimeInterval to expiry of the bet. For a forward start bet, it will NOT return the bet lifetime, but the time till the bet expires.

If you want to get the contract life time, use:

    $contract->get_time_to_expiry({from => $contract->date_start})

=cut

sub get_time_to_expiry {
    my ($self, $attributes) = @_;

    $attributes->{'to'} = $self->date_expiry;

    return $self->_get_time_to_end($attributes);
}

=head2 is_after_expiry

Returns true if the contract is already past the expiry time.

=cut

sub is_after_expiry {
    my $self = shift;

    die "Not supported for tick expiry contracts" if $self->tick_expiry;

    return ($self->get_time_to_expiry->seconds == 0) ? 1 : 0;
}

=head2 is_atm_bet

Is this contract meant to be ATM or non ATM at start?
The status will not change throughout the lifetime of the contract due to differences in offerings for ATM and non ATM contracts.

=cut

sub is_atm_bet {
    my $self = shift;

    return 0 if $self->two_barriers;
    # if not defined, it is non ATM
    return 0 if not defined $self->supplied_barrier;
    return 0 if $self->supplied_barrier ne 'S0P';
    return 1;
}

=head2 shortcode

This is a compact string representation of a L<Finance::Contract> object. It includes all data needed to
reconstruct a contract, with the exception of L</currency>.

=cut

sub shortcode {
    my $self = shift;

    my $shortcode_date_start = (
               $self->is_forward_starting
            or $self->starts_as_forward_starting
    ) ? $self->date_start->epoch . 'F' : $self->date_start->epoch;
    my $shortcode_date_expiry =
          ($self->tick_expiry)  ? $self->tick_count . 'T'
        : ($self->fixed_expiry) ? $self->date_expiry->epoch . 'F'
        :                         $self->date_expiry->epoch;

    # TODO We expect to have a valid bet_type, but there may be codepaths which don't set this correctly yet.
    my $contract_type = $self->bet_type // $self->code;
    my @shortcode_elements = ($contract_type, $self->underlying->symbol, $self->payout, $shortcode_date_start, $shortcode_date_expiry);

    if ($self->two_barriers) {
        push @shortcode_elements, map { $self->_barrier_for_shortcode_string($_) } ($self->supplied_high_barrier, $self->supplied_low_barrier);
    } elsif (defined $self->supplied_barrier and $self->barrier_at_start) {
        push @shortcode_elements, ($self->_barrier_for_shortcode_string($self->supplied_barrier), 0);
    }

    return uc join '_', @shortcode_elements;
}

=head2 tick_expiry

A boolean that indicates if a contract expires after a pre-specified number of ticks.

=cut

sub tick_expiry {
    my ($self) = @_;
    return $self->tick_count ? 1 : 0;
}

=head2 timeinyears

Contract duration in years.

=head2 timeindays

Contract duration in days.

=cut

has [qw(
        timeinyears
        timeindays
        )
    ] => (
    is         => 'ro',
    init_arg   => undef,
    isa        => 'Math::Util::CalculatedValue::Validatable',
    lazy_build => 1,
    );

sub _build_timeinyears {
    my $self = shift;

    my $tiy = Math::Util::CalculatedValue::Validatable->new({
        name        => 'time_in_years',
        description => 'Bet duration in years',
        set_by      => 'Finance::Contract',
        base_amount => 0,
        minimum     => 0.000000001,
    });

    my $days_per_year = Math::Util::CalculatedValue::Validatable->new({
        name        => 'days_per_year',
        description => 'We use a 365 day year.',
        set_by      => 'Finance::Contract',
        base_amount => 365,
    });

    $tiy->include_adjustment('add',    $self->timeindays);
    $tiy->include_adjustment('divide', $days_per_year);

    return $tiy;
}

sub _build_timeindays {
    my $self = shift;

    my $atid = $self->get_time_to_expiry({
            from => $self->effective_start,
        })->days;

    my $tid = Math::Util::CalculatedValue::Validatable->new({
        name        => 'time_in_days',
        description => 'Duration of this bet in days',
        set_by      => 'Finance::Contract',
        minimum     => 0.000001,
        maximum     => 730,
        base_amount => $atid,
    });

    return $tid;
}

# INTERNAL METHODS

# Send in the correct 'to'
sub _get_time_to_end {
    my ($self, $attributes) = @_;

    my $end_point = $attributes->{to};
    my $from = ($attributes and $attributes->{from}) ? $attributes->{from} : $self->date_pricing;

    # Don't worry about how long past expiry
    # Let it die if they gave us nonsense.

    return Time::Duration::Concise->new(
        interval => max(0, $end_point->epoch - $from->epoch),
    );
}

#== BUILDERS =====================

sub _build_date_pricing {
    return Date::Utility->new;
}

sub _build_is_forward_starting {
    my $self = shift;

    return ($self->allow_forward_starting and $self->date_pricing->is_before($self->date_start)) ? 1 : 0;
}

sub _build_remaining_time {
    my $self = shift;

    my $when = ($self->date_pricing->is_after($self->date_start)) ? $self->date_pricing : $self->date_start;

    return $self->get_time_to_expiry({
        from => $when,
    });
}

sub _build_date_start {
    return Date::Utility->new;
}

# Generates a string version of a barrier by multiplying the actual barrier to remove the decimal point
sub _barrier_for_shortcode_string {
    my ($self, $string) = @_;

    return $string if $self->supplied_barrier_type eq 'relative';
    return 'S' . roundnear(1, $string / $self->pip_size) . 'P' if $self->supplied_barrier_type eq 'difference';

    $string = $self->_pipsized_value($string);
    if ($self->bet_type !~ /^DIGIT/ && $self->absolute_barrier_multiplier) {
        $string *= _FOREX_BARRIER_MULTIPLIER;
    } else {
        $string = floor($string);
    }

    # Make sure it's an integer
    $string = roundnear(1, $string);

    return $string;
}

sub _pipsized_value {
    my ($self, $value) = @_;

    my $display_decimals = log(1 / $self->pip_size) / log(10);
    $value = sprintf '%.' . $display_decimals . 'f', $value;
    return $value;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
