package Fancazzista::Scrap::WebsiteScrapper;

use strict;
use warnings;
use LWP::UserAgent;
use HTTP::Request;
use Mojo::DOM;
use JSON;
use Encode qw(encode);

our $VERSION = '0.01';

sub new {
    my $class = shift;

    my $self = {};

    bless $self, $class;

    return $self;
}

sub scrap {
    my $self   = shift;
    my $config = shift;

    my @websites = ();

    foreach ( @{ $config->{websites} } ) {
        my @resourceArticles = $self->extractArticles($_);

        push @websites,
          {
            name     => $_->{name},
            url      => $_->{url},
            articles => \@resourceArticles
          };
    }

    return @websites;
}

sub getWebsiteHtml {
    my $self = shift;
    my $url  = shift;

    my $ua = new LWP::UserAgent;
    $ua->agent( "$0/0.1 " . $ua->agent );

    my $req = new HTTP::Request 'GET' => $url;
    $req->header( 'Accept' => 'text/html' );

    my $res = $ua->request($req);

    return $res->decoded_content;
}

sub extractArticles {
    my $self     = shift;
    my $resource = shift;
    my $content = $self->getWebsiteHtml( $resource->{url} );
    my $dom     = Mojo::DOM->new($content);
    my $found   = $dom->find( $resource->{selector} );

    my @articles = ();

    foreach ( $found->each ) {
        my $text = $_->find( $resource->{textSelector} )->[0]->text;
        my $link = $_->find( $resource->{linkSelector} )->[0]->attr->{href};

        $text =~ s/^\s+|\s+$//g;

        push @articles,
          {
            text => encode( 'utf8', $text ),
            link => $link
          };
    }

    return @articles;
}

1;
