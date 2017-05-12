#!/usr/bin/perl -l -I../lib

use strict;
use warnings;

use Exception::Warning '%SIG' => 'warn', verbosity => 3;

eval {
    eval {
	warn "Simple warn";
    };
};
