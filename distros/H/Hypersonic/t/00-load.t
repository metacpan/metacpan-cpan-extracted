use strict;
use warnings;
use Test::More tests => 4;

use lib 'lib';
use lib '../XS-JIT/blib/lib';
use lib '../XS-JIT/blib/arch';

# Test basic module loading
use_ok('Hypersonic');
use_ok('Hypersonic::Socket');

# Test version
ok(defined $Hypersonic::VERSION, 'Hypersonic has a version');
ok(defined $Hypersonic::Socket::VERSION, 'Hypersonic::Socket has a version');

diag("Testing Hypersonic $Hypersonic::VERSION");
diag("Platform: " . Hypersonic::Socket::platform());
diag("Event backend: " . Hypersonic::Socket::event_backend());
