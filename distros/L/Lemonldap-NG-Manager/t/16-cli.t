use warnings;
use File::Copy;
use File::Temp 'tempdir';
use Test::More;
use Test::Output;
use JSON;
use strict;
require 't/test-lib.pm';

my $tests = 23;

use_ok('Lemonldap::NG::Common::Cli');
use_ok('Lemonldap::NG::Manager::Cli');
&cleanConfFiles;

sub llclient {
    return Lemonldap::NG::Manager::Cli->new(
        iniFile => "$main::tmpdir/lemonldap-ng.ini" );
}

sub llcommonClient {
    return Lemonldap::NG::Common::Cli->new(
        iniFile => "$main::tmpdir/lemonldap-ng.ini" );
}

my @cmd;
my $res;

# Test 'set' command
@cmd = qw(-yes 1 set notification 1);
combined_like( sub { llclient->run(@cmd) }, qr/Saved under/, '"addKey" OK' );

# Test 'get' command
@cmd = qw(get notification);
$res = Test::Output::stdout_from( sub { llclient->run(@cmd) } );
ok( $res =~ /^notification\s+=\s+1$/, '"get notification" OK' )
  or diag " $res";

# Test 'addKey' command
@cmd = qw(-yes 1 addKey locationRules/test1.example.com ^/reject deny);
combined_like( sub { llclient->run(@cmd) }, qr/Saved under/, '"addKey" OK' );

# Test 'addKey' command with negative number, to make sure the option parser
# does not interfere (#3495)
@cmd = qw(-yes 1 addKey vhostOptions/test1.example.com vhostServiceTokenTTL -1);
combined_like( sub { llclient->run(@cmd) }, qr/Saved under/, '"addKey" OK' );

# Test 'delKey' command
@cmd = qw(-yes 1 delKey locationRules/test1.example.com ^/reject);
combined_unlike(
    sub { llclient->run(@cmd) },
    qr#'\^/reject' => 'deny'#s,
    '"delKey" OK'
);

# Test 'get' command with key/subkey
@cmd = qw(get locationRules/test1.example.com/default);
$res = Test::Output::stdout_from( sub { llclient->run(@cmd) } );
ok( $res =~ m#accept#, '"get key/subkey" OK' )
  or diag "$res";

# Test 'set' command with key/subkey
@cmd = qw(-yes 1 set locationRules/test1.example.com/default deny);
combined_like( sub { llclient->run(@cmd) }, qr/Saved under/, '"addKey" OK' );

# Test 'save' command
@cmd = qw(-cfgNum 1 save);
$res = Test::Output::stdout_from( sub { llclient->run(@cmd) } );
ok( $res =~ /^\s*(\{.*\})\s*$/s, '"save" result looks like JSON' );
my $j;
eval { $j = JSON::from_json($res) };
is( $j->{cfgNum}, 1, "correct version number" );
ok( not($@), ' result is JSON' ) or diag "error: $@";

# Test 'restore' command
my $tmpFile = File::Temp->new();
print $tmpFile $res;
@cmd = ( 'restore', $tmpFile->filename );
combined_like(
    sub { llclient->run(@cmd) },
    qr/Configuration has been restored as version \d*/s,
    'New config'
);

# Test 'set' command with force
@cmd = qw(-yes 1 -force 1 -cfgNum 2 set useSafeJail 0);
combined_like(
    sub { llclient->run(@cmd) },
    qr#cfgNum forced with 2#s,
    '"Force cfgNum" OK'
);

# Test 'info' command with force
@cmd = qw(info);
combined_like(
    sub { llcommonClient->run(@cmd) },
    qr#\bAuthor IP\b#s,
    '"Author IP" OK'
);
combined_like( sub { llcommonClient->run(@cmd) }, qr#\bLog\b#s, '"Log" OK' );
combined_like( sub { llcommonClient->run(@cmd) },
    qr#\bVersion\b#s, '"Version" OK' );

# Test 'rollback' command
@cmd = qw(rollback);
combined_like(
    sub { llclient->run(@cmd) },
    qr/Configuration \d+ has been rolled back/,
    'Configuration rollback OK'
);

@cmd = qw(-yes 1 merge t/test-merge.json);
combined_like(
    sub { llclient->run(@cmd) },
    qr/Saved under number \d+/,
    'Configuration merge OK'
);

# Test 'purge' command
my $client = llclient;
my $clientConfAcc = llclient->mgr->_confAcc;

# Generate 3 forged configs
&genConfFiles;
@cmd = qw(-yes 1 purge --keep-last 2);
combined_like(
    sub { $client->run(@cmd) },
     # If there are 3 configs and we want to keep the last 2, one config is deleted
    qr/Deleted 1 configs/,
    'Configuration purge --keep-last OK'
);
is($clientConfAcc->available(), 2, 'Correct number of configurations after purge last');

# Generate 3 forged configs
&genConfFiles;
$client = llclient;
@cmd = qw(-yes 1 purge --keep-recent 5);
combined_like(
    sub { $client->run(@cmd) },
    qr/Deleted 2 configs/,
    'Configuration purge --keep-recent OK'
);

is($clientConfAcc->available(), 1, 'Correct number of configurations after purge recent');

count($tests);
done_testing( count() );


sub cleanConfFiles {
    foreach ( 2 .. $tests - 3 ) {
        unlink "$main::tmpdir/conf/lmConf-$_.json";
    }
}

# Sub to delete all existing configs and create forged ones
sub genConfFiles {
    for my $config ($clientConfAcc->available()) {
        $clientConfAcc->delete( $config );
    }
    my $time = time();
    # FIXME: The locationRules is incorrect in the default configuration file,
    # we need to overwrite it
    my @configsToStore = (
        { cfgNum => 1, cfgDate => $time, locationRules => {} },
        { cfgNum => 2, cfgDate => $time - 10, locationRules => {} },
        { cfgNum => 3, cfgDate => $time - 20, locationRules => {}},
    );
    for my $config (@configsToStore) {
        $clientConfAcc->store( $config );
    }
}
