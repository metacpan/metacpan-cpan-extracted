package File::Feed::Channel;

use strict;
use warnings;

use File::Feed::Util;

sub new {
    my $cls = shift;
    bless { @_ }, $cls;
}

sub id          { $_[0]->{'#'          } }
sub recursive   { $_[0]->{'recursive'  } }
sub description { $_[0]->{'description'} }

sub path { $_[0]->{'path'} || $_[0]->{'#'} }
sub local_path { $_[0]->{'local-path'} || '.' }

sub autodir { exists $_[0]->{'autodir'} ? $_[0]->{'autodir'} : $_[0]->{'_feed'}->autodir }
sub repeat  { exists $_[0]->{'repeat' } ? $_[0]->{'repeat' } : $_[0]->{'_feed'}->repeat  }
sub clobber { exists $_[0]->{'clobber'} ? $_[0]->{'clobber'} : $_[0]->{'_feed'}->clobber }

sub file_filter {
    my ($self) = @_;
    return $self->{'_filter'} if $self->{'_filter'};
    my $spec = $self->{'filter'} or return $self->{'_filter'} = sub { 1 };
    my $rx = File::Feed::Util::pat2rx($spec);
    return $self->{'_filter'} = sub { shift() =~ $rx };
}

sub regexp {
    my ($self) = @_;
    $self->{'_regexp'} ||= File::Feed::Util::pat2rx($self->{'match'} || '*');
}

1;

