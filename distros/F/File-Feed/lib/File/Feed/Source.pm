package File::Feed::Source;

use strict;
use warnings;

use URI;

sub new {
    my $cls = shift;
    my %arg;
    if (@_ % 2 && ref($_[0]) eq 'HASH') {
        %arg = %{ shift() };
    }
    elsif (@_ % 2) {
        %arg = ( 'uri', @_ );
    }
    else {
        %arg = @_;
    }
    my $uri = $arg{'#'} || $arg{'uri'} or die "Can't instantiate a source without a URI";
    $uri = 'file://' . $uri if $uri =~ m{^/};
    $uri = URI->new($uri) if !ref $uri;
    my $scheme = $uri->scheme;
    $cls .= '::' . lc $scheme;
    eval "use $cls; 1" or die $@;
    bless {
        'uri'  => $uri,
    }, $cls;
}

sub uri { $_[0]->{'uri'} }
sub host { $_[0]->{'host'} ||= $_[0]->{'uri'}->host }
sub root { $_[0]->{'root'} ||= $_[0]->{'uri'}->path }
sub user { $_[0]->{'user'} ||= $_[0]->{'uri'}->user }
sub password { $_[0]->{'password'} ||= $_[0]->{'uri'}->password }

sub fetch {
    my ($self, %arg) = @_;
    my $channel = $arg{'channel'};
    my $exclude = $arg{'exclude'} || {};
    my $dest    = $arg{'destination'};
    my $root    = $self->root;
    my $recurse = $channel->recursive;
    my $filter  = $channel->file_filter;
    my $path    = $channel->path;
    my $lpath   = $channel->local_path;
    my $dir  = defined $path  ? $path  : '.';
    my $ldir = defined $lpath ? "$dest/$lpath" : $dest;
    my $pfx  = defined $path  ? $path  . '/' : '';
    my $lpfx = defined $lpath ? $lpath . '/' : '';
    my @fetched;
    foreach ($self->list($dir, $recurse)) {
        my $from = defined $path ? "$path/$_" : $_;
        my $to = "$ldir/$_";
        next if $exclude->{$from} || !$filter->($_);
        $self->fetch_file($from, $to) or die "Can't fetch $from to $to: $!";
        push @fetched, {
            '#' => $pfx . $_,
            'path' => $pfx . $_,
            'local-path' => $lpfx . $_,
        };
    }
    return @fetched;
}

1;
