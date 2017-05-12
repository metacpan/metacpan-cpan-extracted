#!perl -T

use Test::More tests => 70;

#use Data::Dumper;
use Log::Fine;
use Log::Fine::Formatter::Detailed;
use Log::Fine::Formatter::Template;
use Log::Fine::Handle::File;
use Log::Fine::Levels::Syslog;

use File::Basename;
use FileHandle;
use POSIX qw( strftime );
use Sys::Hostname;

# A global for testing
my $counter = 0;

{

        # Set up some variables
        my $hostname = hostname();
        my $msg      = "Stop by this disaster town";
        my $logfile  = "log-fine-formatter-template.log";

        # level
        my $log_level =
            Log::Fine::Formatter::Template->new(template         => "%%LEVEL%%",
                                                timestamp_format => "%Y%m%d");
        isa_ok($log_level, "Log::Fine::Formatter::Template");
        can_ok($log_level, "name");
        can_ok($log_level, "format");

        ok($log_level->name() =~ /\w\d+$/);

        # msg
        my $log_msg =
            Log::Fine::Formatter::Template->new(template         => "%%MSG%%",
                                                timestamp_format => "%Y%m%d");
        isa_ok($log_msg, "Log::Fine::Formatter::Template");
        can_ok($log_msg, "name");
        can_ok($log_msg, "format");

        ok($log_msg->name() =~ /\w\d+$/);

        # package
        my $log_package =
            Log::Fine::Formatter::Template->new(template => "[%%TIME%%] %%LEVEL%% %%PACKAGE%% %%SUBROUT%% %%MSG%%",
                                                timestamp_format => "%H:%M:%S");
        isa_ok($log_package, "Log::Fine::Formatter::Template");
        can_ok($log_package, "name");
        can_ok($log_package, "format");

        ok($log_package->name() =~ /\w\d+$/);

        # filename & lineno
        my $log_filename =
            Log::Fine::Formatter::Template->new(template => "[%%TIME%%] %%LEVEL%% %%FILENAME%%:%%LINENO%% %%MSG%%",
                                                timestamp_format => "%H:%M:%S");
        isa_ok($log_filename, "Log::Fine::Formatter::Template");
        can_ok($log_filename, "name");
        can_ok($log_filename, "format");

        ok($log_filename->name() =~ /\w\d+$/);

        # Short hostname
        my $log_shorthost =
            Log::Fine::Formatter::Template->new(template         => "%%HOSTSHORT%%",
                                                timestamp_format => "%Y%m%d");
        isa_ok($log_shorthost, "Log::Fine::Formatter::Template");
        can_ok($log_shorthost, "name");
        can_ok($log_shorthost, "format");

        ok($log_shorthost->name() =~ /\w\d+$/);

        # long hostname
        my $log_longhost =
            Log::Fine::Formatter::Template->new(template         => "%%HOSTLONG%%",
                                                timestamp_format => "%Y%m%d");
        isa_ok($log_longhost, "Log::Fine::Formatter::Template");
        can_ok($log_longhost, "name");
        can_ok($log_longhost, "format");

        ok($log_longhost->name() =~ /\w\d+$/);

        # user
        my $log_user =
            Log::Fine::Formatter::Template->new(template         => "%%USER%%",
                                                timestamp_format => "%Y%m%d");
        isa_ok($log_user, "Log::Fine::Formatter::Template");
        can_ok($log_user, "name");
        can_ok($log_user, "format");

        ok($log_user->name() =~ /\w\d+$/);

        # group
        my $log_group =
            Log::Fine::Formatter::Template->new(template         => "%%GROUP%%",
                                                timestamp_format => "%Y%m%d");
        isa_ok($log_group, "Log::Fine::Formatter::Template");
        can_ok($log_group, "name");
        can_ok($log_group, "format");

        ok($log_group->name() =~ /\w\d+$/);

        # custom template
        my $log_custom =
            Log::Fine::Formatter::Template->new(template            => "%%FOOBAR%%",
                                                timestamp_format    => "%Y%m%d",
                                                custom_placeholders => {
                                                                         foobar => \&countplus,
                                                });

        ok($log_custom->name() =~ /\w\d+$/);

        eval {

                my $log_badcustom =
                    Log::Fine::Formatter::Template->new(template            => "%%FOOBAR%% %%FooBar%%",
                                                        timestamp_format    => "%Y%m%d",
                                                        custom_placeholders => {
                                                                                 foobar => \&countplus,
                                                                                 FooBar => \&countplus,
                                                        });
        };

        ok($@ =~ /^Duplicate placeholder/);

        # time
        my $log_time =
            Log::Fine::Formatter::Template->new(template         => "%%TIME%%",
                                                timestamp_format => "%Y%m");
        isa_ok($log_time, "Log::Fine::Formatter::Template");
        can_ok($log_time, "name");
        can_ok($log_time, "format");

        ok($log_time->name() =~ /\w\d+$/);

        # Note we test time first to avoid a possible race condition
        # that would occur at the end of every month.

        # Validate
        ok($log_time->format(INFO, $msg, 0) eq strftime("%Y%m", localtime(time)));
        ok($log_level->format(INFO, $msg, 0) eq "INFO");
        ok($log_msg->format(INFO, $msg, 0) eq $msg);

        # Validate call within main
        ok($log_package->format(INFO, $msg, 0) =~ /^\[.*?\] INFO main main $msg/);
        ok($log_filename->format(INFO, $msg, 0) =~ /^\[.*?\] INFO .*?\.t\:\d+ $msg/);

        #printf STDERR "\n%s\n", $log_package->format(CRIT, $msg, 0);
        #printf STDERR "%s\n", $log_filename->format(DEBG, $msg, 0);

        # Validate call within function
        ok(myfunc($log_package,  $msg) =~ /^\[.*?\] INFO main main\:\:myfunc $msg/);
        ok(myfunc($log_filename, $msg) =~ /^\[.*?\] INFO .*?\.t\:\d+ $msg/);

        #printf STDERR "%s\n", myfunc($log_package, $msg);
        #printf STDERR "%s\n", myfunc($log_filename, $msg);

        # Validate call within Package
        ok(This::Test::doIt($log_package,  $msg) =~ /^\[.*?\] WARN This\:\:Test This\:\:Test\:\:doIt $msg/);
        ok(This::Test::doIt($log_filename, $msg) =~ /^\[.*?\] WARN .*?\.t\:\d+ $msg/);

        #printf STDERR "%s\n", This::Test::doIt($log_package, $msg);
        #printf STDERR "%s\n", This::Test::doIt($log_filename, $msg);

        ok($log_longhost->format(INFO, $msg, 0) =~ /$hostname/);
        ok($log_shorthost->format(INFO, $msg, 0) =~ /\w/);

        # Note we test custom templates twice to see if dynamic
        # content changed
        ok($log_custom->format(INFO, $msg, 0) =~ /^$counter/);
        ok($log_custom->format(INFO, $msg, 0) =~ /^$counter/);

    SKIP: {

                skip "Cannot accurately test user and group placeholders under MSWin32", 2
                    if ($^O =~ /MSWin32/);

                ok($log_user->format(INFO, $msg, 0) eq getpwuid($<));
                ok($log_group->format(INFO, $msg, 0) eq getgrgid((split(" ", $())[0]));

        }

        # Now test a combination string for good measure
        my $log_basic =
            Log::Fine::Formatter::Template->new(template         => "[%%time%%] %%level%% %%msg%%",
                                                timestamp_format => Log::Fine::Formatter->LOG_TIMESTAMP_FORMAT);
        isa_ok($log_basic, "Log::Fine::Formatter::Template");
        can_ok($log_basic, "name");
        can_ok($log_basic, "format");

        ok($log_basic->name() =~ /\w\d+$/);
        ok($log_basic->format(INFO, $msg, 1) =~ /^\[.*?\] \w+ $msg/);

        # Grab a logger
        my $logger = Log::Fine->logger("formatlogger0");

        isa_ok($logger, "Log::Fine::Logger");
        can_ok($logger, "name");
        can_ok($logger, "registerHandle");
        can_ok($logger, "log");

        ok($logger->name() =~ /\w\d+$/);

        # If logfile already exists, hose it
        unlink $logfile if (-e $logfile);

        my $handle =
            Log::Fine::Handle::File->new(
                                        file      => $logfile,
                                        autoflush => 1,
                                        formatter =>
                                            Log::Fine::Formatter::Template->new(
                                                        template => "[%%TIME%%] %%LEVEL%% %%SUBROUT%%:%%LINENO%% %%MSG%%\n",
                                                        timestamp_format => "%H:%M:%S"
                                            ));
        isa_ok($handle, "Log::Fine::Handle::File");
        can_ok($handle, "name");

        ok($handle->name() =~ /\w\d+$/);
        $logger->registerHandle($handle);

        # Output
        $logger->log(DEBG, $msg);
        logFunc($logger, $msg);
        This::Test::doFunc($logger, $msg);

        ok(-e $logfile);

        # Check contents
        my $fh      = FileHandle->new($logfile);
        my $logmain = <$fh>;
        my $logfunc = <$fh>;
        my $logpack = <$fh>;

        $fh->close();

        # Validate
        ok($logmain =~ /^\[.*?\] DEBG main\:\d+ $msg/);
        ok($logfunc =~ /^\[.*?\] NOTI main\:\:logFunc\:\d+ $msg/);
        ok($logpack =~ /^\[.*?\] ERR This\:\:Test\:\:doFunc\:\d+ $msg/);

        # We're done so clean up
        $handle->fileHandle()->close();
        unlink $logfile;

}

# Test caller()

sub myfunc
{

        my $formatter = shift;
        my $msg       = shift;

        #my @call = caller(0);
        #print STDERR Dumper \@call;

        return $formatter->format(INFO, $msg, 0);

}          # myfunc()

sub logFunc
{

        my $logger = shift;
        my $msg    = shift;

        $logger->log(NOTI, $msg);

}          # logFunc()

sub countplus { return ++$counter; }

# --------------------------------------------------------------------

package This::Test;

#use Data::Dumper;
use Log::Fine::Levels::Syslog;

sub doIt
{

        my $fmt = shift;
        my $msg = shift;

        #my @call = caller(0);
        #print STDERR Dumper \@call;

        return $fmt->format(WARN, $msg, 0);

}          # doIt()

sub doFunc
{

        my $log = shift;
        my $msg = shift;

        $log->log(ERR, $msg);

}          # doFunc()
