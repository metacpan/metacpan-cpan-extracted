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
    query email_length => (
        select      => __PACKAGE__->_BuildEmailLengthSelect(),
        bind_params => sub { $_[0]->user_id() },
    );

    query user_ids => (
        select => __PACKAGE__->_BuildUserIdsSelect(),
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
    my $meth = User->meta()->get_method('email_length');
    isa_ok(
        $meth, 'Fey::Meta::Method::FromSelect',
        'email_length meta-method'
    );

    ## no critic (Subroutines::ProtectPrivateSubs)
    is(
        $meth->select()->sql('Fey::FakeDBI'),
        User->_BuildEmailLengthSelect()->sql('Fey::FakeDBI'),
        'select for query method is the expected SQL'
    );
    ## use critic

    my $user = User->new( user_id => 42 );
    is(
        $meth->bind_params()->($user), 42,
        'bind_params subroutine reference returns user_id'
    );
}

{
    my $meth = User->meta()->get_method('user_ids');
    isa_ok(
        $meth, 'Fey::Meta::Method::FromSelect',
        'user_ids meta-method'
    );

    ## no critic (Subroutines::ProtectPrivateSubs)
    is(
        $meth->select()->sql('Fey::FakeDBI'),
        User->_BuildUserIdsSelect()->sql('Fey::FakeDBI'),
        'select for method is the expected SQL'
    );
    ## use critic;

    ok(
        !$meth->bind_params(),
        'method has no associated bind_params sub ref'
    );
}

done_testing();
