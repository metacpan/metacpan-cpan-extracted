#!perl

use strict;
use warnings;

use Test2::V0;
use Test::Lib;
use My::Test::Render;

use IPC::PrettyPipe::Render::Template::Tiny;

my %expected = (

    T1 =>
        << 'EOT'
  cmd1
EOT
    ,
    T2 =>
        << 'EOT'
  cmd1     \
    a
EOT
    ,

    T3 =>
        << 'EOT'
  cmd1     \
    a 3
EOT
    ,
    T4 =>
        << 'EOT'
  cmd1      \
    a ''
EOT
    ,
    T5 =>
        << 'EOT'
  cmd1     \
    a=3
EOT
    ,
    T6 =>
        << 'EOT'
  cmd1      \
    -a 3
EOT
    ,
    T7 =>
        << 'EOT'
  cmd1                  \
    --a=3               \
    --b='is after a'
EOT
    ,
    T8 =>
        << 'EOT'
  cmd1     \
    a      \
    b
EOT
    ,
    T9 =>
        << 'EOT'
  cmd1        \
    > file
EOT
    ,
    T10 =>
        << 'EOT'
  cmd1        \
    -a        \
    > file
EOT
    ,
    T11 =>
        << 'EOT'
  cmd1           \
    > stdout     \
    2> stderr
EOT
    ,
    T12 =>
        << 'EOT'
  cmd1           \
    -a           \
    > stdout     \
    2> stderr
EOT
    ,
    T13 =>
        << 'EOT'
  cmd1     \
| cmd2
EOT
    ,
    T14 =>
        << 'EOT'
  cmd1     \
    -a     \
| cmd2     \
    -b
EOT
    ,
    T15 =>
        << 'EOT'
  cmd1            \
    -a            \
    2> stderr     \
| cmd2            \
    -b            \
    > stdout
EOT
    ,
    T16 =>
        << 'EOT'
  cmd1               \
    -a               \
    2> stderr        \
    3> 'out put'     \
| cmd2               \
    -b               \
    > 0              \
    2> 'std err'
EOT
    ,
    T17 =>
        << 'EOT'
(             \
  cmd1        \
| cmd2        \
) > stdout
EOT
    ,
    T18 =>
        << 'EOT'
(                    \
  'cmd 1'            \
    -a               \
    2> 'std err'     \
| 'cmd 2'            \
    -b               \
    > 'std out'      \
) > 0
EOT
    ,
    T19 =>
        << 'EOT'
(                       \
  'cmd 1'               \
    -a                  \
    2> 'std err'        \
|     'cmd 2'           \
        -b              \
        > 'std out'     \
) > 0
EOT
    ,
    T20 =>
        << 'EOT'
(                    \
  'cmd 1'            \
    -a               \
    2> 'std err'     \
| 'cmd 2'            \
    -b               \
    > 'std out'      \
) > 0
EOT
    ,
    T21 =>
        << 'EOT'
  'cmd 1'               \
    -a                  \
    2> 'std err'        \
| (                     \
    'cmd 2'             \
        -b              \
        > 'std out'     \
  ) > 0
EOT
    ,
);

test_renderer( IPC::PrettyPipe::Render::Template::Tiny->new( colorize => 0, ), \%expected );

done_testing;
