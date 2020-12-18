#!perl

use Test::Most;

use JavaScript::Const::Exporter;

eval "use HTTP::Status";
plan skip_all => "HTTP::Status required for this test" if $@;

my $exporter = JavaScript::Const::Exporter->new(
    module    => 'HTTP::Status',
    constants => [':constants'],
);

ok my $js = $exporter->process, 'process';

my @lines = split /\n/, $js;

cmp_deeply \@lines, array_each( re('const HTTP(_[A-Z]+)+ = [12345][0-9][0-9];') ),
    'expected output';

done_testing;
