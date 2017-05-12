package Haineko;
use feature ':5.10';
use strict;
use warnings;
use parent 'Haineko::HTTPD';

our $VERSION = '0.2.16';
our $SYSNAME = 'Haineko';

sub startup {
    my $class = shift;
    my $httpd = shift;  # (Haineko::HTTPD);

    my $nekorouter = $httpd->router;
    my $serverconf = $httpd->conf;
    my $servername = $ENV{'HOSTNAME'} || $ENV{'SERVER_NAME'} || qx(hostname) || q();
    chomp $servername;

    $serverconf->{'smtpd'}->{'system'} = $SYSNAME;
    $serverconf->{'smtpd'}->{'version'} = $VERSION;
    $serverconf->{'smtpd'}->{'hostname'} ||= $servername;
    $serverconf->{'smtpd'}->{'servername'} = $servername;

    $nekorouter->connect( '/', { 'controller' => 'Root', 'action' => 'index' } );
    $nekorouter->connect( '/neko', { 'controller' => 'Root', 'action' => 'neko' } );
    $nekorouter->connect( '/dump', { 'controller' => 'Root', 'action' => 'info' } );
    $nekorouter->connect( '/conf', { 'controller' => 'Root', 'action' => 'info' } );
    $nekorouter->connect( '/submit', { 'controller' => 'Sendmail', 'action' => 'submit' } );
    $nekorouter->connect( '/sample/mail', { 'controller' => 'Sample', 'action' => 'mail' } );

    return $httpd->r;
}

1;
__END__
=encoding utf-8

=head1 NAME

Haineko - HTTP API into ESMTP

=head1 DESCRIPTION

Haineko is a HTTP-API server for sending email. It runs as a web server on 
port 2794 using Plack. 

Haineko stands for B<H>TTP B<A>PI B<IN>TO B<E>SMTP B<K>=undef B<O>=undef, means
a gray cat.

=head1 SYNOPSIS

    $ bin/hainekoctl start -a libexec/haineko.psgi
    $ plackup -o '127.0.0.1' -p 2794 -a libexec/haineko.psgi

=head1 EMAIL SUBMISSION

=head2 URL

    http://127.0.0.1:2794/submit

=head2 PARAMETERS

To send email via Haineko, POST email data as a JSON format like the following:

    { 
        ehlo: 'your-host-name.as.fqdn'
        mail: 'kijitora@example.jp'
        rcpt: [ 'cats@cat-ml.kyoto.example.jp' ]
        header: { 
            from: 'kijitora <kijitora@example.jp>'
            subject: 'About next meeting'
            relpy-to: 'cats <ml@cat-ml.kyoto.example.jp>'
            charset: 'ISO-2022-JP'
        }
        body: 'Next meeting opens at midnight on next thursday'
    }

    $ curl 'http://127.0.0.1:2794/submit' -X POST -H 'Content-Type: application/json' \
        -d '{ ehlo: "[127.0.0.1]", mail: "kijitora@example.jp", ... }'

OR

    $ curl 'http://127.0.0.1:2794/submit' -X POST -H 'Content-Type application/json' \
        -d '@/path/to/email.json'


=head1 CONFIGURATION FILES

These files are read from Haineko as a YAML-formatted file.

=head2 C<etc/haineko.cf>

Main configuration file for Haineko.

=head2 C<etc/mailertable>

Defines "mailer table": Recipient's domain part based routing table like the 
same named file in Sendmail. This file is taken precedence over the routing 
table defined in C<etc/sendermt> for deciding the mailer.

=head2 C<etc/sendermt>

Defines "mailer table" which decide the mailer by sender's domain part.

=head2 C<etc/authinfo>

Provide credentials for client side authentication information.  Credentials 
defined in this file are used at relaying an email to external SMTP server.

This file should be set secure permission: The only user who runs haineko server
can read this file.

=head2 C<etc/relayhosts>

Permitted hosts or network table for relaying via C</submit>.

=head2 C<etc/recipients>

Permitted envelope recipients and domains for relaying via C</submit>.

=head2 C<etc/password>

Username and password pairs for basic authentication. Haineko require an username
and a password at receiving an email if C<HAINEKO_AUTH> environment variable was
set.  The value of C<HAINEKO_AUTH> environment variable is the path to password
file.

=head2 URL

    http://127.0.0.1:2794/conf

C</conf> can be accessed from 127.0.0.1 and display Haineko configuration data as a
JSON.

=head1 ENVIRONMENT VARIABLES

=head2 C<HAINEKO_ROOT>

Haineko decides the root directory by C<HAINEKO_ROOT> or the result of C<`pwd`> 
command, and read C<haineko.cf> from C<HAINEKO_ROOT/etc/haineko.cf> if C<HAINEKO_CONF>
environment variable is not defined.

=head2 C<HAINEKO_CONF>

The value of C<HAINEKO_CONF> is the path to C<__haineko.cf__> file. If this variable
is not defined, Haineko finds the file from C<HAINEKO_ROOT/etc> directory. This
variable can be set with C<-C /path/to/haineko.cf> at C<bin/hainekoctl> script.

=head2 C<HAINEKO_AUTH>

Haineko requires Basic Authentication at connecting Haineko server when C<HAINEK_AUTH>
environment variable is set. The value of C<HAINEKO_AUTH> should be the path to
the password file such as C<'export HAINEKO_AUTH=/path/to/password'>. This variable
can be set with C<-A> option of C<bin/hainekoctl> script.

=head2 C<HAINEKO_DEBUG>

Haineko runs on debug (development) mode when this variable is set. C<-d> option
of C<bin/hainekoctl> turns on debug mode.

=head1 REPOSITORY

https://github.com/azumakuniyuki/Haineko

=head1 AUTHOR

azumakuniyuki E<lt>perl.org [at] azumakuniyuki.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under 
the same terms as Perl itself.

=cut
