package Gedcom::Date::Simple;

use strict;

use vars qw($VERSION @ISA);

our $VERSION = '0.10';
@ISA = qw/Gedcom::Date/;

use Gedcom::Date;
use DateTime 0.15;

my %months = (
    JULIAN     => [qw/JAN FEB MAR APR MAY JUN JUL AUG SEP OCT NOV DEC/],
    GREGORIAN  => [qw/JAN FEB MAR APR MAY JUN JUL AUG SEP OCT NOV DEC/],
    'FRENCH R' => [qw/VEND BRUM FRIM NIVO PLUV VENT
                      GERM FLOR PRAI MESS THER FRUC COMP/],
    HEBREW     => [qw/TSH CSH KSL TVT SHV ADR ADS NSN IYR SVN TMZ AAV ELL/],
);

sub parse_datetime {
    my ($class, $str) = @_;

    my ($cal, $date) =
        $str =~ /^(?:\@#(.+)\@\s+)?(.+)$/
        or return;  # Not a simple date

    $cal ||= 'GREGORIAN';
    return unless exists $months{$cal};

    my ($d, $month, $y) =
        $date =~ /^(?:(?:(\d+)\s+)?(\w+)\s+)?(\d+)$/
        or return;

    my %known = ( d => defined $d, m => defined $month, y => 1 );
    $d ||= 1;   # Handling of incomplete dates is not correct yet
    $month ||= $months{$cal}[6];

    my $m;
    for (0..$#{$months{$cal}}) {
        $m = $_+1 if $month eq $months{$cal}[$_];
    }
    defined($m) or return;

    my $dt = eval {DateTime->new( year => $y, month => $m, day => $d||15 )}
        or return;

    return $dt, \%known;
}

sub parse {
    my $class = shift;
    my ($str) = @_;

    my ($dt, $known) = Gedcom::Date::Simple->parse_datetime($str)
        or return;

    my $self = bless {
        datetime => $dt,
        known => $known,
    }, $class;

    return $self;
}

sub clone {
    my $self = shift;

    my $clone = bless {
        datetime => $self->{datetime}->clone,
        known => { %{$self->{known}} },
    }, ref $self;

    return $clone;
}

sub gedcom {
    my $self = shift;

    if (!defined $self->{gedcom}) {
        $self->{datetime}->set_locale('en');
        my $str;
        if ($self->{known}{d}) {
            $str = uc $self->{datetime}->strftime('%d %b %Y');
        } elsif ($self->{known}{m}) {
            $str = uc $self->{datetime}->strftime('%b %Y');
        } else {
            $str = $self->{datetime}->strftime('%Y');
        }
        $str =~ s/\b0+(\d)/$1/g;
        $self->{gedcom} = $str;
    }
    $self->{gedcom};
}

sub from_datetime {
    my ($class, $dt) = @_;

    return bless {
               datetime => $dt,
               known => {d => 1, m => 1, y => 1},
           }, $class;
}

sub to_approximated {
    my ($self, $type) = @_;

    $type ||= 'abt';
    Gedcom::Date::Approximated->new( date => $self,
                                     type => $type,
                                   );
}

sub latest {
    my ($self) = @_;

    my $dt = $self->{datetime};
    if (!$self->{known}{m}) {
        $dt->truncate(to => 'year')
           ->add(years => 1)
           ->subtract(days => 1);
    } elsif (!$self->{known}{d}) {
        $dt->truncate(to => 'month')
           ->add(months => 1)
           ->subtract(days => 1);
    }

    return $dt;
}

sub earliest {
    my ($self) = @_;

    my $dt = $self->{datetime};
    if (!$self->{known}{m}) {
        $dt->truncate(to => 'year');
    } elsif (!$self->{known}{d}) {
        $dt->truncate(to => 'month');
    }

    return $dt;
}

sub sort_date {
    my ($self) = @_;

    my $dt = $self->{datetime};
    if (!$self->{known}{m}) {
        return $dt->strftime('%Y-??-??');
    } elsif (!$self->{known}{d}) {
        return $dt->strftime('%Y-%m-??');
    }

    return $dt->strftime('%Y-%m-%d');
}

my %text = (
    en => ['on %0', 'in %0', 'in %0'],
    nl => ['op %0', 'in %0', 'in %0'],
);

sub text_format {
    my ($self, $lang) = @_;

    if ($self->{known}{d}) {
        return ($text{$lang}[0], $self);
    } elsif ($self->{known}{m}) {
        return ($text{$lang}[1], $self);
    } else {
        return ($text{$lang}[2], $self);
    }
}

sub _date_as_text {
    my ($self, $locale) = @_;

    my $dt = $self->{datetime};
    $dt->set_locale($locale);

    if ($self->{known}{d}) {
        my $format = $dt->locale->date_format_long;
        $format =~ s/%y\b/%Y/g; # never, EVER, use 2-digit years
        return $dt->format_cldr($format);
    } elsif ($self->{known}{m}) {
        return $dt->strftime('%B %Y');
    } else {
        return $dt->year;
    }
}

sub add {
    my ($self, %p) = @_;
    my $secret = delete $p{secret};

    $self->{datetime}->add(%p);

    $p{months} = 0 if exists $p{days};
    $p{years}  = 0 if exists $p{months};

    $self->{known}{d} &&= exists $p{days};
    $self->{known}{m} &&= exists $p{months};
    $self->{known}{y} &&= exists $p{years};

    unless ($secret) {
        my $d = $self->to_approximated('calculated');
        %{ $self } = %{ $d };
        bless $self, ref $d;
    }

    return $self;
}

1;

__END__

=head1 NAME

Gedcom::Date::Simple - Perl class for interpreting simple Gedcom dates

=head1 SYNOPSIS

  use Gedcom::Date::Simple;

  my $date = Gedcom::Date->parse( '10 JUL 2003' );

=head1 DESCRIPTION

Parse dates from Gedcom files.

=head1 AUTHOR

Eugene van der Pijll <pijll@gmx.net>

=head1 REPOSITORY

L<https://github.com/ronsavage/Gedcom-Date>.

=head1 See Also

L<Genealogy::Date>.

L<Genealogy::Gedcom::Date>.

=head1 COPYRIGHT

Copyright (c) 2003 Eugene van der Pijll.  All rights reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
