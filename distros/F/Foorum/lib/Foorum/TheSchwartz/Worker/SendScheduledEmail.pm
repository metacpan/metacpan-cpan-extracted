package Foorum::TheSchwartz::Worker::SendScheduledEmail;

use strict;
use warnings;
our $VERSION = '1.001000';
use base qw( TheSchwartz::Moosified::Worker );
use Foorum::SUtils qw/schema/;
use Foorum::Logger qw/error_log/;
use Foorum::XUtils qw/config base_path/;
use File::Spec;

sub work {
    my $class = shift;
    my $job   = shift;

    my @args = $job->arg;

    my $schema = schema();

    my $rs = $schema->resultset('ScheduledEmail')
        ->search( { processed => 'N' } );

    my $handled = 0;
    while ( my $rec = $rs->next ) {

        send_email(
            $rec->from_email, $rec->to_email, $rec->subject,
            $rec->plain_body, $rec->html_body
        );

        # update processed
        $rec->update( { processed => 'Y' } );
        $handled++;
    }

    if ($handled) {
        error_log( $schema, 'info', "$0 - sent: $handled" );
    }

    $job->completed();
}

use MIME::Entity;
use Email::Send;
use YAML::XS qw/LoadFile/;

my $base_path = base_path();
my $config;
if ( -e File::Spec->catfile( $base_path, 'conf', 'mail.yml' ) ) {
    $config
        = LoadFile( File::Spec->catfile( $base_path, 'conf', 'mail.yml' ) );
} else {
    $config = LoadFile(
        File::Spec->catfile(
            $base_path, 'conf', 'examples', 'mail', 'sendmail.yml'
        )
    );
}

if ( $config->{mailer} eq 'Sendmail' ) {
    if ( -e '/usr/sbin/sendmail' ) {
        $Email::Send::Sendmail::SENDMAIL = '/usr/sbin/sendmail';
    }
}

my $mailer = Email::Send->new($config);

sub send_email {
    my ( $from, $to, $subject, $plain_body, $html_body ) = @_;

    my $top = MIME::Entity->build(
        'X-Mailer' => undef,                   # remove X-Mailer tag in header
        'Type'     => 'multipart/alternative',
        'Reply-To' => $from,
        'From'     => $from,
        'To'       => $to,
        'Subject'  => $subject,
    );

    return unless ( $plain_body or $html_body );

    if ($plain_body) {
        $top->attach(
            Encoding => '7bit',
            Type     => 'text/plain',
            Charset  => 'utf-8',
            Data     => $plain_body,
        );
    }

    if ($html_body) {
        $top->attach(
            Type     => 'text/html',
            Encoding => '7bit',
            Charset  => 'utf-8',
            Data     => $html_body,
        );
    }

    my $email = $top->stringify;
    $mailer->send($email);
}

1;
__END__

=pod

=head1 NAME

Foorum::TheSchwartz::Worker::SendScheduledEmail - Send email in cron job

=head1 SYNOPSIS

  # check bin/cron/TheSchwartz_client.pl and bin/cron/TheSchwartz_worker.pl for usage

=head1 DESCRIPTION

It's not so quick to send email in Catalyst App, so that Catalyst App just insert data into scheduled_email table and this module handles the sending part!

=head1 SEE ALSO

L<TheSchwartz>

=head1 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut
