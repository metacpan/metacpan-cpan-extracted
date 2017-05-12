#!perl -T

use Test::More tests => 4;

BEGIN {
    use_ok( FrameNet::WordNet::Detour);
    use_ok( FrameNet::WordNet::Detour::Data);
    use_ok( FrameNet::WordNet::Detour::Frame);
}

use FrameNet::WordNet::Detour;
use FrameNet::WordNet::Detour::Data;
use FrameNet::WordNet::Detour::Frame;



 SKIP: {
     skip "\$WNHOME and/or \$FNHOME not set", 1 
	 unless ( exists($ENV{'WNHOME'}) and exists($ENV{'FNHOME'}) );
     my $detour = FrameNet::WordNet::Detour->new;
     is(ref $detour,"FrameNet::WordNet::Detour", 'Testing if Detour loads');
}
