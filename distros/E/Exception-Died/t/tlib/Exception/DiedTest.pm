package Exception::DiedTest;

use strict;
use warnings;

use Test::Unit::Lite;
use parent 'Test::Unit::TestCase';
use Test::Assert ':all';

use Exception::Died;

use Carp;

sub test___isa {
    $@ = '';
    my $obj = Exception::Died->new;
    assert_not_null($obj);
    assert_isa('Exception::Died', $obj);
};

sub test_attribute {
    $@ = '';
    my $obj = Exception::Died->new( message=>'Message' );
    assert_equals('Message', $obj->{message});
    assert_null($obj->{eval_error});
};

sub test_accessor {
    $@ = '';
    my $obj = Exception::Died->new( message=>'Message' );
    assert_equals('Message', $obj->message);
    assert_equals('New message', $obj->message = 'New message');
    assert_equals('New message', $obj->message);
    assert_null($obj->eval_error);
    assert_raises( qr/modify non-lvalue subroutine call/, sub {
        $obj->eval_error = 123;
    } );
};

sub test_collect_system_data_die {
    $@ = '';

    eval {
        die "Die";
    };

    my $obj = Exception::Died->new( message => 'Message' );
    assert_isa('Exception::Died', $obj);
    assert_equals('Message', $obj->{message});
    assert_equals('Die', $obj->{eval_error});
};

sub test_collect_system_data_die_with_eol {
    $@ = '';

    eval {
        die "Die\n";
    };

    my $obj = Exception::Died->new( message => 'Message' );
    assert_isa('Exception::Died', $obj);
    assert_equals('Message', $obj->{message});
    assert_equals('Die', $obj->{eval_error});
};

sub test_collect_system_data_throw {
    $@ = '';

    eval {
        Exception::Died->throw( message => 'Throw' );
    };

    my $obj = Exception::Died->new( message => 'Message' );
    assert_isa('Exception::Died', $obj);
    assert_equals('Message', $obj->{message});
    assert_null($obj->{eval_error});
};

sub test_collect_system_data_die_nested {
    $@ = '';

    eval {
        eval {
            die "Die\n";
        };
        die;
    };

    my $obj = Exception::Died->new( message => 'Message' );
    assert_isa('Exception::Died', $obj);
    assert_equals('Message', $obj->{message});
    assert_equals('Die', $obj->{eval_error});
};

sub test_collect_system_data_die_nested2 {
    $@ = '';

    eval {
        eval {
            eval {
                die "Die\n";
            };
            die;
        };
        die;
    };

    my $obj = Exception::Died->new( message => 'Message');
    assert_isa('Exception::Died', $obj);
    assert_equals('Message', $obj->{message});
    assert_equals('Die', $obj->{eval_error});
};

sub test_to_string {
    {
        my $obj = Exception::Died->new( message => 'Message', verbosity => 0 );
        assert_equals('', $obj->to_string);
    };
    {
        my $obj = Exception::Died->new( message => 'Message', verbosity => 1 );
        assert_equals("Message\n", $obj->to_string);
    };
    {
        my $obj = Exception::Died->new( message => 'Message', verbosity => 2 );
        assert_matches(qr/Message at .* line \d+.\n/s, $obj->to_string);
    };
    {
        my $obj = Exception::Died->new( message => 'Message', verbosity => 3 );
        assert_matches(qr/Exception::Died: Message at .* line \d+\n/s, $obj->to_string);
    };

    {
        my $obj = Exception::Died->new( message => 'Message', verbosity => 0 );
        $obj->{eval_error} = 'Error';
        assert_equals('', $obj->to_string);
    };
    {
        my $obj = Exception::Died->new( message => 'Message', verbosity => 1 );
        $obj->{eval_error} = 'Error';
        assert_equals("Message: Error\n", $obj->to_string);
    };
    {
        my $obj = Exception::Died->new( message => 'Message', verbosity => 2 );
        $obj->{eval_error} = 'Error';
        assert_matches(qr/Message: Error at .* line \d+.\n/s, $obj->to_string);
    };
    {
        my $obj = Exception::Died->new( message => 'Message', verbosity => 3 );
        $obj->{eval_error} = 'Error';
        assert_matches(qr/Exception::Died: Message: Error at .* line \d+\n/s, $obj->to_string);
    };

    {
        my $obj = Exception::Died->new( message => 'Message', verbosity => 1 );
        assert_equals("Message\n", "$obj");
    };
}

