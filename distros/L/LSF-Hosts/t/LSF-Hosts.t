use Test::More tests => 3; 
BEGIN { use_ok('LSF::Hosts') };
can_ok('LSF::Hosts','new');
$LSF::Hosts::PrintOutput  = 0; # disabling output
$LSF::Hosts::RaiseError	  = 0; # disabling errors
$LSF::Hosts::PrintError	  = 0; # disabling error output
ok (defined(LSF::Hosts->new()), "Retrieve LSF hosts" );


