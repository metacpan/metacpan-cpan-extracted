package TestFor::Gideon::Plugin::StrictMode;
use Test::Class::Moose;
use Test::MockObject;
use Test::Exception;

with 'Test::Class::Moose::Role::AutoUse';

sub test_setup {
    my $self = shift;
    $self->{mock} = Test::MockObject->new;
    $self->{plugin} = Gideon::Plugin::StrictMode->new( next => 'MyDriver' );
}

sub test_find {
    my $self = shift;

    my $plugin = $self->{plugin};

    $self->{mock}->fake_module( 'MyDriver', find => sub { [] } );
    lives_ok { $plugin->find } 'find: non-strict with empty set';
    throws_ok { $plugin->find( 'Class', -strict => 1 ) }
    'Gideon::Exception::NotFound', 'find: strict with empty set';

    $self->{mock}->fake_module( 'MyDriver', find => sub { [1] } );
    lives_ok { $plugin->find } 'Non-strict find';
    lives_ok { $plugin->find( 'Class', -strict => 1 ) } 'find: strict';
}

sub test_find_one {
    my $self = shift;

    my $plugin = $self->{plugin};

    $self->{mock}->fake_module( 'MyDriver', find_one => sub { undef } );
    lives_ok { $plugin->find_one } 'find_one: non-strict empty set';
    throws_ok { $plugin->find_one( 'Class', -strict => 1 ) }
    'Gideon::Exception::NotFound', 'find_one: strict with empty set';

    $self->{mock}->fake_module( 'MyDriver', find_one => sub { 1 } );
    lives_ok { $plugin->find_one } 'find_one: non-strict';
    lives_ok { $plugin->find_one( 'Class', -strict => 1 ) } 'find_one: strict';
}

sub test_update {
    my $self = shift;

    my $plugin = $self->{plugin};

    $self->{mock}->fake_module( 'MyDriver', update => sub { undef } );
    lives_ok { $plugin->update } 'update: failed non-strict';
    throws_ok { $plugin->update( 'Class', -strict => 1 ) }
    'Gideon::Exception::UpdateFailure', 'update: failed strict';

    $self->{mock}->fake_module( 'MyDriver', update => sub { 'Class' } );
    lives_ok { $plugin->update } 'update: non-strict';
    lives_ok { $plugin->update( 'TestClass', -strict => 1 ) } 'update: strict';
}

sub test_save {
    my $self = shift;

    my $plugin = $self->{plugin};

    $self->{mock}->fake_module( 'MyDriver', save => sub { undef } );
    lives_ok { $plugin->save } 'save: failed non-strict';
    throws_ok { $plugin->save( {}, -strict => 1 ) }
    'Gideon::Exception::SaveFailure', 'save: failed strict';

    $self->{mock}->fake_module( 'MyDriver', save => sub { {} } );
    lives_ok { $plugin->save } 'save: non-strict';
    lives_ok { $plugin->save( {}, -strict => 1 ) } 'save: strict';
}

sub test_remove {
    my $self = shift;

    my $plugin = $self->{plugin};

    $self->{mock}->fake_module( 'MyDriver', remove => sub { undef } );
    lives_ok { $plugin->remove } 'remove: failed non-strict';
    throws_ok { $plugin->remove( {}, -strict => 1 ) }
    'Gideon::Exception::RemoveFailure', 'remove: failed strict';

    $self->{mock}->fake_module( 'MyDriver', remove => sub { {} } );
    lives_ok { $plugin->remove } 'remove: non-strict';
    lives_ok { $plugin->remove( {}, -strict => 1 ) } 'remove: strict';
}

1;
