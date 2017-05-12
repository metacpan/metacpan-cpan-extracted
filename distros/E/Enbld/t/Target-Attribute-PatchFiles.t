#!perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

require Enbld::Target::AttributeCollector;

my $no = Enbld::Target::AttributeCollector->new;
$no->add( 'PatchFiles' );
is_deeply( \@{ $no->PatchFiles }, [], 'no parameter' );

my $empty_string = Enbld::Target::AttributeCollector->new;
$empty_string->add( 'PatchFiles', '' );
throws_ok {
    $empty_string->PatchFiles;
} qr/ABORT:Attribute 'PatchFiles' isn't ARRAY reference/,
    'null string parameter';

my $empty_array = Enbld::Target::AttributeCollector->new;
$empty_array->add( 'PatchFiles', [] );
eval { $empty_array->PatchFiles };
is_deeply( \@{ $empty_array->PatchFiles }, [],
        'empty array reference parameter' );

my $fixed_string = Enbld::Target::AttributeCollector->new;
$fixed_string->add( 'PatchFiles', 'http://www.example.com/patch' );
throws_ok {
    $fixed_string->PatchFiles;
} qr/ABORT:Attribute 'PatchFiles' isn't ARRAY reference/,
    'fixed string parameter';

my $fixed_array = Enbld::Target::AttributeCollector->new;
$fixed_array->add( 'PatchFiles', [ 'http://www.example.com/patch' ] );
is_deeply( \@{ $fixed_array->PatchFiles },
        [ 'http://www.example.com/patch' ], 'fixed array parameter' );

my $coderef = Enbld::Target::AttributeCollector->new;
$coderef->add(
        'PatchFiles', sub { return [ 'http://www.example.com/patch' ] }
        );
is_deeply( \@{ $coderef->PatchFiles },
        [ 'http://www.example.com/patch' ], 'coderef parameter' );

my $invalid = Enbld::Target::AttributeCollector->new;
$invalid->add( 'PatchFiles', [ 'ftp://www.example.com/patch' ] );
throws_ok {
    $invalid->PatchFiles;
} qr/ABORT:Attribute 'PatchFiles' isn't valid URL string/,
    'invalid parameter';

done_testing();
