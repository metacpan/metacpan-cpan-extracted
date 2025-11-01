use feature "say";
use Hustle::Table;
use Test::More;
use Data::Dumper;

my $table=Hustle::Table->new;

$table->add({matcher=>qq"a/(\w+)/(\w+)",value=>sub {}});
$table->add({matcher=>qq"b/(\w+)/(\w+)",value=>sub {}});

my $d;
my $cache;
for(1..1000){

  $d=$table->prepare_dispatcher(cache=>$cache);;
  #say STDERR $d;
  my @results=$d->("a/testing/1234");
  #say STDERR Dumper @results;

};

ok defined $d;
done_testing;
