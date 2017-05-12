package Exception::BaseTest;

use strict;
use warnings;

use Test::Unit::Lite;
use base 'Test::Unit::TestCase';

use Exception::Base;

sub test___isa {
    my $self = shift;
    my $obj1 = Exception::Base->new;
    $self->assert_not_equals('', ref $obj1);
    $self->assert($obj1->isa("Exception::Base"), '$obj1->isa("Exception::Base")');
    my $obj2 = $obj1->new;
    $self->assert_not_equals('', ref $obj2);
    $self->assert($obj2->isa("Exception::Base"), '$obj2->isa("Exception::Base")');
}

sub test_new {
    my $self = shift;

    my $obj1 = Exception::Base->new;
    $self->assert_null($obj1->{message});

    my $obj2 = Exception::Base->new(message=>'Message');
    $self->assert_equals('Message', $obj2->{message});

    my $obj3 = Exception::Base->new(unknown=>'Unknown');
    $self->assert(! exists $obj3->{unknown}, '! exists $obj3->{unknown}');

    my $obj4 = Exception::Base->new(propagated_stack=>'Ignored');
    $self->assert_not_equals('Ignored', $obj4->{propagated_stack});
}

sub test_attribute {
    my $self = shift;
    my $obj = Exception::Base->new(message=>'Message');
    $self->assert_equals('Message', $obj->{message});
    $self->assert_equals($$, $obj->{pid});
}

sub test_accessor {
    my $self = shift;
    my $obj = Exception::Base->new(message=>'Message');
    $self->assert_equals('Message', $obj->message);
    $self->assert_equals('New Message', $obj->message('New Message'));
    $self->assert_equals('New Message', $obj->message);
    $self->assert_equals('Lvalue accessor Message', $obj->message = 'Lvalue accessor Message');
    $self->assert_equals('Lvalue accessor Message', $obj->message);
    $self->assert_equals($$, $obj->pid);
    eval { $obj->pid = 0 };
    $self->assert_matches(qr/modify non-lvalue subroutine call/, "$@");
}

sub test_accessor_message {
    my $self = shift;
    my $obj = Exception::Base->new(message=>'Message');
    $self->assert_equals('Message', $obj->message);
    $self->assert_equals('New Message', $obj->message('New Message'));
    $self->assert_equals('New Message', $obj->message);
    $self->assert_equals('Lvalue accessor Message', $obj->message = 'Lvalue accessor Message');
    $self->assert_equals('Lvalue accessor Message', $obj->message);
}

sub test_caller_stack_accessors {
    my $self = shift;
    my $obj = Exception::Base->new;
    $obj->{caller_stack} = [
        ['Package1', 'Package1.pm', 1, 'Package1::func1', 0, undef, undef, undef ],
        ['Package2', 'Package2.pm', 2, 'Package2::func2', 6, 1, undef, undef, 1, 2, 3, 4, 5, 6 ],
        ['Package3', 'Package3.pm', 3, 'Package3::func3', 2, 1, undef, undef, "123456789", "123456789" ],
        ['Package4', 'Package4.pm', 4, '(eval)', 0, undef, "123456789", undef ],
    ];

    $self->assert_equals('Package1', $obj->package);
    $self->assert_equals('Package1.pm', $obj->file);
    $self->assert_equals('1', $obj->line);
    $self->assert_equals('Package1::func1', $obj->subroutine);

    $obj->{ignore_level} = 1;

    $self->assert_equals('Package2', $obj->package);
    $self->assert_equals('Package2.pm', $obj->file);
    $self->assert_equals('2', $obj->line);
    $self->assert_equals('Package2::func2', $obj->subroutine);

    $obj->{ignore_package} = 'Package1';

    $self->assert_equals('Package3', $obj->package);
    $self->assert_equals('Package3.pm', $obj->file);
    $self->assert_equals('3', $obj->line);
    $self->assert_equals('Package3::func3', $obj->subroutine);
}

sub test_throw {
    my $self = shift;

    local $SIG{__DIE__};

    # Simple throw
    eval {
        Exception::Base->throw(message=>'Throw');
    };
    my $obj1 = $@;
    $self->assert_not_equals('', ref $obj1);
    $self->assert($obj1->isa("Exception::Base"), '$obj1->isa("Exception::Base")');
    $self->assert_equals('Throw', $obj1->{message});
    $self->assert_equals('Exception::BaseTest', $obj1->{caller_stack}->[0]->[0]);

    # Rethrow
    eval {
        $obj1->throw;
    };
    my $obj2 = $@;
    $self->assert_not_equals('', ref $obj2);
    $self->assert($obj2->isa("Exception::Base"), '$obj2->isa("Exception::Base")');
    $self->assert_equals('Throw', $obj2->{message});
    $self->assert_equals('Exception::BaseTest', $obj1->{caller_stack}->[0]->[0]);

    # Rethrow with overriden message
    eval {
        $obj1->throw(message=>'New throw', pid=>'ignored');
    };
    my $obj3 = $@;
    $self->assert_not_equals('', ref $obj3);
    $self->assert($obj3->isa("Exception::Base"), '$obj3->isa("Exception::Base")');
    $self->assert_equals('New throw', $obj3->{message});
    $self->assert_equals('Exception::BaseTest', $obj1->{caller_stack}->[0]->[0]);
    $self->assert_not_equals('ignored', $obj3->{pid});

    # Rethrow with overriden class
    {
        package Exception::Base::throw::Test1;
        our @ISA = ('Exception::Base');
    }

    eval {
        Exception::Base::throw::Test1->throw($obj1);
    };
    my $obj4 = $@;
    $self->assert_not_equals('', ref $obj4);
    $self->assert($obj4->isa("Exception::Base"), '$obj4->isa("Exception::Base")');
    $self->assert_equals('New throw', $obj4->{message});
    $self->assert_equals('Exception::BaseTest', $obj1->{caller_stack}->[0]->[0]);

    # Throw and ignore levels (does not modify caller stack)
    eval {
        Exception::Base->throw(message=>'Throw', ignore_level => 2);
    };
    my $obj7 = $@;
    $self->assert_not_equals('', ref $obj7);
    $self->assert($obj7->isa("Exception::Base"), '$obj7->isa("Exception::Base")');
    $self->assert_equals('Throw', $obj7->{message});
    $self->assert_equals('Exception::BaseTest', $obj1->{caller_stack}->[0]->[0]);

    # Message only
    eval {
        Exception::Base->throw('Throw');
    };
    my $obj8 = $@;
    $self->assert_not_equals('', ref $obj8);
    $self->assert($obj8->isa("Exception::Base"), '$obj8->isa("Exception::Base")');
    $self->assert_equals('Throw', $obj8->{message});
    $self->assert_equals('Exception::BaseTest', $obj1->{caller_stack}->[0]->[0]);

    # Message and hash only
    eval {
        Exception::Base->throw('Throw', message=>'Hash');
    };
    my $obj9 = $@;
    $self->assert_not_equals('', ref $obj9);
    $self->assert($obj9->isa("Exception::Base"), '$obj9->isa("Exception::Base")');
    $self->assert_equals('Hash', $obj9->{message});
    $self->assert_equals('Exception::BaseTest', $obj1->{caller_stack}->[0]->[0]);

    eval q{
        package Exception::BaseTest::throw::Package1;
        use base 'Exception::Base';
        use constant ATTRS => {
            %{ Exception::Base->ATTRS },
            default_attribute => { default => 'myattr' },
            myattr => { is => 'rw' },
        };
    };
    $self->assert_equals('', $@);

    # One argument only
    eval {
        Exception::BaseTest::throw::Package1->throw('Throw');
    };
    my $obj10 = $@;
    $self->assert_not_equals('', ref $obj10);
    $self->assert($obj10->isa("Exception::BaseTest::throw::Package1"), '$obj10->isa("Exception::BaseTest::throw::Package1")');
    $self->assert($obj10->isa("Exception::Base"), '$obj10->isa("Exception::Base")');
    $self->assert_equals('Throw', $obj10->{myattr});
    $self->assert_null($obj10->{message});
    $self->assert_equals('Exception::BaseTest', $obj1->{caller_stack}->[0]->[0]);
}

