#!/usr/bin/perl -I../lib

use strict;
use warnings;

use Exception::Base;
use Exception::Warning '%SIG' => 'die';

eval {
    warn "Boom!";
};
if ($@) {
    my $e = Exception::Base->catch;
    $e->throw( message => 'Caught warning', verbosity => 3);
}
