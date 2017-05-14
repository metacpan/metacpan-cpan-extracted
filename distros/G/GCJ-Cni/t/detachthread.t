use Test::Simple tests => 1;
use GCJ::Cni;

GCJ::Cni::JvCreateJavaVM(undef);
GCJ::Cni::JvAttachCurrentThread(undef, undef);
my $ret_val = GCJ::Cni::JvDetachCurrentThread();

ok( $ret_val == 0 );
