#!/usr/bin/perl -al

package My::Eval;
our $n = 0;
sub test {
    eval { 1; };
    $n++;
}


package My::Ok;
our $n = 0;
sub test {
    eval { opendir F, '.' and close F; };
    $n++;
}


package My::DieScalar;
our $n = 0;
sub test {
    eval { opendir F, '/filenotfound' or die "Message\n"; };
    if ($@ eq "Message\n") { $n++; }
}


package My::DieObject;
our $n = 0;
sub test {
    eval { opendir F, '/filenotfound' or throw My::DieObject };
    if ($@ and $@->isa('My::DieObject')) { $n++; }
}
sub throw {
    my %args = @_;
    die bless {%args}, shift;
}


package My::FatalOk;
our $n = 0;
sub test {
    use Fatal 'opendir';
    eval { opendir F, '.' and close F; };
    $n++;
}


package My::Fatal;
our $n = 0;
sub test {
    use Fatal 'opendir';
    eval { opendir F, '/filenotfound' };
    if ($@ and $@ ne '') { $n++; }
}


package My::ExceptionBase;
use lib '../lib';	
use Exception::Base;
our $n = 0;
sub test {
    eval {
        opendir F, '/filenotfound' or Exception::Base->throw(message=>'Message');
    };
    if ($@) {
        my $e = Exception::Base->catch;
        if ($e->isa('Exception::Base') and $e->matches('Message')) { $n++; }
    }
}


package My::ExceptionBase1;
use lib 'lib';	
use Exception::Base;
our $n = 0;
sub test {
    eval {
        opendir F, '/filenotfound' or Exception::Base->throw(message=>'Message', verbosity=>1);
    };
    if ($@) {
        my $e = Exception::Base->catch;
        if ($e->isa('Exception::Base') and $e->matches('Message')) { $n++; }
    }
}


package My::FatalExceptionOk;
our $n = 0;
sub test {
    use Fatal::Exception 'Exception::Base' => 'opendir';
    eval { open F, '.' and close F; };
    $n++;
}


package My::FatalException;
our $n = 0;
sub test {
    use Exception::Base ':all';
    use Fatal::Exception 'Exception::Base' => 'opendir';
    eval {
        opendir F, '/filenotfound';
    };
    if ($@) {
        my $e = Exception::Base->catch;
        if ($e->isa('Exception::Base') and $e->matches('Message')) { $n++; }
    }
}


package main;

use Benchmark ':all';

my $result = timethese(-1, {
    '1_Ok'                      => sub { My::Ok::test; },
    '2_DieScalar'               => sub { My::DieScalar::test; },
    '3_DieObject'               => sub { My::DieObject::test; },
    '4_FatalOk'                 => sub { My::FatalOk::test; },
    '5_Fatal'                   => sub { My::Fatal::test; },
    '6_ExceptionBase'           => sub { My::ExceptionBase::test; },
    '7_ExceptionBase1'          => sub { My::ExceptionBase1::test; },
    '8_FatalExceptionOk'        => sub { My::FatalExceptionOk::test; },
    '9_FatalException'          => sub { My::FatalException::test; },
});

cmpthese($result);
