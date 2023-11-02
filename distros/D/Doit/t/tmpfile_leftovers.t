#!/usr/bin/perl -w
# -*- cperl -*-

#
# Author: Slaven Rezic
#

use strict;
use File::Temp 'tempdir';
use Test::More 'no_plan';

my $tempdir = tempdir('doit_XXXXXXXX', TMPDIR => 1, CLEANUP => 1);
my $fixdir = "$tempdir/fixtures";
mkdir $fixdir;
{
    open my $ofh, '>', "$fixdir/content" or die $!;
    print $ofh "bla\n";
}

my $script = "$tempdir/script.pl";
{
    open my $ofh, '>', $script
	or die "Can't create $tempdir/script.pl: $!";
print $ofh <<"EOF1".<<'EOF2';
#! $^X
my \$fixdir = '$fixdir';
EOF1
use Doit;
my $d = Doit->init;
$d->change_file("$fixdir/content", { match => "bla", replace => "foo" });
if ($^O eq 'MSWin32') {
    # SIGINT or SIGTERM causes an interactive "Terminate batch job (Y/N)?" prompt
    kill KILL => $$;
} else {
    kill INT => $$;
}
EOF2
    close $ofh or die $!;
}

system $^X, $script, '--dry-run'; # killed, so don't check exit code

{
    local $TODO = "there should be no leftover temp files";
    opendir my $dirfh, $fixdir or die $!;
    my @found_files = grep { $_ ne '.' && $_ ne '..' } readdir $dirfh;
    is_deeply \@found_files, ['content'], 'no temporary files left';
}

__END__
