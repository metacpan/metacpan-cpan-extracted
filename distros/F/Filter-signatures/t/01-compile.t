#!perl -w
use strict;
use Test::More tests => 8;
use Data::Dumper;

BEGIN{ $ENV{FORCE_FILTER_SIGNATURES} = 1; };
use vars '$TODO';
$TODO = "Eval-compile and Filter::Simple don't play together";

my $sub = eval <<'PERL';
    use Filter::signatures;
    use feature 'signatures';
    sub ($name, $value) {
        return "'$name' is '$value'"
    }
PERL

SKIP: {
    is ref $sub, 'CODE', "we can compile a simple subroutine"
        or skip $@ => 1;
    is $sub->("Foo", 'bar'), "'Foo' is 'bar'", "Passing parameters works";
}

$sub = eval <<'PERL';
    use Filter::signatures;
    use feature 'signatures';
    sub ($name, $value, @) {
        return "'$name' is '$value'"
    }
PERL

SKIP: {
is ref $sub, 'CODE', "we can compile a simple subroutine"
    or skip $@ => 2;

{
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, \@_};
    is $sub->("Foo", 'bar', 'baz'), "'Foo' is 'bar'", "Passing parameters works";
    is_deeply \@warnings, [], "No warnings get raised during call"
        or diag Dumper \@warnings;
}
}

# Test our synopsis
$sub = eval <<'PERL';
    use Filter::signatures;
    no warnings 'experimental::signatures'; # does not raise an error
    use feature 'signatures'; # this now works on <5.16 as well
    
    sub ( $name ) {
        "Hello $name";
    }
PERL

SKIP: {
is ref $sub, 'CODE', "we can compile a simple subroutine"
    or skip $@ => 2;

{
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, \@_};
    is $sub->('world'), "Hello world", "Passing parameters works";
    is_deeply \@warnings, [], "No warnings get raised during call"
        or diag Dumper \@warnings;
}
}
