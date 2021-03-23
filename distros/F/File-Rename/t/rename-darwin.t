use strict;
use warnings;

use Test::More;
BEGIN { push @INC, qw(blib/script) if -d 'blib' };

plan skip_all => "Not darwin", 3 unless $^O eq 'darwin';
 
    plan tests => 3;
    ok( eval { require('rename') }, 'darwin: script is rename');
    ok( !eval { require('file-rename') }, 'darwin: script not file-rename');
    like( $INC{rename}, qr{/ rename \z}msx, "required script in \%INC");

