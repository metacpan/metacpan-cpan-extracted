#!/usr/bin/env perl

use v5.8;
use warnings;
use utf8;

use Test2::V0;

# ---------------------------------------------------------------------------
# 1. Module loads
# ---------------------------------------------------------------------------

ok lives { require Devel::Bug }, 'Devel::Bug loads';

# ---------------------------------------------------------------------------
# 2. Dependencies available
# ---------------------------------------------------------------------------

ok lives { require Term::ANSIColor }, 'Term::ANSIColor available';
ok lives { require List::Util      }, 'List::Util available';

done_testing;
