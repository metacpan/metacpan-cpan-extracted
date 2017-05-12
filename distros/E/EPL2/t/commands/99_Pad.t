use 5.010;
use Moose;
use Test::More;
use EPL2::Command::A;
use EPL2::Command::B;

use_ok 'EPL2::Pad';

my ( $pad );

ok $pad = EPL2::Pad->new, 'New Pad';

is $pad->continuous, 1, 'Pad is continuous';
is $pad->number_sets, 1, 'Pad default number of sets';
is $pad->number_copies, 0, 'Pad default number of copies';
is $pad->clear_image_buffer, 1, 'Pad to clear image buffer';
is $pad->height, 0, 'Pad default height';
is $pad->width, 0, 'Pad default width (auto)';

ok my @commands = $pad->process, 'Process Pad';
is scalar(@commands), 4, 'Pad contains 4 command objects';
is blessed($commands[0]), 'EPL2::Command::N', 'index 0 command is N';
is blessed($commands[1]), 'EPL2::Command::O', 'index 1 command is O';
is blessed($commands[2]), 'EPL2::Command::Q', 'index 2 command is Q';
is blessed($commands[3]), 'EPL2::Command::P', 'index 3 command is P';
is $pad->string, "\nN\nO\nQ0,0\nP1\n", 'Pad string';

done_testing;