sub test_throw {
    $@ = '';

    # Simple die hooked with Exception::Died::__DIE__
    {
        local $SIG{__DIE__};
        Exception::Died->import('%SIG' => 'die');

        eval {
            die 'Die1';
        };
    };
    my $obj1 = $@;
    assert_isa('Exception::Died', $obj1);
    assert_null($obj1->{message});
    assert_equals('Die1', $obj1->{eval_error});

    # Rethrow via object method
    eval {
        $obj1->throw( message => 'Message2' );
    };
    my $obj2 = $@;
    assert_isa('Exception::Died', $obj2);
    assert_equals('Message2', $obj2->{message});
    assert_equals('Die1', $obj2->{eval_error});

    # Rethrow via class method with object as argument
    eval {
        Exception::Died->throw( $obj2, message => 'Message3' );
    };
    my $obj3 = $@;
    assert_isa('Exception::Died', $obj3);
    assert_equals('Message3', $obj3->{message});
    assert_equals('Die1', $obj3->{eval_error});
};

sub test_throw_string {
    $@ = '';

    # Throw via class method with string as argument
    eval {
        Exception::Died->throw( 'String', message => 'Message' );
    };
    my $obj = $@;
    assert_isa('Exception::Died', $obj);
    assert_equals('Message', $obj->{message});
    assert_equals('String', $obj->{eval_error});
};

sub test_throw_object {
    $@ = '';

    # Rethrow via class method with object as argument
    my $obj1 = Exception::Base->new( message => 'Message1' );

    eval {
        Exception::Died->throw( $obj1, message => 'Message2' );
    };
    my $obj2 = $@;
    assert_isa('Exception::Died', $obj2);
    assert_equals('Message2', $obj2->{message});
    assert_null($obj2->{eval_error});
};

sub test_catch_die {
    $@ = '';

    # Simple die
    eval {
        die 'Message';
    };
    my $obj = Exception::Died->catch;
    assert_isa('Exception::Died', $obj);
    assert_null($obj->{message});
    assert_equals('Message', $obj->{eval_error});
};

sub test_catch_throw {
    $@ = '';

    # Exception
    eval {
        Exception::Died->throw( message => 'Message' );
    };
    my $obj = Exception::Died->catch;
    assert_isa('Exception::Died', $obj);
    assert_equals('Message', $obj->{message});
    assert_null($obj->{eval_error});
};

# Derived class exception
{
    package Exception::DiedTest::catch::Exception1;
    use parent 'Exception::Died';
};

{
    package Exception::DiedTest::catch::Exception2;
    use parent 'Exception::Died';
};

sub test_catch_derived_die {
    $@ = '';

    # Simple die with reblessing class
    eval {
        die 'Message';
    };
    my $obj = Exception::DiedTest::catch::Exception1->catch;
    assert_isa('Exception::DiedTest::catch::Exception1', $obj);
    assert_isa('Exception::Died', $obj);
    assert_null($obj->{message});
    assert_equals('Message', $obj->{eval_error});
};

sub test_catch_derived_throw {
    $@ = '';

    # Throw without reblessing class
    eval {
        Exception::Died->throw( message => 'Message' );
    };
    my $obj = Exception::DiedTest::catch::Exception1->catch;
    assert_not_isa('Exception::DiedTest::catch::Exception1', $obj);
    assert_isa('Exception::Died', $obj);
    assert_equals('Message', $obj->{message});
    assert_null($obj->{eval_error});
};

sub test_import_keywords {
    local $SIG{__DIE__};

    assert_equals('', ref $SIG{__DIE__});

    Exception::Died->import('%SIG');
    assert_equals('CODE', ref $SIG{__DIE__});

    Exception::Died->unimport('%SIG');
    assert_equals('', ref $SIG{__DIE__});

    Exception::Died->import('%SIG' => 'die');
    assert_equals('CODE', ref $SIG{__DIE__});

    Exception::Died->unimport('%SIG' => 'die');
    assert_equals('', ref $SIG{__DIE__});

    assert_raises( qr/can only be created with/, sub {
        Exception::Died->import('Exception::Died::test::Import1');
    } );

    assert_raises( qr/can only be created with/, sub {
        Exception::Died->import('Exception::Died::test::Import1' => { has => 'attr' });
    } );

    assert_raises( qr/can only be created with/, sub {
        Exception::Died->import('Exception::Died::test::Import1' => '%SIG');
    } );
};

1;
