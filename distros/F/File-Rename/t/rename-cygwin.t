use strict;
use warnings;

use Test::More;
BEGIN { push @INC, qw(blib/script blib/bin) if -d 'blib' };

plan skip_all => "Not cygwin", 3 unless $^O eq 'cygwin';
 
    plan tests => 3;
    ok( eval { require('file-rename') }, 'cygwin: script is file-rename');
    ok( !eval { require('rename') }, 'cygwin: script not rename');
    like( $INC{'file-rename'}, qr{/ file-rename \z}msx, 
        "required script in \%INC");

