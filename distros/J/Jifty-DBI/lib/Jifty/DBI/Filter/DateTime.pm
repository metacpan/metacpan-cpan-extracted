package Jifty::DBI::Filter::DateTime;

use warnings;
use strict;

use base qw|Jifty::DBI::Filter Class::Data::Inheritable|;
use DateTime                  ();
use DateTime::Format::ISO8601 ();
use DateTime::Format::Strptime ();
use Carp ();

use constant _time_zone => 'UTC';
use constant _strptime  => '%Y-%m-%d %H:%M:%S';
use constant _parser    => DateTime::Format::ISO8601->new();
use constant date_only  => 0;

=head1 NAME

Jifty::DBI::Filter::DateTime - DateTime object wrapper around date columns

=head1 DESCRIPTION

This filter allow you to work with DateTime objects instead of
plain text dates.  If the column type is "date", then the hour,
minute, and second information is discarded when encoding.

Both input and output will always be coerced into UTC (or, in the case of
Dates, the Floating timezone) for consistency.

=head2 formatter

This is an instance of the DateTime::Format object used for inflating the
string in the database to a DateTime object. By default it is a
L<DateTime::Format::Strptime> object that uses the C<_strptime> method as its
pattern.

You can use the _formatter classdata storage as a cache so you don't need
to re-instantiate your format object every C<decode>.

=cut

__PACKAGE__->mk_classdata("_formatter");
sub formatter {
    my $self = shift;
    if ( not $self->_formatter
          or $self->_formatter->pattern ne $self->_strptime )
    {
         $self->_formatter(DateTime::Format::Strptime->new(pattern => $self->_strptime));
    }
    return $self->_formatter;
}

=head2 encode

If value is DateTime object then converts it into ISO format
C<YYYY-MM-DD hh:mm:ss>. Does nothing if value is not defined.

Sets the value to undef if the value is a string and doesn't match an ISO date (at least).


=cut

sub encode {
    my $self = shift;

    my $value_ref = $self->value_ref;

    return if !defined $$value_ref;

    if  ( ! UNIVERSAL::isa( $$value_ref, 'DateTime' )) {
        if ($$value_ref !~ /^\d{4}[ -]?\d{2}[ -]?\d{2}/) {
            $$value_ref = undef;
        }
        return undef;
    }

    return unless $$value_ref;
    if (my $tz = $self->_time_zone) {
        $$value_ref = $$value_ref->clone;
        $$value_ref->set_time_zone($tz);
    }
    $$value_ref = $$value_ref->DateTime::strftime($self->_strptime);
    return 1;
}

=head2 decode

If value is defined then converts it into DateTime object otherwise do
nothing.

=cut

sub decode {
    my $self = shift;

    my $value_ref = $self->value_ref;
    return unless defined $$value_ref;

# XXX: Looks like we should use special modules for parsing DT because
# different MySQL versions can return DT in different formats(none strict ISO)
# Pg has also special format that depends on "european" and
#    server time_zone, by default ISO
# other DBs may have own formats(Interbase for example can be forced to use special format)
# but we need Jifty::DBI::Handle here to get DB type

    my $str = join('T', split ' ', $$value_ref, 2);

    # The ISO8601 parser accepts 2012-11-04T12:34:56+00
    #                        and 2012-11-04T12:34:56.789+00:00
    #                    but not 2012-11-04T12:34:56.789+00
    # Postgres returns sub-second times as the last one; append ":00" to
    # change it into the acceptable second option.
    $str .= ":00" if $str =~ /\d\.\d+[+-]\d\d$/;

    my $dt;
    eval { $dt  = $self->_parser->parse_datetime($str) };

    if ($@) { # if datetime can't decode this, scream loudly with a useful error message
        Carp::cluck("Unable to decode $str: $@");
        return;
    }

    return if !$dt;

    my $tz = $self->_time_zone;
    $dt->set_time_zone($tz) if $tz;

    if ($self->date_only) {
        $dt->set_hour(0);
        $dt->set_minute(0);
        $dt->set_second(0);
    }

    $dt->set_formatter($self->formatter);
    $$value_ref = $dt;
}

=head1 SEE ALSO

L<Jifty::DBI::Filter>, L<DateTime>

=cut

1;
