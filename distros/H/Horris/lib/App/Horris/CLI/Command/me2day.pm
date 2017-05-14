package App::Horris::CLI::Command::me2day;
# ABSTRACT: me2day Watcher


use Moose;
use DBI;
use JSON;
use AnyEvent;
use File::Temp;
use LWP::Simple;
use Const::Fast;
use DateTime::Format::W3CDTF;
use URI;
use WWW::Shorten 'TinyURL';
use namespace::autoclean;
extends 'MooseX::App::Cmd::Command';

const my $URL_FORMAT => "http://me2day.net/api/get_posts/%s.json";

has database => (
    is            => 'ro',
    isa           => 'Str',
    traits        => ['Getopt'],
    documentation => "sqlite3 database file",
);

has tracing => (
    is            => 'ro',
    isa           => "ArrayRef[Str]",
    traits        => ['Getopt'],
    default       => sub { [ 'i_u0516', 'aanoaa' ] }, 
    cmd_aliases   => 't',
    documentation => "me2day id. 'i_u0516' and 'aanoaa' is default to use",
);

has interval => (
    is            => 'rw',
    isa           => 'Int',
    traits        => ['Getopt'],
    default       => 60,
    cmd_aliases   => 'i',
    documentation => "polling interval time as seconds. default is 60 seconds",
);

sub execute {
    my ( $self, $opt, $args ) = @_;

    my $dbh;
    my $sth_insert;
    if ( $self->database ) {
        $dbh = DBI->connect( "dbi:SQLite:dbname=" . $self->database, "", "" );
        $sth_insert = $dbh->prepare("insert into messages values (?, ?, 0, ?)");
    } else {
        print "NODB mode..on\n";
    }

    my $starttime    = scalar time;
    my $lastest_time = 0;

    my $cv = AnyEvent->condvar;
    my $w;
    $w = AnyEvent->timer(
        interval => $self->interval,
        cb       => sub {
            for my $id (@{ $self->tracing }) {
                my $json_url = sprintf $URL_FORMAT, $id;
                print "Checking $json_url\n";
                my $data    = get $json_url;
                my $content = from_json($data);
                for my $tweet ( @{$content} ) {
                    my $out = $tweet->{textBody};
                    $tweet->{pubDate} =~ s/0900$/09:00/; # temporary hack
                    if ( $tweet->{media}{photoUrl} ) {
                        my $url = $tweet->{media}{photoUrl};
                        my $uri = URI->new($url);
                        next unless $uri->scheme && $uri->scheme =~ /^http/i;
                        next unless $uri->authority;

                        if ( length "$uri" > 50
                            && $uri->authority !~ /tinyurl|bit\.ly/ )
                        {
                            $url = makeashorterlink($uri);
                        }

                        $out .= ' ' . $url;
                    }

                    my $dt =
                      DateTime::Format::W3CDTF->parse_datetime( $tweet->{pubDate} );
                    if ( $dt->epoch > $lastest_time and $dt->epoch > $starttime ) {
                        $lastest_time = $dt->epoch;
                        if ($self->database) {
                            $sth_insert->execute( 'me2day_iu', scalar time, $out )
                        } else {
                            printf "%s : %s\n", $dt->epoch, $out;
                        }
                    }
                }
            }
        }
    );

    $cv->recv;
}

1;

__END__
=pod

=encoding utf-8

=head1 NAME

App::Horris::CLI::Command::me2day - me2day Watcher

=head1 VERSION

version v0.1.2

=head1 SYNOPSIS

    horris feed --database /path/to/poll.db

following command for more detail.

    horris help me2day

=head1 AUTHOR

hshong <hshong@perl.kr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by hshong.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

