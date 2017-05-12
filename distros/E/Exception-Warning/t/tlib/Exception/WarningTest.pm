package Exception::WarningTest;

use strict;
use warnings;

use Test::Unit::Lite;
use parent 'Test::Unit::TestCase';
use Test::Assert ':all';

use Exception::Warning '%SIG';

sub test___isa {
    my $obj = Exception::Warning->new;
    assert_not_null($obj);
    assert_isa('Exception::Warning', $obj);
};

sub test_attribute {
    $@ = '';
    my $obj = Exception::Warning->new( message=>'Message' );
    assert_equals('Message', $obj->{message});
    assert_null($obj->{warning});
};

sub test_accessor {
    my $obj = Exception::Warning->new( message=>'Message' );
    assert_equals('Message', $obj->message);
    assert_equals('New message', $obj->message = 'New message');
    assert_equals('New message', $obj->message);
    assert_null($obj->warning);
    assert_raises( qr/modify non-lvalue subroutine call/, sub {
        $obj->warning = 123;
    } );
};

sub test_warn_die {
    local $SIG{__WARN__} = \&Exception::Warning::__DIE__;

    {
        eval { warn "Boom1"; };

        my $obj = $@;
        assert_not_null($obj);
        assert_isa('Exception::Warning', $obj);
        assert_null($obj->{message});
        assert_equals('Boom1', $obj->{warning});
    };

    {
        eval { warn "Boom2\n"; };

        my $obj = $@;
        assert_not_null($obj);
        assert_isa('Exception::Warning', $obj);
        assert_null($obj->{message});
        assert_equals('Boom2', $obj->{warning});
    };

    {
        eval { $@ = "Boom3\n"; warn; };

        my $obj = $@;
        assert_not_null($obj);
        assert_isa('Exception::Warning', $obj);
        assert_null($obj->{message});
        assert_equals('Boom3', $obj->{warning});
    };

    {
        eval { $@ = "Boom4\n\t...propagated at -e line 1.\n"; warn; };

        my $obj = $@;
        assert_not_null($obj);
        assert_isa('Exception::Warning', $obj);
        assert_null($obj->{message});
        assert_equals('Boom4', $obj->{warning});
    };

    {
        eval { $@ = "Boom5\n\t...propagated at -e line 1.\n\t...propagated at -e line 1.\n"; warn; };

        my $obj = $@;
        assert_not_null($obj);
        assert_isa('Exception::Warning', $obj);
        assert_null($obj->{message});
        assert_equals('Boom5', $obj->{warning});
    };
};

sub test_to_string {
    {
        my $obj = Exception::Warning->new( message => 'Message', verbosity => 0 );
        assert_equals('', $obj->to_string);
    };
    {
        my $obj = Exception::Warning->new( message => 'Message', verbosity => 1 );
        assert_equals("Message\n", $obj->to_string);
    };
    {
        my $obj = Exception::Warning->new( message => 'Message', verbosity => 2 );
        assert_matches(qr/Message at .* line \d+.\n/s, $obj->to_string);
    };
    {
        my $obj = Exception::Warning->new( message => 'Message', verbosity => 3 );
        assert_matches(qr/Exception::Warning: Message at .* line \d+\n/s, $obj->to_string);
    };

    {
        my $obj = Exception::Warning->new( message => 'Message', verbosity => 0 );
        $obj->{warning} = 'Error';
        assert_equals('', $obj->to_string);
    };
    {
        my $obj = Exception::Warning->new( message => 'Message', verbosity => 1 );
        $obj->{warning} = 'Error';
        assert_equals("Message: Error\n", $obj->to_string);
    };
    {
        my $obj = Exception::Warning->new( message => 'Message', verbosity => 2 );
        $obj->{warning} = 'Error';
        assert_matches(qr/Message: Error at .* line \d+.\n/s, $obj->to_string);
    };
    {
        my $obj = Exception::Warning->new( message => 'Message', verbosity => 3 );
        $obj->{warning} = 'Error';
        assert_matches(qr/Exception::Warning: Message: Error at .* line \d+\n/s, $obj->to_string);
    };

    {
        my $obj = Exception::Warning->new( message => 'Message', verbosity => 1 );
        assert_equals("Message\n", "$obj");
    };
};

sub test_import_keywords {
    local $SIG{__WARN__};

    assert_equals('', ref $SIG{__WARN__});

    Exception::Warning->import('%SIG');
    assert_equals('CODE', ref $SIG{__WARN__});

    Exception::Warning->unimport('%SIG');
    assert_equals('', ref $SIG{__WARN__});

    Exception::Warning->import('%SIG' => 'die');
    assert_equals('CODE', ref $SIG{__WARN__});

    Exception::Warning->unimport('%SIG' => 'die');
    assert_equals('', ref $SIG{__WARN__});

    Exception::Warning->import('%SIG' => 'warn');
    assert_equals('CODE', ref $SIG{__WARN__});

    Exception::Warning->unimport('%SIG' => 'warn');
    assert_equals('', ref $SIG{__WARN__});

    assert_raises( qr/can only be created with/, sub {
        Exception::Warning->import('Exception::Warning::test::Import1');
    } );

    assert_raises( qr/can only be created with/, sub {
        Exception::Warning->import('Exception::Warning::test::Import1' => { has => 'attr' });
    } );

    assert_raises( qr/can only be created with/, sub {
        Exception::Warning->import('Exception::Warning::test::Import1' => '%SIG');
    } );
};

1;
