use strict;
use warnings;
use Test::Most;
use Test::MockObject;
use IO::All 'io';
use File::Basename 'dirname';

use_ok('Email::Mailer');

my @mail;
Test::MockObject->fake_module( 'Email::Mailer', 'sendmail', sub {
    push( @mail, shift );
} );

sub file_qr {
    my $qr = io( dirname($0) . '/qr/' . shift )->all;
    chomp($qr);
    $qr =~ s/\r?\n/\\s+/msg;
    return qr/$qr/ms;
}

#-------------------------------------------------------------------------------

@mail = ();
lives_ok(
    sub {
        Email::Mailer->send(
            to      => 'to@example.com',
            from    => 'from@example.com',
            subject => 'Test Email',
            text    => 'This is a simple text-only email.',
        )
    },
    'Email::Mailer->send(...) text-only email',
);
is( @mail, 1, '1 mail generated' );
is( ref $mail[0], 'Email::MIME', 'mail object created is Email::MIME' );
like( $mail[0]->as_string, file_qr('text_only.qr'), 'text_only.qr' );

#-------------------------------------------------------------------------------

@mail = ();
lives_ok(
    sub {
        Email::Mailer->new->send(
            to      => 'to@example.com',
            from    => 'from@example.com',
            subject => 'Test Email',
            html    => q{
                <p>
                    This is a generic message for <b>testing purposes only</b>
                    with regard to some stuff and things:
                </p>
                <ul>
                    <li>Stuff</li>
                    <li>Things</li>
                </ul>
            },
        )
    },
    'Email::Mailer->new->send(...) HTML + auto-text',
);
is( @mail, 1, '1 mail generated' );
is( ref $mail[0], 'Email::MIME', 'mail object created is Email::MIME' );
like( $mail[0]->as_string, file_qr('html_auto_text.qr'), 'html_auto_text.qr' );

#-------------------------------------------------------------------------------

@mail = ();
lives_ok(
    sub {
        Email::Mailer->new(
            to      => 'to@example.com',
            from    => 'from@example.com',
            subject => 'Test Email',
            html    => q{
                <p>
                    This is a generic message for <b>testing purposes only</b>
                    with regard to some stuff and things:
                </p>
                <img src="} . dirname($0) . q{/blank.gif">
                <ul>
                    <li>Stuff</li>
                    <li>Things</li>
                </ul>
            },
        )->send
    },
    'Email::Mailer->new(...)->send HTML + auto-text',
);
is( @mail, 1, '1 mail generated' );
is( ref $mail[0], 'Email::MIME', 'mail object created is Email::MIME' );
like( $mail[0]->as_string, file_qr('html_auto_text_img.qr'), 'html_auto_text_img.qr' );

#-------------------------------------------------------------------------------

@mail = ();
lives_ok(
    sub {
        Email::Mailer->new->send(
            to      => 'to@example.com',
            from    => 'from@example.com',
            subject => 'Test Email',
            embed   => 0,
            html    => q{
                <p>
                    This is a generic message for <b>testing purposes only</b>
                    with regard to some stuff and things:
                </p>
                <img src="} . dirname($0) . q{/blank.gif">
                <ul>
                    <li>Stuff</li>
                    <li>Things</li>
                </ul>
            },
        )
    },
    'Email::Mailer->new->send(...) HTML + auto-text',
);
is( @mail, 1, '1 mail generated' );
is( ref $mail[0], 'Email::MIME', 'mail object created is Email::MIME' );
like( $mail[0]->as_string, file_qr('html_auto_text_img_noembed.qr'), 'html_auto_text_img_noembed.qr' );

#-------------------------------------------------------------------------------

@mail = ();
lives_ok(
    sub {
        Email::Mailer->send(
            to      => 'to@example.com',
            from    => 'from@example.com',
            subject => 'Test Email',
            text    => 'This is a simple text-only email.',
            html    => q{
                <p>
                    This is a generic message for <b>testing purposes only</b>
                    with regard to some stuff and things:
                </p>
            },
        )
    },
    'Email::Mailer->send HTML + text',
);
is( @mail, 1, '1 mail generated' );
is( ref $mail[0], 'Email::MIME', 'mail object created is Email::MIME' );
like( $mail[0]->as_string, file_qr('html_text.qr'), 'html_text.qr' );

#-------------------------------------------------------------------------------

@mail = ();
lives_ok(
    sub {
        Email::Mailer->send(
            to      => 'to@example.com',
            from    => 'from@example.com',
            subject => 'Test Email',
            text    => 'This is a simple text-only email.',
            html    => '<p>This is a generic message for <b>testing purposes only</b>.</p>',
            attachments => [
                {
                    ctype  => 'image/gif',
                    source => dirname($0) . '/blank.gif',
                },
                {
                    ctype  => 'image/gif',
                    content => io( dirname($0) . '/blank.gif' )->binary->all,
                    name    => 'blank.gif',
                },
            ],
        )
    },
    'Email::Mailer->send HTML + text + attachments',
);
is( @mail, 1, '1 mail generated' );
is( ref $mail[0], 'Email::MIME', 'mail object created is Email::MIME' );
like( $mail[0]->as_string, file_qr('html_text_attachments.qr'), 'html_text_attachments.qr' );

#-------------------------------------------------------------------------------

@mail = ();
lives_ok(
    sub {
        Email::Mailer->new(
            from    => 'from@example.com',
            subject => 'Test Email',
            html    => '<p>This is a generic message for <b>testing purposes only</b>.</p>',
        )->send(
            { to => 'person_0@example.com' },
            {
                to      => 'person_1@example.com',
                subject => 'Override $subject with this',
            },
        )
    },
    'Email::Mailer->new(...)->send( iterative_send )',
);
is( @mail, 2, '2 mails generated' );
like( $mail[0]->as_string, file_qr('iterative_send_0.qr'), 'iterative_send_0.qr' );
like( $mail[1]->as_string, file_qr('iterative_send_1.qr'), 'iterative_send_1.qr' );

#-------------------------------------------------------------------------------

@mail = ();
lives_ok(
    sub {
        Email::Mailer->new(
            to      => 'to@example.com',
            from    => 'from@example.com',
            subject => \'Test Email: [% content %]',
            html    => \'<p>This is a generic message: <b>[% content %]</b>.</p>',
            process => sub {
                my ( $template, $data ) = @_;
                $template =~ s/\[%\s*content\s*%\]/$data->{content}/g;
                return $template;
            },
        )->send( to => 'override@example.com', data => { content => 'Process' } )
    },
    'Email::Mailer->new(...)->send(...) templating',
);
is( @mail, 1, '1 mail generated' );
like( $mail[0]->as_string, file_qr('templating.qr'), 'templating.qr' );

done_testing;
