package File::Feed::Sink;

use strict;
use warnings;

use URI;

sub new {
    my $cls = shift;
    my %arg;
    if (@_ == 1 && ref($_[0]) eq 'HASH') {
        %arg = %{ shift() };
    }
    elsif (@_ % 2) {
        %arg = ( 'uri', @_ );
    }
    else {
        %arg = @_;
    }
    my $uri = $arg{'#'} || $arg{'uri'} or die "Can't instantiate a sink without a URI";
    $uri = 'file://' . $uri if $uri =~ m{^/};
    $uri = URI->new($uri) if !ref $uri;
    my $scheme = $uri->scheme;
    $cls .= '::' . lc $scheme;
    eval "use $cls; 1" or die $@;
    bless {
        %arg,
        'uri'  => $uri,
    }, $cls;
}

sub uri { $_[0]->{'uri'} }
sub from { $_[0]->{'from'} }
sub host { $_[0]->{'host'} ||= $_[0]->{'uri'}->host }
sub root { $_[0]->{'root'} ||= $_[0]->{'uri'}->path }
sub user { $_[0]->{'user'} ||= $_[0]->{'uri'}->user }
sub password { $_[0]->{'password'} ||= $_[0]->{'uri'}->password }

1;
