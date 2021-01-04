use warnings;
use strict;
use Test::More;

use Data::Dumper;
use Hook::Output::Tiny;
use Dist::Mgr qw(:all);

use lib 't/lib';
use Helper qw(:all);

my %args = (
    dry_run     => 1,
);

# bad params
{
    my $un = $ENV{CPAN_USERNAME};
    my $pw = $ENV{CPAN_PASSWORD};
    delete $ENV{CPAN_USERNAME};
    delete $ENV{CPAN_PASSWORD};

    # no file
    is eval {
        cpan_upload();
        1
    }, undef, "no supplied file croaks ok";
    like $@, qr/distribution file/, "...and error is sane";

    # invalid file
    is eval {
        cpan_upload('no_file.txt', %args);
        1
    }, undef, "invalid file croaks ok";
    like $@, qr/valid file/, "...and error is sane";

    # no username
    is eval {
        cpan_upload(__FILE__, %args);
        1
    }, undef, "username required ok";
    like $@, qr/CPAN_USERNAME/, "...and error is sane";

    # no password
    $args{username} = 'STEVEB';

    is eval {
        cpan_upload(__FILE__, %args);
        1
    }, undef, "username required ok";
    like $@, qr/CPAN_USERNAME/, "...and error is sane";

    delete $args{username};

    $ENV{CPAN_USERNAME} = $un;
    $ENV{CPAN_PASSWORD} = $pw;
}

# success (dry run)

{
    is cpan_upload(__FILE__, %args), 1, "cpan_upload() proper run ok";
}

done_testing();

