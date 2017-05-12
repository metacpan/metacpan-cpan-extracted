use FindBin ;

require "$FindBin::Bin/ParseSource.pm" ;
require "$FindBin::Bin/WrapXS.pm" ;

my $xs = Embperl::WrapXS->new;

my $result = $xs->checkmaps ($ARGV[0]) ;

print Data::Dumper::Dumper ($result) ;


