use utf8;

package Interchange6::Schema::Result::Tax;

=head1 NAME

Interchange6::Schema::Result::Tax

=cut

use strict;
use warnings;
use DateTime;
use POSIX qw/ceil floor/;

use Interchange6::Schema::Candy -components => [
    qw(InflateColumn::DateTime TimeStamp
      +Interchange6::Schema::Component::Validation)
];

=head1 DESCRIPTION

The taxes table contains taxes such as sales tax and VAT. Each tax has a unique tax_name but can contain multiple rows for each tax_name to allow for changes in tax rates over time. When there is more than one row for a single tax_name then the valid_from and valid_to periods may not overlap.

=head1 ACCESSORS

=head2 taxes_id

Primary key.

=cut

primary_column taxes_id => {
    data_type         => "integer",
    is_auto_increment => 1,
    sequence          => "taxes_id_seq"
};

=head2 tax_name

Name of tax, e.g.: vat_full

=cut

column tax_name => { data_type => "varchar", size => 64 };

=head2 description

Description of tax, e.g.: New York sales tax

=cut

column description => { data_type => "varchar", size => 64 };

=head2 percent

Percent rate of tax, e.g.: 19.9775

=cut

column percent =>
  { data_type => "numeric", size => [ 7, 4 ] };

=head2 decimal_places

Number of decimal_places of precision required for tax cost and reporting.

Defaults to 2.

=cut

column decimal_places =>
  { data_type => "integer", default_value => 2 };

=head2 rounding

Default rounding is half round up to the number of decimal_places. To use floor or ceiling set rounding to 'f' or 'c' as appropriate. The rounding value is automatically converted to lower case and any invalid value passed in will cause an exception to be thrown.

Is nullable.

=cut

column rounding =>
  { data_type => "char", is_nullable => 1, size => 1 };

=head2 valid_from

Date from which tax is valid. Defaults to time record is created.

=cut

column valid_from =>
  { data_type => "date", set_on_create => 1 };

=head2 valid_to

Final date on which tax is valid.

Is nullable.

=cut

column valid_to => { data_type => "date", is_nullable => 1 };

=head2 country_iso_code

FK on L<Interchange6::Schema::Result::Country/country_iso_code>.

Is nullable.

=cut

column country_iso_code =>
  { data_type => "char", is_nullable => 1, size => 2 };

=head2 states_id

FK on L<Interchange6::Schema::Result::State/states_id>.

Is nullable.

=cut

column states_id =>
  { data_type => "integer", is_nullable => 1 };

=head2 created

Date and time when this record was created returned as L<DateTime> object.
Value is auto-set on insert.

=cut

column created =>
  { data_type => "datetime", set_on_create => 1 };

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

=head2 state

Type: belongs_to

Related object: L<Interchange6::Schema::Result::State>

=cut

belongs_to
  state => "Interchange6::Schema::Result::State",
  'states_id',
  {
    is_deferrable => 1,
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
    order_by      => 'name',
    join_type     => 'left',
  };

=head2 country

Type: belongs_to

Related object: L<Interchange6::Schema::Result::Country>

=cut

belongs_to
  country => "Interchange6::Schema::Result::Country",
  'country_iso_code',
  {
    is_deferrable => 1,
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
    order_by      => 'name',
    join_type     => 'left',
  };

=head1 METHODS

=head2 calculate

Calculate tax

Arguments should be a hash ref of the following arguments:

=over 4

=item * price

Price of product either inclusive or exclusive of tax - required.

=item * tax_included

Boolean indicating whether price is inclusive of tax or not. Defaults to 0 which means exclusive of tax.

Will throw an exception if the price us not numeric.

=back

Usage example:

    my $tax = $taxrecord->caclulate({ price => 13.47, tax_included => 1 });

    # with percentage 18 our tax is 2.05

=cut

sub calculate {
    my $self = shift;
    my $args = shift;

    my $schema = $self->result_source->schema;
    my $dtf    = $schema->storage->datetime_parser;
    my $dt     = DateTime->today;
    my $tax;

    $schema->throw_exception("argument price is missing")
      unless defined $args->{price};

    $schema->throw_exception(
        "argument price is not a valid numeric: " . $args->{price} )
      unless $args->{price} =~ m/^(\d+)*(\.\d+)*$/;

    if ( $args->{tax_included} ) {
        my $nett = $args->{price} / ( 1 + ( $self->percent / 100 ) );
        $tax = $args->{price} - $nett;
    }
    else {
        $tax = $args->{price} * $self->percent / 100;
    }

    # round & return

    my $decimal_places = $self->decimal_places;

    unless ( $self->rounding ) {

        return sprintf( "%.${decimal_places}f", $tax );
    }
    else {

        $tax *= 10**$decimal_places;

        if ( $self->rounding eq 'c' ) {
            $tax = ceil($tax) / ( 10**$decimal_places );
        }
        elsif ( $self->rounding eq 'f' ) {
            $tax = floor($tax) / ( 10**$decimal_places );
        }
        else {

            # should not be possible to get here
            $schema->throw_exception(
                "rounding value from database is invalid: " . $self->rounding );
        }

        return sprintf( "%.${decimal_places}f", $tax );
    }
}

