use FindBin ;

require "$FindBin::Bin/ParseSource.pm" ;
require "$FindBin::Bin/WrapXS.pm" ;

Embperl::WrapXS->run;


