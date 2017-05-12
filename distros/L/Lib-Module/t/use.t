#!/usr/bin/env perl -w
use strict;
use Test;
BEGIN { plan tests => 3 }

use Lib::Module; ok(1);
use Lib::ModuleSymbol; ok(2);
use Lib::SymbolRef; ok(3);
exit;
__END__


