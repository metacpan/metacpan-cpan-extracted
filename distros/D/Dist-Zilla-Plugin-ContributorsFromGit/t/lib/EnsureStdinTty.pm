#
# This file is part of Dist-Zilla-Plugin-ContributorsFromGit
#
# This software is Copyright (c) 2017, 2015, 2014, 2013, 2012 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
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
