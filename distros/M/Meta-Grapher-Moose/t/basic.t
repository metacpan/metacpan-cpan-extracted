use strict;
use warnings;

use lib 't/lib';

use Test::Requires {
    'MooseX::Role::Parameterized' => '1.09',
};

use Test::Meta::Grapher::Moose qw( test_graphing_for );
use Test2::Bundle::Extended '!meta';

subtest(
    'single class',
    sub {
        my %packages = (
            'ClassA' => {},
        );

        test_graphing_for(
            'ClassA',
            %packages,
        );
    }
);

subtest(
    'ClassB extends ClassA',
    sub {
        my %packages = (
            'ClassB' => { extends => 'ClassA' },
            'ClassA' => {},
        );

        test_graphing_for(
            'ClassB',
            %packages,
        );
    }
);

subtest(
    'ClassC extends ClassB, which extends ClassA',
    sub {
        my %packages = (
            'ClassC' => { extends => 'ClassB' },
            'ClassB' => { extends => 'ClassA' },
            'ClassA' => {},
        );

        test_graphing_for(
            'ClassC',
            %packages,
        );
    }
);

subtest(
    'diamond inheritance - no roles',
    sub {
        my %packages = (
            'ClassD' => { extends => [ 'ClassC', 'ClassB' ] },
            'ClassC' => { extends => 'ClassA' },
            'ClassB' => { extends => 'ClassA' },
            'ClassA' => {},
        );

        test_graphing_for(
            'ClassD',
            %packages,
        );
    }
);

subtest(
    'roles consuming roles - no inheritance',
    sub {
        my %packages = (
            'ClassA' => { with => 'RoleA' },
            'RoleA'  => { with => 'RoleB' },
            'RoleB'  => { with => 'RoleC' },
            'RoleC'  => {},
        );

        test_graphing_for(
            'ClassA',
            %packages,
        );
    }
);

subtest(
    'class consuming many roles which consume many roles',
    sub {
        my %packages = (
            'ClassA' => { with => [qw( RoleA RoleB RoleC )] },
            'RoleA'  => { with => [qw( RoleA1 RoleA2 RoleA3 )] },
            'RoleB'  => { with => [qw( RoleB1 RoleB2 RoleB3 )] },
            'RoleC'  => { with => [qw( RoleC1 RoleC2 RoleC3 )] },
            map { $_ => {} }
                map { ( 'RoleA' . $_, 'RoleB' . $_, 'RoleC' . $_ ) }
                ( 1, 2, 3 ),
        );

        test_graphing_for(
            'ClassA',
            %packages,
        );
    }
);

subtest(
    'class which indirectly consumes roles multiple times',
    sub {
        my %packages = (
            'ClassA' => { with => [qw( RoleA RoleB )] },
            'RoleA'  => { with => [qw( RoleB RoleC )] },
            'RoleB'  => {},
            'RoleC'  => { with => [qw( RoleB RoleD )] },
            'RoleD'  => {},
        );

        test_graphing_for(
            'ClassA',
            %packages,
        );
    }
);

subtest(
    'class which consumes parameterized roles - p-roles only consume roles outside role block',
    sub {
        my %packages = (
            'ClassA'     => { with => [qw( ParamRoleA RoleB )] },
            'ParamRoleA' => {
                with => ['RoleC'],
            },
            'RoleB' => {},
            'RoleC' => {},
        );

        test_graphing_for(
            'ClassA',
            %packages,
        );
    }
);

subtest(
    'class which consumes parameterized roles - p-roles only consume roles inside role block',
    sub {
        my %packages = (
            'ClassA' => { with => [qw( ParamRoleA ParamRoleB )] },
            'ParamRoleA' => { role_block_with => ['RoleC'] },
            'ParamRoleB' => { role_block_with => ['RoleD'] },
            'RoleC'      => {},
            'RoleD'      => {},
        );

        test_graphing_for(
            'ClassA',
            %packages,
        );
    }
);

subtest(
    'class which consumes parameterized roles - p-roles consume roles inside and outside of role block',
    sub {
        my %packages = (
            'ClassA'     => { with => [qw( ParamRoleA ParamRoleB )] },
            'ParamRoleA' => {
                with            => 'RoleC',
                role_block_with => ['RoleD']
            },
            'ParamRoleB' => {
                with            => 'RoleE',
                role_block_with => ['RoleF']
            },
            'RoleC' => {},
            'RoleD' => {},
            'RoleE' => {},
            'RoleF' => {},
        );

        test_graphing_for(
            'ClassA',
            %packages,
        );
    }
);

subtest(
    'complex case with diamond inheritance, roles, and p-roles',
    sub {
        my %packages = (
            ClassD => {
                extends => [ 'ClassB', 'ClassC' ],
            },
            ClassC => {
                extends => 'ClassA',
                with    => 'RoleA',
            },
            ClassB => {
                extends => 'ClassA',
                with    => 'ParamRoleW',
            },
            ClassA => {},
            RoleA  => {
                with => 'RoleB',
            },
            RoleB => {
                with => [ 'RoleC', 'RoleD' ],
            },
            RoleC      => {},
            RoleD      => {},
            ParamRoleW => {
                role_block_with => [ 'ParamRoleX', 'ParamRoleY' ],
            },
            ParamRoleX => {},
            ParamRoleY => {
                role_block_with => 'ParamRoleZ',
            },
            ParamRoleZ => {},
        );

        test_graphing_for(
            'ClassD',
            %packages,
        );
    }
);

done_testing();
