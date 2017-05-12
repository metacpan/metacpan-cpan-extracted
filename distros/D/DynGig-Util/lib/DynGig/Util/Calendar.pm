=head1 NAME

DynGig::Util::Calendar - Print calendar

=cut

package DynGig::Util::Calendar;

use strict;
use warnings;

use constant WEEK => 'Su Mo Tu We Th Fr Sa';
use constant MONTH => qw( _ January February March April May
    June July August September October November December );

our ( $header, @header );

format MONTH_HEADER =
@|||||||||||||||||||||
$header
@|||||||||||||||||||||
WEEK
.

format QUARTER_HEADER =
@|||||||||||||||||||||@|||||||||||||||||||||@|||||||||||||||||||||
@header 
@|||||||||||||||||||||@|||||||||||||||||||||@|||||||||||||||||||||
WEEK, WEEK, WEEK
.

format YEAR_HEADER =
@|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
$header

.

=head1 SYNOPSIS

 use DynGig::Util::Calendar;
 
 DynGig::Util::Calendar->print
 ( 
     year => 2012,
     month => 3,
     handle => \*STDOUT,
     select => \%select, 
 );

=cut
sub print
{
    my ( $class, %param ) = @_;
    my $select = $param{select};
    my $handle = $param{handle} || \*STDOUT;
    my $year = $param{year};
    my $month = $param{month};

    return if $select && ! ( $select = $select->{$year} );
    return _print_month( $handle, $select, $year, $month ) if $month;

    $header = $year;
    $~ = 'YEAR_HEADER';
    write $handle;

    for my $i ( 0 .. 3 )
    {
        _print_quarter( $handle, $select, $year, map { $i * 3 + $_ } 1 .. 3 );
    }
}

sub _print_quarter
{
    my ( $handle, $select, $year, @month ) = @_;
    my %month = map { $_ => _Month->new( year => $year, month => $_ ) } @month;

    @header = ( MONTH )[ @month ];
    $~ = 'QUARTER_HEADER';
    write $handle;

    for my $i ( 0 .. 5 )
    {
        for my $month ( sort keys %month )
        {
            unless ( my $week = $month{$month}->week( $i ) )
            {
                printf $handle ' ' x 22;
            }
            elsif ( ! $select )
            {
                map { printf $handle '%3s', $_ } @$week; 
                print $handle ' ';
            }
            elsif ( my $select = $select->{$month} )
            {
                map { printf $handle '%3s', $select->{$_} ? $_ : '' } @$week; 
                print $handle ' ';
            }
            else
            {
                printf $handle ' ' x 22;
            }
        }

        print $handle "\n";
    }
}

sub _print_month
{
    my ( $handle, $select, $year, $month ) = @_;

    return if $select && ! ( $select = $select->{$month} );

    $header = sprintf '%s %s', ( MONTH )[ $month ], $year;
    $~ = 'MONTH_HEADER';
    write $handle;

    $month = _Month->new( year => $year, month => $month );

    for my $i ( 0 .. 5 )
    {
        if ( my $week = $month->week( $i ) )
        {
            if ( $select )
            {
                map { printf $handle '%3s', $select->{$_} ? $_ : '' } @$week;
            }
            else
            {
                map { printf $handle '%3s', $_ } @$week;
            }
        }

        print $handle "\n";
    }
}

package _Month;

use strict;
use warnings;

use Carp;
use DateTime;

my @_total = ( 0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 );

sub new
{
    my ( $class, %this ) = @_;
    my $month = $this{month};
    my $year = $this{year};

    $this{first} = DateTime->new( %this, day => 1 )->dow() % 7;
    $this{total} = $month != 2 ? $_total[$month]
        : $year % 100 && ! ( $year % 4 && $year % 400 ) ? 29 : 28;

    bless \%this, ref $class || $class;
}

sub dow
{
    my ( $this, $dow ) = @_;

    return if ! defined $dow || ref $dow || $dow !~ /^[0-7]$/;

    $dow %= 7;

    my $first = $this->{first};
    my $day = $dow - $first + ( $dow >= $first ? 1 : 8 );
    my @day;

    while ( $day <= $this->{total} )
    {
        push @day, $day;
        $day += 7;
    }

    return wantarray ? @day : \@day;
}

sub week
{
    my ( $this, $index ) = @_;

    return if ! defined $index || ref $index || $index !~ /^[0-5]$/;

    my @sun = $this->dow( 0 );
    my @day;

    unshift @sun, '' if $sun[0] != 1;

    if ( $index )
    {
        return unless my $day = $sun[$index];
        map { push @day, $day <= $this->{total} ? $day ++ : '' } 0 .. 6;
    }
    else
    {
        my $first = $this->{first};
        map { $day[$_] = '' } 0 .. $first - 1;
        map { $day[$_] = $_ - $first + 1 } $first .. 6;
    }

    return wantarray ? @day : \@day;
}

=head1 NOTE

See DynGig::Util

=cut

1;

__END__
