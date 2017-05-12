#!/usr/bin/perl -w

# unattended Mail::Sendmail test, sends a message to the author
# but you probably want to change $mail{To} below
# to send the message to yourself.
# version 0.78

# if you change your mail server, you may need to change the From:
# address below.
$mail{From} = 'Sendmail Test <sendmail@alma.ch>';

$mail{To}   = 'Sendmail Test <sendmail@alma.ch>';
#$mail{To}   = 'Sendmail Test <sendmail@alma.ch>, You me@myaddress';

# if you want to get a copy of the test mail, you need to specify your
# own server here, by name or IP address
$server = 'mail.alma.ch';
#$server = 'my.usual.mail.server';

BEGIN { $| = 1; print "1..2\n"; }
END {print "not ok 1\n" unless $loaded;}

print <<EOT
Test Mail::Sendmail $Mail::Sendmail::VERSION

Trying to send a message to the author (and/or whoever if you edited test.pl)

(The test is designed so it can be run by Test::Harness from CPAN.pm.
Edit it to send the mail to yourself for more concrete feedback. If you
do this, you also need to specify a different mail server, and possibly
a different From: address.)

Current recipient(s): '$mail{To}'

EOT
;

use Mail::Sendmail;

$loaded = 1;
print "ok 1\n";

if ($server) {
    $mail{Smtp} = $server;
    print "Server set to: $server\n";
}

$mail{Subject} = "Mail::Sendmail version $Mail::Sendmail::VERSION test";

$mail{Message} = "This is a test message sent with Perl version $] from a $^O system.\n\n";
$mail{Message} .= "It contains an accented letter: à (a grave).\n";
$mail{Message} .= "It was sent on " . Mail::Sendmail::time_to_date() . "\n";

# Go send it
print "Sending...\n";

if (sendmail %mail) {
    print "content of \$Mail::Sendmail::log:\n$Mail::Sendmail::log\n";
    if ($Mail::Sendmail::error) {
        print "content of \$Mail::Sendmail::error:\n$Mail::Sendmail::error\n";
    }
    print "ok 2\n";
}
else {
    print "\n!Error sending mail:\n$Mail::Sendmail::error\n";
    print "not ok 2\n";
}
