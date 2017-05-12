use strict;
use Test::More;
use Finance::FITF ;
use File::Temp;

my $tf = File::Temp->new;

my $writer = Finance::FITF->new_writer(
    fh => $tf,
    header => {
        name => 'HKFE.HSI',
        date => '20101119',
        time_zone => 'Asia/Hong_Kong',
        bar_seconds => 300,
        format => FITF_TICK_NONE | FITF_BAR_USHORT,
    },
);

$writer->add_session( 585 * 60, 750 * 60 );
$writer->add_session( 870 * 60, 975 * 60 );

is_deeply $writer->header->{start}, [1290131100, 1290148200];
is_deeply $writer->header->{end}, [1290141000, 1290154500];

is $writer->nbars, 54;

for (1..54) {
    my $ts = $writer->{bar_ts}->[$_-1];
 #   diag $ts;
    $writer->push_bar($ts,
                      { open => 20000+$_,
                        high => 20000+$_,
                        low => 20000+$_,
                        close => 20000+$_,
                        volume => $_,
                        ticks => $_,
                    });
}

$writer->end;
close $tf;

my $reader = Finance::FITF->new_from_file( $tf );
is $reader->header->{name}, 'HKFE.HSI';
is $reader->nbars, 54;

is $reader->header->{records}, 0;
is_deeply $writer->header->{start}, [1290131100, 1290148200, 0];
is_deeply $writer->header->{end}, [1290141000, 1290154500, 0];
is $reader->{bar_ts}[0], 1290131400;

for (1..54) {
    my $ts = $writer->{bar_ts}->[$_-1];
    my $b = $reader->bar_at($ts);
    is $b->{open}, 20000+$_;
}

my $i = 1;
$reader->run_bars(0, 53,
                  sub {
                      is $_[0]{open}, 20000 + $i++
                  });

my @res;
$reader->run_bars_as(3600, 0,
                  sub {
                      my ($ts, $b) = @_;
                      push @res, [ $ts, $b ];
                  });
is_deeply [map {$reader->format_timestamp($_->[0])} @res],
    ['2010-11-19 10:45:00',
     '2010-11-19 11:45:00',
     '2010-11-19 12:30:00',
     '2010-11-19 15:30:00',
     '2010-11-19 16:15:00'];

is_deeply [map {$_->[1]{open}} @res],
    [20001, 20013, 20025, 20034, 20046];

is_deeply [map {$_->[1]{close}} @res],
    [20012, 20024, 20033, 20045, 20054];


#warn Dumper(\@res) ; use Data::Dumper;
done_testing;
