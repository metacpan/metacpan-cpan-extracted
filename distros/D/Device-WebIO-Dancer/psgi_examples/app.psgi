use Dancer;
use Device::WebIO::Dancer;
use Device::WebIO;
use Plack::Builder;

my $webio = Device::WebIO->new;
Device::WebIO::Dancer::init( $webio );

 
builder {
    do 'psgi_examples/default_enable.pl'
        or die "Can't open default_enable.pl: $!\n";
    dance;
};
