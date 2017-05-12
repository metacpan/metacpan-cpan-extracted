
use strict;
use Devel::Hide qw(-from:children Q.pm R);

# Mlib=t is to get around 'use lib' etc being annoying

$ENV{PERL5OPT} = 'Mlib=t '.$ENV{PERL5OPT};

my $ans = system( $^X, 't/child.pl' );

exit( $ans >> 8 );
