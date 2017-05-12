use strict;
use Test::More;
use Test::Output;

use Log::Minimal::Indent;

stderr_like{ warnf("Before foo") }                          qr{\d \Q[WARN] Before foo};
{ # foo
    stderr_like{ Log::Minimal::Indent->forward("FOO") }     qr{\d \Q[INFO] <Entering FOO>};
    stderr_like{ warnf "Running foo" }                      qr{\d \Q  [WARN] Running foo};
    { # bar
        stderr_like{ Log::Minimal::Indent->forward("BAR") } qr{\d \Q  [INFO] <Entering BAR>};
        stderr_like{ warnf "Running bar" }                  qr{\d \Q    [WARN] Running bar};
        stderr_like{ Log::Minimal::Indent->back("BAR") }    qr{\d \Q  [INFO] <Exited BAR};
    }
    stderr_like{ Log::Minimal::Indent->back("FOO") }        qr{\d \Q[INFO] <Exited FOO>};
}
stderr_like{ warnf("After foo") }                           qr{\d \Q[WARN] After foo};


done_testing;

