#!perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

require Enbld::Target::AttributeCollector;

plan skip_all => "Skip a test since it is not OS X" unless ( $^O eq 'darwin' );

my $no = Enbld::Target::AttributeCollector->new;
$no->add( 'Dependencies' );
is_deeply( \@{ $no->Dependencies }, [], 'no parameter' );

my $empty_string = Enbld::Target::AttributeCollector->new;
$empty_string->add( 'Dependencies', '' );
throws_ok {
    $empty_string->Dependencies;
} qr/ABORT:Attribute 'Dependencies' isn't ARRAY reference/,
    'null string parameter';

my $empty_array = Enbld::Target::AttributeCollector->new;
$empty_array->add( 'Dependencies', [] );
$empty_array->Dependencies;
is_deeply( \@{ $empty_array->Dependencies }, [],
        'empty array reference parameter' );

my $fixed_string = Enbld::Target::AttributeCollector->new;
$fixed_string->add( 'Dependencies', 'dependant' );
throws_ok {
    $fixed_string->Dependencies;
} qr/ABORT:Attribute 'Dependencies' isn't ARRAY reference/,
    'fixed string parameter';

my $fixed_array = Enbld::Target::AttributeCollector->new;
$fixed_array->add( 'Dependencies', [ 'dependant' ] );
is_deeply( \@{ $fixed_array->Dependencies }, [ 'dependant' ],
        'fixed array parameter' );

my $coderef = Enbld::Target::AttributeCollector->new;
$coderef->add( 'Dependencies', sub { return [ 'dependant' ] } );
is_deeply( \@{ $coderef->Dependencies }, [ 'dependant' ],
        'coderef parameter' );

my $space = Enbld::Target::AttributeCollector->new;
$space->add( 'Dependencies', [ 'de pe nd an t' ] );
throws_ok {
    $space->Dependencies;
} qr/ABORT:Attribute 'Dependencies' includes space character/,
    'including space';

done_testing();
