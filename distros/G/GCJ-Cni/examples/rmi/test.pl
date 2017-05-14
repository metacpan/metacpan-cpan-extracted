use RmiExample;
use GCJ::Cni;

GCJ::Cni::JvCreateJavaVM(undef);
GCJ::Cni::JvAttachCurrentThread(undef, undef);

my $example = new RmiExample::Client();
$example->connect();
my $bean = $example->getBeanFromServer();
print $bean->getValue() . "\n";


$bean->DISOWN() if $bean;
$example->DISOWN() if $example;

GCJ::Cni::JvDetachCurrentThread();
