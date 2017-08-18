# This code is taken, lock, stock, and barrel, from @karenetheridge, and can
# be found at:
#
#   https://github.com/karenetheridge/Dist-Zilla-Plugin-PromptIfStale/blob/56f2fbc0827e3889e25f3da40136a6e9788e5ded/t/lib/EnsureStdinTty.pm
#
# It was provided and is being used under the license she has granted:
#
#   This software is copyright (c) 2013 by Karen Etheridge.
#
#   This is free software; you can redistribute it and/or modify it under the
#   same terms as the Perl 5 programming language system itself.

use strict;
use warnings;

# do not release before global destruction
my $pty;

if (not -t STDIN)
{
    if ($^O ne 'MSWin32')
    {
        # make these tests work even if stdin is not a tty

        # not sure if this is a bug, but on some platforms, if we do not
        # explicitly close STDIN first, when it is closed (via open) the pty
        # is closed as well
        close STDIN;

        require IO::Pty;
        $pty = IO::Pty->new;
        STDIN->fdopen($pty->slave, '<')
            or die "could not connect stdin to a pty: $!";

        if ("$]" < '5.016')
        {
            $TODO = 'on perls <5.16, IO::Pty may not work on all platforms';

            # diag uses todo_output if in_todo :/
            no warnings 'redefine';
            sub diag
            {
                local $Test::Builder::Level = $Test::Builder::Level + 1;
                my $tb = Test::Builder->new;
                $tb->_print_comment($tb->failure_output, @_);
            }
        }
    }
    else {
        ::plan skip_all => 'cannot run these tests on MSWin32 when stdin is not a tty';
    }
}

1;
