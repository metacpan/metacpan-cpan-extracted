#!/usr/bin/env perl
use strict;
use warnings;
use File::Temp qw(tempdir);
use Fcntl qw(:flock);
use Test::More;
use Test::More import => [qw(subtest)];

BEGIN {
    use FindBin;
    use lib "$FindBin::Bin/../lib";
    require "LightTCP/Server.pm";
}

my $upload_dir = tempdir(CLEANUP => 1);

my %config = (
    server_addr      => '0.0.0.0:8881',
    upload_dir       => $upload_dir,
    upload_max_size  => 1024 * 1024,
    rate_limit_enabled => 1,
    rate_limit_requests => 10,
    rate_limit_window => 60,
    rate_limit_block_duration => 300,
    verbose          => 0,
);

subtest 'Config validation for upload settings' => sub {
    my %valid_config = %config;
    my $server = LightTCP::Server->new(%valid_config);
    ok($server, 'Server created with valid upload config');
    
    is($server->upload_dir, $upload_dir, 'upload_dir attribute set correctly');
    is($server->upload_max_size, 1024 * 1024, 'upload_max_size attribute set correctly');
    ok($server->rate_limit_enabled, 'rate_limit_enabled is true');
    is($server->rate_limit_requests, 10, 'rate_limit_requests is 10');
};

subtest 'Config validation for missing upload_dir' => sub {
    my %invalid_config = %config;
    delete $invalid_config{upload_dir};
    
    my $server = LightTCP::Server->new(%invalid_config);
    ok($server, 'Server created with default upload_dir');
    is($server->upload_dir, '/var/www/uploads', 'Default upload_dir is set');
};

subtest 'Config validation for empty upload_dir' => sub {
    my %invalid_config = %config;
    $invalid_config{upload_dir} = '';
    
    eval {
        LightTCP::Server->new(%invalid_config);
    };
    like($@, qr/upload_dir must be a non-empty string/, 'Dies with empty upload_dir');
};

subtest 'Config validation for invalid upload_max_size' => sub {
    my %invalid_config = %config;
    $invalid_config{upload_max_size} = -1;
    
    eval {
        LightTCP::Server->new(%invalid_config);
    };
    like($@, qr/upload_max_size must be positive/, 'Dies with negative upload_max_size');
};

subtest 'Config validation for rate limit settings' => sub {
    my %valid_config = %config;
    $valid_config{rate_limit_enabled} = 1;
    $valid_config{rate_limit_requests} = 50;
    $valid_config{rate_limit_window} = 60;
    $valid_config{rate_limit_block_duration} = 300;
    
    my $server = LightTCP::Server->new(%valid_config);
    ok($server, 'Server created with valid rate limit config');
    
    is($server->rate_limit_requests, 50, 'rate_limit_requests is 50');
    is($server->rate_limit_window, 60, 'rate_limit_window is 60');
    is($server->rate_limit_block_duration, 300, 'rate_limit_block_duration is 300');
};

subtest 'Config validation for invalid rate_limit_requests' => sub {
    my %invalid_config = %config;
    $invalid_config{rate_limit_requests} = 0;
    
    eval {
        LightTCP::Server->new(%invalid_config);
    };
    like($@, qr/rate_limit_requests must be positive/, 'Dies with zero rate_limit_requests');
};

subtest 'Config validation for invalid rate_limit_window' => sub {
    my %invalid_config = %config;
    $invalid_config{rate_limit_window} = -10;
    
    eval {
        LightTCP::Server->new(%invalid_config);
    };
    like($@, qr/rate_limit_window must be positive/, 'Dies with negative rate_limit_window');
};

subtest 'Sanitize filename removes dangerous patterns' => sub {
    my $server = LightTCP::Server->new(%config);
    
    is($server->_sanitize_filename('../../etc/passwd'), 'etcpasswd', 'Blocks path traversal');
    is($server->_sanitize_filename('file../../../secret'), 'filesecret', 'Blocks trailing path traversal');
    is($server->_sanitize_filename('test/../../config'), 'testconfig', 'Blocks embedded path traversal');
    is($server->_sanitize_filename('normal_file.txt'), 'normal_file.txt', 'Keeps normal filenames');
    is($server->_sanitize_filename('file with spaces.txt'), 'file_with_spaces.txt', 'Replaces spaces with underscores');
    is($server->_sanitize_filename('FILE.TXT'), 'FILE.TXT', 'Preserves uppercase');
    is($server->_sanitize_filename(''), 'unnamed_file', 'Empty filename becomes unnamed_file');
    is($server->_sanitize_filename(undef), 'unnamed_file', 'Undefined filename becomes unnamed_file');
};

