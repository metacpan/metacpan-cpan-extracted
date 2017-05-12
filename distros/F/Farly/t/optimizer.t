use strict;
use warnings;
use File::Spec;
use Test::Simple tests => 9;
use Farly;
use Farly::Rule::Optimizer;
use Farly::Rule::Expander;

my $abs_path = File::Spec->rel2abs(__FILE__);
our ( $volume, $dir, $file ) = File::Spec->splitpath($abs_path);
my $path = $volume . $dir;

my $importer  = Farly->new();
my $container = $importer->process( "ASA", "$path/test.cfg" );

eval { my $optimizer1 = Farly::Rule::Optimizer->new($container); };

ok( $@ =~ /found invalid object/, "not expanded" );

ok( $container->size() == 65, "import" );

my $rule_expander = Farly::Rule::Expander->new($container);

ok( defined($rule_expander), "constructor" );

# get the raw rule entries

my $expanded_rules = $rule_expander->expand_all();

ok( $expanded_rules->size == 22, "expand_all" );

my $optimizer;

eval { $optimizer = Farly::Rule::Optimizer->new($expanded_rules); };

ok( $@ =~ /found invalid object/, "not single rule set" );

my $search = Farly::Object->new();
$search->set( "ID" => Farly::Value::String->new("outside-in") );

my $search_result = Farly::Object::List->new();

$expanded_rules->matches( $search, $search_result );

$optimizer = Farly::Rule::Optimizer->new($search_result);
#$optimizer->verbose(1);
$optimizer->set_l4(); #not really needed, this is the default mode
$optimizer->run();

ok( $optimizer->optimized->size() == 20, "optimized" );

ok( $optimizer->removed->size() == 1, "removed" );

my $l4_optimized = $optimizer->optimized();

$optimizer = Farly::Rule::Optimizer->new($l4_optimized);
#$optimizer->verbose(1);
$optimizer->set_l3();
$optimizer->run();

ok( $optimizer->optimized->size() == 19, "l3 mode - optimized" );

my $l3_optimized = $optimizer->optimized();

$optimizer = Farly::Rule::Optimizer->new($l3_optimized);
#$optimizer->verbose(1);
$optimizer->set_icmp();
$optimizer->run();

ok( $optimizer->optimized->size() == 16, "icmp mode - optimized" );

