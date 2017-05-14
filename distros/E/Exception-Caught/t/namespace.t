package MyPackage;
use Try::Tiny;
use Exception::Class qw(MyEx);
use Exception::Caught;

sub go {
    try { MyEx->throw }
    catch {
        rethrow unless caught('MyEx');
    };
}

package main;
use Test::More tests => 2;
ok(!MyPackage->can('caught'));
ok(!MyPackage->can('rethrow'));
