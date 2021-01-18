use warnings;
use strict;
use Test::More;

use Capture::Tiny qw(:all);
use Data::Dumper;
use File::Touch;
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
    like $@, qr/cpan_upload\(\) requires/, "...and error is sane";

    # no password
    $args{username} = 'STEVEB';

    is eval {
        cpan_upload(__FILE__, %args);
        1
    }, undef, "username required ok";
    like $@, qr/cpan_upload\(\) requires/, "...and error is sane";

    delete $args{username};

    $ENV{CPAN_USERNAME} = $un;
    $ENV{CPAN_PASSWORD} = $pw;
}

# success (dry run)
{
    if ($ENV{CPAN_USERNAME} || $ENV{CPAN_PASSWORD}) {
        is eval {cpan_upload(__FILE__, %args); 1 }, 1, "cpan_upload() proper run ok";
    }
}

# with config file set
{
    my %args = (dry_run => 1);
    write_config();
    config(\%args);

    remove(config_file());

    my $dist = 't/data/work/dist-0.01.tar.gz';
    touch $dist;
    is -e $dist, 1, "$dist file created ok";

    my $out = capture_merged {
        cpan_upload($dist, %args);
    };

    like $out, qr/dry run mode/, "cpan_upload() in dry run mode ok with config file";
    like $out, qr/Successfully uploaded/, "cpan_upload() succeeded ok with config file";

    unlink $dist or die "Can't delete $dist: $!";
    is -e $dist, undef, "$dist file removed ok";
}

done_testing();

sub write_config {
    my ($args) = @_;

    my $file = config_file();

    my $data = config(\%args);
    $data->{cpan_id} = 'steveb';
    $data->{cpan_pw} = 'testing';

    # write new file and check for updated %args

    put($file, $data);
}
sub put {
    my ($conf_file, $data) = @_;
    {
        local $/;
        open my $fh, '>', $conf_file or die "can't open $conf_file: $!";
        my $jobj = JSON->new;

        print $fh $jobj->pretty->encode($data);
    }
}
sub remove {
    my ($conf_file) = @_;

    if (-e $conf_file) {
        unlink $conf_file or die "Can't remove config file $conf_file: $!";
        is -e $conf_file, undef, "Removed config file $conf_file ok";
    }

    is -e $conf_file, undef, "(unlink) config file $conf_file doesn't exist ok";
}
