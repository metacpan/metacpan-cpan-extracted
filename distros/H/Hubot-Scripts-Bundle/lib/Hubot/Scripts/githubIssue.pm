package Hubot::Scripts::githubIssue;
$Hubot::Scripts::githubIssue::VERSION = '0.1.10';
use strict;
use warnings;
use JSON;

sub load {
    my $github = githubot->new;
    my ( $class, $robot ) = @_;
    $robot->hear(
        qr/((\S*|^)?#(\d+)).*/,
        sub {
            my $msg             = shift;
            my $issue_number    = $msg->match->[2];
            my $bot_github_repo = $github->qualified_repo( $msg->match->[1]
                    // $ENV{HUBOT_GITHUB_REPO} );

            my $issue_title = '';
            $github->request(
                'get',
                "/repos/$bot_github_repo/issues/$issue_number",
                sub {
                    my ( $body, $hdr ) = @_;
                    return if ( !$body || $hdr->{Status} !~ /^2/ );
                    my $data = decode_json($body);
                    $issue_title = $data->{title};
                    my $base_url = $ENV{HUBOT_GITHUB_API}
                        // 'https://api.github.com';
                    my $url;
                    unless ( $ENV{HUBOT_GITHUB_API} ) {
                        $url = "https://github.com";
                    }
                    else {
                        $url = $base_url;
                        $url =~ s/\/api\/v3//;
                    }
                    $msg->send(
                        "Issue $issue_number: $issue_title $url/$bot_github_repo/issues/$issue_number"
                    );
                }
            );
        }
    );
}

package githubot;
$githubot::VERSION = '0.1.10';
use strict;
use warnings;
use AnyEvent::HTTP::ScopedClient;

sub new {
    my ( $class, $opts ) = @_;

    $opts->{token}       = $ENV{HUBOT_GITHUB_TOKEN};
    $opts->{defaultRepo} = $ENV{HUBOT_GITHUB_REPO};
    $opts->{defaultUser} = $ENV{HUBOT_GITHUB_USER};
    $opts->{apiRoot}     = $ENV{HUBOT_GITHUB_API} // "https://api.github.com";
    $opts->{apiVersion}  = $ENV{HUBOT_GITHUB_VERSION} // "beta";
    return bless $opts, $class;
}

sub qualified_repo {
    my ( $self, $repo ) = @_;
    unless ($repo) {
        unless ( $repo = $self->{defaultRepo} ) {
            print STDERR "Default Github repo not specified";
            return;
        }
    }
    $repo = lc $repo;
    return $repo unless index( $repo, '/' ) == -1;
    my $user = $self->{defaultUser};
    unless ($user) {
        print STDERR "Default Github user not specified";
        return $repo;
    }
    return "$user/$repo";
}

sub request {
    my ( $self, $verb, $url, $data, $cb ) = @_;
    ( $cb, $data ) = ( $data, undef ) unless $cb;

    my $url_api_base = $self->{apiRoot};
    if ( $url !~ m/^http/ ) {
        $url = "/$url" unless $url =~ m|^/|;
        $url = $url_api_base . $url;
    }
    my $req = AnyEvent::HTTP::ScopedClient->new($url);
    $req = $req->header(
        {
            Accept => 'application/vnd.github.'
                . $self->{apiVersion} . '+json',
            'User-Agent' => "p5-GitHubot"
        }
    );
    my $oauth_token = $self->{token};
    $req->header( 'Authorization', "token $oauth_token" ) if $oauth_token;
    my $method = lc $verb;
    $req->$method( $data, $cb );
}

1;

=head1 NAME

Hubot::Scripts::githubIssue

=head1 VERSION

version 0.1.10

=head1 SYNOPSIS

    #nnn - link to GitHub issue nnn for HUBOT_GITHUB_REPO project
    repo#nnn - link to GitHub issue nnn for repo project
    user/repo#nnn - link to GitHub issue nnn for user/repo project

=head1 CONFIGURATION

=over

=item * HUBOT_GITHUB_REPO

=item * HUBOT_GITHUB_TOKEN

=item * HUBOT_GITHUB_API

=item * HUBOT_GITHUB_ISSUE_LINK_IGNORE_USERS

=back

=head1 AUTHOR

Hyungsuk Hong <hshong@perl.kr>

=cut
