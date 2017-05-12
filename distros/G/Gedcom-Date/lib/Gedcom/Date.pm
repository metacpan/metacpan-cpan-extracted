package Gedcom::Date;

use strict;
use DateTime::Locale;

use vars qw($VERSION);

our $VERSION = '0.10';

use Gedcom::Date::Simple;
use Gedcom::Date::Period;
use Gedcom::Date::Range;
use Gedcom::Date::Approximated;
use Gedcom::Date::Interpreted;
use Gedcom::Date::Phrase;

use overload ( fallback => 1,
               '>'      => '_later_than',
               '<'      => '_earlier_than',
             );

{
    my $DefaultLocale;
    sub DefaultLocale {
        my $class = shift;

        if (my $locale = shift) {
            $DefaultLocale = DateTime::Locale->load($locale);
        }
        return $DefaultLocale;
    }
}
__PACKAGE__->DefaultLocale('en_GB');

sub parse {
    my $class = shift;

    my ($str) = @_;

    return
        Gedcom::Date::Period->parse($str)       ||
        Gedcom::Date::Range->parse($str)        ||
        Gedcom::Date::Approximated->parse($str) ||
        Gedcom::Date::Interpreted->parse($str)  ||
        Gedcom::Date::Simple->parse($str)       ||
        Gedcom::Date::Phrase->parse($str);
}

sub from_datetime {
    my ($class, $dt) = @_;

    return Gedcom::Date::Simple->from_datetime($dt);
}

sub clone {
    my ($self) = @_;

    my %clone;
    for (keys %$self) {
        if (ref($self->{$_})) {
            $clone{$_} = $self->{$_}->clone;
        } else {
            $clone{$_} = $self->{$_};
        }
    }

    return bless \%clone, ref $self;
}

sub _later_than {
    my ($self, $other, $switched) = @_;
    _earlier_than($other, $self) if $switched;

    return 1 if $self->earliest > $other->latest;
    return 0 if $self->latest < $other->earliest;
    return;
}

sub _earlier_than {
    my ($self, $other, $switched) = @_;
    _later_than($other, $self) if $switched;

    return 0 if $self->earliest > $other->latest;
    return 1 if $self->latest < $other->earliest;
    return;
}

sub as_text {
    my ($self, $locale) = @_;

    $locale ||= $self->DefaultLocale();
    $locale = DateTime::Locale->load($locale) unless ref $locale;
    my $lang = $locale->language_id;

    my ($str, @dates) = $self->text_format($lang);

    $str =~ s/%(\d+)/
                $dates[$1]->_date_as_text($locale);
             /ge;

    # Remove those ugly leading zeroes
    $str =~ s/\b0+\B//g;

    return $str;
}

sub add {
    my $self = shift;

    for (qw/date from to bef aft/) {
        $self->{$_}->add(@_, secret => 1) if $self->{$_};
    }
    return $self;
}

1;

__END__

=head1 NAME

Gedcom::Date - Perl class for interpreting dates in Gedcom files

=head1 SYNOPSIS

  use Gedcom::Date;

  my $date = Gedcom::Date->parse( 'ABT 10 JUL 2003' );

  my $dt = DateTime->now;
  my $date2 = Gedcom::Date->from_datetime( $dt );

  # output:
  $date->gedcom;        # 'ABT 10 JUL 2003'
  $date->as_text;       # 'about 10 July 2003'
  $date->as_text('nl'); # 'rond 10 juli 2003'   (nl = Dutch language)
  $date->sort_date;     # '2003-07-10'

  $date->add( years => 2, months => 5 );
                        # ABT DEC 2005

  my $date3 = $date->clone;

=head1 DESCRIPTION

The Gedcom standard for genealogical data files defines a number of date
formats. This module can parse most of these formats.

This package contains a number of modules, each implementing a Gedcom
date format. They are:

  Gedcom::Date::Simple
    e.g. "4 JUN 1729", "JUL 2003", "1974"

  Gedcom::Date::Approximated
    e.g. "ABT 15 JUN 1672", "CAL 1922", "EST 1700"

  Gedcom::Date::Interpreted
    e.g. "INT 12 APR 1657 (Easter Monday)"

  Gedcom::Date::Period
    e.g. "FROM 1522 TO 1534", "FROM 30 APR 1980", "TO 1910"

  Gedcom::Date::Range
    e.g. "BET 1600 AND 1620", "AFTER 1948", "BEF 2 AUG 2003"

  Gedcom::Date::Phrase
    e.g. "(Once upon a time)"

=head1 METHODS

=head2 Class methods

=over 4

=item * parse( $date )

Creates a Gedcom::Date object from a string. The string should be a
valid date value according to the Gedcom standard v5.5.

=item * from_datetime( $datetime_object )

Creates a Gedcom::Date object from a DateTime object. The return value
is a Gedcom::Date::Simple object.

=item * DefaultLocale( $locale )

If called with one argument, sets the default locale used in output
routines. If called without arguments, returns the current default
locale.

=back

=head2 Instance methods

=over 4

=item * clone( $object )

Returns a deep copy of the Gedcom::Date object.

=item * add( years => ..., months => ..., days => ..., secret => 1 )

Adds a certain amount of time to the date. All arguments are optional.
If you do not include the smaller time units in your call, the end
result will not contain these smaller units. For example, if $date is
"10 AUG 2003", then:

    $date->add( years => 18, months => 0, days => 0 );

results in "CAL 10 AUG 2021", while

    $date->add( years => 18 );

results in "CAL 2021".

If the object is a simple date, it will become a calculated date (see
Gedcom::Date::Approximated) after this addition, as shown in the
examples above. If you do not want to advertise that the date is the
result of a calculation, set the C<secret> parameter to 1.

=item * earliest

Returns the earliest possible date; e.g. for the date "BET 10 JUL 2003
AND 20 JUL 2003" it returns July 10, 2003. The value returned is a
DateTime object.

=item * latest

Returns the latest possible date; e.g. for the date "BET 10 JUL 2003
AND 20 JUL 2003" it returns July 20, 2003. The value returned is a
DateTime object.

=item * sort_date

Returns a sortable string, suitable for example for indices. To sort the
individuals in a Gedcom file on birth date:

    my @sorted = map  { $_->[1] }
                 sort { $a->[0] cmp $b->[0] }
                 map  { [ Gedcom::Date->parse($_->birth->date)->sort_date,
                         $_ ] }
                 $gedcom_file->individuals;

=item * gedcom

Returns the date in Gedcom format.

=item * as_text( $locale )

Returns the date in a format that can be included in a narrative text.
You can set the language of the text by passing an optional locale
argument. This should be a DateTime::Locale object, or a valid locale
identifier. The default locale is 'en_GB' by default, but can be set
with the DefaultLocale method.

=back

=head1 AUTHOR

Eugene van der Pijll <pijll@gmx.net>

=head1 REPOSITORY

L<https://github.com/ronsavage/Gedcom-Date>.

=head1 TODO

Implement other calendars (Julian, Hebrew, French).

More languages in as_text().

=head1 See Also

L<Genealogy::Date>.

L<Genealogy::Gedcom::Date>.

=head1 COPYRIGHT

Copyright (c) 2003 Eugene van der Pijll.  All rights reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

perl(1).

=cut
