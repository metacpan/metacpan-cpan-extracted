package Hash::Storage::AutoTester;

our $VERSION = '0.03';

use strict;
use warnings;
use v5.10;

use Test::More;
use Test::Deep;

sub new {
    my $class = shift;
    my %args  = @_;

    my $st = $args{storage};
    die "WRONG STORAGE" unless $st && $st->isa('Hash::Storage');

    return bless { storage => $st }, $class;
}

sub run {
    my $self = shift;
    $self->test_get();
    $self->test_set();
    $self->test_del();
    $self->test_list();
    $self->test_count();
}

sub test_get {
    my $self = shift;
    my $st = $self->{storage};

    my %user1 = (
        fname  => 'Ivan',
        lname  => 'Ivanov',
        age    => '21',
        gender => 'male'
    );

    my %user2 = (
        fname  => 'Taras',
        lname  => 'Schevchenko',
        age    => '64',
        gender => 'male'
    );

    subtest 'Getting users' => sub {
        ok( $st->set('user1', {%user1}), 'should create "user1" and return true' );
        ok( $st->set('user2', {%user2}), 'should create "user2" and return true' );

        cmp_deeply($st->get('user1'), {%user1, _id => 'user1'}, 'should return "user1" attrs');
        cmp_deeply($st->get('user2'), {%user2, _id => 'user2'}, 'should return "user2" attrs');
    };
}


sub test_set {
    my $self = shift;
    my $st = $self->{storage};

    my %user1 = (
        fname  => 'Ivan',
        lname  => 'Ivanov',
        age    => '21',
        gender => 'male'
    );


    subtest 'Set and Update user' => sub {
        ok( $st->set('user1', {%user1}), 'should create "user1" and return true' );
        cmp_deeply($st->get('user1'), {%user1, _id => 'user1'}, 'should return "user1" attrs');

        ok( $st->set('user1', {lname => 'NewLname', age => 33}), 'should update "user1" and return true' );
        my $updated_user = $st->get('user1');

        is( $updated_user->{_id},  'user1',     '_id should should contain object id');
        is( $updated_user->{fname},  'Ivan',     'fname should be the same as before');
        is( $updated_user->{lname},  'NewLname', 'lname should contain new value - "NewLname"');
        is( $updated_user->{age},    '33',       'age should contain new value - "33"');
        is( $updated_user->{gender}, 'male',     'gender should be the same as before');
    };
}

sub test_del {
    my $self = shift;
    my $st = $self->{storage};

    my %user1 = (
        fname  => 'Ivan',
        lname  => 'Ivanov',
        age    => '21',
        gender => 'male'
    );

    my %user2 = (
        fname  => 'Taras',
        lname  => 'Schevchenko',
        age    => '64',
        gender => 'male'
    );

    subtest 'Deleting users' => sub {
        ok( $st->set('user1', {%user1}), 'should create "user1" and return true' );
        ok( $st->set('user2', {%user2}), 'should create "user2" and return true' );

        ok( $st->del('user1'), 'should delete "user1" and return true' );

        ok( !$st->get('user1'), 'should return undef because "user1" was deleted');
        cmp_deeply($st->get('user2'), {%user2,  _id => 'user2'}, 'should return not deleted "user2"');

        ok( $st->del('user2'), 'should delete "user2" and return true' );
        ok( !$st->get('user1'), 'should return undef because "user2" was deleted');
    };
}


sub test_list {
    my $self = shift;
    my $st = $self->{storage};

    my %user1 = (
        fname  => 'Ivan',
        lname  => 'Ivanov',
        age    => '30',
        gender => 'male'
    );

    my %user2 = (
        fname  => 'Taras',
        lname  => 'Leleka',
        age    => '64',
        gender => 'male'
    );

    my %user3 = (
        fname  => 'Taras',
        lname  => 'Schevchenko',
        age    => '22',
        gender => 'male'
    );

    my %user4 = (
        fname  => 'Petrik',
        lname  => 'Pyatochkin',
        age    => '8',
        gender => 'male'
    );

    my %user5 = (
        fname  => 'Lesya',
        lname  => 'Ukrainka',
        age    => '30',
        gender => 'female'
    );

    $st->set('user1', {%user1});
    $user1{_id} = 'user1';

    $st->set('user2', {%user2});
    $user2{_id} = 'user2';

    $st->set('user3', {%user3});
    $user3{_id} = 'user3';

    $st->set('user4', {%user4});
    $user4{_id} = 'user4';

    $st->set('user5', {%user5});
    $user5{_id} = 'user5';

    subtest 'List users' => sub {
        cmp_bag($st->list(), [\%user1, \%user2, \%user3, \%user4, \%user5], 'should return all users');
        cmp_bag($st->list([fname => 'Ivan']), [\%user1], 'simple query should return user with fname="Ivan" users');
        cmp_bag($st->list([fname => ['Ivan']]), [\%user1], 'should return user with fname="Ivan" users');
        cmp_bag($st->list( where => [
            fname => ['Ivan', 'Taras', 'Petrik', 'Lesya'],
            age => {'>=' => 30 },
            gender => { 'like' => 'ma%' },
        ]), [\%user2, \%user1], 'complex query should return "Ivan" and "Taras" ');

        cmp_deeply($st->list(
            where => [
                fname => ['Ivan', 'Taras', 'Petrik', 'Lesya'],
                age => {'>=' => 30 },
            ],
            sort_by => 'age DESC, fname ASC',
        ), [\%user2, \%user1, \%user5], 'complex query with sort should return "Ivan" "Taras" ');
    };
}

sub test_count {
    my $self = shift;
    my $st = $self->{storage};

    my %user1 = (
        fname  => 'Ivan',
        lname  => 'Ivanov',
        age    => '30',
        gender => 'male'
    );

    my %user2 = (
        fname  => 'Taras',
        lname  => 'Leleka',
        age    => '64',
        gender => 'male'
    );

    my %user3 = (
        fname  => 'Taras',
        lname  => 'Schevchenko',
        age    => '22',
        gender => 'male'
    );

    my %user4 = (
        fname  => 'Petrik',
        lname  => 'Pyatochkin',
        age    => '8',
        gender => 'male'
    );

    my %user5 = (
        fname  => 'Lesya',
        lname  => 'Ukrainka',
        age    => '30',
        gender => 'female'
    );

    $st->set('user1', {%user1});
    $st->set('user2', {%user2});
    $st->set('user3', {%user3});
    $st->set('user4', {%user4});
    $st->set('user5', {%user5});

    subtest 'Count users' => sub {
        is($st->count(), 5, 'should return 5 ');
        is($st->count([fname => 'Ivan']), 1, 'should return 1');
        is($st->count([fname => ['Ivan']]), 1, 'should return 1');
        is($st->count( [
            fname => ['Ivan', 'Taras', 'Petrik', 'Lesya'],
            age => {'>=' => 30 },
            gender => { 'like' => 'ma%' },
        ]), 2, 'complex query: should return 2');

        is($st->count( [
            fname => ['Ivan', 'Taras', 'Petrik', 'Lesya'],
            age => {'>=' => 30 },
        ]), 3, 'complex query: should return 3 ');
    };
}

1;
