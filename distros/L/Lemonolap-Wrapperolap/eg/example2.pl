use Lemonolap::Wrapperolap;
my $wrapper = Lemonolap::Wrapperolap->new (config => "/myxml.xml",
                                           workflow => ['format','filter']
                                               );
$wrapper->run (header =>1 );

