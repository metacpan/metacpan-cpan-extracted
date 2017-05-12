######################################################################
# Regression tests for NetLock module.
# Currently nine tests.
# 1) Parameters presented as list.
# 2) Named parameter interface.
# 3) Subroutine (as opposed to OO) interface.
# 4) Heartbeat test - check for slower unlock.
# 5) Sleep test - check that it takes longer to acquire lock.
# 6) Test error handling with invalid host.
# 7) Test error handling with invalid login.
# 8) Test error handling with too short wait time to get lock.
# 9) Test error handling when cannot remove directory. (Some platforms.)
######################################################################

use strict;
use Cwd;
use Config;
use Net::FTP;
use Test;
use vars qw($total_tests);

BEGIN {
	$total_tests = 9;
	plan(tests => $total_tests) if (@ARGV == 0);
}

use LockFile::NetLock qw(lock unlock);

$|++;
select((select(STDERR), $|++)[0]);

my ($child_test_number, $child_test, $child_opt);
my ($perl, $is_win32);
my ($generic_ftp_fn, $ftp_cfg_href, $do_failed_unlock);

my $temp_dir = -d '/tmp' ? '/tmp' : $ENV{TMP} || $ENV{TEMP} || '';
my $timestamp_file = "$temp_dir/timestmp.txt";

######################################################################
# Re-run this program with options identifying which test is to be
# executed by child.
######################################################################
sub run_test_child {
        my $child_test = shift;
        my $child_opt = shift || '';
        my $exec_str = ($0 =~ /perl/) ? $0 : "$perl $0";
        my $incpath = '-I' . join(' -I', 
                grep($_ !~ /^(([\\\/])|(\.\s*$)|(\w*:[\\\/]))/, @INC)
        );

        $incpath =~ tr!\\!/!;
        $exec_str =~ tr!/!\\! if ($is_win32);
        $exec_str =~ s/(perl[^ ]*) /$1 $incpath /i unless ($incpath eq '-I');
        $exec_str .= " $child_test $child_opt";

        open(FH_CHILD, "$exec_str |") ||
                die "Could not run child test: $!";
        return \*FH_CHILD;
}

######################################################################
# Write current time in seconds to a file on a line by itself.
######################################################################
sub write_time_stamp {  
        open(FH, "> $timestamp_file") || 
                die "Could not open timestamp file $timestamp_file ",
                        "for write: $!";
        (print FH time(), "\n") ||
                die "Could not write timestamp file $timestamp_file ",
                        ": $!";
        close(FH); 
}

######################################################################
# Run tests that consist of having calling process get a lock and then
# having a child process try to get the lock later.  Allow child
# configurations to be passed as parameter.
# Some of the child processes will wish to know how long it took them 
# to get the lock so, for some cases, write time stamp to a file.
######################################################################
sub test_parent_normal {
        my $child_test = shift;
        my $sleep_time = shift;
        my $ftp_cfg_href = shift;
        my @test_child_opt = @_; 

        foreach my $child_opt (@test_child_opt) {
                if ($is_win32 && ($child_opt eq 'heartbeat')) {
			skip "Skip: not needed on win32", undef;
                        next;
                }
                eval {
                my ($expected_res, @additional_err);
                my $mx = new LockFile::NetLock (    
                        $ftp_cfg_href->{test_host},
                        $ftp_cfg_href->{test_dir},
                        $ftp_cfg_href->{test_user},
                        $ftp_cfg_href->{test_pass}
                );
                my $fh;
                my $no_contention_time = time;
                $mx->lock || die $mx->errstr; 
                $no_contention_time = time - $no_contention_time;
                $sleep_time += $no_contention_time if (
                	$child_test eq 'too_short_wait'
                );
                write_time_stamp() if ($child_test =~ /normal/);
                $fh = run_test_child($child_test, $child_opt);
                sleep $sleep_time;
                $mx->unlock;
                $expected_res = scalar(<$fh>);
                @additional_err = <$fh>;
                @additional_err = () unless(scalar(@additional_err) > 0);
                close($fh);
                if ($expected_res =~ /^ok/i) {
			ok 1;
                }
                else {
                        die $expected_res, @additional_err;
                }
                };

                if ($@) {
			ok(0, undef, $@);
                        close(FH) if ($@ =~ /Could not write/i);
                }
                
        }
        
        unlink $timestamp_file;
}

