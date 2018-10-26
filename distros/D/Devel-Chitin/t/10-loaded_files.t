use strict;
use warnings;

use Test2::V0; no warnings 'void';
use lib 't/lib';
use TestHelper qw(db_disable db_continue);
use SampleCode;

plan tests => 6;

ok( TestHelper->is_loaded(__FILE__), 'main file is loaded');
ok( TestHelper->is_loaded($INC{'Devel/Chitin.pm'}), 'Devel::Chitin is loaded');
ok( TestHelper->is_loaded($INC{'SampleCode.pm'}), 'SampleCode is loaded');
ok( ! TestHelper->is_loaded('Non/Loaded/Module.pm'), 'Non::Loaded::Module not is_loaded');

my @files = TestHelper->loaded_files();
ok(scalar(@files), 'loaded_files()');
is(\@files,
    bag {
        item __FILE__;
        item $INC{'Devel/Chitin.pm'};
        item $INC{'SampleCode.pm'};
        etc();
    },
    'Found main file, Devel::Chitin and SampleCode in loaded files list');

$DB::single=1;
28;

sub __tests__ {
    # This will run after the $DB::single=1 above.
    # It's needed otherwise TestHelper will complain about the debugger being
    # stopped within the Test2 frmework with no tests to run.
    db_continue;
}
