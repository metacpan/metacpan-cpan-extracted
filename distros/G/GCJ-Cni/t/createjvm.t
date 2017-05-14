use Test::Simple tests => 2;
use GCJ::Cni;

eval {
	my $ret_val = GCJ::Cni::JvCreateJavaVM("something bad");
};

if ( $@ ) {
	ok(1);
}

my $ret_val2 = GCJ::Cni::JvCreateJavaVM(undef);

ok( $ret_val2 == 0 );
