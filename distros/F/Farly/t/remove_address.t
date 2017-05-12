use strict;
use warnings;
use Farly;
use Farly::Template::Cisco;
use Farly::Remove::Address;
use Test::Simple tests => 1;
use File::Spec; 

my $abs_path = File::Spec->rel2abs( __FILE__ );
our ($volume,$dir,$file) = File::Spec->splitpath( $abs_path );
my $path = $volume.$dir;

my $importer = Farly->new();
my $fw = $importer->process( 'ASA', "$path/test.cfg" );

my $remover = Farly::Remove::Address->new($fw);

$remover->remove( Farly::IPv4::Address->new('10.1.2.3') );
$remover->remove( Farly::IPv4::Network->new('10.1.2.0/24') );

my $string;
my $template = Farly::Template::Cisco->new('ASA', 'OUTPUT' => \$string);

foreach my $object ( $remover->result()->iter() ) {
	$template->as_string($object);
	$string .= "\n";
}

my $expected = q{object-group network test_net
no network-object host 10.1.2.3
no access-list outside-in extended permit object citrix object internal_net object citrix_net
no object network internal_net
no object network test_net1_range
};
 
#print $string;

ok( $string eq $expected, "remove address" );
