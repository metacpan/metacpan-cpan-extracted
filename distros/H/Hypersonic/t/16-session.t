#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

# Clean up any cached XS modules for clean testing
system("rm -rf _hypersonic_* _test_cache_*");

BEGIN {
    use_ok('Hypersonic');
    use_ok('Hypersonic::Request');
    use_ok('Hypersonic::Session');
    use_ok('Hypersonic::Response', 'res');
}

# ============================================================
# Test Session module internals
# ============================================================

subtest 'Session ID generation' => sub {
    my $id1 = Hypersonic::Session::_generate_session_id();
    my $id2 = Hypersonic::Session::_generate_session_id();
    
    ok($id1, 'Generated session ID 1');
    ok($id2, 'Generated session ID 2');
    ok($id1 ne $id2, 'Session IDs are unique');
    like($id1, qr/^[a-f0-9]{32}$/, 'Session ID format is correct (32 hex chars)');
    like($id2, qr/^[a-f0-9]{32}$/, 'Session ID format is correct (32 hex chars)');
};

subtest 'Session signing and verification' => sub {
    my $secret = 'test-secret-key-minimum-length';
    my $session_id = 'a' x 32;
    
    my $signed = Hypersonic::Session::_sign($session_id, $secret);
    ok($signed, 'Signed session ID');
    like($signed, qr/^$session_id\.[a-f0-9]{16}$/, 'Signed format is session_id.signature');
    
    # Verify with correct secret
    my $verified = Hypersonic::Session::_verify($signed, $secret);
    is($verified, $session_id, 'Verification with correct secret succeeds');
    
    # Verify with wrong secret
    my $wrong_verified = Hypersonic::Session::_verify($signed, 'wrong-secret-key-very-long');
    is($wrong_verified, undef, 'Verification with wrong secret fails');
    
    # Tampered signature
    my $tampered = $session_id . '.0000000000000000';
    my $tampered_verified = Hypersonic::Session::_verify($tampered, $secret);
    is($tampered_verified, undef, 'Verification of tampered signature fails');
    
    # Invalid format
    my $invalid = 'not-a-valid-signed-cookie';
    my $invalid_verified = Hypersonic::Session::_verify($invalid, $secret);
    is($invalid_verified, undef, 'Verification of invalid format fails');
};

subtest 'Session configuration' => sub {
    # Should fail without secret
    eval { Hypersonic::Session->configure() };
    like($@, qr/secret is required/, 'Requires secret');
    
    # Should fail with short secret
    eval { Hypersonic::Session->configure(secret => 'short') };
    like($@, qr/secret is required/, 'Requires 16+ char secret');
    
    # Clear store for fresh test
    Hypersonic::Session::_clear_store();
    
    # Should succeed with proper config
    my $config = Hypersonic::Session->configure(
        secret      => 'my-super-secret-key-32-chars-min',
        cookie_name => 'mysession',
        max_age     => 7200,
    );
    
    ok($config, 'Configuration succeeded');
    is($config->{cookie_name}, 'mysession', 'Cookie name set');
    is($config->{max_age}, 7200, 'Max age set');
    is($config->{httponly}, 1, 'HttpOnly default');
    is($config->{samesite}, 'Lax', 'SameSite default');
};

# ============================================================
# Test Request session methods
# ============================================================

subtest 'Request session methods' => sub {
    # Create a mock request array
    my $req = bless [], 'Hypersonic::Request';
    
    # Initialize session data
    $req->[12] = { user => 'alice', count => 5 };  # SLOT_SESSION
    $req->[13] = 'abc123def456abc123def456abc12345';  # SLOT_SESSION_ID
    $req->[14] = 0;  # SLOT_SESSION_MODIFIED
    
    # Test getter
    is($req->session('user'), 'alice', 'Session getter works');
    is($req->session('count'), 5, 'Session getter for number works');
    is($req->session('nonexistent'), undef, 'Session getter returns undef for missing');
    
    # Test setter
    $req->session('logged_in', 1);
    is($req->session('logged_in'), 1, 'Session setter works');
    is($req->[14], 1, 'Session marked as modified');
    
    # Test session_data
    my $data = $req->session_data;
    is_deeply($data, { user => 'alice', count => 5, logged_in => 1 }, 'session_data returns all data');
    
    # Test session_clear
    $req->session_clear;
    is_deeply($req->[12], {}, 'session_clear empties session');
    is($req->[14], 1, 'Session marked as modified after clear');
};

# ============================================================
# Test Session with Hypersonic server
# ============================================================

subtest 'Session middleware with Hypersonic' => sub {
    # Clear store for fresh test
    Hypersonic::Session::_clear_store();
    
    my $server = Hypersonic->new(cache_dir => '_test_cache_session');
    
    # Enable sessions
    $server->session_config(
        secret => 'test-secret-for-hypersonic-sessions',
        cookie_name => 'hsid',
        max_age => 3600,
    );
    
    # Set session value route
    $server->post('/login' => sub {
        my ($req) = @_;
        $req->session('user', 'bob');
        $req->session('logged_in', 1);
        return res->json({ success => 1 });
    }, { dynamic => 1, parse_json => 1 });
    
    # Get session value route
    $server->get('/profile' => sub {
        my ($req) = @_;
        my $user = $req->session('user') // 'guest';
        my $logged_in = $req->session('logged_in') // 0;
        return res->json({ user => $user, logged_in => $logged_in });
    }, { dynamic => 1 });
    
    # Logout route
    $server->post('/logout' => sub {
        my ($req) = @_;
        $req->session_clear;
        return res->json({ logged_out => 1 });
    }, { dynamic => 1 });
    
    # Session regeneration route (security best practice after login)
    $server->post('/regenerate' => sub {
        my ($req) = @_;
        my $new_id = $req->session_regenerate;
        return res->json({ regenerated => 1 });
    }, { dynamic => 1 });
    
    # Compile the server
    $server->compile;
    
    # Check store size starts at 0
    is(Hypersonic::Session::_store_size(), 0, 'Store starts empty');
    
    ok($server, 'Server compiled with sessions enabled');
};

