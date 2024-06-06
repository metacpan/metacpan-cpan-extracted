#!perl
use 5.016;
use strict;
use warnings;
use Test::More;
use Extism ':all';
use JSON::PP qw(encode_json decode_json);
use File::Temp qw(tempfile);
use Devel::Peek qw(Dump);
plan tests => 40;

# ...
ok(Extism::version());

# test custom log
{
    my $kid = fork();
    if (defined $kid) {
        if ($kid == 0) {
            my $rc = 0;
            Extism::log_custom("trace") or $rc = 1;
            my $log_text;
            my $tempfunc = sub {
                $log_text .= $_[0];
            };
            Extism::Plugin->new('');
            Extism::log_drain($tempfunc);
            $log_text or $rc = 1;
            POSIX::_exit($rc);
        }
        waitpid($kid, 0);
        ok(($? >> 8) == 0);
    }
}

# test failing plugin new in scalar and list context
{
    my $notplugin = Extism::Plugin->new('');
    ok(!defined $notplugin);
}
{
    my ($notplugin, $error) = Extism::Plugin->new('');
    ok(!defined $notplugin);
    ok($error);
}

# test succeeding plugin new in scalar and list context
# also text various Plugin:: functions
my $wasm = do { local(@ARGV, $/) = 'count_vowels.wasm'; <> };
{
    my $plugin = Extism::Plugin->new($wasm, {wasi => 1});
    ok($plugin);
    my $output = $plugin->call('count_vowels', "this is a test");
    ok($output);
    my $outputhash = decode_json($output);
    ok($outputhash->{count} == 4);
    ok(length($plugin->id) == 16);
    ok($plugin->function_exists('count_vowels'));
    ok(!$plugin->function_exists('does_not_exist'));
    ok($plugin->config({aaa => 'bbb'}));
    ok($plugin->config({aaa => undef}));
    my $ch = $plugin->cancel_handle();
    ok($ch && $$ch);
    ok($ch->cancel());
    ok($plugin->reset());
}
{
    my ($plugin, $error) = Extism::Plugin->new($wasm, {wasi => 1});
    ok($plugin);
    my ($output) = $plugin->call('count_vowels', "this is a test");
    ok($output);
    my $outputhash = decode_json($output);
    ok($outputhash->{count} == 4);
}

# test log_file and call on failing plugin
{
    my ($error_fh, $filename) = tempfile();
    Extism::log_file($filename, "error");
    my $failwasm = do { local(@ARGV, $/) = 'fail.wasm'; <> };
    my $failplugin = Extism::Plugin->new($failwasm, {wasi => 1});
    my $failed = $failplugin->call('run_test', "");
    ok(!$failed);
    my $rc = read($error_fh, my $filler, 1);
    ok($rc == 1);
    unlink($filename);
    Extism::log_file("/dev/stdout", "error");
    my ($res, $rca, $info) = $failplugin->call('run_test', "");
    ok($rca == 1);
    is($info, 'Some error message');
}

# test basic host functions
my $voidfunction = Extism::Function->new("hello_void", [], [], sub {
    print "hello_void\n";
    return;
});
ok($voidfunction);
my $paramsfunction = Extism::Function->new("hello_params", [Extism_F64, Extism_I32, Extism_F32, Extism_I64], [Extism_I64], sub {
    print "hello_params: ".join(' ', @_) . "\n";
    return 18446744073709551615;
});
ok($paramsfunction);
my $hostwasm = do { local(@ARGV, $/) = 'host.wasm'; <> };
my $fplugin = Extism::Plugin->new($hostwasm, {functions => [$voidfunction, $paramsfunction], wasi => 1});
ok($fplugin);
ok(defined $fplugin->call('call_hello_void'));
ok(defined $fplugin->call('call_hello_params'));

# test more advanced host functions
my $count_vowels_kv = encode_json({
    wasm => [
        {
            #url => "https://github.com/extism/plugins/releases/latest/download/count_vowels_kvstore.wasm"
            path => 'count_vowels_kvstore.wasm',
        }
    ],
});

# ... with low level api
my @lowlevel;
{
    my %kv_store;
    my $kv_read = Extism::Function->new("kv_read", [Extism_I64], [Extism_I64], sub {
        my ($key_ptr) = @_;
        my $key = Extism::CurrentPlugin::memory_load_from_handle($key_ptr);
        if (!exists $kv_store{$key}) {
            return Extism::CurrentPlugin::memory_alloc_and_store("\x00" x 4);
        } else {
            return Extism::CurrentPlugin::memory_alloc_and_store($kv_store{$key});
        }
    });
    ok($kv_read);
    my $kv_write = Extism::Function->new("kv_write", [Extism_I64, Extism_I64], [], sub {
        my ($key_ptr, $value_ptr) = @_;
        my $key = Extism::CurrentPlugin::memory_load_from_handle($key_ptr);
        my $value = Extism::CurrentPlugin::memory_load_from_handle($value_ptr);
        $kv_store{$key} = $value;
        return;
    });
    ok($kv_write);
    my $fplugin = Extism::Plugin->new($count_vowels_kv, {functions => [$kv_read, $kv_write], wasi => 1});
    ok($fplugin);
    my $hello = "Hello, World!";
    $lowlevel[0] = $fplugin->call("count_vowels", $hello);
    $lowlevel[1] = $fplugin->call("count_vowels", $hello);
}

# ... with high level api
my @highlevel;
{
    my %kv_store;
    my $kv_read = Extism::Function->new("kv_read", [Extism_String], [Extism_String], sub {
        my ($key) = @_;
        if (!exists $kv_store{$key}) {
            return "\x00" x 4;
        } else {
            return $kv_store{$key};
        }
    });
    ok($kv_read);
    my $kv_write = Extism::Function->new("kv_write", [Extism_String, Extism_String], [], sub {
        my ($key, $value) = @_;
        $kv_store{$key} = $value;
        return;
    });
    ok($kv_write);
    my $fplugin = Extism::Plugin->new($count_vowels_kv, {functions => [$kv_read, $kv_write], wasi => 1});
    ok($fplugin);
    my $hello = "Hello, World!";
    $highlevel[0] = $fplugin->call("count_vowels", $hello);
    $highlevel[1] = $fplugin->call("count_vowels", $hello);
}
my @decoded = map {decode_json $_} @highlevel;
ok($decoded[0]{count} == 3);
ok($decoded[0]{count} == $decoded[1]{count});
ok($decoded[0]{total} == 3);
ok($decoded[1]{total} == 6);

# Verify both sets of results are the same
is($highlevel[0], $lowlevel[0]);
is($highlevel[1], $lowlevel[1]);
