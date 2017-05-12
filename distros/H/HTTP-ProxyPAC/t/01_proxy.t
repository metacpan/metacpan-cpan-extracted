my @interps;
BEGIN {
  eval "require JavaScript";
  if (!$@) {push @interps, 'javascript'}
  eval "require JE";
  if (!$@) {push @interps, 'je'}  
}
use HTTP::ProxyPAC;
use FindBin;
use Test::More tests => 26*@interps;
use URI;
use LWP::UserAgent;

if (!@interps) {BAIL_OUT("Neither the JavaScript nor JE module is installed")}

my $path = "$FindBin::Bin/proxy.pac";

my $ua = LWP::UserAgent->new(timeout => 30);
my ($url, $urlOK);
   
for ($HTTP::ProxyPAC::VERSION, '0.01') {
  # put a previous version here ^, in case we haven't uploaded this $VERSION yet
  $url = "http://cpansearch.perl.org/src/MIYAGAWA/HTTP-ProxyPAC-$_/t/proxy.pac";
  my $resp = $ua->head($url);
  if ($resp->is_success) {
    $urlOK = 1;
    last;
} }
undef $ua;

# perform the tests for the installed interpreter(s) and both libraries
for my $interp (@interps) {
  for my $lib ('javascript', 'perl') {
  
    diag("testing with $interp interpreter and $lib PAC-library");

    # test via path
    my $pac = HTTP::ProxyPAC->new($path, 'interp' => $interp, 'lib' => $lib);
    
    my $res = $pac->find_proxy("http://www.google.com/");
    ok $res->direct, "direct for Google";
    ok !$res->proxy, "not proxy for Google";
    
    $res = $pac->find_proxy("http://intra.example.com/");
    ok !$res->direct, "scalar example is not direct";
    is $res->proxy->host_port, 'proxy.example.jp:8080', 
       "scalar example should be proxy";
    
    @res = $pac->find_proxy("http://intra.example.com/");
    is scalar @res, 2, "array example returns 2 choices";
    is $res[0]->proxy->host_port, 'proxy.example.jp:8080', 
       "first array example should be proxy";
    ok $res[1]->direct, "second array example should be direct";
    
    $res = $pac->find_proxy("http://localhost/");
    ok $res->direct, "localhost should be direct";
    
    $res = $pac->find_proxy("http://192.168.108.3/");
    ok !$res->direct, "192 IP ad should not be direct";
    is $res->proxy->host_port, 'proxy.example.jp:8080', 
       "192 IP ad should yield example proxy";
    
    # test via URL
    SKIP: {
        skip "Problems accessing the internet", 1 unless $urlOK;
        $pac = HTTP::ProxyPAC->new(URI->new($url), 'interp' => $interp, 'lib' => $lib);
        $res = $pac->find_proxy("http://www.google.com/");
        ok $res->direct;
    }
    
    # test via scalar ref
    open my $fh, $path or die "$path: $!";
    my $code = join '', <$fh>;
    
    $pac = HTTP::ProxyPAC->new(\$code, 'interp' => $interp, 'lib' => $lib);
    $res = $pac->find_proxy("http://www.google.com/");
    ok $res->direct, "scalar ref PAC: google should be direct";
    
    # test via filehandle
    open my $fh2, $path or die "$path: $!";
    
    $pac = HTTP::ProxyPAC->new($fh2, 'interp' => $interp, 'lib' => $lib);
    $res = $pac->find_proxy("http://www.google.com/");
    ok $res->direct, "filehandle PAC: google should be direct";
} }