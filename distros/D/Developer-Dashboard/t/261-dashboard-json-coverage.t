#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More;

use lib 'lib';
use Developer::Dashboard::JSON qw(json_decode json_decode_state json_encode json_encode_with_options);

my $value = { z => 1, a => 'café' };
my $pretty = json_encode($value);
like( $pretty, qr/\n/, 'json_encode returns canonical pretty JSON' );
is_deeply( json_decode($pretty), $value, 'json_decode decodes the canonical JSON payload' );

my $compact = json_encode_with_options( $value );
unlike( $compact, qr/\n/, 'option-based encoder defaults to compact output' );
is( json_encode_with_options( $value, ascii => 1 ), '{"a":"caf\\u00e9","z":1}', 'ASCII mode escapes non-ASCII characters' );
like( json_encode_with_options( $value, pretty => 1 ), qr/\n/, 'pretty option enables multiline output' );
my $utf8_bytes = json_encode_with_options( $value, utf8 => 1 );
ok( !utf8::is_utf8($utf8_bytes), 'UTF-8 option returns encoded bytes' );
is_deeply( json_decode($utf8_bytes), $value, 'JSON decoder accepts UTF-8 bytes produced by the encoder' );
my $all_options = json_encode_with_options( $value, ascii => 1, pretty => 1, utf8 => 1 );
ok( !utf8::is_utf8($all_options), 'all encoder options may be enabled together' );
is_deeply( json_decode($all_options), $value, 'combined options preserve the decoded value' );

ok( !defined json_decode_state(undef), 'state decoder rejects an undefined payload as unavailable' );
ok( !defined json_decode_state(" \n\t"), 'state decoder rejects a whitespace-only payload as unavailable' );
is_deeply( json_decode_state('{"ready":true}'), { ready => JSON::XS::true }, 'state decoder accepts a complete JSON object' );
ok( !defined json_decode_state('{"ready":'), 'state decoder returns undef for truncated JSON' );

done_testing();

__END__

=head1 NAME

t/261-dashboard-json-coverage.t - verifies the shared JSON serialization API

=head1 PURPOSE

This unit test exercises every public function in C<Developer::Dashboard::JSON>
and each documented encoder option, as well as all state-decoder outcomes.

=head1 WHY IT EXISTS

The JSON module centralizes encoding and decoding semantics used throughout the
application. Focused tests make its UTF-8, canonical ordering, formatting, and
partial-state behavior independently verifiable.

=head1 WHEN TO USE

Run this test when changing the shared JSON API, its encoding defaults, or its
handling of concurrently written state files.

=head1 HOW TO USE

Run C<prove -lv t/261-dashboard-json-coverage.t> through the project's Docker
development service from the repository root.

=head1 WHAT USES IT

Application modules use this package to serialize persisted data and parse
complete or transiently incomplete JSON state.

=head1 EXAMPLES

Example 1: C<json_encode_with_options($value, ascii =E<gt> 1)> emits ASCII-safe
JSON for generated source text.

Example 2: C<json_decode_state($text)> returns undef while a state file is
temporarily empty or malformed and decodes it once complete.

=cut
