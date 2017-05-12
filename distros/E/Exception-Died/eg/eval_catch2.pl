#!/usr/bin/perl

use lib 'lib', '../lib';

use Exception::Base;
use Exception::Died '%SIG';

eval { open my $file, "z", "/badmodeexample" };
warn 'ref $@ = ', ref $@;
warn '$@ = ', $@;
if ($@) {
    my $e = Exception::Died->catch;
    warn 'ref $e = ', ref $e;
    warn '$e = ', $e;
    warn '$e->message = ', $e->message;
    warn '$e->eval_error = ', $e->eval_error;
    $e->throw;
}
