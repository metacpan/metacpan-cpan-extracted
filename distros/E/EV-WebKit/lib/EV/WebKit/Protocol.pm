package EV::WebKit::Protocol;
use v5.10;
use strict;
use warnings;

our $VERSION = '0.04';

# The control protocol's wire codec, and nothing else: no EV, no sockets, no
# browser. Both the server (EV::WebKit::Control) and the client
# (EV::WebKit::Client) use it, so "split on newlines, tolerate a partial read"
# exists once instead of drifting in two places -- and it is the one piece of
# the protocol that can be tested without a browser at all.
#
# One JSON object per line, UTF-8 octets.

use constant PROTO => 1;

# A client that opens a socket and never sends a newline would otherwise buffer
# without bound. 64 MiB is far above any real frame (a base64 full-page
# screenshot runs to a few MiB) and far below "eat the machine".
use constant MAX_LINE => 64 * 1024 * 1024;

# utf8(1): unlike EV::WebKit's own JSON object -- which is in CHARACTER mode,
# because Glib::Object::Introspection marshals utf8 strings as characters --
# this one writes to a SOCKET, and a socket carries octets.
my $JSON = do {
    my $j = eval { require Cpanel::JSON::XS; Cpanel::JSON::XS->new }
         || do { require JSON::PP; JSON::PP->new };
    $j->canonical(1)->utf8(1);
};

sub encode { $JSON->encode($_[0]) . "\n" }

# Returns a stateful decoder. Feed it octets; it returns however many complete
# frames those octets completed (possibly none). A line that is not a JSON
# object comes back as { _bad => $reason } instead of dying -- one client's
# garbage must not take down the browser or anybody else's session.
sub decoder {
    my $buf  = '';
    my $dead = 0;
    return sub {
        my ($octets) = @_;
        return ({ _bad => 'line too long' }) if $dead;
        $buf .= $octets if defined $octets && length $octets;
        if (length($buf) > MAX_LINE) {
            $dead = 1;
            $buf  = '';
            return ({ _bad => 'line too long' });
        }
        my @frames;
        while ((my $nl = index($buf, "\n")) >= 0) {
            my $line = substr($buf, 0, $nl, '');   # take the line...
            substr($buf, 0, 1, '');                # ...and drop the newline
            next unless length $line;              # a blank line is nothing
            my $f = eval { $JSON->decode($line) };
            push @frames, (ref $f eq 'HASH') ? $f : { _bad => 'bad request' };
        }
        return @frames;
    };
}

1;

__END__

=head1 NAME

EV::WebKit::Protocol - wire codec for the EV::WebKit control protocol

=head1 DESCRIPTION

Newline-delimited JSON: one object per line, UTF-8 octets. Used by
L<EV::WebKit::Control> and L<EV::WebKit::Client>. You do not normally touch it
directly.

=head1 FUNCTIONS

=head2 encode

    my $line = EV::WebKit::Protocol::encode({ i => 1, m => 'go', a => ['x'] });

Returns one newline-terminated line of UTF-8 octets.

=head2 decoder

    my $dec = EV::WebKit::Protocol::decoder();
    my @frames = $dec->($octets_from_the_socket);

Returns a stateful decoder. Feed it whatever the socket gave you -- a partial
line, several lines, a single byte -- and it returns the frames those octets
completed.

A line that is not a JSON object comes back as C<< { _bad => $reason } >> rather
than thrown: one client's garbage is that client's problem, not the browser's.
A line longer than C<MAX_LINE> (64 MiB) is refused outright, so a client that
never sends a newline cannot make the server buffer without bound.

=cut
