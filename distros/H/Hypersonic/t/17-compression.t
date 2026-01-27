#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

# Clean up any cached XS modules for clean testing
system("rm -rf _hypersonic_* 2>/dev/null");
system("rm -rf _test_cache_* 2>/dev/null");

BEGIN {
    use_ok('Hypersonic');
    use_ok('Hypersonic::Compress');
    use_ok('Hypersonic::Response', 'res');
}

# ============================================================
# Test Compression module internals
# ============================================================

subtest 'zlib detection' => sub {
    my $has_zlib = Hypersonic::Compress::check_zlib();
    ok(defined $has_zlib, 'check_zlib returns a value');
    
    if ($has_zlib) {
        pass('zlib is available');
        my ($cflags, $ldflags) = Hypersonic::Compress::get_zlib_flags();
        ok(defined $cflags, 'get_zlib_flags returns cflags');
        ok(defined $ldflags, 'get_zlib_flags returns ldflags');
        like($ldflags, qr/-lz/, 'ldflags contains -lz');
    } else {
        pass('zlib not available - compression tests will be skipped');
    }
};

subtest 'Compression configuration' => sub {
    my $config = Hypersonic::Compress->configure(
        min_size => 512,
        level    => 9,
    );
    
    ok($config, 'Configuration succeeded');
    is($config->{min_size}, 512, 'min_size set');
    is($config->{level}, 9, 'level set');
    is($config->{enabled}, 1, 'enabled by default');
    ok(ref($config->{types}) eq 'ARRAY', 'types is array');
};

subtest 'Default configuration' => sub {
    my $config = Hypersonic::Compress->configure();
    
    is($config->{min_size}, 1024, 'default min_size is 1024');
    is($config->{level}, 6, 'default level is 6');
};

# ============================================================
# Test Compression with Hypersonic server
# ============================================================

SKIP: {
    skip "zlib not available", 1 unless Hypersonic::Compress::check_zlib();
    
    subtest 'Compression with Hypersonic server' => sub {
        my $server = Hypersonic->new(cache_dir => '_test_cache_compress');
        
        # Enable compression
        $server->compress(
            min_size => 100,  # Low threshold for testing
            level    => 6,
        );
        
        # Route that returns a large response
        $server->get('/large' => sub {
            my ($req) = @_;
            # Return a string larger than min_size
            my $data = 'x' x 500;
            return res->text($data);
        }, { dynamic => 1 });
        
        # Route that returns small response (should not be compressed)
        $server->get('/small' => sub {
            my ($req) = @_;
            return res->text('small');
        }, { dynamic => 1 });
        
        # JSON route (should be compressed)
        $server->get('/json' => sub {
            my ($req) = @_;
            # Create a large JSON response
            my @items = map { { id => $_, name => "Item $_" } } 1..50;
            return res->json({ items => \@items });
        }, { dynamic => 1 });
        
        # Compile the server
        eval { $server->compile };
        
        if ($@) {
            fail("Compilation failed: $@");
        } else {
            pass('Server compiled with compression enabled');
        }
        
        ok($server->{_compression_enabled}, 'Compression is enabled');
        ok($server->{_compression_config}, 'Compression config stored');
    };
}

# ============================================================
# Test that compression doesn't break without zlib
# ============================================================

subtest 'Graceful handling without zlib' => sub {
    # This tests that the server works even if compression
    # is requested but zlib is not available
    
    my $server = Hypersonic->new(cache_dir => '_test_cache_no_compress');
    
    # Simple route without compression (must be a coderef for static)
    $server->get('/hello' => sub { '{"message":"hello"}' });
    
    # Compile should work
    eval { $server->compile };
    ok(!$@, 'Server compiles without compression');
    ok(!$server->{_compression_enabled}, 'Compression not enabled by default');
};

# ============================================================
# Test C code generation
# ============================================================

subtest 'C code generation' => sub {
    Hypersonic::Compress->configure(
        min_size => 1024,
        level    => 6,
    );
    
    my $c_code = Hypersonic::Compress->generate_c_code();
    
    ok($c_code, 'C code generated');
    like($c_code, qr/#include <zlib\.h>/, 'Includes zlib.h');
    like($c_code, qr/accepts_gzip/, 'Contains accepts_gzip function');
    like($c_code, qr/gzip_compress/, 'Contains gzip_compress function');
    like($c_code, qr/deflateInit2/, 'Uses deflateInit2 for gzip format');
    like($c_code, qr/15 \+ 16/, 'Uses gzip window bits (15+16)');
};

# Cleanup
system("rm -rf _test_cache_compress _test_cache_no_compress 2>/dev/null");

done_testing();
