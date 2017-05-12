use strict;
use warnings;

use lib 't/lib';
use TestCmd;

use Test::More      0.88                            ;


eval "use Memory::Usage ()";
if ($@)
{
    plan skip_all => "Memory::Usage required for testing memory usage";
}

# it appears that some CPAN Testers have Memory::Usage installed on non-Linux systems (?!?)
# that doesn't work out so hot ... let's see if we can pre-empt that explosion
unless (-r "/proc/$$/statm")
{
    plan skip_all => "Memory::Usage doesn't work on systems without a /proc mount";
}


# Memory::Usage::state returns arrays with the following elements:
#
# 0 - timestamp
# 1 - message
# 2 - virtual memory size
# 3 - resident set size
# 4 - shared memory size
# 5 - text (aka code or exe) size
# 6 - data and stack size
#
# The one we care about is virtsz.  Generally speaking, RSS and shared size seem to fluctuate based
# on nothing that I can determine (possibly OS, whatever other processes are running, sunspots,
# etc).  The virtsz seems to be text + data, which makes sense.  Thus, virtsz is the only one we
# really need to look at.  Note that all sizes are in kilobytes.


# For some reason I am utterly unable to fathom, Test::More interacts with Memory::Usage in an
# unfavorable way.  If I run this code directly in the test script, it always reports an increase.
# So, to get around that, we'll just run the code in its own perl instance.

my $proglet = <<'END';

    use Memory::Usage;

    my $mu = Memory::Usage->new;
    $mu->record('before');

    eval
    {
        require Debuggit;
        Debuggit->import();
    };
    my $err = $@;
    $mu->record('after');

    my ($before, $after) = @{ $mu->state };
    # sanity checking to make sure things are what we think they are
    unless ( $before->[1] eq 'before' and $after->[1] eq 'after' )
    {
        print "ERROR: weird results from state(): $before->[1] and $after->[1]\n";
    }

    if ($err)
    {
        print "ERROR: $err\n";
    }
    else
    {
        my $increase = $after->[virtsz] - $before->[virtsz];
        print "USAGE: ${increase}k\n";
    }

    $mu->report;

END

my $out = cmd_stdout({ perl => $proglet });
my ($type, $data) = $out =~ /^(\w+): (.*?)\n/;

if (is $type, 'USAGE', "successfully imported module for memory test")
{
    is $data, '0k', "loading module adds zero memory overhead" or diag $out;
}
else
{
    diag("error was: $data");
}


done_testing;