subtest 'Extract boundary from Content-Type' => sub {
    my $server = LightTCP::Server->new(%config);
    
    is($server->_extract_boundary('multipart/form-data; boundary=----WebKitFormBoundary7MA4YWxkTrZu0gW'),
       '----WebKitFormBoundary7MA4YWxkTrZu0gW', 'Extracts boundary correctly');
    is($server->_extract_boundary('multipart/form-data; boundary=abc123'), 'abc123', 'Extracts simple boundary');
    is($server->_extract_boundary('multipart/form-data'), undef, 'Returns undef without boundary');
};

subtest 'Split multipart headers' => sub {
    my $server = LightTCP::Server->new(%config);
    
    my $part_data = <<"EOF";
Content-Disposition: form-data; name="file"; filename="test.txt"
Content-Type: text/plain

EOF
    my ($headers, $body) = $server->_split_part_headers($part_data);
    
    is($headers->{'Content-Disposition'}, 'form-data; name="file"; filename="test.txt"', 'Parses Content-Disposition');
    is($headers->{'Content-Type'}, 'text/plain', 'Parses Content-Type');
    is($body, '', 'Body is empty for headers-only part');
};

subtest 'Validate upload type' => sub {
    my $server = LightTCP::Server->new(%config);
    $server->upload_allowed_types([qw(image/jpeg image/png application/pdf)]);
    
    ok($server->_validate_upload_type('image/jpeg'), 'Accepts JPEG');
    ok($server->_validate_upload_type('image/png'), 'Accepts PNG');
    ok($server->_validate_upload_type('application/pdf'), 'Accepts PDF');
    ok(!$server->_validate_upload_type('text/html'), 'Rejects HTML');
    ok(!$server->_validate_upload_type('application/x-executable'), 'Rejects executable');
};

subtest 'Validate upload type with no restrictions' => sub {
    my $server = LightTCP::Server->new(%config);
    $server->upload_allowed_types([]);
    
    ok($server->_validate_upload_type('any/type'), 'Accepts any type when allowed list is empty');
    ok($server->_validate_upload_type('application/octet-stream'), 'Accepts octet-stream');
    ok($server->_validate_upload_type(undef), 'Accepts undefined type');
    ok($server->_validate_upload_type(''), 'Accepts empty type');
};

subtest 'Rate limit store shared hash' => sub {
    my $server = LightTCP::Server->new(%config);
    
    my $data = $server->_rate_limit_data;
    ok(defined $data, 'Rate limit data exists');
    ok(ref($data) eq 'HASH', 'Rate limit data is a hashref');
    
    my $lock = $server->_rate_limit_lock;
    ok(defined $lock, 'Rate limit lock exists');
    ok(ref($lock) eq 'SCALAR', 'Rate limit lock is a scalar ref');
};

subtest 'Whitelist contains defaults' => sub {
    my $server = LightTCP::Server->new(%config);
    
    my @whitelist = @{$server->rate_limit_whitelist};
    ok(scalar(grep { $_ eq '127.0.0.1' } @whitelist), 'Contains 127.0.0.1');
    ok(scalar(grep { $_ eq '::1' } @whitelist), 'Contains ::1');
    ok(scalar(grep { $_ eq 'localhost' } @whitelist), 'Contains localhost');
};

subtest 'func_upload callback' => sub {
    my %test_config = %config;
    my @captured_uploads;
    $test_config{func_upload} = sub {
        push @captured_uploads, \@_;
    };
    
    my $server = LightTCP::Server->new(%test_config);
    ok(defined $server->func_upload, 'func_upload attribute is defined');
    ok(ref($server->func_upload) eq 'CODE', 'func_upload is a code ref');
};

subtest 'Upload directory is created on first save' => sub {
    my $new_upload_dir = tempdir(CLEANUP => 1);
    my $subdir = "$new_upload_dir/new_subdir";
    
    my %test_config = %config;
    $test_config{upload_dir} = $subdir;
    
    ok(!-d $subdir, 'Directory does not exist yet');
    
    my $server = LightTCP::Server->new(%test_config);
    
    ok(!-d $subdir, 'Directory not created at server init');
    
    $server->_save_upload_file('test.txt', 'content');
    
    ok(-d $subdir, 'Directory created on first save');
};

