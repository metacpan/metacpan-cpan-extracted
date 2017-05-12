#!/usr/bin/perl

use t::lib::Test;
use MIME::Base64 qw(encode_base64);

$ENV{DBGP_PERL_IGNORE_PADWALKER} = 1;

run_debugger('t/scripts/variables.pl');

send_command('run');

my $values = send_command('context_get');
parsed_response_is($values, {
    command => 'context_get',
    values  => [
        {
            name        => '$aref',
            fullname    => '$aref',
            type        => 'ARRAY',
            constant    => '0',
            children    => '1',
            numchildren => '3',
            page        => 0,
            pagesize    => 10,
            value       => undef,
            childs      => [],
        },
        {
            name        => '$foo',
            fullname    => '$foo',
            type        => 'int',
            constant    => '0',
            children    => '0',
            value       => '123',
        },
        {
            name        => '%foo',
            fullname    => '%foo',
            type        => 'HASH',
            constant    => '0',
            children    => '1',
            numchildren => '3',
            page        => 0,
            pagesize    => 10,
            value       => undef,
            childs      => [],
        },
        {
            name        => '@foo',
            fullname    => '@foo',
            type        => 'ARRAY',
            constant    => '0',
            children    => '1',
            numchildren => '3',
            page        => 0,
            pagesize    => 10,
            value       => undef,
            childs      => [],
        },
        {
            name        => '$undef',
            fullname    => '$undef',
            type        => 'undef',
            constant    => '0',
            children    => '0',
            value       => undef,
        },
    ],
});

my $refs = send_command('eval', '--', encode_base64('[map "$_", ($aref, undef, \%foo, \@foo, undef)]'));
my @addresses = map {
    if ($_->value) {
        $_->value =~ /\(0x(.*)\)/ or die $_->value;
        hex $1;
    } else {
        undef;
    }
} @{$refs->result->childs};

for my $i (0 .. 4) {
    is($values->values->[$i]->address, $addresses[$i]);
}

done_testing();
