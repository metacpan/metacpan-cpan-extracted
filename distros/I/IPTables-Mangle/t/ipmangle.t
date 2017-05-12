use strict;
use Test::More tests => 9;
use YAML;

use_ok( 'IPTables::Mangle' );

my $sample_file = <<END;
filter:
    forward: { default: drop }
    input:
        # by default, do not allow any connections unless authorized
        # in the rules below
        default: drop

        # by default, if no "action" is given to a rule below, accept it
        default_rule_action: accept 

        rules:
            # Accept all traffic on loopback interface
            - in-interface: lo

            # Don't disconnect existing connections during a rule change.
            - { match: state, state: 'ESTABLISHED,RELATED' }

            # Allow for pings (no more than 10 a second)
            - { protocol: icmp, icmp-type: 8, match: limit, limit: 10/sec }

            # Allow these IPs, no matter what
            - src: 123.123.123.123

            # example of blocking an IP 
            # - { action: drop, src: 8.8.8.8 }

            # open ssh to the world (for now)
            - { protocol: tcp, dport: 22 }

            - { protocol: tcp, dport: 8000:20000 }
            - { protocol: tcp, dport: 80 }
            - { protocol: tcp, dport: 443 }

END

my $config = IPTables::Mangle::process_config(Load($sample_file));

my @verify_rules = (
    '-A INPUT --in-interface lo -j ACCEPT',
    '-A INPUT --match state --state ESTABLISHED,RELATED -j ACCEPT',
    '-A INPUT --protocol icmp --match limit --limit 10/sec --icmp-type 8 -j ACCEPT',
    '-A INPUT --src 123.123.123.123 -j ACCEPT',
    '-A INPUT --protocol tcp --dport 22 -j ACCEPT',
    '-A INPUT --protocol tcp --dport 8000:20000 -j ACCEPT',
    '-A INPUT --protocol tcp --dport 80 -j ACCEPT',
    '-A INPUT --protocol tcp --dport 443 -j ACCEPT',
);

ok($config =~ /$_/, "found '$_'") for @verify_rules;