subtest 'Upload form generation' => sub {
    my $server = LightTCP::Server->new(%config);
    
    my $form = <<'HTML';
<!DOCTYPE html>
<html>
<head>
    <title>File Upload</title>
    <style>
        body { font-family: Arial, sans-serif; max-width: 600px; margin: 50px auto; padding: 20px; }
        h1 { color: #333; }
        .info { background: #f0f0f0; padding: 10px; margin: 10px 0; border-radius: 5px; }
        .error { color: red; margin: 10px 0; }
        button { background: #4CAF50; color: white; padding: 10px 20px; border: none; cursor: pointer; }
        button:hover { background: #45a049; }
    </style>
</head>
<body>
    <h1>File Upload</h1>
    <div class="info">
        <strong>Maximum file size:</strong> 1MB<br>
        <strong>Allowed types:</strong> 
    </div>
    <form action="/upload" method="POST" enctype="multipart/form-data">
        <p><input type="file" name="file" required></p>
        <p><button type="submit">Upload File</button></p>
    </form>
</body>
</html>
HTML
    
    like($form, qr/<form/, 'Contains form element');
    like($form, qr/enctype="multipart\/form-data"/, 'Has multipart encoding');
    like($form, qr/name="file"/, 'Has file input');
    like($form, qr/<button type="submit"/, 'Has submit button');
    like($form, qr/Maximum file size/, 'Shows max size');
    like($form, qr/Allowed types:/, 'Shows allowed types');
};

subtest 'Save upload file with sanitization' => sub {
    my $server = LightTCP::Server->new(%config);
    
    my ($success, $path, $msg, $sanitized) = $server->_save_upload_file(
        'test.txt',
        'Hello, World!',
    );
    
    ok($success, 'Save succeeded');
    like($path, qr/\.txt$/, 'File has txt extension');
    
    ok(-f "$upload_dir/test.txt", 'File exists');
    
    open(my $fh, '<', "$upload_dir/test.txt");
    my $saved_content = do { local $/; <$fh> };
    close($fh);
    is($saved_content, 'Hello, World!', 'Content was saved correctly');
};

subtest 'Save upload file with dangerous name' => sub {
    my $server = LightTCP::Server->new(%config);
    
    my ($success, $path, $msg) = $server->_save_upload_file(
        '../../../etc/passwd',
        'malicious content',
    );
    
    ok($success, 'Save succeeded with sanitization');
    unlike($path, qr/\.\./, 'Path traversal .. removed from path');
    is($msg, $path, 'Third return value is the path');
    like($path, qr/etcpasswd$/, 'Filename is sanitized correctly');
};

subtest 'Upload size limit enforcement in save' => sub {
    my %small_config = %config;
    $small_config{upload_max_size} = 10;
    
    my $server = LightTCP::Server->new(%small_config);
    
    my ($success, $msg) = $server->_save_upload_file(
        'test.txt',
        'This is more than ten bytes!!!',
    );
    
    ok(!$success, 'Save fails when file too large');
    like($msg, qr/File exceeds maximum size/i, 'Reports size limit error');
};

subtest 'Rate limit blocking' => sub {
    my %test_config = %config;
    $test_config{rate_limit_requests} = 2;
    $test_config{rate_limit_window} = 1;
    $test_config{rate_limit_block_duration} = 1;
    
    my $server = LightTCP::Server->new(%test_config);
    
    my $test_ip = '192.168.1.100';
    
    ok(!$server->_is_blocked($test_ip), 'IP not blocked initially');
    
    my $result1 = $server->_check_rate_limit($test_ip);
    my $result2 = $server->_check_rate_limit($test_ip);
    my $result3 = $server->_check_rate_limit($test_ip);
    
    ok($result1, 'First request allowed');
    ok($result2, 'Second request allowed');
    ok(!$result3, 'Third request exceeds limit');
    
    ok(!$server->_is_blocked($test_ip), 'IP not blocked yet (blocking only happens in request handler)');
    
    $server->_block_ip($test_ip, 1);
    ok($server->_is_blocked($test_ip), 'IP blocked after _block_ip called');
    
    sleep(2);
    
    ok(!$server->_is_blocked($test_ip), 'IP unblocked after duration');
};

subtest 'Rate limit whitelist bypass' => sub {
    my %test_config = %config;
    $test_config{rate_limit_requests} = 1;
    $test_config{rate_limit_window} = 60;
    $test_config{rate_limit_block_duration} = 300;
    
    my $server = LightTCP::Server->new(%test_config);
    
    my $result = $server->_check_rate_limit('127.0.0.1');
    ok($result, 'Whitelisted IP not rate limited (returns true)');
    
    $result = $server->_check_rate_limit('192.168.1.1');
    ok($result, 'First request from non-whiteleted IP is allowed');
    
    $result = $server->_check_rate_limit('192.168.1.1');
    ok(!$result, 'Second request from non-whiteleted IP exceeds limit');
};

subtest 'Rate limit count increases' => sub {
    my %test_config = %config;
    $test_config{rate_limit_requests} = 3;
    $test_config{rate_limit_window} = 60;
    
    my $server = LightTCP::Server->new(%test_config);
    
    my $test_ip = '10.0.0.1';
    
    my $result1 = $server->_check_rate_limit($test_ip);
    my $result2 = $server->_check_rate_limit($test_ip);
    my $result3 = $server->_check_rate_limit($test_ip);
    
    ok($result1, 'First request allowed');
    ok($result2, 'Second request allowed');
    ok($result3, 'Third request allowed');
    
    my $data = $server->_rate_limit_data;
    my $count = $data->{$test_ip}{count};
    is($count, 3, 'All 3 requests counted');
};

done_testing();
