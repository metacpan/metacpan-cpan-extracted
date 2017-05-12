use strict;
use warnings;
use Test::More;
use FindBin;
use lib ($FindBin::RealBin);
use testlib::Utils qw(newf);
use testlib::Croak;
use Test::Builder;
use Carp;

$Carp::Verbose = 0;

sub test_error_here {
    my ($f, $msg) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $executed = 0;
    $f->catch(sub {
        my $e = shift;
        like($e, qr{at .*failure-position\.t +line}, $msg);
        note($e);
        $executed = 1;
    });
    ok($executed, "catcher callback executed");
}

note("------ failure should be reported from the user's perspective.");

{
    note("--- die() method");
    my $f = newf()->die("died here");
    test_error_here($f, "die() method reports the error here");
}

{
    note("--- die() method on return future");
    my $f = newf()->fulfill()->then(sub {
        return newf()->die("died here");
    });
    test_error_here($f, "die() method on return future reports the error here");
}

{
    note("--- throw in then() callback");
    my $f = newf()->fulfill()->then(sub {
        die "died here";
    });
    test_error_here($f, "throwing an exception in then() callback reports the error here");
}

{
    note("--- return died future in try()");
    my $f = Future::Q->try(sub {
        return newf()->die("died here");
    });
    test_error_here($f, "died future returned in try() callback reportes the error here");
}

{
    note("--- throw in try()");
    my $f = Future::Q->try(sub {
        die "died here";
    });
    test_error_here($f, "throwing an excetpion in try() callback reports the error here");
}

{
    note("--- try() with junk");
    my $f = Future::Q->try();
    test_error_here($f, "try() with junk reports the error here");
}

foreach my $func (qw(croak_in_try croak_in_fcall croak_in_then_fulfilled croak_in_then_rejected croak_in_catch)){
    note("--- $func");
    my $f = testlib::Croak->$func();
    test_error_here($f, "$func reports the error here");
}

{
    note("--- croak_in_then_pending_fulfilled");
    my ($child, $parent) = testlib::Croak->croak_in_then_pending_fulfilled();
    $parent->fulfill("OK");
    test_error_here($child, "croak_in_then_pending_fulfilled reports the error here");
}

foreach my $func (qw(croak_in_then_pending_rejected croak_in_catch_pending)) {
    note("--- $func");
    my ($child, $parent) = testlib::Croak->$func();
    $parent->reject("NG");
    test_error_here($child, "$func reports the error here");
}

done_testing();

