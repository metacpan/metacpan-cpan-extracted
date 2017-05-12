#!perl -T

use Test::More;

use Log::Fine;
use Log::Fine::Handle::Console;
use Log::Fine::Levels::Syslog;

# Set message
my $msg = "Stop by this disaster town, we put our eyes to the sun and say 'Hello!'";

# Add a handle.  Note we use the default formatter.
my $handle = Log::Fine::Handle::Console->new();

{

        # See if we have Test::Output installed
        eval "use Test::Output 0.10";

        if ($@) {
                plan skip_all => "Test::Output 0.10 or above required for testing Console output";
        } else {
                plan tests => 17;
        }

        isa_ok($handle, "Log::Fine::Handle::Console");
        can_ok($handle, "name");

        ok($handle->name() =~ /\w\d+$/);

        # Get a logger
        my $log = Log::Fine->logger("handleconsole0");

        isa_ok($log, "Log::Fine");
        can_ok($log, "name");

        ok($log->name() =~ /\w\d+$/);

        # Do some validation
        isa_ok($handle,              "Log::Fine::Handle");
        isa_ok($handle->{formatter}, "Log::Fine::Formatter::Basic");
        can_ok($handle, "name");
        can_ok($handle, "msgWrite");

        ok($handle->name() =~ /\w\d+$/);

        # These should be set to their default values
        ok($handle->{mask} == $handle->levelMap()->bitmaskAll());
        ok($handle->{formatter}->isa("Log::Fine::Formatter::Basic"));

        # Console-specific attributes
        ok(!$handle->{use_stderr});
        stdout_like(\&writer, qr/$msg/, 'Test STDOUT');

        # Test STDOUT
        $handle->{use_stderr} = 1;

        ok($handle->{use_stderr});
        stderr_like(\&writer, qr/$msg/, 'Test STDERR');

}

sub writer
{
        $handle->msgWrite(INFO, $msg);
}
