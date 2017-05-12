#line 1
#! /usr/bin/perl -w

package Test::Exception;
use 5.005;
use strict;
use Test::Builder;
use Sub::Uplevel;
use base qw(Exporter);

use vars qw($VERSION @EXPORT @EXPORT_OK);

$VERSION = '0.21';
@EXPORT = qw(dies_ok lives_ok throws_ok lives_and);

my $Tester = Test::Builder->new;

sub import {
    my $self = shift;
    if (@_) {
        my $package = caller;
        $Tester->exported_to($package);
        $Tester->plan(@_);
    };
    $self->export_to_level(1, $self, $_) foreach @EXPORT;
}

#line 76


sub _try_as_caller {
    my $coderef = shift;
    eval { uplevel 3, $coderef };
    return $@;
};


sub _is_exception {
    my $exception = shift;
    ref($exception) || $exception ne '';
};


sub _exception_as_string {
    my ($prefix, $exception) = @_;
    return "$prefix undef" unless defined($exception);
    return "$prefix normal exit" unless _is_exception($exception);
    my $class = ref($exception);
    $exception = "$class ($exception)" 
            if $class && "$exception" !~ m/^\Q$class/;
    chomp($exception);
    return("$prefix $exception");
};


#line 123


sub dies_ok (&;$) {
    my ($coderef, $description) = @_;
    my $exception = _try_as_caller($coderef);
    my $ok = $Tester->ok( _is_exception($exception), $description );
    $@ = $exception;
    return($ok);
}


#line 163

sub lives_ok (&;$) {
    my ($coderef, $description) = @_;
    my $exception = _try_as_caller($coderef);
    my $ok = $Tester->ok(! _is_exception($exception), $description)
        || $Tester->diag(_exception_as_string("died:", $exception));
    $@ = $exception;
    return($ok);
}


#line 220


sub throws_ok (&$;$) {
    my ($coderef, $expecting, $description) = @_;
    $description ||= _exception_as_string("threw", $expecting);
    my $exception = _try_as_caller($coderef);
    my $regex = $Tester->maybe_regex($expecting);
    my $ok = $regex ? ($exception =~ m/$regex/) 
            : UNIVERSAL::isa($exception, ref($expecting) || $expecting);
    $Tester->ok($ok, $description);
    unless ($ok) {
        $Tester->diag( _exception_as_string("expecting:", $expecting) );
        $Tester->diag( _exception_as_string("found:", $exception) );
    };
    $@ = $exception;
    return($ok);
};


#line 268

sub lives_and (&$) {
    my ($test, $description) = @_;
    {
        local $Test::Builder::Level = $Test::Builder::Level+1;
        my $ok = \&Test::Builder::ok;
        no warnings;
        local *Test::Builder::ok = sub {
            $_[2] = $description unless defined $_[2];
            $ok->(@_);
        };
        use warnings;
        eval { $test->() } and return 1;
    };
    my $exception = $@;
    if (_is_exception($exception)) {
        $Tester->ok(0, $description);
        $Tester->diag( _exception_as_string("died:", $exception) );
    };
    $@ = $exception;
    return;
}

#line 367

1;
