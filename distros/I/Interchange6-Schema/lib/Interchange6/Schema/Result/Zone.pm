use utf8;

package Interchange6::Schema::Result::Zone;

=head1 NAME

Interchange6::Schema::Result::Zone

=cut

use DateTime;
use Scalar::Util qw(blessed);

use Interchange6::Schema::Candy -components =>
  [qw(InflateColumn::DateTime TimeStamp)];

=head1 DESCRIPTION

In the context of zones the term 'state' refers to state, province or other principal subdivision of a country as defined in L<ISO 3116-2|http://en.wikipedia.org/wiki/ISO_3166-2>. Countries to be added to a zone must already exist in L<Interchange6::Schema::Result::Country> and states in L<Interchange6::Schema::Result::State>.

Zones can contain any of the following:

=over 4

=item * No countries and no states

An empty zone must be created before countries/states are added but otherwise is probably not useful.

=item * Multiple countries

For example to create a trading group like the European Union.

=item * A single country


=item * A single country with a single state

For example Quebec in Canada which has GST + QST

=item * A single country with multiple states

For example a group containing all Canadian provinces that charge only GST.

=back

The following combinations are NOT allowed:

=over 4

=item * Multiple countries with one or more states

=item * One or more states with no country

=back

Countries and states should be added to and removed from the zone using these methods which are described further below:

=over 4

=item * add_countries

=item * remove_countries

=item * add_states

=item * remove_states

=back

B<NOTE:> avoid using other methods from L<DBIx::Class::Relationship::Base> since you may inadvertently end up with an invalid zone.

=head1 ACCESSORS

=head2 zones_id

Primary Key.

=cut

primary_column zones_id => {
    data_type         => "integer",
    is_auto_increment => 1,
    sequence          => "zones_id_seq"
};

=head2 zone

For example for storing the UPS/USPS zone code or a simple name for the zone.

Unique constraint.

=cut

unique_column zone => { data_type => "varchar", size => 255 };

=head2 created

Date and time when this record was created returned as L<DateTime> object.
Value is auto-set on insert.

=cut

column created => { data_type => "datetime", set_on_create => 1 };

=head2 last_modified

Date and time when this record was last modified returned as L<DateTime> object.
Value is auto-set on insert and update.

=cut

column last_modified => {
    data_type     => "datetime",
    set_on_create => 1,
    set_on_update => 1,
};

=head1 RELATIONS

=head2 zone_countries

Type: has_many

Related object: L<Interchange6::Schema::Result::ZoneCountry>

=cut

has_many
  zone_countries => "Interchange6::Schema::Result::ZoneCountry",
  "zones_id",
  { cascade_copy => 0, cascade_delete => 0 };

=head2 countries

Type: many_to_many

Accessor to related country results ordered by name.

=cut

many_to_many
  countries => "zone_countries",
  "country",
  { order_by => 'country.name' };

=head2 zone_states

Type: has_many

Related object: L<Interchange6::Schema::Result::ZoneState>

=cut

has_many
  zone_states => "Interchange6::Schema::Result::ZoneState",
  "zones_id",
  { cascade_copy => 0, cascade_delete => 0 };

=head2 states

Type: many_to_many

Accessor to related state results ordered by name.

=cut

many_to_many
  states => "zone_states",
  "state", { order_by => 'state.name' };

=head2 shipment_destinations

C<has_many> relationship with
L<Interchange6::Schema::Result::ShipmentDestination>

=cut

has_many
  shipment_destinations => "Interchange6::Schema::Result::ShipmentDestination",
  "zones_id";

=head2 shipment_methods

C<many_to_many> relationship to shipment_method. Currently it ignores
the C<active> field in shipment_destinations.

=cut

many_to_many shipment_methods => "shipment_destinations", "shipment_method";

=head1 METHODS

=head2 new

Overloaded method. We allow a form of multi-create here so you can do something like:

    $schema->resultset('Zone')->create({
        zone      => 'some states of the USA',
        countries => [ 'US' ],
        states    => [ 'CA', 'PA' ],
    });

If there is only a single country or state the value can be a scalar instead of a hashref.

=cut

sub new {
    my ( $class, $attrs ) = @_;

    my ( $countries, $states, $new );

    if ( $attrs->{countries} ) {
        if ( ref( $attrs->{countries} ) eq 'ARRAY' ) {
            push @$countries, @{ $attrs->{countries} };
        }
        else {
            push @$countries, $attrs->{countries};
        }
        delete $attrs->{countries};

        if ( $attrs->{states} ) {
            if ( ref( $attrs->{states} ) eq 'ARRAY' ) {
                push @$states, @{ $attrs->{states} };
            }
            else {
                push @$states, $attrs->{states};
            }
            delete $attrs->{states};
        }
    }
    elsif ( $attrs->{states} ) {
        die "Cannot create Zone with states but without countries";
    }

    $new = $class->next::method($attrs);
    $new->add_countries($countries) if $countries;
    $new->add_states($states)       if $states;

    return $new;
}

