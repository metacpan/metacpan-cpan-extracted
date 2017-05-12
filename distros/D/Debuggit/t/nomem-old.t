use strict;
use warnings;

use lib 't/lib';
use TestCmd;


# I'm removing these tests because they seem to consistently fail on some versions of Perl.  (The
# ones I've discovered so far are 5.10.1 and 5.12.5, but there are probably more.)  On top of that,
# I don't know how many people have GTop installed anyway, so these tests probably aren't even
# being run that often.  So I'm officially "deprecating" these tests in favor of the Memory::Usage
# ones (in t/nomem.t).  But I want to leave them here for myself, and for anyone else who'd like to
# try them out.
use Test::More      0.88                            skip_all => "GTop memory tests not reliable across all Perl versions";


eval "use GTop ()";
if ($@)
{
    plan skip_all => "GTop required for testing memory usage";
}


# GTop doesn't interact with Test::More quite as badly as Memory::Usage (see t/nomem.t), but it
# still freaks out every once in a while.  Now running this one in a separate perl instance as well.

my $proglet = <<'END';

    use GTop;

    my $gtop = GTop->new;
    my $before = $gtop->proc_mem($$)->size;

    eval
    {
        require Debuggit;
        Debuggit->import();
    };
    my $err = $@;
    my $after = $gtop->proc_mem($$)->size;

    print "USAGE: ", $after - $before, "\n";

END

my $out = cmd_stdout({ perl => $proglet });
my ($type, $data) = $out =~ /^(\w+): (.*?)\n/;

if (is $type, 'USAGE', "successfully imported module for memory test")
{
    is $data, '0', "loading module adds zero memory overhead" or diag $out;
}
else
{
    diag("error was: $data");
}


done_testing;
