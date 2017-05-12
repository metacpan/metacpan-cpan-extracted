#!perl -T

use Test::More tests => 26;

use File::Spec::Functions;
use File::Temp qw/ :mktemp /;
use FileHandle;

use Log::Fine;
use Log::Fine::Handle;
use Log::Fine::Handle::File;
use Log::Fine::Levels::Syslog;
use Log::Fine::Logger;

{

        my $file = "fine.log";
        my $msg  = "We're so miserable it's stunning";

        # Get a logger
        my $log = Log::Fine->logger("handlefile0");

        isa_ok($log, "Log::Fine::Logger");
        can_ok($log, "name");

        ok($log->name() =~ /\w\d+$/);

        # Add a handle.  Note we use the default formatter.
        my $handle =
            Log::Fine::Handle::File->new(file      => $file,
                                         autoflush => 1);

        # Do some validation
        isa_ok($handle, "Log::Fine::Handle");
        can_ok($handle, "name");
        can_ok($handle, "levelMap");
        can_ok($handle, "msgWrite");

        ok($handle->name() =~ /\w\d+$/);

        # These should be set to their default values
        ok($handle->{mask} == $handle->levelMap()->bitmaskAll());
        ok($handle->{formatter}->isa("Log::Fine::Formatter::Basic"));

        # File-specific attributes
        ok($handle->{file} eq $file);
        ok($handle->{dir} eq "./");
        ok($handle->{autoflush} == 1);
        ok($handle->{autoclose} == 0);

        # Remove the file if it exists so as not to confuse ourselves
        unlink $file if -e $file;

        # Write a test message
        $handle->msgWrite(INFO, $msg, 1);

        # Grab a ref to our filehandle
        my $fh = $handle->fileHandle();

        # See if a file handle was properly constructed
        isa_ok($fh, "IO::File");

        # Now check the file
        ok(-e $file);

        # Close the file handle and reopen
        $fh->close();

        $fh = FileHandle->new(catdir($handle->{dir}, $file));

        # See if a file handle was properly constructed
        isa_ok($fh, "IO::File");

        # Read in the file
        while (<$fh>) {
                ok(/^\[.*?\] \w+ $msg/);
        }

        # Clean up
        $fh->close();
        unlink $file;

        # Test to make sure autoclose works as expected
        my $closehandle =
            Log::Fine::Handle::File->new(file      => $file,
                                         autoflush => 1,
                                         autoclose => 1
            );

        isa_ok($closehandle, "Log::Fine::Handle::File");
        can_ok($closehandle, "fileHandle");
        can_ok($closehandle, "msgWrite");

        # Grab a ref to the FileHandle object
        my $fh2 = $closehandle->fileHandle();

        # Write something out and make sure our filehandle is closed
        $closehandle->msgWrite(INFO, $msg, 1);

        # fileno will return undef if $fh2 is a closed filehandle
        ok(not defined fileno $fh2);

        # Clean up
        unlink $file;

        # Test abs path
        my ($tempfh, $tmpfile) = mkstemp("logfinehandletmpXXXXXX");

        ok(defined $tmpfile);

        $tempfh->close();

        # print STDERR "Temp file is $tmpfile\n";

        my $tmphandle =
            Log::Fine::Handle::File->new(file      => $tmpfile,
                                         autoflush => 1);

        isa_ok($tmphandle, "Log::Fine::Handle::File");

        my $fh3 = $tmphandle->fileHandle();
        isa_ok($fh3, "FileHandle");

        $tmphandle->msgWrite(DEBG, $msg, 1);

        ok(-f $tmpfile);

        $fh3->close();
        unlink $tmpfile;

}
