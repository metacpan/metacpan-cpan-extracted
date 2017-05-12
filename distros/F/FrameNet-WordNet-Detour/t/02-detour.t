#!perl

use Test::More tests => 24;

use FrameNet::WordNet::Detour;
use FrameNet::WordNet::Detour::Data;
use FrameNet::WordNet::Detour::Frame;
 SKIP: {
     skip "\$WNHOME and/or \$FNHOME not set", 24
	 unless ( exists($ENV{'WNHOME'}) and exists($ENV{'FNHOME'}) );
     my $detour = FrameNet::WordNet::Detour->new(-cached => 1);
#$detour->unlimited;
#$detour->cached;

# formal part - checking if all functions return the right type
     my $qr = $detour->query("get#v#1");
     like($qr,
	  qr/^FrameNet::WordNet::Detour::Data/, 
	  "Testing if query() returns a good reference");
     
     use WordNet::QueryData;
     my $qd = WordNet::QueryData->new($ENV{'WNHOME'}."/dict");
     my $detour2 = FrameNet::WordNet::Detour->new(-wnquerydata => $qd);
     like($detour->query("get#v#10"),qr/^FrameNet::WordNet::Detour::Data/,
	  "Testing if detour works with a given WordNet::QueryData object");
     
# FrameNet::WordNet::Detour::Data
     isnt($qr->message,"",
	  "Testing if Data::message returns a non-empty scalar");
     
     isnt($qr->query,"",
	  "Testing if Data::query returns a non-empty scalar");
     
     cmp_ok(scalar $qr->get_fees("getting"), '>', 0 ,
	    "Testing if Data::get_fees returns an array");
     
     isnt($qr->get_weight("Getting"),"",
	  "Testing if Data::get_weight returns a non-empty scalar");
     
     like($qr->get_number_of_frames, qr/\d+/,
	  "Testing if Data::get_number_of_frames returns a number");
     
     is(ref $qr->get_best_frames, "ARRAY",
	"Testing if Data::get_best_frames returns an array");
     
     is(ref $qr->get_best_framenames, "ARRAY",
	"Testing if Data::get_best_framenames returns an array");
     
     is(ref $qr->get_all_frames, "ARRAY",
	"Testing if Data::get_all_frames returns an array");

     is(ref $qr->get_all_framenames, "ARRAY",
	"Testing if Data::get_all_framenames returns an array");
     
     is(ref $qr->get_frame("Getting"), 
	"FrameNet::WordNet::Detour::Frame",
	"Testing if Data::get_frame returns a Detour::Frame object");
     
     like($qr->get_best_weight,qr/[\d\.]+/,
	  "Testing if Data::get_best_weight returns a number");
     
     is(ref $qr->get_frames_with_weight($qr->get_best_weight),
	"ARRAY",
	"Testing if Data::get_frames_with_weight returns an array");

# FrameNet::WordNet::Detour::Frame
     
     my $f = $qr->get_frame("Getting");
     like($f->weight,qr/[\d\.]+/,
	  "Testing if Frame::weight returns a number");
     
     like($f->name,qr/[\w_]/,
	  "Testing if Frame::name returns a potential frame name");
     
     is(ref scalar $f->fees,"ARRAY",
	"Testing if Frame::fees returns an array");

     is(ref scalar $f->sims, "ARRAY",
	"Testing if Frame::sims returns an array");

# content part
     ok($detour->query("get#v#1")->isOK, 
	"Testing if a simple Query returns a result");

     ok(! $detour->query("get#")->isOK,
	"Testing if a syntactically wrong query fails");
     
     my @l = @{$detour->query("get#v#7")->get_best_framenames};

     ok(@l > 0, "Examining a complex query");

     is($l[1],
	"Feeling",
	"Checking if the result is correct");

     is(ref $detour->query("drink#v"),
	"ARRAY",
	"Testing if a underspecified result returns an array");

     is($detour->query("get#v#1")->query,
	"get#v#1",
	"Checking if the embedded classes work correctly");
}
