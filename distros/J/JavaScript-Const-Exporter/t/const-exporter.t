#!perl

use version 0.77;

use Test::Most 0.35;
use Test::Deep::Set;
use Test::Deep::Regexp;
use Test::Warnings qw/ warnings /;

use JavaScript::Const::Exporter;

eval "use Const::Exporter";
plan skip_all => "Const::Exporter required for this test" if $@;

subtest 'Const::Exporter (specific constants)' => sub {

    local @INC;

    my $exporter = JavaScript::Const::Exporter->new(
        module    => 'Consts1',
        include   => [qw( t/lib )],
        constants => [qw/ $zoo foo /],
    );

    my @warnings = warnings {

        ok my $js = $exporter->process, 'process';

        my $expected = <<EOF;
const foo = 1;
const zoo = 3;
EOF

        is $js, $expected, 'expected output';

    };

    cmp_deeply \@INC, supersetof( @{ $exporter->include } ), "\@INC changed";

  SKIP: {
        if ( version->parse($Const::Exporter::VERSION) >= version->declare('v1.1.0') ) {
            is_deeply \@warnings, [], 'no warnings';
        }
        else {
            cmp_deeply \@warnings,
              [ re(/^Symbol 'foo' is not a constant in Consts1/) ],
              'expected warning';
        }
    }
};

subtest 'Const::Exporter tag' => sub {

    local @INC;

    my $exporter = JavaScript::Const::Exporter->new(
        module    => 'Consts1',
        include   => [qw( t/lib )],
        constants => [':tag_a'],
    );

    my @warnings = warnings {

        ok my $js = $exporter->process, 'process';

        my $expected = <<EOF;
const bar = 2;
const baz = ["a","b","c"];
const bo = {"a":1};
const foo = 1;
EOF

        is $js, $expected, 'expected output';

    };

};

subtest 'Const::Exporter (all exports)' => sub {

    local @INC;

    my $exporter = JavaScript::Const::Exporter->new(
        module  => 'Consts1',
        include => [qw( t/lib )],
    );

    my @warnings = warnings {

        ok my $js = $exporter->process, 'process';

        my $expected = <<EOF;
const bar = 2;
const baz = ["a","b","c"];
const bo = {"a":1};
const foo = 1;
const zoo = 3;
EOF

        is $js, $expected, 'expected output';

    };

};

done_testing;
