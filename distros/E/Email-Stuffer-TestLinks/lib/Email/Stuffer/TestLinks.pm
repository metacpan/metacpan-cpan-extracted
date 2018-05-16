package Email::Stuffer::TestLinks;

use strict;
use warnings;

our $VERSION = 0.020;

use Test::Most;
use Mojolicious 6.00;
use Mojo::UserAgent;
use Email::Stuffer;
use Class::Method::Modifiers qw/ install_modifier /;

=head1 SYNOPSIS

    use Email::Stuffer::TestLinks;

=head1 NAME

Email::Stuffer::TestLinks - validates links in HTML emails sent by
Email::Stuffer>send_or_die()

=head1 DESCRIPTION

When this module is included in a test, it parses HTML links (<a href="xyz"...)
in every email sent through Email::Stuffer->send_or_die(). Each URI must get a
successful response code (200 range) and the returned pagetitle must not contain
'error' or 'not found'.

=cut

install_modifier 'Email::Stuffer', after => send_or_die => sub {

    my $self = shift;
    my $ua = Mojo::UserAgent->new(max_redirects => 10, connect_timeout => 5);

    my %urls;
    $self->email->walk_parts(
        sub {
            my ($part) = @_;
            return unless ($part->content_type && $part->content_type =~ /text\/html/i);
            my $dom = Mojo::DOM->new($part->body);
            my $links = $dom->find('a')->map(attr => 'href')->compact;

            # Exclude anchors, mailto
            $urls{$_} = 1 for (grep { !/^mailto:/ } @$links);
        });

    for my $url (sort keys %urls) {

        my $err = '';

        if ($url =~ /^[#\/]/) {
            $err = "$url is not a valid URL for an email";
        } else {
            my $tx = $ua->get($url);

            if ($tx->success) {
                my $res = $tx->result;

                if ($res->code !~ /^2\d\d/) {
                    $err = "HTTP code was " . $res->code;
                } else {
                    my $title = $res->dom->at('title')->text;
                    $err = "Page title contains text '$1'"
                        if $title =~ /(error|not found)/i;
                }
            } else {
                $err = "Could not retrieve URL: " . $tx->error->{message};
            }
        }
        ok(!$err, "Link in email works ($url)") or diag($err);
    }

};

1;
