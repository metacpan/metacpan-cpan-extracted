package TestFor::Gideon::Plugin::ResultSet;
use Test::Class::Moose;
use Test::MockObject;

with 'Test::Class::Moose::Role::AutoUse';

sub test_find_scalar_context {
    my $fake_driver = Test::MockObject->new;
    my $plugin = Gideon::Plugin::ResultSet->new( next => $fake_driver );

    my %query = ( id => { '!=' => 1 } );
    my $result_set = $plugin->find( 'TestClass', %query );

    isa_ok $result_set, 'Gideon::ResultSet', 'find: returned set';
    is $result_set->driver, $fake_driver, 'set: driver';
    is $result_set->target, 'TestClass', 'set: target';
    is_deeply $result_set->query, \%query, 'set: query';
}

sub test_find_array_context {
    my $fake_driver = Test::MockObject->new->mock( find => sub { [1] } );
    my $plugin = Gideon::Plugin::ResultSet->new( next => $fake_driver );

    my %query = ( id => { '!=' => 1 } );
    my @result_set = $plugin->find( 'TestClass', %query );

    is scalar @result_set, 1, 'find: returned values';
}

1;
