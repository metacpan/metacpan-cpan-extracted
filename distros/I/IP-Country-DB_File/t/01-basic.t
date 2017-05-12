use strict;
use warnings;

use Test::More tests => 72;

BEGIN { use_ok('IP::Country::DB_File') };
BEGIN { use_ok('IP::Country::DB_File::Builder') };

my $ipv6_supported = IP::Country::DB_File::Builder::_ipv6_supported();

my $filename = 't/ipcc.db';
unlink($filename);

{
    # Build the database in a separate lexical scope to make sure that
    # the builder is destroyed before running the rest of the tests.

    my $builder = IP::Country::DB_File::Builder->new($filename);
    ok(defined($builder), 'new');

    my $num_ranges_v4  = 81;
    my $num_ranges_v6  = 5;
    my $priv_ranges_v4 = 3;
    my $priv_ranges_v6 = 1;
    my $flags          = 0;

    if (!$ipv6_supported) {
        $flags          = IP::Country::DB_File::Builder::_EXCLUDE_IPV6;
        $num_ranges_v6  = 0;
        $priv_ranges_v6 = 0;
    }

    ok(open(my $file, '<', 't/delegated-test'), 'open source file');
    is($builder->_import_file($file, $flags), $num_ranges_v4 + $num_ranges_v6,
       'import file');
    $builder->_store_private_networks($flags);
    $builder->_sync();
    close($file);

    is($builder->num_ranges_v4, $num_ranges_v4 + $priv_ranges_v4,
       'num_ranges_v4');
    is($builder->num_ranges_v6, $num_ranges_v6 + $priv_ranges_v6,
       'num_ranges_v6');
    is($builder->num_addresses_v4, 40337408, 'num_addresses_v4');
}

ok(-e $filename, 'create db');

my $ipcc = IP::Country::DB_File->new($filename);

SKIP: {
    my $db_time = $ipcc->db_time();
    # For some reason stat can return a zero mtime on Windows. Unfortunately,
    # I haven't figured out why.
    skip("Getting mtime fails on Windows", 1)
        if $db_time == 0 && $^O =~ /mswin|cygwin/i;
    my $now = time();
    ok(abs($db_time - $now) < 60,
       "db_time ($db_time) near current time ($now)");
}

my @tests_v4 = qw(
    0.0.0.0         ?
    0.0.0.1         ?
    0.0.1.0         ?
    0.1.0.0         ?
    1.2.3.4         ?
    9.255.255.255   ?
    10.0.0.0        **
    10.255.255.255  **
    11.0.0.0        ?
    24.131.255.255  ?
    24.132.0.0      NL
    24.132.127.255  NL
    24.132.128.0    NL
    24.132.255.255  NL
    24.133.0.0      ?
    24.255.255.255  ?
    25.0.0.0        GB
    25.50.100.200   GB
    25.255.255.255  GB
    26.0.0.0        ?
    33.177.178.99   ?
    61.1.255.255    ?
    62.12.95.255    CY
    62.12.96.0      ?
    62.12.127.255   ?
    62.12.128.0     CH
    172.15.255.255  ?
    172.16.0.0      **
    172.31.255.255  **
    172.32.0.0      ?
    192.167.255.255 ?
    192.168.0.0     **
    192.168.255.255 **
    192.169.0.0     ?
    217.198.128.241 UA
    217.255.255.255 DE
    218.0.0.0       ?
    218.0.0.1       ?
    218.0.0.111     ?
    218.0.111.111   ?
    218.111.111.111 ?
    224.111.111.111 ?
    254.111.111.111 ?
    255.255.255.255 ?
);

for(my $i=0; $i<@tests_v4; $i+=2) {
    my ($ip, $test_cc) = ($tests_v4[$i], $tests_v4[$i+1]);
    #print STDERR ("\n*** $ip $cc ", $ipcc->inet_atocc($ip));
    my $cc = $ipcc->inet_atocc($ip);
    $cc = '?' unless defined($cc);
    ok($cc eq $test_cc, "lookup $ip, got $cc, expected $test_cc");
}

my @tests_v6 = qw(
    ::                                      ?
    ::1                                     ?
    2001:5ff::                              ?
    2001:5ff:ffff:ffff:ffff:ffff:ffff:ffff  ?
    2001:600::                              EU
    2001:600:1fff:ffff::                    EU
    2001:600:2000::                         EU
    2001:600:ffff:ffff::                    EU
    2001:601::                              ?
    2a02:650:a3f0:4626:94f0:b695:a178:f9d2  DE
    2a02:660:ffff:ffff::                    RS
    2a02:661::                              ?
    d730:3039:322c:4516:bb78:caf4:1d88:c62f ?
    fbff:ffff:ffff:ffff::                   ?
    fc00::                                  **
    fdff:ffff:ffff:ffff::                   **
    fe00::                                  ?
    ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff ?
);

SKIP: {
    skip("Socket doesn't support IPv6", 18)
        if !$ipv6_supported;

    for (my $i = 0; $i < @tests_v6; $i += 2) {
        my ($ip, $test_cc) = ($tests_v6[$i], $tests_v6[$i+1]);
        my $cc = $ipcc->inet6_atocc($ip);
        $cc = '?' unless defined($cc);
        ok($cc eq $test_cc, "lookup $ip, got $cc, expected $test_cc");
    }
}

unlink($filename);

