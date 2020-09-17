package Log::Dispatch::Email::Mailer;
# ABSTRACT: Log::Dispatch::Email subclass that sends mail using Email::Mailer

use 5.014;
use strict;
use warnings;

use base 'Log::Dispatch::Email';

use Email::Mailer 1.09;

our $VERSION = '1.08'; # VERSION

sub _params {
    my %params = @_;
    delete $params{$_} for ( qw( buffer buffered level_names level_numbers max_level min_level name ) );
    return %params;
}

sub new {
    my $self = shift->SUPER::new(@_);

    my %params = _params( @_, %$self );
    delete $params{$_} for ( qw( message mailer level ) );
    $self->{mailer} //= Email::Mailer->new(%params);

    for ( qw( html text ) ) {
        $self->{$_} = $params{$_} if ( not exists $self->{$_} and exists $params{$_} );
    }

    return $self;
}

sub send_email {
    my $self = shift;

    my %params = _params( @_, %$self );
    $params{data}{messages} = ( ref $params{message} ) ? $params{message} : [ $params{message} ];
    $params{data}{message}  = join( "\n", @{ $params{data}{messages} } );
    $params{text} = $params{data}{message} unless ( $self->{html} or $self->{text} );
    delete $params{$_} for ( qw( message mailer level ) );

    $self->{mailer}->send(%params);
    return;
}

