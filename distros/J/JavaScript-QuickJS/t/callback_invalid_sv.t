#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;

use JavaScript::QuickJS;

my $js = JavaScript::QuickJS->new();

my $cb = $js->eval( 'a => a' );

eval { $cb->( bless [], 'FooFoo' ) };

my $err = $@;

like $err, qr<FooFoo>, 'invalid SV given to JS callback coderef';

done_testing;

