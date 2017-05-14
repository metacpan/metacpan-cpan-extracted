=head1 NAME

DynGig::CLI::Schedule::Period - Scheduling tool

=cut
package DynGig::CLI::Schedule::Period;

use strict;
use warnings;

use Carp;
use YAML::XS;
use File::Spec;
use Pod::Usage;
use Getopt::Long;

use DynGig::Util::CLI;
use DynGig::Util::Time;
use DynGig::Util::Calendar;
use DynGig::Schedule::Period;

use constant DAY => 86400;

$| ++;

=head1 SYNOPSIS

$exe B<--help>

$exe [B<--timezone> zone] [B<--grep> pattern] [B<--config> file]
[B<--now> time] B<--calendar> year/month

$exe [B<--timezone> zone] [B<--grep> pattern] [B<--config> file]
[B<--now> time] B<--days> days

$exe [B<--timezone> zone] [B<--config> file] [B<--now> time]

=cut
sub main
{
    my ( $class, %option ) = @_;

    map { croak "$_ not defined" if ! defined $option{$_} }
        qw( days timezone now config );

    my $menu = DynGig::Util::CLI->new
    (
        'h|help','help menu',
        'g|grep=s','pattern',
        'c|calendar=s',"calendar mode",
        'days=i',"[ $option{days} ] number of days to display",
        'timezone=s',"[ $option{timezone} ] timezone",
        'now=s',"[ now ] start time",
        'config=s',"[ $option{config} ]",
    );
    
    Pod::Usage::pod2usage( -input => __FILE__, -output => \*STDERR )
        unless Getopt::Long::GetOptions( \%option, $menu->option() );

    my $this = bless \%option;

    if ( $option{h} )
    {
        warn join "\n", "Default value in [ ]", $menu->string(), "\n";
    }
    elsif ( $option{c} )
    {
        $this->_calendar();
    }
    else
    {
        $this->_list();
    }

    return 0;
}

sub _calendar
{
    my $this = shift @_;

    return unless $this->{c} =~ /^(\d+)(?:\/+(0?[1-9]|1[0-2]))?$/;

    my $pattern = $this->{g};
    my $timezone = $this->{timezone};
    my %time = ( day => 1, hour => 0, minute => 0, second => 0 );
    my $time = DateTime->from_epoch( time_zone => $timezone, epoch => time );

    if ( $2 )
    {
        $time{year} = $1;
        $time{month} = $2;
    }
    elsif ( $1 > 12 )
    {
        $time{year} = $1;
    }
    else
    {
        $time{year} = $time->year();
        $time{month} = $1;
    }

    $time->set
    (
        %time,
        month => $time{month} || 1,
    );

    my %period = $time{month} ? ( months => 1 ) : ( years => 1 ); 

    return DynGig::Util::Calendar->print( %time ) unless defined $pattern;

    my %select;
    my $period = DynGig::Schedule::Period->new
    (
        period => [ $time->epoch(), $time->add( %period )->epoch() ],
        config => $this->{config},
    );

    for my $entry ( $period->schedule( $pattern ) )
    {
        my $time = DateTime->from_epoch
        (
            epoch => shift @$entry,
            time_zone => $timezone,
        );

        $select{ $time->year() }{ $time->month() }{ $time->day() } = 1;
    }
    
    DynGig::Util::Calendar->print( %time, select => \%select );
}

sub _list
{
    my $this = shift @_;

    my @date = '';
    my $days = $this->{days};
    my $timezone = $this->{timezone};
    my $now = DynGig::Util::Time->epoch( $this->{now}, $timezone );

    my $period = DynGig::Schedule::Period->new
    (
        period => [ $now - DAY, $now + DAY * ( $days || 1 ) ],
        config => $this->{config},
    );

    for my $entry ( $days
        ? $period->schedule( $this->{g} ) : [ $now, $period->search( $now ) ] )
    {
        my $time = DateTime->from_epoch
        ( 
            epoch => shift @$entry,
            time_zone => $timezone,
        );

        $date[1] = $time->ymd() ;
        
        if ( $date[0] ne $date[1] )
        {
            printf "%s %s\n", $date[1], $time->day_abbr();
            $date[0] = $date[1];
        }

        my $hour = $time->strftime( '%H:%M' );
        my @level = map { $_->[0]->string() } @$entry;

        if ( my $last = pop @level )
        {
            printf "%10s    ", $hour;
            map { printf ' %-18s', $_ } @level;
            printf "%s\n", $last;
        }
    }
}

=head1 NOTE

See DynGig::CLI

=cut

1;

__END__
