#!perl -T

#
# Note: The purpose of these tests is to ensure that Log::Fine is able
# to write out to a file with an absolute path under MSWin32 (e.g.,
# C:\WINDOWS\Temp\foo.log).  This does *not* include cygwin, which
# behaves more UNIX-y.
#

use Test::More;

use Log::Fine;
use Log::Fine::Handle::File;
use Log::Fine::Levels::Syslog;
use Log::Fine::Logger;

use File::Temp;
use FileHandle;
use POSIX qw(strftime);

{

        if ($^O ne "MSWin32") {
                my $not_cygwin = ($^O ne "cygwin") ? "" : "(not cygwin) ";
                plan skip_all => "Tests for MSWin32 ${not_cygwin}environment only";
        } else {
                plan tests => 5;
        }

        my $tempfh = File::Temp->new(TEMPLATE => 'LFXXXXXX',
                                     DIR      => ($ENV{TEMP} =~ /^([-\@\w.\\:]+)$/ && -d $1)
                                     ? $1
                                     : 'C:\\WINDOWS\\Temp',
                                     SUFFIX => '.log'
        );

        my $file = $tempfh->filename();

        # We do not need $tempfh so close it
        $tempfh->close();

        my $msg = "Smoke me a kipper, I'll be back for breakfast";

        # Get a logger
        my $log = Log::Fine->logger("windowstest0");

        isa_ok($log, "Log::Fine");

        # Add file handle
        my $handle =
            Log::Fine::Handle::File->new(file      => $file,
                                         autoflush => 1);

        isa_ok($handle, "Log::Fine::Handle");

        # Remove the file if it exists so as not to confuse ourselves
        unlink $file if -e $file;

        # Write a test message
        $handle->msgWrite(INFO, $msg, 1);

        $handle->fileHandle()->close();
        ok(-e $file);

        # Grab a ref to our filehandle
        my $fh = FileHandle->new($file);
        isa_ok($fh, "IO::File");

        # Read in the file
        while (<$fh>) {
                ok(/^\[.*?\] \w+ $msg/);
        }

        # Clean up
        $fh->close();
        unlink $file;

}