sub flush {
    my $self = shift;

    if ( $self->{buffered} and @{ $self->{buffer} } ) {
        $self->send_email( message => $self->{buffer} );
        $self->{buffer} = [];
    }

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Dispatch::Email::Mailer - Log::Dispatch::Email subclass that sends mail using Email::Mailer

=head1 VERSION

version 1.08

=for markdown [![Build Status](https://travis-ci.org/gryphonshafer/Log-Dispatch-Email-Mailer.svg)](https://travis-ci.org/gryphonshafer/Log-Dispatch-Email-Mailer)
[![Coverage Status](https://coveralls.io/repos/gryphonshafer/Log-Dispatch-Email-Mailer/badge.png)](https://coveralls.io/r/gryphonshafer/Log-Dispatch-Email-Mailer)

=head1 SYNOPSIS

    use Log::Dispatch;

    # simple text email alert via Log::Dispatch
    my $log = Log::Dispatch->new(
        outputs => [
            [
                'Email::Mailer',
                min_level => 'alert',
                to        => [ qw( foo@example.com bar@example.org ) ],
                subject   => 'Alert Log Message',
            ],
        ],
    );
    $log->alert('This is to alert you something happened.');

    # simple text email alert via direct instantiation
    my $email = Log::Dispatch::Email::Mailer->new(
        min_level => 'alert',
        to        => [ qw( foo@example.com bar@example.org ) ],
        subject   => 'Alert Log Message',
    );
    $email->log(
        message => 'This is to alert you something happened.',
        level   => 'alert',
    );

    # simple text email using an Email::Mailer object with explicit transport
    $log = Log::Dispatch->new(
        outputs => [
            [
                'Email::Mailer',
                min_level => 'alert',
                to        => [ qw( foo@example.com bar@example.org ) ],
                subject   => 'Alert Log Message',
                mailer    => Email::Mailer->new(
                    transport => Email::Sender::Transport::SMTP->new({
                        host => 'smtp.example.com',
                        port => 25,
                    }),
                ),
            ],
        ],
    );
    $log->alert('This is to alert you something happened.');

    # HTML email alert with attached log file using Template Toolkit
    use Template;
    my $tt = Template->new;
    $log   = Log::Dispatch->new(
        outputs => [
            [
                'Email::Mailer',
                min_level => 'alert',
                to        => [ qw( foo@example.com bar@example.org ) ],
                subject   => 'Alert Log Message',
                html      => \q{
                    <pre>[% message %]</pre>
                    <p>[% messages.join("<br>") %]</p>
                },
                attachments => [
                    {
                        ctype   => 'text/plain',
                        content => 'This is plain text attachment content.',
                        name    => 'log_file.txt',
                    },
                ],
                process => sub {
                    my ( $template, $data ) = @_;
                    my $content;
                    $tt->process( \$template, $data, \$content );
                    return $content;
                },
            ],
        ],
    );
    $log->alert('This is to alert you something happened.');

=head1 DESCRIPTION

This is a subclass of L<Log::Dispatch::Email> that implements the C<send_email()>
method using the L<Email::Mailer> module. Much like the L<Email::Mailer> module,
you can send email in a great variety of ways including text-only, HTML with
text auto-generated, including attachments, and even using your favorite
templating system.

=head2 Simple Text Email

The simplest way to use this module is to setup an "outputs" record with
L<Log::Dispatch> much like you would any other email subclass.

    my $log = Log::Dispatch->new(
        outputs => [
            [
                'Email::Mailer',
                min_level => 'alert',
                to        => [ qw( foo@example.com bar@example.org ) ],
                subject   => 'Alert Log Message',
            ],
        ],
    );
    $log->alert('This is to alert you something happened.');

By default, log messages are buffered and sent either when C<$log> is destroyed
or when you call C<< $log->flush >>.

    $log->alert('This message will appear in an email.');
    $log->alert('This message will appear in the same email, but not yet...');
    $log->flush; # now both alerts will get sent in one email

Note that unlike many other L<Log::Dispatch::Email> subclasses, multiple
buffered messages won't be concatenated together without spaces. Instead, the
messages will appear in a text-only email as independent lines.

As an alternative to buffering, you can explicitly set buffering off to have
each log line send a single email.

    my $log = Log::Dispatch->new(
        outputs => [
            [
                'Email::Mailer',
                min_level => 'alert',
                to        => [ qw( foo@example.com bar@example.org ) ],
                subject   => 'Alert Log Message',
                buffer    => 0,
            ],
        ],
    );
    $log->alert('This will be in one email.');
    $log->alert('This will be in a second email.');

=head2 Simple Text Email with Explicit Transport

By default, this module will create its own L<Email::Mailer> object through
which to send email. You can provide a "mailer" value of an explicit
L<Email::Mailer> object you create and control, thus allowing you to set things
like an explicit transport mechanism.

    my $log = Log::Dispatch->new(
        outputs => [
            [
                'Email::Mailer',
                min_level => 'alert',
                to        => [ qw( foo@example.com bar@example.org ) ],
                subject   => 'Alert Log Message',
                mailer    => Email::Mailer->new(
                    transport => Email::Sender::Transport::SMTP->new({
                        host => 'smtp.example.com',
                        port => 25,
                    }),
                ),
            ],
        ],
    );
    $log->alert('This is to alert you something happened.');

=head2 HTML Email with Attached File Using Template Toolkit

If you want to have some real fun with sending email log messages (and let's be
real here, who doesn't), try using this module to send templated HTML email
with attachments. Any key/value you can pass to L<Email::Mailer>, you can pass
as part of the "outputs" element.

The following example uses an HTML template (which per L<Email::Mailer> needs
to be a scalar reference) and a very simple Template Toolkit process subref.

    use Template;
    my $tt  = Template->new;
    my $log = Log::Dispatch->new(
        outputs => [
            [
                'Email::Mailer',
                min_level => 'alert',
                to        => [ qw( foo@example.com bar@example.org ) ],
                subject   => 'Alert Log Message',
                html      => \q{
                    <pre>[% message %]</pre>
                    <p>[% messages.join("<br>") %]</p>
                },
                attachments => [
                    {
                        ctype   => 'text/plain',
                        content => 'This is plain text attachment content.',
                        name    => 'log_file.txt',
                    },
                ],
                process => sub {
                    my ( $template, $data ) = @_;
                    my $content;
                    $tt->process( \$template, $data, \$content );
                    return $content;
                },
            ],
        ],
    );
    $log->alert('This is to alert you something happened.');

What's happening behind the scenes is that the "data" value that you'd normally
pass to L<Email::Mailer> that would work its way down into the "process" subref
is in this case being generated for you. It gets populated with two sub-keys:
message and messages. The first is a "\n"-separated string of log messages.
The second is an arrayref of those strings.

=head1 SEE ALSO

L<Email::Mailer>, L<Log::Dispatch::Email>, L<Log::Dispatch>.

You can also look for additional information at:

=over 4

=item *

L<GitHub|https://github.com/gryphonshafer/Log-Dispatch-Email-Mailer>

=item *

L<MetaCPAN|https://metacpan.org/pod/Log::Dispatch::Email::Mailer>

=item *

L<Travis CI|https://travis-ci.org/gryphonshafer/Log-Dispatch-Email-Mailer>

=item *

L<Coveralls|https://coveralls.io/r/gryphonshafer/Log-Dispatch-Email-Mailer>

=item *

L<CPANTS|http://cpants.cpanauthors.org/dist/Log-Dispatch-Email-Mailer>

=item *

L<CPAN Testers|http://www.cpantesters.org/distro/D/Log-Dispatch-Email-Mailer.html>

=back

=head1 AUTHOR

Gryphon Shafer <gryphon@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Gryphon Shafer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
