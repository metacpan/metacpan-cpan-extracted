#!perl

use Test::Without::Module ("List::Moreutils", "File::HomeDir", "local::lib");

use strict;
use warnings;
use FindBin '$Bin';

use Test::More;

use File::ConfigDir ();

SCOPE:
{
    # override $ENV{HOME} for test
    local $ENV{HOME} = $Bin;

    foreach my $fn (qw(config_dirs user_cfg_dir))
    {
        my $faddr = File::ConfigDir->can($fn);
        my @dirs  = $faddr->();
        note("$fn: " . join(",", @dirs));
        if ($fn eq "config_dirs")
        {
            ok(scalar @dirs >= 1, "config_dirs") or diag(join(",", @dirs));    # we expect at least system_cfg_dir
        }
        elsif ($fn =~ m/(?:local|user)_cfg_dir/)
        {
            ok(scalar @dirs == 1, $fn) or diag(join(",", @dirs));    # probably we do not have local::lib or File::HomeDir
        }
    }
}

SCOPE:
{
    # override $ENV{HOME} for test
    local $ENV{HOME};
    local $ENV{HOMEDRIVE};
    local $ENV{HOMEPATH};

    foreach my $fn (qw(user_cfg_dir locallib_cfg_dir))
    {
        my $faddr = File::ConfigDir->can($fn);
        my @dirs  = $faddr->();
        note("$fn: " . join(",", @dirs));
        ok(scalar @dirs == 0, $fn) or diag(join(",", @dirs));    # probably we do not have local::lib or File::HomeDir
    }
}

done_testing();
