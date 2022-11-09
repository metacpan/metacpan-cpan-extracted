package Email::Stuffer::TestLinks;

use strict;
use warnings;

our $VERSION = '0.03';

use Test::More;
use Mojo::DOM;
use Email::Stuffer;
use Class::Method::Modifiers qw/ install_modifier /;
use IO::Async::Loop;
use Net::Async::HTTP;
use IO::Async::SSL;
use URI;
use Future::Utils qw( fmap_void );

=head1 SYNOPSIS

    use Email::Stuffer::TestLinks;

=head1 NAME

Email::Stuffer::TestLinks - validates links in HTML emails sent by
Email::Stuffer>send_or_die()

=head1 DESCRIPTION

When this module is included in a test, it parses http links (<a href="xyz">...</a>)
and image links (<img src="xyz">) in every email sent through Email::Stuffer->send_or_die().
Each URI must be  get a successful response code (200 range).
Page title must not contain 'error' or 'not found' for text/html content.
Image links must return an image content type.

=cut

install_modifier 'Email::Stuffer', after => send_or_die => sub {

    my $self = shift;

    my %urls;
    $self->email->walk_parts(
        sub {
            my ($part) = @_;
            return unless ($part->content_type && $part->content_type =~ /text\/html/i);
            my $dom = Mojo::DOM->new($part->body);
            push @{$urls{http}},  $dom->find('a')->map(attr => 'href')->compact->grep(sub { $_ !~ /^mailto:/ })->uniq->to_array->@*;
            push @{$urls{image}}, $dom->find('img')->map(attr => 'src')->compact->uniq->to_array->@*;
        });

    my @data = map {
        my $type = $_;
        map { [$type, $_] } $urls{$type}->@*
    } keys %urls;

    my $loop = IO::Async::Loop->new();
    $loop->add(my $http = Net::Async::HTTP->new(max_connections_per_host => 3));

    (
        fmap_void {
            my ($type, $url) = @$_;

            my $uri = URI->new($url);
            unless ($uri->scheme) {
                fail "$type link $url is an invalid uri";
                return Future->done;
            }

            $http->GET(URI->new($uri))->then(
                sub {
                    my $response = shift;

                    return Future->fail("Response code was " . $response->code) if ($response->code !~ /^2\d\d/);

                    if ($response->content_type eq 'text/html') {
                        my $dom = Mojo::DOM->new($response->decoded_content);
                        if (my $title = $dom->at('title')) {
                            return Future->fail("Page title contains text '$1'") if $title->text =~ /(error|not found)/i;
                        }
                    }

                    if ($type eq 'image') {
                        return Future->fail("Unexpected content type: " . $response->content_type) unless $response->content_type =~ /^image\//;
                    }

                    return Future->done;
                }
            )->transform(
                done => sub {
                    pass "$type link works ($url)";
                },
                fail => sub {
                    my $failure = shift;
                    fail "$type link $url does not work - $failure";
                }
            )->else(sub { Future->done })
        }
        foreach    => \@data,
        concurrent => 10
    )->get;

};

1;
