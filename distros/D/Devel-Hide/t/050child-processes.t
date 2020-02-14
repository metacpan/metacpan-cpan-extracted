use strict;
use warnings;
use Devel::Hide qw(-quiet -from:children Q.pm R);

# Mlib=t is to get around 'use lib' etc being annoying

$ENV{PERL5OPT} = '-Mblib '.$ENV{PERL5OPT}
    if($INC{'blib.pm'});
$ENV{PERL5OPT} = '-Mlib=t '.$ENV{PERL5OPT};

# run this script and tell it to:
#  try to load P, Q and R;
#  expect only P to succeed;
# moan about Q and R
my $ans = system( $^X, qw(
    t/child.pl try:PQR succeed:P moan:QR
) );

exit( $ans >> 8 );
