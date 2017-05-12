# <@LICENSE>
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
# </@LICENSE>

package Konfidi::Client;
use warnings;
use strict;

=head1 NAME

Konfidi::Client - Interact with a Konfidi TrustServer

=head1 DESCRIPTION

Konfidi is a trust framework that uses topical trust values from a social network of authenticated people. When you see a document (e.g email, webpage) from someone you do not know, but he/she is in the network, Konfidi will compute an inferred trust value for you.  For more information, see L<http://konfidi.org>

=head1 VERSION

Version 1.0.4

=cut

our $VERSION = '1.0.4';

=head1 SYNOPSIS

    use Konfidi::Client;
    use Error qw(:try);

    my $k = Konfidi::Client->new();
    $k->server('http://test-server.konfidi.org');
    try {
        my $response = $k->query($truster_40char_pgp_fingerprint, $trusted_40char_pgp_fingerprint, 'http://www.konfidi.org/ns/topics/0.0#internet-communication');
    } catch Konfidi::Client::Error with {
        my $E = shift;
        die "Couldn't query the trustserver: $E";
    };
    ...

See L<Error> for error handling documentation

=head1 METHODS

=head2 C<new()>

Create a new C<Konfidi::Client>

=cut

use Carp;
use LWP::UserAgent;
use URI::Escape;
use Konfidi::Client::Error;
use Konfidi::Response;

sub new {
    my $this = shift;
    my $class = ref($this) || $this;
    croak unless $class;
    my $self = {};
    bless $self, $class;
    $self->_initialize();
    return $self;
}

sub _initialize {
    my $self = shift;
    $self->{server} = undef;
    #$self->{strategy} = 'Multiplicative2';
	return;
}

=head2 C<server()>

Get or set the server to use.  Required.  For example: C<http://test-server.konfidi.org>

=cut

sub server {
    my $self = shift;
    if (@_) {
        $self->{server} = shift;
        if ($self->{server} && substr($self->{server}, -1, 1) eq '/') {
            chop $self->{server};
        }
    }
    return $self->{server};
}

=head2 C<strategy()>

Get or set which trust propogation strategy to use.  No default (server decides)

=cut

sub strategy {
    my $self = shift;
    if (@_) { $self->{strategy} = shift;}
    return $self->{strategy};
}

=head2 C<query($source, $sink, $topic)>

Query the Konfidi Trustserver, using the default or set C<server> and C<strategy> values.  C<$source> and C<$sink> must be 40 character long OpenPGP fingerprint identifiers.  The only topic currently in use is C<'http://www.konfidi.org/ns/topics/0.0#internet-communication'>.
Returns a L<Konfidi::Response> or throws a L<Konfidi::Client::Error> upon error

=cut

sub query {
    my $self = shift;
    my ($source, $sink, $topic) = @_;
    
    throw Konfidi::Client::Error("You must set the 'server'") unless $self->{server};
    
    my $ua = LWP::UserAgent->new;
    $ua->agent("Perl Konfidi::Client/$VERSION");
    
    my $url = $self->{server} . '/query?';
    if (defined($self->{'strategy'})) {
        $url .= 'strategy=' . uri_escape($self->{'strategy'}) . '&';
    }
    if (defined($source)) {
        $url .= "source=" . uri_escape($source) . '&';
    }
    if (defined($sink)) {
        $url .= "sink=" . uri_escape($sink) . '&';
    }
    if (defined($topic)) {
        $url .= "topic=" . uri_escape($topic) . '&';
    }
    my $req = HTTP::Request->new(GET => $url);
    #$req->content_type('application/x-www-form-urlencoded');
    #$req->content('query=libwww-perl&mode=dist');
    
    my $res = $ua->request($req);
    
    my $server_version = $res->header('X-Konfidi-Frontend-Version');
    # TODO compare server_version
    
    if ($res->is_success) {
        # mod_python errors are text/html
        # and we don't know how to handle anything else anyway
        if ($res->header('Content-Type') ne 'text/plain') {
            throw Konfidi::Client::Error("Server had a bad error:\n " . $res->content);
        }
        
        my $response = Konfidi::Response->new();
        foreach (split(/\n/,$res->content)) {
            my ($key, $val) = split /:/;
            $val =~ s/^\s+//; # ltrim
            $response->{$key} = $val;
        }
        
        if ($response->{'Error'}) {
            throw Konfidi::Client::Error("Server had an error: " . $response->{'Error'});
        } else {
            return $response;
        }
    }else {
        throw Konfidi::Client::Error("Could not reach server; HTTP status: " . $res->status_line);
    }
}

1;

__END__

=head1 AUTHOR

Dave Brondsema, C<< <dave at brondsema.net> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-konfidi-client at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Konfidi>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Konfidi::Client

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Konfidi>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Konfidi>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Konfidi>

=item * Search CPAN

L<http://search.cpan.org/dist/Konfidi>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2006 Dave Brondsema

This program is released under the following license: Apache License, Version 2.0

=cut

