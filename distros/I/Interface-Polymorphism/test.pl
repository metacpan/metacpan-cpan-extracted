# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..5\n"; }
END {print "not ok 1\n" unless $loaded;}
require ex::implements;
require ex::interface;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

eval {
    package Interface;
    
    use ex::interface qw/foo bar bletch/;
};

print "not " if $@;
print "ok 2\n";

$error =
    `perl -Mblib -e 'package Interface; use ex::interface qw/foo bar bletch/;\
package Broken;\
use ex::implements qw/Interface/;sub foo; sub bar;' 2>&1`;

$error =~ s/^.*\n//m;
print "not " unless $error eq <<"EOE";
Broken: Method 'bletch'
\tis missing for interface Interface
EOE
print "ok 3\n";

$error =
    `perl -Mblib -e 'package Interface; use ex::interface qw/foo bar bletch/;\
package Working; \
use ex::implements qw/Interface/; \
sub foo; sub bar; sub bletch;' 2>&1`;

$error =~ s{^Using.*/blib\n}{}m;

print "not " if $error;
print "ok 4\n";

$error =
    `perl -Mblib -e 'package Interface; use ex::interface qw/foo bar bletch/;\
package Working; \
use ex::implements qw/Interface/; \
sub foo; sub bar; sub bletch;
print "ISA not set" unless Working->isa("Interface")' 2>/dev/null`;

print "not " if $error =~ /ISA not set/;
print "ok 5\n";