sub test_to_string {
    my $self = shift;

    my $obj = Exception::Base->new;

    $self->assert_not_equals('', ref $obj);
    $self->assert($obj->isa("Exception::Base"), '$obj->isa("Exception::Base")');

    $obj->{verbosity} = 0;
    $self->assert_equals('', $obj->to_string);
    $obj->{verbosity} = 1;
    $self->assert_equals("Unknown exception\n", $obj->to_string);
    $obj->{verbosity} = 2;
    $self->assert_matches(qr/Unknown exception at .* line \d+.\n/s, $obj->to_string);

    $obj->{message} = 'Stringify';
    $obj->{value} = 123;
    $obj->{verbosity} = 0;
    $self->assert_equals('', $obj->to_string);
    $obj->{verbosity} = 1;
    $self->assert_equals("Stringify\n", $obj->to_string);
    $obj->{verbosity} = 2;
    $self->assert_matches(qr/Stringify at .* line \d+.\n/s, $obj->to_string);
    $obj->{verbosity} = 3;
    $self->assert_matches(qr/Exception::Base: Stringify at .* line \d+\n/s, $obj->to_string);

    $obj->{message} = ['%s', 'Stringify'];
    $self->assert_matches(qr/Exception::Base: Stringify at .* line \d+\n/s, $obj->to_string);

    $obj->{message} = "Ends with EOL\n";
    $obj->{value} = 123;
    $obj->{verbosity} = 0;
    $self->assert_equals('', $obj->to_string);
    $obj->{verbosity} = 1;
    $self->assert_equals("Ends with EOL\n", $obj->to_string);
    $obj->{verbosity} = 2;
    $self->assert_equals("Ends with EOL\n", $obj->to_string);
    $obj->{verbosity} = 3;
    $self->assert_matches(qr/Exception::Base: Ends with EOL\n at .* line \d+\n/s, $obj->to_string);

    $obj->{message} = "Stringify";
    $obj->{verbosity} = 2;
    $obj->{ignore_packages} = [ ];
    $obj->{ignore_class} = [ ];
    $obj->{ignore_level} = 0;
    $obj->{max_arg_len} = 64;
    $obj->{max_arg_nums} = 8;
    $obj->{max_eval_len} = 0;

    $obj->{caller_stack} = [ [ 'main', '-e', 1, 'Exception::Base::throw', 1, undef, undef, undef, 'Exception::Base' ] ];
    $obj->{file} = '-e';
    $obj->{line} = 1;

    $self->assert_equals("Stringify at -e line 1.\n", $obj->to_string);

    $obj->{caller_stack} = [
        ['Package1', 'Package1.pm', 1, 'Package1::func1', 0, undef, undef, undef ],
        ['Package1', 'Package1.pm', 1, 'Package1::func1', 0, undef, undef, undef ],
        ['Package2', 'Package2.pm', 2, 'Package2::func2', 1, 1, undef, undef, 1, [], {}, sub {1; }, $self, $obj ],
        ['Package3', 'Package3.pm', 3, '(eval)', 0, undef, 1, undef ],
        ['Package4', 'Package4.pm', 4, 'Package4::func4', 0, undef, 'Require', 1 ],
        ['Package5', 'Package5.pm', 5, 'Package5::func5', 1, undef, undef, undef, "\x{00}", "'\"\\\`\x{0d}\x{c3}", "\x{09}\x{263a}", undef, 123, -123.56, 1, 2, 3 ],
        ['Package6', '-e', 6, 'Package6::func6', 0, undef, undef, undef ],
        ['Package7', undef, undef, 'Package7::func7', 0, undef, undef, undef ],
    ];
    $obj->{propagated_stack} = [
        ['Exception::BaseTest::Propagate1', 'Propagate1.pm', 11],
        ['Exception::BaseTest::Propagate2', 'Propagate2.pm', 22],
    ];

    $self->assert_equals("Stringify at Package1.pm line 1.\n", $obj->to_string(2));

    my $s1 = << 'END';
Exception::Base: Stringify at Package1.pm line 1
\t$_ = Package1::func1 called in package Package1 at Package1.pm line 1
\t$_ = Package1::func1 called in package Package1 at Package1.pm line 1
\t@_ = Package2::func2(1, "ARRAY(0x1234567)", "HASH(0x1234567)", "CODE(0x1234567)", "Exception::BaseTest=HASH(0x1234567)", "Exception::Base=HASH(0x1234567)") called in package Package2 at Package2.pm line 2
\t$_ = eval '1' called in package Package3 at Package3.pm line 3
\t$_ = require Require called in package Package4 at Package4.pm line 4
\t$_ = Package5::func5("\x{00}", "'\"\\\`\x{0d}\x{c3}", "\x{09}\x{263a}", undef, 123, -123.56, 1, ...) called in package Package5 at Package5.pm line 5
\t$_ = Package6::func6 called in package Package6 at -e line 6
\t$_ = Package7::func7 called in package Package7 at unknown line 0
\t...propagated in package Exception::BaseTest::Propagate1 at Propagate1.pm line 11.
\t...propagated in package Exception::BaseTest::Propagate2 at Propagate2.pm line 22.
END

    $s1 =~ s/\\t/\t/g;

    $obj->{verbosity} = 4;
    my $s2 = $obj->to_string;
    $s2 =~ s/(ARRAY|HASH|CODE)\(0x\w+\)/$1(0x1234567)/g;
    $self->assert_equals($s1, $s2);

    $obj->{verbosity} = 2;
    $self->assert_equals("Stringify at Package1.pm line 1.\n", $obj->to_string);

    $obj->{caller_stack} = [
        ['Exception::BaseTest::Package1', 'Package1.pm', 1, 'Exception::BaseTest::Package1::func1', 0, undef, undef, undef ],
        ['Exception::BaseTest::Package1', 'Package1.pm', 1, 'Exception::BaseTest::Package1::func1', 6, 1, undef, undef, 1, 2, 3, 4, 5, 6 ],
        ['Exception::BaseTest::Package2', 'Package2.pm', 2, 'Exception::BaseTest::Package2::func2', 2, 1, undef, undef, "123456789", "123456789" ],
        ['Exception::BaseTest::Package3', 'Package3.pm', 3, '(eval)', 0, undef, "123456789", undef ],
    ];
    $obj->{max_arg_nums} = 2;
    $obj->{max_arg_len} = 5;
    $obj->{max_eval_len} = 5;

    my $s4 = << 'END';
Exception::Base: Stringify at Package1.pm line 1
\t$_ = Exception::BaseTest::Package1::func1 called in package Exception::BaseTest::Package1 at Package1.pm line 1
\t@_ = Exception::BaseTest::Package1::func1(1, ...) called in package Exception::BaseTest::Package1 at Package1.pm line 1
\t@_ = Exception::BaseTest::Package2::func2(12..., 12...) called in package Exception::BaseTest::Package2 at Package2.pm line 2
\t$_ = eval '12...' called in package Exception::BaseTest::Package3 at Package3.pm line 3
\t...propagated in package Exception::BaseTest::Propagate1 at Propagate1.pm line 11.
\t...propagated in package Exception::BaseTest::Propagate2 at Propagate2.pm line 22.
END
    $s4 =~ s/\\t/\t/g;

    $obj->{verbosity} = 4;
    my $s5 = $obj->to_string;
    $self->assert_equals($s4, $s5);

    $obj->{ignore_level} = 1;

    my $s6 = << 'END';
Exception::Base: Stringify at Package1.pm line 1
\t@_ = Exception::BaseTest::Package2::func2(12..., 12...) called in package Exception::BaseTest::Package2 at Package2.pm line 2
\t$_ = eval '12...' called in package Exception::BaseTest::Package3 at Package3.pm line 3
\t...propagated in package Exception::BaseTest::Propagate1 at Propagate1.pm line 11.
\t...propagated in package Exception::BaseTest::Propagate2 at Propagate2.pm line 22.
END
    $s6 =~ s/\\t/\t/g;

    $obj->{verbosity} = 3;
    my $s7 = $obj->to_string;
    $self->assert_equals($s6, $s7);

    $obj->{verbosity} = 2;
    $self->assert_equals("Stringify at Package1.pm line 1.\n", $obj->to_string);

    $obj->{ignore_package} = 'Exception::BaseTest::Package1';

    my $s8 = << 'END';
Exception::Base: Stringify at Package3.pm line 3
\t...propagated in package Exception::BaseTest::Propagate1 at Propagate1.pm line 11.
\t...propagated in package Exception::BaseTest::Propagate2 at Propagate2.pm line 22.
END

    $s8 =~ s/\\t/\t/g;

    $obj->{verbosity} = 3;
    my $s9 = $obj->to_string;
    $self->assert_equals($s8, $s9);

    { package Exception::BaseTest::Package1; }
    { package Exception::BaseTest::Package2; }
    { package Exception::BaseTest::Package3; }
    { package Exception::BaseTest::Propagate1; }
    { package Exception::BaseTest::Propagate2; }

    my $s10 = << 'END';
Exception::Base: Stringify at Package3.pm line 3
\t$_ = Exception::BaseTest::Package1::func1 called in package Exception::BaseTest::Package1 at Package1.pm line 1
\t@_ = Exception::BaseTest::Package1::func1(1, ...) called in package Exception::BaseTest::Package1 at Package1.pm line 1
\t@_ = Exception::BaseTest::Package2::func2(12..., 12...) called in package Exception::BaseTest::Package2 at Package2.pm line 2
\t$_ = eval '12...' called in package Exception::BaseTest::Package3 at Package3.pm line 3
\t...propagated in package Exception::BaseTest::Propagate1 at Propagate1.pm line 11.
\t...propagated in package Exception::BaseTest::Propagate2 at Propagate2.pm line 22.
END

    $s10 =~ s/\\t/\t/g;

    $obj->{verbosity} = 4;
    my $s11 = $obj->to_string;
    $self->assert_equals($s10, $s11);

    $obj->{verbosity} = 2;
    $self->assert_equals("Stringify at Package3.pm line 3.\n", $obj->to_string);

    $obj->{ignore_level} = 0;

    my $s12 = << 'END';
Exception::Base: Stringify at Package2.pm line 2
\t$_ = eval '12...' called in package Exception::BaseTest::Package3 at Package3.pm line 3
\t...propagated in package Exception::BaseTest::Propagate1 at Propagate1.pm line 11.
\t...propagated in package Exception::BaseTest::Propagate2 at Propagate2.pm line 22.
END

    $s12 =~ s/\\t/\t/g;

    $obj->{verbosity} = 3;
    my $s13 = $obj->to_string;
    $self->assert_equals($s12, $s13);

    $obj->{verbosity} = 2;
    $self->assert_equals("Stringify at Package2.pm line 2.\n", $obj->to_string);

    $obj->{ignore_package} = [ 'Exception::BaseTest::Package1', 'Exception::BaseTest::Package2', 'Exception::BaseTest::Propagate1' ];

    my $s14 = << 'END';
Exception::Base: Stringify at Package3.pm line 3
\t...propagated in package Exception::BaseTest::Propagate2 at Propagate2.pm line 22.
END

    $s14 =~ s/\\t/\t/g;

    $obj->{verbosity} = 3;
    my $s15 = $obj->to_string;
    $self->assert_equals($s14, $s15);

    $obj->{verbosity} = 2;
    $self->assert_equals("Stringify at Package3.pm line 3.\n", $obj->to_string);

    $obj->{ignore_package} = qr/^Exception::BaseTest::(Package|Propagate)/;

    my $s16 = << 'END';
Exception::Base: Stringify at Package1.pm line 1
END

    $s16 =~ s/\\t/\t/g;

    $obj->{verbosity} = 3;
    my $s17 = $obj->to_string;
    $self->assert_equals($s16, $s17);

    $obj->{verbosity} = 2;
    $self->assert_equals("Stringify at Package1.pm line 1.\n", $obj->to_string);

    $obj->{ignore_package} = [ qr/^Exception::BaseTest::Package1/, qr/^Exception::BaseTest::Package2/, qr/^Exception::BaseTest::Propagate2/ ];

    my $s18 = << 'END';
Exception::Base: Stringify at Package3.pm line 3
\t...propagated in package Exception::BaseTest::Propagate1 at Propagate1.pm line 11.
END

    $s18 =~ s/\\t/\t/g;

    $obj->{verbosity} = 3;
    my $s19 = $obj->to_string;
    $self->assert_equals($s18, $s19);

    $obj->{verbosity} = 2;
    $self->assert_equals("Stringify at Package3.pm line 3.\n", $obj->to_string);

    $obj->{ignore_package} = [ ];
    $obj->{ignore_class} = 'Exception::BaseTest::Package1';

    my $s20 = << 'END';
Exception::Base: Stringify at Package2.pm line 2
\t$_ = eval '12...' called in package Exception::BaseTest::Package3 at Package3.pm line 3
\t...propagated in package Exception::BaseTest::Propagate1 at Propagate1.pm line 11.
\t...propagated in package Exception::BaseTest::Propagate2 at Propagate2.pm line 22.
END

    $s20 =~ s/\\t/\t/g;

    $obj->{verbosity} = 3;
    my $s21 = $obj->to_string;
    $self->assert_equals($s20, $s21);

    $obj->{verbosity} = 2;
    $self->assert_equals("Stringify at Package2.pm line 2.\n", $obj->to_string);

    $obj->{ignore_class} = [ 'Exception::BaseTest::Package1', 'Exception::BaseTest::Package2', 'Exception::BaseTest::Propagate1' ];

    my $s22 = << 'END';
Exception::Base: Stringify at Package3.pm line 3
\t...propagated in package Exception::BaseTest::Propagate2 at Propagate2.pm line 22.
END

    $s22 =~ s/\\t/\t/g;

    $obj->{verbosity} = 3;
    my $s23 = $obj->to_string;
    $self->assert_equals($s22, $s23);

    $obj->{verbosity} = 4;
    my $s24 = $obj->to_string;
    $self->assert_equals($s10, $s24);

    $obj->{verbosity} = 2;
    $self->assert_equals("Stringify at Package3.pm line 3.\n", $obj->to_string);

    $obj->{caller_stack} = [ ];
    $obj->{propagated_stack} = [ ];

    my $s25 = << 'END';
Exception::Base: Stringify at unknown line 0
END

    $s25 =~ s/\\t/\t/g;

    $obj->{verbosity} = 3;
    my $s26 = $obj->to_string;
    $self->assert_equals($s25, $s26);

    $obj->{verbosity} = 2;
    $self->assert_equals("Stringify at unknown line 0.\n", $obj->to_string);

    $obj->{defaults}->{verbosity} = 1;
    $obj->{verbosity} = undef;
    $self->assert_equals("Stringify\n", $obj->to_string);
    $self->assert_not_null(Exception::Base->ATTRS->{verbosity}->{default});
    $self->assert_equals(2, $obj->{defaults}->{verbosity} = Exception::Base->ATTRS->{verbosity}->{default});
    $obj->{verbosity} = 1;

    $obj->{defaults}->{string_attributes} = ['verbosity', 'message', 'value'];
    $self->assert_equals("1: Stringify: 123\n", $obj->to_string);

    $obj->{value} = '';
    $self->assert_equals("1: Stringify\n", $obj->to_string);

    $obj->{value} = undef;
    $self->assert_equals("1: Stringify\n", $obj->to_string);

    $self->assert_not_null(Exception::Base->ATTRS->{string_attributes}->{default});
    $self->assert_deep_equals(['message'], $obj->{defaults}->{string_attributes} = Exception::Base->ATTRS->{string_attributes}->{default});

    $self->assert_equals("Stringify\n", $obj->to_string);
}

