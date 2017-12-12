#!/usr/bin/perl -w
# -*- cperl -*-

#
# Author: Slaven Rezic
#

use strict;
use Test::More;
BEGIN {
    plan skip_all => 'No Capture::Tiny available' if !eval { require Capture::Tiny; Capture::Tiny->import('capture'); 1 };
    plan skip_all => 'No Term::ANSIColor available' if !eval { require Term::ANSIColor; 1 };
    plan skip_all => 'Term::ANSIColor probably too old (no colorstrip function)' if !eval { Term::ANSIColor->import('colorstrip'); 1 };
}

use Doit;
use Doit::Log;

plan 'no_plan';

SKIP: {
    skip "No log coloring on Windows", 1
	if $^O eq 'MSWin32';
    is Doit::Log::_can_coloring(), 1; # as Term::ANSIColor is a prereq for this test, _can_coloring has to be true on non-Windows systems
}

my($stdout, $stderr);

($stdout, $stderr) = capture {
    info "info message";
};
is $stdout, '';
is colorstrip($stderr), "INFO: info message\n";
SKIP: {
    skip "No log coloring here", 1
	if !Doit::Log::_can_coloring();
    isnt $stderr, colorstrip($stderr), 'message is colored';
}

($stdout, $stderr) = capture {
    warning "warning message";
};
is $stdout, '';
is colorstrip($stderr), "WARN: warning message\n";

eval {
    error "error message";
};
like colorstrip($@), qr{^ERROR: error message at .* line \d+\.?\n\z};

# Labels
Doit::Log::set_label('label');
(undef, $stderr) = capture {
    info "info message with label";
};
is colorstrip($stderr), "INFO label: info message with label\n";
Doit::Log::set_label(undef);
(undef, $stderr) = capture {
    info "info message without label";
};
is colorstrip($stderr), "INFO: info message without label\n";

# Non-colored
Doit::Log::_no_coloring(); # XXX hmmm, should there be a public function for this?

(undef, $stderr) = capture {
    info "info message";
};
is $stderr, "INFO: info message\n", 'message without color';

__END__
