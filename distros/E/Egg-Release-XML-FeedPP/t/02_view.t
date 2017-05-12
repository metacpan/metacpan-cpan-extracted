use Test::More qw/no_plan/;
use Egg::Helper::VirtualTest;

my $test= Egg::Helper::VirtualTest->new;
   $test->prepare(
     config=> { VIEW=> [ [ FeedPP => {} ] ] },
     );

my $e= $test->egg_pcomp_context;

ok my $view= $e->view('FeedPP');
isa_ok $view, 'Egg::View::FeedPP';
isa_ok $view, 'Egg::View';
can_ok $view, qw/_setup new cache feed_type feed reset render output/;

