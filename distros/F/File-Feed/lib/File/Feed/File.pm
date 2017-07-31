package File::Feed::File;

use strict;
use warnings;

sub new {
    my $cls = shift;
    unshift @_, 'id' if @_ % 2;
    my %arg = @_;
    $arg{'#'} ||= delete $arg{'id'};
    $arg{'@'} ||= 'file';
    $arg{'channel'} = $arg{'_channel'}->id;
    bless \%arg, $cls;
}

sub id { $_[0]->{'#'} }
sub path { $_[0]->{'#'} }
sub local_path { $_[0]->{'local-path'} }
sub feed { $_[0]->{'_feed'} }
sub source { $_[0]->{'source'} }
sub channel { $_[0]->{'_channel'} }

1;
