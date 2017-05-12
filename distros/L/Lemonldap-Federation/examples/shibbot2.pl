use Lemonldap::Federation::ShibbolethRequestMap ;
use XML::Simple;
use Data::Dumper;
my $file = shift||"./shibboleth.xml";
my $uri= shift || "https://sp.example.org/secure/admin/";
my $test;
eval {
$test = XMLin( $file,
  #   'ForceArray' => '1'
			 );		     
} ;
my $extrait_de_xml = $test->{RequestMapProvider}->{RequestMap} ;
my $extrait_de_xml2 = $test->{Applications} ;

my $requestmap = Lemonldap::Federation::ShibbolethRequestMap->new( xml_host => $extrait_de_xml ,
                                  xml_application=> $extrait_de_xml2 ,
                                  uri => $uri , ) ;
my $r= $requestmap->application_id;
print "$r\n";
my  $redirection = $requestmap->redirection ;
 
print "$redirection\n";

  
