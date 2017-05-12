use strict; 
use Test::Simple tests => 1;

eval "use Language::Homespring::Visualise::GraphViz";
ok(!$@, "loaded module $@"); 
