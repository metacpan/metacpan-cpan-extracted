use warnings;
use strict;
use Test::More;

use Log::Fast;


plan tests => 9;


my $LOG = Log::Fast->new();
my $BUF = q{};
open my $fh, '>', \$BUF;
$LOG->config({ fh=>$fh });
sub _log() { seek $fh, 0, 0; substr $BUF, 0, length $BUF, q{} }

sub logall {
    $LOG->ERR('E');
    $LOG->WARN('W');
    $LOG->NOTICE('N');
    $LOG->INFO('I');
    $LOG->DEBUG('D');
}

logall();
is _log(), "E\nW\nN\nI\nD\n", '(default) DEBUG';

$LOG->level('INFO');
is $LOG->level(), 'INFO';
logall();
is _log(), "E\nW\nN\nI\n", 'INFO';

$LOG->config({ level=>'NOTICE' });
is $LOG->level(), 'NOTICE';
logall();
is _log(), "E\nW\nN\n", 'NOTICE';

$LOG->level('WARN');
logall();
is _log(), "E\nW\n", 'WARN';

$LOG->level('ERR');
logall();
is _log(), "E\n", 'ERR';

$LOG->level('DEBUG');
logall();
is _log(), "E\nW\nN\nI\nD\n", 'DEBUG';

is $LOG->level('INFO'), 'DEBUG',    'previous level on change';
