use Test::More ;

eval q(
use Test::Legal  'license_ok',  
                 copyright_ok => { dirs=>['lib'] },
                 defaults => { base=> $ENV{PWD} =~ m#\/t$#  ? '..' : '.' , actions=>['fix']} ,
;
license_ok;
copyright_ok;
);

ok 1 if $@;

