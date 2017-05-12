#!/usr/bin/perl

package Locale::Handle::Pluggable::DateTime;
#use Moose::Role;
use Moose;

use Moose::Util::TypeConstraints;
use MooseX::Types::VariantTable::Declare;

use MooseX::Types::DateTime qw(DateTime TimeZone);

variant_method loc => DateTime() => "loc_datetime";

has time_zone => (
    isa => TimeZone,
    is  => "rw",
    coerce => 1,
    predicate => "has_time_zone",
);

sub loc_datetime {
    my ( $self, $date_proto, @args ) = @_;

    # the first argument is treated as a format or format name
    my $format = @args % 2 ? shift @args : undef;

    # make a copy of the date so we can set the time zone
    my $date = $self->loc_datetime_clone($date_proto, @args);
    
    $self->loc_datetime_set_time_zone($date, @args);

    if ( $format ) {
        $self->loc_datetime_format($date, $format, @args);
    } else {
        return $date;
    }
}

sub loc_datetime_format {
    my ( $self, $date, $format, @args ) = @_;

    # first check if this is a symbolic format name
    foreach my $method ( $format, "${format}_format" ) {
        if ( $date->locale->can($method) ) {
            return $date->strftime( $date->locale->$method );
        }
    }

    # if not treat it as an actual format
    return $date->strftime( $format );
}

sub loc_datetime_clone {
    my ( $self, $date_proto, @args ) = @_;

    # clone the object with the locale set
    ( ref $date_proto )->from_object(
        object    => $date_proto,
        locale    => $self->language_tag, # we can postfix this with our own subclasses, http://search.cpan.org/~drolsky/DateTime-Locale-0.34/lib/DateTime/Locale.pm#Subclass_an_existing_locale.
        @args
    );
}

sub loc_datetime_set_time_zone {
    my ( $self, $date, @args ) = @_;

    if ( $self->has_time_zone ) {
        $date->set_time_zone( $self->time_zone );
    }
}

__PACKAGE__

__END__

=pod

=head1 NAME

Locale::Handle::Pluggable::DateTime - Localize DateTime objects with your
maketext handles.

=head1 SYNOPSIS

    package My::I18N;
    use Moose;

    extends qw(
        Locale::Maketext
        Locale::Handle::Pluggable::DateTime
        Locale::Handle::Pluggable
    );

    # and then you can use your maketext handle to localize dates too
    $handle->loc( DateTime->now ); # localizied to $handle's language

=head1 DESCRIPTION

This package extends the L<Locale::Maketext::Pluggable> with a variant method
for L<DateTime> objects.

=head1 ATTRIBUTES

=over 4

=item time_zone

If set all L<DateTime> objects being localized will also have their time zone
set to this value.

This is a L<MooseX::Types::DateTime/DateTime::TimeZone> with coercions enabled.

=back

=head1 METHODS

=over 4

=item loc

Adds a variant method that goes to C<loc_date> with L<DateTime> from
L<MooseX::Types::DateTime> as the variant.

=item loc_date

Localize a L<DateTime> object using L<DateTime::Locale> and the handle's
language.

=back

=cut


