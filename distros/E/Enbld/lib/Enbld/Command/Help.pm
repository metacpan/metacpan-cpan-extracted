package Enbld::Command::Help;

use strict;
use warnings;

use parent qw/Enbld::Command/;

sub do {
    my $help = do { local $/; <DATA> };

    print $help . "\n";

    return $_[0];
}

1;

__DATA__
Usage: enbld command target [option]

Commands:
  available            displays all software supported by Enbld
  available target     displays all version of target software
  install target       installs target software
  install target ver   installs the specific version of target software
  list                 displays installed software
  list target          displays all installed version of target software
  outdated             displays all outdated software
  upgrade target       installs upgraded target software
  rehash target        re-create target software's symbolic link
  freeze               displays a conditions script reproduce installed software
  deploy ~/path        deploys all installed software to specific path

Options:
  -h,--help     Displays Enbld's help.
  -v,--version  Displays Enbld's version.
  -f,--force    Install target whether it is installed or not.
  -t,--test     Execute target's test at installtion process.
  -c,--curret   Displays target's current installed version at 'freeze' command.

SEE ALSO

To see more detailed help, type below command.

 $ enblder intro    # displays perldoc of lib/Enbld.pm
 $ enblder tutorial # displays perldoc of lib/Enbld/Tutorial.pm
 $ perldoc enblder  # displays perldoc of bin/enblder

