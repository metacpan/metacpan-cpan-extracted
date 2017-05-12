#!/usr/bin/perl -al

use lib 'lib', '../lib';

BEGIN {
    package My::Common;
    *throw_something = $0 =~ /_ok/ ? sub () { 0 } : sub () { 1 };
}

{
    package My::EvalDieScalar;
    sub test {
        eval {
            die 'Message' if My::Common::throw_something;
        };
        if ($@ =~ /^Message/) {
            1;
        }
    }
}

{
    package My::EvalDieObject;
    sub test {
        eval {
             My::EvalDieObject->throw if My::Common::throw_something;
        };
        if ($@) {
            my $e = $@;
            if (ref $e and $e->isa('My::EvalDieObject')) {
                1;
            }
        }
    }
    sub throw {
        my %args = @_;
        die bless {%args}, shift;
    }
}

{
    package My::ExceptionEval;
    use Exception::Base 'Exception::My';
    sub test {
        eval {
            Exception::My->throw(message=>'Message') if My::Common::throw_something;
        };
        if ($@) {
	    my $e = Exception::Base->catch;
            if ($e->isa('Exception::My') and $e->matches('Message')) {
                1;
            }
        }
    }
}

{
    package My::ExceptionSystemEval;
    use Exception::Base 'Exception::System';
    sub test {
        eval {
            Exception::System->throw(message=>'Message') if My::Common::throw_something;
        };
        if ($@) {
	    my $e = Exception::Base->catch;
            if ($e->isa('Exception::System') and $e->matches('Message')) {
                1;
            }
        }
    }
}

{
    package My::Exception1Eval;
    use Exception::Base 'Exception::My';
    sub test {
        eval {
            Exception::My->throw(message=>'Message', verbosity=>1) if My::Common::throw_something;
        };
        if ($@) {
	    my $e = Exception::Base->catch;
            if ($e->isa('Exception::My') and $e->matches('Message')) {
                1;
            }
        }
    }
}

{
    package My::ExceptionSystem1Eval;
    use Exception::Base 'Exception::System';
    sub test {
        eval {
            Exception::System->throw(message=>'Message', verbosity=>1) if My::Common::throw_something;
        };
        if ($@) {
	    my $e = Exception::Base->catch;
            if ($e->isa('Exception::System') and $e->matches('Message')) {
                1;
            }
        }
    }
}

eval q{
    package My::Error;
    use Error qw(:try);
    sub test {
        try {
            Error::Simple->throw('Message') if My::Common::throw_something;
        }
        Error->catch(with {
            my $e = $_[0];
            if ($e->text eq 'Message') {
                1;
            }
        });
    }
};

eval q{
    package My::ErrorSystem;
    use Error qw(:try);
    use Error::SystemException;
    sub test {
        try {
            Error::SystemException->throw('Message') if My::Common::throw_something;
        }
        Error->catch(with {
            my $e = $_[0];
            if ($e->text eq 'Message') {
                1;
            }
        });
    }
};


package main;

use Benchmark ':all';

my %tests = (
    '01_EvalDieScalar'             => sub { My::EvalDieScalar->test },
    '02_EvalDieObject'             => sub { My::EvalDieObject->test },
    '03_ExceptionEval'             => sub { My::ExceptionEval->test },
    '04_ExceptionSystemEval'       => sub { My::ExceptionSystemEval->test },
    '05_Exception1Eval'            => sub { My::Exception1Eval->test },
    '06_ExceptionSystem1Eval'      => sub { My::ExceptionSystem1Eval->test },
);
$tests{'07_Error'}                  = sub { My::Error->test }                if eval { Error->VERSION };
$tests{'08_ErrorSystem'}            = sub { My::ErrorSystem->test }          if eval { Error::SystemException->can('new') };

print "Benchmark for ", (My::Common::throw_something ? "FAIL" : "OK"), "\n";
my $result = timethese($ARGV[0] || -1, { %tests });
cmpthese($result);
