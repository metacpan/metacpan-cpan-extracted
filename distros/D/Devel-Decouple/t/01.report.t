use Test::More;
use Test::Differences;
use Test::Deep;

use Devel::Decouple;
use lib 't';
use TestMod::Baz;

my $module = 'TestMod::Baz';

BASIC_REPORT: {
    my $DD = Devel::Decouple->new->decouple( $module );
    
    local $/ = '';
    my $report = "\n".<DATA>."\n";
    
    #         GOT                     EXPECTED                   MESSAGE
    is(       $DD->report,            $report,                  "returned a correctly formatted report" );
}

done_testing;



__DATA__
Function-import usage statistics for TestMod::Baz:
    TestMod::Foo
        inhibit             calls: 1	lines: 7.
    TestMod::Bar
        prohibit            calls: 1	lines: 10.