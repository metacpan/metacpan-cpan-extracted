#!perl

use Test::Most;

use JavaScript::Const::Exporter;

use lib 't/lib';

my $exporter = JavaScript::Const::Exporter->new(
    module  => 'Consts2',
    use_var => 1,
);

ok my $js = $exporter->process, 'process';

my $expected = <<EOF;
var A = 100;
var B = 200;
EOF

is $js, $expected, 'expected output';

done_testing;
