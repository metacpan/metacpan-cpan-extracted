use strict;
use warnings;

use Test::More 0.88;

use lib 't/lib';

use Fey::FakeDBI;
use Fey::ORM::Test;
use Fey::Literal::Function;

Fey::ORM::Test::define_live_classes();
Fey::ORM::Test::insert_user_data();

{
    package User;

    use Fey::ORM::Table;

    ## no critic (Subroutines::ProtectPrivateSubs)
    has email_length => (
        metaclass   => 'FromSelect',
        is          => 'ro',
        isa         => 'Int',
        select      => __PACKAGE__->_BuildEmailLengthSelect(),
        bind_params => sub { $_[0]->user_id() },
    );

    has user_ids => (
        metaclass => 'FromSelect',
        is        => 'ro',
        isa       => 'ArrayRef',
        select    => __PACKAGE__->_BuildUserIdsSelect(),
    );
    ## use critic

    sub _BuildEmailLengthSelect {
        my $class = shift;

        my $schema = Schema->Schema();

        my $length = Fey::Literal::Function->new(
            'LENGTH',
            $class->Table()->column('email')
        );
        $length->set_alias_name('email_length');

        my $select = Schema->SQLFactoryClass()->new_select();

        $select->select($length)->from( $class->Table() )->where(
            $class->Table()->column('user_id'), '=',
            Fey::Placeholder->new()
        );

        return $select;
    }

    sub _BuildUserIdsSelect {
        my $class = shift;

        my $schema = Schema->Schema();

        my $select = Schema->SQLFactoryClass()->new_select();

        $select->select( $class->Table()->column('user_id') )
            ->from( $class->Table() )
            ->order_by( $class->Table()->column('user_id') );

        return $select;
    }
}

{
    my $user = User->new( user_id => 1 );
    is(
        $user->email_length(), length $user->email(),
        'email_length accessor gets the right value'
    );
    is_deeply(
        $user->user_ids(), [ 1, 42 ],
        'user_ids returns an arrayref with the expected values'
    );
}

{
    my $attr = User->meta()->get_attribute('email_length');
    isa_ok(
        $attr, 'Fey::Meta::Attribute::FromSelect',
        'email_length meta-attr'
    );

    ## no critic (Subroutines::ProtectPrivateSubs)
    is(
        $attr->select()->sql('Fey::FakeDBI'),
        User->_BuildEmailLengthSelect()->sql('Fey::FakeDBI'),
        'select for attr is the expected SQL'
    );
    ## use critic;

    my $user = User->new( user_id => 42 );
    is(
        $attr->bind_params()->($user), 42,
        'bind_params subroutine reference returns user_id'
    );
}

{
    my $attr = User->meta()->get_attribute('user_ids');
    isa_ok(
        $attr, 'Fey::Meta::Attribute::FromSelect',
        'user_ids meta-attr'
    );

    ## no critic (Subroutines::ProtectPrivateSubs)
    is(
        $attr->select()->sql('Fey::FakeDBI'),
        User->_BuildUserIdsSelect()->sql('Fey::FakeDBI'),
        'select for attr is the expected SQL'
    );
    ## use critic

    ok( !$attr->bind_params(), 'attr has no associated bind_params sub ref' );
}

done_testing();
