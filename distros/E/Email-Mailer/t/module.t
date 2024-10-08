use Test2::V0;
use Email::Mailer;
use File::Basename 'dirname';
use IO::All 'io';

my @mail;
my $mock = mock 'Email::Mailer' => ( override => [ sendmail => sub { push( @mail, shift ) } ] );

sub file_qr {
    my $qr = io( dirname($0) . '/qr/' . shift )->all;
    chomp($qr);
    $qr =~ s/\r?\n/\\s+/msg;
    return qr/$qr/ms;
}

sub get_headers {
    my @headers;
    ( my $content = $_[0] ) =~ s/\r//g;

    while ( $content =~ /^((?:[\w\-]+:\s*[^\n]+\n)+)/mg ) {
        my $block = $1;
        my %block;
        $block{$1} = $2 while ( $block =~ /([\w\-]+):\s*([^\n]+)/g );
        push( @headers, \%block );
    }

    return \@headers;
}

#-------------------------------------------------------------------------------

@mail = ();
ok(
    lives {
        Email::Mailer->send(
            to      => 'to@example.com',
            from    => 'from@example.com',
            subject => 'Test Email',
            text    => 'This is a simple text-only email.',
        )
    },
    'Email::Mailer->send(...) text-only email',
) or note $@;
is( @mail, 1, '1 mail generated' );
is( ref $mail[0], 'Email::MIME', 'mail object created is Email::MIME' );
like( $mail[0]->as_string, file_qr('text_only.qr'), 'text_only.qr' );

#-------------------------------------------------------------------------------

@mail = ();
ok(
    lives {
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
            width => 0,
        )
    },
    'Email::Mailer->new->send(...) HTML + auto-text',
) or note $@;
is( @mail, 1, '1 mail generated' );
is( ref $mail[0], 'Email::MIME', 'mail object created is Email::MIME' );

my $as_string = $mail[0]->as_string;
like( $as_string, file_qr('html_auto_text.qr'), 'html_auto_text.qr' );

my $headers = get_headers($as_string);
like( $headers->[0]{'Message-Id'}, qr/^<[^>]+>$/, 'Message-Id header looks reasonable' );
like( $headers->[0]{'Content-Type'}, qr|^multipart/mixed\b|, 'Content-Type is multipart/mixed' );
is( $headers->[0]{'Subject'}, 'Test Email', 'Subject is correct' );
is( $headers->[0]{'To'}, 'to@example.com', 'To is correct' );
is( $headers->[0]{'From'}, 'from@example.com', 'From is correct' );
is( $headers->[2]{'Content-Type'}, 'text/plain; charset=UTF-8', 'Email contains text-only portion' );
like( $headers->[3]{'Content-Type'}, qr|^text/html\b|, 'Email contains HTML portion' );

#-------------------------------------------------------------------------------

@mail = ();
ok(
    lives {
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
            width => 0,
        )->send
    },
    'Email::Mailer->new(...)->send HTML + auto-text',
) or note $@;
is( @mail, 1, '1 mail generated' );
is( ref $mail[0], 'Email::MIME', 'mail object created is Email::MIME' );

$as_string = $mail[0]->as_string;
like( $as_string, file_qr('html_auto_text_img.qr'), 'html_auto_text_img.qr' );

$headers = get_headers($as_string);
like( $headers->[0]{'Message-Id'}, qr/^<[^>]+>$/, 'Message-Id header looks reasonable' );
like( $headers->[0]{'Content-Type'}, qr|^multipart/mixed\b|, 'Content-Type is multipart/mixed' );
is( $headers->[0]{'Subject'}, 'Test Email', 'Subject is correct' );
is( $headers->[0]{'To'}, 'to@example.com', 'To is correct' );
is( $headers->[0]{'From'}, 'from@example.com', 'From is correct' );
is( $headers->[2]{'Content-Type'}, 'text/plain; charset=UTF-8', 'Email contains text-only portion' );
like( $headers->[4]{'Content-Type'}, qr|^text/html\b|, 'Email contains HTML portion' );
like( $headers->[5]{'Content-Type'}, qr|^image/gif\b|, 'Email contains image portion' );

#-------------------------------------------------------------------------------

@mail = ();
ok(
    lives {
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
            width => 0,
        )
    },
    'Email::Mailer->new->send(...) HTML + auto-text',
) or note $@;
is( @mail, 1, '1 mail generated' );
is( ref $mail[0], 'Email::MIME', 'mail object created is Email::MIME' );

$as_string = $mail[0]->as_string;
like( $as_string, file_qr('html_auto_text_img_noembed.qr'), 'html_auto_text_img_noembed.qr' );

