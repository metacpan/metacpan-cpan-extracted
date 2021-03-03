use strict;
use warnings;
use Devel::Util qw(:all);

# $Devel::Util::QUIET = 1;

dt {
    my $i = 10_000_000;
    rand while $i--;
} '10 million rands';

dt {
    my $i = 10_000_000;
    rand while $i--;
};

tz {
    printf "Current time is %s\n\n", scalar localtime
} "Pacific/Honolulu";

{
    my $i = 0;
    my $t = time;
    while (time-$t < 3) {
        ++$i;
        oiaw {
            print STDERR "\rprogress: $i"
        } 0.5;
    }
    print STDERR "\n\n";
}

{
    my $i = 0;
    my $t = time;
    my $progress = oiaw { print STDERR "\rprogress: $i" } 0.5;
    while (time-$t < 3) {
        ++$i;
        $progress->();
    }
    print STDERR "\n\n";
}

{
    printr 'this';
    sleep 1;
    printr 'is';
    sleep 1;
    printr 'simple';

    sleep 1;

    printr "1+1=%d\n", 1+1;
    printr sprintf("1+1=%d\n\n", 1+1);
}

if (forked) {
    warn 'We are in a forked process'
} else {
    warn 'We are in the main process'
}