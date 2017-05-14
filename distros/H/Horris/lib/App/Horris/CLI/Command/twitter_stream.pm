package App::Horris::CLI::Command::twitter_stream;
# ABSTRACT: anyevent twitter streaming script


use Moose;
use Config::General qw/ParseConfig/;
use DBI;
use AnyEvent::Twitter::Stream;
use namespace::autoclean;
extends 'MooseX::App::Cmd::Command';

has database => (
    is            => 'ro',
    isa           => 'Str',
    traits        => ['Getopt'],
    required      => 1,
    documentation => "sqlite3 database file",
);

has key_config => (
    is          => 'rw',
    isa         => 'Str', 
    traits      => ['Getopt'],
    default     => "$ENV{HOME}/.twitter_key", 
    cmd_aliases => 'k',
    documentation =>
      "twitter api key file. default using $ENV{HOME}/.twitter_key",
);

has track => (
    is            => 'ro',
    isa           => 'Str',
    traits        => ['Getopt'],
    default       => 'perl,anyevent,catalyst,dancer,plack,psgi',
    cmd_aliases   => 't',
    documentation => "tracking keywords",
);

has key => (
    is          => 'rw',
    isa         => 'HashRef', 
    traits        => ['NoGetopt'],
    lazy_build  => 1
);

sub _build_key {
    my $self = shift;
    return { ParseConfig($self->key_config) };
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    my $consumer_key        = $self->key->{consumer_key};
    my $consumer_secret     = $self->key->{consumer_secret};
    my $access_token        = $self->key->{access_token};
    my $access_token_secret = $self->key->{access_token_secret};

    my $dbh = DBI->connect( "dbi:SQLite:dbname=" . $self->database, "", "" );
    my $sth_insert = $dbh->prepare("insert into messages values (?, ?, 0, ?)");

    my $done = AE::cv;

    # to use OAuth authentication
    my $listener = AnyEvent::Twitter::Stream->new(
        consumer_key    => $consumer_key,
        consumer_secret => $consumer_secret,
        token           => $access_token,
        token_secret    => $access_token_secret,
        method          => "filter",
        track           => $self->track, 
        on_tweet        => sub {
            my $tweet = shift;

            my $text = $tweet->{text};
            my @chars = split //, $text;

            my $cnt = 0;
            map { $cnt++ if /[\p{Hangul}\p{Hiragana}\p{Katakana}\p{Latin}\p{Common}]/; } @chars;
            if($cnt / scalar @chars > 0.5 and $tweet->{user}{screen_name} !~ m/perlism/i) {
                $sth_insert->execute( 'twitter_stream', scalar time,
                    "$tweet->{user}{screen_name}: $tweet->{text}" );
            }
        },
        on_keepalive => sub {
            warn "ping\n";
        },
        on_error => sub {
            my $error = shift;
            warn "Error : $error\n";
            $done->send;
        },
        on_eof => sub {
            $done->send;
        },
        timeout => 60,
    );

    $done->recv;

}

1;

__END__
=pod

=encoding utf-8

=head1 NAME

App::Horris::CLI::Command::twitter_stream - anyevent twitter streaming script

=head1 VERSION

version v0.1.2

=head1 SYNOPSIS

    sample code base here
    horris twitter_stream --database /path/to/poll.db

following command for more detail.

    horris help twitter_stream

=head1 DESCRIPTION

F<$HOME/.twitter_key> sample

    consumer_key              cosumer key here
    consumer_secret           cosumer secret here
    access_token              access token here           # oauth_token
    access_token_secret       access token secret here    # (oauth_token_secret)

=head1 AUTHOR

hshong <hshong@perl.kr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by hshong.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

