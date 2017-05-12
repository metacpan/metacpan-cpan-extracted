#This runs all tests - but we need to start to split these up for schedulers

#use Test::Class::Moose::Load 't/lib';
#use Test::Class::Moose::Runner;

#Test::Class::Moose::Runner->new->runtests;

use File::Spec::Functions qw( catdir  );
use FindBin qw( $Bin  );
use Test::Class::Moose::Load catdir( $Bin,  'lib' );
use Test::Class::Moose::Runner;
Test::Class::Moose::Runner->new( classes => ['TestsFor::HPC::Runner::Command::Plugin::Test001'], )
    ->runtests;
