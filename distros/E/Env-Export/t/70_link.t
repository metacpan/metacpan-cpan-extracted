#!/usr/bin/perl

use strict;
use warnings;
use subs qw(sub_count);

use Test::More;

# TEST SCOPE: These tests exercise the ":link" and ":nolink" keywords

plan tests => 10;

my $namespace = 'namespace0000';

# 1. Verify that by default an exported sub is not directly tied to %ENV
$ENV{LINK} = 0;
eval qq|
package $namespace;
use Env::Export 'LINK';
package main;
\$ENV{LINK}++;
isnt(${namespace}::LINK(), \$ENV{LINK},
     'Verify that the default is no linkage');
|;
warn "eval fail: $@" if $@;

# 2. Test linking an exported sub to the underlying %ENV key
$namespace++;
eval qq|
package $namespace;
use Env::Export qw(:link LINK);
package main;
\$ENV{LINK}++;
is(${namespace}::LINK(), \$ENV{LINK}, 'Exported sub linked to %ENV key');
|;
warn "eval fail: $@" if $@;

# 3. Toggle between linking and not
$namespace++;
for (1 .. 3) { $ENV{"LINK$_"} = $_ }
eval qq|
package $namespace;
use Env::Export qw(:link LINK1 LINK2 :nolink LINK3);
package main;
\$ENV{LINK1}++;
\$ENV{LINK2}++;
\$ENV{LINK3}++;
is(${namespace}::LINK1(), \$ENV{LINK1}, 'Toggling :link/:nolink [1]');
is(${namespace}::LINK2(), \$ENV{LINK2}, 'Toggling :link/:nolink [2]');
isnt(${namespace}::LINK3(), \$ENV{LINK3}, 'Toggling :link/:nolink [3]');
|;
warn "eval fail: $@" if $@;

# 4. Toggle back and forth a few times
$namespace++;
for (1 .. 5) { $ENV{"LINK$_"} = $_ }
eval qq|
package $namespace;
use Env::Export qw(:link LINK1 LINK2
                   :nolink LINK3
                   :link LINK4 LINK5);
package main;
\$ENV{LINK1}++;
\$ENV{LINK2}++;
\$ENV{LINK3}++;
\$ENV{LINK4}++;
\$ENV{LINK5}++;
is(${namespace}::LINK1(), \$ENV{LINK1}, 'Multiple toggling [1]');
is(${namespace}::LINK2(), \$ENV{LINK2}, 'Multiple toggling [2]');
isnt(${namespace}::LINK3(), \$ENV{LINK3}, 'Multiple toggling [3]');
is(${namespace}::LINK4(), \$ENV{LINK4}, 'Multiple toggling [4]');
is(${namespace}::LINK5(), \$ENV{LINK5}, 'Multiple toggling [5]');
|;
warn "eval fail: $@" if $@;

exit;
