use strict;
use warnings;

use Test::More;

use Path::Iterator::Rule 1.003;
use Path::Tiny;
use List::Util qw/ max /;
use List::MoreUtils qw/ indexes /;

Path::Iterator::Rule->new
    ->perl_file
    ->all( qw# t lib bin #, { visitor => sub {
        my $file = path(shift);

        my @lines = $file->lines;

        my @indexes = indexes { /\$DB::single/ } @lines
            or return pass $file;

        fail $file;

        for ( @indexes ) {
            diag "\$DB::single found at line $_";

            diag @lines[max(0, $_ - 3)..$_+3];
        }

}} );

done_testing;

