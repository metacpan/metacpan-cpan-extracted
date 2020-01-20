#!/usr/bin/env perl

use strict;
use warnings;

use Env::Browser qw(run);

# Set $BROWSER variable.
$ENV{'BROWSER'} = 'foo:echo %s:bar';

# Run.
run('http://example.com');

# Output:
# http://example.com