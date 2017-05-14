package App::Horris::CLI::Command::feed;
# ABSTRACT: rss feed update and notify


use Moose;
use Const::Fast;
use AnyEvent;
use AnyEvent::Feed;
use Encode;
use HTML::Strip;
use DBI;
use namespace::autoclean;
extends 'MooseX::App::Cmd::Command';

const my @FEED_URLS => (
    "http://www.blogger.com/feeds/5137684887780288527/posts/default",
    "http://www.perl.com/pub/atom.xml",
    "http://feeds.feedburner.com/YetAnotherCpanRecentChanges",
    "http://jeen.tistory.com/rss",
    "http://blogs.perl.org/atom.xml",
    "http://planet.perl.org/rss20.xml",
    "http://perlsphere.net/atom.xml",
    "http://use.perl.org/index.rss",
"http://blogsearch.google.co.kr/blogsearch_feeds?q=perl+dancer+OR+catalyst+OR+anyevent+OR+moose&hl=ko&lr=&newwindow=1&prmdo=1&prmd=ivns&output=atom",
);

has database => (
    is            => 'ro',
    isa           => 'Str',
    traits        => ['Getopt'],
    required      => 1,
    documentation => "sqlite3 database file",
);

has interval => (
    is            => 'rw',
    isa           => 'Int',
    traits        => ['Getopt'],
    default       => 300,
    cmd_aliases   => 'i', 
    documentation => "polling interval time as seconds. default is 300 seconds",
);

sub execute {
    my ( $self, $opt, $args ) = @_;

    my $dbh = DBI->connect( "dbi:SQLite:dbname=" . $self->database, "", "" );
    my $sth_insert = $dbh->prepare("insert into messages values (?, ?, 0, ?)");
    my $hs         = HTML::Strip->new();
    my $w          = AnyEvent->condvar;
    my @feeders;
    my %firstfeed;
    foreach my $url (@FEED_URLS) {
        my $feed_reader;
        $feed_reader = AnyEvent::Feed->new(
            url      => $url,
            interval => $self->interval,

            on_fetch => sub {
                my ( $feed_reader, $new_entries, $feed, $error ) = @_;
                if ( defined $error ) {
                    warn "ERROR: $error\n";
                    return;
                }

                #warn "$url\n";
                unless ( $firstfeed{ $feed->link } ) {
                    warn "Skip the first feeding. :: $url\n";
                    $firstfeed{ $feed->link }++;
                    return;
                }
                warn "\n";

                printf "Added %d entries..\n", scalar @$new_entries;
                for (@$new_entries) {

                    my ( $hash, $entry ) = @$_;

                    my $body =
                      $hs->parse( encode( 'utf8', $entry->content->body ) );
                    $body =~ s/[\r\n]//g;
                    $body =~ s/\s+/ /g;

                    my $message = sprintf "%s :: %s :: %s\n\n",
                      encode( 'utf8', $entry->title ),
                      substr( $body, 0, 100 ),
                      $entry->link;

                    my $issue_time =
                      $entry->issued ? $entry->issued->epoch : time;
                    $sth_insert->execute( 'rss_atom', $issue_time, $message );
                }
            }
        );
        push @feeders, $feed_reader;
    }

    $w->recv;
}

1;

__END__
=pod

=encoding utf-8

=head1 NAME

App::Horris::CLI::Command::feed - rss feed update and notify

=head1 VERSION

version v0.1.2

=head1 SYNOPSIS

    horris feed --database /path/to/poll.db

following command for more detail.

    horris help feed

=head1 AUTHOR

hshong <hshong@perl.kr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by hshong.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