$headers = get_headers($as_string);
like( $headers->[0]{'Message-Id'}, qr/^<[^>]+>$/, 'Message-Id header looks reasonable' );
like( $headers->[0]{'Content-Type'}, qr|^multipart/mixed\b|, 'Content-Type is multipart/mixed' );
is( $headers->[0]{'Subject'}, 'Test Email', 'Subject is correct' );
is( $headers->[0]{'To'}, 'to@example.com', 'To is correct' );
is( $headers->[0]{'From'}, 'from@example.com', 'From is correct' );
is( $headers->[2]{'Content-Type'}, 'text/plain; charset=UTF-8', 'Email contains text-only portion' );
like( $headers->[3]{'Content-Type'}, qr|^text/html\b|, 'Email contains HTML portion' );

#-------------------------------------------------------------------------------

@mail = ();
ok(
    lives {
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
            width => 0,
        )
    },
    'Email::Mailer->send HTML + text',
) or note $@;
is( @mail, 1, '1 mail generated' );
is( ref $mail[0], 'Email::MIME', 'mail object created is Email::MIME' );

$as_string = $mail[0]->as_string;
like( $as_string, file_qr('html_text.qr'), 'html_text.qr' );

$headers = get_headers($as_string);
like( $headers->[0]{'Message-Id'}, qr/^<[^>]+>$/, 'Message-Id header looks reasonable' );
like( $headers->[0]{'Content-Type'}, qr|^multipart/mixed\b|, 'Content-Type is multipart/mixed' );
is( $headers->[0]{'Subject'}, 'Test Email', 'Subject is correct' );
is( $headers->[0]{'To'}, 'to@example.com', 'To is correct' );
is( $headers->[0]{'From'}, 'from@example.com', 'From is correct' );
is( $headers->[2]{'Content-Type'}, 'text/plain; charset=UTF-8', 'Email contains text-only portion' );
like( $headers->[3]{'Content-Type'}, qr|^text/html\b|, 'Email contains HTML portion' );

#-------------------------------------------------------------------------------

@mail = ();
ok(
    lives {
        Email::Mailer->send(
            to      => 'to@example.com',
            from    => 'from@example.com',
            subject => 'Test Email',
            text    => 'This is a simple text-only email.',
            html    => '<p>This is a generic message for <b>testing purposes only</b>.</p>',
            attachments => [
                {
                    ctype    => 'image/gif',
                    source   => dirname($0) . '/blank.gif',
                    encoding => 'quoted-printable',
                },
                {
                    ctype    => 'image/gif',
                    content  => io( dirname($0) . '/blank.gif' )->binary->all,
                    name     => 'blank.gif',
                    encoding => 'quoted-printable',
                },
            ],
        )
    },
    'Email::Mailer->send HTML + text + attachments',
) or note $@;
is( @mail, 1, '1 mail generated' );
is( ref $mail[0], 'Email::MIME', 'mail object created is Email::MIME' );

$as_string = $mail[0]->as_string;
like( $as_string, file_qr('html_text_attachments.qr'), 'html_text_attachments.qr' );

$headers = get_headers($as_string);
like( $headers->[0]{'Message-Id'}, qr/^<[^>]+>$/, 'Message-Id header looks reasonable' );
like( $headers->[0]{'Content-Type'}, qr|^multipart/mixed\b|, 'Content-Type is multipart/mixed' );
is( $headers->[0]{'Subject'}, 'Test Email', 'Subject is correct' );
is( $headers->[0]{'To'}, 'to@example.com', 'To is correct' );
is( $headers->[0]{'From'}, 'from@example.com', 'From is correct' );
is( $headers->[2]{'Content-Type'}, 'text/plain; charset=UTF-8', 'Email contains text-only portion' );
like( $headers->[3]{'Content-Type'}, qr|^text/html\b|, 'Email contains HTML portion' );
like( $headers->[4]{'Content-Type'}, qr|^image/gif\b|, 'Email contains image portion 1' );
like( $headers->[5]{'Content-Type'}, qr|^image/gif\b|, 'Email contains image portion 2' );

#-------------------------------------------------------------------------------

@mail = ();
ok(
    lives {
        Email::Mailer->new(
            from    => 'from@example.com',
            subject => 'Test Email',
            html    => '<p>This is a generic message for <b>testing purposes only</b>.</p>',
            width   => 0,
        )->send(
            { to => 'person_0@example.com' },
            {
                to      => 'person_1@example.com',
                subject => 'Override $subject with this',
            },
        )
    },
    'Email::Mailer->new(...)->send( iterative_send )',
) or note $@;
is( @mail, 2, '2 mails generated' );
like( $mail[0]->as_string, file_qr('iterative_send_0.qr'), 'iterative_send_0.qr' );
like( $mail[1]->as_string, file_qr('iterative_send_1.qr'), 'iterative_send_1.qr' );

#-------------------------------------------------------------------------------

@mail = ();
ok(
    lives {
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
) or note $@;
is( @mail, 1, '1 mail generated' );
like( $mail[0]->as_string, file_qr('templating.qr'), 'templating.qr' );

#-------------------------------------------------------------------------------

done_testing;
