package File::Feed::Sink::kit;

use strict;
use warnings;

use vars qw(@ISA);

@ISA = qw(File::Feed::Sink);

use File::Feed::Sink;
use File::Kit;

sub protocol { 'kit' }

sub feed { $_[0]->{'_feed'} }
sub path { $_[0]->{'path'} ||= $_[0]->{'uri'}->path }

sub begin {
    my ($self) = @_;
    my $path = $self->path;
    $path = $self->feed->dir . '/' . $path if $path !~ m{^/};  # XXX Really?
    $self->{'_kit'} = File::Kit->new($path);
    return $self;
}

sub end {
    my ($self) = @_;
    $self->{'_kit'}->save;
    return $self;
}

sub store {
    my $self = shift;
    my $kit = $self->{'_kit'};
    my $from = $self->from;  # XXX Really?
    foreach my $file (@_) {
        my $lpath = $file->local_path;
        $kit->add("$from/$lpath", $file);
    }
}

1;
