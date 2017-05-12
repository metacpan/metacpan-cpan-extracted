package REPLTest;

use strict;
use warnings;
use autodie;
use parent 'Exporter';

use Devel::REPL;
use Test::More;
use Test::SharedFork;

our @EXPORT = qw(test_repl);

sub test_repl (&) {
    my ( $action ) = @_;

    my $pid = fork();

    if($pid) {
        waitpid $pid, 0;

        return $? ? 0 : 1;
    } else {
        my $repl = Devel::REPL->new(term => {});
        my $ok   = $action->($repl);
        exit($ok ? 0 : 1);
    }
}

1;
