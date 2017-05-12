use strict;
use warnings;

use Capture::Tiny 'capture';
use Try::Tiny;

sub runtests
{
    my $tzil = shift;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $die;
    my ($stdout, $stderr, @result) = capture {
        try {
            $tzil->test;
        }
        catch {
            chomp($die = $_);
            undef;
        };
    };

    if (defined $die)
    {
        fail $die;
        diag $stdout if $stdout;
        diag $stderr if $stderr;
        diag explain $tzil->log_messages;
        return;
    }

    # success
    note $stdout if $stdout;
    note $stderr if $stderr;
    return 1;
}

1;
