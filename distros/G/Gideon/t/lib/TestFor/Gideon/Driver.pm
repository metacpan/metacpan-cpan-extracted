package TestFor::Gideon::Driver;
use Test::Class::Moose;
use Test::Exception;
use TestClass;
use MooseX::Test::Role;

with 'Test::Class::Moose::Role::AutoUse';

sub test_find {
    my $fake_driver = consumer_of(
        'Gideon::Driver',
        _find => sub {
            is $_[1], 'TestClass', 'find: target';
            is_deeply $_[2], { id   => 1 },    'find: filter';
            is_deeply $_[3], { desc => 'id' }, 'find: order';
            return [ TestClass->new ];
        }
    );

    $fake_driver->find(
        'TestClass',
        id     => 1,
        -order => { desc => 'id' }
    );
}

sub test_find_one {
    my $fake_driver = consumer_of(
        'Gideon::Driver',
        _find => sub {
            is $_[1], 'TestClass', 'find_one: target';
            is $_[4], 1,           'find_one: limit';
            is_deeply $_[3], { asc => 'id' }, 'find_one: order';
            is_deeply $_[2], { name => { like => 'john' } }, 'find_one: filter';
            return [ TestClass->new ];
        }
    );

    $fake_driver->find_one(
        'TestClass',
        name   => { like => 'john' },
        -order => { asc  => 'id' },
    );
}

sub test_update_object {
    my $fake_driver = consumer_of(
        'Gideon::Driver',
        _update        => sub { die },
        _update_object => sub {
            isa_ok $_[1], 'TestClass', 'update: target class';
            is_deeply $_[2], { id => 2 }, 'update: changes';
            1;
        }
    );

    my $object = TestClass->new( id => 1 );

    throws_ok { $fake_driver->update( $object, id => 2 ) }
    'Gideon::Exception::ObjectNotInStore', 'update: not persited';

    my $result;
    $object->__is_persisted(1);
    lives_ok { $result = $fake_driver->update( $object, id => 2 ) }
    'update: persited';
    is $result, $object, 'update: returned target';
}

sub test_update_class {
    my $fake_driver = consumer_of(
        'Gideon::Driver',
        _update_object => sub { die },
        _update        => sub {
            is $_[1], 'TestClass', 'update: target';
            is_deeply $_[2], { name => 'charles' }, 'update: changes';
            1;
        }
    );

    my $result = $fake_driver->update( 'TestClass', name => 'charles' );
    is $result, 'TestClass', 'update: returned target';
}

sub test_update_failure {
    my $fake_driver = consumer_of(
        'Gideon::Driver',
        _update        => sub { die },
        _update_object => sub {
            isa_ok $_[1], 'TestClass', 'update: target class';
            is_deeply $_[2], { id => 2 }, 'update: changes';
            undef;
        }
    );

    my $object = TestClass->new( id => 1, __is_persisted => 1 );
    my $result = $fake_driver->update( $object, id => 2 );
    is $result, undef, 'update: returned undef';
}

sub test_save_new {
    my $fake_driver = consumer_of(
        'Gideon::Driver',
        _update_object => sub { die },
        _insert_object => sub {
            isa_ok $_[1], 'TestClass', 'save: target class';
            1;
        }
    );

    my $object = TestClass->new;
    my $result = $fake_driver->save($object);
    is $result, $object, 'save: returned target';
}

sub test_save_modified {
    my $fake_driver = consumer_of(
        'Gideon::Driver',
        _insert_object => sub { die },
        _update_object => sub {
            isa_ok $_[1], 'TestClass', 'save: target class';
        }
    );

    my $object = TestClass->new( __is_persisted => 1 );
    my $result = $fake_driver->save($object);
    is $result, $object, 'save: returned target';
}

sub test_save_failure {
    my $fake_driver = consumer_of(
        'Gideon::Driver',
        _insert_object => sub { die },
        _update_object => sub {
            isa_ok $_[1], 'TestClass', 'save: target class';
            undef;
        }
    );

    throws_ok { $fake_driver->save('TestClass') }
    'Gideon::Exception::InvalidOperation', 'save: not persisted';

    my $object = TestClass->new( __is_persisted => 1 );
    my $result = $fake_driver->save($object);
    is $result, undef, 'save: returned undef';
}

sub test_remove_object {
    my $fake_driver = consumer_of(
        'Gideon::Driver',
        _remove        => sub { die },
        _remove_object => sub {
            isa_ok $_[1], 'TestClass', 'remove: target class';
            1;
        }
    );

    my $object = TestClass->new( __is_persisted => 1 );
    my $result = $fake_driver->remove($object);
    is $result, $object, 'remove: returned target';
}

sub test_remove_class {
    my $fake_driver = consumer_of(
        'Gideon::Driver',
        _remove_object => sub { die },
        _remove        => sub {
            is $_[1], 'TestClass', 'remove: target';
            is_deeply $_[2], { id => 2 }, 'remove: query';
            1;
        }
    );

    my $result = $fake_driver->remove( 'TestClass', id => 2 );
    is $result, 'TestClass', 'remove: returned target';
}

sub test_remove_failure {
    my $fake_driver = consumer_of(
        'Gideon::Driver',
        _remove_object => sub { die },
        _remove        => sub {
            is $_[1], 'TestClass', 'remove: target';
            undef;
        }
    );

    my $result = $fake_driver->remove('TestClass');
    is $result, undef, 'remove: returned undef';
}

1;
