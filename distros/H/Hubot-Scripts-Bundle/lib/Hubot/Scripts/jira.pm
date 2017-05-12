package Hubot::Scripts::jira;
$Hubot::Scripts::jira::VERSION = '0.1.10';
use strict;
use warnings;
use Encode qw/decode_utf8/;
use JSON;

sub load {
    my ( $class, $robot ) = @_;
    $robot->httpd->reg_cb(
        '/hubot/jira' => sub {
            my ( $httpd, $req ) = @_;
            my $json = undef;

            my $url = URI->new($req->url);
            my $req_secret = undef;
            if ($url->query_param("secret") && $url->query_param("secret") =~ m/.../) {
              $req_secret = $url->query_param("secret");
            }

            my $req_room = undef;
            if ($url->query_param("room") && $url->query_param("room") =~ m/.../) {
              $req_room = $url->query_param("room");
              $req_room=~s/^%23/#/;
            }

            eval { $json = decode_json( $req->{content} ); };
            if ($@) {
                $req->respond(
                    [
                        400,
                        'Bad Request',
                        { content => 'text/json' },
                        "{ 'status': 'error', 'error': 'could not parse json' }"
                    ]
                );
                return;
            }
            my $helper = Hubot::Scripts::jira::helper->new();

            if ( !$helper->checkRoom( $req_room ) ) {
                $req->respond(
                    [
                        400, 'Bad Request',
                        { content => 'text/json' },
                        "{ 'status': 'error', 'error': 'missing room' }"
                    ]
                );
                return;
            }
            if ( !$helper->checkSecret( $req_secret ) ) {
                $req->respond(
                    [
                        401,
                        'Unauthorized',
                        { content => 'text/json' },
                        "{ 'status': 'error', 'error': 'Secret missing/wrong/not set in ENV' }"
                    ]
                );
                return;
            }

            my $jira_created_issue = 0;
            my $jira_username;
            my $jira_subject;
            my $jira_ticketnr;
            eval {
              $jira_username = $json->{'user'}->{'displayName'};
              if ($json->{'webhookEvent'} && $json->{'webhookEvent'} =~ m/jira:issue_created/) {
                $jira_created_issue = 1;
              }
              $jira_subject = $json->{'issue'}->{'fields'}->{'summary'};
              $jira_ticketnr = $json->{'issue'}->{'key'};
            };
            if (! $jira_created_issue) {
              $req->respond(
                [
                  500,
                  'jira_issue_created',
                  { content => 'text/json' },
                  "{ 'status': 'error', 'error': 'JIRA Issue was not created'}"
                ]
              );
              return;
            }

            my $line = "JIRA Issue $jira_username created $jira_ticketnr with $jira_subject\n";

            my $user = Hubot::User->new( { 'room' => $req_room } );
            $robot->adapter->send( $user, decode_utf8( $line ) );
            $req->respond(
                { content => ['text/json', "{ 'status': 'OK' }"] } );
        }
    );
}


package Hubot::Scripts::jira::helper;
$Hubot::Scripts::jira::helper::VERSION = '0.1.10';
use strict;
use warnings;

sub new {
    my $class = shift;
    my $self = { _secret => $ENV{HUBOT_JIRA_WEBHOOK_SECRET} };
    bless $self, $class;
    return $self;
}

sub checkSecret {
    my ( $class, $secret ) = @_;
    unless ($secret) {
        return undef;
    }
    unless ( $class->{_secret} ) {
        return undef;
    }
    if ( $secret eq $class->{_secret} ) {
        return 1;
    }
    return undef;
}

sub checkRoom {
    my ( $class, $room ) = @_;
    if ( $room && $room =~ m /../ ) {
        return 1;
    }
    return undef;
}

1;

=pod

=encoding utf-8

=head1 NAME

Hubot::Scripts::jira

=head1 VERSION

version 0.1.10

=head1 SYNOPSIS

Inform channel members about new created issues in JIRA.

=head1 CONFIGURATION

=over

=item HUBOT_JIRA_WEBHOOK_SECRET

=back

=head1 DESCRIPTION

HTTP Jira Interface WebHook Interface with SERECT file.

Create a JIRA Webhook in the JIRA admin interface with the following options:


 * URL:
   https://yourbot.com/hubot/jira?secret=123456&room=%23foobar

 * Exclude details:
   No

 * JQL:
   (nothing) = All issues

 * Events:
   Issue Created

Please use the environment variable HUBOT_JIRA_WEBHOOK_SECRET to set the secret key.

Your room is #foobar, you need to escape the '#' for JIRA.

This p5 hubot plugin was tested with JIRA 6.1.7.

=head1 AUTHOR

Jonas Genannt <jonas@capi2name.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Jonas Genannt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
