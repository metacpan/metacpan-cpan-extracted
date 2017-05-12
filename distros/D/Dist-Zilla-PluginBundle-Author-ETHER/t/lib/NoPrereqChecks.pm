use strict;
use warnings;

# make darned sure this plugin it doesn't run for users during tests, because
# it's going to fail if they haven't satisfied develop prereqs.
END {
    die '[EnsurePrereqsInstalled] has been loaded!' if $INC{ 'Dist/Zilla/Plugin/EnsurePrereqsInstalled.pm' };
}

1;
