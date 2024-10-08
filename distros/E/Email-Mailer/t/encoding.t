use Test2::V0;
use Email::Mailer;

my @mail;
my $mock = mock 'Email::Mailer' => ( override => [ sendmail => sub { push( @mail, shift ) } ] );

my $attachments = [{
    ctype    => 'text/plain',
    encoding => 0,
    content  => 'data',
    name     => 'data.txt',
}];

my $re = [
    qr|
        \r?\n
        Content-Type:\s+text/plain;\s+charset=UTF-8\r?\n
        Content-Transfer-Encoding:\s+quoted-printable\r?\n\r?\n
        E\s=3D\smc\^2;\sBeton=
    |x,
    qr|
        \r?\n
        Content-Type:\s+text/plain;\s+charset=UTF-8\r?\n
        Content-Transfer-Encoding:\s+quoted-printable\r?\n\r?\n
        E\s=3D\smc\^2;\sB=C3=A9ton=
    |x,
    qr|
        \r?\n
        Content-Type:\s+text/plain;\s+charset=UTF-8\r?\n
        Content-Transfer-Encoding:\s+quoted-printable\r?\n\r?\n
        E\s=3D\smc\^2;\sBeton
        .+?
        \r?\n
        Content-Type:\s+text/html;\s+charset=UTF-8\r?\n
        Content-Transfer-Encoding:\s+quoted-printable\r?\n\r?\n
        E\s=3D\smc\^2;\sB<b>e</b>ton=
    |xs,
    qr|
        \r?\n
        Content-Type:\s+text/plain;\s+charset=UTF-8\r?\n
        Content-Transfer-Encoding:\s+quoted-printable\r?\n\r?\n
        E\s=3D\smc\^2;\sB=C3=A9ton
        .+?
        \r?\n
        Content-Type:\s+text/html;\s+charset=UTF-8\r?\n
        Content-Transfer-Encoding:\s+quoted-printable\r?\n\r?\n
        E\s=3D\smc\^2;\sB<b>=C3=A9</b>ton=
    |xs,
];

for (
    [ '01. ASCII text', { text => 'Beton' }, $re->[0] ],
    [ '02. UTF-8 text', { text => 'Béton' }, $re->[1] ],
    [ '03. ASCII HTML', { html => 'B<b>e</b>ton' }, $re->[2] ],
    [ '04. UTF-8 HTML', { html => 'B<b>é</b>ton' }, $re->[3] ],
    [ '05. ASCII text + HTML', { text => 'Beton', html => 'B<b>e</b>ton' }, $re->[2] ],
    [ '06. UTF-8 text + HTML', { text => 'Béton', html => 'B<b>é</b>ton' }, $re->[3] ],
    [ '07. ASCII text w/ attach', { text => 'Beton', attachments => $attachments }, $re->[0] ],
    [ '08. UTF-8 text w/ attach', { text => 'Béton', attachments => $attachments }, $re->[1] ],
    [ '09. ASCII HTML w/ attach', { html => 'B<b>e</b>ton', attachments => $attachments }, $re->[2] ],
    [ '10. UTF-8 HTML w/ attach', { html => 'B<b>é</b>ton', attachments => $attachments }, $re->[3] ],
    [
        '11. ASCII text + HTML w/ attach',
        { text => 'Beton', html => 'B<b>e</b>ton', attachments => $attachments },
        $re->[2],
    ],
    [
        '12. UTF-8 text + HTML w/ attach',
        { text => 'Béton', html => 'B<b>é</b>ton', attachments => $attachments },
        $re->[3],
    ],
) {
    $_->[1]{text} = 'E = mc^2; ' . $_->[1]{text} if ( exists $_->[1]{text} );
    $_->[1]{html} = 'E = mc^2; ' . $_->[1]{html} if ( exists $_->[1]{html} );

    Email::Mailer->new( %{ $_->[1] } )->send;

    like( $mail[-1]->as_string, $_->[2], $_->[0] );
}

done_testing;
