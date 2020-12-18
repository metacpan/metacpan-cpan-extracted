#!perl

use Test::Most;

use JavaScript::Const::Exporter;

eval "use Const::Fast::Exporter";
plan skip_all => "Const::Fast::Exporter required for this test" if $@;

use lib 't/lib';

my $exporter = JavaScript::Const::Exporter->new(
    module  => 'Consts3',
    constants => [qw/ $A $B @C /],
);

ok my $js = $exporter->process, 'process';

my $expected = <<EOF;
const A = 100;
const B = 200;
const C = [1,2,3,4,5];
EOF

is $js, $expected, 'expected output';


done_testing;
