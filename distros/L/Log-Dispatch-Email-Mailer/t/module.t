use strict;
use warnings;
use Test::Most;
use Test::MockObject;
use IO::All 'io';
use File::Basename 'dirname';

use_ok('Log::Dispatch::Email::Mailer');

my @mail;
Test::MockObject->fake_module( 'Email::Mailer', 'sendmail', sub {
    push( @mail, shift );
} );

sub file_qr {
    my $qr = io( dirname($0) . '/qr/' . shift )->all;
    chomp($qr);
    $qr =~ s/\s+$//msg;
    $qr =~ s/\r?\n/\\s+/msg;
    return qr/$qr/ms;
}

#-------------------------------------------------------------------------------

@mail = ();
lives_ok(
    sub {
        my $log = Log::Dispatch->new(
            outputs => [
                [
                    'Email::Mailer',
                    min_level => 'alert',
                    to        => [ qw( foo@example.com bar@example.org ) ],
                    from      => 'from@example.com',
                    subject   => 'Alert Log Message',
                ],
            ],
        );
        $log->alert('This is to alert you something happened.');
    },
    'simple text email alert via Log::Dispatch',
);
is( @mail, 1, '1 mail generated' );
like( $mail[0]->as_string, file_qr('simple_text.qr'), 'simple_text.qr' );

#-------------------------------------------------------------------------------

@mail = ();
lives_ok(
    sub {
        my $log = Log::Dispatch->new(
            outputs => [
                [
                    'Email::Mailer',
                    min_level => 'alert',
                    to        => [ qw( foo@example.com bar@example.org ) ],
                    from      => 'from@example.com',
                    subject   => 'Alert Log Message',
                ],
            ],
        );
        $log->alert( 'This is to alert you something happened: ' . $_ ) for ( 1 .. 3 );
    },
    'multiple log messages in a simple text email',
);
is( @mail, 1, '1 mail generated' );
like( $mail[0]->as_string, file_qr('buffered_3.qr'), 'buffered_3.qr' );

#-------------------------------------------------------------------------------

@mail = ();
lives_ok(
    sub {
        my $log = Log::Dispatch->new(
            outputs => [
                [
                    'Email::Mailer',
                    min_level => 'alert',
                    to        => [ qw( foo@example.com bar@example.org ) ],
                    from      => 'from@example.com',
                    subject   => 'Alert Log Message',
                    buffered  => 0,
                ],
            ],
        );
        $log->alert( 'This is to alert you something happened: ' . $_ ) for ( 1 .. 3 );
    },
    'multiple log messages in a simple text email',
);
is( @mail, 3, '3 mails generated' );
like( $mail[1]->as_string, file_qr('unbuffered_2_of_3.qr'), 'unbuffered_2_of_3.qr' );

#-------------------------------------------------------------------------------

@mail = ();
lives_ok(
    sub {
        my $email = Log::Dispatch::Email::Mailer->new(
            min_level => 'alert',
            to        => [ qw( foo@example.com bar@example.org ) ],
            from      => 'from@example.com',
            subject   => 'Alert Log Message',
        );
        $email->log(
            message => 'This is to alert you something happened.',
            level   => 'alert',
        );
    },
    'simple text email alert via direct instantiation',
);
is( @mail, 1, '1 mail generated' );
like( $mail[0]->as_string, file_qr('simple_text.qr'), 'simple_text.qr' );

#-------------------------------------------------------------------------------

@mail = ();
lives_ok(
    sub {
        my $log = Log::Dispatch->new(
            outputs => [
                [
                    'Email::Mailer',
                    min_level => 'alert',
                    to        => [ qw( foo@example.com bar@example.org ) ],
                    from      => 'from@example.com',
                    subject   => 'Alert Log Message',
                    mailer    => Email::Mailer->new,
                ],
            ],
        );
        $log->alert('This is to alert you something happened.');
    },
    'simple text email using an Email::Mailer object with explicit transport',
);
is( @mail, 1, '1 mail generated' );
like( $mail[0]->as_string, file_qr('simple_text.qr'), 'simple_text.qr' );

#-------------------------------------------------------------------------------

@mail = ();
lives_ok(
    sub {
        my $log = Log::Dispatch->new(
            outputs => [
                [
                    'Email::Mailer',
                    min_level => 'alert',
                    to        => [ qw( foo@example.com bar@example.org ) ],
                    from      => 'from@example.com',
                    subject   => 'Alert Log Message',
                    html      => \'<p>This is a generic message: <b>[% content %]</b>.</p>',
                    attachments => [
                        {
                            ctype   => 'text/plain',
                            content => 'This is plain text attachment content.',
                            name    => 'log_file.txt',
                        },
                    ],
                    process => sub {
                        my ( $template, $data ) = @_;
                        $template =~ s/\[%\s*content\s*%\]/$data->{message}/g;
                        return $template;
                    },
                ],
            ],
        );
        $log->alert('This is to alert you something happened.');
    },
    'HTML email alert with attached log file using Template Toolkit',
);
is( @mail, 1, '1 mail generated' );
like( $mail[0]->as_string, file_qr('html_attachment.qr'), 'html_attachment.qr' );

done_testing;
