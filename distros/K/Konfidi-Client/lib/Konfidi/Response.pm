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

package Konfidi::Response;

use warnings;
use strict;

=head1 NAME

Konfidi::Response - a Konfidi TrustServer response

=head1 DESCRIPTION

A hash of values as the response from querying the Konfidi TrustServer.  The 'Rating' value is used when a Response is used in a numerical context.

=head1 VERSION

Version 1.0.4

=cut

our $VERSION = '1.0.4';

=head1 SYNOPSIS

    use Konfidi::Client;
    use Konfidi::Response;
    use Error(:try);

    my $k = Konfidi::Client->new();
    $k->server('http://test-server.konfidi.org');
    try {
        my $response = $k->query($truster_40char_pgp_fingerprint, $trusted_40char_pgp_fingerprint, 'http://www.konfidi.org/ns/topics/0.0#internet-communication');
    } catch Konfidi::Client::Error with {
        my $E = shift;
        die "Couldn't query the trustserver: $E";
    };
    
    if ($response > 0.5) {
        ...
    }
    $response->{'Subject'};
    $response->{'Error'};
    ...

=head1 METHODS

=head2 C<new()>

=cut

use Carp;
use Scalar::Util qw(refaddr);

sub new {
    my $this = shift;
    my $class = ref($this) || $this;
    croak unless $class;
    my $self = {};
    bless $self, $class;
    return $self;
}

sub _numify {
    my $self = shift;
    return $self->{'Rating'};
}

# overloading 0+ without overloading "" would make stringification requests use numify
# so we have to overload ""
# this emulates the default "" operator, not sure how to make it actually use the default
sub _stringify {
    my $self = shift;
    return ref($self) . '=HASH(0x' . sprintf("%lx",refaddr($self)) . ')';
}

use overload
    '0+' => \&_numify,
    q("") => \&_stringify,
    fallback => 1;

1;

__END__

=head1 SEE ALSO

L<Konfidi::Client>, L<Konfidi::Client::Error>
