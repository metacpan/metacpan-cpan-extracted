use Test::More qw/no_plan/;
use Egg::Helper::VirtualTest;
use XML::FeedPP;

my $test= Egg::Helper::VirtualTest->new;
   $test->prepare(
     config=> { MODEL=> [ [ FeedPP => {} ] ] },
     );

my $e= $test->egg_pcomp_context;

my $rss= XML::FeedPP::RSS->new;
$rss->title('TEST');
$rss->add_item( 'http://test/', title=> 'test1' );
my $rss_text= $rss->to_string;

ok my $model= $e->model('FeedPP');
isa_ok $model, 'Egg::Model::FeedPP';
isa_ok $model, 'Egg::Model';
can_ok $model, qw/new feed/;
ok my $feed= $model->feed($rss_text);
isa_ok $feed, 'XML::FeedPP';
