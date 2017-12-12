#!/usr/bin/perl -T
# Yes, we want to make sure things work in taint mode

#
# Copyright (C) 2015-2017 Joelle Maslak
# All Rights Reserved - See License
#

# Basic testing

use Test::More tests => 12;

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

