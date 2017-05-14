use Try::Tiny;
use Exception::Caught;
use Exception::Class qw(Ex);
use Test::More tests => 2;

try { Ex->throw }
catch { ok caught('Ex') };

try {
    try { Ex->throw }
    catch { rethrow };
}
catch {
    ok caught('Ex');
};
