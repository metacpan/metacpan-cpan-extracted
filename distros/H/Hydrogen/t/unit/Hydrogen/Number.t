# This file was autogenerated.

=head1 NAME

t/unit/Hydrogen/Number.t - unit tests for Hydrogen::Number

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2022-2025 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=cut

use 5.008001;
use strict;
use warnings;
use Test2::V0 -target => "Hydrogen::Number";

isa_ok( 'Hydrogen::Number', 'Exporter::Tiny' );

my %EXPORTS = map +( $_ => 1 ), @Hydrogen::Number::EXPORT_OK;

subtest 'abs' => sub {
    ok exists(&Hydrogen::Number::abs), 'function exists';
    ok $EXPORTS{'abs'}, 'function is importable';
    my $exception = dies {
        my $testnumber = -5;
        Hydrogen::Number::abs( $testnumber );
        is( $testnumber, 5, q{$testnumber is 5} );
    };
    is $exception, undef, 'no exception thrown running abs example';
};

subtest 'add' => sub {
    ok exists(&Hydrogen::Number::add), 'function exists';
    ok $EXPORTS{'add'}, 'function is importable';
    my $exception = dies {
        my $testnumber = 4;
        Hydrogen::Number::add( $testnumber, 5 );
        is( $testnumber, 9, q{$testnumber is 9} );
    };
    is $exception, undef, 'no exception thrown running add example';
};

subtest 'ceil' => sub {
    ok exists(&Hydrogen::Number::ceil), 'function exists';
    ok $EXPORTS{'ceil'}, 'function is importable';
};

subtest 'cmp' => sub {
    ok exists(&Hydrogen::Number::cmp), 'function exists';
    ok $EXPORTS{'cmp'}, 'function is importable';
};

subtest 'div' => sub {
    ok exists(&Hydrogen::Number::div), 'function exists';
    ok $EXPORTS{'div'}, 'function is importable';
    my $exception = dies {
        my $testnumber = 6;
        Hydrogen::Number::div( $testnumber, 2 );
        is( $testnumber, 3, q{$testnumber is 3} );
    };
    is $exception, undef, 'no exception thrown running div example';
};

subtest 'eq' => sub {
    ok exists(&Hydrogen::Number::eq), 'function exists';
    ok $EXPORTS{'eq'}, 'function is importable';
};

subtest 'floor' => sub {
    ok exists(&Hydrogen::Number::floor), 'function exists';
    ok $EXPORTS{'floor'}, 'function is importable';
};

subtest 'ge' => sub {
    ok exists(&Hydrogen::Number::ge), 'function exists';
    ok $EXPORTS{'ge'}, 'function is importable';
};

subtest 'get' => sub {
    ok exists(&Hydrogen::Number::get), 'function exists';
    ok $EXPORTS{'get'}, 'function is importable';
    my $exception = dies {
        my $testnumber = 4;
        is( Hydrogen::Number::get( $testnumber ), 4, q{Hydrogen::Number::get( $testnumber ) is 4} );
    };
    is $exception, undef, 'no exception thrown running get example';
};

subtest 'gt' => sub {
    ok exists(&Hydrogen::Number::gt), 'function exists';
    ok $EXPORTS{'gt'}, 'function is importable';
};

subtest 'le' => sub {
    ok exists(&Hydrogen::Number::le), 'function exists';
    ok $EXPORTS{'le'}, 'function is importable';
};

subtest 'lt' => sub {
    ok exists(&Hydrogen::Number::lt), 'function exists';
    ok $EXPORTS{'lt'}, 'function is importable';
};

subtest 'mod' => sub {
    ok exists(&Hydrogen::Number::mod), 'function exists';
    ok $EXPORTS{'mod'}, 'function is importable';
    my $exception = dies {
        my $testnumber = 5;
        Hydrogen::Number::mod( $testnumber, 2 );
        is( $testnumber, 1, q{$testnumber is 1} );
    };
    is $exception, undef, 'no exception thrown running mod example';
};

subtest 'mul' => sub {
    ok exists(&Hydrogen::Number::mul), 'function exists';
    ok $EXPORTS{'mul'}, 'function is importable';
    my $exception = dies {
        my $testnumber = 2;
        Hydrogen::Number::mul( $testnumber, 5 );
        is( $testnumber, 10, q{$testnumber is 10} );
    };
    is $exception, undef, 'no exception thrown running mul example';
};

subtest 'ne' => sub {
    ok exists(&Hydrogen::Number::ne), 'function exists';
    ok $EXPORTS{'ne'}, 'function is importable';
};

subtest 'set' => sub {
    ok exists(&Hydrogen::Number::set), 'function exists';
    ok $EXPORTS{'set'}, 'function is importable';
    my $exception = dies {
        my $testnumber = 4;
        Hydrogen::Number::set( $testnumber, 5 );
        is( $testnumber, 5, q{$testnumber is 5} );
    };
    is $exception, undef, 'no exception thrown running set example';
};

subtest 'sub' => sub {
    ok exists(&Hydrogen::Number::sub), 'function exists';
    ok $EXPORTS{'sub'}, 'function is importable';
    my $exception = dies {
        my $testnumber = 9;
        Hydrogen::Number::sub( $testnumber, 6 );
        is( $testnumber, 3, q{$testnumber is 3} );
    };
    is $exception, undef, 'no exception thrown running sub example';
};

done_testing; # :)
