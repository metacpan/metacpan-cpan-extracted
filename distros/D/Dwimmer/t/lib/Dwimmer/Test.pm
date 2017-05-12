package t::lib::Dwimmer::Test;
use strict;
use warnings;

use base 'Exporter';

our @EXPORT = qw(start stop $admin_mail @users read_file);

#use File::Basename qw(dirname);

use File::Basename qw(basename);
use File::Spec;
use File::Temp qw(tempdir);
use File::Copy qw(copy);
use POSIX ":sys_wait_h";

my $process;

sub start {
    my ($password) = @_;
    #return if $^O !~ /win32/i;    # this test is for windows only now

    my $dir = tempdir( CLEANUP => 1 );

    # print STDERR "# $dir\n";
	my ($cnt) = split /_/, basename $0;

    $ENV{DWIMMER_TEST} = 1;
    $ENV{DWIMMER_PORT} = 20_000+$cnt;
    $ENV{DWIMMER_MAIL} = File::Spec->catfile( $dir, 'mail.txt' );

    our $admin_mail = 'test@dwimmer.org';

    our @users = (
        {   uname    => 'tester',
            fname    => 'foo',
            lname    => 'bar',
            email    => 'test@dwimmer.org',
            password => 'dwimmer',
        },
    );

    my $root = File::Spec->catdir( $dir, 'dwimmer' );
    system
        "$^X -Ilib script/dwimmer_admin.pl --setup --root $root --email $admin_mail --password $password" and die $!;

    mkdir "$root/polls" or die $!;
    copy("t/files/testing-polls.json", "$root/polls") or die $!;


    if ( $^O =~ /win32/i ) {
        require Win32::Process;

        #import Win32::Process;

        Win32::Process::Create( $process, $^X,
            "perl -Ilib -It\\lib $root\\bin\\app.pl",
            0, Win32::Process::NORMAL_PRIORITY_CLASS(), "." )
            || die ErrorReport();
    } else {
	    $process = fork();

        die "Could not fork() while running on $^O" if not defined $process;

        if ($process) { # parent
            # wait 1 sec to let server start
            sleep 1;
            my $res = waitpid($process, WNOHANG);
            return if $res == -1;
            return if $res;
            return $process;
        }

        my $cmd = "$^X -Ilib -It/lib $root/bin/app.pl";
        exec $cmd;
    }

    return 1;
}

sub stop {
    return if not $process;
    if ( $^O =~ /win32/i ) {
        $process->Kill(0);
    } else {
        kill 9, $process;
    }
}

END {
    stop();
}

sub read_file {
    my $file = shift;
    open my $fh, '<', $file or die "Could not open '$file' $!";
    local $/ = undef;
    my $cont = <$fh>;
    close $fh;
    return $cont;
}

1;
