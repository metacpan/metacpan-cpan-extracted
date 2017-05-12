# Copyrights 2011-2015 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
use warnings;
use strict;

package IOMux;
use vars '$VERSION';
$VERSION = '1.00';

use Log::Report 'iomux';

use List::Util  'min';
use POSIX       'errno_h';

$SIG{PIPE} = 'IGNORE';     # pipes are handled in mux

use constant
  { LONG_TIMEOUT   => 60   # no-one has set a timeout
  };


sub new(@)  {my $class = shift; (bless {}, $class)->init( {@_} ) }
sub init($)
{   my ($self, $args) = @_;
    $self->{IM_handlers} = {};
    $self->{IM_timeouts} = {};
    $self;
}

#-------------

#-------------

# add() is the main user interface to mux, because from then the
# user works with connection objects. Therefore, offer some extra
# features here.

sub add($)
{   my ($self, $handler) = @_;

    UNIVERSAL::isa($handler, 'IOMux::Handler')
        or error __x"attempt to add non handler {pkg}"
          , pkg => (ref $handler || $handler);

    $handler->muxInit($self);
    $handler;
}


sub open(@)
{   my $self = shift;
    IOMux::Open->can('new')
        or error __x"IOMux::Open not loaded";
    my $conn = IOMux::Open->new(@_);
    $self->add($conn) if $conn;
    $conn;
}


sub loop(;$)
{   my($self, $heartbeat) = @_;
    $self->{IM_endloop} = 0;

    my $handlers = $self->{IM_handlers};
    keys %$handlers
        or error __x"there are no handlers for the mux loop";

  LOOP:
    while(!$self->{IM_endloop} && keys %$handlers)
    {
#       while(my($fileno, $conn) = each %$handlers)
#       {   $conn->read
#               if $conn->usesSSL && $conn->pending;
#       }

        my $timeout = $self->{IM_next_timeout};
        my $wait    = defined $timeout ? $timeout-time : LONG_TIMEOUT;

        # For negative values, still give select a chance, to avoid
        # starvation when timeout handling starts consuming all
        # processor time.
        $wait       = 0.001 if $wait < 0.001;

        $self->one_go($wait, $heartbeat)
            or last LOOP;

        $self->_checkTimeouts($timeout);
    }

    $_->close
        for values %$handlers;
}


sub endLoop($) { $_[0]->{IM_endloop} = $_[1] }

#-------------

sub handlers()  {values %{shift->{IM_handlers}}}
sub _handlers() {shift->{IM_handlers}}


sub handler($;$)
{   my $hs     = shift->{IM_handlers};
    my $fileno = shift;
    @_ or return $hs->{$fileno};
    (defined $_[0]) ? ($hs->{$fileno} = shift) : (delete $hs->{$fileno});
}


sub remove($)
{   my ($self, $fileno) = @_;

    my $obj = delete $self->{IM_handlers}{$fileno}
        or return $self;

    $self->fdset($fileno, 0, 1, 1, 1);
    $obj->muxRemove;

    if(my $timeout = delete $self->{IM_timeouts}{$fileno})
    {   delete $self->{IM_next_timeout}
            if $self->{IM_next_timeout}==$timeout;
    }

    $self;
}


sub fdset($$$$$) {panic}


sub changeTimeout($$$)
{   my ($self, $fileno, $old, $when) = @_;
    return if $old==$when;

    my $next = $self->{IM_next_timeout};
    if($old)
    {   # next timeout will be recalculated max once per loop
        delete $self->{IM_timeouts}{$fileno};
        $self->{IM_next_timeout} = $next = undef if $next && $next==$old;
    }

    if($when)
    {   $self->{IM_next_timeout} = $when if !$next || $next > $when;
        $self->{IM_timeouts}{$fileno} = $when;
    }
}

# handle all timeouts which have expired either during the select
# or during the processing of flags.
sub _checkTimeouts($)
{   my ($self, $next) = @_;

    my $now  = time;
    if($next && $now < $next)
    {   # Even when next is cancelled, none can have expired.
        # However, a new timeout may have arrived which may expire immediately.
        return $next if $self->{IM_next_timeout};
    }

    my $timo = $self->{IM_timeouts};
    my $hnd  = $self->{IM_handlers};
    while(my ($fileno, $when) = each %$timo)
    {   $when <= $now or next;
        $hnd->{$fileno}->muxTimeout($self);
        delete $timo->{$fileno};
    }

    $self->{IM_next_timeout} = min values %$timo;
}

1;

__END__