=head2 add_countries

Argument is one of:

=over 4

=item an L<Interchange6::Schema::Result::Country> object

=item a country ISO code

=item an arrayref of the above (can include a mixture of both)

=back

Returns the zone object on success.

=cut

# add/remove_countries can be passed all sorts of junk but we need Country obj

sub _get_country_obj {

    my ( $self, $country ) = @_;

    if ( !defined $country ) {
        $self->throw_exception("Country must be defined");
    }
    elsif ( blessed($country) ) {

        my $class = ref($country);

        $self->throw_exception("Country cannot be a $class")
          unless $country->isa('Interchange6::Schema::Result::Country');

    }
    elsif ( $country =~ m/^[a-z]{2}$/i ) {

        my $result = $self->result_source->schema->resultset("Country")
          ->find( { country_iso_code => uc($country) } );

        $self->throw_exception("No country found for code: $country")
          unless defined $result;

        $country = $result;
    }
    else {
        $self->throw_exception("Bad country: $country");
    }

    return $country;
}

sub add_countries {
    my ( $self, $arg ) = ( shift, shift );

    my $schema = $self->result_source->schema;

    if ( $self->state_count > 0 ) {
        $self->throw_exception(
            "Cannot add countries to zone containing states");
    }
    elsif ( ref($arg) ne "ARRAY" ) {

        # we need an arrayref
        $arg = [$arg];
    }

    # use a transaction when adding countries so that all succeed or all fail

    my $guard = $schema->txn_scope_guard;

    foreach my $country (@$arg) {

        $country = $self->_get_country_obj($country);

        if ( $self->has_country($country) ) {
            $self->throw_exception(
                "Zone already includes country: " . $country->name );
        }

        $self->add_to_countries($country);
    }

    $guard->commit;

    return $self;
}

=head2 has_country

Argument can be Interchange6::Schema::Result::Country, country name or iso code. Returns 1 if zone includes that country else 0;

=cut

sub has_country {
    my ( $self, $country ) = ( shift, shift );
    my $rset;

    # first try Country object

    if ( blessed($country) ) {
        if ( $country->isa('Interchange6::Schema::Result::Country') ) {

            $rset = $self->countries->search(
                { "country.country_iso_code" => $country->country_iso_code, } );
            return 1 if $rset->count == 1;

        }
        else {
            return 0;
        }
    }
    else {

        # maybe an ISO code?

        if ( $country =~ /^[a-z]{2}$/i ) {

            $rset = $self->countries->search(
                { "country.country_iso_code" => uc($country) } );

            return 1 if $rset->count == 1;
        }
        else {

            # finally try country name

            $rset = $self->countries->search( { "country.name" => $country } );

            return 1 if $rset->count == 1;
        }
    }

    # failed to find the country
    return 0;
}

=head2 country_count

Takes no args. Returns the number of countries in the zone.

=cut

sub country_count {
    my $self = shift;
    return $self->countries->count;
}

=head2 remove_countries

Argument is either a L<Interchange6::Schema::Result::Country> object or an arrayref of the same.

Throws an exception on failure.

=cut

sub remove_countries {
    my ( $self, $arg ) = ( shift, shift );

    my $schema = $self->result_source->schema;

    if ( $self->state_count > 0 ) {

        $self->throw_exception("States must be removed before countries");

    }
    elsif ( ref($arg) ne "ARRAY" ) {

        # convert to arrayref
        $arg = [$arg];
    }

    # use a transaction when removing countries so that all succeed or all fail

    my $guard = $schema->txn_scope_guard;

    foreach my $country (@$arg) {

        $country = $self->_get_country_obj($country);

        unless ( $self->has_country($country) ) {
            $self->throw_exception(
                "Country does not exist in zone: " . $country->name );
        }

        $self->remove_from_countries($country);
    }

    $guard->commit;

    return $self;
}

=head2 add_states

Argument is one of:

=over 4

=item an L<Interchange6::Schema::Result::State> object

=item a state ISO code

=item an arrayref of the above (can include a mixture of both)

=back

Returns the zone object on success.

=cut

# add/remove_states can be passed all sorts of junk but we need State obj

