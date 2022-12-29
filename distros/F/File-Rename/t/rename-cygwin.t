use strict;
use warnings;

use Test::More;
BEGIN { push @INC, qw(blib/script blib/bin) if -d 'blib' };

plan skip_all => "Not cygwin" unless $^O eq 'cygwin';
 
plan tests => 3;
ok( eval { require('rename') }, 'cygwin: script is rename');
ok( !eval { require('file-rename') }, 'cygwin: script not file-rename');
like( $INC{'rename'}, qr{/ rename \z}msx, "required script in \%INC");

