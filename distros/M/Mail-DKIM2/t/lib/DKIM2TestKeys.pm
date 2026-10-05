package DKIM2TestKeys;
use strict;
use warnings;

use Path::Tiny;
use JSON qw(decode_json);
use Mail::DKIM2::Common qw(load_private_key parse_dkim_pubkey);

# The test keys and dns.json ship with the distribution under t/data/, so
# the suite runs from an unpacked tarball with nothing else around it. In the
# interop repository they are copies of ../keys/ and ../dns.json, which the
# other implementations' tests share; t/data-in-sync.t keeps them identical.
my $DATA     = path(__FILE__)->absolute->parent->parent->child('data');
my $KEYS_DIR = $DATA->child('keys');
my $DNS_JSON = $DATA->child('dns.json');

# Paths for tests that hand them to a CLI or a config, as strings.
sub keys_dir { return "$KEYS_DIR" }
sub dns_json { return "$DNS_JSON" }

my %_key_cache;

# Returns the private key object for a given domain and Selector.
sub private_key {
    my ($domain, $selector) = @_;
    my $cache_key = "$selector/$domain";
    unless (exists $_key_cache{$cache_key}) {
        my $pem = $KEYS_DIR->child("${selector}._domainkey.${domain}.pem");
        die "No key file for $selector._domainkey.$domain (looked for $pem)\n"
            unless $pem->exists;
        $_key_cache{$cache_key} = load_private_key("$pem");
    }
    return $_key_cache{$cache_key};
}

# Returns PEM-encoded private key string for the given Selector.
sub private_key_pem {
    my ($domain, $selector) = @_;
    my $pem = $KEYS_DIR->child("${selector}._domainkey.${domain}.pem");
    die "No key file for $selector._domainkey.$domain\n" unless $pem->exists;
    return $pem->slurp;
}

# Returns a pubkey callback sub for Verifier->set_pubkey_callback.
# Looks up the key in the shared dns.json file.
sub pubkey_callback {
    my $dns = decode_json($DNS_JSON->slurp);
    return sub {
        my ($signature, $idx) = @_;
        $idx //= 0;
        my $sel = $signature->selector($idx);
        my $dom = $signature->domain;
        my $entry = $dns->{$dom}{"${sel}._domainkey"};
        return unless $entry && $entry->[0];
        my $txt = $entry->[0][1];
        return parse_dkim_pubkey($txt);
    };
}

1;
