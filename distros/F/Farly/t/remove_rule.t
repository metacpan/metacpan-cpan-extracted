use strict;
use warnings;
use Farly;
use Farly::Rule::Expander;
use Farly::Remove::Rule;
use Farly::Template::Cisco;
use Test::Simple tests => 1;
use File::Spec; 

my $abs_path = File::Spec->rel2abs( __FILE__ );
our ($volume,$dir,$file) = File::Spec->splitpath( $abs_path );
my $path = $volume.$dir;

my $importer = Farly->new();
my $fw = $importer->process( 'ASA', "$path/test.cfg" );

my $expander = Farly::Rule::Expander->new($fw);

my $entries = $expander->expand_all();

my $rules = Farly::Object::List->new();

my $ce0 = Farly::Object->new();
$ce0->set('ID', Farly::Value::String->new('outside-in') );

$entries->matches( $ce0, $rules );

my $ce1 = Farly::Object->new();
$ce1->set('LINE', Farly::Value::Integer->new('3') );

my $ce2 = Farly::Object->new();
$ce2->set('LINE', Farly::Value::Integer->new('5') );
$ce2->set('DST_IP', Farly::IPv4::Address->new('192.168.2.1') );

foreach my $obj ( $rules->iter() ) {
    if ($obj->matches($ce1) || $obj->matches($ce2) ) {
    $obj->set( 'REMOVE', Farly::Value::String->new('RULE') );
    }
}

my $remover = Farly::Remove::Rule->new($fw);

$remover->remove($rules);

my $string;
my $template = Farly::Template::Cisco->new('ASA', 'OUTPUT' => \$string);

foreach my $object ( $remover->result()->iter() ) {
	$template->as_string($object);
	$string .= "\n";
}

my $expected = q{no access-list outside-in extended permit 6 object-group customerX object-group high_ports host 192.168.10.1 eq 80
access-list outside-in line 5 extended permit 6 any host 192.168.2.3 eq 1494
access-list outside-in line 5 extended permit 6 any host 192.168.2.2 eq 1494
no access-list outside-in extended permit object citrix any object-group citrix_servers
};

#print $string;

ok( $string eq $expected, "remove address" );