######################################################################
# Test error handling on invalid FTP lock requests including
# invalid host name and invalid login name.
######################################################################
sub test_err {
        my $ftp_cfg_href = shift;

        my $mx = lock (
                'nonesuch.cqm',
                'lock.lck',
                'nonesuch',
                'nonesuch',
        );
        
        if (    (! $mx)                                         &&
                ($LockFile::NetLock::errstr =~ /Can't connect/i)) {
                ok 1;
        }
        else {
                ok 0;
        }
        
        $mx = lock (
                $ftp_cfg_href->{test_host},
                'lock.lck',
                'nonesuch',
                'nonesuch',
        );
        
        if (    (! $mx)                                         &&
                ($LockFile::NetLock::errstr =~ /Can't log in/i) ){
                ok 1;
        }
        else {
                ok 0;
        }
        
}

######################################################################
# Get Mutex held by parent and test that we got it successfully in a
# reasonable amount of time.  If too little time passes we worry that
# the parent did not lock mutex.
######################################################################
sub test_child_normal {
        my $ftp_cfg_href = shift;
        my ($timestamp_line, $child_timestamp);
        my $mx;
        my %lock_opts = (
                -dir => $ftp_cfg_href->{test_dir},
                -host => $ftp_cfg_href->{test_host},
                -user => $ftp_cfg_href->{test_user},
                -password => $ftp_cfg_href->{test_pass}
        );
       
        eval {
        if ($child_opt eq 'old_parm') {
                $mx = new LockFile::NetLock(
                        $ftp_cfg_href->{test_host},
                        $ftp_cfg_href->{test_dir},
                        $ftp_cfg_href->{test_user},
                        $ftp_cfg_href->{test_pass}
                );
        }
        elsif ($child_opt =~ /named_parm|heartbeat|sleep/) {
                $lock_opts{-heartbeat} = 10 if ($child_opt eq 'heartbeat');
                $lock_opts{-sleep} = 15 if ($child_opt eq 'sleep');
                die 'Could not allocate child mutex: ',
                        $LockFile::NetLock::errstr unless(defined(
                                $mx = new LockFile::NetLock(%lock_opts)
                ));
        }
        elsif ($child_opt eq 'sub_interface') {
                die 'Could not lock mutex in child: ' unless (
                        lock(   $ftp_cfg_href->{test_host},
                                $ftp_cfg_href->{test_dir},
                                $ftp_cfg_href->{test_user},
                                $ftp_cfg_href->{test_pass},
                                # just check it doesn't break anything
                                -disconnect => 1 
                        )
                );
        }
        if ($child_opt =~ /old_parm|named_parm|heartbeat|sleep/) {
                die 'Could not lock mutex in child: ',
                        $LockFile::NetLock::errstr unless($mx->lock);
        }
        open(FH, $timestamp_file) || 
                die "Could not open timestamp file $timestamp_file ",
                        "for read: $!";
        die "Could not read actual timestamp in child"
                unless(defined($timestamp_line = <FH>));
        close(FH);
        chomp($timestamp_line);
        $child_timestamp = time();
        if ($child_opt eq 'sleep') {
                die "Invalid timestamp (parent: $timestamp_line, ",
                        "child: $child_timestamp)" if (
                        (($child_timestamp - $timestamp_line) < 14)      ||
                        (($child_timestamp - $timestamp_line) > 40)
                );
        }
        else {
                die "Invalid timestamp (parent: $timestamp_line, ",
                        "child: $child_timestamp)" if (
                        (($child_timestamp - $timestamp_line) < 5)      ||
                        (($child_timestamp - $timestamp_line) > 30)
                );
        }

        if ($child_opt eq 'heartbeat') {
                my $before_unlock_ts = time();
                $mx->unlock;    
                if ((time() - $before_unlock_ts) < 5) {
                        die "Heartbeat not honored";
                }
        }

        };
        if ($@) {
                print $@;
                close(FH) if ($@ =~ /Could not read/i);
        }
        else {
                print "ok\n";
        }
        if ($child_opt eq 'sub_interface') {
                unlock( $ftp_cfg_href->{test_host},
                        $ftp_cfg_href->{test_dir}
                );
        }
}

######################################################################
# Test NetLock handling of time out failure.  Parent holds for 20
# seconds but we only wait 5 seconds to try to get mutex.
######################################################################
sub test_child_too_short_wait {
        my $mx;
        my $ftp_cfg_href = shift;

        eval {
                $mx = new LockFile::NetLock (
                        $ftp_cfg_href->{test_host},
                        $ftp_cfg_href->{test_dir},
                        $ftp_cfg_href->{test_user},
                        $ftp_cfg_href->{test_pass},
                        -timeout => 5
                );
                die "Should not have acquired mutex\n"
                        if ($mx->lock);
                die $mx->errstr;
        };

        if ($@ !~ /timed out/) {
                print $@;
        }
        else {
                print "ok\n";
        }
}

######################################################################
# See if ftp server supports site idle command used to test
# failed closing by setting short (30 sec) idle.
######################################################################
sub site_idle_ok {
        my $ftp_cfg_href = shift;

        my $conn = Net::FTP->new($ftp_cfg_href->{test_host});
        if ($conn) {
                if ($conn->login(grep($_, (
                        $ftp_cfg_href->{test_user},
                        $ftp_cfg_href->{test_pass}
                )))) {
                        if ($conn->site('idle 30') == 2) {
                                $conn->quit;
                                return 1;
                        }
                }
        }
        $conn->quit;
        return;
}

######################################################################
# Connect directly via ftp and remove test directory for case
# where unlock fails.
######################################################################
sub remove_test_dir {
        my $ftp_cfg_href = shift;

        my $conn = Net::FTP->new($ftp_cfg_href->{test_host});

        if ($conn &&  $conn->login(grep($_, (
                        $ftp_cfg_href->{test_user},
                        $ftp_cfg_href->{test_pass}
        )))) {
                $conn->rmdir($ftp_cfg_href->{test_dir});
        }
        else {
                warn 'could not remove test directory ',
                        $ftp_cfg_href->{test_dir}, ' on host ',
                        $ftp_cfg_href->{test_host};
        }
}

######################################################################
# Verify that if we lose connection and cannot remove directory
# we get bad return code from unlock.  We test this by setting
# the heartbeat longer than the idle time allowing the ftp
# server to disconnect while idling.
######################################################################
sub test_failed_unlock {
        my $ftp_cfg_href = shift;
        eval {
                my $mx = lock (
                        $ftp_cfg_href->{test_host},
                        $ftp_cfg_href->{test_dir},
                        $ftp_cfg_href->{test_user},
                        $ftp_cfg_href->{test_pass},
                        -ftp_heartbeat => 35,
                        -idle => 30
                ) || die "Lock failed $LockFile::NetLock::errstr";
                sleep 32; # give idle time to expire
                unlock( $ftp_cfg_href->{test_host},
                        $ftp_cfg_href->{test_dir}
                ) && die 'Unlock succeded and expected to fail';
                die "Unexpected final error $LockFile::NetLock::errstr"
                        unless ($mx->errstr =~ /failed.*remove/i);
        };
        if ($@) {
                ok(0, undef, $@);
        }
        else {
                ok 1;
        }

        remove_test_dir($ftp_cfg_href);

}

######################################################################
# Start of program.
######################################################################


# You may need to tinker below if we cannot find your Perl executable
# or temporary directory.
$perl = -x './perl' ? './perl' : $Config{'perlpath'} || '';
die "Could not find perl executable." unless((-x $perl) || ($0 =~/perl/));

die "Could not identify directory for temporary files" unless(-d $temp_dir);
$is_win32 = ($^O eq 'MSWin32');

#print "starting with pid $$ and args: ", join(' ', @ARGV);
$child_test = (shift @ARGV) || '';
$child_opt = (shift @ARGV) || 'standard';

$ftp_cfg_href = do 'netlock.cfg' if (-r 'netlock.cfg');

unless (	$ftp_cfg_href    and
		$ftp_cfg_href->{ test_dir } and $ftp_cfg_href->{ test_host }
) {
	# hack to get around test harnesses that don't do test configuration
	# if you are debugging and see this comment try 
	#     manually running "perl Makefile.PL" and entering test server etc.
	ok 1; # some credit for getting this far;
	skip $_ for ( 2 .. $total_tests );
	exit;
}

$generic_ftp_fn = $ftp_cfg_href->{test_dir};
$do_failed_unlock = ($Net::FTP::VERSION >= 2.64) && site_idle_ok($ftp_cfg_href);

if (! $child_test) {      
        test_parent_normal('normal', 7,
                $ftp_cfg_href, 
                qw(old_parm named_parm sub_interface heartbeat sleep));
        test_err($ftp_cfg_href);
        test_parent_normal('too_short_wait', 15, $ftp_cfg_href, 
                'old_parm');            
        if ($do_failed_unlock) {
                test_failed_unlock($ftp_cfg_href );
        }
        else {
                skip "Skip: no support for ftp idle used in testing", undef;
        }
}
elsif ($child_test eq 'normal') {
        test_child_normal($ftp_cfg_href);
}
elsif ($child_test eq 'too_short_wait') {
        test_child_too_short_wait($ftp_cfg_href);
}


