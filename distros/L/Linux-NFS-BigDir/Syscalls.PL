# :WORKAROUND:06/06/2017 10:32:54:ARFREITAS: this script relies on behavior of ExtUtils::MakeMaker described in Pod, PL_FILES
use warnings;
use strict;
use File::Spec;
use Inline 0.80 C => <<'...';
#include <sys/syscall.h>
int _get_syscall_num() {
      return SYS_getdents;
}
...

my $output =
  File::Spec->catfile( 'blib', 'lib', 'Linux', 'NFS', 'BigDir', 'Syscalls.pm' );
my $orig_perms = (stat($output))[2];
chmod 0755, $output;

open( my $out, '>>', $output ) or die "Cannot update $output: $!";
my $getdents_num = _get_syscall_num();
print $out <<BLOCK;
sub SYS_getdents {
    return $getdents_num;
}

1;
BLOCK
close($out);
chmod $orig_perms, $output;