sub _get_state_obj {

    my ( $self, $state ) = @_;

    # let Devel::Cover watch this for us since it should never happen
    # uncoverable branch true
    if ( !defined $state ) {
        # uncoverable statement
        $self->throw_exception("State must be defined");
    }
    elsif ( blessed($state) ) {

        my $class = ref($state);

        $self->throw_exception("State cannot be a $class")
          unless $state->isa('Interchange6::Schema::Result::State');

    }
    elsif ( $state =~ m/^[a-z]{2}$/i ) {

        if ( $self->country_count == 1 ) {

            my $result =
              $self->result_source->schema->resultset("State")->single(
                {
                    country_iso_code => {
                        -in => $self->countries->get_column('country_iso_code')
                          ->as_query
                    },
                    state_iso_code => uc($state),
                }
              );

            $self->throw_exception("No state found for code: $state")
              unless defined $result;

            $state = $result;

        }
        else {
            # We should have elsif/else as part of main if statement but
            # since we have an uncoverable branch and Devel::Cover is a bit
            # brain dead we have to split this up so. :(
            # uncoverable branch false
            if ( $self->country_count == 0 ) {

                $self->throw_exception(
                    "Cannot resolve state_iso_code for zone with no country");
            }
            else {
                # uncoverable statement
                $self->throw_exception(
                    "Cannot resolve state_iso_code for zone with > 1 country");
            }
        }
    }
    else {
        $self->throw_exception("Bad state: $state");
    }

    return $state;
}

sub add_states {
    my ( $self, $arg ) = ( shift, shift );

    my $schema = $self->result_source->schema;

    if ( $self->country_count > 1 ) {

        $self->throw_exception(
            "Cannot add state to zone with multiple countries");
    }
    elsif ( ref($arg) ne "ARRAY" ) {

        # we need an arayref
        $arg = [$arg];
    }

    # use a transaction when adding states so that all succeed or all fail

    my $guard = $schema->txn_scope_guard;

    foreach my $state (@$arg) {

        $state = $self->_get_state_obj($state);

        if ( $self->country_count == 0 ) {

            # add the country first

            $self->add_countries( $state->country );
        }
        else {

            # make sure state is in the existing country

            my $country = $self->countries->single;

            unless ( $country->country_iso_code eq
                $state->country->country_iso_code )
            {
                $self->throw_exception( "State "
                      . $state->name
                      . " is not in country "
                      . $country->name );
            }
        }

        if ( $self->has_state($state) ) {
            $self->throw_exception(
                "Zone already includes state: " . $state->name );
        }

        # try to add the state

        $self->add_to_states($state);
    }

    $guard->commit;

    return $self;
}

=head2 has_state

Argument can be Interchange6::Schema::Result::State, state name or iso code. Returns 1 if zone includes that state else 0;

=cut

sub has_state {
    my ( $self, $state ) = ( shift, shift );
    my $rset;

    # first try State object

    if ( blessed($state) ) {
        if ( $state->isa('Interchange6::Schema::Result::State') ) {

            $rset = $self->states->search(
                {
                    "state.country_iso_code" => $state->country_iso_code,
                    "state.state_iso_code"   => $state->state_iso_code
                }
            );
            return 1 if $rset->count == 1;

        }
        else {
            return 0;
        }
    }
    else {

        # maybe an ISO code?

        if ( $state =~ /^[a-z]{2}$/i ) {

            $rset = $self->states->search( { state_iso_code => uc($state) } );

            return 1 if $rset->count == 1;
        }
        else {

            # finally try state name

            $rset = $self->states->search( { name => $state } );

            return 1 if $rset->count == 1;

        }
    }

    # failed to find the state
    return 0;
}

=head2 state_count

Takes no args. Returns the number of states in the zone.

=cut

sub state_count {
    my $self = shift;
    return $self->states->search( {} )->count;
}

=head2 remove_states

Argument is either a L<Interchange6::Schema::Result::State> object or an arrayref of the same.

Returns the Zone object or undef on failure. Errors are available via errors method inherited from L<Interchange6::Schema::Role::Errors>.

=cut

sub remove_states {
    my ( $self, $arg ) = ( shift, shift );

    my $schema = $self->result_source->schema;

    if ( ref($arg) ne "ARRAY" ) {

        # we need an arrayref
        $arg = [$arg];
    }

    # use a transaction when removing states so that all succeed or all fail

    my $guard = $schema->txn_scope_guard;

    foreach my $state (@$arg) {

        $state = $self->_get_state_obj($state);

        $self->remove_from_states($state);
    }

    $guard->commit;

    return $self;
}

1;
