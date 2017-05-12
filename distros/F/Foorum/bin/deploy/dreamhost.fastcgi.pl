#!/usr/bin/perl -w

#######################################
# better rename it as dispatch.cgi (Dreamhost tested)
#
# if u can't run this, first try something like:
# perl dispatch.cgi -l ~/foorum.sock
#######################################

use strict;
use warnings;

BEGIN { $ENV{CATALYST_ENGINE} = 'FastCGI' }

use Getopt::Long;
use lib '/home/username/foorumbbs.com/Foorum/lib';    # your Foorum dir
use lib '/home/username/perl5/lib/perl5';             # your Perl module dir
use Foorum;

$SIG{USR1} = 'INGORE';
$SIG{TERM} = 'INGORE';
$SIG{PIPE} = 'IGNORE';    # continue processing on client disconnect (i think)
$SIG{CHLD} = 'IGNORE';    # prevent children from becoming zombies

my $help = 0;
my ( $listen, $nproc, $pidfile, $manager, $detach, $keep_stderr );

GetOptions(
    'help|?'      => \$help,
    'listen|l=s'  => \$listen,
    'nproc|n=i'   => \$nproc,
    'pidfile|p=s' => \$pidfile,
    'manager|M=s' => \$manager,
    'daemon|d'    => \$detach,
    'keeperr|e'   => \$keep_stderr,
);

Foorum->run(
    $listen,
    {   nproc       => $nproc,
        pidfile     => $pidfile,
        manager     => $manager,
        detach      => $detach,
        keep_stderr => $keep_stderr,
    }
);

1;
