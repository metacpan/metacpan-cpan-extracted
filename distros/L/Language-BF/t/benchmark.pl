#
# $Id: benchmark.pl,v 0.3 2007/11/13 12:31:06 dankogai Exp dankogai $
#
use strict;
use warnings;
use Language::BF;
use Benchmark ':all';

my $bf = Language::BF->new(<<EOC);
++++++++++[>+++++++>++++++++++>+++>+<<<<-]>++.>+.+++++++..+++.>++.<<
+++++++++++++++.>.+++.------.--------.>+.>.
EOC

cmpthese(
    timethese(
        0,
        {
            compiler    => sub { $bf->reset->run(0) },
            interpreter => sub { $bf->reset->run(1) },
        }
    )
);

