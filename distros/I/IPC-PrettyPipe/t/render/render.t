#!perl

use strict;
use warnings;

use IPC::PrettyPipe::DSL ':all';

use Test::Base;

filters { input => 'ppx' };

sub dump {

    say STDERR $_[0];

    return @_;

}

sub ppx {

    my $pipe = eval( $_[0] )
      or die( "error evaluation $_[0]: $@\n");
    $pipe->render( colorize => 0 );
}

run_is 'input', 'expected';

__END__


=== One command

--- input
ppipe [ 'cmd1' ];

--- expected
  cmd1

=== One command w/ one arg

--- input
ppipe [ 'cmd1', 'a' ];

--- expected
  cmd1	\
    a

=== One command w/ one arg + value, no sep

--- input
ppipe [ 'cmd1', [ 'a', 3 ] ];

--- expected
  cmd1	\
    a 3

=== One command w/ one arg + blank value, no sep

--- input
ppipe [ 'cmd1', [ 'a', '' ] ];

--- expected
  cmd1	\
    a ''

=== One command w/ one arg + value, sep

--- input
ppipe [ 'cmd1', argsep '=', [ 'a', 3 ] ];

--- expected
  cmd1	\
    a=3

=== One command w/ one arg + value, pfx, no sep

--- input
ppipe [ 'cmd1', argpfx '-', [ 'a', 3 ] ];

--- expected
  cmd1	\
    -a 3

=== One command w/ one arg + value, pfx, sep

--- input
ppipe [ 'cmd1', argpfx '--', argsep '=', [ 'a', 3 ], [ 'b', 'is after a' ] ];

--- expected
  cmd1	\
    --a=3	\
    --b='is after a'

=== One command w/ two args

--- input
ppipe [ 'cmd1', 'a', 'b' ];

--- expected
  cmd1	\
    a	\
    b

=== One command w/ one stream

--- input
ppipe [ 'cmd1', '>', 'file' ];

--- expected
  cmd1	\
> file


=== One command w/ one stream, one arg

--- input
ppipe [ 'cmd1', '>', 'file', '-a' ];

--- expected
  cmd1	\
    -a	\
> file

=== One command w/ two streams

--- input
ppipe [ 'cmd1', '>', 'stdout', '2>', 'stderr' ];

--- expected
  cmd1	\
> stdout	\
2> stderr

=== One command w/ two streams, one arg

--- input
ppipe [ 'cmd1', '>', 'stdout', '2>', 'stderr', '-a' ];

--- expected
  cmd1	\
    -a	\
> stdout	\
2> stderr


=== Two commands
Two simple commands

--- input
ppipe ['cmd1' ], [ 'cmd2'];

--- expected
  cmd1	\
| cmd2


=== Two commands w/ args

--- input
ppipe ['cmd1', '-a' ], [ 'cmd2', '-b' ];

--- expected
  cmd1	\
    -a	\
| cmd2	\
    -b


=== Two commands w/ args and one stream apiece

--- input
ppipe [ 'cmd1', '-a', '2>', 'stderr' ],
      [ 'cmd2', '-b', '>', 'stdout' ];

--- expected
  cmd1	\
    -a	\
2> stderr	\
| cmd2	\
    -b	\
> stdout

=== Two commands w/ args and two streams apiece

--- input
ppipe [ 'cmd1', '-a', '2>', 'stderr', '3>', 'out put' ],
      [ 'cmd2', '-b', '>', 0, '2>', 'std err' ];

--- expected
  cmd1	\
    -a	\
2> stderr	\
3> 'out put'	\
| cmd2	\
    -b	\
> 0	\
2> 'std err'

=== Two commands + pipe streams

--- input
ppipe [ 'cmd1' ],
      [ 'cmd2' ], '>', 'stdout';

--- expected
(	\
  cmd1	\
| cmd2	\
)	\
> stdout



=== Two commands w/ args and one stream apiece + pipe streams

--- input
ppipe [ 'cmd 1', '-a', '2>', 'std err' ],
      [ 'cmd 2', '-b', '>', 'std out' ],
      '>', 0;

--- expected
(	\
  'cmd 1'	\
    -a	\
2> 'std err'	\
| 'cmd 2'	\
    -b	\
> 'std out'	\
)	\
> 0
