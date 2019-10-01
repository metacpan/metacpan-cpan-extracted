my $tests;

BEGIN { $tests = 5 }

use Test::More tests => $tests;
use JSON;
use strict;

use_ok('Lemonldap::NG::Common::Cli');
use_ok('Lemonldap::NG::Manager::Cli');
&cleanConfFiles;

SKIP: {
    eval 'use Test::Output;';
    if ($@) {
        skip 'Test::Output is missing, skipping', $tests - 2;
    }
    my @cmd;
    @cmd = ('save');
    my $client =
      Lemonldap::NG::Manager::Cli->new( iniFile => 't/lemonldap-ng.ini' );
    my $res = Capture::Tiny::capture_stdout( sub { $client->run(@cmd) } );
    ok( $res =~ /^\s*(\{.*\})\s*$/s, '"save" result looks like JSON' );
    eval { JSON::from_json($res) };
    ok( not($@), ' result is JSON' ) or diag "error: $@";
    close STDIN;
    open STDIN, '<', \$res;
    @cmd = ( 'restore', '-' );
    Test::Output::combined_like( sub { $client->run(@cmd) },
        qr/"cfgNum"\s*:\s*"2"/s, 'New config: 2' );
}
&cleanConfFiles;

sub cleanConfFiles {
    foreach ( 2 .. $tests - 3 ) {
        unlink "t/conf/lmConf-$_.json";
    }
}
