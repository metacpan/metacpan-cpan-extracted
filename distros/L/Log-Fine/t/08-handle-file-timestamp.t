#!perl -T

use Test::More tests => 15;

use File::Spec::Functions;

use Log::Fine;
use Log::Fine::Handle;
use Log::Fine::Handle::File::Timestamp;
use Log::Fine::Levels::Syslog;

use POSIX qw( strftime );

{

        my $base     = "fine.%y%m%d.log";
        my $timebase = "fine.%Y%m%d%H%M%S.log";
        my $msg      = "We're so miserable it's stunning";

        # Add a handle.  Note we use the default formatter.
        my $handle =
            Log::Fine::Handle::File::Timestamp->new(file      => $base,
                                                    autoflush => 1);

        isa_ok($handle, "Log::Fine::Handle");
        can_ok($handle, "name");
        can_ok($handle, "msgWrite");

        ok($handle->name() =~ /\w\d+$/);

        # These should be set to their default values
        ok($handle->{mask} == $handle->levelMap()->bitmaskAll());
        ok($handle->{formatter}->isa("Log::Fine::Formatter::Basic"));

        # File-specific attributes
        ok($handle->{file} eq $base);
        ok($handle->{dir} eq "./");
        ok($handle->{autoflush} == 1);

        # Remove the file if it exists so as not to confuse ourselves
        unlink $base if -e $base;

        # Write a test message
        $handle->msgWrite(INFO, $msg, 1);

        # Construct the full name of the file
        my $file = strftime($base, localtime(time));

        # See if a file handle was properly constructed
        ok($handle->{_filehandle}->isa("IO::File"));

        # Now check the file
        ok(-e $file);

        # Close the file handle and reopen
        $handle->{_filehandle}->close();

        my $fh = FileHandle->new(catdir($handle->{dir}, $file));

        # See if a file handle was properly constructed
        ok($fh->isa("IO::File"));

        # Read in the file
        while (<$fh>) {
                ok(/^\[.*?\] \w+ $msg/);
        }

        # Clean up
        $fh->close();
        unlink $file;

        # Okay, now test with a different file name that changes per minute
        # add a handle.  Note we use the default formatter.
        my $timehandle =
            Log::Fine::Handle::File::Timestamp->new(file      => $timebase,
                                                    autoflush => 1);

        isa_ok($timehandle, "Log::Fine::Handle");

        # Write out a couple of files
        $timehandle->msgWrite(INFO, $msg, 1);
        my $t1 = $timehandle->{_filename};
        sleep 1;

        $timehandle->msgWrite(NOTI, $msg, 1);
        my $t2 = $timehandle->{_filename};

        ok($t1 ne $t2);

        # Clean up
        $timehandle->{_filehandle}->close();
        unlink $t1;
        unlink $t2;

}
