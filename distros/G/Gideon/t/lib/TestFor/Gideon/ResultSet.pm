package TestFor::Gideon::ResultSet;
use Test::Class::Moose;

with 'Test::Class::Moose::Role::AutoUse';

sub test_combine {
    my $set = Gideon::ResultSet->new(
        driver => undef,
        target => undef,
        query  => { id => { '!=' => 1 } }
    );

    my $set2 = $set->find( id => { '!=' => 2 } );
    is_deeply $set2->query,
      { id => [ -and => { '!=' => 1 }, { '!=' => 2 } ] },
      'set: combined #1';

    my $set3 = $set->find( name => { like => 'joe' } );
    is_deeply $set3->query,
      { id => { '!=' => 1 }, name => { like => 'joe' } },
      'set: combined #2';
}

1;
