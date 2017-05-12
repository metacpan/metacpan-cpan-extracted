#!perl
use warnings;
use strict;

use Test::More tests => 20;

BEGIN {#1
    use_ok( 'Devel::Examine::Subs::Engine' ) || print "Bail out!\n";
    use_ok( 'Devel::Examine::Subs::Postprocessor' ) || print "Bail out!\n";
    use_ok( 'Devel::Examine::Subs' ) || print "Bail out!\n";
}

my $pf = Devel::Examine::Subs::Preprocessor->new();
my $e = Devel::Examine::Subs::Engine->new();
my $pf_dt = $pf->_dt();
my $e_dt = $e->_dt();

{
    my $des = Devel::Examine::Subs->new();
    my @post_processors = $des->post_procs();
    my @engines = $des->engines();
    
    isa_ok(\@post_processors, 'ARRAY', "post_processors() returns an array");
    isa_ok(\@engines, 'ARRAY', "engines() returns an array");

    for (keys %$pf_dt){
        ok ( grep /$_/, @post_processors, "post_processors() returns all the post_proc names" );
    }
    for (keys %$e_dt){
        ok ( grep /$_/, @engines, "post_processors() returns all the post_proc names" );
    }


}
