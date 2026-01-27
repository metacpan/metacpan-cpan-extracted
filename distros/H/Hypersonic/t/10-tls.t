use strict;
use warnings;
use Test::More;

use lib 'lib';
use lib '../XS-JIT/blib/lib';
use lib '../XS-JIT/blib/arch';

# Test TLS configuration options

use Hypersonic;

# Check if TLS is available
my $HAS_TLS = 0;
eval { 
    require Hypersonic::TLS; 
    $HAS_TLS = Hypersonic::TLS::check_openssl(); 
};

plan tests => 6;

# Test 1: TLS disabled by default
{
    my $server = Hypersonic->new(cache_dir => '_test_cache_tls1');
    is($server->{tls}, 0, 'TLS disabled by default');
}

# Test 2: TLS requires cert_file (or TLS not available)
SKIP: {
    skip "OpenSSL not available", 1 unless $HAS_TLS;
    
    eval {
        Hypersonic->new(
            cache_dir => '_test_cache_tls2',
            tls => 1,
        );
    };
    like($@, qr/cert_file required/, 'TLS requires cert_file');
}

# Test 3: TLS requires key_file
SKIP: {
    skip "OpenSSL not available", 1 unless $HAS_TLS;
    
    # Create a temp cert file for testing
    my $cert_file = '_test_cert.pem';
    open my $fh, '>', $cert_file or die;
    print $fh "fake cert\n";
    close $fh;
    
    eval {
        Hypersonic->new(
            cache_dir => '_test_cache_tls3',
            tls => 1,
            cert_file => $cert_file,
        );
    };
    like($@, qr/key_file required/, 'TLS requires key_file');
    
    unlink $cert_file;
}

# Test 4: TLS validates cert file exists
SKIP: {
    skip "OpenSSL not available", 1 unless $HAS_TLS;
    
    eval {
        Hypersonic->new(
            cache_dir => '_test_cache_tls4',
            tls => 1,
            cert_file => '/nonexistent/cert.pem',
            key_file => '/nonexistent/key.pem',
        );
    };
    like($@, qr/cert_file not found/, 'TLS validates cert_file exists');
}

# Test 5: TLS validates key file exists
SKIP: {
    skip "OpenSSL not available", 1 unless $HAS_TLS;
    
    my $cert_file = '_test_cert.pem';
    open my $fh, '>', $cert_file or die;
    print $fh "fake cert\n";
    close $fh;
    
    eval {
        Hypersonic->new(
            cache_dir => '_test_cache_tls5',
            tls => 1,
            cert_file => $cert_file,
            key_file => '/nonexistent/key.pem',
        );
    };
    like($@, qr/key_file not found/, 'TLS validates key_file exists');
    
    unlink $cert_file;
}

# Test 6: TLS module availability check
SKIP: {
    eval { require Hypersonic::TLS };
    skip "Hypersonic::TLS not available", 1 if $@;
    
    my $has_openssl = Hypersonic::TLS::check_openssl();
    ok(defined $has_openssl, 'check_openssl returns defined value');
}

# Cleanup
for my $i (1..5) {
    my $dir = "_test_cache_tls$i";
    system("rm -rf $dir") if -d $dir;
}

done_testing();
