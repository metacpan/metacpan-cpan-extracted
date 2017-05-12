use warnings;
use strict;
use Test::More;
use Image::PNG::Libpng 'libpng_supports';

my @values = (qw/
sCAL
tEXt
zTXt
iTXt
pCAL
iCCP
sPLT
USER_LIMITS
UNKNOWN_CHUNKS
/);

for my $value (@values) {
    my $supported = libpng_supports ($value);
    ok ($supported == 0 || $supported == 1,
	"$value is known to Image::PNG::Libpng");
}

{
    my $guff;
    local $SIG{__WARN__} = sub { $guff = $_[0]; };
    my $supported = libpng_supports ('Pangalactic Gargleblaster');
    like ($guff, qr/^Unknown whether 'Pangalactic Gargleblaster' is supported/);
}


done_testing ();
