#!perl
use strict;
use warnings;
use Test::More tests => 3;
use Test::Warn;

use File::Find::utf8;

# Check if warnings levels progate well

# Test no warnings in File::Find
warning_is
    {
        no warnings 'File::Find';
        find( { no_chdir => 1, wanted => sub { } }, 'does_not_exist');
    }
    undef, 'No warning for non-existing directory';

# Test warnings in File::Find
warning_like
    {
        #use warnings 'File::Find'; # This is actually the default
        find( { no_chdir => 1, wanted => sub { } }, 'does_not_exist');
    }
    qr/Can't stat does_not_exist/, 'Warning for non-existing directory' or diag $@;

# Test fatal warnings in File::Find
warning_like
    {
        eval {
            use warnings FATAL => 'File::Find';
            find( { no_chdir => 1, wanted => sub { } }, 'does_not_exist');
        };
        warn $@ if $@;
    }
    qr/Can't stat does_not_exist/, 'Fatal warning for non-existing directory' or diag $@;
