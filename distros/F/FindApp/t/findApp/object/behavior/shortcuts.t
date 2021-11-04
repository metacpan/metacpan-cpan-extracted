#!/usr/bin/env perl 

use t::setup;

use FindApp::Utils <:{foreign,package,syntax,list}>;

require_ok(my $Class  = __TEST_CLASS__ );
require_ok(my $Top    = -$Class        );
require_ok(my $Parent =  $Class  - 1   );
require_ok(my $Gramps =  $Class  - 2   );

UNPACKAGE for $Class, $Top, $Parent, $Gramps;

sub generated_method_tests {
    my @methods = ( 
              <rootdir {bin,lib,man}dirs>,
               <rootdir_{is,has}>,
               <{bin,lib,man}dirs_{are,have}>,
               <export_{root,bin,lib,man}_to_env>,
                      <{root,bin,lib,man}dirs>,    <allowed found wanted>,
                      <{rootdir,{bin,lib,man}dirs}_{allowed,found,wanted}>,
        <{add,get,set}_{rootdir,{bin,lib,man}dirs}_{allowed,found,wanted}>,
    );  

    my $ob = $Top->new;

    for my $method (@methods) {
        ok  $Top->can($method),        "$Top can $method";
        ok !$Parent->can($method),     "$Parent can't $method";
        ok  $Gramps->can($method),     "$Gramps can $method";
        ok  $Class->can($method),      "$Class can $method";
        ok  $ob->can($method),         "$Top ob can $method";
    }   
}

run_tests();

1;
