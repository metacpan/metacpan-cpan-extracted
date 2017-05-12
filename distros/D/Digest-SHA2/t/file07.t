use diagnostics;
use strict;
use warnings;
use Test::More tests => 4;
BEGIN {
    use_ok('Digest::SHA2')
};

BEGIN {
    open INFILE, "t/file07.dat";
    my $sha2obj = new Digest::SHA2;
    $sha2obj->addfile(*INFILE);
    my $digest = $sha2obj->hexdigest();
    is("0ab803344830f92089494fb635ad00d76164ad6e57012b237722df0d7ad26896",
        $digest);

    close INFILE;

    open INFILE, "t/file07.dat";
    my $sha2obj2 = new Digest::SHA2 384;
    $sha2obj2->addfile(*INFILE);
    my $digest2 = $sha2obj2->hexdigest();
    is("e3e3602f4d90c935321d788f722071a8809f4f09366f2825cd85da97ccd2955eb6b8245974402aa64789ed45293e94ba",
        $digest2);

    close INFILE;

    open INFILE, "t/file07.dat";
    my $sha2obj3 = new Digest::SHA2 512;
    $sha2obj3->addfile(*INFILE);
    my $digest3 = $sha2obj3->hexdigest();
    is("97fb4ec472f3cb698b9c3c12a12768483e5b62bcdad934280750b4fa4701e5e0550a80bb0828342c19631ba55a55e1cee5de2fda91fc5d40e7bee1d4e6d415b3",
        $digest3);

    close INFILE;
};

