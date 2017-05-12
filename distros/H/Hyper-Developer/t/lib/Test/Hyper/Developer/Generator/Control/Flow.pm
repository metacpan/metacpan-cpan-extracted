package Test::Hyper::Developer::Generator::Control::Flow;

use strict;
use warnings;

use diagnostics;
use Test::More;

use base qw(Test::Class::Hyper::Developer);

sub startup : Test(startup => 1) {
    # do everything you need to once before tests start here

    use_ok('Hyper::Developer::Generator::Control::Flow');
    # manipulate @ISA to call restricted methods
    push @Test::Hyper::Developer::Generator::Control::Flow::ISA,
        'Hyper::Developer::Generator::Control::Flow';
}

sub shutdown : Test(shutdown) {
    # do everything you need to do after testing finished here
}

sub setup : Test(setup) {
    # do everything you need to do before every test here
}

sub teardown : Test(teardown) {
    # do everything you need to do after every test here
}



sub flow :Test(60) {
    my $obj;
    ok($obj = Hyper::Developer::Generator::Control::Flow->new( {
        usecase   => 'bla',
        service   => 'blub',
        namespace => 'Sample',
        base_path => Hyper::Singleton::Context
            ->singleton()
            ->get_config()
            ->get_base_path()
    }
    ), 'Object creation');

    my %actiondata = actiondata_valid();
    # make order foreseeable
    for my $line (sort keys %actiondata) {
        my $expected = $actiondata{ $line };
        eval {
            my $got = $obj->_create_action_code($line);
            is $got, $expected, $line;
        };
        fail "$line : $@" if $@;
    }
    # invalid actions
    for my $line (actiondata_invalid()) {
        eval { $obj->_create_action_code($line) };
        pass $line if $@;
    }

    my %conditiondata = conditiondata_valid();
    for my $line (sort keys %conditiondata) {
        my $expected = $conditiondata{$line};
        eval {
            my $got = $obj->_create_condition_code($line);
            is $got, $expected, $line;
        };
        fail "$line : $@" if $@;
    }

}

sub conditiondata_valid {
    return (
        q{mOscar eq 'true'}
            => q{$self->get_value_recursive([qw(mOscar)]) eq 'true'},
        q{'a'}
            => q{'a'},
        q{mGroovyMovie.mOscar ne 'grrzwrrz("drrrz")'}
            => q{$self->get_value_recursive([qw(mGroovyMovie mOscar)]) ne 'grrzwrrz("drrrz")'},
        'mGroovyMovie.mOscar == 123'
            => '$self->get_value_recursive([qw(mGroovyMovie mOscar)]) == 123',
        'mGroovyMovie.mOscar == mGroovyMovie.mHimbeere'
            => '$self->get_value_recursive([qw(mGroovyMovie mOscar)]) == $self->get_value_recursive([qw(mGroovyMovie mHimbeere)])',
        # with logop
        'mGroovyMovie.mOscar == 1 && mGroovyMovie.mHimbeere == 30'
            => '$self->get_value_recursive([qw(mGroovyMovie mOscar)]) == 1 && $self->get_value_recursive([qw(mGroovyMovie mHimbeere)]) == 30',
        # with method call
        'testMe()'
            => '$self->testMe()',
        'mGroovyMovie.mOscar == Get_Value() || mHimbeere == mOscar.himbeere.value()'
            => '$self->get_value_recursive([qw(mGroovyMovie mOscar)]) == $self->Get_Value() || $self->get_value_recursive([qw(mHimbeere)]) == $self->get_value_recursive([qw(mOscar himbeere)])->value()',
        # complex
        q{this._get_action() eq 'change'}
            => q{$self->_get_action() eq 'change'},
        '"a" == b && "c" eq d or "e" ne f and "g" != h'
            => '"a" == $self->get_value_recursive([qw(b)]) && "c" eq $self->get_value_recursive([qw(d)]) or "e" ne $self->get_value_recursive([qw(f)]) and "g" != $self->get_value_recursive([qw(h)])',
        'a.b or b.c or x.y and b.c or t.x'
            => '$self->get_value_recursive([qw(a b)]) or $self->get_value_recursive([qw(b c)]) or $self->get_value_recursive([qw(x y)]) and $self->get_value_recursive([qw(b c)]) or $self->get_value_recursive([qw(t x)])',
        'cSummary.state eq "trslaInventoryData" || cSummary.state eq "trslaSupportData" || cSummary.state eq "trslaLocationData"'
            => '$self->get_value_recursive([qw(cSummary state)]) eq "trslaInventoryData" || $self->get_value_recursive([qw(cSummary state)]) eq "trslaSupportData" || $self->get_value_recursive([qw(cSummary state)]) eq "trslaLocationData"',
        # with negative number
        'cLockedSelect.Locked == -1'
            => '$self->get_value_recursive([qw(cLockedSelect Locked)]) == -1',
    )
}

