use Test::More;
use Test::UsedModules;

my $f = [ qw|
    Default.pm
    JSON.pm
    Log.pm
    Root.pm
    Sendmail.pm
    HTTPD.pm
    HTTPD/Auth.pm
    HTTPD/Request.pm
    HTTPD/Response.pm
    HTTPD/Router.pm
    SMTPD/Address.pm
    SMTPD/Greeting.pm
    SMTPD/Milter.pm
    SMTPD/Milter/Example.pm
    SMTPD/Milter/Nyaa.pm
    SMTPD/Relay/AmazonSES.pm
    SMTPD/Relay/Discard.pm
    SMTPD/Relay/ESMTP.pm
    SMTPD/Relay/File.pm
    SMTPD/Relay/Haineko.pm
    SMTPD/Relay/MX.pm
    SMTPD/Relay/Screen.pm
    SMTPD/Relay/SendGrid.pm
    SMTPD/Relay.pm
    SMTPD/Response.pm
    SMTPD/RFC5321.pm
    SMTPD/RFC5322.pm
    SMTPD/Session.pm
| ];

for my $e ( @$f ){ 
    used_modules_ok( 'lib/Haineko/'.$e );
}
used_modules_ok( 'lib/Haineko.pm' );
used_modules_ok( 'libexec/haineko.psgi' );

done_testing;
