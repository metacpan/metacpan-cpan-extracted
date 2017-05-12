package Foorum::ResultSet::ScheduledEmail;

use strict;
use warnings;
our $VERSION = '1.001000';
use base 'DBIx::Class::ResultSet';

use Foorum::Utils qw/generate_random_word/;
use Foorum::Logger qw/error_log/;

sub send_activation {
    my ( $self, $user, $new_email, $opts ) = @_;

    my $schema = $self->result_source->schema;
    my $cache  = $schema->cache();
    my $tt2    = $schema->tt2();
    my $config = $schema->config();
    my $lang   = $opts->{lang};

    my $activation_code;
    my $rs = $schema->resultset('UserActivation')
        ->find( { user_id => $user->user_id, } );
    if ($rs) {
        $activation_code = $rs->activation_code;
    } else {
        $activation_code = generate_random_word(10);
        my @extra_insert;
        if ($new_email) {
            @extra_insert = ( 'new_email', $new_email );
        }
        $schema->resultset('UserActivation')->create(
            {   user_id         => $user->user_id,
                activation_code => $activation_code,
                @extra_insert,
            }
        );
    }

    my $vars = {
        username        => $user->username,
        activation_code => $activation_code,
        new_email       => $new_email,
        config          => $config,
    };

    my $email_body;
    $tt2->process( "lang/$lang/email/activation.html", $vars, \$email_body );

    $self->create(
        {   email_type => 'activation',
            from_email => $config->{mail}->{from_email},
            to_email   => $user->email,
            subject    => 'Your Activation Code In ' . $config->{name},
            plain_body => $email_body,
            time       => time(),
            processed  => 'N',
        }
    );
    my $client = $schema->theschwartz();
    $client->insert('Foorum::TheSchwartz::Worker::SendScheduledEmail');
}

sub create_email {
    my ( $self, $opts ) = @_;

    my $schema    = $self->result_source->schema;
    my $cache     = $schema->cache();
    my $tt2       = $schema->tt2();
    my $config    = $schema->config();
    my $base_path = $schema->base_path();
    my $lang      = $opts->{lang};

    my $subject    = $opts->{subject};
    my $plain_body = $opts->{plain_body};
    my $html_body  = $opts->{html_body};

    unless ( $subject and ( $plain_body or $html_body ) ) {

        # find the template for TT use
        my $template_prefix;
        my $template_name = $opts->{template};
        my $file_prefix
            = "$base_path/templates/lang/$lang/email/$template_name";
        if ( -e $file_prefix . '.txt' or -e $file_prefix . '.html' ) {
            $template_prefix = "lang/$lang/email/$template_name";
        } elsif ( 'en' ne $lang ) {

            # try to use lang=en for default
            $file_prefix
                = "$base_path/templates/lang/en/email/$template_name";
            if ( -e $file_prefix . '.txt' or -e $file_prefix . '.html' ) {
                $template_prefix = 'lang/en/email/' . $template_name;
            }
        }
        unless ($template_prefix) {
            error_log( $schema, 'error',
                "Template not found in Email.pm notification with params: $template_name"
            );
            return 0;
        }

# we will set 'base' in cron manually, so we put %$stash before %{$opts->{stash}}
        my $stash = $opts->{stash};
        $stash->{config} = $config;

        # prepare TXT format
        if ( -e $file_prefix . '.txt' ) {
            $tt2->process( $template_prefix . '.txt', $stash, \$plain_body );
        }
        if ( -e $file_prefix . '.html' ) {
            $tt2->process( $template_prefix . '.html', $stash, \$html_body );
        }

        # get the subject from $plain_body or $html_body
        # the format is ########Title Subject#########
        if ( $plain_body and $plain_body =~ s/\#{6,}(.*?)\#{6,}\s+//isg ) {
            $subject = $1;
        }
        if ( $html_body and $html_body =~ s/\#{6,}(.*?)\#{6,}\s+//isg ) {
            $subject = $1;
        }
        $subject ||= 'Notification From ' . $config->{name};
    }

    my $to         = $opts->{to};
    my $from       = $opts->{from} || $config->{mail}->{from_email};
    my $email_type = $opts->{email_type} || $opts->{template};
    $self->create(
        {   email_type => $email_type,
            from_email => $from,
            to_email   => $to,
            subject    => $subject,
            plain_body => $plain_body,
            html_body  => $html_body,
            time       => time(),
            processed  => 'N',
        }
    );

    my $client = $schema->theschwartz();
    $client->insert('Foorum::TheSchwartz::Worker::SendScheduledEmail');

    return 1;
}

1;
