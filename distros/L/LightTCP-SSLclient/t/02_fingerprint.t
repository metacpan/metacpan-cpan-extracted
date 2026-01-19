use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Path qw(rmtree);

use lib '../lib';
use LightTCP::SSLclient qw(EREQUEST);

my $tempdir = tempdir(CLEANUP => 1);

subtest 'fingerprint_read with no file' => sub {
    my $client = LightTCP::SSLclient->new();
    my $fp = $client->fingerprint_read($tempdir, 'nonexistent.test', 443);
    is($fp, '', 'returns empty string for non-existent file');
};

subtest 'fingerprint_read with existing file' => sub {
    my $client = LightTCP::SSLclient->new();

    my $test_fp = 'AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD:EE:FF:00:11:22:33';
    my $file = "$tempdir/test.example.com.443";
    open my $fh, '>', $file or die "Cannot create test file: $!";
    print $fh "$test_fp\n";
    close $fh;

    my $fp = $client->fingerprint_read($tempdir, 'test.example.com', 443);
    is($fp, $test_fp, 'fingerprint read correctly');
};

subtest 'fingerprint_save to new file' => sub {
    my $client = LightTCP::SSLclient->new();
    my $test_fp = '11:22:33:44:55:66:77:88:99:AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA';

    my ($err, $msg, $debug, $code) = $client->fingerprint_save($tempdir, 'save.test', 443, $test_fp, 0);
    is($err, 1, 'returns 1 on success');
    is($code, 0, 'error code is 0 on success');

    my $new_file = "$tempdir/save.test.443.new";
    ok(-f $new_file, '.new file created');

    my $fp = $client->fingerprint_read($tempdir, 'save.test', 443);
    is($fp, '', 'original fingerprint not updated yet');
};

subtest 'fingerprint_save permanently' => sub {
    my $client = LightTCP::SSLclient->new();
    my $test_fp = 'AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD:EE:FF:00:11:22:33';

    my ($err, $msg, $debug, $code) = $client->fingerprint_save($tempdir, 'perm.test', 443, $test_fp, 1);
    is($err, 1, 'returns 1 on success');
    is($code, 0, 'error code is 0 on success');

    my $file = "$tempdir/perm.test.443";
    ok(-f $file, 'permanent file created');

    my $fp = $client->fingerprint_read($tempdir, 'perm.test', 443);
    is($fp, $test_fp, 'fingerprint saved correctly');

    ok(!-f "$file.new", '.new file not created for permanent save');
};

subtest 'fingerprint_save with errors' => sub {
    my $client = LightTCP::SSLclient->new();
    my $tempdir = '/nonexistent/directory/that/does/not/exist';

    my ($err, $msg, $debug, $code) = $client->fingerprint_save($tempdir, 'error.test', 443, 'test', 1);
    is($err, 1, 'returns 1 even with errors (legacy behavior)');
    is($code, EREQUEST, 'error code is EREQUEST');
    ok(@$msg > 0, 'error message returned');
};

subtest 'fingerprint_save with verbose' => sub {
    my $client = LightTCP::SSLclient->new(verbose => 1);
    my $test_fp = '11:22:33:44:55:66:77:88:99:AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA';

    my ($err, $msg, $debug, $code) = $client->fingerprint_save($tempdir, 'verbose.test', 443, $test_fp, 0);
    is($err, 1, 'returns 1 on success');
    is($code, 0, 'error code is 0 on success');
    ok(@$debug > 0, 'debug messages present when verbose is true');
};

done_testing();
