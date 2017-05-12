#!/usr/bin/perl -w
use strict;
use Data::Dumper;

#
# this script can be used to stream a remote file to a local path.  it
# works by ssh-ing into the remote server and running 'tail -f' on the
# target file and appending all the output to a local file.  When this
# is running, it's possible to 'tail -f' the local copy of the file
# and (assuming your resources aren't saturated) see live data.
#
# The '-n +0' option is used with the remote gnu tail so the entire
# contents of the file will be captured on initial connect.
#
# Also, the '-F' option is specified, so that if the remote file gets
# zeroed out or recreated (e.g. due to file rotation), the local file
# will still contain the full contents.
#
#
#


$| = 1;

#
#_* Config
#

# remote path for gnu tail
my $tail = "/usr/local/bin/tail";
my $ssh = "/usr/bin/ssh";

#
#_* Main
#

my $usage = "$0 <server> <remote path> <local path>";

my ( $server, $remote_path, $local_path ) = ( @ARGV );
unless ( $local_path ) {
    die $usage;
}

# open local file for writing
print "Writing output to $local_path\n";
open(my $local_fh, ">", $local_path)
    or die "Couldn't open $local_path for writing: $!\n";

# disable buffering to $local_fh
select((select($local_fh), $|=1)[0]);

# start tail process on remote server that gets the entire
# contents of the file.  Also uses -F which follows the file in
# case it is renamed.
my $command = "$ssh $server $tail -n +0 -F $remote_path";
print "Opening remote log file: $command\n";
open my $tail_fh, "-|", "$command 2>&1" or die "Unable to execute $command: $!";

# output all results of remote tail to local file
while ( my $line = <$tail_fh> ) {
    print $local_fh $line or die "Error printing to $local_path\n";
}

# if the remote command ends, shut everything down before exiting
close $tail_fh;
close $local_fh or die "Error closing file: $!\n";

# check exit status
unless ( $? eq 0 ) {
    my $status = $? >> 8;
    my $signal = $? & 127;

    die "Died:\n\tstatus=$status\n\tsignal=$signal";
}