sub actiondata_valid {
    return (
    # <@identifier> "=" <constant>
    'cIdentToConstant = 1;'
        => '$self->set_value_recursive([qw(cIdentToConstant)], 1);',
    'cIdentToConstant = 123;'
        => '$self->set_value_recursive([qw(cIdentToConstant)], 123);',
    # <@identifier> "=" <method>
    'cIdentToConstant = cTest.checked();'
        => '$self->set_value_recursive([qw(cIdentToConstant)], $self->get_value_recursive([qw(cTest)])->checked());',
    'cIdentToConstant = cTest.cExtended.checked();'
        => '$self->set_value_recursive([qw(cIdentToConstant)], $self->get_value_recursive([qw(cTest cExtended)])->checked());',
    # <@identifier> "=" <@identifier>
    'cIdent = mIdent;'
        => '$self->set_value_recursive([qw(cIdent)], $self->get_value_recursive([qw(mIdent)]));',
    # <method>
    'testMethod();'      => '$self->testMethod();',
    'this.testMethod();' => '$self->testMethod();',
    # <@identifier> <method>
    'myControl.anotherMethod();'
        => '$self->get_value_recursive([qw(myControl)])->anotherMethod();',
    'myControl.embeddedControl.anotherMethod();'
        => '$self->get_value_recursive([qw(myControl embeddedControl)])->anotherMethod();',
    # <@identifier> ::= <identifier> ( "." <identifier>)*
    'cIdent.With.Dot = 123;'
        => '$self->set_value_recursive([qw(cIdent With Dot)], 123);',
    'cIdent.With_Score.Dot = 123;'
        => '$self->set_value_recursive([qw(cIdent With_Score Dot)], 123);',
    # quoting with escaped quote chars
    q{cIdentToConstant = 'esc. single \' quote ';} => q{$self->set_value_recursive([qw(cIdentToConstant)], 'esc. single \' quote ');},
    q{cIdentToConstant = 'esc. single quote \'';} => q{$self->set_value_recursive([qw(cIdentToConstant)], 'esc. single quote \'');},
    'cIdentToConstant = "esc. double \" quote ";' => '$self->set_value_recursive([qw(cIdentToConstant)], "esc. double \" quote ");',
    'cIdentToConstant = "esc. double quote \"";' => '$self->set_value_recursive([qw(cIdentToConstant)], "esc. double quote \"");',
    # single ids are alphanumeric <identifier> ::= /\b[A-z0-9_]+\b/
    'ABCDEFGHIJKLM = 123;'
        => '$self->set_value_recursive([qw(ABCDEFGHIJKLM)], 123);',
    'NOPQRSTUVWXYZ = 123;'
        => '$self->set_value_recursive([qw(NOPQRSTUVWXYZ)], 123);',
    'abcdefghijklm = 123;'
        => '$self->set_value_recursive([qw(abcdefghijklm)], 123);',
    'nopqrstuvwxyz = 123;'
        => '$self->set_value_recursive([qw(nopqrstuvwxyz)], 123);',
    # constant ::= ['"0-9].*  - constants start with ', " or numbers
    q{cSingleQuote = 'abc';}
        => q{$self->set_value_recursive([qw(cSingleQuote)], 'abc');},
    q{cSingleQuote = '123';}
        => q{$self->set_value_recursive([qw(cSingleQuote)], '123');},
    q{cSingleQuote = '^!"$%&/()=?[]@+~,;:.-<>|';}  
        => q{$self->set_value_recursive([qw(cSingleQuote)], '^!"$%&/()=?[]@+~,;:.-<>|');},
    q{cDoubleQuote = "abcXYZ";}
        => q{$self->set_value_recursive([qw(cDoubleQuote)], "abcXYZ");},
    q{cDoubleQuote = "it's o.k.";}
        => q{$self->set_value_recursive([qw(cDoubleQuote)], "it's o.k.");},
    'cNumber = 123;'    => '$self->set_value_recursive([qw(cNumber)], 123);',
    'cNumber = 123_456_789_012;'
        => '$self->set_value_recursive([qw(cNumber)], 123_456_789_012);',
    'cNumber = 47.11;'  => '$self->set_value_recursive([qw(cNumber)], 47.11);',
    'cNumber = 08.15;'  => '$self->set_value_recursive([qw(cNumber)], 08.15);',
    # white space
    ' cSpace = 123;'    => '$self->set_value_recursive([qw(cSpace)], 123);',
    'cSpace= 123;'      => '$self->set_value_recursive([qw(cSpace)], 123);',
    'cSpace =123;'      => '$self->set_value_recursive([qw(cSpace)], 123);',
    'cSpace = 123 ;'    => '$self->set_value_recursive([qw(cSpace)], 123);',
    'cSpace = 123; '    => '$self->set_value_recursive([qw(cSpace)], 123);',
    # ignorables
    'cSpace = 123;;'    => '$self->set_value_recursive([qw(cSpace)], 123);',
    # comment
    'cSpace = 123;# comment'
        => '$self->set_value_recursive([qw(cSpace)], 123);',
    'cSpace = 123; # comment;'
        => '$self->set_value_recursive([qw(cSpace)], 123);',
    'cSpace = 123; # comment;#'
        => '$self->set_value_recursive([qw(cSpace)], 123);',
    );
}

sub actiondata_invalid {
    return (
    # invalid constant number
    'cIdentToConstant = _123;',
    'cIdentToConstant = 123_;',
    'cNumber = 47e15;',
    'cNumber = 47E15;',
    # invalid variable(s)
    'I.3_ly.mixed.4.u = 123;',
    'I.3_ly.o.?.u = 123;',
    'I.3_ly.o.?.u = 123;',
    # invalid method
    'testMethod(_);',
    # invalid assignment
    '0123456789 = 123;',
    '_ = 123;',
    # invalid quoting
    q{'Single Quote ' without escape'},
    q{"Double Quote " without escape"},
    );
}

#
#sub actiondata {
#    return << 'EOAD';
#
#cSelectStuff = 123;
#cSelectStuff.Constant = 'Blafatz';
#mAffe.mProcessType="test";
#cSelectPerson.mRole = mInitiatorRole;
#cSelectPerson.mInitiator=mInitiatorData.mInitiator;
#testMethod();
#a.testMethod();
#that.testMethod();
#a.b.c.testMethod();
#
#EOAD
#}

1;
