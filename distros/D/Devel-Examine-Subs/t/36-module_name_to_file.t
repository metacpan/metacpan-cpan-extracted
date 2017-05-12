#!perl 
use warnings;
use strict;

use Data::Dumper;
use Test::More tests => 3;
use Test::Trap;

BEGIN {#1
    use_ok( 'Devel::Examine::Subs' ) || print "Bail out!\n";
}
my $des;

eval {
    $des = Devel::Examine::Subs->new(
                            file => 'Data::Dumper',
                          );
};

ok ($des->{params}{file} =~ /Data\/Dumper\.pm/, "Module finds the file" );

eval {
    $des->run({file => 'Bad::XXX'});
};

isnt ($@, undef, "{file => 'module'} with module not found croaks with DES error msg");

