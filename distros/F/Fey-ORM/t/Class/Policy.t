use strict;
use warnings;

use Test::More 0.88;

use lib 't/lib';

use Fey::ORM::Test qw( schema );

## no critic (Modules::ProhibitMultiplePackages)
{
    package Date;

    sub new { bless { date => $_[1] }, $_[0] }

    sub date { $_[0]->{date} }
}

{
    package MyApp::Policy;

    use Fey::ORM::Policy;

    transform_all matching { $_[0]->type eq 'date' } =>
        inflate { Date->new( $_[1] ) } =>
        deflate { defined $_[1] && ref $_[1] ? $_[1]->date() : $_[1] };

    has_one_namer { lc $_[0]->name() . '_one' };

    has_many_namer { lc $_[0]->name() . '_many' };
}

{
    package FakeTable;

    sub new { bless { name => $_[1] }, $_[0] }

    sub name { $_[0]->{name} }
}

{
    package FakeColumn;

    sub new { bless { type => $_[1] }, $_[0] }

    sub type { $_[0]->{type} }
}

{
    my $policy = MyApp::Policy->Policy();

    isa_ok( $policy, 'Fey::Object::Policy' );

    my $table = FakeTable->new('User');

    is(
        $policy->has_one_namer()->($table), 'user_one',
        'has_one_namer returns expected value when called'
    );

    is(
        $policy->has_many_namer()->($table), 'user_many',
        'has_many_namer returns expected value'
    );

    my @transforms = $policy->transforms();
    is( scalar @transforms, 1, 'policy has one transform' );

    my $col1 = FakeColumn->new('date');
    my $col2 = FakeColumn->new('int');

    ok(
        $transforms[0]{matching}->($col1),
        'date type column matches transform'
    );
    ok(
        !$transforms[0]{matching}->($col2),
        'int type column does not match transform'
    );

    my $date = $transforms[0]{inflate}->( undef, '2009-01-01' );
    is(
        $date->date(), '2009-01-01',
        'inflate returns expected date object'
    );
    is(
        $transforms[0]{deflate}->( undef, $date ), '2009-01-01',
        'deflate returns expected string'
    );

    ok(
        $policy->transform_for_column($col1),
        'found a transform for date column'
    );
    ok(
        !$policy->transform_for_column($col2),
        'did not find a transform for int column'
    );
}

my $Schema = schema();

{
    package Schema;

    use Fey::ORM::Schema;

    has_schema $Schema;
}

{
    package User;

    use Fey::ORM::Table;

    has_table $Schema->table('User');

    has_policy 'MyApp::Policy';
}

{
    is(
        User->meta()->policy(), MyApp::Policy->Policy(),
        'policy object was set from policy-defining class'
    );
}

{
    package Group;

    use Fey::ORM::Table;

    has_table $Schema->table('Group');

    has_policy( MyApp::Policy->Policy() );
}

{
    is(
        Group->meta()->policy(), MyApp::Policy->Policy(),
        'policy object was set from an object'
    );
}

done_testing();