sub test_to_number {
    my $self = shift;

    my $obj = Exception::Base->new;

    $self->assert_not_equals('', ref $obj);
    $self->assert($obj->isa("Exception::Base"), '$obj->isa("Exception::Base")');

    $self->assert_num_equals(0, $obj->to_number);
    $self->assert_num_equals(0, 0+ $obj);

    $obj->{defaults}->{value} = 123;
    $obj->{value} = undef;

    $self->assert_num_equals(123, $obj->to_number);
    $self->assert_num_equals(123, 0+ $obj);

    $obj->{value} = 456;

    $self->assert_num_equals(456, $obj->to_number);
    $self->assert_num_equals(456, 0+ $obj);

    $obj->{defaults}->{value} = undef;
    $obj->{value} = undef;

    $self->assert_num_equals(0, $obj->to_number);
    $self->assert_num_equals(0, 0+ $obj);

    $self->assert_num_equals(0, $obj->{defaults}->{value} = Exception::Base->ATTRS->{value}->{default});
}

sub test_overload {
    my $self = shift;

    local $SIG{__DIE__};

    my $obj = Exception::Base->new(message=>'String', value=>123);
    $self->assert_not_equals('', ref $obj);
    $self->assert($obj->isa("Exception::Base"), '$obj->isa("Exception::Base")');

    # boolify
    $self->assert($obj && 1, '$obj && 1');

    # numerify
    $self->assert_num_equals(123, $obj);

    # stringify without $SIG{__DIE__}
    $self->assert_matches(qr/String at /, $obj);

    # smart matching for Perl 5.10
    if ($] >= 5.010) {
        no if $] >= 5.018, warnings => 'experimental::smartmatch';
        eval q{
            $self->assert_num_equals(1, 'String' ~~ $obj);
        };
        die "$@" if $@;
        eval q{
            $self->assert_num_equals(1, 123 ~~ $obj);
        };
        die "$@" if $@;
        eval q{
            $self->assert_num_equals(1, ['Exception::Base'] ~~ $obj);
        };
        die "$@" if $@;
    }
}

