#!/usr/bin/perl -w

use Test::More 'no_plan';

use IO::Interactive::Tiny;

# Tests which depend on not being connected to a terminal
SKIP: {
    skip "connected to a terminal", 2 if -t *STDIN && -t *STDOUT;

    ok !IO::Interactive::Tiny::is_interactive();
    ok !IO::Interactive::Tiny::is_interactive(*STDOUT);
}


# Tests which depend on being connected to a terminal.
SKIP: {
    skip "not connected to a terminal", 7 unless -t *STDIN && -t *STDOUT;

    ok IO::Interactive::Tiny::is_interactive();
    ok IO::Interactive::Tiny::is_interactive(*STDOUT);

    {
        ok open my $manifest_fh, '<', "MANIFEST";  # any ol file will do.
        ok !IO::Interactive::Tiny::is_interactive($manifest_fh);

        my $old_fh = select $manifest_fh;
        ok !IO::Interactive::Tiny::is_interactive(), 'defaults to selected filehandle';
        select $old_fh;
    }

    {
        local @ARGV = qw(-);
    
        ok IO::Interactive::Tiny::is_interactive();
        
        @ARGV = (1,2,3);
        ok IO::Interactive::Tiny::is_interactive();
    }
}
