use strict;
use warnings;

use JavaBin;
use Test::Fatal;
use Test::More;

is from_javabin(), undef, 'from_javabin no args, scalar context';

is_deeply [from_javabin()], [], 'from_javabin no args, array context';

my %from = (
     'expected version 2' => "\0\0",
    'insufficient length' => '',
);

is exception { from_javabin $from{$_} },
    "Invalid from_javabin input: $_ at $0 line @{[__LINE__-1]}.\n",
    "from_javabin $_"
        for sort keys %from;

format=
.

my %to = (
      'double reference' => \.1,
                'format' => *STDOUT{FORMAT},
            'I/O object' => *STDIN{IO},
                'object' => bless(\$_),
    'regular expression' => qr//,
      'string reference' => \"",
            'subroutine' => sub {},
              'typeglob' => *STDIN,
                 'undef' => undef,
);

is to_javabin( $to{$_} ), "\2\0", "to_javabin $_" for sort keys %to;

done_testing;
