use Test::Simple tests => 3;
use GCJ::Cni;

GCJ::Cni::JvCreateJavaVM(undef);

eval {
	GCJ:Cni::JvAttachCurrentThread(undef, 2345);
};

if ( $@ ) {
	ok( 1 );
} else {
	ok( 0 );
}

eval {
	GCJ::Cni::JvAttachCurrentThread(34213, 34234);
};

if ( $@ ) {
	ok( 1 );
} else {
	ok( 0 );
}

my $ret_val4 = GCJ::Cni::JvAttachCurrentThread(undef, undef);
ok( $ret_val4 );
