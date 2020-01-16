# Copyrights 2011-2020 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution IOMux.  Meta-POD processed with OODoc
# into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package IOMux::Select;
use vars '$VERSION';
$VERSION = '1.01';

use base 'IOMux';

use warnings;
use strict;

use Log::Report 'iomux';

use List::Util  'min';
use POSIX       'errno_h';

$SIG{PIPE} = 'IGNORE';   # pipes are handled in select


sub init($)
{   my ($self, $args) = @_;
    $self->SUPER::init($args);
    $self->{IMS_readers} = '';
    $self->{IMS_writers} = '';
    $self->{IMS_excepts} = '';
    $self;
}

#-----------------

sub _flags2string($);
sub showFlags($;$$)
{   my $self = shift;
    return _flags2string(shift)
        if @_==1;

    my ($rdbits, $wrbits, $exbits) = @_ ? @_ : $self->selectFlags;
    my $rd = _flags2string $rdbits;
    my $wr = _flags2string $wrbits;
    my $ex = _flags2string $exbits;

    <<__SHOW;
  read: $rd
 write: $wr
except: $ex
__SHOW
}

sub _flags2string($)
{   my $bytes = shift;
    use bytes;
    my $bits  = length($bytes) * 8;
    my $out   = '';
    for my $fileno (0..$bits-1)
    {   $out .= vec($bytes, $fileno, 1)==1 ? ($fileno%10) : '-';
    }
    $out =~ s/-+$//;
    length $out ? $out : '(none)';
}

#--------------------------

sub fdset($$$$$)
{   my ($self, $fileno, $state, $r, $w, $e) = @_;
    vec($self->{IMS_readers}, $fileno, 1) = $state if $r;
    vec($self->{IMS_writers}, $fileno, 1) = $state if $w;
    vec($self->{IMS_excepts}, $fileno, 1) = $state if $e;
    # trace "fdset(@_), now: " .$self->showFlags($self->waitFlags);
}

sub one_go($$)
{   my ($self, $wait, $heartbeat) = @_;

    #trace "SELECT=\n".$self->showFlags($self->waitFlags);

    my ($rdready, $wrready, $exready)
       = @$self{ qw/IMS_readers IMS_writers IMS_excepts/ };

    my ($numready, $timeleft)
       = select $rdready, $wrready, $exready, $wait;
info "time left: $timeleft";

    #trace "READY=\n".$self->showFlags($rdready, $wrready, $exready);

    if($heartbeat)
    {   # can be collected from within heartbeat
        $self->{IMS_select_flags} = [$rdready, $wrready, $exready];
        $heartbeat->($self, $numready, $timeleft)
    }

    unless(defined $numready)
    {   return if $! == EINTR || $! == EAGAIN;
        alert "leaving loop";
        return 0;
    }

    # Hopefully the regexp improves performance when many slow connections
    $self->_ready(muxReadFlagged   => $rdready) if $rdready =~ m/[^\x00]/;
    $self->_ready(muxWriteFlagged  => $wrready) if $wrready =~ m/[^\x00]/;
    $self->_ready(muxExceptFlagged => $exready) if $exready =~ m/[^\x00]/;

info "sleeping 1";
sleep 1;
    1;  # success
}

# It would be nice to have an algorithm which is better than O(n)
sub _ready($$)
{   my ($self, $call, $flags) = @_;
    my $handlers = $self->_handlers;
    while(my ($fileno, $conn) = each %$handlers)
    {   $conn->$call($fileno) if (vec $flags, $fileno, 1)==1;
#warn "$conn $call($fileno)" if (vec $flags, $fileno, 1)==1;
    }
}


sub waitFlags()
{   my $self = shift;
    @{$self}{ qw/IMS_readers IMS_writers IMS_excepts/ };
}


sub selectFlags() { @{shift->{IMS_select_flags} || []} }

1;

__END__
