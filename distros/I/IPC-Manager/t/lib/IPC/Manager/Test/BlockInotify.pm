package IPC::Manager::Test::BlockInotify;
use strict;
use warnings;

# Importing this module (via "use" or -M) prevents Linux::Inotify2
# from loading, which forces IPC::Manager::Util to set USE_INOTIFY
# to 0.  The @INC hook is installed in a BEGIN block so it takes
# effect before any subsequent "use" or "require".

BEGIN {
    unshift @INC, sub {
        die "Linux::Inotify2 blocked for testing\n" if $_[1] eq 'Linux/Inotify2.pm';
        return;
    };
}

1;
