package Fancazzista::Scrap::DevtoScrapper;

use strict;
use warnings;
use LWP::UserAgent;
use HTTP::Request;
use JSON;
use Encode qw(encode);

our $VERSION = '1.00';

sub new {
    my $class = shift;

    my $self = {};

    bless $self, $class;

    return $self;
}

sub scrap {
    my $self   = shift;
    my $config = shift;

    my @list = ();

    foreach ( @{ $config->{devto} } ) {
        my @posts = $self->getPosts($_);

        push @list,
          {
            name       => $_->{tag},
            url        => "https://dev.to/t/" . $_->{tag},
            articles   => \@posts,
            from_devto => 1,
          };
    }

    return @list;
}

sub getPosts {
    my $self  = shift;
    my $devto = shift;

    my $base = "https://dev.to/api/articles";
    my $url  = $base . "?tag=" . $devto->{tag} . "&per_page=" . ( $devto->{limit} || 5 );

    my $r  = HTTP::Request->new( 'GET', $url );
    my $ua = LWP::UserAgent->new();
    $ua->agent('Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:86.0) Gecko/20100101 Firefox/86.0');
    my $response = $ua->request($r);

    my @posts = ();

    if ( $response->is_success ) {
        my $responseContent = decode_json $response->decoded_content;
        my @children        = @{$responseContent};

        foreach (@children) {
            my $text = $_->{title};
            $text =~ s/^\s+|\s+$//g;

            push @posts,
              {
                text => encode( 'utf8', $text ),
                link => $_->{url}
              };
        }
    } else {
        die $response->status_line;
    }

    return @posts;
}

1;

__END__

# ABSTRACT: Methods shared by Net::HTTP and Net::HTTPS
