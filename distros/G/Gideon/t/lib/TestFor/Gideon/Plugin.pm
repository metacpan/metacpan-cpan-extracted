package TestFor::Gideon::Plugin;
use Test::Class::Moose;
use Test::MockObject;

with 'Test::Class::Moose::Role::AutoUse';

sub test_setup {
    my $self = shift;

    $self->{mock} = Test::MockObject->new;
    $self->{mock}->fake_module(
        'MyDriver',
        find     => sub { die },
        find_one => sub { die },
        remove   => sub { die },
        update   => sub { die },
        save     => sub { die }
    );

    $self->{plugin} = Gideon::Plugin->new( next => 'MyDriver' );
}

sub test_dispatch_find {
    my $self = shift;

    $self->{mock}
      ->fake_module( 'MyDriver', find => sub { ok 1, 'find: dispatched' } );
    $self->{plugin}->find;
}

sub test_dispatch_find_one {
    my $self = shift;

    $self->{mock}->fake_module( 'MyDriver',
        find_one => sub { ok 1, 'update: dispatched' } );
    $self->{plugin}->find_one;
}

sub test_dispatch_remove {
    my $self = shift;

    $self->{mock}
      ->fake_module( 'MyDriver', remove => sub { ok 1, 'remove: dispatched' } );
    $self->{plugin}->remove;
}

sub test_dispatch_save {
    my $self = shift;

    $self->{mock}
      ->fake_module( 'MyDriver', save => sub { ok 1, 'save: dispatched' } );
    $self->{plugin}->save;
}

sub test_dispatch_update {
    my $self = shift;

    $self->{mock}
      ->fake_module( 'MyDriver', update => sub { ok 1, 'update: dispatched' } );
    $self->{plugin}->update;
}

1;
