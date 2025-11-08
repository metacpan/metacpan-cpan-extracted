#!/usr/bin/env perl
use v5.36.1;
use strict;
use warnings;
use lib './lib';
use utf8;
use open ':std' => 'utf8';
use Test::More;
use JSON;
use JSON::Schema::Validate;

my $fmt = sub { +{
    type => 'object',
    properties =>
    {
        v =>
        {
            type => 'string',
            format => $_[0]
        }
    },
    required => ['v'], additionalProperties => JSON::false
}};

sub run_case
{
    my( $format, $value, $ok ) = @_;
    my $js = JSON::Schema::Validate->new( $fmt->( $format ) )->register_builtin_formats;
    my $got = $js->validate({ v => $value });
    ok( $ok ? $got : !$got, "$format: ".($ok?'OK':'FAIL')." - $value" )
        or diag( $js->error );
}

run_case 'date-time', '2025-11-07T12:34:56Z', 1;
run_case 'date-time', '2025-13-40T12:34:56Z', 0;
run_case 'date',      '2025-01-31', 1;
run_case 'date',      '2025-13-01', 0;
run_case 'time',      '23:59:59', 1;
run_case 'time',      '24:00:00', 0;

run_case 'duration',  'P1Y2M3DT4H5M6S', 1;
run_case 'duration',  'P-1Y', 0;

run_case 'email',     'jack@example.org', 1;
run_case 'email',     'jack@@example.org', 0;
run_case 'idn-email', '名@example.org', 1;

run_case 'hostname',  'example.org', 1;
run_case 'hostname',  '-bad.example', 0;
run_case 'idn-hostname', 'xn--bcher-kva.example', 1;

run_case 'ipv4', '192.168.0.1', 1;
run_case 'ipv4', '256.1.1.1', 0;

run_case 'ipv6', '2001:db8::1', 1;
run_case 'ipv6', '2001:::1', 0;

run_case 'uri', 'https://example.org/x?y#z', 1;
run_case 'uri', 'noscheme', 0;

run_case 'uri-reference', '../rel', 1;
run_case 'iri', 'https://例え.テスト/道', 1;

run_case 'uuid', '123e4567-e89b-12d3-a456-426614174000', 1;
run_case 'uuid', '123e4567e89b12d3a456426614174000', 0;

run_case 'json-pointer', '', 1;
run_case 'json-pointer', '/a~1b/c~0d', 1;
run_case 'json-pointer', '/bad~2', 0;

run_case 'relative-json-pointer', '0', 1;
run_case 'relative-json-pointer', '2/child', 1;
run_case 'relative-json-pointer', '01/child', 0;

run_case 'regex', '^[a-z]+$', 1;
run_case 'regex', '(?P<bad>', 0;

done_testing;

__END__
