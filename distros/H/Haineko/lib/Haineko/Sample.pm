package Haineko::Sample;
use feature ':5.10';
use strict;
use warnings;
use utf8;

sub mail {
    my $class = shift;
    my $httpd = shift;

    my $xforwarded = [ split( ',', $httpd->req->header('X-Forwarded-For') || q() ) ];
    my $remoteaddr = pop @$xforwarded || $httpd->req->address // undef;
    my $samplemail = [
        {
            'mail' => 'envelope-sender-address@example.org',
            'rcpt' => [ 'envelope-recipient-address-1@example.jp' ],
            'ehlo' => sprintf( "[%s]", $remoteaddr ),
            'body' => 'Email message body',
            'header' => {
                'from' => 'Your Name <email-from-addr@example.com>',
                'subject' => 'Email subject',
                'replyto' => 'another-email-address-if-you-want-to-receive@example.net',
            },
        },
        {
            'helo' => 'your-host-name.example.net',
            'from' => 'envelope-sender-address@example.org',
            'to' => [ 'recipient1@example.com', 'recipient2@example.com' ],
            'body' => 'メールの本文(日本語)',
            'header' => {
                'from' => 'はいねこ <email-from-addr@example.com>',
                'subject' => 'メールの件名',
                'charset' => 'UTF-8',
            },
        },
    ];

    return $httpd->res->json( 200, Haineko::JSON->dumpjson( $samplemail ) );
}

1;
__END__
=encoding utf-8

=head1 NAME

Haineko::Sample - Controller for sample email

=head1 DESCRIPTION

Haineko::Sample is a controller for displaying email sample as a JSON.

=head2 URL

    http://127.0.0.1:2794/sample/mail

=head1 REPOSITORY

https://github.com/azumakuniyuki/Haineko

=head1 AUTHOR

azumakuniyuki E<lt>perl.org [at] azumakuniyuki.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under 
the same terms as Perl itself.

=cut
