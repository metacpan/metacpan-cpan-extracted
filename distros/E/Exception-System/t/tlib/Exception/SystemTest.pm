package Exception::SystemTest;

use strict;
use warnings;

use base 'Test::Unit::TestCase';

use Exception::System;

use Errno ();

our $ENOENT;

sub set_up {
    $! = Errno::ENOENT;
    $ENOENT = $!;
    $! = 0;
}

sub test___isa {
    my $self = shift;
    my $obj = Exception::System->new;
    $self->assert_not_null($obj);
    $self->assert($obj->isa("Exception::System"), '$obj->isa("Exception::System")');
    $self->assert($obj->isa("Exception::Base"), '$obj->isa("Exception::Base")');
}

sub test_attribute {
    my $self = shift;
    local $!;
    my $obj = Exception::System->new(message=>'Message');
    $self->assert_equals('Message', $obj->{message});
    $self->assert_equals(0, $obj->{errno});
}

sub test_accessor {
    my $self = shift;
    local $!;
    my $obj = Exception::System->new(message=>'Message');
    $self->assert_equals('Message', $obj->message);
    $self->assert_equals('New message', $obj->message = 'New message');
    $self->assert_equals('New message', $obj->message);
    $self->assert_equals(0, $obj->errno);
    eval { $self->assert_equals(0, $obj->errno = 123) };
    $self->assert_matches(qr/modify non-lvalue subroutine call/, $@);
}

sub test_collect_system_data {
    my $self = shift;
    
    eval {
        eval { 1; };

        my $obj = Exception::System->new(message=>'Collect');
        $self->assert_not_null($obj);
        $self->assert($obj->isa("Exception::Base"), '$obj->isa("Exception::Base")');
        $self->assert_equals('Collect', $obj->{message});
        $self->assert_not_null($obj->{errstr});
        $self->assert_not_null($obj->{errstros});
        $self->assert_not_null($obj->{errname});
        $self->assert_not_null($obj->{errno});

        $obj->{errno} = 666;
        eval { 1; };
        $obj->_collect_system_data;
        $self->assert_equals(0, $obj->{errno});
    };
    die "$@" if $@;
}

sub test_throw {
    my $self = shift;

    # Secure with eval
    eval {
        # Simple throw
        eval {
            open FILE, "filenotfound.$$";
            Exception::System->throw;
        };
        my $obj1 = $@;
        $self->assert_not_null($obj1);
        $self->assert($obj1->isa("Exception::System"), '$obj1->isa("Exception::System")');
        $self->assert($obj1->isa("Exception::Base"), '$obj1->isa("Exception::Base")');
        $obj1->verbosity = 1;
        $self->assert_equals("$ENOENT\n", $obj1->to_string);
        $self->assert($obj1->{errstr});
        $self->assert_equals('ENOENT', $obj1->{errname});
        $self->assert_equals(__PACKAGE__ . '::test_throw', $obj1->{caller_stack}->[3]->[3]);
        $self->assert(ref $self, ref $obj1->{caller_stack}->[3]->[8]);

        # Rethrow
        eval {
            chdir $0;
            $obj1->throw;
        };
        my $obj2 = $@;
        $self->assert_not_null($obj2);
        $self->assert($obj2->isa("Exception::System"), '$obj2->isa("Exception::System")');
        $self->assert($obj2->isa("Exception::Base"), '$obj2->isa("Exception::Base")');
        $self->assert_null($obj2->{message});
        $self->assert($obj2->{errstr});
        $self->assert_equals('ENOENT', $obj2->{errname});
        $self->assert_equals(__PACKAGE__ . '::test_throw', $obj2->{caller_stack}->[3]->[3]);
        $self->assert_equals(ref $self, ref $obj2->{caller_stack}->[3]->[8]);
    };
    die "$@" if $@;
}

sub test_with {
    my $self = shift;

    my $obj1 = Exception::System->new(message=>'Message');
    $obj1->{errstr} = 'Errstr';
    $obj1->{errno} = 123;
    $self->assert_num_equals(0, $obj1->matches(undef));
    $self->assert_num_equals(0, $obj1->matches({message=>undef}));
    $self->assert_num_equals(1, $obj1->matches('Message: Errstr'));
    $self->assert_num_equals(1, $obj1->matches(123));
    $self->assert_num_equals(1, $obj1->matches({message=>'Message'}));
    $self->assert_num_equals(0, $obj1->matches({errstr=>undef}));
    $self->assert_num_equals(1, $obj1->matches({errstr=>'Errstr'}));
    $self->assert_num_equals(1, $obj1->matches({errstr=>sub {/Errstr/}}));
    $self->assert_num_equals(0, $obj1->matches({errstr=>sub {/false/}}));
    $self->assert_num_equals(1, $obj1->matches({errstr=>qr/Errstr/}));
    $self->assert_num_equals(0, $obj1->matches({errstr=>qr/false/}));
    $self->assert_num_equals(1, $obj1->matches({errno=>123}));
}

sub test_to_string {
    my $self = shift;

    my $obj = Exception::System->new(message=>'Stringify');

    $self->assert_not_null($obj);
    $self->assert($obj->isa("Exception::System"), '$obj->isa("Exception::System")');
    $self->assert($obj->isa("Exception::Base"), '$obj->isa("Exception::Base")');
    $obj->verbosity = 0;
    $self->assert_equals('', $obj->to_string);
    $obj->verbosity = 1;
    $self->assert_equals("Stringify\n", $obj->to_string);
    $obj->verbosity = 2;
    $self->assert_matches(qr/Stringify at .* line \d+.\n/s, $obj->to_string);
    $obj->verbosity = 3;
    $self->assert_matches(qr/Exception::System: Stringify at .* line \d+\n/s, $obj->to_string);

    $obj->{errstr} = 'Error';
    $obj->verbosity = 0;
    $self->assert_equals('', $obj->to_string);
    $obj->verbosity = 1;
    $self->assert_equals("Stringify: Error\n", $obj->to_string);
    $obj->verbosity = 2;
    $self->assert_matches(qr/Stringify: Error at .* line \d+.\n/s, $obj->to_string);
    $obj->verbosity = 3;
    $self->assert_matches(qr/Exception::System: Stringify: Error at .* line \d+\n/s, $obj->to_string);

    $obj->verbosity = undef;
    $self->assert_equals(1, $obj->{defaults}->{verbosity} = 1);
    $self->assert_equals(1, $obj->{defaults}->{verbosity});
    $self->assert_equals("Stringify: Error\n", $obj->to_string);
    $self->assert_not_null($obj->{defaults}->{verbosity});
    $obj->{defaults}->{verbosity} = Exception::System->ATTRS->{verbosity}->{default};
    $self->assert_equals(1, $obj->{verbosity} = 1);
    $self->assert_equals("Stringify: Error\n", $obj->to_string);

    $self->assert_equals("Stringify: Error\n", "$obj");
}

sub test_to_number {
    my $self = shift;

    my $obj = Exception::System->new;
    $obj->{errno} = 123;    

    $self->assert_num_equals(123, $obj->to_number);
    $self->assert_num_equals(123, 0+$obj);
}

1;
