#!/usr/bin/env perl

use strict;
use warnings;

use Env::Browser qw(run);

# Set $BROWSER variable.
$ENV{'BROWSER'} = 'echo %s';

# Run.
run('http://example.com');

# Output:
# http://example.com