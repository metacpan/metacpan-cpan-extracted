use warnings;
use strict;

package Jifty::DBI::Column;

our $VERSION = '0.01';
use base qw/Class::Accessor::Fast Jifty::DBI::HasFilters/;
use UNIVERSAL::require;
use version;

my @attrs = qw/
    name
    type
    default
    readable writable
    max_length
    mandatory
    virtual
    computed
    distinct
    sort_order
    refers_to by
    alias_for_column
    aliased_as
    since till
    indexed
    _validator
    _checked_for_validate_sub
    record_class
    attributes
    case_sensitive
    private
    protected
    encode_on_select
    /;

# these actually live in the attributes hash
my @handy_attrs = qw/
    container
    label hints render_as
    display_length
    documentation
    valid_values
    available_values
    autocompleted
    no_placeholder
    /;

# compat: this should probably never exist and be deprecated
our @ATTRS = (@attrs, @handy_attrs);

__PACKAGE__->mk_accessors(@attrs);

for my $attr (@handy_attrs) {
    no strict 'refs';
    *$attr = sub {
        my $self = shift;
        $self->attributes({}) unless $self->attributes;
        return $self->attributes->{$attr} unless @_;
        $self->attributes->{$attr} = (@_ == 1 ? $_[0] : [@_]);
    }
}

=head1 NAME

Jifty::DBI::Column - Encapsulates a single column in a Jifty::DBI::Record table

=head1 DESCRIPTION


This class encapsulates a single column in a Jifty::DBI::Record table
description. It replaces the _accessible method in
L<Jifty::DBI::Record>.

It has the following accessors: C<name type default validator boolean
refers_to readable writable length>.

=cut

=head2 new

=cut

sub new {
    my ($class, $args) = @_;
    my $self = $class->SUPER::new({});

    # run through accessors, push unknown keys into the attributes hash

    # XXX: we might want to construct the proper hash (lifting things
    # not in @attrs into attributes and just pass the whole hash
    $self->attributes({});
    for (keys %$args) {
        if ($self->can($_)) {
            $self->$_($args->{$_});
        } else {
            $self->attributes->{$_} = $args->{$_};
        }
    }

    return $self;
}

=head2 is_numeric

Returns true if the column is of some numeric type, otherwise returns false.

=cut

sub is_numeric {
    my $self = shift;
    if ( $self->type =~ /INT|NUMERIC|DECIMAL|REAL|DOUBLE|FLOAT/i ) {
        return 1;
    }
    return 0;
}



=head2 is_string

Returns true if this column is a text field

=cut


sub is_string {
    my $self = shift;
    if ( $self->type =~ /CHAR|TEXT/i ){ 
        return 1;
    }
    return 0;
}

=head2 is_boolean

Returns true if this column is a boolean

=cut

sub is_boolean {
    my $self = shift;
    return 1 if grep { $_->isa('Jifty::DBI::Filter::Boolean') } $self->output_filters;
    return 1 if $self->type =~ /BOOL/i;
    return 0;
}

=head2 serialize_metadata

Returns a hash describing this column object with enough detail to
fully describe it in the database.  Intentionally skips
C<record_class>, all column attributes starting with C<_>, and all
column attributes which are undefined.  The "known" attributes in the
C<attributes> hash are flattened and returned as well.  The list of
known attributes are:

=over

=item container

=item label hints render_as

=item display_length

=item valid_values

=item available_values

=item autocompleted

=item documentation

=item no_placeholder

Setting this to a true value causes L<Jifty::DBI::record/load_by_cols>
to not use a placeholder when loading the column.  This can allow the
database to come up with better query plans in some cases.

=back

=cut

sub serialize_metadata {
    my $self = shift;
    return {map { $_ => $self->$_() } grep { $_ ne 'attributes' && $_ ne 'record_class' && $_ !~ /^_/ && defined $self->$_}
            @ATTRS};
}

=head2 serialize_metadata2

Returns a hash describing this column object with enough detail to
fully describe it in the database.  Intentionally skips C<record_class>,
all column attributes starting with C<_>, and all column attributes
which are undefined.

=cut

sub serialize_metadata2 {
    my $self = shift;
    return {map { $_ => $self->$_() } grep { $_ ne 'record_class' && $_ !~ /^_/ && defined $self->$_} @attrs};
}

=head2 validator

Gets/sets the validator coderef for the column.

=cut

sub validator {
    my $self = shift;

    if ( @_ ) {
        $self->_validator( shift );
    }
    elsif ( not $self->_checked_for_validate_sub and not $self->_validator ) {
        my $name = ( $self->aliased_as ? $self->aliased_as : $self->name );
        my $can  = $self->record_class->can( "validate_" . $name );

        $self->_validator( $can ) if $can;
        $self->_checked_for_validate_sub( 1 );
    }

    return $self->_validator;
}

# Aliases for compatibility with searchbuilder code
*read  = \&readable;
*write = \&writable;

=head2 read

DEPRECATED.  Use C<< $column->readable >> instead.

=head2 write

DEPRECATED.  Use C<< $column->writable >> instead.

=head2 length

DEPRECATED.  Use C<< $column->max_length >> instead.

=head2 until

DEPRECATED.  Use C<< $column->till >> instead.

=cut

sub length { Carp::croak('$column->length is no longer supported; use $column->max_length instead') }
sub until { Carp::croak('$column->until is no longer supported; use $column->till instead') }

=head2 active

Returns the a true value if the column method exists for the current application
version. The current application version is determined by checking the L<Jifty::DBI::Record/schema_version> of the column's L</record_class>. This method returns a false value if the column is not yet been added or has been dropped.

This method returns a false value under these circumstances:

=over

=item *

Both the C<since> trait and C<schema_version> method are defined and C<schema_version> is less than the version set on C<since>.

=item *

Both the C<till> trait and C<schema_version> method are defined and C<schema_version> is greater than or equal to the version set on C<till>.

=back

Otherwise, this method returns true.

=cut

sub active {
    my $self    = shift;

    return 1 unless $self->record_class->can('schema_version');
    return 1 unless defined $self->record_class->schema_version;

    my $version = version->new($self->record_class->schema_version);

    # The application hasn't yet started using this column
    return 0 if defined $self->since
            and $version < version->new($self->since);

    # The application stopped using this column
    return 0 if defined $self->till
            and $version >= version->new($self->till);

    # The application currently uses this column
    return 1;
}

1;
