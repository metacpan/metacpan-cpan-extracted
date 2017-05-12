#!perl -T

BEGIN { $ENV{EMAIL_SENDER_TRANSPORT} = 'Test' }

#use Data::Dumper;
use Log::Fine;
use Log::Fine::Formatter::Template;
use Log::Fine::Levels::Syslog qw( :macros :masks );
use Test::More;

{

        plan skip_all => "Email handle only supported in perl 5.8.3 or above"
            if $^V lt v5.8.3;

        # See if we have Email::Sender installed
        eval "require Email::Sender";

        if ($@) {
                plan skip_all => "Email::Sender is not installed.  Unable to test Log::Fine::Handle::Email";
        } else {
                plan tests => 9;
        }

        use_ok("Log::Fine::Handle::Email");

        my $email_sender_version = $Email::Sender::VERSION;

        # Load appropriate modules
        require Email::Sender::Simple;
        require Email::Sender::Transport::Test;

        my $user =
            sprintf('%s@localhost', getlogin() || getpwuid($<) || "nobody");

        my $log = Log::Fine->logger("email0");

        isa_ok($log, "Log::Fine");

        # Create a formatter for subject line
        my $subjfmt =
            Log::Fine::Formatter::Template->new(name     => 'email-subject',
                                                template => "%%LEVEL%% : Test of Log::Fine::Handle::Email");

        # Create a formatted msg template
        my $msgtmpl = <<EOF;
This is a test of Log::Fine::Handle::Email.  The following message was
delivered at %%TIME%%:

--------------------------------------------------------------------
%%MSG%%
--------------------------------------------------------------------

This is only a test.  Thank you for your patience.

/Chris

EOF

        my $bodyfmt =
            Log::Fine::Formatter::Template->new(name     => 'email-body',
                                                template => $msgtmpl);

        isa_ok($subjfmt, "Log::Fine::Formatter::Template");
        isa_ok($bodyfmt, "Log::Fine::Formatter::Template");

        # Register an email handle
        my $handle =
            Log::Fine::Handle::Email->new(name              => 'email11',
                                          mask              => LOGMASK_EMERG | LOGMASK_ALERT | LOGMASK_CRIT,
                                          subject_formatter => $subjfmt,
                                          body_formatter    => $bodyfmt,
                                          header_from       => $user,
                                          header_to         => $user,
            );

        isa_ok($handle, "Log::Fine::Handle::Email");

        # Quick validation using default method
        ok($handle->_validate_default($user));

        my $transport = Email::Sender::Simple->default_transport;
        ok(ref $transport eq "Email::Sender::Transport::Test");

        # Register the handle
        $log->registerHandle($handle);

        $log->log(DEBG, "Debugging 15-handle-email.t");
        if ($email_sender_version < 0.120000) {
                ok(scalar @{ $transport->deliveries } == 0);
        } else {
                ok(scalar $transport->deliveries == 0);
        }

        $transport->clear_deliveries();

        $log->log(CRIT, "Beware the weeping angels");
        if ($email_sender_version < 0.120000) {
                ok(scalar @{ $transport->deliveries } == 1);
        } else {
                ok(scalar $transport->deliveries == 1);
        }

        #print STDERR Dumper $transport->deliveries();

}
