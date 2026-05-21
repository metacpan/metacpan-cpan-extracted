#!/usr/bin/env perl

use v5.8;
use warnings;
use utf8;

use Test2::V0;

require Devel::Bug;

# ---------------------------------------------------------------------------
# 1. Default export installs bug() in caller namespace
# ---------------------------------------------------------------------------

{ package T::Default; Devel::Bug->import(out => *STDERR) }

ok defined &T::Default::bug, 'default export installs bug()';

# ---------------------------------------------------------------------------
# 2. Custom name via bug => 'name'
# ---------------------------------------------------------------------------

{ package T::Renamed; Devel::Bug->import(out => *STDERR, bug => 'dbg') }

ok  defined &T::Renamed::dbg, 'custom name installed';
ok !defined &T::Renamed::bug, 'original name not installed when renamed';

# ---------------------------------------------------------------------------
# 3. Export suppressed with bug => 0
# ---------------------------------------------------------------------------

{ package T::SuppressZero; Devel::Bug->import(out => *STDERR, bug => 0) }

ok !defined &T::SuppressZero::bug, 'export suppressed with bug => 0';

# ---------------------------------------------------------------------------
# 4. Export suppressed with bug => ''
# ---------------------------------------------------------------------------

{ package T::SuppressEmpty; Devel::Bug->import(out => *STDERR, bug => '') }

ok !defined &T::SuppressEmpty::bug, 'export suppressed with bug => ""';

# ---------------------------------------------------------------------------
# 5. Option aliases accepted
# ---------------------------------------------------------------------------

# Output
ok lives { Devel::Bug->import(output => *STDERR)               }, "alias 'output' (=> out) accepted";
ok lives { Devel::Bug->import(o      => *STDERR)               }, "alias 'o' (=> out) accepted";
ok lives { my $b; open my $fh, '>', \$b; Devel::Bug->import(out => $fh) },
    'lexical filehandle accepted as out';

# Colors
ok lives { Devel::Bug->import(out => *STDERR, ic => 'bold')    }, "alias 'ic' (=> infocolor) accepted";
ok lives { Devel::Bug->import(out => *STDERR, lc => 'bold')    }, "alias 'lc' (=> labelcolor) accepted";
ok lives { Devel::Bug->import(out => *STDERR, vc => 'red')     }, "alias 'vc' (=> valcolor) accepted";

# Display
ok lives { Devel::Bug->import(out => *STDERR, ml  => 1)        }, "alias 'ml' (=> multiline) accepted";
ok lives { Devel::Bug->import(out => *STDERR, m   => 1)        }, "alias 'm' (=> multiline) accepted";
ok lives { Devel::Bug->import(out => *STDERR, indexes => 1)    }, "alias 'indexes' (=> indices) accepted";
ok lives { Devel::Bug->import(out => *STDERR, index   => 1)    }, "alias 'index' (=> indices) accepted";
ok lives { Devel::Bug->import(out => *STDERR, i   => 1)        }, "alias 'i' (=> indices) accepted";
ok lives { Devel::Bug->import(out => *STDERR, '@' => 1)        }, "alias '\@' (=> indices) accepted";
ok lives { Devel::Bug->import(out => *STDERR, kv  => 1)        }, "alias 'kv' (=> keyval) accepted";
ok lives { Devel::Bug->import(out => *STDERR, k   => 1)        }, "alias 'k' (=> keyval) accepted";
ok lives { Devel::Bug->import(out => *STDERR, '%' => 1)        }, "alias '\%' (=> keyval) accepted";

# Caller info
ok lives { Devel::Bug->import(out => *STDERR, pkg  => 1)       }, "alias 'pkg' (=> package) accepted";
ok lives { Devel::Bug->import(out => *STDERR, p    => 1)       }, "alias 'p' (=> package) accepted";
ok lives { Devel::Bug->import(out => *STDERR, fn   => 1)       }, "alias 'fn' (=> filename) accepted";
ok lives { Devel::Bug->import(out => *STDERR, f    => 1)       }, "alias 'f' (=> filename) accepted";
ok lives { Devel::Bug->import(out => *STDERR, line => 1)       }, "alias 'line' (=> lineno) accepted";
ok lives { Devel::Bug->import(out => *STDERR, ln   => 1)       }, "alias 'ln' (=> lineno) accepted";
ok lives { Devel::Bug->import(out => *STDERR, l    => 1)       }, "alias 'l' (=> lineno) accepted";

# Val
ok lives { Devel::Bug->import(out => *STDERR, value    => '[X]') }, "alias 'value' (=> val) accepted";
ok lives { Devel::Bug->import(out => *STDERR, v        => '[X]') }, "alias 'v' (=> val) accepted";
ok lives { Devel::Bug->import(out => *STDERR, override => '[X]') }, "alias 'override' (=> val) accepted";

# ---------------------------------------------------------------------------
# 6. Unknown option causes error
# ---------------------------------------------------------------------------

like(
    dies { Devel::Bug->import(nosuchoption => 1) },
    qr/Unknown option/,
    'unknown option causes error',
);

# ---------------------------------------------------------------------------
# 7. Illegal export name causes error
# ---------------------------------------------------------------------------

like(
    dies { Devel::Bug->import(out => *STDERR, bug => '1invalid') },
    qr/Illegal characters/,
    'illegal export name causes error',
);

# ---------------------------------------------------------------------------
# 8. Invalid flag in colon-flag string causes error
# ---------------------------------------------------------------------------

like(
    dies { Devel::Bug->import(':q') },
    qr/Unknown option/,
    'invalid flag causes error',
);

# ---------------------------------------------------------------------------
# 9. Import-time colon-flag string accepted
# ---------------------------------------------------------------------------

ok lives { Devel::Bug->import(':p')                    }, "import-time ':p' flag accepted";
ok lives { Devel::Bug->import(':fi')                   }, "import-time ':fi' flags accepted";
ok lives { Devel::Bug->import(':p', out => *STDERR)    }, "import-time flag with option accepted";
ok lives { Devel::Bug->import('default_label')         }, 'import-time label accepted';
ok lives { Devel::Bug->import('default_label:fi')      }, 'import-time label with flags accepted';

done_testing;
