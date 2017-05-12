
use FindBin ;

require "$FindBin::Bin/ParseSource.pm" ;

#$::RD_TRACE = 50 ;

Embperl::ParseSource->run  ;

