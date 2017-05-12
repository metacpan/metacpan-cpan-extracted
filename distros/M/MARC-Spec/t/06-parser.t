use Test::More;
use Test::Exception;
use MARC::Spec;

throws_ok { MARC::Spec->parse(['245']) } qr/SCALAR/, 'not scalar' ;
throws_ok { MARC::Spec->parse('245 $a') } qr/Whitespaces are not allowed./, 'has whitespace' ;
throws_ok { MARC::Spec->parse('2A') } qr/Spec must be at least/, 'only 2 chars' ;
throws_ok { MARC::Spec->parse('___') } qr/For fieldtag only/, 'unallowed chars' ;
throws_ok { MARC::Spec->parse('2Aa') } qr/For fieldtag only/, 'unallowed char combination' ;
throws_ok { MARC::Spec->parse('245a') } qr/Detected useless data fragment/, 'useless 1' ;
throws_ok { MARC::Spec->parse('245/1-2_01') } qr/Detected useless data fragment/, 'useless 2' ;
throws_ok { MARC::Spec->parse('245_01/1-2') } qr/Detected useless data fragment/, 'useless 3' ;
throws_ok { MARC::Spec->parse('245/1-2$a') } qr/Either characterSpec for field or subfields are allowed./, 'chapos and subfield' ;
throws_ok { MARC::Spec->parse('245$A') } qr/Invalid subfield spec detected./, 'invalid subfield' ;
throws_ok { MARC::Spec->parse('LDR/1-0') } qr/Ending character or index position must be equal or higher/, 'invalid charpos' ;

done_testing();