use strict;
use warnings;

use Test::More;
use File::Spec; 
use Farly::ASA::Filter;
use Farly::ASA::Parser;
use IO::File;

eval "use Test::Memory::Cycle";

if($@){
    plan skip_all => "Test::Memory::Cycle is required to run this test";
}

my $abs_path = File::Spec->rel2abs( __FILE__ );
our ($volume,$dir,$file) = File::Spec->splitpath( $abs_path );
my $path = $volume.$dir;

my $filter = Farly::ASA::Filter->new;
my $parser = Farly::ASA::Parser->new;

$filter->set_file(IO::File->new("$path/test.cfg"));

foreach ($filter->run){
    my $tree = $parser->parse($_);
    memory_cycle_ok($tree)
}
done_testing;

