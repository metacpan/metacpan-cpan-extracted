# Before `make install' is performed this script should be runnable with
# `make test' or 'prove'. After `make install' it should work
# as `perl HTML-ParseBrowser.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';
use strict;
use warnings;
use FindBin qw($Bin);
use File::Spec;
BEGIN {
  eval { require JSON::Tiny; JSON::Tiny->import("decode_json"); 1; } ||
  eval { require JSON; JSON->import("decode_json"); 1; };
}
# 0.94 necessary for subtests and note()
use Test::More 0.94;
# plan tests => 46;
require_ok('HTML::ParseBrowser');

my $ua;
ok($ua = HTML::ParseBrowser->new(), 'constructor');
isa_ok($ua, 'HTML::ParseBrowser');

my $tests;
{
    my $json_file = File::Spec->catfile($Bin, 'corpus.json');
    local $/;
    open my $fh, '<', $json_file or
        die q(couldn't open $json_file: $!);
    my $bytes = <$fh>;
    $tests = decode_json($bytes);
}

for my $data (@$tests){
    # anything that isn't a hash is a comment
    next if('HASH' ne (ref $data));
    my $ua_string = $data->{user_agent};
    my $test_name = substr($ua_string, 0, 40) . '...';
    subtest $test_name => sub {
        plan tests => scalar keys %$data;
        $ua->Parse($ua_string);
        for my $key (keys %$data){
            # TODO: should check validity with can() but autoload prevents that currently
            is($ua->$key(), $data->{$key}, $key) or
                note "failed $key for $ua_string";
        }
    };
}

# tests that cannot yet be done via JSON

$ua->Parse('Mozilla/5.0 (Macintosh; U; PPC Mac OS X; it-IT) AppleWebKit/125.4 (KHTML, like Gecko, Safari) OmniWeb/v563.15');
ok(!defined($ua->osvers), 'no OS version for this UA string')
  or note $ua->osvers;

done_testing();
