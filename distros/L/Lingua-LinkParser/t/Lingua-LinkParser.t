use strict;
use Test::More tests => 17;
use Data::Dumper;

BEGIN { use_ok('Lingua::LinkParser') };

my $parser = new Lingua::LinkParser;

ok($parser, "constructor");

$parser->opts('disjunct_cost' => 2,
              'linkage_limit' => 101,
              'verbosity'     => 1
             );

ok ($parser->opts('linkage_limit') == 101, "linkage_limit opts" );
ok ($parser->opts('disjunct_cost') == 2, "disjunct_cost opts");

my $sentence = $parser->create_sentence("We tried to make the tests exhaustive.");
ok ($sentence, "create_sentence");

my $num_linkages = $sentence->num_linkages;
ok ($num_linkages > 0, "num_linkages");

my $linkage = $sentence->linkage(1);
ok ($linkage, "linkage");

my $diagram = $parser->get_diagram($linkage);
like ($diagram, qr!we tried\.v-d to\.*r* make\.v!, "get_diagram");

my $num_sublinkages = $linkage->num_sublinkages;
ok ($num_sublinkages > 0, "num_sublinkages");

my $sublinkage = $linkage->sublinkage(1);
ok ($sublinkage, "sublinkage");

my $num_links = $sublinkage->num_links;
ok ($num_links > 0, "num_links");

my $link = $sublinkage->link(7);
ok ($link->num_domains > 0, "sublinkage link");

my @domain_names = $link->domain_names;
ok (@domain_names > 0, "domain_names");

like ($parser->print_constituent_tree($linkage,2), qr!\[S We \[VP tried to!, "print_constituent_tree");

ok ($linkage->num_links > 0, "num_links");

ok ($linkage->words > 0, "words");

my $tree = $linkage->constituent_tree();
ok (ref $tree, "constituent_tree()");


