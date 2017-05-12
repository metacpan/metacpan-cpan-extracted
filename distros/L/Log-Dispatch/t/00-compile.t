use strict;
use warnings;

use Test::More;

my %deps = (
    ApacheLog             => 'Apache::Log',
    Code                  => q{},
    File                  => q{},
    'File::Locked'        => q{},
    Handle                => q{},
    Null                  => q{},
    Screen                => q{},
    Syslog                => 'Sys::Syslog 0.28',
    'Email::MailSend'     => 'Mail::Send',
    'Email::MIMELite'     => 'MIME::Lite',
    'Email::MailSendmail' => 'Mail::Sendmail',
    'Email::MailSender'   => 'Mail::Sender',
);

use_ok('Log::Dispatch');

for my $subclass ( sort keys %deps ) {
    my $module = "Log::Dispatch::$subclass";

    if ( !$deps{$subclass}
        || ( eval "use $deps{$subclass}; 1" && !$@ ) ) {
        use_ok($module);
    }
    else {
    SKIP:
        {
            skip "Cannot load $module without $deps{$subclass}", 1;
        }
    }
}

done_testing();
