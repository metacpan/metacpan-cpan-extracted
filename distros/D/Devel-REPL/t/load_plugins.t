
use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';

use_ok('Devel::REPL');

my @plugins = qw/
B::Concise
Colors
Commands
Completion
CompletionDriver::Globals
CompletionDriver::INC
CompletionDriver::Keywords
CompletionDriver::LexEnv
CompletionDriver::Methods
CompletionDriver::Turtles
DDC
DDS
DumpHistory
FancyPrompt
FindVariable
History
Interrupt
LexEnv
MultiLine::PPI
Nopaste
OutputCache
PPI
Packages
Peek
ReadLineHistory
Refresh
ShowClass
Timing
Turtles
/;

# one $repl is shared:
# "Looks like the problem is that you can't open multiple instances of
# Term::ReadLine:Perl from the same object.  I was able to correct this by
# changing the test to reuse the same Devel::REPL instance each time.  This
# prevents the warning that causes the test to fail.  I don't think this
# changes the spirit of the test, it's just a byproduct of how
# Term::ReadLine::Perl works." -- RT#84246
my $repl = Devel::REPL->new;
for my $plugin_name (@plugins) {
    test_load_plugin($plugin_name);
}

sub test_load_plugin {
    my ($plugin_name) = @_;
    my $test_name = "plugin $plugin_name loaded";

    SKIP: {
        eval "use Devel::REPL::Plugin::$plugin_name; 1"
            or skip "could not eval plugin $plugin_name", 1;

        ok(eval { $repl->load_plugin($plugin_name); 1 }, $test_name)
            or diag $@;
    }
}

done_testing;
