use strict;
use warnings;

use Test::Simple tests => 3;

use File::Spec; 

my $abs_path = File::Spec->rel2abs( __FILE__ );
our ($volume,$dir,$file) = File::Spec->splitpath( $abs_path );
my $path = $volume.$dir;

use Farly;
my $importer = Farly->new();

my $container = $importer->process( "ASA", "$path/test.cfg" );

ok( $container->size() == 65, "import");

use Farly::Rule::Expander;

my $rule_expander = Farly::Rule::Expander->new( $container );

ok( defined($rule_expander), "constructor" );

# get the expanded entries

my $expanded_rules = $rule_expander->expand_all();

ok( $expanded_rules->size == 22, "expand_all" );
