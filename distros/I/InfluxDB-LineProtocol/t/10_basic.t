#!/usr/bin/env perl
use strict;
use warnings;
use 5.012;
use lib 'lib';
use Test::Most;
use InfluxDB::LineProtocol qw(data2line line2data);

my @faketime = ( 1437072205, 500681 );
my $nano = join( '', @faketime ) * 1000;
{
    no warnings 'redefine';

    sub InfluxDB::LineProtocol::gettimeofday() {
        wantarray ? @faketime : join( '.', @faketime );
    }
};

# tests look like:
# - boolan flag if we provide an explicit timestamp
# - ArrayRef of data passed to data2line
# - String of the expected line (without the timestamp if we're not using explicit_timestamp
# - ArrayRef we expected when parsing the line
# - Optional is-TODO-marker

my @tests = (
    # some basic tests without timestamps
    [   0,
        [ 'metric', { cost => '423i' } ],
        'metric cost=423i',
        [ 'metric', { cost => 423 }, undef ]
    ],
    [   0,
        [ 'metric', 42 ],
        'metric value=42i',
        [ 'metric', { value => 42 }, undef ]
    ],
    [
        0, ['metric', {hit=>1, cost=>42}],
        'metric cost=42i,hit=1i',
        [ 'metric', {hit=>1, cost=>42}, undef ]
    ],
    [
        0, ['metric', 42, {server=>'srv1',location=>'eu'}],
        'metric,location=eu,server=srv1 value=42i',
        [ 'metric', {value=>42}, {server=>'srv1',location=>'eu'} ]
    ],
    [
        0, ['metric', {cost=>42}, {server=>'srv1',location=>'eu'}],
        'metric,location=eu,server=srv1 cost=42i',
        [ 'metric', {cost=>42}, {server=>'srv1',location=>'eu'} ]
    ],
    # now with timestamps
    [   1,
        [ 'metric', 42, 1437072299900001000 ],
        'metric value=42i 1437072299900001000',
        [ 'metric', { value => 42 }, undef, 1437072299900001000 ]
    ],
    [
        1, ['metric', {hit=>1, cost=>42},1437072299900001000],
        'metric cost=42i,hit=1i 1437072299900001000',
        [ 'metric', {hit=>1, cost=>42},undef, 1437072299900001000 ]
    ],
    [
        1, ['metric', 42, , {server=>'srv1',location=>'eu'},1437072299900001000],
        'metric,location=eu,server=srv1 value=42i 1437072299900001000',
        [ 'metric', {value=>42}, {server=>'srv1',location=>'eu'}, 1437072299900001000 ]
    ],
    [
        1, ['metric', {cost=>42}, {server=>'srv1',location=>'eu'} ,1437072299900001000],
        'metric,location=eu,server=srv1 cost=42i 1437072299900001000',
        [ 'metric', {cost=>42}, {server=>'srv1',location=>'eu'},1437072299900001000 ]
    ],
    # weird measurement names
    [   0,
        [ 'metric with space', 42 ],
        'metric\ with\ space value=42i',
        [ 'metric with space', { value => '42' }, undef ]
    ],
    [   0,
        [ 'metric,with,comma', 42 ],
        'metric\,with\,comma value=42i',
        [ 'metric,with,comma', { value => '42' }, undef ]
    ],
    [   0,
        [ 'metric,with,comma', 42 , { tag=>'foo' }],
        'metric\,with\,comma,tag=foo value=42i',
        [ 'metric,with,comma', { value => '42' }, { tag=>'foo' } ]
    ],
    [   0,
        [ 'metric\with\backslash', 42 ],
        'metric\with\backslash value=42i',
        [ 'metric\with\backslash', { value => '42' }, undef ]
    ],

    # different value types
    [   0,
        [ 'metric', 'foo' ],
        'metric value="foo"',
        [ 'metric', { value => 'foo' }, undef ]
    ],
    [   0,
        [ 'metric', 1.41 ],
        'metric value=1.41',
        [ 'metric', { value => 1.41 }, undef ]
    ],
    [   0,
        [ 'metric', -1.41 ],
        'metric value=-1.41',
        [ 'metric', { value => -1.41 }, undef ]
    ],
    [   0,
        [ 'metric', -42 ],
        'metric value=-42i',
        [ 'metric', { value => -42 }, undef ]
    ],
    [   0,
        [ 'metric', 7.51696501241595e-05 ],
        'metric value=7.51696501241595e-05',
        [ 'metric', { value => 7.51696501241595e-05 }, undef ],
        [ 'SKIP', sub { $^O eq 'MSWin32' }, 'negative exponentials are strange on windows' ]
    ],
    [   0,
        [ 'metric', '7.51696501241595e05' ],
        'metric value=7.51696501241595e05',
        [ 'metric', { value => '7.51696501241595e05' }, undef ]
    ],
    [   0,
        [ 'metric', 'foo"bar"' ],
        'metric value="foo\"bar\""',
        [ 'metric', { value => 'foo"bar"' }, undef ],
    ],
    [
        0,
        [ 'metric', 't' ],
        'metric value=TRUE',
        [ 'metric', { value => 'TRUE' }, undef ],
    ],
    [
        0,
        [ 'metric', 'T' ],
        'metric value=TRUE',
        [ 'metric', { value => 'TRUE' }, undef ],
    ],
    [
        0,
        [ 'metric', 'FALSE' ],
        'metric value=FALSE',
        [ 'metric', { value => 'FALSE' }, undef ],
    ],
    [
        0,
        [ 'metric', 'F' ],
        'metric value=FALSE',
        [ 'metric', { value => 'FALSE' }, undef ],
    ],
    [
        0,
        [ 'metric', 'False' ],
        'metric value=FALSE',
        [ 'metric', { value => 'FALSE' }, undef ],
    ],
    [
        0,
        [ 'metric', 'tru' ],
        'metric value="tru"',
        [ 'metric', { value => 'tru' }, undef ],
    ],

    # escape values
    [
        0,
        ['metric', "some value"],
        'metric value="some value"',
        ['metric', { value=>'some value' } , undef],
    ],
    [
        0,
        ['metric', {a => "some value", b=>'another value'}],
        'metric a="some value",b="another value"',
        ['metric', { a=>'some value', b=>'another value' } , undef],
    ],
    [
        0,
        ['metric', {a => "some value", b=>'another, value'}],
        'metric a="some value",b="another, value"',
        ['metric', { a=>'some value', b=>'another, value' } , undef],
    ],
    [
        0,
        ['metric', 'some "value"'],
        'metric value="some \"value\""',
        ['metric', { value=>'some "value"' } , undef],
    ],
    [   0,
        [ 'metric', 'some \"value\"' ],
        'metric value="some \\\\\"value\\\\\""',
        [ 'metric', { value => 'some \"value\"' }, undef ],
    ],

    # tag types
    # escape tags
    [
        0,
        ['metric',42,{ 'tag space, comma'=>'value space, comma' }],
        'metric,tag\ space\,\ comma=value\ space\,\ comma value=42i',
        ['metric',{value=>42},{ 'tag space, comma'=>'value space, comma' }],
    ],

    # Examples from https://influxdb.com/docs/v0.9/write_protocols/write_syntax.html
    [
        1,
        ['disk_free', {free_space=>442221834240, disk_type=>'SSD'},1435362189575692182],
        'disk_free disk_type="SSD",free_space=442221834240i 1435362189575692182',
        ['disk_free', {free_space=>442221834240, disk_type=>'SSD'},undef,1435362189575692182],
    ],
    [
        1,
        ["total disk free",442221834240,{ volumes=>'/net,/home,/'},1435362189575692182],
        'total\ disk\ free,volumes=/net\,/home\,/ value=442221834240i 1435362189575692182',
        ["total disk free",{value=>442221834240},{ volumes=>'/net,/home,/'},1435362189575692182],
    ],
    [
        0,
        ['disk_free',442221834240,{ path=>'C:\Windows' }],
        'disk_free,path=C:\Windows value=442221834240i',
        ['disk_free',{value=>442221834240},{ path=>'C:\Windows' }],
    ],
    [
        0,
        ['disk_free',{ value=> 442221834240, 'working directories'=>'C:\My Documents\Stuff for examples,C:\My Documents'}],
        'disk_free value=442221834240i,working\ directories="C:\\\\My Documents\\\\Stuff for examples,C:\\\\My Documents"',
        ['disk_free',{ value=> 442221834240, 'working directories'=>'C:\My Documents\Stuff for examples,C:\My Documents'}, undef],
    ],
    [
        0,
        ['"measurement with quotes"',{ 'field_key\\\\'=>'string field value, only " need be quoted'} , { 'tag key with spaces' =>  'tag,value,with"commas"'} ],
        '"measurement\ with\ quotes",tag\ key\ with\ spaces=tag\,value\,with"commas" field_key\\\\="string field value, only \" need be quoted"',
        ['"measurement with quotes"',{ 'field_key\\\\'=>'string field value, only " need be quoted'}, { 'tag key with spaces' =>  'tag,value,with"commas"'} ],
    ],
    # 0.9.3 integer in tag and value
    [
        0, ['metric', {int=>42, float=>0.5}, {inttag=>8,floattag=>13.13}],
        'metric,floattag=13.13,inttag=8 float=0.5,int=42i',
        [ 'metric', {int=>42, float=>0.5}, {inttag=>8,floattag=>13.13} ]
    ],

);


while ( my ( $i, $case ) = each @tests ) {
    my ( $explicit_timestamp, $in, $raw_line, $out, $testtag ) = @$case;
    explain("case $i: $raw_line");

    my $expected_line;
    if ($explicit_timestamp) {
        $expected_line = $raw_line;
    }
    else {
        $expected_line = $raw_line . ' ' . $nano;
        push(@$out,$nano);
    }

    if ($testtag) {
        if ($testtag->[0] eq 'TODO') {
            TODO: {
                local $TODO = 'not implemented yet';
                _do_test($i, $in, $expected_line, $out);
            };
            next;
        }
        elsif ($testtag->[0] eq 'SKIP' && $testtag->[1]->()) {
            SKIP: {
                skip $testtag->[2], 2;
                _do_test($i, $in, $expected_line, $out);
            };
            next;
        }
    }

    _do_test($i, $in, $expected_line, $out);
}

sub _do_test {
    my ($i, $in, $expected_line, $out) = @_;
    is( data2line(@$in), $expected_line, "data2line case $i" );
    my @result = line2data($expected_line);
    cmp_deeply( \@result, $out, "line2data case $i" );
}
done_testing();
