#!/usr/bin/env perl

# This script demonstrates how to share static files using
#     Not Even A Framework

# There *are* better tools for this.
# Still not having to run a whole web-server just
#     to test a CSS and a logo may be nice.

use strict;
use warnings;
use File::Basename qw(dirname);
use MVC::Neaf qw(:sugar);

# Now obviously. Thou shalt not expose the application code in production.

# The content path has to be specified.
# Omission of dir_index will lead to a 404 error displayed for all directories
#     (NOT 403 to avoid exposing directory structure)
neaf static => '/03/static' => dirname( __FILE__ ), dir_index => 1,
    description => 'Browse static content';

# Serving a single file is also possible.
neaf static => '/03/self'   => __FILE__,
    description => 'Single-file static content';

# Text files are downloaded, not displayed.

neaf->run;
