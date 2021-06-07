#!/usr/bin/perl -T
# Yes, we want to make sure things work in taint mode

#
# Copyright (C) 2015-2021 Joelle Maslak
# All Rights Reserved - See License
#

# Basic testing

use Test::More tests => 17;

# Instantiate the object
require_ok('JCM::Boilerplate');

# Verify switch statement works
# (This is turned on in the boilerplate)
eval {
    use JCM::Boilerplate;

    my $test = 1;
    given ($test) {
        when (/1/) {
            pass('Boilerplate works!');
        }
    }
} or fail('Boilerplate fails');

eval {
    package foo_script {
        use JCM::Boilerplate 'script';
    }
    pass('Boilerplate script tag works');
} or fail('Boilerplate script tag works');

eval {
    package foo_class {
        use JCM::Boilerplate 'class';
    }
    pass('Boilerplate class tag works');
} or fail('Boilerplate class tag works');

eval {
    package foo_role {
        use JCM::Boilerplate 'role';
    }
    pass('Boilerplate role tag works');
} or fail('Boilerplate role tag works');

$ret = eval {
    my $x = 'abc';
    local $SIG{__WARN__} = sub { };
    eval(
        "use JCM::Boilerplate 'script'; if (\$x =~ m/\\xabc/) { warn('Should not see this'); }; 1");
};
if ($ret) {
    fail('Invalid regex under strict mode dies');
} else {
    pass('Invalid regex under strict mode dies');
}


#
# Same thing, but for JTM
#

# Instantiate the object
require_ok('JTM::Boilerplate');

# Verify switch statement works
# (This is turned on in the boilerplate)
eval {
    use JTM::Boilerplate;

    my $test = 1;
    given ($test) {
        when (/1/) {
            pass('Boilerplate works!');
        }
    }
} or fail('Boilerplate fails');

eval {
    package foo_script {
        use JTM::Boilerplate 'script';
    }
    pass('Boilerplate script tag works');
} or fail('Boilerplate script tag works');

eval {
    package foo_class {
        use JTM::Boilerplate 'class';
    }
    pass('Boilerplate class tag works');
} or fail('Boilerplate class tag works');

eval {
    package foo_role {
        use JTM::Boilerplate 'role';
    }
    pass('Boilerplate role tag works');
} or fail('Boilerplate role tag works');

$ret = eval {
    my $x = 'abc';
    local $SIG{__WARN__} = sub { };
    eval(
        "use JTM::Boilerplate 'script'; if (\$x =~ m/\\xabc/) { warn('Should not see this'); }; 1 ");
};
if ($ret) {
    fail('Invalid regex under strict mode dies');
} else {
    pass('Invalid regex under strict mode dies');
}

# Verify indirect mode doesn't work.
SKIP: {
    skip "Indirect test only works on >= 5.32", 1 if $PERL_VERSION lt v5.32.0;
    local $SIG{__WARN__} = sub { };

    $ret = eval '
        use JTM::Boilerplate;

        package foo {
            sub new {
                my $class = shift;
                return bless {}, $class;
            }
            sub testing {
                my $self = shift;
                return 1;
            }
        }

        my $f = foo->new();
        testing $f;
        1;
    ';
    if (!defined $ret) {
        pass('Indirect syntax dies');
    } else {
        fail('Indirect syntax does not die');
    }
}

# Verify ISA does work
SKIP: {
    skip "Indirect test only works on >= 5.32", 1 if $PERL_VERSION lt v5.32.0;
    local $SIG{__WARN__} = sub { };

    $ret = eval '
        use JTM::Boilerplate;

        package foo {
            sub new {
                my $class = shift;
                return bless {}, $class;
            }
            sub testing {
                my $self = shift;
                return 1;
            }
        }

        my $f = foo->new();
        if ($f isa foo) {
            return 1;
        } else {
            return 0;
        }
    ';
    if (!defined $ret) {
        fail('isa not working');
    } else {
        pass('isa works');
    }
}

# Verify bareword filehandles don't work.
SKIP: {
    skip "No bareword filehandle test only works on >= 5.34", 1 if $PERL_VERSION lt v5.34.0;
    local $SIG{__WARN__} = sub { };

    $ret = eval '
        use JTM::Boilerplate;

        open FH, ">>a.txt";
        1;
    ';
    if (!defined $ret) {
        pass('Bareword filehandle dies');
    } else {
        fail('Bareword filehandle does not die');
    }
}

# Verify multidimensional array emulation doesn't work.
SKIP: {
    skip "No multidimensional test only works on >= 5.34", 1 if $PERL_VERSION lt v5.34.0;
    local $SIG{__WARN__} = sub { };

    $ret = eval '
    use JTM::Boilerplate;

        my %foo;
        $foo{"1", "2"} = 3;
        1;
    ';
    if (!defined $ret) {
        pass('Multidimensional emulation dies');
    } else {
        fail('Multidimensional emulation does not die');
    }
}

# Verify try/catch
SKIP: {
    skip "try/catch only woks on >= 5.34", 1 if $PERL_VERSION lt v5.34.0;
    $ret = eval '
        use JTM::Boilerplate;

        try {
            my $foo = 1 / 0;    # Div by zero
        } catch ($e) {
            return 1;
        }
    ';
    if (defined $ret and $ret == 1) {
        pass('try/catch working');
    } else {
        fail('try/catch not working');
    }
}
