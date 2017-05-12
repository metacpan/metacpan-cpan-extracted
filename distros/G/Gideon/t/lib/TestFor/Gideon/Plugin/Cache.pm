package TestFor::Gideon::Plugin::Cache;
use Test::Class::Moose;
use Test::MockObject;
use Gideon::Registry;
use TestClass;

with 'Test::Class::Moose::Role::AutoUse';

sub test_setup {
    my $fake_cache = Test::MockObject->new;
    Gideon::Registry->register_cache($fake_cache);
}

sub test_find {
    Gideon::Registry->get_cache->mock(
        get => sub {
            ok $_[1], 'get: key';
            undef;
        }
    );
    Gideon::Registry->get_cache->mock(
        set => sub {
            ok $_[1], 'set: key';
            is scalar @{ $_[2] }, 1, 'set: results';
            is $_[3], '10m', 'set: expiration';
        }
    );

    my %query = ( id => 1, -order => { desc => 'id' } );

    my $fake_driver = Test::MockObject->new;
    $fake_driver->mock(
        find => sub {
            my ( $self, $target, %actual_query ) = @_;
            is $target, 'TestClass', 'find: target';
            is_deeply \%actual_query, \%query, 'find: query';
            return [ TestClass->new ];
        }
    );

    my $plugin = Gideon::Plugin::Cache->new( next => $fake_driver );
    my $result = $plugin->find( 'TestClass', %query, -cache_for => '10m' );
    is scalar @$result, 1, 'find: returned number of results';
}

sub test_find_cached {
    Gideon::Registry->get_cache->mock(
        get => sub {
            ok $_[1], 'get: key';
            return [ TestClass->new ];
        }
    );

    my $plugin = Gideon::Plugin::Cache->new( next => undef );

    my $result = $plugin->find( 'TestClass', -cache_for => '10m', );
    is scalar @$result, 1, 'find: returned number of result';
}

sub test_find_one {
    Gideon::Registry->get_cache->mock(
        get => sub {
            ok $_[1], 'get: key';
            undef;
        }
    );
    Gideon::Registry->get_cache->mock(
        set => sub {
            ok $_[1],     'set: key';
            isa_ok $_[2], 'TestClass', 'set: result';
            is $_[3],     '10m', 'set: expiration';
        }
    );

    my %query = ( id => 1, -order => { desc => 'id' } );

    my $fake_driver = Test::MockObject->new;
    $fake_driver->mock(
        find_one => sub {
            my ( $self, $target, %actual_query ) = @_;
            is $target, 'TestClass', 'find_one: target';
            is_deeply \%actual_query, \%query, 'find_one: query';
            return TestClass->new;
        }
    );

    my $plugin = Gideon::Plugin::Cache->new( next => $fake_driver );
    my $result = $plugin->find_one( 'TestClass', %query, -cache_for => '10m' );
    isa_ok $result, 'TestClass', 'find_one: result';
}

sub test_find_one_cached {
    Gideon::Registry->get_cache->mock(
        get => sub {
            ok $_[1], 'get: key';
            return TestClass->new;
        }
    );

    my $plugin = Gideon::Plugin::Cache->new( next => undef );

    my $result = $plugin->find_one( 'TestClass', -cache_for => '10m', );
    isa_ok $result, 'TestClass', 'find_one: result';
}

sub test_serialize_key {
    my $query1 = {
        a => 1,
        b => 2,
        c => { a => 1, b => 2, c => 3 },
        d => [ 1, 2, 3 ]
    };

    my $query2 = {
        c => { b => 2, c => 3, a => 1 },
        b => 2,
        d => [ 1, 2, 3 ],
        a => 1,
    };

    my $query3 = {
        c => { b => 2, c => 3, a => 2 },
        b => 2,
        d => [ 1, 2, 3 ],
        a => 1,
    };

    my $key1 = Gideon::Plugin::Cache->_serialize_key( __PACKAGE__, $query1 );
    my $key2 = Gideon::Plugin::Cache->_serialize_key( __PACKAGE__, $query2 );
    my $key3 = Gideon::Plugin::Cache->_serialize_key( __PACKAGE__, $query3 );

    ok $key1,   'Not empty key';
    is $key1,   $key2, 'same query cache key';
    isnt $key1, $key3, 'different query cache key';
}

1;
