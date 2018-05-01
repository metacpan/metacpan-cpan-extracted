#!perl

use strict;
use warnings;

use Test::More;

use File::ConfigDir ();

foreach my $fn (
    qw(config_dirs system_cfg_dir desktop_cfg_dir),
    qw(core_cfg_dir site_cfg_dir vendor_cfg_dir),
    qw(local_cfg_dir here_cfg_dir vendorapp_cfg_dir),
    qw(xdg_config_home user_cfg_dir locallib_cfg_dir),
  )
{
    my $faddr = File::ConfigDir->can($fn);
    eval { $faddr->(qw(foo bar)); };
    my $exception = $@;
    like($exception, qr/$fn\(;\$\), not $fn\(\$,\$\)/, "$fn throws exception on misuse");
}

foreach my $fn (qw(singleapp_cfg_dir))
{
    my $faddr = File::ConfigDir->can($fn);
    eval { $faddr->(qw(foo bar)); };
    my $exception = $@;
    like($exception, qr/$fn\(\), not $fn\(\$,\$\)/, "$fn throws exception on misuse");
}

done_testing;