=head1 INHERITED METHODS

=head2 new

We overload the new method to set default values on certain rows at create time.

=cut

sub new {
    my ( $class, $attrs ) = @_;

    my %attrs = %$attrs;

    $attrs->{decimal_places} = 2 unless defined $attrs->{decimal_places};

    my $new = $class->next::method( \%attrs );

    return $new;
}

=head2 sqlt_deploy_hook

Called during table creation to add indexes on the following columns:

=over 4

=item * tax_name

=item * valid_from

=item * valid_to

=back

=cut

sub sqlt_deploy_hook {
    my ( $self, $table ) = @_;

    $table->add_index( name => 'taxes_idx_tax_name', fields => ['tax_name'] );
    $table->add_index(
        name   => 'taxes_idx_valid_from',
        fields => ['valid_from']
    );
    $table->add_index(
        name   => 'taxes_idx_valid_to',
        fields => ['valid_to']
    );
}

=head2 validate

Validity checks that cannot be enforced using primary key, unique or other database methods using L<Interchange6::Schema::Component::Validation>. The validity checks enforce the following rules:

=over 4

=item * Check country_iso_code is valid

=item * If both valid_from and valid_to are defined then valid_to must be a later date than valid_from.

=item * A single tax_name may appear more than once in the table to allow for changes in tax rates but valid_from/valid_to date ranges must not overlap.

=back

=cut

sub validate {
    my $self   = shift;
    my $schema = $self->result_source->schema;
    my $dtf    = $schema->storage->datetime_parser;
    my $rset;

    # country iso code

    if ( defined $self->country_iso_code ) {
        $rset =
          $schema->resultset('Country')
          ->search( { country_iso_code => $self->country_iso_code } );
        if ( $rset->count == 0 ) {
            $schema->throw_exception(
                'country_iso_code not valid: ' . $self->country_iso_code );
        }
    }

    # rounding

    if ( defined $self->rounding ) {

        # set lower case

        my $rounding = lc( $self->rounding );
        $self->rounding($rounding);

        unless ( $self->rounding =~ /^(c|f)$/ ) {
            $self->rounding(undef);
            $schema->throw_exception(
                'value for rounding not c, f or undef: ' . $rounding );
        }
    }

    # check that valid_to is later than valid_from (if it is defined)

    $self->valid_from->truncate( to => 'day' );

    if ( defined $self->valid_to ) {

        # remove time - we only want the date
        $self->valid_to->truncate( to => 'day' );

        unless ( $self->valid_to > $self->valid_from ) {
            $schema->throw_exception("valid_to is not later than valid_from");
        }
    }

    # grab our resultset

    $rset = $self->result_source->resultset;

    if ( $self->in_storage ) {

        # this is an update so we must exclude our existing record from
        # the resultset before range overlap checks are performed

        $rset = $rset->search( { taxes_id => { '!=', $self->taxes_id } } );
    }

    # multiple entries for a single tax code do not overlap dates

    if ( defined $self->valid_to ) {
        $rset = $rset->search(
            {
                tax_name => $self->tax_name,
                -or      => [
                    valid_from => {
                        -between => [
                            $dtf->format_datetime( $self->valid_from ),
                            $dtf->format_datetime( $self->valid_to ),
                        ]
                    },
                    valid_to => {
                        -between => [
                            $dtf->format_datetime( $self->valid_from ),
                            $dtf->format_datetime( $self->valid_to ),
                        ]
                    },
                ],
            }
        );

        if ( $rset->count > 0 ) {
            $schema->throw_exception(
                'tax overlaps existing date range: ' . $self->tax_name );
        }
    }
    else {
        $rset = $rset->search(
            {
                tax_name => $self->tax_name,
                -or      => [
                    {
                        valid_to => undef,
                        valid_from =>
                          { '<=', $dtf->format_datetime( $self->valid_from ) },
                    },
                    {
                        valid_to => { '!=', undef },
                        valid_to =>
                          { '>=', $dtf->format_datetime( $self->valid_from ) },
                    },
                ],
            }
        );
    }
    if ( $rset->count > 0 ) {
        $schema->throw_exception('tax overlaps existing date range');
    }
}

1;
