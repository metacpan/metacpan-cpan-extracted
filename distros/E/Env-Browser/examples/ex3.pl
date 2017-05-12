#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Env::Browser qw(run);

# Set $BROWSER variable.
$ENV{'BROWSER'} = 'foo:echo %s:bar';

# Run.
run('http://example.com');

# Output:
# http://example.com