# ============================================================
# Test session middleware functions directly
# ============================================================

subtest 'Session middleware functions' => sub {
    # Clear store for fresh test
    Hypersonic::Session::_clear_store();
    
    # Configure fresh session
    Hypersonic::Session->configure(
        secret => 'direct-middleware-test-secret-key',
        cookie_name => 'sid',
    );
    
    my $before_mw = Hypersonic::Session::before_middleware();
    my $after_mw = Hypersonic::Session::after_middleware();
    
    ok(ref($before_mw) eq 'CODE', 'before_middleware returns code ref');
    ok(ref($after_mw) eq 'CODE', 'after_middleware returns code ref');
    
    # Create mock request (new session - no cookie)
    my $req = bless [], 'Hypersonic::Request';
    $req->[7] = {};  # SLOT_COOKIES (empty - no session cookie)
    
    # Run before middleware - should create new session
    $before_mw->($req);
    
    ok($req->[12], 'Session data created');
    ok($req->[13], 'Session ID assigned');
    like($req->[13], qr/^[a-f0-9]{32}$/, 'Session ID format correct');
    ok(exists $req->[12]->{_created}, 'Session has _created timestamp');
    ok(exists $req->[12]->{_new}, 'Session marked as new');
    
    # Set session data
    $req->[12]->{user} = 'charlie';
    $req->[14] = 1;  # Mark modified
    
    # Create mock response
    require Hypersonic::Response;
    my $res = Hypersonic::Response->new->status(200);
    
    # Run after middleware - should set cookie
    my $final_res = $after_mw->($req, $res);
    
    ok($final_res, 'After middleware returned response');
    
    # Verify session in store
    is(Hypersonic::Session::_store_size(), 1, 'Session stored');
    
    # Get the session ID for next request
    my $session_id = $req->[13];
    
    # Simulate second request with session cookie
    my $req2 = bless [], 'Hypersonic::Request';
    my $signed_cookie = Hypersonic::Session::_sign($session_id, 'direct-middleware-test-secret-key');
    $req2->[7] = { sid => $signed_cookie };  # SLOT_COOKIES
    
    # Run before middleware - should load existing session
    $before_mw->($req2);
    
    is($req2->[13], $session_id, 'Same session ID loaded');
    is($req2->[12]->{user}, 'charlie', 'Session data persisted');
};

# ============================================================
# Test session cleanup
# ============================================================

subtest 'Session cleanup' => sub {
    # Clear store first
    Hypersonic::Session::_clear_store();
    
    # Configure with short max_age
    Hypersonic::Session->configure(
        secret => 'cleanup-test-secret-key-long',
        max_age => 1,  # 1 second
    );
    
    # Manually add expired session to store
    my $old_session_id = 'expired' . ('0' x 25);
    
    # Create a session that's "old"
    my $before_mw = Hypersonic::Session::before_middleware();
    my $req = bless [], 'Hypersonic::Request';
    $req->[7] = {};
    $before_mw->($req);
    
    # Manually set old timestamp
    $req->[12]->{_created} = time() - 100;  # Created 100 seconds ago
    
    # Run after middleware to save
    my $res = Hypersonic::Response->new->status(200);
    my $after_mw = Hypersonic::Session::after_middleware();
    $after_mw->($req, $res);
    
    is(Hypersonic::Session::_store_size(), 1, 'One session in store before cleanup');
    
    # Run cleanup
    Hypersonic::Session::cleanup(10);  # Expire anything older than 10 seconds
    
    is(Hypersonic::Session::_store_size(), 0, 'Session cleaned up');
};

# ============================================================
# Test session regeneration
# ============================================================

subtest 'Session regeneration' => sub {
    Hypersonic::Session::_clear_store();
    
    Hypersonic::Session->configure(
        secret => 'regeneration-test-secret-long',
    );
    
    # Create initial session
    my $before_mw = Hypersonic::Session::before_middleware();
    my $req = bless [], 'Hypersonic::Request';
    $req->[7] = {};
    $before_mw->($req);
    
    my $original_id = $req->[13];
    $req->[12]->{user} = 'david';
    
    # Regenerate session ID
    my $new_id = $req->session_regenerate;
    
    ok($new_id, 'New session ID generated');
    isnt($new_id, $original_id, 'Session ID changed');
    is($req->[12]->{user}, 'david', 'Session data preserved');
    is($req->[14], 1, 'Session marked modified');
    is($req->[13], $new_id, 'Request has new session ID');
};

# Cleanup
system("rm -rf _test_cache_session");

done_testing();
