BEGIN {
    unless ($ENV{RELEASE_TESTING} || $ENV{ONLINE_TESTS}) {
        require Test::More;
        Test::More::plan(skip_all=>'these online tests require env variable ONLINE_TESTS be set to run');
    }
}

use Test::More;

use LWPx::ParanoidAgent;
 
my @urls = qw(
    https://raw.github.com/csirtgadgets/LWPx-ParanoidAgent/master/testdata/small.txt
    https://raw.github.com/csirtgadgets/LWPx-ParanoidAgent/master/testdata/512.txt
    https://raw.github.com/csirtgadgets/LWPx-ParanoidAgent/master/testdata/19200.txt
    https://raw.github.com/csirtgadgets/LWPx-ParanoidAgent/master/testdata/20480.txt
    https://raw.github.com/csirtgadgets/LWPx-ParanoidAgent/master/testdata/40960.txt
);
 
my $ua = LWPx::ParanoidAgent->new(
    ssl_opts => {
        verify_hostname => 0,
        SSL_verify_mode => 'SSL_VERIFY_NONE',
    }
);

foreach my $url (@urls) {
    my $res=$ua->get($url);
    ok($res->status_line !~ m/Can't read entity body/);
    ok($res->is_success());
}

done_testing();