sub test_matches {
    my $self = shift;

    {
        my $obj = Exception::Base->new;
        $self->assert_num_equals(1, $obj->matches);
        $self->assert_num_equals(1, $obj->matches(undef));
        $self->assert_num_equals(0, $obj->matches(sub {/Unknown/}));
        $self->assert_num_equals(0, $obj->matches(qr/Unknown/));
        $self->assert_num_equals(0, $obj->matches(sub {/False/}));
        $self->assert_num_equals(0, $obj->matches(qr/False/));
        $self->assert_num_equals(1, $obj->matches({tag=>undef}));
        $self->assert_num_equals(0, $obj->matches({tag=>'false'}));
        $self->assert_num_equals(1, $obj->matches({tag=>['False', qr//, sub {}, undef]}));
        $self->assert_num_equals(0, $obj->matches({tag=>['False', qr//, sub {}]}));
        $self->assert_num_equals(0, $obj->matches({tag=>[]}));
        $self->assert_num_equals(1, $obj->matches({tag=>[undef]}));
        $self->assert_num_equals(1, $obj->matches({message=>undef}));
        $self->assert_num_equals(0, $obj->matches({message=>'false'}));
        $self->assert_num_equals(0, $obj->matches({message=>sub{/false/}}));
        $self->assert_num_equals(0, $obj->matches({message=>qr/false/}));
        $self->assert_num_equals(0, $obj->matches({message=>[]}));
        $self->assert_num_equals(1, $obj->matches({message=>[undef]}));
        $self->assert_num_equals(1, $obj->matches({message=>['False', qr//, sub {}, undef]}));
        $self->assert_num_equals(0, $obj->matches({message=>['False', qr//, sub {}]}));
        $self->assert_num_equals(0, $obj->matches({-isa=>'False'}));
        $self->assert_num_equals(1, $obj->matches({-isa=>'Exception::Base'}));
        $self->assert_num_equals(0, $obj->matches({-isa=>['False', 'False', 'False']}));
        $self->assert_num_equals(1, $obj->matches({-isa=>['False', 'Exception::Base', 'False']}));
        $self->assert_num_equals(0, $obj->matches({-has=>'False'}));
        $self->assert_num_equals(1, $obj->matches({-has=>'message'}));
        $self->assert_num_equals(0, $obj->matches({-has=>['False', 'False', 'False']}));
        $self->assert_num_equals(1, $obj->matches({-has=>['False', 'message', 'False']}));
        $self->assert_num_equals(1, $obj->matches({-default=>undef}));
        $self->assert_num_equals(0, $obj->matches({-default=>'false'}));
        $self->assert_num_equals(0, $obj->matches('False'));
        $self->assert_num_equals(0, $obj->matches('Exception::Base'));
        $self->assert_num_equals(1, $obj->matches(0));
        $self->assert_num_equals(0, $obj->matches(1));
        $self->assert_num_equals(0, $obj->matches(123));
        $self->assert_num_equals(0, $obj->matches(['False', 'False', 'False']));
        $self->assert_num_equals(1, $obj->matches(['False', 'Exception::Base', 'False']));
        $self->assert_num_equals(0, $obj->matches(\1));
    };

    {
        my $obj = Exception::Base->new(message=>'Message', value=>123);
        $self->assert_num_equals(0, $obj->matches(undef));
        $self->assert_num_equals(1, $obj->matches(sub {/Message/}));
        $self->assert_num_equals(0, $obj->matches(sub {/False/}));
        $self->assert_num_equals(1, $obj->matches(qr/Message/));
        $self->assert_num_equals(0, $obj->matches(qr/False/));
        $self->assert_num_equals(1, $obj->matches({value=>123}));
        $self->assert_num_equals(0, $obj->matches({value=>'false'}));
        $self->assert_num_equals(1, $obj->matches({value=>sub {/123/}}));
        $self->assert_num_equals(1, $obj->matches({value=>qr/123/}));
        $self->assert_num_equals(0, $obj->matches({value=>sub {/false/}}));
        $self->assert_num_equals(0, $obj->matches({value=>qr/false/}));
        $self->assert_num_equals(0, $obj->matches({value=>undef}));
        $self->assert_num_equals(0, $obj->matches({value=>[]}));
        $self->assert_num_equals(0, $obj->matches({value=>[undef]}));
        $self->assert_num_equals(0, $obj->matches({value=>['False', qr/False/, sub {/False/}, undef]}));
        $self->assert_num_equals(1, $obj->matches({value=>['123', qr/False/, sub {/False/}, undef]}));
        $self->assert_num_equals(1, $obj->matches({value=>['False', qr/123/, sub {/False/}, undef]}));
        $self->assert_num_equals(1, $obj->matches({value=>['False', qr/False/, sub {/123/}, undef]}));
        $self->assert_num_equals(0, $obj->matches({false=>'false'}));
        $self->assert_num_equals(1, $obj->matches({false=>undef}));
        $self->assert_num_equals(1, $obj->matches({message=>'Message', value=>123}));
        $self->assert_num_equals(1, $obj->matches({message=>sub {/Message/}, value=>sub {/123/}}));
        $self->assert_num_equals(1, $obj->matches({message=>qr/Message/, value=>qr/123/}));
        $self->assert_num_equals(0, $obj->matches({message=>undef}));
        $self->assert_num_equals(1, $obj->matches({message=>'Message'}));
        $self->assert_num_equals(0, $obj->matches({message=>'false'}));
        $self->assert_num_equals(1, $obj->matches({message=>sub{/Message/}}));
        $self->assert_num_equals(1, $obj->matches({message=>qr/Message/}));
        $self->assert_num_equals(0, $obj->matches({message=>sub{/false/}}));
        $self->assert_num_equals(0, $obj->matches({message=>qr/false/}));
        $self->assert_num_equals(0, $obj->matches({message=>[]}));
        $self->assert_num_equals(0, $obj->matches({message=>[undef]}));
        $self->assert_num_equals(0, $obj->matches({message=>['False', qr/False/, sub {/False/}, undef]}));
        $self->assert_num_equals(1, $obj->matches({message=>['Message', qr/False/, sub {/False/}, undef]}));
        $self->assert_num_equals(1, $obj->matches({message=>['False', qr/Message/, sub {/False/}, undef]}));
        $self->assert_num_equals(1, $obj->matches({message=>['False', qr/False/, sub {/Message/}, undef]}));
        $self->assert_num_equals(0, $obj->matches({-default=>undef}));
        $self->assert_num_equals(1, $obj->matches({-default=>'Message'}));
        $self->assert_num_equals(0, $obj->matches('False'));
        $self->assert_num_equals(0, $obj->matches('Exception::Base'));
        $self->assert_num_equals(1, $obj->matches('Message'));
        $self->assert_num_equals(0, $obj->matches(0));
        $self->assert_num_equals(0, $obj->matches(1));
        $self->assert_num_equals(1, $obj->matches(123));
        $self->assert_num_equals(0, $obj->matches(['False', 'False', 'False']));
        $self->assert_num_equals(1, $obj->matches(['False', 'Exception::Base', 'False']));
        $self->assert_num_equals(0, $obj->matches(\1));
    };

    {
        my $obj = Exception::Base->new(message=>['%s', 'Message'], value=>123);
        $self->assert_num_equals(0, $obj->matches(undef));
        $self->assert_num_equals(1, $obj->matches(sub {/Message/}));
        $self->assert_num_equals(0, $obj->matches(sub {/False/}));
        $self->assert_num_equals(1, $obj->matches(qr/Message/));
        $self->assert_num_equals(0, $obj->matches(qr/False/));
        $self->assert_num_equals(1, $obj->matches({value=>123}));
        $self->assert_num_equals(0, $obj->matches({value=>'false'}));
        $self->assert_num_equals(1, $obj->matches({value=>sub {/123/}}));
        $self->assert_num_equals(1, $obj->matches({value=>qr/123/}));
        $self->assert_num_equals(0, $obj->matches({value=>sub {/false/}}));
        $self->assert_num_equals(0, $obj->matches({value=>qr/false/}));
        $self->assert_num_equals(0, $obj->matches({value=>undef}));
        $self->assert_num_equals(0, $obj->matches({value=>[]}));
        $self->assert_num_equals(0, $obj->matches({value=>[undef]}));
        $self->assert_num_equals(0, $obj->matches({value=>['False', qr/False/, sub {/False/}, undef]}));
        $self->assert_num_equals(1, $obj->matches({value=>['123', qr/False/, sub {/False/}, undef]}));
        $self->assert_num_equals(1, $obj->matches({value=>['False', qr/123/, sub {/False/}, undef]}));
        $self->assert_num_equals(1, $obj->matches({value=>['False', qr/False/, sub {/123/}, undef]}));
        $self->assert_num_equals(0, $obj->matches({false=>'false'}));
        $self->assert_num_equals(1, $obj->matches({false=>undef}));
        $self->assert_num_equals(1, $obj->matches({message=>'Message', value=>123}));
        $self->assert_num_equals(1, $obj->matches({message=>sub {/Message/}, value=>sub {/123/}}));
        $self->assert_num_equals(1, $obj->matches({message=>qr/Message/, value=>qr/123/}));
        $self->assert_num_equals(0, $obj->matches({message=>undef}));
        $self->assert_num_equals(1, $obj->matches({message=>'Message'}));
        $self->assert_num_equals(0, $obj->matches({message=>'false'}));
        $self->assert_num_equals(1, $obj->matches({message=>sub{/Message/}}));
        $self->assert_num_equals(1, $obj->matches({message=>qr/Message/}));
        $self->assert_num_equals(0, $obj->matches({message=>sub{/false/}}));
        $self->assert_num_equals(0, $obj->matches({message=>qr/false/}));
        $self->assert_num_equals(0, $obj->matches({message=>[]}));
        $self->assert_num_equals(0, $obj->matches({message=>[undef]}));
        $self->assert_num_equals(0, $obj->matches({message=>['False', qr/False/, sub {/False/}, undef]}));
        $self->assert_num_equals(1, $obj->matches({message=>['Message', qr/False/, sub {/False/}, undef]}));
        $self->assert_num_equals(1, $obj->matches({message=>['False', qr/Message/, sub {/False/}, undef]}));
        $self->assert_num_equals(1, $obj->matches({message=>['False', qr/False/, sub {/Message/}, undef]}));
        $self->assert_num_equals(0, $obj->matches({-default=>undef}));
        $self->assert_num_equals(1, $obj->matches({-default=>'Message'}));
        $self->assert_num_equals(0, $obj->matches('False'));
        $self->assert_num_equals(0, $obj->matches('Exception::Base'));
        $self->assert_num_equals(1, $obj->matches('Message'));
        $self->assert_num_equals(0, $obj->matches(0));
        $self->assert_num_equals(0, $obj->matches(1));
        $self->assert_num_equals(1, $obj->matches(123));
        $self->assert_num_equals(0, $obj->matches(['False', 'False', 'False']));
        $self->assert_num_equals(1, $obj->matches(['False', 'Exception::Base', 'False']));
        $self->assert_num_equals(0, $obj->matches(\1));
    };

    {
        my $obj = Exception::Base->new(message=>undef);
        $self->assert_num_equals(1, $obj->matches(undef));
        $self->assert_num_equals(1, $obj->matches({message=>undef}));
        $self->assert_num_equals(0, $obj->matches('false'));
        $self->assert_num_equals(0, $obj->matches({message=>'false'}));
        $self->assert_num_equals(0, $obj->matches({message=>sub {/false/}}));
        $self->assert_num_equals(0, $obj->matches({message=>qr/false/}));
        $self->assert_num_equals(0, $obj->matches({message=>[]}));
        $self->assert_num_equals(1, $obj->matches({message=>[undef]}));
        $self->assert_num_equals(1, $obj->matches({message=>['False', qr/False/, sub {/False/}, undef]}));
        $self->assert_num_equals(1, $obj->matches({message=>['Message', qr/False/, sub {/False/}, undef]}));
        $self->assert_num_equals(1, $obj->matches({message=>['False', qr/Message/, sub {/False/}, undef]}));
        $self->assert_num_equals(1, $obj->matches({message=>['False', qr/False/, sub {/Message/}, undef]}));
    };

    eval q{
        package Exception::BaseTest::matches::Package1;
        use base 'Exception::Base';
        use constant ATTRS => {
            %{ Exception::Base->ATTRS },
            string_attributes => { default => [ 'message', 'strattr' ] },
            numeric_attribute    => { default => 'numattr' },
            strattr => { is => 'rw' },
            numattr => { is => 'rw' },
        };
    };
    $self->assert_equals('', $@);

    {
        my $obj = Exception::BaseTest::matches::Package1->new;
        $self->assert_num_equals(1, $obj->matches(undef));
        $self->assert_num_equals(1, $obj->matches(0));
    };

    {
        my $obj = Exception::BaseTest::matches::Package1->new(message=>'Message', value=>123);
        $self->assert_num_equals(0, $obj->matches(undef));
        $self->assert_num_equals(1, $obj->matches('Message'));
        $self->assert_num_equals(1, $obj->matches(qr/Message/));
        $self->assert_num_equals(1, $obj->matches(sub{qr/Message/}));
        $self->assert_num_equals(1, $obj->matches(0));
    };

    {
        my $obj = Exception::BaseTest::matches::Package1->new(message=>'Message', strattr=>'String', value=>123, numattr=>456);
        $self->assert_num_equals(0, $obj->matches(undef));
        $self->assert_num_equals(1, $obj->matches('Message: String'));
        $self->assert_num_equals(1, $obj->matches(qr/Message: String/));
        $self->assert_num_equals(1, $obj->matches(sub{qr/Message: String/}));
        $self->assert_num_equals(1, $obj->matches(456));
    };
}

sub test_catch {
    my $self = shift;

    local $SIG{__DIE__};

    eval { 1; };
    my $e1 = Exception::Base->catch;
    $self->assert_null($e1);

    eval { die "Die 2\n"; };
    my $e2 = Exception::Base->catch;
    $self->assert_not_equals('', ref $e2);
    $self->assert($e2->isa("Exception::Base"), '$e2->isa("Exception::Base")');
    $self->assert_equals("Die 2", $e2->{message});
    $self->assert($e2->isa("Exception::Base"), '$e2->isa("Exception::Base")');
    $self->assert_equals('Exception::BaseTest', $e2->{caller_stack}->[0]->[0]);

    eval { die "Die 3\n"; };
    my $e3 = Exception::Base->catch;
    $self->assert_not_equals('', ref $e3);
    $self->assert($e3->isa("Exception::Base"), '$e3->isa("Exception::Base")');
    $self->assert_equals("Die 3", $e3->{message});

    eval { Exception::Base->throw; };
    my $e5 = Exception::Base->catch;
    $self->assert_not_equals('', ref $e5);
    $self->assert($e5->isa("Exception::Base"), '$e5->isa("Exception::Base")');
    $self->assert_null($e5->{message});

    eval { 1; };
    my $e10 = Exception::Base->catch;
    $self->assert_null($e10);

    eval { die $self; };
    my $e13 = Exception::Base->catch;
    $self->assert_str_not_equals('', $e13);
    $self->assert($e13->isa("Exception::Base"), '$e13->isa("Exception::Base")');

    eval { Exception::Base->throw; };
    my $e14 = Exception::Base::catch;
    $self->assert($e14->isa("Exception::Base"), '$e14->isa("Exception::Base")');

    eval { 1; };
    eval 'package Exception::Base::catch::Package16; our @ISA = "Exception::Base"; 1;';
    $self->assert_equals('', "$@");
    eval {
        die "Die 16";
    };
    my $e16 = Exception::Base->catch;
    $self->assert_equals('Exception::Base', ref $e16);

    eval { 1; };
    eval 'package Exception::Base::catch::Package17; our @ISA = "Exception::Base"; 1;';
    $self->assert_equals('', "$@");
    eval {
        die "Die 17";
    };
    my $e17 = Exception::Base::catch::Package17->catch;
    $self->assert_equals('Exception::Base::catch::Package17', ref $e17);

    eval q{
        package Exception::BaseTest::catch::Package19;
        use base 'Exception::Base';
        use constant ATTRS => {
            %{ Exception::Base->ATTRS },
            eval_attribute => { default => 'myattr' },
        myattr => { is => 'rw' },
        };
    };
    $self->assert_equals('', $@);

    # Recover $@ to myattr
    eval {
        die 'Throw 19';
    };
    my $e19 = Exception::BaseTest::catch::Package19->catch;
    $self->assert_not_equals('', ref $e19);
    $self->assert_equals('Exception::BaseTest::catch::Package19', ref $e19);
    $self->assert($e19->isa("Exception::Base"), '$e19->isa("Exception::Base")');
    $self->assert_equals('Throw 19', $e19->{myattr});
    $self->assert_null($e19->{message});

    # Recover from argument
    my $e20 = Exception::Base->catch($e19);
    $self->assert_not_equals('', ref $e19);
    $self->assert_equals('Exception::BaseTest::catch::Package19', ref $e19);
}

sub test_catch_non_exception {
    my $self = shift;

    local $SIG{__DIE__};

    $@ = "Unknown message";
    my $obj1 = Exception::Base->catch;
    $self->assert_equals("Unknown message", $obj1->{message});

    do { $@ = "Unknown message\n" };
    my $obj2 = Exception::Base->catch;
    $self->assert_equals("Unknown message", $obj2->{message});

    do { $@ = "Unknown message at file line 123.\n" };
    my $obj3 = Exception::Base->catch;
    $self->assert_equals("Unknown message", $obj3->{message});

    do { $@ = "Unknown message at file line 123 thread 456789.\n" };
    my $obj4 = Exception::Base->catch;
    $self->assert_equals("Unknown message", $obj4->{message});

    do { $@ = "Unknown message at foo at bar at baz at file line 123.\n" };
    my $obj5 = Exception::Base->catch;
    $self->assert_equals("Unknown message at foo at bar at baz", $obj5->{message});

    do { $@ = "Unknown message\nNext line\n" };
    my $obj6 = Exception::Base->catch;
    $self->assert_equals("Unknown message\nNext line", $obj6->{message});

    do { $@ = "Unknown message\n\t...propagated at -e line 1.\n" };
    my $obj7 = Exception::Base->catch;
    $self->assert_equals("Unknown message", $obj7->{message});

    do { $@ = "Unknown message\n\t...propagated at -e line 1.\n\t...propagated at file line 123 thread 456789.\n" };
    my $obj8 = Exception::Base->catch;
    $self->assert_equals("Unknown message", $obj8->{message});
}

sub test_import_all {
    my $self = shift;

    local $SIG{__DIE__};

    eval 'Exception::Base->import(":all");';
    $self->assert_equals('', "$@");
}

sub test_import_class {
    my $self = shift;

    local $SIG{__DIE__} = '';

    eval {
        Exception::Base->import(
            'Exception::Base',
        );
    };
    $self->assert_equals('', "$@");
};

sub test_import_class_simple {
    my $self = shift;

    local $SIG{__DIE__} = '';

    eval {
        Exception::Base->import(
            'Exception::BaseTest::import::TestSimple',
        );
    };
    $self->assert_equals('', "$@");
    eval {
        Exception::BaseTest::import::TestSimple->throw;
    };
    my $obj = $@;
    $self->assert($obj->isa("Exception::BaseTest::import::TestSimple"), '$obj->isa("Exception::BaseTest::import::TestSimple")');
    $self->assert($obj->isa("Exception::Base"), '$obj->isa("Exception::Base")');
    $self->assert_equals('0.01', $obj->VERSION);
};

sub test_import_class_with_isa {
    my $self = shift;

    local $SIG{__DIE__} = '';

    eval {
        Exception::Base->import(
            'Exception::BaseTest::import::TestWithIsa' => {
                isa => 'Exception::BaseTest::import::TestSimple',
                version => 1.3,
            },
        );
    };
    $self->assert_equals('', "$@");
    eval {
        Exception::BaseTest::import::TestWithIsa->throw;
    };
    my $obj = $@;
    $self->assert($obj->isa("Exception::BaseTest::import::TestWithIsa"), '$obj->isa("Exception::BaseTest::import::TestWithIsa")');
    $self->assert($obj->isa("Exception::BaseTest::import::TestSimple"), '$obj->isa("Exception::BaseTest::import::TestSimple")');
    $self->assert($obj->isa("Exception::Base"), '$obj->isa("Exception::Base")');
    $self->assert_equals('1.3', $obj->VERSION);
};

sub test_import_class_with_version {
    my $self = shift;

    local $SIG{__DIE__} = '';

    eval {
        Exception::Base->import(
            'Exception::BaseTest::import::TestWithVersion' => {
                version => 1.4,
            },
        );
    };
    $self->assert_equals('', "$@");
    eval {
        Exception::BaseTest::import::TestWithVersion->throw;
    };
    my $obj = $@;
    $self->assert($obj->isa("Exception::BaseTest::import::TestWithVersion"), '$obj->isa("Exception::BaseTest::import::TestWithVersion")');
    $self->assert($obj->isa("Exception::Base"), '$obj->isa("Exception::Base")');
    $self->assert_equals('1.4', $obj->VERSION);
};

sub test_import_class_with_isa_not_existing {
    my $self = shift;

    local $SIG{__DIE__} = '';

    eval {
        Exception::Base->import(
            'Exception::BaseTest::import::TestWithIsaNotExisting' => {
                isa => 'Exception::BaseTest::import::TestNotExisting',
            },
        );
    };
    $self->assert_matches(qr/Base class.* can not be found/, "$@");
};

sub test_import_class_with_bad_import_class {
    my $self = shift;

    local $SIG{__DIE__} = '';

    eval {
        Exception::BaseTest::import::TestSimple->import(
            'Exception::BaseTest::import::TestWithBadImportClass',
        );
    };
    $self->assert_matches(qr/Exceptions can only be created with Exception::Base class/, "$@");
};

sub test_import_class_with_pure_package {
    my $self = shift;

    local $SIG{__DIE__} = '';

    eval {
        Exception::Base->import(
            'Exception::BaseTest::PurePackage',
        );
    };
    $self->assert_equals('', "$@");
    eval {
        Exception::BaseTest::PurePackage->throw;
    };
    my $obj = $@;
    $self->assert($obj->isa("Exception::BaseTest::PurePackage"), '$obj->isa("Exception::BaseTest::PurePackage")');
    $self->assert($obj->isa("Exception::Base"), '$obj->isa("Exception::Base")');
    $self->assert_equals('0.02', $obj->VERSION);
};

sub test_import_class_with_loaded_exception {
    my $self = shift;

    local $SIG{__DIE__} = '';

    eval {
        Exception::Base->import(
            'Exception::BaseTest::LoadedException',
        );
    };
    $self->assert_equals('', "$@");
    eval {
        Exception::BaseTest::LoadedException->throw;
    };
    my $obj = $@;
    $self->assert($obj->isa("Exception::BaseTest::LoadedException"), '$obj->isa("Exception::BaseTest::LoadedException")');
    $self->assert($obj->isa("Exception::Base"), '$obj->isa("Exception::Base")');
    $self->assert_equals('0.03', $obj->VERSION);
};

sub test_import_class_via_loaded_exception {
    my $self = shift;

    local $SIG{__DIE__} = '';

    eval {
        require Exception::BaseTest::LoadedException;
        Exception::BaseTest::LoadedException->import;
    };
    $self->assert_equals('', "$@");
    eval {
        Exception::BaseTest::LoadedException->throw;
    };
    my $obj = $@;
    $self->assert($obj->isa("Exception::BaseTest::LoadedException"), '$obj->isa("Exception::BaseTest::LoadedException")');
    $self->assert($obj->isa("Exception::Base"), '$obj->isa("Exception::Base")');
    $self->assert_equals('0.03', $obj->VERSION);
};

sub test_import_class_with_version_required {
    my $self = shift;

    local $SIG{__DIE__} = '';

    eval {
        Exception::Base->import(
            'Exception::Base' => {
                version => 999.12
            },
        );
    };
    $self->assert_matches(qr/version 999.12 required/, "$@");
};

sub test_import_class_with_message {
    my $self = shift;

    local $SIG{__DIE__} = '';

    eval {
        Exception::Base->import(
            'Exception::BaseTest::import::TestWithMessage' => {
                message => "Message",
                verbosity => 1,
            },
        );
    };
    $self->assert_equals('', "$@");
    eval {
        Exception::BaseTest::import::TestWithMessage->throw;
    };
    my $obj = $@;
    $self->assert($obj->isa("Exception::BaseTest::import::TestWithMessage"), '$obj->isa("Exception::BaseTest::import::TestWithMessage")');
    $self->assert($obj->isa("Exception::Base"), '$obj->isa("Exception::Base::TestWithMessage")');
    $self->assert_equals("Message\n", "$obj");
};

sub test_import_class_with_readonly_attr {
    my $self = shift;

    local $SIG{__DIE__} = '';

    eval {
        Exception::Base->import(
            'Exception::BaseTest::import::TestWithReadonlyAttr' => {
                time => "readonly",
            }
        );
    };
    $self->assert_matches(qr/class does not implement default value/, "$@");
};

sub test_import_class_with_has_scalar {
    my $self = shift;

    local $SIG{__DIE__} = '';

    eval {
        Exception::Base->import(
            'Exception::BaseTest::import::TestWithHasScalar' => {
                has => "attr",
            }
        );
    };
    $self->assert_equals('', "$@");
    eval {
        Exception::BaseTest::import::TestWithHasScalar->throw(
            attr => "attr",
        );
    };
    my $obj = $@;
    $self->assert($obj->isa("Exception::BaseTest::import::TestWithHasScalar"), '$obj->isa("Exception::BaseTest::import::TestWithHasScalar")');
    $self->assert($obj->isa("Exception::Base"), '$obj->isa("Exception::Base")');
    $self->assert_equals("attr", $obj->{attr});
    $self->assert_equals("attr", $obj->attr);
};

sub test_import_class_with_has_array {
    my $self = shift;

    local $SIG{__DIE__} = '';

    eval {
        Exception::Base->import(
            'Exception::BaseTest::import::TestWithHasArray' => {
                has => [ "attr1", "attr2" ],
            },
        );
    };
    $self->assert_equals('', "$@");
    eval {
        Exception::BaseTest::import::TestWithHasArray->throw(
            attr1 => "attr1",
            attr2 => "attr2",
        );
    };
    my $obj = $@;
    $self->assert($obj->isa("Exception::BaseTest::import::TestWithHasArray"), '$obj->isa("Exception::BaseTest::import::TestWithHasArray")');
    $self->assert($obj->isa("Exception::Base"), '$obj->isa("Exception::Base")');
    $self->assert_equals("attr1", $obj->{attr1});
    $self->assert_equals("attr1", $obj->attr1);
    $self->assert_equals("attr2", $obj->{attr2});
    $self->assert_equals("attr2", $obj->attr2);
};

sub test_import_class_with_has_rw_scalar {
    my $self = shift;

    local $SIG{__DIE__} = '';

    eval {
        Exception::Base->import(
            'Exception::BaseTest::import::TestWithHasRwScalar' => {
                has => {
                    rw => "attr",
                },
            },
        );
    };
    $self->assert_equals('', "$@");
    eval {
        Exception::BaseTest::import::TestWithHasRwScalar->throw(
            attr => "attr",
        );
    };
    my $obj = $@;
    $self->assert($obj->isa("Exception::BaseTest::import::TestWithHasRwScalar"), '$obj->isa("Exception::BaseTest::import::TestWithHasRwScalar")');
    $self->assert($obj->isa("Exception::Base"), '$obj->isa("Exception::Base")');
    $self->assert_equals("attr", $obj->{attr});
    $self->assert_equals("attr", $obj->attr);
};

sub test_import_class_with_has_rw_array {
    my $self = shift;

    local $SIG{__DIE__} = '';

    eval {
        Exception::Base->import(
            'Exception::BaseTest::import::TestWithHasRwArray' => {
                has => {
                    rw => [ "attr1", "attr2" ],
                },
            },
        );
    };
    $self->assert_equals('', "$@");
    eval {
        Exception::BaseTest::import::TestWithHasRwArray->throw(
            attr1 => "attr1",
        );
    };
    my $obj = $@;
    $self->assert($obj->isa("Exception::BaseTest::import::TestWithHasRwArray"), '$obj->isa("Exception::BaseTest::import::TestWithHasRwArray")');
    $self->assert($obj->isa("Exception::Base"), '$obj->isa("Exception::Base")');
    $self->assert_equals("attr1", $obj->{attr1});
    $self->assert_equals("attr1", $obj->attr1);
    $self->assert_null($obj->{attr2});
    $self->assert_null($obj->attr2);
};

sub test_import_class_with_has_ro_scalar {
    my $self = shift;

    local $SIG{__DIE__} = '';

    eval {
        Exception::Base->import(
            'Exception::BaseTest::import::TestWithHasRoScalar' => {
                has => {
                    ro => "attr",
                },
            },
        );
    };
    $self->assert_equals('', "$@");
    eval {
        Exception::BaseTest::import::TestWithHasRoScalar->throw(
            attr => "attr",
        );
    };
    my $obj = $@;
    $self->assert($obj->isa("Exception::BaseTest::import::TestWithHasRoScalar"), '$obj->isa("Exception::BaseTest::import::TestHasWithRoScalar")');
    $self->assert($obj->isa("Exception::Base"), '$obj->isa("Exception::Base")');
    $self->assert_null($obj->{attr});
    $self->assert_null($obj->attr);
};

sub test_import_class_with_has_ro_array {
    my $self = shift;

    local $SIG{__DIE__} = '';

    eval {
        Exception::Base->import(
            'Exception::BaseTest::import::TestWithHasRoArray' => {
                has => {
                    ro => [ "attr1", "attr2" ],
                },
            },
        );
    };
    $self->assert_equals('', "$@");
    eval {
        Exception::BaseTest::import::TestWithHasRoArray->throw(
            attr1 => "attr1",
        );
    };
    my $obj = $@;
    $self->assert($obj->isa("Exception::BaseTest::import::TestWithHasRoArray"), '$obj->isa("Exception::BaseTest::import::TestHasWithRoArray")');
    $self->assert($obj->isa("Exception::Base"), '$obj->isa("Exception::Base")');
    $self->assert_null($obj->{attr1});
    $self->assert_null($obj->attr1);
    $self->assert_null($obj->{attr2});
    $self->assert_null($obj->attr2);
};

sub test_import_class_with_has_scalar_restricted_keyword {
    my $self = shift;

    local $SIG{__DIE__} = '';

    eval {
        Exception::Base->import(
            'Exception::BaseTest::import::TestWithHasScalarRestrictedKeyword' => {
                has => "has",
            },
        );
    };
    $self->assert_matches(qr/can not be defined/, "$@");
};

sub test_import_class_with_has_array_restricted_keyword {
    my $self = shift;

    local $SIG{__DIE__} = '';

    eval {
        Exception::Base->import(
            'Exception::BaseTest::import::TestWithHasArrayRestrictedKeyword' => {
                has => [ "has" ],
            },
        );
    };
    $self->assert_matches(qr/can not be defined/, "$@");
};

sub test_import_class_with_syntax_error {
    my $self = shift;

    local $SIG{__DIE__} = '';

    eval {
        Exception::Base->import(
            'Exception::BaseTest::SyntaxError',
        );
    };
    $self->assert_matches(qr/Can not load/, "$@");
};

sub test_import_class_with_missing_version {
    my $self = shift;

    local $SIG{__DIE__} = '';

    eval {
        Exception::Base->import(
            'Exception::BaseTest::MissingVersion',
        );
    };
    $self->assert_matches(qr/Can not load/, "$@");
};

sub test_import_defaults_message {
    my $self = shift;

    eval {
        Exception::Base->import(
            'Exception::BaseTest::import_defaults::WithMessage',
        );
        Exception::BaseTest::import_defaults::WithMessage->import(
            'message' => "New message",
        );
    };
    $self->assert_equals('', "$@");
    $self->assert_equals('New message', Exception::BaseTest::import_defaults::WithMessage->ATTRS->{message}->{default});
};

sub test_import_defaults_plus_message {
    my $self = shift;

    eval {
        Exception::Base->import(
            'Exception::BaseTest::import_defaults::WithPlusMessage',
        );
        Exception::BaseTest::import_defaults::WithPlusMessage->import(
            '+message' => " with suffix",
        );
    };
    $self->assert_equals('', "$@");
    $self->assert_equals('Unknown exception with suffix', Exception::BaseTest::import_defaults::WithPlusMessage->ATTRS->{message}->{default});
};

sub test_import_defaults_minus_message {
    my $self = shift;

    eval {
        Exception::Base->import(
            'Exception::BaseTest::import_defaults::WithMinusMessage',
        );
        Exception::BaseTest::import_defaults::WithMinusMessage->import(
            'message' => "New message",
        );
        Exception::BaseTest::import_defaults::WithMinusMessage->import(
            '-message' => "Another new message",
        );
    };
    $self->assert_equals('', "$@");
    $self->assert_equals('Another new message', Exception::BaseTest::import_defaults::WithMinusMessage->ATTRS->{message}->{default});
};

sub test_import_defaults_ignore_package {
    my $self = shift;

    eval {
        Exception::Base->import(
            'Exception::BaseTest::import_defaults::WithIgnorePackage',
        );
        Exception::BaseTest::import_defaults::WithIgnorePackage->import(
            "ignore_package" => [ "1" ]
        );
    };
    $self->assert_equals('', "$@");
    $self->assert_deep_equals([ 1 ], Exception::BaseTest::import_defaults::WithIgnorePackage->ATTRS->{ignore_package}->{default});

    eval {
        Exception::BaseTest::import_defaults::WithIgnorePackage->import(
            "+ignore_package" => "2"
        );
    };
    $self->assert_equals('', "$@");
    $self->assert_deep_equals([ 1, 2 ], [sort @{ Exception::BaseTest::import_defaults::WithIgnorePackage->ATTRS->{ignore_package}->{default} }]);

    eval {
        Exception::BaseTest::import_defaults::WithIgnorePackage->import(
            "+ignore_package" => [ "3" ]
        );
    };
    $self->assert_equals('', "$@");
    $self->assert_deep_equals([ 1, 2, 3 ], [sort @{ Exception::BaseTest::import_defaults::WithIgnorePackage->ATTRS->{ignore_package}->{default} }]);

    eval {
        Exception::BaseTest::import_defaults::WithIgnorePackage->import(
            "+ignore_package" => [ "3", "4", "5" ]
        );
    };
    $self->assert_equals('', "$@");
    $self->assert_deep_equals([ 1, 2, 3, 4, 5 ], [sort @{ Exception::BaseTest::import_defaults::WithIgnorePackage->ATTRS->{ignore_package}->{default} }]);

    eval {
        Exception::BaseTest::import_defaults::WithIgnorePackage->import(
            "+ignore_package" => [ "1", "2", "3" ]
        );
    };
    $self->assert_equals('', "$@");
    $self->assert_deep_equals([ 1, 2, 3, 4, 5 ], [sort @{ Exception::BaseTest::import_defaults::WithIgnorePackage->ATTRS->{ignore_package}->{default} }]);

    eval {
        Exception::BaseTest::import_defaults::WithIgnorePackage->import(
            "-ignore_package" => [ "1" ]
        );
    };
    $self->assert_equals('', "$@");
    $self->assert_deep_equals([ 2, 3, 4, 5 ], [sort @{ Exception::BaseTest::import_defaults::WithIgnorePackage->ATTRS->{ignore_package}->{default} }]);

    eval {
        Exception::BaseTest::import_defaults::WithIgnorePackage->import(
            "-ignore_package" => "2"
        );
    };
    $self->assert_equals('', "$@");
    $self->assert_deep_equals([ 3, 4 ,5 ], [sort @{ Exception::BaseTest::import_defaults::WithIgnorePackage->ATTRS->{ignore_package}->{default} }]);

    eval {
        Exception::BaseTest::import_defaults::WithIgnorePackage->import(
            "-ignore_package" => [ "2", "3", "4" ]
        );
    };
    $self->assert_equals('', "$@");
    $self->assert_deep_equals([ 5 ], [sort @{ Exception::BaseTest::import_defaults::WithIgnorePackage->ATTRS->{ignore_package}->{default} }]);

    eval {
        Exception::BaseTest::import_defaults::WithIgnorePackage->import(
            "+ignore_package" => qr/6/
        );
    };
    $self->assert_equals('', "$@");
    $self->assert_equals(5, Exception::BaseTest::import_defaults::WithIgnorePackage->ATTRS->{ignore_package}->{default}->[0]);
    $self->assert_equals('Regexp', ref Exception::BaseTest::import_defaults::WithIgnorePackage->ATTRS->{ignore_package}->{default}->[1]);

    eval {
        Exception::BaseTest::import_defaults::WithIgnorePackage->import(
            "-ignore_package" => [ "5", qr/6/ ]
        );
    };
    $self->assert_equals('', "$@");
    $self->assert_deep_equals([], [sort @{ Exception::BaseTest::import_defaults::WithIgnorePackage->ATTRS->{ignore_package}->{default} }]);
};

sub test_import_defaults_ignore_level {
    my $self = shift;

    eval {
        Exception::Base->import(
            'Exception::BaseTest::import_defaults::WithIgnoreLevel',
        );
        Exception::BaseTest::import_defaults::WithIgnoreLevel->import(
            "ignore_level" => 5
        );
    };
    $self->assert_equals('', "$@");
    $self->assert_equals(5, Exception::BaseTest::import_defaults::WithIgnoreLevel->ATTRS->{ignore_level}->{default});

    eval {
        Exception::BaseTest::import_defaults::WithIgnoreLevel->import(
            "+ignore_level" => 1
        );
    };
    $self->assert_equals('', "$@");
    $self->assert_equals(6, Exception::BaseTest::import_defaults::WithIgnoreLevel->ATTRS->{ignore_level}->{default});

    eval {
        Exception::BaseTest::import_defaults::WithIgnoreLevel->import(
            "-ignore_level" => 2
        );
    };
    $self->assert_equals('', "$@");
    $self->assert_equals(4, Exception::BaseTest::import_defaults::WithIgnoreLevel->ATTRS->{ignore_level}->{default});
};

sub test_import_defaults_ignore_class {
    my $self = shift;

    eval {
        Exception::Base->import(
            'Exception::BaseTest::import_defaults::WithIgnoreClass',
        );
        Exception::BaseTest::import_defaults::WithIgnoreClass->import(
            'ignore_class' => undef,
        );
    };
    $self->assert_equals('', "$@");
    $self->assert_null(Exception::BaseTest::import_defaults::WithIgnoreClass->ATTRS->{ignore_class}->{default});
};

sub test_import_defaults_no_such_field {
    my $self = shift;

    eval {
        Exception::Base->import(
            'Exception::BaseTest::import_defaults::WithNoSuchField',
        );
        Exception::BaseTest::import_defaults::WithNoSuchField->import(
            'exception_basetest_no_such_field' => undef,
        );
    };
    $self->assert_matches(qr/class does not implement default value/, "$@");
};

sub test_import_defaults_verbosity {
    my $self = shift;

    {
        eval {
            Exception::Base->import(
                'Exception::BaseTest::import_defaults::WithVerbosity' => {
                    verbosity => 0,
                 },
            );
        };
        $self->assert_equals('', "$@");

        eval {
            Exception::BaseTest::import_defaults::WithVerbosity->throw(
                message => 'Message',
            )
        };
        my $obj = $@;
        $self->assert($obj->isa("Exception::BaseTest::import_defaults::WithVerbosity"), '$obj->isa("Exception::BaseTest::import_defaults::WithVerbosity")');
        $self->assert($obj->isa("Exception::Base"), '$obj->isa("Exception::Base")');
        $self->assert_equals("", "$obj");
    };

    {
        eval {
            Exception::BaseTest::import_defaults::WithVerbosity->import(
                verbosity => 1,
            );
        };
        $self->assert_equals('', "$@");

        eval {
            Exception::BaseTest::import_defaults::WithVerbosity->throw(
                message => 'Message',
            );
        };
        my $obj = $@;
        $self->assert($obj->isa("Exception::BaseTest::import_defaults::WithVerbosity"), '$obj->isa("Exception::BaseTest::import_defaults::WithVerbosity")');
        $self->assert($obj->isa("Exception::Base"), '$obj->isa("Exception::Base")');
        $self->assert_equals("Message\n", "$obj");
    };
};

sub test_import_defaults_via_loaded_exception {
    my $self = shift;

    local $SIG{__DIE__} = '';

    {
        eval {
            require Exception::BaseTest::LoadedException;
            Exception::BaseTest::LoadedException->import(
                verbosity => 1,
            );
        };
        $self->assert_equals('', "$@");
        eval {
            Exception::BaseTest::LoadedException->throw(
                message => "Message",
            );
        };
        my $obj = $@;
        $self->assert($obj->isa("Exception::BaseTest::LoadedException"), '$obj->isa("Exception::BaseTest::LoadedException")');
        $self->assert($obj->isa("Exception::Base"), '$obj->isa("Exception::Base")');
        $self->assert_equals("Message\n", "$obj");
    };

    {
        eval {
            Exception::Base->throw(
                message => "Message",
            );
        };
        my $obj = $@;
        $self->assert($obj->isa("Exception::Base"), '$obj->isa("Exception::Base")');
        $self->assert_matches(qr/Message at.* line/, "$obj");
    };
};

sub test__collect_system_data {
    my $self = shift;

    {
        package Exception::BaseTest::_collect_system_data::Test1;
        sub sub1 {
        my $obj = shift;
            $obj->_collect_system_data;
            return $obj;
        }
        sub sub2 {
            return sub1 shift();
        }
        sub sub3 {
            return sub2 shift();
        }

        package Exception::BaseTest::_collect_system_data::Test2;
        sub sub1 {
            return Exception::BaseTest::_collect_system_data::Test1::sub1 shift();
        }
        sub sub2 {
            return sub1 shift();
        }
        sub sub3 {
            return sub2 shift();
        }

        package Exception::BaseTest::_collect_system_data::Test3;
        sub sub1 {
            return Exception::BaseTest::_collect_system_data::Test2::sub1 shift();
        }
        sub sub2 {
            return sub1 shift();
        }
        sub sub3 {
            return sub2 shift();
        }
    }

    my $obj1 = Exception::Base->new;
    Exception::BaseTest::_collect_system_data::Test3::sub3($obj1);
    $self->assert_equals('Exception::BaseTest::_collect_system_data::Test2', $obj1->{caller_stack}->[0]->[0]);
    $self->assert_equals('Exception::BaseTest::_collect_system_data::Test1::sub1', $obj1->{caller_stack}->[0]->[3]);
}

sub test__caller_info {
    my $self = shift;

    my $obj = Exception::Base->new;

    $obj->{caller_stack} = [
        ['Package0', 'Package0.pm', 1, 'Package0::func0', 0, undef, undef, undef ],
        ['Package1', 'Package1.pm', 1, 'Package1::func1', 1, undef, undef, undef ],
        ['Package2', 'Package2.pm', 1, 'Package2::func2', 1, undef, undef, undef, 1 ],
        ['Package3', 'Package3.pm', 1, 'Package3::func3', 1, undef, undef, undef, 1, 2, 3, 4, 5, 6, 7, 8],
    ];
    $self->assert_equals('Package0::func0', ${$obj->_caller_info(0)}{sub_name});
    $self->assert_equals('Package1::func1()', ${$obj->_caller_info(1)}{sub_name});
    $self->assert_equals('Package2::func2(1)', ${$obj->_caller_info(2)}{sub_name});
    $self->assert_equals('Package3::func3(1, 2, 3, 4, 5, 6, 7, 8)', ${$obj->_caller_info(3)}{sub_name});
    $obj->{defaults}->{max_arg_nums} = 5;
    $self->assert_equals('Package3::func3(1, 2, 3, 4, ...)', ${$obj->_caller_info(3)}{sub_name});
    $obj->{max_arg_nums} = 10;
    $self->assert_equals('Package3::func3(1, 2, 3, 4, 5, 6, 7, 8)', ${$obj->_caller_info(3)}{sub_name});
    $obj->{max_arg_nums} = 0;
    $self->assert_equals('Package3::func3(1, 2, 3, 4, 5, 6, 7, 8)', ${$obj->_caller_info(3)}{sub_name});
    $obj->{max_arg_nums} = 1;
    $self->assert_equals('Package3::func3(...)', ${$obj->_caller_info(3)}{sub_name});
    $obj->{max_arg_nums} = 2;
    $self->assert_equals('Package3::func3(1, ...)', ${$obj->_caller_info(3)}{sub_name});
    $self->assert_not_null($obj->ATTRS->{max_arg_nums}->{default});
    $self->assert_equals($obj->ATTRS->{max_arg_nums}->{default}, $obj->{defaults}->{max_arg_nums} = $obj->ATTRS->{max_arg_nums}->{default});
}

sub test__get_subname {
    my $self = shift;
    my $obj = Exception::Base->new;
    $self->assert_equals('sub', $obj->_get_subname({subroutine=>'sub'}));
    $self->assert_equals('eval {...}', $obj->_get_subname({subroutine=>'(eval)'}));
    $self->assert_equals("eval 'evaltext'", $obj->_get_subname({subroutine=>'sub', evaltext=>'evaltext'}));
    $self->assert_equals("require evaltext", $obj->_get_subname({subroutine=>'sub', evaltext=>'evaltext', is_require=>1}));
    $self->assert_equals("eval 'eval\\\\\\\'text'", $obj->_get_subname({subroutine=>'sub', evaltext=>'eval\\\'text'}));
    $obj->{defaults}->{max_eval_len} = 5;
    $self->assert_equals("eval 'ev...'", $obj->_get_subname({subroutine=>'sub', evaltext=>'evaltext'}));
    $obj->{max_eval_len} = 10;
    $self->assert_equals("eval 'evaltext'", $obj->_get_subname({subroutine=>'sub', evaltext=>'evaltext'}));
    $obj->{max_eval_len} = 0;
    $self->assert_equals("eval 'evaltext'", $obj->_get_subname({subroutine=>'sub', evaltext=>'evaltext'}));
    $self->assert_not_null($obj->ATTRS->{max_eval_len}->{default});
    $self->assert_equals($obj->ATTRS->{max_eval_len}->{default}, $obj->{defaults}->{max_eval_len} = $obj->ATTRS->{max_eval_len}->{default});
}

sub test__format_arg {
    my $self = shift;
    my $obj = Exception::Base->new;
    $self->assert_equals('undef', $obj->_format_arg());
    $self->assert_equals('""', $obj->_format_arg(''));
    $self->assert_equals('0', $obj->_format_arg('0'));
    $self->assert_equals('1', $obj->_format_arg('1'));
    $self->assert_equals('12.34', $obj->_format_arg('12.34'));
    $self->assert_equals('"A"', $obj->_format_arg('A'));
    $self->assert_equals('"\""', $obj->_format_arg("\""));
    $self->assert_equals('"\`"', $obj->_format_arg("\`"));
    $self->assert_equals('"\\\\"', $obj->_format_arg("\\"));
    $self->assert_equals('"\x{0d}"', $obj->_format_arg("\x{0d}"));
    $self->assert_equals('"\x{c3}"', $obj->_format_arg("\x{c3}"));
    $self->assert_equals('"\x{263a}"', $obj->_format_arg("\x{263a}"));
    $self->assert_equals('"\x{c3}\x{263a}"', $obj->_format_arg("\x{c3}\x{263a}"));
    $self->assert(qr/^.ARRAY/, $obj->_format_arg([]));
    $self->assert(qr/^.HASH/, $obj->_format_arg({}));
    $self->assert(qr/^.Exception::BaseTest=/, $obj->_format_arg($self));
    $self->assert(qr/^.Exception::Base=/, $obj->_format_arg($obj));
    $obj->{defaults}->{max_arg_len} = 5;
    $self->assert_equals('12...', $obj->_format_arg('123456789'));
    $obj->{max_arg_len} = 10;
    $self->assert_equals('123456789', $obj->_format_arg('123456789'));
    $obj->{max_arg_len} = 0;
    $self->assert_equals('123456789', $obj->_format_arg('123456789'));
    $self->assert_not_null($obj->ATTRS->{max_arg_len}->{default});
    $self->assert_equals($obj->ATTRS->{max_arg_len}->{default}, $obj->{defaults}->{max_arg_len} = $obj->ATTRS->{max_arg_len}->{default});
}

sub test__str_len_trim {
    my $self = shift;
    my $obj = Exception::Base->new;
    $self->assert_equals('', $obj->_str_len_trim(''));
    $self->assert_equals('1', $obj->_str_len_trim('1'));
    $self->assert_equals('12', $obj->_str_len_trim('12'));
    $self->assert_equals('123', $obj->_str_len_trim('123'));
    $self->assert_equals('1234', $obj->_str_len_trim('1234'));
    $self->assert_equals('12345', $obj->_str_len_trim('12345'));
    $self->assert_equals('123456789', $obj->_str_len_trim('123456789'));
    $self->assert_equals('', $obj->_str_len_trim('', 10));
    $self->assert_equals('1', $obj->_str_len_trim('1', 10));
    $self->assert_equals('12', $obj->_str_len_trim('12', 10));
    $self->assert_equals('123', $obj->_str_len_trim('123', 10));
    $self->assert_equals('1234', $obj->_str_len_trim('1234', 10));
    $self->assert_equals('12345', $obj->_str_len_trim('12345', 10));
    $self->assert_equals('123456789', $obj->_str_len_trim('123456789', 10));
    $self->assert_equals('', $obj->_str_len_trim('', 2));
    $self->assert_equals('1', $obj->_str_len_trim('1', 2));
    $self->assert_equals('12', $obj->_str_len_trim('12', 2));
    $self->assert_equals('123', $obj->_str_len_trim('123', 2));
    $self->assert_equals('1234', $obj->_str_len_trim('1234', 2));
    $self->assert_equals('12345', $obj->_str_len_trim('12345', 2));
    $self->assert_equals('123456789', $obj->_str_len_trim('123456789', 2));
    $self->assert_equals('', $obj->_str_len_trim('', 3));
    $self->assert_equals('1', $obj->_str_len_trim('1', 3));
    $self->assert_equals('12', $obj->_str_len_trim('12', 3));
    $self->assert_equals('123', $obj->_str_len_trim('123', 3));
    $self->assert_equals('...', $obj->_str_len_trim('1234', 3));
    $self->assert_equals('...', $obj->_str_len_trim('12345', 3));
    $self->assert_equals('...', $obj->_str_len_trim('123456789', 3));
    $self->assert_equals('', $obj->_str_len_trim('', 4));
    $self->assert_equals('1', $obj->_str_len_trim('1', 4));
    $self->assert_equals('12', $obj->_str_len_trim('12', 4));
    $self->assert_equals('123', $obj->_str_len_trim('123', 4));
    $self->assert_equals('1234', $obj->_str_len_trim('1234', 4));
    $self->assert_equals('1...', $obj->_str_len_trim('12345', 4));
    $self->assert_equals('1...', $obj->_str_len_trim('123456789', 4));
    $self->assert_equals('', $obj->_str_len_trim('', 5));
    $self->assert_equals('1', $obj->_str_len_trim('1', 5));
    $self->assert_equals('12', $obj->_str_len_trim('12', 5));
    $self->assert_equals('123', $obj->_str_len_trim('123', 5));
    $self->assert_equals('1234', $obj->_str_len_trim('1234', 5));
    $self->assert_equals('12345', $obj->_str_len_trim('12345', 5));
    $self->assert_equals('12...', $obj->_str_len_trim('123456789', 5));
}

1;
