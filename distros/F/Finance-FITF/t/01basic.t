use strict;
use Test::More;
use Finance::FITF ;
use File::Temp;

my $tf = File::Temp->new;

my $writer = Finance::FITF->new_writer(
    fh => $tf,
    header => {
        name => 'XTAF.TX',
        date => '20101119',
        time_zone => 'Asia/Taipei',
        bar_seconds => 10,
        format => FITF_TICK_USHORT | FITF_BAR_USHORT,
    },
);

$writer->add_session( 525 * 60, 825 * 60 );

is_deeply $writer->header->{start}, [1290127500];
is_deeply $writer->header->{end}, [1290145500];

$writer->push_price( 1290127500, 8200, 5);
$writer->push_price( 1290127501, 8205, 5);
$writer->push_price( 1290127502, 8203, 4);
$writer->push_price( 1290127510, 8204, 1);
$writer->push_price( 1290127511, 8203, 4);
$writer->push_price( 1290127529, 8205, 2);
$writer->push_price( 1290127530, 8206, 9);
$writer->push_price( 1290145499, 8199, 4);

$writer->end;

seek $tf, 0, 0;
close $tf;

my $reader = Finance::FITF->new_from_file( $tf );
is $reader->header->{name}, 'XTAF.TX';
is $reader->nbars, 1800;

is $reader->header->{records}, 8;
is $reader->header->{start}[0], 1290127500;
is $reader->{bar_ts}[0], 1290127510;

my $bar = $reader->bar_at(1290127510);
is_deeply $bar, { 'high' => 8205,
                  'low' => 8200,
                  'open' => 8200,
                  'index' => 0,
                  'close' => 8203,
                  'ticks' => 3,
                  'volume' => 14,
              };

$bar = $reader->bar_at(1290127520);
is_deeply $bar, { 'high' => 8204,
                  'low' => 8203,
                  'open' => 8204,
                  'index' => 3,
                  'close' => 8203,
                  'ticks' => 2,
                  'volume' => 5,
              };

my @res;
$reader->run_ticks($bar->{index}, $bar->{index}+$bar->{ticks},
                   sub {
                       my ($time, $price, $vol) = @_;
                       push @res, [$time, $price, $vol];
                   });

is_deeply \@res, [[1290127510, 8204, 1],
                  [1290127511, 8203, 4],
                  [1290127529, 8205, 2]];

$bar = $reader->bar_at(1290127550);
is_deeply $bar, { 'high' => 8206,
                  'low' => 8206,
                  'open' => 8206,
                  'index' => 7,
                  'close' => 8206,
                  'ticks' => 0,
                  'volume' => 0,
              };

done_testing;

