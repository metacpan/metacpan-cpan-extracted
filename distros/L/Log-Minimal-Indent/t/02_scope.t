use strict;
use Test::More;
use Test::Output;

use Log::Minimal::Indent;

stderr_like{ warnf("Before foo") }                          qr{\d \Q[WARN] Before foo};
{ # foo
    indent_log_scope("FOO", "MUTE");
    stderr_like{ warnf "Running foo" }                      qr{\d \Q  [WARN] Running foo};
    { # bar
        indent_log_scope("BAR", "MUTE");
        stderr_like{ warnf "Running bar" }                  qr{\d \Q    [WARN] Running bar};
    }
    stderr_like{ warnf "After bar" }                        qr{\d \Q  [WARN] After bar};
}
stderr_like{ warnf("After foo") }                           qr{\d \Q[WARN] After foo};


done_testing;

